// [協作區] Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift
// Purpose: Extracts display-only route preparation into Shared without changing platform renderers.
// Delegates to: MotionSample source-of-truth data, ActivityFidelityPolicy, and platform-specific renderers.

import Foundation

struct RouteDisplayPipeline: Equatable, Sendable {
    private static let startupStableAnchorClusterWindowSeconds: TimeInterval = 7
    private static let startupStableAnchorMinimumCandidateCount = 3
    private static let startupGPSLockSearchWindowSeconds: TimeInterval = 60
    private static let startupConvergenceWarmupSeconds: TimeInterval = 45
    private static let startupRouteVisualSuppressionMaximumSeconds: TimeInterval = 45

    let configuration: RouteDisplayConfiguration

    init(configuration: RouteDisplayConfiguration = RouteDisplayConfiguration()) {
        self.configuration = configuration
    }

    func makeDisplayRoute(
        samples: [MotionSample],
        startDate: Date,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> RouteDisplayResult {
        let candidates = deduplicatedTrustedLocationFixes(from: samples, fidelityPolicy: fidelityPolicy)
        guard !candidates.isEmpty else {
            return emptyResult(rawSampleCount: samples.count, droppedSampleCount: samples.count)
        }

        let gpsLockAnchorTimestamp = firstGPSLockAnchorTimestamp(
            from: candidates,
            startDate: startDate,
            fidelityPolicy: fidelityPolicy
        )
        let stableStartupAnchorTimestamp = firstStableStartupAnchorTimestamp(
            gpsLockAnchorTimestamp: gpsLockAnchorTimestamp,
            fidelityPolicy: fidelityPolicy
        )
        let points = makeDisplayPoints(
            from: candidates,
            startDate: startDate,
            fidelityPolicy: fidelityPolicy,
            stableStartupAnchorTimestamp: stableStartupAnchorTimestamp,
            gpsLockAnchorTimestamp: gpsLockAnchorTimestamp
        )
        let segments = makeRouteSegments(from: points)

        return RouteDisplayResult(
            points: points,
            segments: segments,
            summary: RouteDisplaySummary(
                quality: quality(for: points),
                rawSampleCount: samples.count,
                displayPointCount: points.count,
                segmentCount: segments.count,
                hasLowConfidenceSegments: points.contains { $0.semantic == .lowConfidence },
                hasStartupWarmup: points.contains { $0.semantic == .startupWarmup },
                bounds: bounds(for: points.map(\.displayCoordinate))
            ),
            diagnostics: RouteDisplayDiagnostics(
                messages: diagnosticsMessages(for: points),
                droppedSampleCount: max(0, samples.count - points.count)
            )
        )
    }

    private func makeDisplayPoints(
        from candidates: [MotionSample],
        startDate: Date,
        fidelityPolicy: ActivityFidelityPolicy,
        stableStartupAnchorTimestamp: Date?,
        gpsLockAnchorTimestamp: Date?
    ) -> [ActivityRouteDisplayPoint] {
        var displayPoints: [ActivityRouteDisplayPoint] = []
        var previousDisplayCoordinate: GeoCoordinate?
        var previousRawCoordinate: GeoCoordinate?
        var pointID = 0

        for sample in candidates {
            guard let rawCoordinate = validCoordinate(from: sample) else { continue }
            let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
            let hasReliableAnchor = displayPoints.contains(where: isReliableAnchor)
            let isStartupWarmup = isStartupWarmupSample(
                sample,
                startDate: startDate,
                fidelityPolicy: fidelityPolicy,
                stableStartupAnchorTimestamp: stableStartupAnchorTimestamp,
                gpsLockAnchorTimestamp: gpsLockAnchorTimestamp,
                hasReliableAnchor: hasReliableAnchor
            )
            let semantic = semantic(for: confidence, isStartupWarmup: isStartupWarmup)
            let isFirstReliableAnchor = !hasReliableAnchor && isReliableAnchor(semantic: semantic)

            if semantic != .startupWarmup,
               !isFirstReliableAnchor,
               let previousDisplayCoordinate,
               let previousRawCoordinate,
               shouldSuppressSmallAreaJitter(
                   from: previousRawCoordinate,
                   previousDisplayCoordinate: previousDisplayCoordinate,
                   to: rawCoordinate,
                   sample: sample
               ) {
                continue
            }

            let displayCoordinate: GeoCoordinate
            if isFirstReliableAnchor {
                displayCoordinate = rawCoordinate
            } else if let previousDisplayCoordinate {
                displayCoordinate = smoothDisplayCoordinate(
                    previous: previousDisplayCoordinate,
                    current: rawCoordinate,
                    sample: sample
                )
            } else {
                displayCoordinate = rawCoordinate
            }

            displayPoints.append(ActivityRouteDisplayPoint(
                id: pointID,
                timestamp: routeTimestamp(for: sample),
                elapsedSeconds: routeTimestamp(for: sample).timeIntervalSince(startDate),
                rawCoordinate: rawCoordinate,
                displayCoordinate: displayCoordinate,
                speedKilometersPerHour: sample.speedKmh,
                semantic: semantic,
                confidence: displayConfidence(for: confidence),
                horizontalAccuracyMeters: sample.locationDiagnostics?.horizontalAccuracyMeters
            ))
            previousRawCoordinate = rawCoordinate
            previousDisplayCoordinate = displayCoordinate
            pointID += 1
        }

        return displayPoints
    }

    private func deduplicatedTrustedLocationFixes(
        from samples: [MotionSample],
        fidelityPolicy: ActivityFidelityPolicy
    ) -> [MotionSample] {
        let primary = deduplicatedTrustedLocationFixes(
            from: samples,
            fidelityPolicy: fidelityPolicy,
            allowsTimerFusionFallback: false
        )
        if !primary.isEmpty { return primary }
        return deduplicatedTrustedLocationFixes(
            from: samples,
            fidelityPolicy: fidelityPolicy,
            allowsTimerFusionFallback: true
        )
    }

    private func deduplicatedTrustedLocationFixes(
        from samples: [MotionSample],
        fidelityPolicy: ActivityFidelityPolicy,
        allowsTimerFusionFallback: Bool
    ) -> [MotionSample] {
        var seenKeys = Set<String>()
        return samples.sorted { routeTimestamp(for: $0) < routeTimestamp(for: $1) }.compactMap { sample in
            guard validCoordinate(from: sample) != nil,
                  isTrustedDisplayRouteSample(
                      sample,
                      fidelityPolicy: fidelityPolicy,
                      allowsTimerFusionFallback: allowsTimerFusionFallback
                  ) else { return nil }
            let key = locationFixKey(for: sample)
            guard seenKeys.insert(key).inserted else { return nil }
            return sample
        }
    }

    private func isStartupWarmupSample(
        _ sample: MotionSample,
        startDate: Date,
        fidelityPolicy: ActivityFidelityPolicy,
        stableStartupAnchorTimestamp: Date?,
        gpsLockAnchorTimestamp: Date?,
        hasReliableAnchor: Bool
    ) -> Bool {
        let timestamp = routeTimestamp(for: sample)
        let elapsed = timestamp.timeIntervalSince(startDate)
        if elapsed < 0 { return elapsed >= -10 }
        guard !hasReliableAnchor else { return false }
        guard elapsed <= Self.startupConvergenceWarmupSeconds else { return false }
        guard let diagnostics = sample.locationDiagnostics else { return elapsed <= 8 }

        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        let warmupAccuracyLimit = max(fidelityPolicy.preferredHorizontalAccuracyMeters * 1.8, 18)
        if diagnostics.freshnessState == .stale { return true }
        if diagnostics.routeSegmentConfidence == .low || diagnostics.routeSegmentConfidence == .unavailable { return true }
        if accuracy > warmupAccuracyLimit { return true }

        if startupAnchorGuardApplies(fidelityPolicy: fidelityPolicy) {
            guard let stableStartupAnchorTimestamp else {
                return elapsed <= Self.startupConvergenceWarmupSeconds
                    && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
            }
            if timestamp < stableStartupAnchorTimestamp { return true }
            return elapsed <= Self.startupRouteVisualSuppressionMaximumSeconds
                && timestamp.timeIntervalSince(stableStartupAnchorTimestamp) <= 3
                && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
        }

        if let gpsLockAnchorTimestamp {
            return timestamp < gpsLockAnchorTimestamp
        }

        return elapsed <= 10 && !isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
    }

    private func firstStableStartupAnchorTimestamp(
        gpsLockAnchorTimestamp: Date?,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Date? {
        guard startupAnchorGuardApplies(fidelityPolicy: fidelityPolicy) else { return nil }
        return gpsLockAnchorTimestamp
    }

    private func startupAnchorGuardApplies(fidelityPolicy: ActivityFidelityPolicy) -> Bool {
        switch fidelityPolicy.profile {
        case .technicalSkateboard, .standardSkateboard, .electricSkateboard, .inlineRecreation:
            return true
        case .inlineSpeed, .snowReserved, .vehicleValidation:
            return fidelityPolicy.usesStrictSmallAreaLowSpeedGate
        }
    }

    private func firstGPSLockAnchorTimestamp(
        from candidates: [MotionSample],
        startDate: Date,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Date? {
        let lockCandidates = candidates.filter { sample in
            let elapsed = routeTimestamp(for: sample).timeIntervalSince(startDate)
            return elapsed >= 0
                && elapsed <= Self.startupGPSLockSearchWindowSeconds
                && isPreferredFreshAnchor(sample, fidelityPolicy: fidelityPolicy)
        }
        guard lockCandidates.count >= Self.startupStableAnchorMinimumCandidateCount else { return nil }

        for candidate in lockCandidates {
            let anchorTime = routeTimestamp(for: candidate)
            let cluster = lockCandidates.filter { sample in
                let delta = routeTimestamp(for: sample).timeIntervalSince(anchorTime)
                return delta >= 0 && delta <= Self.startupStableAnchorClusterWindowSeconds
            }
            guard cluster.count >= Self.startupStableAnchorMinimumCandidateCount else { continue }
            return anchorTime
        }

        return nil
    }

    private func isPreferredFreshAnchor(
        _ sample: MotionSample,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Bool {
        guard let diagnostics = sample.locationDiagnostics else { return false }
        let accuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
        return diagnostics.freshnessState == .fresh
            && diagnostics.routeSegmentConfidence == .high
            && accuracy <= fidelityPolicy.preferredHorizontalAccuracyMeters
    }

    private func isTrustedDisplayRouteSample(
        _ sample: MotionSample,
        fidelityPolicy: ActivityFidelityPolicy,
        allowsTimerFusionFallback: Bool
    ) -> Bool {
        guard allowsTimerFusionFallback
                || sample.sampleSource != .timerFusion
                || sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 == nil else {
            return false
        }

        guard let diagnostics = sample.locationDiagnostics else { return true }
        if diagnostics.freshnessState == .stale { return false }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > max(12, fidelityPolicy.maximumTrustedUpdateIntervalSeconds + 4) }) == true { return false }
        if diagnostics.horizontalAccuracyMeters.map({ $0 > fidelityPolicy.displayRouteMaximumHorizontalAccuracyMeters }) == true { return false }
        if diagnostics.coordinateDerivedSpeedKmh.map({ $0 > fidelityPolicy.maximumTrustedImpliedSpeedKmh }) == true { return false }
        return true
    }

    private func makeRouteSegments(from points: [ActivityRouteDisplayPoint]) -> [RouteDisplaySegment] {
        var segments: [RouteDisplaySegment] = []
        var currentPoints: [ActivityRouteDisplayPoint] = []
        var currentSemantic: RouteDisplaySemantic?
        var segmentID = 0
        var previousPoint: ActivityRouteDisplayPoint?

        for point in points.sorted(by: { $0.timestamp < $1.timestamp }) {
            let pointSemantic = point.semantic
            if let previousPoint, shouldStartNewRouteSegment(after: previousPoint, current: point) {
                appendSegmentIfNeeded(currentPoints, semantic: currentSemantic ?? .highConfidence, id: segmentID, to: &segments)
                currentPoints = []
                currentSemantic = pointSemantic
                segmentID += 1
            } else if let previousPoint,
                      let existingSemantic = currentSemantic,
                      existingSemantic != pointSemantic {
                appendSegmentIfNeeded(currentPoints, semantic: existingSemantic, id: segmentID, to: &segments)
                currentPoints = pointSemantic == .highConfidence ? [] : [previousPoint]
                currentSemantic = pointSemantic
                segmentID += 1
            } else if currentSemantic == nil {
                currentSemantic = pointSemantic
            }

            currentPoints.append(point)
            previousPoint = point
        }

        appendSegmentIfNeeded(currentPoints, semantic: currentSemantic ?? .highConfidence, id: segmentID, to: &segments)
        return segments
    }

    private func validCoordinate(from sample: MotionSample) -> GeoCoordinate? {
        guard let coordinate = sample.gpsCoordinate,
              coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              (-90.0...90.0).contains(coordinate.latitude),
              (-180.0...180.0).contains(coordinate.longitude) else {
            return nil
        }
        return coordinate
    }

    private func shouldStartNewRouteSegment(
        after previousPoint: ActivityRouteDisplayPoint,
        current point: ActivityRouteDisplayPoint
    ) -> Bool {
        if point.timestamp.timeIntervalSince(previousPoint.timestamp) > 12 { return true }
        let rawDistance = distanceMeters(from: previousPoint.rawCoordinate, to: point.rawCoordinate)
        let displayDistance = distanceMeters(from: previousPoint.displayCoordinate, to: point.displayCoordinate)
        return rawDistance > 55 && displayDistance > 40
    }

    private func shouldSuppressSmallAreaJitter(
        from previousRawCoordinate: GeoCoordinate,
        previousDisplayCoordinate: GeoCoordinate,
        to rawCoordinate: GeoCoordinate,
        sample: MotionSample
    ) -> Bool {
        let rawDistance = distanceMeters(from: previousRawCoordinate, to: rawCoordinate)
        let displayDistance = distanceMeters(from: previousDisplayCoordinate, to: rawCoordinate)
        let horizontalAccuracy = sample.locationDiagnostics?.horizontalAccuracyMeters ?? 12
        let speed = max(sample.speedKmh, sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? 0)
        let jitterThreshold = min(max(horizontalAccuracy * 0.18, 1.25), 4.0)
        guard speed < 4.5 else { return false }
        return rawDistance < jitterThreshold && displayDistance < max(jitterThreshold, 1.75)
    }

    private func smoothDisplayCoordinate(
        previous: GeoCoordinate,
        current: GeoCoordinate,
        sample: MotionSample
    ) -> GeoCoordinate {
        let distance = distanceMeters(from: previous, to: current)
        guard distance.isFinite, distance > 0 else { return previous }

        let horizontalAccuracy = sample.locationDiagnostics?.horizontalAccuracyMeters ?? 12
        let confidence = sample.locationDiagnostics?.routeSegmentConfidence ?? .medium
        let speed = max(sample.speedKmh, sample.locationDiagnostics?.coordinateDerivedSpeedKmh ?? 0)

        let weight: Double
        if distance > 18 || speed > 12 {
            weight = 0.82
        } else if confidence == .high && horizontalAccuracy <= 6 {
            weight = 0.68
        } else if horizontalAccuracy <= 12 {
            weight = 0.52
        } else {
            weight = 0.34
        }

        return interpolatedCoordinate(from: previous, to: current, weight: weight)
    }

    private func interpolatedCoordinate(
        from previous: GeoCoordinate,
        to current: GeoCoordinate,
        weight: Double
    ) -> GeoCoordinate {
        let clampedWeight = min(max(weight, 0), 1)
        return GeoCoordinate(
            latitude: previous.latitude + (current.latitude - previous.latitude) * clampedWeight,
            longitude: previous.longitude + (current.longitude - previous.longitude) * clampedWeight
        )
    }

    private func appendSegmentIfNeeded(
        _ points: [ActivityRouteDisplayPoint],
        semantic: RouteDisplaySemantic,
        id: Int,
        to segments: inout [RouteDisplaySegment]
    ) {
        guard points.count >= 2 else { return }
        segments.append(RouteDisplaySegment(id: id, points: points, semantic: semantic))
    }

    private func semantic(
        for confidence: RouteSegmentConfidence,
        isStartupWarmup: Bool
    ) -> RouteDisplaySemantic {
        if isStartupWarmup { return .startupWarmup }
        return confidence == .low || confidence == .unavailable ? .lowConfidence : .highConfidence
    }

    private func displayConfidence(for confidence: RouteSegmentConfidence) -> RouteDisplayConfidence {
        switch confidence {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .unavailable: return .unavailable
        }
    }

    private func isReliableAnchor(_ point: ActivityRouteDisplayPoint) -> Bool {
        isReliableAnchor(semantic: point.semantic)
    }

    private func isReliableAnchor(semantic: RouteDisplaySemantic) -> Bool {
        semantic == .highConfidence
    }

    private func routeTimestamp(for sample: MotionSample) -> Date {
        sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
    }

    private func locationFixKey(for sample: MotionSample) -> String {
        if let timestamp = sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 {
            return "locationFix:\(timestamp)"
        }

        if let coordinate = sample.gpsCoordinate {
            let latitude = (coordinate.latitude * 100_000).rounded() / 100_000
            let longitude = (coordinate.longitude * 100_000).rounded() / 100_000
            let second = Int(sample.timestamp.timeIntervalSince1970.rounded())
            return "coordinate:\(latitude):\(longitude):\(second)"
        }

        return sample.id.uuidString
    }

    private func distanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
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

    private func bounds(for coordinates: [GeoCoordinate]) -> RouteDisplayBounds? {
        guard !coordinates.isEmpty else { return nil }
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        return RouteDisplayBounds(
            minimumLatitude: latitudes.min() ?? 0,
            maximumLatitude: latitudes.max() ?? 0,
            minimumLongitude: longitudes.min() ?? 0,
            maximumLongitude: longitudes.max() ?? 0
        )
    }

    private func quality(for points: [ActivityRouteDisplayPoint]) -> ActivityVisualizationQuality {
        if points.count >= 2 { return .usable }
        if points.count == 1 { return .limited }
        return .unavailable
    }

    private func diagnosticsMessages(for points: [ActivityRouteDisplayPoint]) -> [String] {
        guard points.isEmpty else { return [] }
        return ["route.display.noUsableCoordinates"]
    }

    private func emptyResult(rawSampleCount: Int, droppedSampleCount: Int) -> RouteDisplayResult {
        RouteDisplayResult(
            summary: RouteDisplaySummary(
                quality: .unavailable,
                rawSampleCount: rawSampleCount,
                displayPointCount: 0,
                segmentCount: 0
            ),
            diagnostics: RouteDisplayDiagnostics(
                messages: ["route.display.noUsableCoordinates"],
                droppedSampleCount: droppedSampleCount
            )
        )
    }
}
