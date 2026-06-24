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
    private var currentPowerType: PowerType = .humanPowered
    private var currentFidelityProfileOverride: ActivityFidelityProfile?
    private var currentPriorityPlan: SensorFusionPriorityPlan?
    private var sessionStartDate: Date?
    private var sessionSamples: [MotionSample] = []
    private var latestCoordinate: GeoCoordinate?
    private var latestSpeedKmh: Double = 0
    private var latestAcceleration = ThreeAxisValue.zero
    private var latestGyroscope = ThreeAxisValue.zero
    private var latestAltitudeMeters: Double?
    private var altitudeOutlierGuard = AltitudeOutlierGuard()
    private var pressureFilter = AltitudePressureFilter()
    private var latestPressureDiagnostics: AltitudePressureDiagnostics?
    private var latestLocationDiagnostics: LocationFixDiagnostics?
    private var latestRawLocation: CLLocation?
    private var latestDeviceHeading: CLHeading?
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

    func startSession(
        mode: SportMode,
        powerType: PowerType = .humanPowered,
        fidelityProfile: ActivityFidelityProfile? = nil
    ) async throws {
        let alreadyRunning = stateLock.withLock {
            sessionStartDate != nil
        }

        guard !alreadyRunning else {
            throw SensorFusionEngineError.sessionAlreadyRunning
        }

        resetSessionState(mode: mode, powerType: powerType, fidelityProfile: fidelityProfile)
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
            powerType: snapshot.powerType,
            motionSamples: snapshot.samples,
            fidelityProfile: snapshot.fidelityProfile
        )
    }

    func startRecording(
        mode: SportMode,
        powerType: PowerType = .humanPowered,
        fidelityProfile: ActivityFidelityProfile? = nil
    ) async throws {
        try await startSession(mode: mode, powerType: powerType, fidelityProfile: fidelityProfile)
    }

    func stopRecording() async -> SessionData {
        await stopSession()
    }

    func priorityPlan(for mode: SportMode) -> SensorFusionPriorityPlan {
        calibrationEngine.priorityPlan(for: mode)
    }
    private func resetSessionState(mode: SportMode, powerType: PowerType, fidelityProfile: ActivityFidelityProfile?) {
        stateLock.withLock {
            currentMode = mode
            currentPowerType = powerType
            currentFidelityProfileOverride = fidelityProfile
            currentPriorityPlan = calibrationEngine.priorityPlan(for: mode)
            sessionStartDate = Date()
            sessionSamples = []
            latestCoordinate = nil
            latestSpeedKmh = 0
            latestAcceleration = .zero
            latestGyroscope = .zero
            latestAltitudeMeters = nil
            altitudeOutlierGuard.reset()
            pressureFilter.reset()
            latestPressureDiagnostics = nil
            latestLocationDiagnostics = nil
            latestRawLocation = nil
            latestDeviceHeading = nil
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

        gpsProvider.headingPublisher
            .sink { [weak self] heading in
                self?.updateDeviceHeading(heading)
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

        barometerProvider.pressureKilopascalsPublisher
            .sink { [weak self] pressureKilopascals in
                self?.updatePressure(pressureKilopascals)
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
        let now = Date()
        let altitudeGuardConfig = AltitudeOutlierGuardConfig(
            policy: ActivityFidelityPolicy(profile: currentActivityFidelityProfile())
        )
        let snapshot = stateLock.withLock { () -> (
            coordinate: GeoCoordinate?,
            speedKmh: Double,
            acceleration: ThreeAxisValue,
            gyroscope: ThreeAxisValue,
            altitude: Double?,
            altitudeDiagnostics: AltitudeDiagnostics?,
            locationDiagnostics: LocationFixDiagnostics?,
            calibratedAcceleration: ThreeAxisValue,
            calibratedGyroscope: ThreeAxisValue
        ) in
            let coordinate = latestCoordinate
            let speedKmh = latestSpeedKmh
            let acceleration = latestAcceleration
            let gyroscope = latestGyroscope
            let altitude = latestAltitudeMeters
            let pressureDiagnostics = latestPressureDiagnostics
            let altitudeSource: AltitudeSampleSource? = altitude == nil ? nil : .barometerRelative
            let deviceHeading = latestDeviceHeading
            let locationDiagnostics = latestLocationDiagnostics.map { diagnostics in
                timerFusionDiagnostics(
                    from: diagnostics,
                    latestRawLocation: latestRawLocation,
                    latestDeviceHeading: deviceHeading,
                    now: now
                )
            }
            let altitudeDiagnostics = altitudeSource.map { source in
                altitudeOutlierGuard.evaluate(
                    altitudeMeters: altitude,
                    source: source,
                    timestamp: now,
                    verticalAccuracyMeters: nil,
                    locationDiagnostics: locationDiagnostics,
                    sessionStartDate: sessionStartDate,
                    config: altitudeGuardConfig,
                    pressureDiagnostics: pressureDiagnostics
                )
            }
            calibrationEngine.ingest(acceleration: acceleration, gyroscope: gyroscope)
            let calibratedAcceleration = calibrationEngine.calibratedAcceleration(from: acceleration)
            let calibratedGyroscope = calibrationEngine.calibratedGyroscope(from: gyroscope)

            return (
                coordinate,
                speedKmh,
                acceleration,
                gyroscope,
                altitude,
                altitudeDiagnostics,
                locationDiagnostics,
                calibratedAcceleration,
                calibratedGyroscope
            )
        }

        return MotionSample(
            timestamp: now,
            gpsCoordinate: snapshot.coordinate,
            speedKmh: snapshot.speedKmh,
            accelerometerG: snapshot.calibratedAcceleration,
            gyroscopeRadPS: snapshot.calibratedGyroscope,
            altitudeMeters: snapshot.altitude,
            altitudeSource: snapshot.altitude == nil ? nil : .barometerRelative,
            altitudeDiagnostics: snapshot.altitudeDiagnostics,
            locationDiagnostics: snapshot.locationDiagnostics,
            sampleSource: .timerFusion
        )
    }
    private func updateLocation(_ location: CLLocation) {
        let receivedAt = Date()
        let stateSnapshot = stateLock.withLock { (
            previousLocation: latestRawLocation,
            sessionStartDate: sessionStartDate,
            latestDeviceHeading: latestDeviceHeading
        ) }
        let diagnostics = makeLocationDiagnostics(
            for: location,
            previousLocation: stateSnapshot.previousLocation,
            sessionStartDate: stateSnapshot.sessionStartDate,
            receivedAt: receivedAt,
            deviceHeading: stateSnapshot.latestDeviceHeading
        )

        let liveRoutePolicy = ActivityFidelityPolicy(profile: currentActivityFidelityProfile())
        stateLock.withLock {
            latestRawLocation = location
            latestLocationDiagnostics = diagnostics

            if Self.trustsLocationForLiveRoute(diagnostics, policy: liveRoutePolicy) {
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
        let liveRoutePolicy = ActivityFidelityPolicy(profile: currentActivityFidelityProfile())
        let altitudeGuardConfig = AltitudeOutlierGuardConfig(policy: liveRoutePolicy)
        let sample = stateLock.withLock { () -> MotionSample? in
            guard sessionStartDate != nil else { return nil }
            let coordinate = GeoCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let rawAltitude = normalizedAltitude(from: location)
            let altitudeSource: AltitudeSampleSource? = rawAltitude == nil ? nil : .coreLocationAbsolute
            let altitudeDiagnostics = altitudeSource.map { source in
                altitudeOutlierGuard.evaluate(
                    altitudeMeters: rawAltitude,
                    source: source,
                    timestamp: location.timestamp,
                    verticalAccuracyMeters: diagnostics.verticalAccuracyMeters,
                    locationDiagnostics: diagnostics,
                    sessionStartDate: sessionStartDate,
                    config: altitudeGuardConfig
                )
            }
            let trustedForLiveRoute = Self.trustsLocationForLiveRoute(
                diagnostics,
                policy: liveRoutePolicy
            )
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
                altitudeMeters: rawAltitude,
                altitudeSource: altitudeSource,
                altitudeDiagnostics: altitudeDiagnostics,
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
        receivedAt: Date,
        deviceHeading: CLHeading?
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
        let confidenceProfile = routeConfidenceProfile(
            coreLocationSpeedKmh: coreLocationSpeedKmh,
            coordinateDerivedSpeedKmh: rawCoordinateDerivedSpeedKmh
        )
        let isLowSpeedLocalJump = isLowSpeedLocalMetricOutlier(
            coreLocationSpeedKmh: coreLocationSpeedKmh,
            coordinateDerivedSpeedKmh: rawCoordinateDerivedSpeedKmh,
            horizontalAccuracyMeters: horizontalAccuracy,
            speedAccuracyMetersPerSecond: normalizedAccuracy(location.speedAccuracy),
            segmentDistanceMeters: segmentDistance,
            profile: confidenceProfile
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
                profile: confidenceProfile
            )

        let headingDiagnostics = headingDiagnostics(
            for: location,
            coreLocationSpeedKmh: coreLocationSpeedKmh,
            deviceHeading: deviceHeading,
            receivedAt: receivedAt
        )
        let gpsGapDiagnostics = gpsGapDiagnostics(gapSeconds: updateInterval, isTimerFusionRepeat: false)
        let deadReckoningDiagnostics = deadReckoningDiagnostics(
            gpsGapDiagnostics: gpsGapDiagnostics,
            headingDiagnostics: headingDiagnostics,
            anchorAvailable: confidence != .low && confidence != .unavailable
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
            routeSegmentConfidence: confidence,
            headingDiagnostics: headingDiagnostics,
            gpsGapDiagnostics: gpsGapDiagnostics,
            deadReckoningDiagnostics: deadReckoningDiagnostics
        )
    }
    private func timerFusionDiagnostics(
        from diagnostics: LocationFixDiagnostics,
        latestRawLocation: CLLocation?,
        latestDeviceHeading: CLHeading?,
        now: Date
    ) -> LocationFixDiagnostics {
        let gapSeconds = latestRawLocation.map { max(now.timeIntervalSince($0.timestamp), 0) }
        let gpsGap = gpsGapDiagnostics(gapSeconds: gapSeconds, isTimerFusionRepeat: true)
        let headingDiagnostics = headingDiagnostics(
            for: latestRawLocation,
            fallback: diagnostics.headingDiagnostics,
            deviceHeading: latestDeviceHeading,
            receivedAt: now
        )
        let deadReckoning = deadReckoningDiagnostics(
            gpsGapDiagnostics: gpsGap,
            headingDiagnostics: headingDiagnostics,
            anchorAvailable: diagnostics.routeSegmentConfidence != .low && diagnostics.routeSegmentConfidence != .unavailable
        )
        return diagnostics.replacingR4Diagnostics(
            headingDiagnostics: headingDiagnostics,
            gpsGapDiagnostics: gpsGap,
            deadReckoningDiagnostics: deadReckoning
        )
    }

    private func headingDiagnostics(
        for location: CLLocation,
        coreLocationSpeedKmh: Double?,
        deviceHeading: CLHeading?,
        receivedAt: Date
    ) -> HeadingDiagnostics {
        headingDiagnostics(
            for: Optional(location),
            fallback: nil,
            coreLocationSpeedKmh: coreLocationSpeedKmh,
            deviceHeading: deviceHeading,
            receivedAt: receivedAt
        )
    }

    private func headingDiagnostics(
        for location: CLLocation?,
        fallback: HeadingDiagnostics?,
        coreLocationSpeedKmh: Double? = nil,
        deviceHeading: CLHeading?,
        receivedAt: Date
    ) -> HeadingDiagnostics {
        let courseDegrees = location.flatMap { normalizedHeadingDegrees($0.course) }
            ?? fallback?.courseOverGroundDegrees
        let accuracyDegrees = location.flatMap { courseAccuracyDegrees(for: $0) }
            ?? fallback?.courseAccuracyDegrees
        let speedKmh = coreLocationSpeedKmh
            ?? fallback?.coreLocationSpeedKmh
            ?? location.flatMap { $0.speed >= 0 ? GPSProvider.kilometersPerHour(fromMetersPerSecond: $0.speed) : nil }
        let courseReliable = courseDegrees != nil
            && speedKmh.map { $0 >= 3 } == true
            && accuracyDegrees.map { $0 <= 45 } != false

        let deviceDegrees = deviceHeadingDegrees(for: deviceHeading)
        let deviceAccuracy = deviceHeading.flatMap { normalizedAccuracy($0.headingAccuracy) }
        let deviceTimestamp = deviceHeading?.timestamp
        let deviceAge = deviceTimestamp.map { max(receivedAt.timeIntervalSince($0), 0) }
        let deviceReliable = deviceDegrees != nil
            && deviceAccuracy.map { $0 <= 35 } == true
            && deviceAge.map { $0 <= 5 } != false
        let deltaDegrees = angularDifferenceDegrees(courseDegrees, deviceDegrees)
        let courseDeviceAgreement = deltaDegrees.map { $0 <= 45 }

        let source: HeadingDiagnosticsSource
        switch (courseDegrees != nil, deviceDegrees != nil) {
        case (true, true):
            source = .courseAndDeviceMagnetometer
        case (true, false):
            source = .coreLocationCourse
        case (false, true):
            source = .deviceMagnetometer
        case (false, false):
            source = .unavailable
        }

        return HeadingDiagnostics(
            source: source,
            headingAvailable: source != .unavailable,
            courseOverGroundDegrees: courseDegrees,
            courseAccuracyDegrees: accuracyDegrees,
            coreLocationSpeedKmh: speedKmh,
            courseReliableForRouteContinuity: courseReliable,
            deviceHeadingDeferred: false,
            deviceHeadingDegrees: deviceDegrees,
            deviceHeadingAccuracyDegrees: deviceAccuracy,
            deviceHeadingTimestamp: deviceTimestamp,
            deviceHeadingTimestampMillisecondsSince1970: deviceTimestamp?.millisecondsSince1970,
            deviceHeadingAgeSeconds: deviceAge,
            deviceHeadingReliableForRouteContinuity: deviceReliable,
            courseDeviceHeadingDeltaDegrees: deltaDegrees,
            courseDeviceHeadingAgreement: courseDeviceAgreement
        )
    }
    private func gpsGapDiagnostics(
        gapSeconds: TimeInterval?,
        isTimerFusionRepeat: Bool
    ) -> GPSGapDiagnostics? {
        guard let classification = GPSGapDiagnostics.classification(for: gapSeconds) else { return nil }
        return GPSGapDiagnostics(
            classification: classification,
            gapSeconds: gapSeconds,
            isTimerFusionRepeat: isTimerFusionRepeat,
            rawLocationAvailable: true
        )
    }
    private func deadReckoningDiagnostics(
        gpsGapDiagnostics: GPSGapDiagnostics?,
        headingDiagnostics: HeadingDiagnostics?,
        anchorAvailable: Bool
    ) -> DeadReckoningDiagnostics? {
        guard let gpsGapDiagnostics else { return nil }
        let hasGap = gpsGapDiagnostics.classification != .normalCadence
        let headingAvailable = headingDiagnostics?.hasReliableHeadingForRouteContinuity ?? false
        let eligible = hasGap && headingAvailable && anchorAvailable
        let reason: DeadReckoningReadinessReason
        if !hasGap {
            reason = .normalCadence
        } else if !anchorAvailable {
            reason = .anchorUnavailable
        } else if !headingAvailable {
            reason = .headingUnavailable
        } else {
            reason = .r4RouteReconstructionDeferred
        }
        return DeadReckoningDiagnostics(
            estimatedRouteActive: false,
            eligibleForFutureEstimation: eligible,
            anchorAvailable: anchorAvailable,
            gapSeconds: gpsGapDiagnostics.gapSeconds,
            headingAvailable: headingAvailable,
            reason: reason
        )
    }
    private static func trustsLocationForLiveRoute(_ diagnostics: LocationFixDiagnostics, policy: ActivityFidelityPolicy) -> Bool {
        guard diagnostics.routeSegmentConfidence != .low,
              diagnostics.routeSegmentConfidence != .unavailable else { return false }
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
        segmentDistanceMeters: Double?,
        profile: ActivityFidelityProfile
    ) -> Bool {
        let policy = ActivityFidelityPolicy(profile: profile)

        // Task-030c-b13-A-4: coreLocationSpeedKmh only fires when CLLocation actually reported a speed.
        // Coordinate-derived speed must not substitute into this gate; doing so over-penalizes
        // low-speed freebord carving under tree canopy when CLLocation.speed is unavailable.
        if let coreSpeedKmh = coreLocationSpeedKmh, coreSpeedKmh > 0 {
            if coreSpeedKmh >= Self.lowSpeedSuspiciousCoreLocationSpeedKmh {
                return !policy.acceptsLowSpeedMetricSample(
                    speedKmh: coreSpeedKmh,
                    horizontalAccuracyMeters: horizontalAccuracyMeters,
                    speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
                    coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh,
                    segmentDistanceMeters: segmentDistanceMeters
                )
            }
        }

        if let coordinateDerivedSpeedKmh, coordinateDerivedSpeedKmh >= Self.lowSpeedLocalJumpKmh {
            let metricSpeedKmh = coreLocationSpeedKmh ?? coordinateDerivedSpeedKmh
            return !policy.acceptsLowSpeedMetricSample(
                speedKmh: metricSpeedKmh,
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
    private func routeConfidenceProfile(
        coreLocationSpeedKmh: Double?,
        coordinateDerivedSpeedKmh: Double?
    ) -> ActivityFidelityProfile {
        let baseProfile = currentActivityFidelityProfile()
        let candidateSpeed = max(coreLocationSpeedKmh ?? 0, coordinateDerivedSpeedKmh ?? 0)
        let basePolicy = ActivityFidelityPolicy(profile: baseProfile)
        let powerType = stateLock.withLock { currentPowerType }

        // Task-030c-b11-r2: motorcycle / vehicle validation may still be started from a
        // human-powered UI path during summer snow-proxy testing. Treat clearly high-speed
        // proxy movement as validation so route continuity is not judged by skateboard-only
        // limits, while normal skateboard / walking sessions keep their stricter gates.
        if powerType == .humanPowered,
           candidateSpeed > basePolicy.chartMaximumSpeedKmh + 20 {
            return .vehicleValidation
        }

        return baseProfile
    }

    private func currentActivityFidelityProfile() -> ActivityFidelityProfile {
        stateLock.withLock {
            if let currentFidelityProfileOverride { return currentFidelityProfileOverride }
            return ActivityFidelityProfile.defaultProfile(
                for: currentMode ?? .skateboard(.streetPark),
                powerType: currentPowerType
            )
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

    private func deviceHeadingDegrees(for heading: CLHeading?) -> Double? {
        guard let heading else { return nil }
        if let trueHeading = normalizedHeadingDegrees(heading.trueHeading) { return trueHeading }
        return normalizedHeadingDegrees(heading.magneticHeading)
    }

    private func normalizedHeadingDegrees(_ degrees: CLLocationDirection) -> Double? {
        guard degrees >= 0, degrees.isFinite else { return nil }
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }

    private func angularDifferenceDegrees(_ lhs: Double?, _ rhs: Double?) -> Double? {
        guard let lhs, let rhs else { return nil }
        let delta = abs(lhs - rhs).truncatingRemainder(dividingBy: 360)
        return min(delta, 360 - delta)
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

    private func updatePressure(_ pressureKilopascals: Double?) {
        stateLock.withLock {
            latestPressureDiagnostics = pressureFilter.evaluate(rawPressureKilopascals: pressureKilopascals)
        }
    }

    private func updateDeviceHeading(_ heading: CLHeading?) {
        stateLock.withLock {
            latestDeviceHeading = heading
        }
    }
    private func sessionSnapshot() -> (
        startDate: Date,
        mode: SportMode,
        powerType: PowerType,
        fidelityProfile: ActivityFidelityProfile,
        samples: [MotionSample]
    ) {
        stateLock.withLock {
            let startDate = sessionStartDate ?? Date()
            let mode = currentMode ?? .skateboard(.streetPark)
            let powerType = currentPowerType
            let fidelityProfile = currentFidelityProfileOverride
                ?? ActivityFidelityProfile.defaultProfile(for: mode, powerType: powerType)
            let samples = sessionSamples
            return (startDate, mode, powerType, fidelityProfile, samples)
        }
    }
    private func resetTransientState() {
        stateLock.withLock {
            currentMode = nil
            currentPowerType = .humanPowered
            currentFidelityProfileOverride = nil
            currentPriorityPlan = nil
            sessionStartDate = nil
            latestCoordinate = nil
            latestSpeedKmh = 0
            latestAcceleration = .zero
            latestGyroscope = .zero
            latestAltitudeMeters = nil
            altitudeOutlierGuard.reset()
            pressureFilter.reset()
            latestPressureDiagnostics = nil
            latestLocationDiagnostics = nil
            latestRawLocation = nil
            latestDeviceHeading = nil
        }
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1_000).rounded())
    }
}
