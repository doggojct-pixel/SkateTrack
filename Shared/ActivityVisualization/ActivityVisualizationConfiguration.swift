// [協作區] Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift
// Purpose: Defines platform-neutral display-preparation configuration shells for activity visualization.
// Delegates to: Route, speed, and elevation display pipelines that will be implemented in later subtasks.

import Foundation

struct ActivityVisualizationConfiguration: Equatable, Sendable {
    let route: RouteDisplayConfiguration
    let speed: SpeedDisplayConfiguration
    let elevation: ElevationDisplayConfiguration

    init(
        route: RouteDisplayConfiguration = RouteDisplayConfiguration(),
        speed: SpeedDisplayConfiguration = SpeedDisplayConfiguration(),
        elevation: ElevationDisplayConfiguration = ElevationDisplayConfiguration()
    ) {
        self.route = route
        self.speed = speed
        self.elevation = elevation
    }

    static let standard = ActivityVisualizationConfiguration()
}

struct ActivityVisualizationPreparedSummary: Equatable, Sendable {
    let route: RouteDisplayResult
    let speed: SpeedDisplayResult
    let elevation: ElevationDisplayResult
    let diagnostics: ActivityVisualizationDiagnostics

    init(
        route: RouteDisplayResult,
        speed: SpeedDisplayResult,
        elevation: ElevationDisplayResult,
        diagnostics: ActivityVisualizationDiagnostics = .empty
    ) {
        self.route = route
        self.speed = speed
        self.elevation = elevation
        self.diagnostics = diagnostics
    }
}
