// [協作區] Shared/Models/MotionSample.swift
// 用途：定義 GPS、速度、加速度、陀螺儀、高度與定位品質診斷的單筆跨平台感測樣本。
// 委派至：SensorProvider、session recording、fall detection 與後續分析引擎。

import Foundation

struct GeoCoordinate: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct ThreeAxisValue: Codable, Sendable, Equatable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

enum LocationSpeedSource: String, Codable, Sendable, Equatable {
    case coreLocation
    case coordinateDerived
    case stale
    case unavailable
}

enum LocationFreshnessState: String, Codable, Sendable, Equatable {
    case fresh
    case recent
    case stale
    case unavailable
}

enum RouteSegmentConfidence: String, Codable, Sendable, Equatable {
    case high
    case medium
    case low
    case unavailable
}

struct LocationFixDiagnostics: Codable, Sendable, Equatable {
    let horizontalAccuracyMeters: Double?
    let verticalAccuracyMeters: Double?
    let speedAccuracyMetersPerSecond: Double?
    let courseAccuracyDegrees: Double?
    let rawLocationTimestamp: Date?
    let rawLocationTimestampMillisecondsSince1970: Int64?
    let gpsUpdateIntervalSeconds: TimeInterval?
    let gpsSegmentDistanceMeters: Double?
    let coordinateDerivedSpeedKmh: Double?
    let speedSource: LocationSpeedSource
    let freshnessState: LocationFreshnessState
    let routeSegmentConfidence: RouteSegmentConfidence

    init(
        horizontalAccuracyMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        speedAccuracyMetersPerSecond: Double? = nil,
        courseAccuracyDegrees: Double? = nil,
        rawLocationTimestamp: Date? = nil,
        rawLocationTimestampMillisecondsSince1970: Int64? = nil,
        gpsUpdateIntervalSeconds: TimeInterval? = nil,
        gpsSegmentDistanceMeters: Double? = nil,
        coordinateDerivedSpeedKmh: Double? = nil,
        speedSource: LocationSpeedSource = .unavailable,
        freshnessState: LocationFreshnessState = .unavailable,
        routeSegmentConfidence: RouteSegmentConfidence = .unavailable
    ) {
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond
        self.courseAccuracyDegrees = courseAccuracyDegrees
        self.rawLocationTimestamp = rawLocationTimestamp
        self.rawLocationTimestampMillisecondsSince1970 = rawLocationTimestampMillisecondsSince1970
        self.gpsUpdateIntervalSeconds = gpsUpdateIntervalSeconds
        self.gpsSegmentDistanceMeters = gpsSegmentDistanceMeters
        self.coordinateDerivedSpeedKmh = coordinateDerivedSpeedKmh
        self.speedSource = speedSource
        self.freshnessState = freshnessState
        self.routeSegmentConfidence = routeSegmentConfidence
    }
}

struct RouteQualitySummary: Codable, Sendable, Equatable {
    let sampleCount: Int
    let gpsSampleCount: Int
    let uniqueCoordinateCount: Int
    let lowConfidenceSegmentCount: Int
    let staleLocationSampleCount: Int
    let averageGPSUpdateIntervalSeconds: TimeInterval?
    let maxGPSUpdateIntervalSeconds: TimeInterval?
    let totalGPSDistanceMeters: Double

    init(
        sampleCount: Int,
        gpsSampleCount: Int,
        uniqueCoordinateCount: Int,
        lowConfidenceSegmentCount: Int,
        staleLocationSampleCount: Int,
        averageGPSUpdateIntervalSeconds: TimeInterval? = nil,
        maxGPSUpdateIntervalSeconds: TimeInterval? = nil,
        totalGPSDistanceMeters: Double = 0
    ) {
        self.sampleCount = max(0, sampleCount)
        self.gpsSampleCount = max(0, gpsSampleCount)
        self.uniqueCoordinateCount = max(0, uniqueCoordinateCount)
        self.lowConfidenceSegmentCount = max(0, lowConfidenceSegmentCount)
        self.staleLocationSampleCount = max(0, staleLocationSampleCount)
        self.averageGPSUpdateIntervalSeconds = averageGPSUpdateIntervalSeconds
        self.maxGPSUpdateIntervalSeconds = maxGPSUpdateIntervalSeconds
        self.totalGPSDistanceMeters = max(0, totalGPSDistanceMeters)
    }

    static func make(from samples: [MotionSample]) -> RouteQualitySummary {
        var uniqueCoordinates = Set<String>()
        var lowConfidenceSegmentCount = 0
        var staleLocationSampleCount = 0
        var updateIntervals: [TimeInterval] = []
        var totalGPSDistanceMeters = 0.0
        var lastDiagnosticsLocationKey: String?
        var previousCoordinate: GeoCoordinate?
        var previousTimestamp: Date?

        for sample in samples {
            guard let coordinate = sample.gpsCoordinate else { continue }
            uniqueCoordinates.insert(Self.coordinateKey(for: coordinate))

            if let diagnostics = sample.locationDiagnostics {
                if diagnostics.freshnessState == .stale {
                    staleLocationSampleCount += 1
                }

                let diagnosticsLocationKey = diagnostics.rawLocationTimestampMillisecondsSince1970.map(String.init)
                    ?? Self.coordinateKey(for: coordinate)
                guard diagnosticsLocationKey != lastDiagnosticsLocationKey else { continue }
                lastDiagnosticsLocationKey = diagnosticsLocationKey

                if diagnostics.routeSegmentConfidence == .low {
                    lowConfidenceSegmentCount += 1
                }
                if let interval = diagnostics.gpsUpdateIntervalSeconds, interval > 0 {
                    updateIntervals.append(interval)
                }
                if let distance = diagnostics.gpsSegmentDistanceMeters, distance > 0 {
                    totalGPSDistanceMeters += distance
                }
                continue
            }

            guard let lastCoordinate = previousCoordinate else {
                previousCoordinate = coordinate
                previousTimestamp = sample.timestamp
                continue
            }

            let segmentDistance = haversineDistanceMeters(from: lastCoordinate, to: coordinate)
            guard segmentDistance >= 0.5 else { continue }
            totalGPSDistanceMeters += segmentDistance

            if let previousTimestamp {
                let interval = max(sample.timestamp.timeIntervalSince(previousTimestamp), 0)
                if interval > 0 {
                    updateIntervals.append(interval)
                }
                if interval > 10 || segmentDistance > 100 {
                    lowConfidenceSegmentCount += 1
                }
            }

            previousCoordinate = coordinate
            previousTimestamp = sample.timestamp
        }

        let averageInterval = updateIntervals.isEmpty ? nil : updateIntervals.reduce(0, +) / Double(updateIntervals.count)
        return RouteQualitySummary(
            sampleCount: samples.count,
            gpsSampleCount: samples.filter { $0.gpsCoordinate != nil }.count,
            uniqueCoordinateCount: uniqueCoordinates.count,
            lowConfidenceSegmentCount: lowConfidenceSegmentCount,
            staleLocationSampleCount: staleLocationSampleCount,
            averageGPSUpdateIntervalSeconds: averageInterval,
            maxGPSUpdateIntervalSeconds: updateIntervals.max(),
            totalGPSDistanceMeters: totalGPSDistanceMeters
        )
    }

    private static func coordinateKey(for coordinate: GeoCoordinate) -> String {
        "\(coordinate.latitude.rounded(toPlaces: 7)),\(coordinate.longitude.rounded(toPlaces: 7))"
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

struct MotionSample: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let timestampMillisecondsSince1970: Int64?
    let gpsCoordinate: GeoCoordinate?
    let speedKmh: Double
    let accelerometerG: ThreeAxisValue
    let gyroscopeRadPS: ThreeAxisValue
    let altitudeMeters: Double?
    let locationDiagnostics: LocationFixDiagnostics?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        timestampMillisecondsSince1970: Int64? = nil,
        gpsCoordinate: GeoCoordinate? = nil,
        speedKmh: Double,
        accelerometerG: ThreeAxisValue,
        gyroscopeRadPS: ThreeAxisValue,
        altitudeMeters: Double? = nil,
        locationDiagnostics: LocationFixDiagnostics? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.timestampMillisecondsSince1970 = timestampMillisecondsSince1970 ?? timestamp.millisecondsSince1970
        self.gpsCoordinate = gpsCoordinate
        self.speedKmh = speedKmh
        self.accelerometerG = accelerometerG
        self.gyroscopeRadPS = gyroscopeRadPS
        self.altitudeMeters = altitudeMeters
        self.locationDiagnostics = locationDiagnostics
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1_000).rounded())
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
