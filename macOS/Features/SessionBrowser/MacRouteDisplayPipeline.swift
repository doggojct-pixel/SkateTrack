// [協作區] macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift
// 用途：為 macOS read-only package viewer 建立與 iOS Summary 對齊的 display-route、speed、elevation 與指標衍生流程。
// 委派至：Shared RouteDisplayPipeline / MacSessionViewerModel / MacRouteMapContextView；只產生顯示模型，不修正、不重建、不寫回路線或 trusted metrics。

import Foundation

enum MacSessionMetricsDeriver {
    static func deriveMetrics(session: SessionData, samples: [MotionSample]) -> MacDerivedMetricsResult {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        let routeSamples = sortedSamples.compactMap { sample -> (timestamp: Date, coordinate: GeoCoordinate, speedKmh: Double)? in
            guard let coordinate = sample.gpsCoordinate else { return nil }
            return (routeTimestamp(for: sample), coordinate, sample.speedKmh)
        }
        let distanceKilometers = deriveDistanceKilometers(from: routeSamples)
        let routeResult = routeDisplayResult(session: session, samples: samples)
        let routePoints = routePoints(from: routeResult)
        let durationSeconds = max(0, session.durationSeconds ?? 0)
        let validSpeeds = sortedSamples.map(\.speedKmh).filter { $0.isFinite && $0 >= 0 }
        let maxSpeed = validSpeeds.max() ?? 0
        let averageSpeed = distanceKilometers > 0 && durationSeconds > 0
            ? distanceKilometers / (durationSeconds / 3600)
            : (validSpeeds.isEmpty ? 0 : validSpeeds.reduce(0, +) / Double(validSpeeds.count))
        let metrics = SessionSummaryMetrics(
            distanceKilometers: distanceKilometers,
            maxSpeedKilometersPerHour: maxSpeed,
            averageSpeedKilometersPerHour: averageSpeed,
            elevationGainMeters: deriveElevationGainMeters(from: sortedSamples),
            movingRatio: deriveMovingRatio(from: sortedSamples)
        )
        let quality = routeQuality(
            routeSampleCount: routeSamples.count,
            routePointCount: routePoints.count,
            distanceKilometers: distanceKilometers
        )
        let summary = MacRouteSummary(
            startCoordinate: routePoints.first?.displayCoordinate ?? routeSamples.first?.coordinate,
            finishCoordinate: routePoints.last?.displayCoordinate ?? routeSamples.last?.coordinate,
            routePointCount: routeSamples.count,
            uniqueRoutePointCount: routePoints.count,
            derivedDistanceKilometers: distanceKilometers,
            quality: quality,
            hasStartupWarmup: routePoints.contains(where: { $0.isStartupWarmup })
        )
        return MacDerivedMetricsResult(metrics: metrics, routeSummary: summary, routePoints: routePoints)
    }

    static func speedPoints(from samples: [MotionSample]) -> [MacSpeedPoint] {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let firstDate = sortedSamples.first?.timestamp else { return [] }
        let points = sortedSamples.compactMap { sample -> MacSpeedPoint? in
            guard sample.speedKmh.isFinite, sample.speedKmh >= 0 else { return nil }
            return MacSpeedPoint(
                timestamp: sample.timestamp,
                elapsedSeconds: sample.timestamp.timeIntervalSince(firstDate),
                speedKmh: sample.speedKmh
            )
        }
        return downsample(points: points, maxCount: 180)
    }

    private static func routeDisplayResult(session: SessionData, samples: [MotionSample]) -> RouteDisplayResult {
        let policy = ActivityFidelityPolicy(
            profile: session.fidelityProfile ?? ActivityFidelityProfile.defaultProfile(for: session.sportMode, powerType: session.powerType)
        )
        return RouteDisplayPipeline().makeDisplayRoute(
            samples: samples,
            startDate: session.startDate,
            fidelityPolicy: policy
        )
    }

    private static func routePoints(from result: RouteDisplayResult) -> [MacRoutePoint] {
        downsample(routePoints: result.points.map { macRoutePoint(from: $0) }, maxCount: 260)
    }

    private static func macRoutePoint(from point: ActivityRouteDisplayPoint) -> MacRoutePoint {
        MacRoutePoint(
            id: point.id,
            timestamp: point.timestamp,
            elapsedSeconds: point.elapsedSeconds,
            rawCoordinate: point.rawCoordinate,
            displayCoordinate: point.displayCoordinate,
            speedKmh: point.speedKilometersPerHour ?? 0,
            confidence: macRouteConfidence(for: point.confidence),
            horizontalAccuracyMeters: point.horizontalAccuracyMeters,
            isStartupWarmup: point.semantic == .startupWarmup
        )
    }

    private static func macRouteConfidence(for confidence: RouteDisplayConfidence) -> RouteSegmentConfidence {
        switch confidence {
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        case .unavailable:
            return .unavailable
        }
    }

    private static func deriveDistanceKilometers(from routeSamples: [(timestamp: Date, coordinate: GeoCoordinate, speedKmh: Double)]) -> Double {
        guard let first = routeSamples.first else { return 0 }
        var anchor = first
        var distanceMeters = 0.0
        for sample in routeSamples.dropFirst() {
            let segmentMeters = distanceMetersBetween(anchor.coordinate, sample.coordinate)
            guard segmentMeters >= 3 else { continue }
            let elapsedSeconds = max(sample.timestamp.timeIntervalSince(anchor.timestamp), 0.1)
            let impliedSpeedKmh = (segmentMeters / elapsedSeconds) * 3.6
            guard segmentMeters <= 2_000, impliedSpeedKmh <= 150 else {
                anchor = sample
                continue
            }
            distanceMeters += segmentMeters
            anchor = sample
        }
        return distanceMeters / 1_000
    }

    private static func routeQuality(routeSampleCount: Int, routePointCount: Int, distanceKilometers: Double) -> MacRouteVisualizationQuality {
        guard routeSampleCount >= 2, routePointCount >= 2, distanceKilometers > 0.01 else { return .unavailable }
        if routePointCount < 6 || distanceKilometers < 0.05 { return .limited }
        return .usable
    }

    private static func deriveMovingRatio(from samples: [MotionSample]) -> Double {
        guard samples.count > 1 else { return 0 }
        return min(1, max(0, Double(samples.filter { $0.speedKmh >= 1 }.count) / Double(samples.count)))
    }

    private static func deriveElevationGainMeters(from samples: [MotionSample]) -> Double {
        let altitudes = samples.compactMap(\.altitudeMeters)
        guard altitudes.count > 1 else { return 0 }
        var gain = 0.0
        var previous = altitudes[0]
        for altitude in altitudes.dropFirst() {
            let delta = altitude - previous
            if delta > 0 { gain += delta }
            previous = altitude
        }
        return gain
    }

    private static func routeTimestamp(for sample: MotionSample) -> Date {
        sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
    }

    private static func distanceMetersBetween(_ first: GeoCoordinate, _ second: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitude1 = first.latitude * .pi / 180
        let latitude2 = second.latitude * .pi / 180
        let deltaLatitude = (second.latitude - first.latitude) * .pi / 180
        let deltaLongitude = (second.longitude - first.longitude) * .pi / 180
        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(latitude1) * cos(latitude2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }

    private static func downsample(points: [MacSpeedPoint], maxCount: Int) -> [MacSpeedPoint] {
        guard points.count > maxCount, maxCount > 0 else { return points }
        let stride = max(1, Int(ceil(Double(points.count) / Double(maxCount))))
        return points.enumerated().compactMap { index, point in index % stride == 0 || index == points.count - 1 ? point : nil }
    }

    private static func downsample(routePoints: [MacRoutePoint], maxCount: Int) -> [MacRoutePoint] {
        guard routePoints.count > maxCount, maxCount > 0 else { return routePoints }
        let stride = max(1, Int(ceil(Double(routePoints.count) / Double(maxCount))))
        return routePoints.enumerated().compactMap { index, point in index % stride == 0 || index == routePoints.count - 1 ? point : nil }
    }
}
