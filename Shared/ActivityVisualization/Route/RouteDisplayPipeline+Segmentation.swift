// [協作區] Shared/ActivityVisualization/Route/RouteDisplayPipeline+Segmentation.swift
// Purpose: Builds display-only route segments and smoothing decisions without changing stored route geometry.
// Delegates to: ActivityRouteDisplayPoint semantics and GeoCoordinate distance helpers.

import Foundation

extension RouteDisplayPipeline {
    func makeRouteSegments(from points: [ActivityRouteDisplayPoint]) -> [RouteDisplaySegment] {
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

    func shouldStartNewRouteSegment(
        after previousPoint: ActivityRouteDisplayPoint,
        current point: ActivityRouteDisplayPoint
    ) -> Bool {
        if point.timestamp.timeIntervalSince(previousPoint.timestamp) > 12 { return true }
        let rawDistance = distanceMeters(from: previousPoint.rawCoordinate, to: point.rawCoordinate)
        let displayDistance = distanceMeters(from: previousPoint.displayCoordinate, to: point.displayCoordinate)
        return rawDistance > 55 && displayDistance > 40
    }

    func shouldSuppressSmallAreaJitter(
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

    func smoothDisplayCoordinate(
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

    func interpolatedCoordinate(
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

    func appendSegmentIfNeeded(
        _ points: [ActivityRouteDisplayPoint],
        semantic: RouteDisplaySemantic,
        id: Int,
        to segments: inout [RouteDisplaySegment]
    ) {
        guard points.count >= 2 else { return }
        segments.append(RouteDisplaySegment(id: id, points: points, semantic: semantic))
    }

}
