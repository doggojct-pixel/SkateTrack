// [協作區] Shared/ActivityVisualization/ActivityVisualizationPipeline.swift
// Purpose: Provides an umbrella entry point for preparing route, speed, elevation, and compact display summaries together.
// Delegates to: Focused RouteDisplayPipeline, SpeedDisplayPipeline, ElevationDisplayPipeline, and platform renderers.

import Foundation

struct ActivityVisualizationPipeline: Equatable, Sendable {
    let configuration: ActivityVisualizationConfiguration

    init(configuration: ActivityVisualizationConfiguration = .standard) {
        self.configuration = configuration
    }

    func makeVisualization(
        samples: [MotionSample],
        startDate: Date? = nil,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> ActivityVisualizationResult {
        let visualizationStartDate = startDate
            ?? samples.map(\.timestamp).min()
            ?? Date(timeIntervalSince1970: 0)
        let route = RouteDisplayPipeline(configuration: configuration.route).makeDisplayRoute(
            samples: samples,
            startDate: visualizationStartDate,
            fidelityPolicy: fidelityPolicy
        )
        let speed = SpeedDisplayPipeline(configuration: configuration.speed).makeDisplaySpeed(
            samples: samples,
            startDate: visualizationStartDate,
            fidelityPolicy: fidelityPolicy
        )
        let elevation = ElevationDisplayPipeline(configuration: configuration.elevation).makeDisplayElevation(
            samples: samples,
            startDate: visualizationStartDate,
            fidelityPolicy: fidelityPolicy
        )
        let diagnostics = ActivityVisualizationDiagnostics(
            routeMessages: route.diagnostics.messages,
            speedMessages: speed.diagnostics.messages,
            elevationMessages: elevation.diagnostics.messages,
            droppedSampleCount: route.diagnostics.droppedSampleCount
                + speed.diagnostics.droppedSampleCount
                + elevation.diagnostics.droppedSampleCount,
            downsampledPointCount: speed.diagnostics.downsampledPointCount
                + elevation.diagnostics.downsampledPointCount
        )

        return ActivityVisualizationResult(
            route: route,
            speed: speed,
            elevation: elevation,
            compactSummary: ActivityVisualizationCompactSummary(
                route: route,
                speed: speed,
                elevation: elevation
            ),
            diagnostics: diagnostics
        )
    }
}
