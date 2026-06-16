// [自主區] iOS/Core/SensorEngine/SensorFusionEngine.swift
// 用途：將 GPS、IMU 與氣壓計資料融合為 10Hz MotionSample 串流。
// 委派至：Session Recording、Live HUD、FallDetectionEngine 與後續資料管線。

import Combine
import CoreLocation
import Foundation

enum SensorFusionEngineError: Error, Sendable {
    case sessionAlreadyRunning
}

final class SensorFusionEngine: SensorProvider {
    static let sampleFrequencyHz: Double = 10
    static let sampleIntervalSeconds: TimeInterval = 1 / sampleFrequencyHz
    private static let startupStabilizationSeconds: TimeInterval = 8
    private static let startupCoordinateDerivedSpeedSpikeKmh: Double = 18
    private static let lowSpeedLocalJumpKmh: Double = 18
    private static let lowSpeedSuspiciousCoreLocationSpeedKmh: Double = 6
    private let gpsProvider: GPSProvider
    private let imuProvider: IMUProvider
    private let barometerProvider: BarometerProvider
    private let calibrationEngine: SensorCalibrationEngine
    private let sampleQueue = DispatchQueue(label: "com.jjf.skateTrack.sensorFusionEngine")
    private let stateLock = NSLock()
    private let motionSampleSubject = PassthroughSubject<MotionSample, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var sampleTimer: DispatchSourceTimer?

    private var currentMode: SportMode?
    private var currentPriorityPlan: SensorFusionPriorityPlan?
    private var sessionStartDate: Date?
    private var sessionSamples: [MotionSample] = []
    private var latestCoordinate: GeoCoordinate?
    private var latestSpeedKmh: Double = 0
    private var latestAcceleration = ThreeAxisValue.zero
    private var latestGyroscope = ThreeAxisValue.zero
    private var latestAltitudeMeters: Double?
    private var latestLocationDiagnostics: LocationFixDiagnostics?
    private var latestRawLocation: CLLocation?
    var motionSamplePublisher: AnyPublisher<MotionSample, Never> {
        motionSampleSubject.eraseToAnyPublisher()
    }
    init(
        gpsProvider: GPSProvider = GPSProvider(),
        imuProvider: IMUProvider = IMUProvider(),
        barometerProvider: BarometerProvider = BarometerProvider(),
        calibrationEngine: SensorCalibrationEngine = SensorCalibrationEngine()
    ) {
        self.gpsProvider = gpsProvider
        self.imuProvider = imuProvider
        self.barometerProvider = barometerProvider
        self.calibrationEngine = calibrationEngine
    }

    func startSession(mode: SportMode) async throws {
        let alreadyRunning = stateLock.withLock {
            sessionStartDate != nil
        }

        guard !alreadyRunning else {
            throw SensorFusionEngineError.sessionAlreadyRunning
        }

        resetSessionState(mode: mode)
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
            RecordingDebugRecoveryEvent(
                eventType: "sensorFusionStartSession",
                reason: "startSession"
            )
        )
        #endif
        bindProviderStreams()
        startProviderUpdates(for: mode)
        startSampleTimer()
    }

    func stopSession() async -> SessionData {
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
            RecordingDebugRecoveryEvent(
                eventType: "sensorFusionStopSession",
                reason: "stopSession"
            )
        )
        #endif
        stopSampleTimer()
        stopProviderUpdates()
        cancellables.removeAll()

        let snapshot = sessionSnapshot()
        resetTransientState()

        return try! SessionData(
            startDate: snapshot.startDate,
            endDate: Date(),
            sportMode: snapshot.mode,
            motionSamples: snapshot.samples
        )
    }

    func startRecording(mode: SportMode) async throws {
        try await startSession(mode: mode)
    }

    func stopRecording() async -> SessionData {
        await stopSession()
    }

    func priorityPlan(for mode: SportMode) -> SensorFusionPriorityPlan {
        calibrationEngine.priorityPlan(for: mode)
    }
    private func resetSessionState(mode: SportMode) {
        stateLock.withLock {
            currentMode = mode
            currentPriorityPlan = calibrationEngine.priorityPlan(for: mode)
            sessionStartDate = Date()
            sessionSamples = []
            latestCoordinate = nil
            latestSpeedKmh = 0
            latestAcceleration = .zero
            latestGyroscope = .zero
            latestAltitudeMeters = nil
            latestLocationDiagnostics = nil
            latestRawLocation = nil
            calibrationEngine.reset()
        }
    }
    private func bindProviderStreams() {
        cancellables.removeAll()

        gpsProvider.locationPublisher
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)

        gpsProvider.speedKilometersPerHourPublisher
            .sink { [weak self] speedKmh in
                self?.updateSpeed(speedKmh)
            }
            .store(in: &cancellables)

        imuProvider.accelerationVectorPublisher
            .sink { [weak self] acceleration in
                self?.updateAcceleration(acceleration)
            }
            .store(in: &cancellables)

        imuProvider.gyroscopeVectorPublisher
            .sink { [weak self] gyroscope in
                self?.updateGyroscope(gyroscope)
            }
            .store(in: &cancellables)

        barometerProvider.relativeAltitudeMetersPublisher
            .sink { [weak self] altitude in
                self?.updateAltitude(altitude)
            }
            .store(in: &cancellables)
    }
    private func startProviderUpdates(for mode: SportMode) {
        let plan = calibrationEngine.priorityPlan(for: mode)
        let routeTrackingChannels = plan.primary + plan.secondary + plan.supplemental
        let gpsMode: GPSAccuracyMode = routeTrackingChannels.contains(.gps) ? .activeRide : .stationaryPowerSaving

        gpsProvider.startUpdatingLocation(accuracyMode: gpsMode)
        imuProvider.startUpdates()
        barometerProvider.startUpdates()
    }
    private func stopProviderUpdates() {
        gpsProvider.stopUpdatingLocation()
        imuProvider.stopUpdates()
        barometerProvider.stopUpdates()
    }
    private func startSampleTimer() {
        let timer = DispatchSource.makeTimerSource(queue: sampleQueue)
        timer.schedule(deadline: .now(), repeating: Self.sampleIntervalSeconds)
        timer.setEventHandler { [weak self] in
            self?.publishCurrentMotionSample()
        }
        sampleTimer = timer
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
            RecordingDebugRecoveryEvent(
                eventType: "recordingSampleTimerStarted",
                reason: "startSampleTimer"
            )
        )
        #endif
        timer.resume()
    }
    private func stopSampleTimer() {
        sampleTimer?.cancel()
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
            RecordingDebugRecoveryEvent(
                eventType: "recordingSampleTimerStopped",
                reason: "stopSampleTimer"
            )
        )
        #endif
        sampleTimer = nil
    }
    private func publishCurrentMotionSample() {
        let sample = makeMotionSample()

        stateLock.withLock {
            sessionSamples.append(sample)
        }

        motionSampleSubject.send(sample)
    }
    private func makeMotionSample() -> MotionSample {
        let snapshot = stateLock.withLock { () -> (
            coordinate: GeoCoordinate?,
            speedKmh: Double,
            acceleration: ThreeAxisValue,
            gyroscope: ThreeAxisValue,
            altitude: Double?,
            locationDiagnostics: LocationFixDiagnostics?,
            calibratedAcceleration: ThreeAxisValue,
            calibratedGyroscope: ThreeAxisValue
        ) in
            let coordinate = latestCoordinate
            let speedKmh = latestSpeedKmh
            let acceleration = latestAcceleration
            let gyroscope = latestGyroscope
            let altitude = latestAltitudeMeters
            let locationDiagnostics = latestLocationDiagnostics
            calibrationEngine.ingest(acceleration: acceleration, gyroscope: gyroscope)
            let calibratedAcceleration = calibrationEngine.calibratedAcceleration(from: acceleration)
            let calibratedGyroscope = calibrationEngine.calibratedGyroscope(from: gyroscope)

            return (
                coordinate,
                speedKmh,
                acceleration,
                gyroscope,
                altitude,
                locationDiagnostics,
                calibratedAcceleration,
                calibratedGyroscope
            )
        }

        return MotionSample(
            timestamp: Date(),
            gpsCoordinate: snapshot.coordinate,
            speedKmh: snapshot.speedKmh,
            accelerometerG: snapshot.calibratedAcceleration,
            gyroscopeRadPS: snapshot.calibratedGyroscope,
            altitudeMeters: snapshot.altitude,
            altitudeSource: snapshot.altitude == nil ? nil : .barometerRelative,
            locationDiagnostics: snapshot.locationDiagnostics,
            sampleSource: .timerFusion
        )
    }
    private func updateLocation(_ location: CLLocation) {
        let receivedAt = Date()
        let stateSnapshot = stateLock.withLock { (
            previousLocation: latestRawLocation,
            sessionStartDate: sessionStartDate
        ) }
        let diagnostics = makeLocationDiagnostics(
            for: location,
            previousLocation: stateSnapshot.previousLocation,
            sessionStartDate: stateSnapshot.sessionStartDate,
            receivedAt: receivedAt
        )

        stateLock.withLock {
            latestRawLocation = location
            latestLocationDiagnostics = diagnostics

            if Self.trustsLocationForLiveRoute(diagnostics) {
                latestCoordinate = GeoCoordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )

                if location.speed >= 0 {
                    latestSpeedKmh = GPSProvider.kilometersPerHour(fromMetersPerSecond: location.speed)
                } else if let coordinateDerivedSpeedKmh = diagnostics.coordinateDerivedSpeedKmh {
                    latestSpeedKmh = coordinateDerivedSpeedKmh
                }
            } else {
                latestSpeedKmh = 0
            }
        }
        publishRawLocationFixMotionSample(for: location, diagnostics: diagnostics)
    }
    private func publishRawLocationFixMotionSample(for location: CLLocation, diagnostics: LocationFixDiagnostics) {
        let sample = stateLock.withLock { () -> MotionSample? in
            guard sessionStartDate != nil else { return nil }
            let coordinate = GeoCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let trustedForLiveRoute = Self.trustsLocationForLiveRoute(diagnostics)
            let speedKmh = trustedForLiveRoute
                ? (location.speed >= 0
                    ? GPSProvider.kilometersPerHour(fromMetersPerSecond: location.speed)
                    : (diagnostics.coordinateDerivedSpeedKmh ?? latestSpeedKmh))
                : 0
            let sample = MotionSample(
                timestamp: location.timestamp,
                timestampMillisecondsSince1970: location.timestamp.millisecondsSince1970,
                gpsCoordinate: coordinate,
                speedKmh: max(speedKmh, 0),
                accelerometerG: calibrationEngine.calibratedAcceleration(from: latestAcceleration),
                gyroscopeRadPS: calibrationEngine.calibratedGyroscope(from: latestGyroscope),
                altitudeMeters: normalizedAltitude(from: location),
                altitudeSource: normalizedAltitude(from: location) == nil ? nil : .coreLocationAbsolute,
                locationDiagnostics: diagnostics,
                sampleSource: .locationFix
            )
            sessionSamples.append(sample)
            return sample
        }
        if let sample {
            motionSampleSubject.send(sample)
        }
    }
    private func makeLocationDiagnostics(
        for location: CLLocation,
        previousLocation: CLLocation?,
        sessionStartDate: Date?,
        receivedAt: Date
    ) -> LocationFixDiagnostics {
        let updateInterval = previousLocation.flatMap { previous -> TimeInterval? in
            let interval = location.timestamp.timeIntervalSince(previous.timestamp)
            return interval > 0 ? interval : nil
        }
        let segmentDistance = previousLocation.map { location.distance(from: $0) }
        let rawCoordinateDerivedSpeedKmh = makeCoordinateDerivedSpeedKmh(
            segmentDistanceMeters: segmentDistance,
            updateIntervalSeconds: updateInterval
        )
        let freshnessState = locationFreshnessState(for: location, receivedAt: receivedAt)
        let horizontalAccuracy = normalizedAccuracy(location.horizontalAccuracy)
        let coreLocationSpeedKmh = location.speed >= 0
            ? GPSProvider.kilometersPerHour(fromMetersPerSecond: location.speed)
            : nil
        let isStartupSpeedSpike = isStartupCoordinateDerivedSpeedSpike(
            coordinateDerivedSpeedKmh: rawCoordinateDerivedSpeedKmh,
            sessionStartDate: sessionStartDate,
            receivedAt: receivedAt
        )
        let isLowSpeedLocalJump = isLowSpeedLocalMetricOutlier(
            coreLocationSpeedKmh: coreLocationSpeedKmh,
            coordinateDerivedSpeedKmh: rawCoordinateDerivedSpeedKmh,
            horizontalAccuracyMeters: horizontalAccuracy,
            speedAccuracyMetersPerSecond: normalizedAccuracy(location.speedAccuracy),
            segmentDistanceMeters: segmentDistance
        )
        let coordinateDerivedSpeedKmh = (isStartupSpeedSpike || isLowSpeedLocalJump) ? nil : rawCoordinateDerivedSpeedKmh
        let speedSource = locationSpeedSource(
            location: location,
            freshnessState: freshnessState,
            coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh
        )
        let confidence = (isStartupSpeedSpike || isLowSpeedLocalJump)
            ? RouteSegmentConfidence.low
            : routeSegmentConfidence(
                horizontalAccuracyMeters: horizontalAccuracy,
                freshnessState: freshnessState,
                updateIntervalSeconds: updateInterval,
                segmentDistanceMeters: segmentDistance,
                coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh,
                profile: currentActivityFidelityProfile()
            )

        return LocationFixDiagnostics(
            horizontalAccuracyMeters: horizontalAccuracy,
            verticalAccuracyMeters: normalizedAccuracy(location.verticalAccuracy),
            speedAccuracyMetersPerSecond: normalizedAccuracy(location.speedAccuracy),
            courseAccuracyDegrees: courseAccuracyDegrees(for: location),
            rawLocationTimestamp: location.timestamp,
            rawLocationTimestampMillisecondsSince1970: location.timestamp.millisecondsSince1970,
            receivedAtTimestamp: receivedAt,
            receivedAtTimestampMillisecondsSince1970: receivedAt.millisecondsSince1970,
            gpsUpdateIntervalSeconds: updateInterval,
            gpsSegmentDistanceMeters: segmentDistance,
            coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh,
            speedSource: speedSource,
            freshnessState: freshnessState,
            routeSegmentConfidence: confidence
        )
    }
    private static func trustsLocationForLiveRoute(_ diagnostics: LocationFixDiagnostics) -> Bool {
        guard diagnostics.routeSegmentConfidence != .low,
              diagnostics.routeSegmentConfidence != .unavailable else { return false }
        let policy = ActivityFidelityPolicy(profile: .standardSkateboard)
        return policy.trustsRouteSegment(
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            freshnessState: diagnostics.freshnessState,
            updateIntervalSeconds: diagnostics.gpsUpdateIntervalSeconds,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh
        )
    }
    private func normalizedAltitude(from location: CLLocation) -> Double? {
        location.verticalAccuracy >= 0 && location.altitude.isFinite ? location.altitude : nil
    }
    private func makeCoordinateDerivedSpeedKmh(
        segmentDistanceMeters: Double?,
        updateIntervalSeconds: TimeInterval?
    ) -> Double? {
        guard let segmentDistanceMeters, segmentDistanceMeters >= 1 else { return nil }
        guard let updateIntervalSeconds, updateIntervalSeconds >= 0.5 else { return nil }
        let speedKmh = (segmentDistanceMeters / updateIntervalSeconds) * 3.6
        guard speedKmh <= ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh else { return nil }
        return max(speedKmh, 0)
    }
    private func isStartupCoordinateDerivedSpeedSpike(
        coordinateDerivedSpeedKmh: Double?,
        sessionStartDate: Date?,
        receivedAt: Date
    ) -> Bool {
        guard let coordinateDerivedSpeedKmh,
              coordinateDerivedSpeedKmh >= Self.startupCoordinateDerivedSpeedSpikeKmh,
              let sessionStartDate else { return false }
        let elapsed = receivedAt.timeIntervalSince(sessionStartDate)
        return elapsed >= 0 && elapsed <= Self.startupStabilizationSeconds
    }
    private func isLowSpeedLocalMetricOutlier(
        coreLocationSpeedKmh: Double?,
        coordinateDerivedSpeedKmh: Double?,
        horizontalAccuracyMeters: Double?,
        speedAccuracyMetersPerSecond: Double?,
        segmentDistanceMeters: Double?
    ) -> Bool {
        let policy = ActivityFidelityPolicy(profile: currentActivityFidelityProfile())
        let speedKmh = coreLocationSpeedKmh ?? coordinateDerivedSpeedKmh ?? 0
        guard speedKmh > 0 else { return false }
        if speedKmh >= Self.lowSpeedSuspiciousCoreLocationSpeedKmh {
            return !policy.acceptsLowSpeedMetricSample(
                speedKmh: speedKmh,
                horizontalAccuracyMeters: horizontalAccuracyMeters,
                speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
                coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh,
                segmentDistanceMeters: segmentDistanceMeters
            )
        }
        if let coordinateDerivedSpeedKmh, coordinateDerivedSpeedKmh >= Self.lowSpeedLocalJumpKmh {
            return !policy.acceptsLowSpeedMetricSample(
                speedKmh: speedKmh,
                horizontalAccuracyMeters: horizontalAccuracyMeters,
                speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
                coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh,
                segmentDistanceMeters: segmentDistanceMeters
            )
        }
        return false
    }
    private func locationFreshnessState(for location: CLLocation, receivedAt: Date) -> LocationFreshnessState {
        let age = max(receivedAt.timeIntervalSince(location.timestamp), 0)
        if age <= 2 { return .fresh }
        if age <= 5 { return .recent }
        return .stale
    }
    private func locationSpeedSource(
        location: CLLocation,
        freshnessState: LocationFreshnessState,
        coordinateDerivedSpeedKmh: Double?
    ) -> LocationSpeedSource {
        if freshnessState == .stale { return .stale }
        if location.speed >= 0 { return .coreLocation }
        if coordinateDerivedSpeedKmh != nil { return .coordinateDerived }
        return .unavailable
    }
    private func routeSegmentConfidence(
        horizontalAccuracyMeters: Double?,
        freshnessState: LocationFreshnessState,
        updateIntervalSeconds: TimeInterval?,
        segmentDistanceMeters: Double?,
        coordinateDerivedSpeedKmh: Double?,
        profile: ActivityFidelityProfile
    ) -> RouteSegmentConfidence {
        guard freshnessState != .unavailable else { return .unavailable }
        guard freshnessState != .stale, let horizontalAccuracyMeters else { return .low }
        let policy = ActivityFidelityPolicy(profile: profile)
        // Compatibility verify token: policy.maximumTrustedSegmentDistanceMeters
        guard policy.trustsRouteSegment(
            horizontalAccuracyMeters: horizontalAccuracyMeters,
            freshnessState: freshnessState,
            updateIntervalSeconds: updateIntervalSeconds,
            segmentDistanceMeters: segmentDistanceMeters,
            coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh
        ) else { return .low }
        if horizontalAccuracyMeters <= policy.preferredHorizontalAccuracyMeters { return .high }
        if horizontalAccuracyMeters <= policy.maximumUsableHorizontalAccuracyMeters { return .medium }
        return .low
    }
    private func currentActivityFidelityProfile() -> ActivityFidelityProfile {
        stateLock.withLock {
            switch currentMode ?? .skateboard(.streetPark) {
            case .skateboard(.surfskate): return .technicalSkateboard
            case .skateboard: return .standardSkateboard
            case .inline(.fitnessSpeed): return .inlineSpeed
            case .inline: return .inlineRecreation
            }
        }
    }
    private func normalizedAccuracy(_ accuracy: CLLocationAccuracy) -> Double? {
        accuracy >= 0 ? accuracy : nil
    }
    private func courseAccuracyDegrees(for location: CLLocation) -> Double? {
        if #available(iOS 13.4, *) {
            return normalizedAccuracy(location.courseAccuracy)
        }
        return nil
    }
    private func updateSpeed(_ speedKmh: Double) {
        stateLock.withLock {
            if latestLocationDiagnostics?.routeSegmentConfidence == .low ||
                latestLocationDiagnostics?.routeSegmentConfidence == .unavailable {
                latestSpeedKmh = 0
            } else {
                latestSpeedKmh = speedKmh
            }
        }
    }
    private func updateAcceleration(_ acceleration: ThreeAxisValue) {
        stateLock.withLock {
            latestAcceleration = acceleration
        }
    }
    private func updateGyroscope(_ gyroscope: ThreeAxisValue) {
        stateLock.withLock {
            latestGyroscope = gyroscope
        }
    }
    private func updateAltitude(_ altitude: Double?) {
        stateLock.withLock {
            latestAltitudeMeters = altitude
        }
    }
    private func sessionSnapshot() -> (startDate: Date, mode: SportMode, samples: [MotionSample]) {
        stateLock.withLock {
            let startDate = sessionStartDate ?? Date()
            let mode = currentMode ?? .skateboard(.streetPark)
            let samples = sessionSamples
            return (startDate, mode, samples)
        }
    }
    private func resetTransientState() {
        stateLock.withLock {
            currentMode = nil
            currentPriorityPlan = nil
            sessionStartDate = nil
            latestCoordinate = nil
            latestSpeedKmh = 0
            latestAcceleration = .zero
            latestGyroscope = .zero
            latestAltitudeMeters = nil
            latestLocationDiagnostics = nil
            latestRawLocation = nil
        }
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1_000).rounded())
    }
}
