// [自主區] iOS/Core/SessionRecording/SessionRecordingCoordinator.swift
// 用途：Session lifecycle 唯一入口，協調感測器融合、跌倒偵測與即時指標累積。
// 委派至：useSessionRecording Hook、Task-012 Session Start UI、Task-014 Fall Alert UI、Task-015 persistence。
import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif
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


#if DEBUG
final class RecordingDebugDiagnosticsCollector {
    static let shared = RecordingDebugDiagnosticsCollector()

    private let lock = NSLock()
    private let heartbeatIntervalSeconds: TimeInterval = 5
    private let motionGapThresholdSeconds: TimeInterval = 5
    private let locationGapThresholdSeconds: TimeInterval = 10

    private var diagnosticsStartedAt: Date?
    private var sessionStartDate: Date?
    private var testContext: RecordingDebugTestContext?
    private var appLifecycleEvents: [RecordingDebugLifecycleEvent] = []
    private var recordingHeartbeats: [RecordingDebugHeartbeat] = []
    private var authorizationSnapshots: [RecordingDebugAuthorizationSnapshot] = []
    private var locationManagerSnapshots: [RecordingDebugLocationManagerSnapshot] = []
    private var locationCallbackEvents: [RecordingDebugLocationCallbackEvent] = []
    private var gapEvents: [RecordingDebugGapEvent] = []
    private var recoveryEvents: [RecordingDebugRecoveryEvent] = []
    private var acceptedLocationFixCount = 0
    private var rejectedLocationFixCount = 0
    private var rejectionReasons: [String: Int] = [:]
    private var lastHeartbeatAt: Date?
    private var lastMotionSampleAt: Date?
    private var lastLocationFixAt: Date?
    private var lastTimerFusionAt: Date?
    private var motionSampleCount = 0
    private var locationFixCount = 0
    private var timerFusionCount = 0
    private var latestLocationDiagnostics: LocationFixDiagnostics?
    private var latestSpeedKmh: Double?

    func beginSession(startDate: Date, testContext: RecordingDebugTestContext?) {
        lock.withLock {
            diagnosticsStartedAt = Date()
            sessionStartDate = startDate
            self.testContext = testContext
            appLifecycleEvents = []
            recordingHeartbeats = []
            authorizationSnapshots = []
            locationManagerSnapshots = []
            locationCallbackEvents = []
            gapEvents = []
            recoveryEvents = []
            acceptedLocationFixCount = 0
            rejectedLocationFixCount = 0
            rejectionReasons = [:]
            lastHeartbeatAt = nil
            lastMotionSampleAt = nil
            lastLocationFixAt = nil
            lastTimerFusionAt = nil
            motionSampleCount = 0
            locationFixCount = 0
            timerFusionCount = 0
            latestLocationDiagnostics = nil
            latestSpeedKmh = nil
        }
        recordLifecycleEvent("sessionStarted", runtime: nil)
    }

    func recordLifecycleEvent(_ eventType: String, runtime: RecordingDebugRuntimeSnapshot?) {
        lock.withLock {
            guard diagnosticsStartedAt != nil else { return }
            appLifecycleEvents.append(
                RecordingDebugLifecycleEvent(eventType: eventType, runtime: runtime)
            )
            trimArraysIfNeeded()
        }
    }

    func recordAuthorizationSnapshot(_ snapshot: RecordingDebugAuthorizationSnapshot) {
        lock.withLock {
            guard diagnosticsStartedAt != nil else { return }
            authorizationSnapshots.append(snapshot)
            trimArraysIfNeeded()
        }
    }

    func recordLocationManagerSnapshot(_ snapshot: RecordingDebugLocationManagerSnapshot) {
        lock.withLock {
            guard diagnosticsStartedAt != nil else { return }
            locationManagerSnapshots.append(snapshot)
            trimArraysIfNeeded()
        }
    }

    func recordLocationCallbackEvent(_ event: RecordingDebugLocationCallbackEvent) {
        lock.withLock {
            guard diagnosticsStartedAt != nil else { return }
            locationCallbackEvents.append(event)
            trimArraysIfNeeded()
        }
    }

    func recordFilterDecision(accepted: Bool, reason: String) {
        lock.withLock {
            guard diagnosticsStartedAt != nil else { return }
            if accepted {
                acceptedLocationFixCount += 1
            } else {
                rejectedLocationFixCount += 1
                rejectionReasons[reason, default: 0] += 1
            }
        }
    }

    func recordRecoveryEvent(_ event: RecordingDebugRecoveryEvent) {
        lock.withLock {
            guard diagnosticsStartedAt != nil else { return }
            recoveryEvents.append(event)
            trimArraysIfNeeded()
        }
    }

    func recordMotionSample(
        _ sample: MotionSample,
        sessionStatus: String,
        isRecordingActive: Bool,
        runtime: RecordingDebugRuntimeSnapshot?
    ) {
        let now = Date()
        lock.withLock {
            guard let sessionStartDate else { return }
            motionSampleCount += 1
            latestSpeedKmh = sample.speedKmh
            latestLocationDiagnostics = sample.locationDiagnostics

            if let lastMotionSampleAt {
                let interval = now.timeIntervalSince(lastMotionSampleAt)
                if interval > motionGapThresholdSeconds {
                    gapEvents.append(makeGapEvent(
                        startedAt: lastMotionSampleAt,
                        endedAt: now,
                        durationSeconds: interval,
                        gapType: "motionGap",
                        runtime: runtime,
                        lastMotionAgeSeconds: interval
                    ))
                }
            }
            lastMotionSampleAt = now

            switch sample.sampleSource {
            case .some(.locationFix):
                if let lastLocationFixAt {
                    let interval = now.timeIntervalSince(lastLocationFixAt)
                    if interval > locationGapThresholdSeconds {
                        gapEvents.append(makeGapEvent(
                            startedAt: lastLocationFixAt,
                            endedAt: now,
                            durationSeconds: interval,
                            gapType: "locationGap",
                            runtime: runtime,
                            lastLocationAgeSeconds: interval,
                            lastMotionAgeSeconds: lastMotionSampleAt.map { now.timeIntervalSince($0) }
                        ))
                    }
                }
                locationFixCount += 1
                lastLocationFixAt = now
            case .some(.timerFusion):
                timerFusionCount += 1
                lastTimerFusionAt = now
            case .some(.debugSimulated):
                locationFixCount += 1
                timerFusionCount += 1
                lastLocationFixAt = now
                lastTimerFusionAt = now
            case .none:
                break
            }

            if lastHeartbeatAt == nil || now.timeIntervalSince(lastHeartbeatAt ?? now) >= heartbeatIntervalSeconds {
                recordingHeartbeats.append(
                    RecordingDebugHeartbeat(
                        timestamp: now,
                        elapsedSessionSeconds: now.timeIntervalSince(sessionStartDate),
                        isRecordingActive: isRecordingActive,
                        sessionStatus: sessionStatus,
                        motionSampleCount: motionSampleCount,
                        locationFixCount: locationFixCount,
                        timerFusionCount: timerFusionCount,
                        lastMotionSampleAgeSeconds: lastMotionSampleAt.map { now.timeIntervalSince($0) },
                        lastLocationFixAgeSeconds: lastLocationFixAt.map { now.timeIntervalSince($0) },
                        lastTimerFusionAgeSeconds: lastTimerFusionAt.map { now.timeIntervalSince($0) },
                        runtime: runtime
                    )
                )
                lastHeartbeatAt = now
            }
            trimArraysIfNeeded()
        }
    }

    func finishSession(endDate: Date, samples: [MotionSample]) -> RecordingDebugDiagnostics {
        lock.withLock {
            let startedAt = diagnosticsStartedAt ?? sessionStartDate ?? endDate
            let filterSummary = RecordingDebugFilterDecisionSummary(
                acceptedLocationFixCount: acceptedLocationFixCount,
                rejectedLocationFixCount: rejectedLocationFixCount,
                rejectionReasons: rejectionReasons
            )
            let hasRecordedEvents = !appLifecycleEvents.isEmpty
                || !recordingHeartbeats.isEmpty
                || !authorizationSnapshots.isEmpty
                || !locationManagerSnapshots.isEmpty
                || !locationCallbackEvents.isEmpty
                || !gapEvents.isEmpty
                || !recoveryEvents.isEmpty
                || acceptedLocationFixCount > 0
                || rejectedLocationFixCount > 0
            return RecordingDebugDiagnostics(
                buildIdentity: RecordingDebugBuildIdentity(
                    debugBuildTaskID: RecordingDebugBuildIdentity.currentDebugBuildTaskID,
                    gitBranchName: "task-030c-gps-route-fidelity",
                    diagnosticsSchemaVersion: 1,
                    appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                    buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
                    platform: "iOS",
                    osVersionMajorMinor: ProcessInfo.processInfo.operatingSystemVersionString
                ),
                testContext: testContext ?? RecordingDebugTestContext(label: .unspecified),
                diagnosticsStartedAt: startedAt,
                diagnosticsEndedAt: endDate,
                diagnosticsStatus: hasRecordedEvents ? "enabled" : "enabledButNoEventsRecorded",
                appLifecycleEvents: appLifecycleEvents,
                recordingHeartbeats: recordingHeartbeats,
                authorizationSnapshots: authorizationSnapshots,
                locationManagerSnapshots: locationManagerSnapshots,
                locationCallbackEvents: locationCallbackEvents,
                gapEvents: gapEvents,
                recoveryEvents: recoveryEvents,
                filterDecisionSummary: filterSummary,
                altitudeDiagnostics: Self.makeAltitudeDiagnostics(from: samples)
            )
        }
    }

    private func makeGapEvent(
        startedAt: Date,
        endedAt: Date,
        durationSeconds: TimeInterval,
        gapType: String,
        runtime: RecordingDebugRuntimeSnapshot?,
        lastLocationAgeSeconds: TimeInterval? = nil,
        lastMotionAgeSeconds: TimeInterval? = nil
    ) -> RecordingDebugGapEvent {
        RecordingDebugGapEvent(
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            gapType: gapType,
            appStateAtEnd: runtime?.appState,
            authorizationStatus: authorizationSnapshots.last?.authorizationStatus,
            accuracyAuthorization: authorizationSnapshots.last?.accuracyAuthorization,
            lastKnownHorizontalAccuracyMeters: latestLocationDiagnostics?.horizontalAccuracyMeters,
            lastKnownSpeedKmh: latestSpeedKmh,
            lastKnownSpeedAccuracyMetersPerSecond: latestLocationDiagnostics?.speedAccuracyMetersPerSecond,
            lastLocationAgeAtEndSeconds: lastLocationAgeSeconds,
            lastMotionAgeAtEndSeconds: lastMotionAgeSeconds,
            motionLoopAlsoPaused: durationSeconds > motionGapThresholdSeconds,
            timerFusionAlsoPaused: lastTimerFusionAt.map { endedAt.timeIntervalSince($0) > motionGapThresholdSeconds },
            restartAttempted: false,
            restartRecovered: nil
        )
    }

    private static func makeAltitudeDiagnostics(from samples: [MotionSample]) -> RecordingDebugAltitudeDiagnostics {
        var sourceCounts: [String: Int] = [:]
        var acceptedCoreLocation = 0
        var rejectedCoreLocation = 0
        var acceptedBarometer = 0
        var rejectionReasons: [String: Int] = [:]
        var maxSingleJump: Double?
        var maxVerticalAccuracy: Double?
        var previousAltitude: Double?
        var previousSource: AltitudeSampleSource?

        for sample in samples.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let source = sample.altitudeSource else { continue }
            sourceCounts[source.rawValue, default: 0] += 1
            if let verticalAccuracy = sample.locationDiagnostics?.verticalAccuracyMeters {
                maxVerticalAccuracy = max(maxVerticalAccuracy ?? verticalAccuracy, verticalAccuracy)
            }
            guard let altitude = sample.altitudeMeters, altitude.isFinite else {
                rejectionReasons["missingAltitude", default: 0] += 1
                continue
            }
            if let previousAltitude {
                let jump = abs(altitude - previousAltitude)
                maxSingleJump = max(maxSingleJump ?? jump, jump)
                if previousSource != source {
                    rejectionReasons["mixedAltitudeSource", default: 0] += 1
                }
            }
            switch source {
            case .coreLocationAbsolute, .debugSimulated:
                if let verticalAccuracy = sample.locationDiagnostics?.verticalAccuracyMeters, verticalAccuracy > 35 {
                    rejectedCoreLocation += 1
                    rejectionReasons["verticalAccuracyTooPoor", default: 0] += 1
                } else {
                    acceptedCoreLocation += 1
                }
            case .barometerRelative:
                acceptedBarometer += 1
            case .unavailable:
                rejectionReasons["missingAltitude", default: 0] += 1
            }
            previousAltitude = altitude
            previousSource = source
        }

        return RecordingDebugAltitudeDiagnostics(
            altitudeSourceCounts: sourceCounts,
            coreLocationAltitudeAcceptedCount: acceptedCoreLocation,
            coreLocationAltitudeRejectedCount: rejectedCoreLocation,
            barometerRelativeAltitudeAcceptedCount: acceptedBarometer,
            maxSingleAltitudeJumpMeters: maxSingleJump,
            maxVerticalAccuracyMeters: maxVerticalAccuracy,
            altitudeRejectionReasons: rejectionReasons
        )
    }

    private func trimArraysIfNeeded() {
        let maxEntries = 240
        if appLifecycleEvents.count > maxEntries { appLifecycleEvents.removeFirst(appLifecycleEvents.count - maxEntries) }
        if recordingHeartbeats.count > maxEntries { recordingHeartbeats.removeFirst(recordingHeartbeats.count - maxEntries) }
        if authorizationSnapshots.count > maxEntries { authorizationSnapshots.removeFirst(authorizationSnapshots.count - maxEntries) }
        if locationManagerSnapshots.count > maxEntries { locationManagerSnapshots.removeFirst(locationManagerSnapshots.count - maxEntries) }
        if locationCallbackEvents.count > maxEntries { locationCallbackEvents.removeFirst(locationCallbackEvents.count - maxEntries) }
        if gapEvents.count > maxEntries { gapEvents.removeFirst(gapEvents.count - maxEntries) }
        if recoveryEvents.count > maxEntries { recoveryEvents.removeFirst(recoveryEvents.count - maxEntries) }
    }
}
#endif
final class SessionRecordingCoordinator {
    static let shared = SessionRecordingCoordinator()
    private static let startupFallHandlingSuppressionSeconds: TimeInterval = 10
    private let sensorEngine: SessionSensorProviding
    let fallDetectionEngine: SessionFallDetecting
    let sosDispatcher: SOSEventDispatcher
    let sessionRepository: SessionRepositoryProtocol
    let equipmentMileageTracker: EquipmentMileageTracking
    let spotVisitTracker: SpotVisitTracking
    private var stateMachine = SessionStateMachine()
    var metricsAccumulator = SessionMetricsAccumulator()

    var selectedSportMode: SportMode?
    private var selectedPowerType: PowerType = .humanPowered
    private var selectedEquipmentID: UUID?
    private var selectedEquipmentSnapshot: EquipmentSessionSnapshot?
    private var selectedSpotID: UUID?
    private var selectedSpotSnapshot: SpotSessionSnapshot?
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
    var mockSampleTimer: DispatchSourceTimer?
    var mockSampleIndex = 0
    var mockSessionSamples: [MotionSample] = []
    #if DEBUG
    var dataSource: SessionRecordingDataSource = .live
    var mockRouteSimulator = DebugOutdoorRouteSimulator()
    var debugRecordingTestContext = RecordingDebugTestContext(label: .unspecified)
    private var debugLifecycleObservationTokens: [NSObjectProtocol] = []
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
        sosDispatcher: SOSEventDispatcher = .shared,
        sessionRepository: SessionRepositoryProtocol = SessionRepository.shared,
        equipmentMileageTracker: EquipmentMileageTracking = EquipmentMileageTracker.shared,
        spotVisitTracker: SpotVisitTracking = SpotVisitTracker.shared
    ) {
        self.sensorEngine = sensorEngine
        self.fallDetectionEngine = fallDetectionEngine
        self.sosDispatcher = sosDispatcher
        self.sessionRepository = sessionRepository
        self.equipmentMileageTracker = equipmentMileageTracker
        self.spotVisitTracker = spotVisitTracker
    }

    #if DEBUG
    var debugDataSource: SessionRecordingDataSource { dataSource }

    func setDataSource(_ source: SessionRecordingDataSource) {
        dataSource = source
    }

    func setDebugRecordingTestContext(_ context: DebugRecordingTestContextLabel) {
        debugRecordingTestContext = RecordingDebugTestContext(label: context)
    }
    #endif

    func startSession(
        mode: SportMode,
        powerType: PowerType,
        equipmentID: UUID? = nil,
        equipmentSnapshot: EquipmentSessionSnapshot? = nil,
        spotID: UUID? = nil,
        spotSnapshot: SpotSessionSnapshot? = nil
    ) async throws {
        guard powerType.isValid(for: mode) else {
            publishError(SessionRecordingError.invalidPowerType.localizationKey)
            throw SessionRecordingError.invalidPowerType
        }

        try applyTransition(to: .preparing)

        selectedSportMode = mode
        selectedPowerType = powerType
        selectedEquipmentID = equipmentID
        selectedEquipmentSnapshot = equipmentSnapshot
        selectedSpotID = spotID
        selectedSpotSnapshot = spotSnapshot
        sessionStartDate = Date()
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.beginSession(
            startDate: sessionStartDate ?? Date(),
            testContext: debugRecordingTestContext
        )
        startDebugLifecycleObservationIfNeeded()
        RecordingDebugDiagnosticsCollector.shared.recordLifecycleEvent(
            "sessionStartConfigured",
            runtime: makeDebugRuntimeSnapshot(scenePhase: nil)
        )
        #endif
        activeFallEvent = nil
        fallEventSubject.send(nil)
        fallCountdownSubject.send(nil)
        sosTriggerEventSubject.send(nil)
        completedSession = nil
        metricsAccumulator.beginSession(at: sessionStartDate ?? Date())
        await Task.yield()

        do {
            #if DEBUG
            if dataSource == .mock { startMockSampleFeed(for: mode) } else {
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
        do {
            let savedSession = try await sessionRepository.saveCompletedSession(sessionData)
            await applyEquipmentMileageIfNeeded(for: savedSession)
            await applySpotVisitIfNeeded(for: savedSession)
            try applyTransition(to: .idle)
            completedSession = savedSession
            completedSessionSubject.send(savedSession)
            return savedSession
        } catch let error as RepositoryError {
            publishError(error.localizationKey)
            try? applyTransition(to: .failed)
            throw error
        } catch {
            publishError(RepositoryError.saveFailed.localizationKey)
            try? applyTransition(to: .failed)
            throw RepositoryError.saveFailed
        }
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
                guard let self else { return }
                let isArmed = metricsAccumulator.elapsedTime >= 10
                let hasRideMotion = metricsAccumulator.currentSpeedKilometersPerHour >= 4 || metricsAccumulator.distanceKilometers >= 0.01
                let fallPolicy = ActivityFidelityPolicy(profile: self.currentFidelityProfile())
                let isPlausibleFallSpeed = fallPolicy.fallDetectionEnabled
                    && metricsAccumulator.currentSpeedKilometersPerHour <= fallPolicy.fallDetectionMaximumSpeedKmh
                guard isArmed && hasRideMotion && isPlausibleFallSpeed else {
                    activeFallEvent = nil
                    fallEventSubject.send(nil)
                    fallCountdownSubject.send(nil)
                    fallDetectionEngine.cancelFallAlert()
                    return
                }
                activeFallEvent = fallEvent
                fallEventSubject.send(fallEvent)
            }
            .store(in: &fallCancellables)

        fallDetectionEngine.countdownPublisher
            .sink { [weak self] seconds in self?.fallCountdownSubject.send(seconds) }
            .store(in: &fallCancellables)

        fallDetectionEngine.sosTriggerPublisher
            .sink { [weak self] fallEvent in
                guard let self else { return }
                guard activeFallEvent?.id == fallEvent.id else {
                    fallCountdownSubject.send(nil)
                    return
                }
                activeFallEvent = nil
                fallEventSubject.send(nil)
                fallCountdownSubject.send(nil)
                _ = dispatchSOS(source: SOSTriggerSource.fallCountdownExpired, fallEvent: fallEvent)
            }
            .store(in: &fallCancellables)
    }

    func handleMotionSample(_ sample: MotionSample) {
        guard stateMachine.status == .recording else { return }
        #if DEBUG
        if dataSource == .mock {
            mockSessionSamples.append(sample)
        }
        #endif
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordMotionSample(
            sample,
            sessionStatus: String(describing: stateMachine.status),
            isRecordingActive: stateMachine.status == .recording,
            runtime: makeDebugRuntimeSnapshot(scenePhase: nil)
        )
        #endif
        metricsAccumulator.process(sample)
        publishMetrics()
    }

    private func publishMetrics() {
        metricsSubject.send(metricsAccumulator.makeLiveMetrics())
    }

    func publishError(_ key: String) {
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

        let liveSummaryMetrics = metricsAccumulator.makeSummaryMetrics()
        let endDate = Date()
        let fallEvents = sessionScopedFallEvents(
            fallDetectionEngine.detectedFallEvents,
            startDate: sessionStartDate,
            endDate: endDate
        )

        let baseSession: SessionData
        if discard {
            baseSession = makeDiscardedSessionData(endDate: endDate, summaryMetrics: liveSummaryMetrics, fallEvents: fallEvents)
        } else {
            #if DEBUG
            if dataSource == .mock {
                baseSession = makeMockSessionData(endDate: endDate, summaryMetrics: liveSummaryMetrics, fallEvents: fallEvents)
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
            liveSummaryMetrics: liveSummaryMetrics
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
        liveSummaryMetrics: SessionSummaryMetrics
    ) -> SessionData {
        let routeQualitySummary = RouteQualitySummary.make(from: session.motionSamples)
        let summaryMetrics = reconciledSummaryMetrics(
            liveSummaryMetrics,
            routeQualitySummary: routeQualitySummary,
            samples: session.motionSamples
        )

        #if DEBUG
        let debugRecordingDiagnostics = RecordingDebugDiagnosticsCollector.shared.finishSession(
            endDate: endDate,
            samples: session.motionSamples
        )
        #else
        let debugRecordingDiagnostics = makeDiagnosticsDisabledByBuildConfiguration(
            session: session,
            endDate: endDate
        )
        #endif

        return try! SessionData(
            id: session.id,
            startDate: session.startDate,
            endDate: endDate,
            sportMode: session.sportMode,
            powerType: powerType,
            motionSamples: session.motionSamples,
            trickEvents: session.trickEvents,
            fallEvents: fallEvents,
            summaryMetrics: summaryMetrics,
            routeQualitySummary: routeQualitySummary,
            fidelityProfile: currentFidelityProfile(),
            debugRecordingDiagnostics: debugRecordingDiagnostics,
            equipmentID: selectedEquipmentID,
            equipmentSnapshot: selectedEquipmentSnapshot,
            spotID: selectedSpotID ?? session.spotID,
            spotSnapshot: selectedSpotSnapshot ?? session.spotSnapshot
        )
    }


    private func makeDiagnosticsDisabledByBuildConfiguration(
        session: SessionData,
        endDate: Date
    ) -> RecordingDebugDiagnostics {
        RecordingDebugDiagnostics(
            buildIdentity: RecordingDebugBuildIdentity(
                debugBuildTaskID: RecordingDebugBuildIdentity.currentDebugBuildTaskID,
                gitBranchName: "task-030c-gps-route-fidelity",
                diagnosticsSchemaVersion: 1,
                appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
                platform: "iOS",
                osVersionMajorMinor: ProcessInfo.processInfo.operatingSystemVersionString
            ),
            testContext: RecordingDebugTestContext(label: .unspecified),
            diagnosticsStartedAt: session.startDate,
            diagnosticsEndedAt: endDate,
            diagnosticsStatus: "disabledByBuildConfiguration",
            filterDecisionSummary: RecordingDebugFilterDecisionSummary(),
            altitudeDiagnostics: RecordingDebugAltitudeDiagnostics()
        )
    }

    private func sessionScopedFallEvents(
        _ fallEvents: [FallEvent],
        startDate: Date?,
        endDate: Date
    ) -> [FallEvent] {
        guard let startDate else { return [] }
        return fallEvents.filter { event in
            let elapsedAfterStart = event.timestamp.timeIntervalSince(startDate)
            return event.timestamp >= startDate
                && event.timestamp <= endDate
                && elapsedAfterStart >= Self.startupFallHandlingSuppressionSeconds
        }
    }

    private func reconciledSummaryMetrics(
        _ liveSummaryMetrics: SessionSummaryMetrics,
        routeQualitySummary: RouteQualitySummary,
        samples: [MotionSample]
    ) -> SessionSummaryMetrics {
        let profile = currentFidelityProfile(observedSamples: samples)
        let policy = ActivityFidelityPolicy(profile: profile)
        let routeDistanceKilometers = trustedRouteDistanceKilometers(from: samples, policy: policy)
        let distanceKilometers = routeDistanceKilometers > 0 ? routeDistanceKilometers : liveSummaryMetrics.distanceKilometers
        let plausibleSpeeds = samples
            .filter { isTrustedSummarySpeedSample($0, policy: policy) }
            .map(\.speedKmh)
        let maxSpeed = plausibleSpeeds.max() ?? 0
        let averageSpeed = plausibleSpeeds.isEmpty
            ? 0
            : plausibleSpeeds.reduce(0, +) / Double(plausibleSpeeds.count)
        let elevationGain = trustedElevationGainMeters(from: samples, policy: policy, fallback: liveSummaryMetrics.elevationGainMeters)

        return SessionSummaryMetrics(
            distanceKilometers: distanceKilometers,
            maxSpeedKilometersPerHour: maxSpeed,
            averageSpeedKilometersPerHour: averageSpeed,
            elevationGainMeters: elevationGain,
            movingRatio: liveSummaryMetrics.movingRatio
        )
    }


    private func isTrustedSummarySpeedSample(_ sample: MotionSample, policy: ActivityFidelityPolicy) -> Bool {
        guard sample.speedKmh.isFinite, sample.speedKmh >= 0 else { return false }
        if sample.sampleSource == .debugSimulated { return policy.acceptsSpeed(sample.speedKmh) }
        guard let diagnostics = sample.locationDiagnostics else { return policy.acceptsSpeed(sample.speedKmh) }
        guard diagnostics.routeSegmentConfidence != .low,
              diagnostics.routeSegmentConfidence != .unavailable else { return false }
        guard policy.acceptsLowSpeedMetricSample(
            speedKmh: sample.speedKmh,
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            speedAccuracyMetersPerSecond: diagnostics.speedAccuracyMetersPerSecond,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters
        ) else { return false }
        return policy.trustsRouteSegment(
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            freshnessState: diagnostics.freshnessState,
            updateIntervalSeconds: diagnostics.gpsUpdateIntervalSeconds,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh
        )
    }

    private func trustedRouteDistanceKilometers(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double {
        let sortedSamples = samples
            .filter { $0.gpsCoordinate != nil }
            .sorted { lhs, rhs in
                (lhs.locationDiagnostics?.rawLocationTimestamp ?? lhs.timestamp) <
                    (rhs.locationDiagnostics?.rawLocationTimestamp ?? rhs.timestamp)
            }
        var seenFixes = Set<String>()
        var distanceMeters = 0.0
        var previousCoordinate: GeoCoordinate?
        var previousTimestamp: Date?

        for sample in sortedSamples {
            guard let coordinate = sample.gpsCoordinate else { continue }
            let timestamp = sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
            let fixKey = "\(sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 ?? sample.timestampMillisecondsSince1970 ?? Int64(timestamp.timeIntervalSince1970 * 1_000))-\(coordinate.latitude)-\(coordinate.longitude)"
            guard seenFixes.insert(fixKey).inserted else { continue }

            guard let lastCoordinate = previousCoordinate, let lastTimestamp = previousTimestamp else {
                previousCoordinate = coordinate
                previousTimestamp = timestamp
                continue
            }

            let interval = max(timestamp.timeIntervalSince(lastTimestamp), 0)
            let segmentDistanceMeters = haversineDistanceMeters(from: lastCoordinate, to: coordinate)
            let impliedSpeedKmh = interval > 0 ? (segmentDistanceMeters / interval) * 3.6 : 0
            let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
            let isTrusted = confidence != .low
                && confidence != .unavailable
                && interval <= policy.maximumTrustedUpdateIntervalSeconds
                && segmentDistanceMeters <= policy.maximumTrustedSegmentDistanceMeters
                && impliedSpeedKmh <= policy.maximumTrustedImpliedSpeedKmh
                && policy.acceptsLowSpeedMetricSample(
                    speedKmh: sample.speedKmh,
                    horizontalAccuracyMeters: sample.locationDiagnostics?.horizontalAccuracyMeters,
                    speedAccuracyMetersPerSecond: sample.locationDiagnostics?.speedAccuracyMetersPerSecond,
                    coordinateDerivedSpeedKmh: sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? impliedSpeedKmh,
                    segmentDistanceMeters: segmentDistanceMeters
                )

            if isTrusted {
                distanceMeters += segmentDistanceMeters
            }

            previousCoordinate = coordinate
            previousTimestamp = timestamp
        }

        return distanceMeters / 1_000
    }

    private func haversineDistanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let deltaLatitude = (end.latitude - start.latitude) * (.pi / 180)
        let deltaLongitude = (end.longitude - start.longitude) * (.pi / 180)
        let startLatitude = start.latitude * (.pi / 180)
        let endLatitude = end.latitude * (.pi / 180)
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusMeters * centralAngle
    }

    private func currentFidelityProfile(observedSamples: [MotionSample] = []) -> ActivityFidelityProfile {
        let baseProfile = ActivityFidelityProfile.defaultProfile(
            for: selectedSportMode ?? .skateboard(.streetPark),
            powerType: selectedPowerType
        )
        let maxObservedSpeed = observedSamples.map(\.speedKmh).filter { $0.isFinite }.max() ?? metricsAccumulator.currentSpeedKilometersPerHour
        if selectedPowerType == .humanPowered, maxObservedSpeed > ActivityFidelityPolicy(profile: baseProfile).chartMaximumSpeedKmh + 20 {
            return .vehicleValidation
        }
        return baseProfile
    }

    private func trustedElevationGainMeters(
        from samples: [MotionSample],
        policy: ActivityFidelityPolicy,
        fallback: Double
    ) -> Double {
        let sortedSamples = samples.sorted(by: { $0.timestamp < $1.timestamp })
        let hasBarometerSamples = sortedSamples.contains { $0.altitudeSource == .barometerRelative }
        let barometerGain = trustedBarometerElevationGainMeters(from: sortedSamples, policy: policy)
        if hasBarometerSamples { return barometerGain }

        let coreLocationGain = trustedCoreLocationElevationGainMeters(from: sortedSamples, policy: policy)
        if coreLocationGain > 0 { return coreLocationGain }

        let hasAltitudeSamples = sortedSamples.contains { $0.altitudeMeters != nil }
        return hasAltitudeSamples ? 0 : min(max(fallback, 0), policy.maximumElevationStepMeters)
    }

    private func trustedBarometerElevationGainMeters(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double {
        var lastAltitude: Double?
        var gain = 0.0
        for sample in samples where sample.altitudeSource == .barometerRelative {
            guard let altitude = sample.altitudeMeters, altitude.isFinite else { continue }
            defer { lastAltitude = altitude }
            guard let previousAltitude = lastAltitude else { continue }
            let delta = altitude - previousAltitude
            guard delta > 0.03, delta <= min(policy.maximumElevationStepMeters, 1.0) else { continue }
            gain += delta
        }
        return gain
    }

    private func trustedCoreLocationElevationGainMeters(from samples: [MotionSample], policy: ActivityFidelityPolicy) -> Double {
        var lastAltitude: Double?
        var gain = 0.0
        let firstTimestamp = samples.first?.timestamp
        for sample in samples where sample.altitudeSource == .coreLocationAbsolute || sample.altitudeSource == .debugSimulated {
            guard let altitude = sample.altitudeMeters, altitude.isFinite else { continue }
            if sample.altitudeSource == .debugSimulated {
                defer { lastAltitude = altitude }
                guard let previousAltitude = lastAltitude else { continue }
                let delta = altitude - previousAltitude
                if delta > 0, delta <= policy.maximumElevationStepMeters { gain += delta }
                continue
            }
            guard let firstTimestamp,
                  sample.timestamp.timeIntervalSince(firstTimestamp) > 30 else { continue }
            defer { lastAltitude = altitude }
            guard let previousAltitude = lastAltitude else { continue }
            let delta = altitude - previousAltitude
            guard delta > 0 else { continue }
            let verticalAccuracy = sample.locationDiagnostics?.verticalAccuracyMeters
            let strictVerticalAccuracy = min(policy.maximumVerticalAccuracyMeters, 5)
            if let verticalAccuracy,
               verticalAccuracy <= strictVerticalAccuracy,
               delta <= min(policy.maximumElevationStepMeters, 1.0) {
                gain += delta
            }
        }
        return gain
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
            summaryMetrics: summaryMetrics,
            routeQualitySummary: RouteQualitySummary.make(from: [])
        )
    }

    private func makeMockSessionData(
        endDate: Date,
        summaryMetrics: SessionSummaryMetrics,
        fallEvents: [FallEvent]
    ) -> SessionData {
        let mode = selectedSportMode ?? .skateboard(.streetPark)
        let samples = mockSessionSamples
        return try! SessionData(
            startDate: sessionStartDate ?? endDate,
            endDate: endDate,
            sportMode: mode,
            powerType: selectedPowerType,
            motionSamples: samples,
            fallEvents: fallEvents,
            summaryMetrics: summaryMetrics,
            routeQualitySummary: RouteQualitySummary.make(from: samples)
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


    #if DEBUG
    private func startDebugLifecycleObservationIfNeeded() {
        guard debugLifecycleObservationTokens.isEmpty else { return }
        #if canImport(UIKit)
        let center = NotificationCenter.default
        let events: [(Notification.Name, String)] = [
            (UIApplication.willResignActiveNotification, "appWillResignActive"),
            (UIApplication.didEnterBackgroundNotification, "appDidEnterBackground"),
            (UIApplication.willEnterForegroundNotification, "appWillEnterForeground"),
            (UIApplication.didBecomeActiveNotification, "appDidBecomeActive"),
            (UIApplication.willTerminateNotification, "appWillTerminate"),
            (UIApplication.protectedDataWillBecomeUnavailableNotification, "protectedDataWillBecomeUnavailable"),
            (UIApplication.protectedDataDidBecomeAvailableNotification, "protectedDataDidBecomeAvailable")
        ]
        debugLifecycleObservationTokens = events.map { name, eventType in
            center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                RecordingDebugDiagnosticsCollector.shared.recordLifecycleEvent(
                    eventType,
                    runtime: self.makeDebugRuntimeSnapshot(scenePhase: nil)
                )
            }
        }
        #endif
    }

    private func stopDebugLifecycleObservation() {
        #if canImport(UIKit)
        debugLifecycleObservationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        #endif
        debugLifecycleObservationTokens.removeAll()
    }

    private func makeDebugRuntimeSnapshot(scenePhase: String?) -> RecordingDebugRuntimeSnapshot {
        let now = Date()
        let elapsed = sessionStartDate.map { now.timeIntervalSince($0) }
        #if canImport(UIKit)
        let application = UIApplication.shared
        return RecordingDebugRuntimeSnapshot(
            timestamp: now,
            secondsSinceSessionStart: elapsed,
            appState: Self.debugAppStateDescription(application.applicationState),
            scenePhase: scenePhase,
            isProtectedDataAvailable: application.isProtectedDataAvailable,
            backgroundRefreshStatus: Self.debugBackgroundRefreshDescription(application.backgroundRefreshStatus),
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermalState: Self.debugThermalStateDescription(ProcessInfo.processInfo.thermalState),
            isIdleTimerDisabled: application.isIdleTimerDisabled
        )
        #else
        return RecordingDebugRuntimeSnapshot(
            timestamp: now,
            secondsSinceSessionStart: elapsed,
            scenePhase: scenePhase,
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermalState: Self.debugThermalStateDescription(ProcessInfo.processInfo.thermalState)
        )
        #endif
    }

    #if canImport(UIKit)
    private static func debugAppStateDescription(_ state: UIApplication.State) -> String {
        switch state {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }

    private static func debugBackgroundRefreshDescription(_ status: UIBackgroundRefreshStatus) -> String {
        switch status {
        case .available: return "available"
        case .denied: return "denied"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }
    #endif

    private static func debugThermalStateDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
    #endif

    private func resetCoordinatorState() {
        #if DEBUG
        stopDebugLifecycleObservation()
        #endif
        selectedSportMode = nil
        selectedPowerType = .humanPowered
        selectedEquipmentID = nil
        selectedEquipmentSnapshot = nil
        selectedSpotID = nil
        selectedSpotSnapshot = nil
        sessionStartDate = nil
        activeFallEvent = nil
        metricsAccumulator.reset()
        mockSampleIndex = 0
        mockSessionSamples = []
    }

}

