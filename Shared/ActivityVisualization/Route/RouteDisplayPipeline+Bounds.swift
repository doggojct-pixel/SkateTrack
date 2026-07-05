// [協作區] Shared/ActivityVisualization/Route/RouteDisplayPipeline+Bounds.swift
// Purpose: Computes display-only route bounds, quality, diagnostics, and empty results.
// Delegates to: ActivityVisualization route display model shells.

import Foundation

extension RouteDisplayPipeline {
    func distanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
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

    func bounds(for coordinates: [GeoCoordinate]) -> RouteDisplayBounds? {
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

    func quality(for points: [ActivityRouteDisplayPoint]) -> ActivityVisualizationQuality {
        if points.count >= 2 { return .usable }
        if points.count == 1 { return .limited }
        return .unavailable
    }

    func diagnosticsMessages(for points: [ActivityRouteDisplayPoint]) -> [String] {
        guard points.isEmpty else { return [] }
        return ["route.display.noUsableCoordinates"]
    }

    func emptyResult(rawSampleCount: Int, droppedSampleCount: Int) -> RouteDisplayResult {
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
