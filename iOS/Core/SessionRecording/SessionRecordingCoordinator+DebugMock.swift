// [自主區] iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift
// 用途：集中 DEBUG-only simulated outdoor route sample feed，避免正常 App runtime 使用 mock 位置或速度。
// 委派至：Debug Tools simulated route session、SwiftUI previews、Task-015 persistence tests。

import Foundation

#if DEBUG
extension SessionRecordingCoordinator {
    func startMockSampleFeed(for mode: SportMode) {
        stopMockSampleFeed()
        mockSampleIndex = 0
        mockSessionSamples = []
        mockRouteSimulator.reset(for: mode, startDate: Date())

        // Task-030c-b15-B-3: DEBUG mock recording must run on the main queue so
        // SessionRecordingCoordinator, Combine publishers, Live HUD trace state, and
        // the final save path all observe the same deterministic MotionSample stream.
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + .milliseconds(150),
            repeating: .milliseconds(Int(DebugOutdoorRouteSimulator.sampleIntervalSeconds * 1_000))
        )
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            handleMotionSample(makeMockSample(for: mode))
        }
        mockSampleTimer = timer
        timer.resume()
    }

    func stopMockSampleFeed() {
        mockSampleTimer?.cancel()
        mockSampleTimer = nil
    }

    func makeMockSample(for mode: SportMode) -> MotionSample {
        mockSampleIndex += 1
        return mockRouteSimulator.nextSample(for: mode)
    }

    static func makeMockCoordinator() -> SessionRecordingCoordinator {
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: SensorFusionEngine(),
            fallDetectionEngine: FallDetectionEngine()
        )
        coordinator.setDataSource(.mock)
        return coordinator
    }
}

struct DebugOutdoorRouteSimulator: Sendable {
    static let sampleIntervalSeconds: TimeInterval = 0.5

    private var startDate = Date()
    private var previousTimestamp: Date?
    private var previousCoordinate: GeoCoordinate?
    private var latitude = 25.033000
    private var longitude = 121.565000
    private var elapsedSeconds: TimeInterval = 0
    private var cumulativeDistanceMeters = 0.0
    private var sampleIndex = 0

    mutating func reset(for mode: SportMode, startDate: Date = Date()) {
        self.startDate = startDate
        previousTimestamp = nil
        previousCoordinate = nil
        elapsedSeconds = 0
        cumulativeDistanceMeters = 0
        sampleIndex = 0

        switch mode {
        case .skateboard(.longboard):
            latitude = 25.034150
            longitude = 121.565350
        case .skateboard(.surfskate):
            latitude = 25.032650
            longitude = 121.564550
        case .skateboard(.freebord):
            latitude = 25.033700
            longitude = 121.563950
        case .inline(.fitnessSpeed):
            latitude = 25.034500
            longitude = 121.564900
        case .inline:
            latitude = 25.032900
            longitude = 121.565200
        case .snow:
            latitude = 25.034850
            longitude = 121.564300
        default:
            latitude = 25.033000
            longitude = 121.565000
        }
    }

    mutating func nextSample(for mode: SportMode) -> MotionSample {
        sampleIndex += 1
        elapsedSeconds += Self.sampleIntervalSeconds

        let timestamp = startDate.addingTimeInterval(elapsedSeconds)
        let speedKmh = simulatedSpeedKmh(for: mode, elapsedSeconds: elapsedSeconds)
        let distanceMeters = max(speedKmh / 3.6 * Self.sampleIntervalSeconds, 0)
        let bearingDegrees = simulatedBearingDegrees(elapsedSeconds: elapsedSeconds)
        advanceCoordinate(distanceMeters: distanceMeters, bearingDegrees: bearingDegrees)
        cumulativeDistanceMeters += distanceMeters

        let coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
        let updateInterval = previousTimestamp.map { timestamp.timeIntervalSince($0) }
        let segmentDistance = previousCoordinate.map { Self.haversineDistanceMeters(from: $0, to: coordinate) }
        let horizontalAccuracy = simulatedHorizontalAccuracyMeters(sampleIndex: sampleIndex)
        let routeConfidence = simulatedRouteConfidence(horizontalAccuracyMeters: horizontalAccuracy)

        let diagnostics = LocationFixDiagnostics(
            horizontalAccuracyMeters: horizontalAccuracy,
            verticalAccuracyMeters: horizontalAccuracy <= 12 ? 8 : 18,
            speedAccuracyMetersPerSecond: horizontalAccuracy <= 12 ? 0.8 : 3.5,
            courseAccuracyDegrees: horizontalAccuracy <= 12 ? 6 : 24,
            rawLocationTimestamp: timestamp,
            rawLocationTimestampMillisecondsSince1970: timestamp.millisecondsSince1970,
            receivedAtTimestamp: timestamp,
            receivedAtTimestampMillisecondsSince1970: timestamp.millisecondsSince1970,
            gpsUpdateIntervalSeconds: updateInterval,
            gpsSegmentDistanceMeters: segmentDistance,
            coordinateDerivedSpeedKmh: speedKmh,
            speedSource: .debugSimulated,
            freshnessState: .fresh,
            routeSegmentConfidence: routeConfidence
        )

        previousTimestamp = timestamp
        previousCoordinate = coordinate

        return MotionSample(
            timestamp: timestamp,
            gpsCoordinate: coordinate,
            speedKmh: speedKmh,
            accelerometerG: simulatedAcceleration(elapsedSeconds: elapsedSeconds),
            gyroscopeRadPS: simulatedGyroscope(elapsedSeconds: elapsedSeconds),
            altitudeMeters: simulatedAltitudeMeters(elapsedSeconds: elapsedSeconds),
            altitudeSource: .debugSimulated,
            locationDiagnostics: diagnostics,
            sampleSource: .debugSimulated
        )
    }

    private func simulatedSpeedKmh(for mode: SportMode, elapsedSeconds: TimeInterval) -> Double {
        let cruiseSpeed: Double
        switch mode {
        case .skateboard(.longboard):
            cruiseSpeed = 18
        case .inline(.fitnessSpeed):
            cruiseSpeed = 20
        case .skateboard(.streetPark), .inline(.urbanFreestyle):
            cruiseSpeed = 13
        case .skateboard(.surfskate), .inline(.slalom):
            cruiseSpeed = 11
        case .snow:
            cruiseSpeed = 24
        default:
            cruiseSpeed = 12
        }

        let wave = 3.2 * sin(elapsedSeconds / 7.5) + 1.4 * sin(elapsedSeconds / 2.8)
        let shortCoast = sampleIndex % 84 > 72 ? -6.5 : 0
        return min(max(cruiseSpeed + wave + shortCoast, 2.0), 26.0)
    }

    private func simulatedBearingDegrees(elapsedSeconds: TimeInterval) -> Double {
        38 + (18 * sin(elapsedSeconds / 28)) + (7 * sin(elapsedSeconds / 9))
    }

    private mutating func advanceCoordinate(distanceMeters: Double, bearingDegrees: Double) {
        let bearing = bearingDegrees * (.pi / 180)
        let northMeters = cos(bearing) * distanceMeters
        let eastMeters = sin(bearing) * distanceMeters
        let latitudeMetersPerDegree = 111_111.0
        let longitudeMetersPerDegree = max(111_111.0 * cos(latitude * (.pi / 180)), 1)

        latitude += northMeters / latitudeMetersPerDegree
        longitude += eastMeters / longitudeMetersPerDegree
    }

    private func simulatedAltitudeMeters(elapsedSeconds: TimeInterval) -> Double {
        20.0 + (1.7 * sin(elapsedSeconds / 38)) + (0.35 * sin(elapsedSeconds / 6.5))
    }

    private func simulatedHorizontalAccuracyMeters(sampleIndex: Int) -> Double {
        if sampleIndex % 55 == 0 { return 32 }
        if sampleIndex % 31 == 0 { return 18 }
        return 6 + (2.5 * abs(sin(Double(sampleIndex) / 8)))
    }

    private func simulatedRouteConfidence(horizontalAccuracyMeters: Double) -> RouteSegmentConfidence {
        if horizontalAccuracyMeters <= 10 { return .high }
        if horizontalAccuracyMeters <= 25 { return .medium }
        return .low
    }

    private func simulatedAcceleration(elapsedSeconds: TimeInterval) -> ThreeAxisValue {
        ThreeAxisValue(
            x: 0.05 + (0.03 * sin(elapsedSeconds / 1.7)),
            y: 0.08 + (0.04 * sin(elapsedSeconds / 2.1)),
            z: 0.98 + (0.02 * sin(elapsedSeconds / 3.2))
        )
    }

    private func simulatedGyroscope(elapsedSeconds: TimeInterval) -> ThreeAxisValue {
        ThreeAxisValue(
            x: 0.018 * sin(elapsedSeconds / 1.8),
            y: 0.026 * sin(elapsedSeconds / 2.6),
            z: 0.012 * sin(elapsedSeconds / 3.4)
        )
    }

    private static func haversineDistanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
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
}

private extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1_000).rounded())
    }
}
#else
extension SessionRecordingCoordinator {
    func stopMockSampleFeed() {}
}
#endif
