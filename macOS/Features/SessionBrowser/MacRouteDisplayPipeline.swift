// [協作區] macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift
// 用途：為 macOS read-only package viewer 建立與 iOS Summary 對齊的 display-route 分段、暖機、平滑與指標衍生流程。
// 委派至：MacSessionViewerModel / MacRouteMapContextView；只產生顯示模型，不修正、不重建、不寫回路線或 trusted metrics。

import Foundation

enum MacSessionMetricsDeriver {
    private static let startupStableAnchorClusterWindowSeconds: TimeInterval = 7
    private static let startupStableAnchorMinimumCandidateCount = 3
    private static let startupGPSLockSearchWindowSeconds: TimeInterval = 60
    private static let startupConvergenceWarmupSeconds: TimeInterval = 45
    private static let startupRouteVisualSuppressionMaximumSeconds: TimeInterval = 45

    static func deriveMetrics(session: SessionData, samples: [MotionSample]) -> MacDerivedMetricsResult {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        let routeSamples = sortedSamples.compactMap { sample -> (timestamp: Date, coordinate: GeoCoordinate, speedKmh: Double)? in
            guard let coordinate = sample.gpsCoordinate else { return nil }
            return (routeTimestamp(for: sample), coordinate, sample.speedKmh)
        }
        let distanceKilometers = deriveDistanceKilometers(from: routeSamples)
        let routePoints = routePoints(session: session, from: samples)
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

    private static func routePoints(session: SessionData, from samples: [MotionSample]) -> [MacRoutePoint] {
        let candidates = deduplicatedTrustedLocationFixes(from: samples)
        guard let first = candidates.first else { return [] }
        let firstDate = routeTimestamp(for: first)
        let policy = ActivityFidelityPolicy(
            profile: session.fidelityProfile ?? ActivityFidelityProfile.defaultProfile(for: session.sportMode, powerType: session.powerType)
        )
        let gpsLockTimestamp = firstGPSLockAnchorTimestamp(from: candidates, session: session, fidelityPolicy: policy)
        var displayPoints: [MacRoutePoint] = []
        var previousDisplayCoordinate: GeoCoordinate?
        var previousRawCoordinate: GeoCoordinate?
        var pointID = 0

        for sample in candidates {
            guard let rawCoordinate = sample.gpsCoordinate else { continue }
            let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
            let hasReliableAnchor = displayPoints.contains(where: { $0.isReliableAnchor })
            let isStartup = isStartupWarmupSample(
                sample,
                session: session,
                fidelityPolicy: policy,
                stableStartupAnchorTimestamp: gpsLockTimestamp,
                gpsLockAnchorTimestamp: gpsLockTimestamp,
                hasReliableAnchor: hasReliableAnchor
            )
            let isFirstReliableAnchor = !hasReliableAnchor && !isStartup && confidence != .low && confidence != .unavailable
            if shouldSkipJitter(
                isFirstReliableAnchor: isFirstReliableAnchor,
                previousDisplayCoordinate: previousDisplayCoordinate,
                previousRawCoordinate: previousRawCoordinate,
                rawCoordinate: rawCoordinate,
                sample: sample
            ) { continue }

            let displayCoordinate = displayCoordinateForPoint(
                isFirstReliableAnchor: isFirstReliableAnchor,
                previousDisplayCoordinate: previousDisplayCoordinate,
                rawCoordinate: rawCoordinate,
                sample: sample
            )
            displayPoints.append(MacRoutePoint(
                id: pointID,
                timestamp: routeTimestamp(for: sample),
                elapsedSeconds: routeTimestamp(for: sample).timeIntervalSince(firstDate),
                rawCoordinate: rawCoordinate,
                displayCoordinate: displayCoordinate,
                speedKmh: sample.speedKmh,
                confidence: confidence,
                horizontalAccuracyMeters: sample.locationDiagnostics?.horizontalAccuracyMeters,
                isStartupWarmup: isStartup
            ))
            previousRawCoordinate = rawCoordinate
            previousDisplayCoordinate = displayCoordinate
            pointID += 1
        }
        return downsample(routePoints: displayPoints, maxCount: 260)
    }

    private static func shouldSkipJitter(
        isFirstReliableAnchor: Bool,
        previousDisplayCoordinate: GeoCoordinate?,
        previousRawCoordinate: GeoCoordinate?,
        rawCoordinate: GeoCoordinate,
        sample: MotionSample
    ) -> Bool {
        guard !isFirstReliableAnchor,
              let previousDisplayCoordinate,
              let previousRawCoordinate else { return false }
        return shouldSuppressSmallAreaJitter(
            from: previousRawCoordinate,
            previousDisplayCoordinate: previousDisplayCoordinate,
            to: rawCoordinate,
            sample: sample
        )
    }

    private static func displayCoordinateForPoint(
        isFirstReliableAnchor: Bool,
        previousDisplayCoordinate: GeoCoordinate?,
        rawCoordinate: GeoCoordinate,
        sample: MotionSample
    ) -> GeoCoordinate {
        if isFirstReliableAnchor { return rawCoordinate }
        guard let previousDisplayCoordinate else { return rawCoordinate }
        return smoothDisplayCoordinate(previous: previousDisplayCoordinate, current: rawCoordinate, sample: sample)
    }

    private static func deduplicatedTrustedLocationFixes(from samples: [MotionSample]) -> [MotionSample] {
        let primary = deduplicatedTrustedLocationFixes(from: samples, allowsTimerFusionFallback: false)
        return primary.isEmpty ? deduplicatedTrustedLocationFixes(from: samples, allowsTimerFusionFallback: true) : primary
    }

    private static func deduplicatedTrustedLocationFixes(from samples: [MotionSample], allowsTimerFusionFallback: Bool) -> [MotionSample] {
        var seenKeys = Set<String>()
        return samples.sorted { routeTimestamp(for: $0) < routeTimestamp(for: $1) }.compactMap { sample in
            guard sample.gpsCoordinate != nil,
                  isTrustedDisplayRouteSample(sample, allowsTimerFusionFallback: allowsTimerFusionFallback) else { return nil }
            guard seenKeys.insert(locationFixKey(for: sample)).inserted else { return nil }
            return sample
        }
    }

    private static func isStartupWarmupSample(
        _ sample: MotionSample,
        session: SessionData,
        fidelityPolicy: ActivityFidelityPolicy,
        stableStartupAnchorTimestamp: Date?,
        gpsLockAnchorTimestamp: Date?,
        hasReliableAnchor: Bool
    ) -> Bool {
        let timestamp = routeTimestamp(for: sample)
        let elapsed = timestamp.timeIntervalSince(session.startDate)
        if elapsed < 0 { return elapsed >= -10 }
        guard !hasReliableAnchor, elapsed <= startupConvergenceWarmupSeconds else { return false }
        guard let diagnostics = sample.locationDiagnostics else { return elapsed <= 8 }

        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        let warmupAccuracyLimit = max(fidelityPolicy.preferredHorizontalAccuracyMeters * 1.8, 18)
        if diagnostics.freshnessState == .stale { return true }
        if diagnostics.routeSegmentConfidence == .low || diagnostics.routeSegmentConfidence == .unavailable { return true }
        if accuracy > warmupAccuracyLimit { return true }
        if startupAnchorGuardApplies(fidelityPolicy: fidelityPolicy) {
            return startupGuardWarmup(
                sample: sample,
                elapsed: elapsed,
                timestamp: timestamp,
                stableStartupAnchorTimestamp: stableStartupAnchorTimestamp,
                fidelityPolicy: fidelityPolicy
            )
        }
        if let gpsLockAnchorTimestamp { return timestamp < gpsLockAnchorTimestamp }
        return elapsed <= 10 && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
    }

    private static func startupGuardWarmup(
        sample: MotionSample,
        elapsed: TimeInterval,
        timestamp: Date,
        stableStartupAnchorTimestamp: Date?,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Bool {
        guard let stableStartupAnchorTimestamp else {
            return elapsed <= startupConvergenceWarmupSeconds && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
        }
        if timestamp < stableStartupAnchorTimestamp { return true }
        return elapsed <= startupRouteVisualSuppressionMaximumSeconds
            && timestamp.timeIntervalSince(stableStartupAnchorTimestamp) <= 3
            && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
    }

    private static func startupAnchorGuardApplies(fidelityPolicy: ActivityFidelityPolicy) -> Bool {
        switch fidelityPolicy.profile {
        case .technicalSkateboard, .standardSkateboard, .electricSkateboard, .inlineRecreation:
            return true
        case .inlineSpeed, .snowReserved, .vehicleValidation:
            return fidelityPolicy.usesStrictSmallAreaLowSpeedGate
        }
    }

    private static func firstGPSLockAnchorTimestamp(from candidates: [MotionSample], session: SessionData, fidelityPolicy: ActivityFidelityPolicy) -> Date? {
        let lockCandidates = candidates.filter { sample in
            let elapsed = routeTimestamp(for: sample).timeIntervalSince(session.startDate)
            return elapsed >= 0 && elapsed <= startupGPSLockSearchWindowSeconds && isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
        }
        guard lockCandidates.count >= startupStableAnchorMinimumCandidateCount else { return nil }
        for candidate in lockCandidates {
            let anchorTime = routeTimestamp(for: candidate)
            let cluster = lockCandidates.filter { sample in
                let delta = routeTimestamp(for: sample).timeIntervalSince(anchorTime)
                return delta >= 0 && delta <= startupStableAnchorClusterWindowSeconds
            }
            if cluster.count >= startupStableAnchorMinimumCandidateCount { return anchorTime }
        }
        return nil
    }

    private static func isPreferredFreshAnchor(_ sample: MotionSample, fidelityPolicy: ActivityFidelityPolicy) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return false }
        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        return diagnostics.freshnessState == .fresh
            && diagnostics.routeSegmentConfidence == .high
            && accuracy <= fidelityPolicy.preferredHorizontalAccuracyMeters
    }

    private static func isTrustedDisplayRouteSample(_ sample: MotionSample, allowsTimerFusionFallback: Bool) -> Bool {
        if !allowsTimerFusionFallback && sample.sampleSource == .timerFusion && sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 != nil { return false }
        guard let diagnostics = sample.locationDiagnostics else { return true }
        if diagnostics.freshnessState == .stale { return false }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > 12 }) == true { return false }
        if diagnostics.horizontalAccuracyMeters.map({ $0 > 45 }) == true { return false }
        if diagnostics.coordinateDerivedSpeedKmh.map({ $0 > 150 }) == true { return false }
        return true
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

    private static func shouldSuppressSmallAreaJitter(from previousRawCoordinate: GeoCoordinate, previousDisplayCoordinate: GeoCoordinate, to rawCoordinate: GeoCoordinate, sample: MotionSample) -> Bool {
        let rawDistance = distanceMetersBetween(previousRawCoordinate, rawCoordinate)
        let displayDistance = distanceMetersBetween(previousDisplayCoordinate, rawCoordinate)
        let horizontalAccuracy = sample.locationDiagnostics?.horizontalAccuracyMeters ?? 12
        let speed = max(sample.speedKmh, sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? 0)
        let jitterThreshold = min(max(horizontalAccuracy * 0.18, 1.25), 4.0)
        guard speed < 4.5 else { return false }
        return rawDistance < jitterThreshold && displayDistance < max(jitterThreshold, 1.75)
    }

    private static func smoothDisplayCoordinate(previous: GeoCoordinate, current: GeoCoordinate, sample: MotionSample) -> GeoCoordinate {
        let distance = distanceMetersBetween(previous, current)
        guard distance.isFinite, distance > 0 else { return previous }
        let horizontalAccuracy = sample.locationDiagnostics?.horizontalAccuracyMeters ?? 12
        let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
        let speed = max(sample.speedKmh, sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? 0)
        let weight = smoothingWeight(distance: distance, horizontalAccuracy: horizontalAccuracy, confidence: confidence, speed: speed)
        return GeoCoordinate(
            latitude: previous.latitude + (current.latitude - previous.latitude) * weight,
            longitude: previous.longitude + (current.longitude - previous.longitude) * weight
        )
    }

    private static func smoothingWeight(distance: Double, horizontalAccuracy: Double, confidence: RouteSegmentConfidence, speed: Double) -> Double {
        if distance > 18 || speed > 12 { return 0.82 }
        if confidence == .high && horizontalAccuracy <= 6 { return 0.68 }
        if horizontalAccuracy <= 12 { return 0.52 }
        return 0.34
    }

    private static func locationFixKey(for sample: MotionSample) -> String {
        if let timestamp = sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 { return "locationFix:\(timestamp)" }
        if let coordinate = sample.gpsCoordinate {
            let latitude = (coordinate.latitude * 100_000).rounded() / 100_000
            let longitude = (coordinate.longitude * 100_000).rounded() / 100_000
            let second = Int(sample.timestamp.timeIntervalSince1970.rounded())
            return "coordinate:\(latitude):\(longitude):\(second)"
        }
        return sample.id.uuidString
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
