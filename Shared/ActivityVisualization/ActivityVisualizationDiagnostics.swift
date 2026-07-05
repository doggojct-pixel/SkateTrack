// [協作區] Shared/ActivityVisualization/ActivityVisualizationDiagnostics.swift
// Purpose: Collects developer-facing diagnostics emitted by display-only activity visualization preparation.
// Delegates to: Task-specific verifiers and future route, speed, elevation, and compact adapters.

import Foundation

struct ActivityVisualizationDiagnostics: Equatable, Sendable {
    let routeMessages: [String]
    let speedMessages: [String]
    let elevationMessages: [String]
    let droppedSampleCount: Int
    let downsampledPointCount: Int

    init(
        routeMessages: [String] = [],
        speedMessages: [String] = [],
        elevationMessages: [String] = [],
        droppedSampleCount: Int = 0,
        downsampledPointCount: Int = 0
    ) {
        self.routeMessages = routeMessages
        self.speedMessages = speedMessages
        self.elevationMessages = elevationMessages
        self.droppedSampleCount = droppedSampleCount
        self.downsampledPointCount = downsampledPointCount
    }

    static let empty = ActivityVisualizationDiagnostics()
}
