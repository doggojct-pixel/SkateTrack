// [協作區] Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift
// Purpose: Defines platform-neutral configuration and umbrella result shells for activity visualization.
// Delegates to: Route, speed, elevation display pipelines, future compact adapters, and platform-specific renderers.

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

struct ActivityVisualizationResult: Equatable, Sendable {
    let route: RouteDisplayResult
    let speed: SpeedDisplayResult
    let elevation: ElevationDisplayResult
    let compactSummary: ActivityVisualizationCompactSummary
    let diagnostics: ActivityVisualizationDiagnostics

    init(
        route: RouteDisplayResult,
        speed: SpeedDisplayResult,
        elevation: ElevationDisplayResult,
        compactSummary: ActivityVisualizationCompactSummary? = nil,
        diagnostics: ActivityVisualizationDiagnostics = .empty
    ) {
        self.route = route
        self.speed = speed
        self.elevation = elevation
        self.compactSummary = compactSummary ?? ActivityVisualizationCompactSummary(
            route: route,
            speed: speed,
            elevation: elevation
        )
        self.diagnostics = diagnostics
    }
}

struct ActivityVisualizationCompactSummary: Equatable, Sendable {
    let compactRoute: CompactRouteDisplay
    let speedSparkline: CompactSpeedSparkline
    let elevationProfile: CompactElevationProfile
    let routeQuality: ActivityVisualizationQuality
    let speedQuality: ActivityVisualizationQuality
    let elevationQuality: ActivityVisualizationQuality
    let routeDisplayPointCount: Int
    let speedDisplayPointCount: Int
    let elevationDisplayPointCount: Int
    let routeSegmentCount: Int
    let speedSegmentCount: Int
    let elevationSegmentCount: Int
    let selectedElevationSource: ElevationDisplaySource
    let hasAnyDisplayData: Bool

    init(
        routeQuality: ActivityVisualizationQuality = .unavailable,
        speedQuality: ActivityVisualizationQuality = .unavailable,
        elevationQuality: ActivityVisualizationQuality = .unavailable,
        routeDisplayPointCount: Int = 0,
        speedDisplayPointCount: Int = 0,
        elevationDisplayPointCount: Int = 0,
        routeSegmentCount: Int = 0,
        speedSegmentCount: Int = 0,
        elevationSegmentCount: Int = 0,
        selectedElevationSource: ElevationDisplaySource = .motionSample,
        compactRoute: CompactRouteDisplay = .empty,
        speedSparkline: CompactSpeedSparkline = .empty,
        elevationProfile: CompactElevationProfile = .empty
    ) {
        self.compactRoute = compactRoute
        self.speedSparkline = speedSparkline
        self.elevationProfile = elevationProfile
        self.routeQuality = routeQuality
        self.speedQuality = speedQuality
        self.elevationQuality = elevationQuality
        self.routeDisplayPointCount = max(0, routeDisplayPointCount)
        self.speedDisplayPointCount = max(0, speedDisplayPointCount)
        self.elevationDisplayPointCount = max(0, elevationDisplayPointCount)
        self.routeSegmentCount = max(0, routeSegmentCount)
        self.speedSegmentCount = max(0, speedSegmentCount)
        self.elevationSegmentCount = max(0, elevationSegmentCount)
        self.selectedElevationSource = selectedElevationSource
        self.hasAnyDisplayData = compactRoute.hasDisplayData
            || speedSparkline.hasDisplayData
            || elevationProfile.hasDisplayData
            || routeDisplayPointCount > 0
            || speedDisplayPointCount > 0
            || elevationDisplayPointCount > 0
    }

    init(
        route: RouteDisplayResult,
        speed: SpeedDisplayResult,
        elevation: ElevationDisplayResult
    ) {
        self.init(
            routeQuality: route.summary.quality,
            speedQuality: speed.summary.quality,
            elevationQuality: elevation.summary.quality,
            routeDisplayPointCount: route.summary.displayPointCount,
            speedDisplayPointCount: speed.summary.displayPointCount,
            elevationDisplayPointCount: elevation.summary.displayPointCount,
            routeSegmentCount: route.summary.segmentCount,
            speedSegmentCount: speed.summary.segmentCount,
            elevationSegmentCount: elevation.summary.segmentCount,
            selectedElevationSource: elevation.summary.selectedSource,
            compactRoute: CompactRouteDisplay(route: route),
            speedSparkline: CompactSpeedSparkline(speed: speed),
            elevationProfile: CompactElevationProfile(elevation: elevation)
        )
    }
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
