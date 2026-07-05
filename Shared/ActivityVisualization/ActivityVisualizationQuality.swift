// [協作區] Shared/ActivityVisualization/ActivityVisualizationQuality.swift
// Purpose: Defines platform-neutral display quality states for shared activity visualization data.
// Delegates to: Route, speed, elevation, and compact visualization pipelines in later subtasks.

import Foundation

enum ActivityVisualizationQuality: String, Codable, Sendable, Equatable {
    case unavailable
    case limited
    case usable
}
