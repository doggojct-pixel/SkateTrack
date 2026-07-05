// [協作區] Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift
// Purpose: Extracts display-only route preparation into Shared without changing platform renderers.
// Delegates to: MotionSample source-of-truth data, ActivityFidelityPolicy, and platform-specific renderers.

import Foundation

struct RouteDisplayPipeline: Equatable, Sendable {
    static let startupStableAnchorClusterWindowSeconds: TimeInterval = 7
    static let startupStableAnchorMinimumCandidateCount = 3
    static let startupGPSLockSearchWindowSeconds: TimeInterval = 60
    static let startupConvergenceWarmupSeconds: TimeInterval = 45
    static let startupRouteVisualSuppressionMaximumSeconds: TimeInterval = 45

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

    func semantic(
        for confidence: RouteSegmentConfidence,
        isStartupWarmup: Bool
    ) -> RouteDisplaySemantic {
        if isStartupWarmup { return .startupWarmup }
        return confidence == .low || confidence == .unavailable ? .lowConfidence : .highConfidence
    }

    func displayConfidence(for confidence: RouteSegmentConfidence) -> RouteDisplayConfidence {
        switch confidence {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .unavailable: return .unavailable
        }
    }

    func isReliableAnchor(_ point: ActivityRouteDisplayPoint) -> Bool {
        isReliableAnchor(semantic: point.semantic)
    }

    func isReliableAnchor(semantic: RouteDisplaySemantic) -> Bool {
        semantic == .highConfidence
    }

    func routeTimestamp(for sample: MotionSample) -> Date {
        sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
    }
}
