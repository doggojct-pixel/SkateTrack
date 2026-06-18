// [自主區] iOS/Core/SessionRecording/SessionMetricsAccumulator.swift
// 用途：依 MotionSample 即時累積速度、距離、爬升、傾角與滑行比例。
// 委派至：SessionRecordingCoordinator、Live HUD（Task-013）與 Session summary。

import Foundation

struct SessionMetricsAccumulator: Equatable, Sendable {
    private static let movingSpeedThresholdKmh = 1.0
    private static let maximumSegmentSpeedKmh = ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh
    private static let minimumSegmentDistanceKilometers = 0.003
    private static let maximumSegmentDistanceKilometers = 2.0
    private static let earthRadiusKilometers = 6_371.0

    private(set) var currentSpeedKilometersPerHour: Double = 0
    private(set) var maxSpeedKilometersPerHour: Double = 0
    private(set) var averageSpeedKilometersPerHour: Double = 0
    private(set) var distanceKilometers: Double = 0
    private(set) var elevationGainMeters: Double = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var currentTiltDegrees: Double = 0
    private(set) var latestMotionSample: MotionSample?
    private(set) var motionSampleCount: Int = 0
    private(set) var gpsSampleCount: Int = 0

    private var sessionStartDate: Date?
    private var lastProcessedTimestamp: Date?
    private var lastCoordinate: GeoCoordinate?
    private var lastCoordinateTimestamp: Date?
    private var lastAltitudeMeters: Double?
    private var lastBarometerAltitudeMeters: Double?
    private var lastCoreLocationAltitudeMeters: Double?
    private var speedSampleCount: Int = 0
    private var speedSampleSum: Double = 0
    private var movingElapsedTime: TimeInterval = 0
    private var isPaused = false
    private var activePolicy = ActivityFidelityPolicy(profile: .standardSkateboard)

    mutating func beginSession(
        at startDate: Date = Date(),
        policy: ActivityFidelityPolicy = ActivityFidelityPolicy(profile: .standardSkateboard)
    ) {
        reset()
        activePolicy = policy
        sessionStartDate = startDate
        lastProcessedTimestamp = startDate
    }

    mutating func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    mutating func process(_ sample: MotionSample) {
        guard !isPaused else { return }

        latestMotionSample = sample
        motionSampleCount += 1
        if sample.gpsCoordinate != nil {
            gpsSampleCount += 1
        }
        let trustedForSummary = trustsSampleForSummaryMetrics(sample)
        currentSpeedKilometersPerHour = trustedForSummary ? max(sample.speedKmh, 0) : 0
        maxSpeedKilometersPerHour = max(maxSpeedKilometersPerHour, currentSpeedKilometersPerHour)

        speedSampleCount += 1
        speedSampleSum += currentSpeedKilometersPerHour
        averageSpeedKilometersPerHour = speedSampleCount > 0 ? speedSampleSum / Double(speedSampleCount) : 0

        currentTiltDegrees = tiltDegrees(from: sample.accelerometerG)
        accumulateElapsedTime(until: sample.timestamp)
        accumulateDistance(from: sample)
        accumulateElevation(from: sample)
    }

    mutating func reset() {
        currentSpeedKilometersPerHour = 0
        maxSpeedKilometersPerHour = 0
        averageSpeedKilometersPerHour = 0
        distanceKilometers = 0
        elevationGainMeters = 0
        elapsedTime = 0
        currentTiltDegrees = 0
        latestMotionSample = nil
        motionSampleCount = 0
        gpsSampleCount = 0
        sessionStartDate = nil
        lastProcessedTimestamp = nil
        lastCoordinate = nil
        lastAltitudeMeters = nil
        lastBarometerAltitudeMeters = nil
        lastCoreLocationAltitudeMeters = nil
        lastCoordinateTimestamp = nil
        speedSampleCount = 0
        speedSampleSum = 0
        movingElapsedTime = 0
        isPaused = false
        activePolicy = ActivityFidelityPolicy(profile: .standardSkateboard)
    }

    func makeSummaryMetrics() -> SessionSummaryMetrics {
        let movingRatio = elapsedTime > 0 ? movingElapsedTime / elapsedTime : 0
        return SessionSummaryMetrics(
            distanceKilometers: distanceKilometers,
            maxSpeedKilometersPerHour: maxSpeedKilometersPerHour,
            averageSpeedKilometersPerHour: averageSpeedKilometersPerHour,
            elevationGainMeters: elevationGainMeters,
            movingRatio: min(max(movingRatio, 0), 1)
        )
    }

    func makeLiveMetrics() -> LiveSessionMetrics {
        LiveSessionMetrics(
            currentSpeedKilometersPerHour: currentSpeedKilometersPerHour,
            maxSpeedKilometersPerHour: maxSpeedKilometersPerHour,
            averageSpeedKilometersPerHour: averageSpeedKilometersPerHour,
            distanceKilometers: distanceKilometers,
            elapsedTime: elapsedTime,
            currentTiltDegrees: currentTiltDegrees,
            latestMotionSample: latestMotionSample,
            motionSampleCount: motionSampleCount,
            gpsSampleCount: gpsSampleCount
        )
    }

    private mutating func accumulateElapsedTime(until timestamp: Date) {
        guard let lastProcessedTimestamp else {
            self.lastProcessedTimestamp = timestamp
            if sessionStartDate == nil {
                sessionStartDate = timestamp
            }
            return
        }

        let delta = max(timestamp.timeIntervalSince(lastProcessedTimestamp), 0)
        elapsedTime += delta

        if currentSpeedKilometersPerHour >= Self.movingSpeedThresholdKmh {
            movingElapsedTime += delta
        }

        self.lastProcessedTimestamp = timestamp
    }

    private mutating func accumulateDistance(from sample: MotionSample) {
        guard let coordinate = sample.gpsCoordinate else { return }

        let coordinateTimestamp = sample.timestamp

        guard trustsSampleForRouteDistance(sample) else {
            lastCoordinate = nil
            lastCoordinateTimestamp = nil
            return
        }

        guard let previousCoordinate = lastCoordinate else {
            lastCoordinate = coordinate
            lastCoordinateTimestamp = coordinateTimestamp
            return
        }

        let segmentDistance = Self.haversineDistanceKilometers(from: previousCoordinate, to: coordinate)
        guard segmentDistance >= Self.minimumSegmentDistanceKilometers else {
            // Keep the previous GPS anchor when high-frequency samples repeat the same coordinate.
            // Updating the timestamp for duplicate coordinates makes the next real GPS move look
            // impossibly fast and causes valid distance segments to be filtered out.
            return
        }
        guard segmentDistance <= Self.maximumSegmentDistanceKilometers else { return }

        if let previousCoordinateTimestamp = lastCoordinateTimestamp {
            let deltaSeconds = max(coordinateTimestamp.timeIntervalSince(previousCoordinateTimestamp), 0.001)
            let impliedSpeedKmh = (segmentDistance / deltaSeconds) * 3_600
            guard impliedSpeedKmh <= Self.maximumSegmentSpeedKmh else { return }
        }

        distanceKilometers += segmentDistance
        lastCoordinate = coordinate
        lastCoordinateTimestamp = coordinateTimestamp
    }

    private func trustsSampleForSummaryMetrics(_ sample: MotionSample) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return true }
        if sample.sampleSource == .debugSimulated { return true }
        guard diagnostics.routeSegmentConfidence != .low,
              diagnostics.routeSegmentConfidence != .unavailable else { return false }
        let policy = activePolicy
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

    private func trustsSampleForRouteDistance(_ sample: MotionSample) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return true }
        guard diagnostics.routeSegmentConfidence != .low,
              diagnostics.routeSegmentConfidence != .unavailable else { return false }
        return trustsSampleForSummaryMetrics(sample)
    }

    private mutating func accumulateElevation(from sample: MotionSample) {
        guard let altitude = sample.altitudeMeters, altitude.isFinite else { return }
        let policy = activePolicy

        switch sample.altitudeSource {
        case .barometerRelative:
            defer { lastBarometerAltitudeMeters = altitude }
            guard let previousAltitude = lastBarometerAltitudeMeters else { return }
            let delta = altitude - previousAltitude
            guard delta > 0.03, delta <= min(policy.maximumElevationStepMeters, 1.0) else { return }
            elevationGainMeters += delta
        case .coreLocationAbsolute:
            // Task-030c-b10-r4: once barometer-relative altitude is present, Core Location
            // absolute altitude is retained as raw diagnostics only and must not inflate
            // low-speed / short-distance elevation gain.
            guard lastBarometerAltitudeMeters == nil else { return }
            let verticalAccuracy = sample.locationDiagnostics?.verticalAccuracyMeters
            defer { lastCoreLocationAltitudeMeters = altitude }
            guard let previousAltitude = lastCoreLocationAltitudeMeters else { return }
            guard sample.timestamp.timeIntervalSince(sessionStartDate ?? sample.timestamp) > 30 else { return }
            let delta = altitude - previousAltitude
            guard delta > 0 else { return }
            let strictVerticalAccuracy = min(policy.maximumVerticalAccuracyMeters, 5)
            if let verticalAccuracy, verticalAccuracy <= strictVerticalAccuracy,
               delta <= min(policy.maximumElevationStepMeters, 1.0) {
                elevationGainMeters += delta
            }
        case .debugSimulated:
            defer { lastAltitudeMeters = altitude }
            guard let previousAltitude = lastAltitudeMeters else { return }
            let delta = altitude - previousAltitude
            if delta > 0, delta <= policy.maximumElevationStepMeters {
                elevationGainMeters += delta
            }
        case .unavailable, .none:
            return
        }
    }

    private func tiltDegrees(from acceleration: ThreeAxisValue) -> Double {
        let rollRadians = atan2(acceleration.y, acceleration.z)
        return rollRadians * (180 / .pi)
    }

    private static func haversineDistanceKilometers(from: GeoCoordinate, to: GeoCoordinate) -> Double {
        let deltaLatitude = (to.latitude - from.latitude) * (.pi / 180)
        let deltaLongitude = (to.longitude - from.longitude) * (.pi / 180)
        let startLatitude = from.latitude * (.pi / 180)
        let endLatitude = to.latitude * (.pi / 180)

        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusKilometers * centralAngle
    }
}
