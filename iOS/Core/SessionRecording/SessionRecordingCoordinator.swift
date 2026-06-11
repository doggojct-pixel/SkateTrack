// [自主區] iOS/Core/SessionRecording/SessionRecordingCoordinator.swift
// 用途：Session lifecycle 唯一入口，協調感測器融合、跌倒偵測與即時指標累積。
// 委派至：useSessionRecording Hook、Task-012 Session Start UI、Task-014 Fall Alert UI。

import Combine
import Foundation

enum SessionRecordingError: Error, Sendable, Equatable {
    case invalidPowerType
    case sensorUnavailable
    case invalidStateTransition

    var localizationKey: String {
        switch self {
        case .invalidPowerType:
            return "session.error.invalidPowerType"
        case .sensorUnavailable:
            return "session.error.sensorUnavailable"
        case .invalidStateTransition:
            return "session.error.invalidStateTransition"
        }
    }
}
#if DEBUG
enum SessionRecordingDataSource: Sendable, Equatable {
    case live
    case mock
}
#endif

protocol SessionSensorProviding: AnyObject {
    var motionSamplePublisher: AnyPublisher<MotionSample, Never> { get }
    func startRecording(mode: SportMode) async throws
    func stopRecording() async -> SessionData
}

protocol SessionFallDetecting: AnyObject {
    var fallEventPublisher: AnyPublisher<FallEvent, Never> { get }
    var sosTriggerPublisher: AnyPublisher<FallEvent, Never> { get }
    var countdownPublisher: AnyPublisher<Int?, Never> { get }
    var detectedFallEvents: [FallEvent] { get }
    func startMonitoring(samples: AnyPublisher<MotionSample, Never>, mode: SportMode)
    func stopMonitoring()
    func cancelFallAlert()
}

extension SensorFusionEngine: SessionSensorProviding {}
extension FallDetectionEngine: SessionFallDetecting {}

final class SessionRecordingCoordinator {
    static let shared = SessionRecordingCoordinator()

    private let sensorEngine: SessionSensorProviding
    let fallDetectionEngine: SessionFallDetecting
    let sosDispatcher: SOSEventDispatcher
    private var stateMachine = SessionStateMachine()
    var metricsAccumulator = SessionMetricsAccumulator()

    var selectedSportMode: SportMode?
    private var selectedPowerType: PowerType = .humanPowered
    private var sessionStartDate: Date?
    var activeFallEvent: FallEvent?
    private var completedSession: SessionData?

    private let stateSubject = CurrentValueSubject<SessionRecordingStatus, Never>(.idle)
    private let metricsSubject = CurrentValueSubject<LiveSessionMetrics, Never>(.zero)
    private let errorSubject = PassthroughSubject<String, Never>()
    let fallEventSubject = CurrentValueSubject<FallEvent?, Never>(nil)
    let fallCountdownSubject = CurrentValueSubject<Int?, Never>(nil)
    let sosTriggerEventSubject = CurrentValueSubject<SOSTriggerEvent?, Never>(nil)
    private let completedSessionSubject = PassthroughSubject<SessionData, Never>()

    private var sampleCancellables = Set<AnyCancellable>()
    private var fallCancellables = Set<AnyCancellable>()
    private var mockSampleTimer: DispatchSourceTimer?
    private var mockSampleIndex = 0
    #if DEBUG
    private var dataSource: SessionRecordingDataSource = .live
    #endif

    var status: SessionRecordingStatus { stateMachine.status }
    var statePublisher: AnyPublisher<SessionRecordingStatus, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    var metricsPublisher: AnyPublisher<LiveSessionMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    var activeFallEventPublisher: AnyPublisher<FallEvent?, Never> {
        fallEventSubject.eraseToAnyPublisher()
    }
    var completedSessionPublisher: AnyPublisher<SessionData, Never> {
        completedSessionSubject.eraseToAnyPublisher()
    }

    init(
        sensorEngine: SessionSensorProviding = SensorFusionEngine(),
        fallDetectionEngine: SessionFallDetecting = FallDetectionEngine(),
        sosDispatcher: SOSEventDispatcher = .shared
    ) {
        self.sensorEngine = sensorEngine
        self.fallDetectionEngine = fallDetectionEngine
        self.sosDispatcher = sosDispatcher
    }

    #if DEBUG
    var debugDataSource: SessionRecordingDataSource { dataSource }

    func setDataSource(_ source: SessionRecordingDataSource) {
        dataSource = source
    }
    #endif

    func startSession(mode: SportMode, powerType: PowerType) async throws {
        guard powerType.isValid(for: mode) else {
            publishError(SessionRecordingError.invalidPowerType.localizationKey)
            throw SessionRecordingError.invalidPowerType
        }

        try applyTransition(to: .preparing)

        selectedSportMode = mode
        selectedPowerType = powerType
        sessionStartDate = Date()
        activeFallEvent = nil
        fallEventSubject.send(nil)
        fallCountdownSubject.send(nil)
        sosTriggerEventSubject.send(nil)
        completedSession = nil
        metricsAccumulator.beginSession(at: sessionStartDate ?? Date())

        do {
            #if DEBUG
            if dataSource == .mock {
                startMockSampleFeed(for: mode)
            } else {
                try await sensorEngine.startRecording(mode: mode)
                bindLiveSampleStream(for: mode)
            }
            #else
            try await sensorEngine.startRecording(mode: mode)
            bindLiveSampleStream(for: mode)
            #endif
            try applyTransition(to: .recording)
            publishMetrics()
        } catch {
            await teardownActiveSession(resetToIdle: false)
            publishError(SessionRecordingError.sensorUnavailable.localizationKey)
            try? applyTransition(to: .failed)
            throw SessionRecordingError.sensorUnavailable
        }
    }

    func pauseSession() async throws {
        try applyTransition(to: .paused)
        metricsAccumulator.setPaused(true)
        fallDetectionEngine.stopMonitoring()
        stopMockSampleFeed()
    }

    func resumeSession() async throws {
        guard let mode = selectedSportMode else {
            throw SessionRecordingError.invalidStateTransition
        }

        try applyTransition(to: .recording)
        metricsAccumulator.setPaused(false)

        #if DEBUG
        if dataSource == .mock {
            startMockSampleFeed(for: mode)
        } else {
            bindFallDetection(for: mode)
        }
        #else
        bindFallDetection(for: mode)
        #endif
    }

    @discardableResult
    func requestEndSession() async throws -> SessionData {
        try applyTransition(to: .ending)
        try applyTransition(to: .saving)

        let sessionData = await finalizeSession(discard: false)
        try applyTransition(to: .idle)
        completedSession = sessionData
        completedSessionSubject.send(sessionData)
        return sessionData
    }

    func discardCurrentSession() async {
        _ = await finalizeSession(discard: true)
        resetCoordinatorState()
        stateMachine.resetToIdle()
        stateSubject.send(.idle)
        metricsSubject.send(.zero)
        fallEventSubject.send(nil)
        fallCountdownSubject.send(nil)
    }

    private func bindLiveSampleStream(for mode: SportMode) {
        sampleCancellables.removeAll()
        fallCancellables.removeAll()

        sensorEngine.motionSamplePublisher
            .sink { [weak self] sample in
                self?.handleMotionSample(sample)
            }
            .store(in: &sampleCancellables)

        bindFallDetection(for: mode)
    }
    private func bindFallDetection(for mode: SportMode) {
        fallCancellables.removeAll()

        fallDetectionEngine.startMonitoring(
            samples: sensorEngine.motionSamplePublisher,
            mode: mode
        )

        fallDetectionEngine.fallEventPublisher
            .sink { [weak self] fallEvent in
                self?.activeFallEvent = fallEvent
                self?.fallEventSubject.send(fallEvent)
            }
            .store(in: &fallCancellables)

        fallDetectionEngine.countdownPublisher
            .sink { [weak self] seconds in self?.fallCountdownSubject.send(seconds) }
            .store(in: &fallCancellables)

        fallDetectionEngine.sosTriggerPublisher
            .sink { [weak self] fallEvent in
                guard let self else { return }
                activeFallEvent = nil
                fallEventSubject.send(nil)
                fallCountdownSubject.send(nil)
                _ = dispatchSOS(source: SOSTriggerSource.fallCountdownExpired, fallEvent: fallEvent)
            }
            .store(in: &fallCancellables)
    }

    private func handleMotionSample(_ sample: MotionSample) {
        guard stateMachine.status == .recording else { return }
        metricsAccumulator.process(sample)
        publishMetrics()
    }

    private func publishMetrics() {
        metricsSubject.send(metricsAccumulator.makeLiveMetrics())
    }

    private func publishError(_ key: String) {
        errorSubject.send(key)
    }

    private func applyTransition(to newStatus: SessionRecordingStatus) throws {
        do {
            try stateMachine.transition(to: newStatus)
            stateSubject.send(stateMachine.status)
        } catch {
            throw SessionRecordingError.invalidStateTransition
        }
    }

    private func finalizeSession(discard: Bool) async -> SessionData {
        stopMockSampleFeed()
        fallDetectionEngine.stopMonitoring()
        fallCountdownSubject.send(nil)
        sampleCancellables.removeAll()
        fallCancellables.removeAll()

        let summaryMetrics = metricsAccumulator.makeSummaryMetrics()
        let fallEvents = fallDetectionEngine.detectedFallEvents
        let endDate = Date()

        let baseSession: SessionData
        if discard {
            baseSession = makeDiscardedSessionData(endDate: endDate, summaryMetrics: summaryMetrics, fallEvents: fallEvents)
        } else {
            #if DEBUG
            if dataSource == .mock {
                baseSession = makeMockSessionData(endDate: endDate, summaryMetrics: summaryMetrics, fallEvents: fallEvents)
            } else {
                baseSession = await sensorEngine.stopRecording()
            }
            #else
            baseSession = await sensorEngine.stopRecording()
            #endif
        }

        let enrichedSession = enrich(
            baseSession,
            endDate: endDate,
            powerType: selectedPowerType,
            fallEvents: fallEvents,
            summaryMetrics: summaryMetrics
        )

        resetCoordinatorState()
        fallEventSubject.send(nil)
        fallCountdownSubject.send(nil)
        return enrichedSession
    }

    private func enrich(
        _ session: SessionData,
        endDate: Date,
        powerType: PowerType,
        fallEvents: [FallEvent],
        summaryMetrics: SessionSummaryMetrics
    ) -> SessionData {
        try! SessionData(
            id: session.id,
            startDate: session.startDate,
            endDate: endDate,
            sportMode: session.sportMode,
            powerType: powerType,
            motionSamples: session.motionSamples,
            trickEvents: session.trickEvents,
            fallEvents: fallEvents,
            summaryMetrics: summaryMetrics,
            equipmentID: session.equipmentID,
            spotID: session.spotID
        )
    }

    private func makeDiscardedSessionData(
        endDate: Date,
        summaryMetrics: SessionSummaryMetrics,
        fallEvents: [FallEvent]
    ) -> SessionData {
        let mode = selectedSportMode ?? .skateboard(.streetPark)
        return try! SessionData(
            startDate: sessionStartDate ?? endDate,
            endDate: endDate,
            sportMode: mode,
            powerType: selectedPowerType,
            motionSamples: [],
            fallEvents: fallEvents,
            summaryMetrics: summaryMetrics
        )
    }

    private func makeMockSessionData(
        endDate: Date,
        summaryMetrics: SessionSummaryMetrics,
        fallEvents: [FallEvent]
    ) -> SessionData {
        let mode = selectedSportMode ?? .skateboard(.streetPark)
        let samples = metricsAccumulator.latestMotionSample.map { [$0] } ?? []
        return try! SessionData(
            startDate: sessionStartDate ?? endDate,
            endDate: endDate,
            sportMode: mode,
            powerType: selectedPowerType,
            motionSamples: samples,
            fallEvents: fallEvents,
            summaryMetrics: summaryMetrics
        )
    }

    private func teardownActiveSession(resetToIdle: Bool) async {
        stopMockSampleFeed()
        fallDetectionEngine.stopMonitoring()
        sampleCancellables.removeAll()
        fallCancellables.removeAll()

        #if DEBUG
        if dataSource != .mock {
            _ = await sensorEngine.stopRecording()
        }
        #else
        _ = await sensorEngine.stopRecording()
        #endif

        resetCoordinatorState()
        fallCountdownSubject.send(nil)

        if resetToIdle {
            stateMachine.resetToIdle()
            stateSubject.send(.idle)
            metricsSubject.send(.zero)
            fallEventSubject.send(nil)
        }
    }


    private func resetCoordinatorState() {
        selectedSportMode = nil
        selectedPowerType = .humanPowered
        sessionStartDate = nil
        activeFallEvent = nil
        metricsAccumulator.reset()
        mockSampleIndex = 0
    }

    #if DEBUG
    private func startMockSampleFeed(for mode: SportMode) {
        stopMockSampleFeed()

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let sample = self.makeMockSample(for: mode)
            self.handleMotionSample(sample)
        }
        mockSampleTimer = timer
        timer.resume()
    }

    private func stopMockSampleFeed() {
        mockSampleTimer?.cancel()
        mockSampleTimer = nil
    }

    private func makeMockSample(for _: SportMode) -> MotionSample {
        mockSampleIndex += 1
        let speedKmh = 12 + Double(mockSampleIndex % 5)
        let latitude = 25.033 + (Double(mockSampleIndex) * 0.00005)
        let longitude = 121.565 + (Double(mockSampleIndex) * 0.00005)

        return MotionSample(
            timestamp: Date(),
            gpsCoordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
            speedKmh: speedKmh,
            accelerometerG: ThreeAxisValue(x: 0.05, y: 0.1, z: 0.98),
            gyroscopeRadPS: ThreeAxisValue(x: 0.02, y: 0.03, z: 0.01),
            altitudeMeters: 20 + Double(mockSampleIndex)
        )
    }
    #endif
}

#if DEBUG
extension SessionRecordingCoordinator {
    static func makeMockCoordinator() -> SessionRecordingCoordinator {
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: SensorFusionEngine(),
            fallDetectionEngine: FallDetectionEngine()
        )
        coordinator.setDataSource(.mock)
        return coordinator
    }
}
#endif
