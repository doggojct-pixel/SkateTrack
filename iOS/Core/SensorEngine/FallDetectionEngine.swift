// [自主區] iOS/Core/SensorEngine/FallDetectionEngine.swift
// 用途：監控 MotionSample 的 G 值尖峰與靜止模式，發布跌倒事件與 SOS 倒數事件。
// 委派至：Task-011 之後的跌倒警示 UI、watchOS SOS 流程與 session timeline。

import Combine
import Foundation

struct FallDetectionConfiguration: Sendable, Equatable {
    let impactThresholdG: Double
    let stationaryDurationSeconds: TimeInterval
    let stationaryBandAroundOneG: Double
    let stationaryGyroscopeThreshold: Double
    let stationarySpeedThresholdKmh: Double
    let sosCountdownSeconds: Int

    static let production = FallDetectionConfiguration(
        impactThresholdG: 4,
        stationaryDurationSeconds: 3,
        stationaryBandAroundOneG: 0.35,
        stationaryGyroscopeThreshold: 0.25,
        stationarySpeedThresholdKmh: 1,
        sosCountdownSeconds: 15
    )

    #if DEBUG
    static let debugSensitive = FallDetectionConfiguration(
        impactThresholdG: 1.8,
        stationaryDurationSeconds: 1,
        stationaryBandAroundOneG: 0.5,
        stationaryGyroscopeThreshold: 0.4,
        stationarySpeedThresholdKmh: 2,
        sosCountdownSeconds: 15
    )
    #endif

    static var defaultForCurrentBuild: FallDetectionConfiguration {
        #if DEBUG
        return .debugSensitive
        #else
        return .production
        #endif
    }
}

enum FallDetectionState: Equatable, Sendable {
    case idle
    case monitoring
    case impactCandidate(peakG: Double)
    case alertCountdown(secondsRemaining: Int)
    case cancelled
    case sosTriggered
}

final class FallDetectionEngine {
    private let configuration: FallDetectionConfiguration
    private let stateSubject = CurrentValueSubject<FallDetectionState, Never>(.idle)
    private let fallEventSubject = PassthroughSubject<FallEvent, Never>()
    private let sosTriggerSubject = PassthroughSubject<FallEvent, Never>()
    private let countdownSubject = CurrentValueSubject<Int?, Never>(nil)

    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: DispatchSourceTimer?
    private var activeMode: SportMode?
    private var impactStartDate: Date?
    private var stationaryStartDate: Date?
    private var peakImpactG: Double = 0
    private var latestCoordinate: GeoCoordinate?
    private var pendingFallEvent: FallEvent?

    private(set) var detectedFallEvents: [FallEvent] = []

    var statePublisher: AnyPublisher<FallDetectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var fallEventPublisher: AnyPublisher<FallEvent, Never> {
        fallEventSubject.eraseToAnyPublisher()
    }

    var sosTriggerPublisher: AnyPublisher<FallEvent, Never> {
        sosTriggerSubject.eraseToAnyPublisher()
    }

    var countdownPublisher: AnyPublisher<Int?, Never> {
        countdownSubject.eraseToAnyPublisher()
    }

    init(configuration: FallDetectionConfiguration = .defaultForCurrentBuild) {
        self.configuration = configuration
    }

    func startMonitoring(
        samples: AnyPublisher<MotionSample, Never>,
        mode: SportMode
    ) {
        stopMonitoring()
        activeMode = mode
        stateSubject.send(.monitoring)

        samples
            .sink { [weak self] sample in
                self?.process(sample)
            }
            .store(in: &cancellables)
    }

    func stopMonitoring() {
        cancellables.removeAll()
        cancelCountdownTimer()
        activeMode = nil
        resetCandidateState()
        stateSubject.send(.idle)
    }

    func cancelFallAlert() {
        cancelCountdownTimer()
        pendingFallEvent = nil
        countdownSubject.send(nil)
        stateSubject.send(.cancelled)
        resetCandidateState()
    }

    private func process(_ sample: MotionSample) {
        latestCoordinate = sample.gpsCoordinate

        let impactG = sample.accelerometerG.magnitude
        if impactG >= configuration.impactThresholdG {
            registerImpactCandidate(impactG: impactG, sample: sample)
            return
        }

        guard impactStartDate != nil else { return }
        evaluatePostImpactStationaryState(sample: sample)
    }

    private func registerImpactCandidate(impactG: Double, sample: MotionSample) {
        if impactStartDate == nil {
            impactStartDate = sample.timestamp
            stationaryStartDate = nil
        }

        peakImpactG = max(peakImpactG, impactG)
        stateSubject.send(.impactCandidate(peakG: peakImpactG))
    }

    private func evaluatePostImpactStationaryState(sample: MotionSample) {
        guard isStationary(sample) else {
            stationaryStartDate = nil
            return
        }

        if stationaryStartDate == nil {
            stationaryStartDate = sample.timestamp
        }

        guard let stationaryStartDate else { return }
        let stationaryDuration = sample.timestamp.timeIntervalSince(stationaryStartDate)

        if stationaryDuration >= configuration.stationaryDurationSeconds {
            publishFallEvent(recoveryDuration: stationaryDuration, sample: sample)
        }
    }

    private func isStationary(_ sample: MotionSample) -> Bool {
        let accelerationMagnitude = sample.accelerometerG.magnitude
        let gyroMagnitude = sample.gyroscopeRadPS.magnitude
        let isNearGravity = abs(accelerationMagnitude - 1) <= configuration.stationaryBandAroundOneG
        let hasLowRotation = gyroMagnitude <= configuration.stationaryGyroscopeThreshold
        let hasLowSpeed = sample.speedKmh <= configuration.stationarySpeedThresholdKmh
        return isNearGravity && hasLowRotation && hasLowSpeed
    }

    private func publishFallEvent(recoveryDuration: TimeInterval, sample: MotionSample) {
        guard pendingFallEvent == nil else { return }

        let fallEvent = FallEvent(
            timestamp: impactStartDate ?? sample.timestamp,
            peakImpactGForce: peakImpactG,
            locationCoordinate: latestCoordinate,
            recoveryDurationSeconds: recoveryDuration,
            sportMode: activeMode,
            userConfirmed: false
        )

        detectedFallEvents.append(fallEvent)
        pendingFallEvent = fallEvent
        fallEventSubject.send(fallEvent)
        startSOSCountdown(for: fallEvent)
        resetCandidateState()
    }

    private func startSOSCountdown(for fallEvent: FallEvent) {
        cancelCountdownTimer()

        var secondsRemaining = configuration.sosCountdownSeconds
        countdownSubject.send(secondsRemaining)
        stateSubject.send(.alertCountdown(secondsRemaining: secondsRemaining))

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }

            secondsRemaining -= 1
            countdownSubject.send(max(secondsRemaining, 0))

            if secondsRemaining <= 0 {
                triggerSOS(for: fallEvent)
            } else {
                stateSubject.send(.alertCountdown(secondsRemaining: secondsRemaining))
            }
        }

        countdownTimer = timer
        timer.resume()
    }

    private func triggerSOS(for fallEvent: FallEvent) {
        cancelCountdownTimer()
        pendingFallEvent = nil
        countdownSubject.send(nil)
        stateSubject.send(.sosTriggered)
        sosTriggerSubject.send(fallEvent)
    }

    private func cancelCountdownTimer() {
        countdownTimer?.cancel()
        countdownTimer = nil
    }

    private func resetCandidateState() {
        impactStartDate = nil
        stationaryStartDate = nil
        peakImpactG = 0
    }
}
