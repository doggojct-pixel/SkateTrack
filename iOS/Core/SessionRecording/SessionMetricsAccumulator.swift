// [自主區] iOS/Core/SessionRecording/SessionMetricsAccumulator.swift
// 用途：依 MotionSample 即時累積速度、距離、爬升、傾角與滑行比例。
// 委派至：SessionRecordingCoordinator、Live HUD（Task-013）與 Session summary。

import Foundation

struct SessionMetricsAccumulator: Equatable, Sendable {
    private static let movingSpeedThresholdKmh = 1.0
    private static let maximumSegmentSpeedKmh = 150.0
    private static let maximumSegmentDistanceKilometers = 0.05
    private static let earthRadiusKilometers = 6_371.0

    private(set) var currentSpeedKilometersPerHour: Double = 0
    private(set) var maxSpeedKilometersPerHour: Double = 0
    private(set) var averageSpeedKilometersPerHour: Double = 0
    private(set) var distanceKilometers: Double = 0
    private(set) var elevationGainMeters: Double = 0
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var currentTiltDegrees: Double = 0
    private(set) var latestMotionSample: MotionSample?

    private var sessionStartDate: Date?
    private var lastProcessedTimestamp: Date?
    private var lastCoordinate: GeoCoordinate?
    private var lastAltitudeMeters: Double?
    private var previousSampleTimestamp: Date?
    private var speedSampleCount: Int = 0
    private var speedSampleSum: Double = 0
    private var movingElapsedTime: TimeInterval = 0
    private var isPaused = false

    mutating func beginSession(at startDate: Date = Date()) {
        reset()
        sessionStartDate = startDate
        lastProcessedTimestamp = startDate
    }

    mutating func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    mutating func process(_ sample: MotionSample) {
        guard !isPaused else { return }

        latestMotionSample = sample
        currentSpeedKilometersPerHour = max(sample.speedKmh, 0)
        maxSpeedKilometersPerHour = max(maxSpeedKilometersPerHour, currentSpeedKilometersPerHour)

        speedSampleCount += 1
        speedSampleSum += currentSpeedKilometersPerHour
        averageSpeedKilometersPerHour = speedSampleCount > 0 ? speedSampleSum / Double(speedSampleCount) : 0

        currentTiltDegrees = tiltDegrees(from: sample.accelerometerG)
        accumulateElapsedTime(until: sample.timestamp)
        accumulateDistance(from: sample)
        accumulateElevation(from: sample)
        previousSampleTimestamp = sample.timestamp
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
        sessionStartDate = nil
        lastProcessedTimestamp = nil
        lastCoordinate = nil
        lastAltitudeMeters = nil
        previousSampleTimestamp = nil
        speedSampleCount = 0
        speedSampleSum = 0
        movingElapsedTime = 0
        isPaused = false
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
            latestMotionSample: latestMotionSample
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

        defer { lastCoordinate = coordinate }

        guard let previousCoordinate = lastCoordinate else { return }

        let segmentDistance = Self.haversineDistanceKilometers(from: previousCoordinate, to: coordinate)
        guard segmentDistance > 0 else { return }
        guard segmentDistance <= Self.maximumSegmentDistanceKilometers else { return }

        if let previousSampleTimestamp {
            let deltaSeconds = max(sample.timestamp.timeIntervalSince(previousSampleTimestamp), 0.001)
            let impliedSpeedKmh = (segmentDistance / deltaSeconds) * 3_600
            guard impliedSpeedKmh <= Self.maximumSegmentSpeedKmh else { return }
        }

        distanceKilometers += segmentDistance
    }

    private mutating func accumulateElevation(from sample: MotionSample) {
        guard let altitude = sample.altitudeMeters else { return }

        defer { lastAltitudeMeters = altitude }

        guard let previousAltitude = lastAltitudeMeters else { return }

        let delta = altitude - previousAltitude
        if delta > 0 {
            elevationGainMeters += delta
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
