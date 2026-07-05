// [協作區] Shared/ActivityVisualization/Route/RouteDisplayModels.swift
// Purpose: Defines platform-neutral route display model shells without changing renderer behavior.
// Delegates to: Future RouteDisplayPipeline extraction and platform-specific iOS/macOS/watchOS renderers.
// Note: Uses ActivityRouteDisplayPoint to avoid colliding with the existing private iOS SessionRouteMapView RouteDisplayPoint during ActivityViz-001.

import Foundation

enum RouteDisplaySemantic: String, Codable, Sendable, Equatable {
    case highConfidence
    case lowConfidence
    case startupWarmup
}

enum RouteDisplayConfidence: String, Codable, Sendable, Equatable {
    case high
    case medium
    case low
    case unavailable
}

struct ActivityRouteDisplayPoint: Identifiable, Equatable, Sendable {
    let id: Int
    let timestamp: Date
    let elapsedSeconds: TimeInterval
    let rawCoordinate: GeoCoordinate
    let displayCoordinate: GeoCoordinate
    let speedKilometersPerHour: Double?
    let semantic: RouteDisplaySemantic
    let confidence: RouteDisplayConfidence
    let horizontalAccuracyMeters: Double?

    init(
        id: Int,
        timestamp: Date,
        elapsedSeconds: TimeInterval,
        rawCoordinate: GeoCoordinate,
        displayCoordinate: GeoCoordinate,
        speedKilometersPerHour: Double? = nil,
        semantic: RouteDisplaySemantic,
        confidence: RouteDisplayConfidence,
        horizontalAccuracyMeters: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.elapsedSeconds = elapsedSeconds
        self.rawCoordinate = rawCoordinate
        self.displayCoordinate = displayCoordinate
        self.speedKilometersPerHour = speedKilometersPerHour
        self.semantic = semantic
        self.confidence = confidence
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
    }
}

struct RouteDisplaySegment: Identifiable, Equatable, Sendable {
    let id: Int
    let points: [ActivityRouteDisplayPoint]
    let semantic: RouteDisplaySemantic

    init(id: Int, points: [ActivityRouteDisplayPoint], semantic: RouteDisplaySemantic) {
        self.id = id
        self.points = points
        self.semantic = semantic
    }
}

struct RouteDisplayBounds: Equatable, Sendable {
    let minimumLatitude: Double
    let maximumLatitude: Double
    let minimumLongitude: Double
    let maximumLongitude: Double

    init(
        minimumLatitude: Double,
        maximumLatitude: Double,
        minimumLongitude: Double,
        maximumLongitude: Double
    ) {
        self.minimumLatitude = minimumLatitude
        self.maximumLatitude = maximumLatitude
        self.minimumLongitude = minimumLongitude
        self.maximumLongitude = maximumLongitude
    }
}

struct RouteDisplaySummary: Equatable, Sendable {
    let quality: ActivityVisualizationQuality
    let rawSampleCount: Int
    let displayPointCount: Int
    let segmentCount: Int
    let hasLowConfidenceSegments: Bool
    let hasStartupWarmup: Bool
    let bounds: RouteDisplayBounds?

    init(
        quality: ActivityVisualizationQuality,
        rawSampleCount: Int,
        displayPointCount: Int,
        segmentCount: Int,
        hasLowConfidenceSegments: Bool = false,
        hasStartupWarmup: Bool = false,
        bounds: RouteDisplayBounds? = nil
    ) {
        self.quality = quality
        self.rawSampleCount = rawSampleCount
        self.displayPointCount = displayPointCount
        self.segmentCount = segmentCount
        self.hasLowConfidenceSegments = hasLowConfidenceSegments
        self.hasStartupWarmup = hasStartupWarmup
        self.bounds = bounds
    }
}

struct RouteDisplayDiagnostics: Equatable, Sendable {
    let messages: [String]
    let droppedSampleCount: Int

    init(messages: [String] = [], droppedSampleCount: Int = 0) {
        self.messages = messages
        self.droppedSampleCount = droppedSampleCount
    }
}

struct RouteDisplayResult: Equatable, Sendable {
    let points: [ActivityRouteDisplayPoint]
    let segments: [RouteDisplaySegment]
    let summary: RouteDisplaySummary
    let diagnostics: RouteDisplayDiagnostics

    init(
        points: [ActivityRouteDisplayPoint] = [],
        segments: [RouteDisplaySegment] = [],
        summary: RouteDisplaySummary,
        diagnostics: RouteDisplayDiagnostics = RouteDisplayDiagnostics()
    ) {
        self.points = points
        self.segments = segments
        self.summary = summary
        self.diagnostics = diagnostics
    }
}

struct RouteDisplayConfiguration: Equatable, Sendable {
    let maximumDisplayPointCount: Int
    let preservesStartupWarmupSegments: Bool
    let preservesLowConfidenceSegments: Bool

    init(
        maximumDisplayPointCount: Int = 500,
        preservesStartupWarmupSegments: Bool = true,
        preservesLowConfidenceSegments: Bool = true
    ) {
        self.maximumDisplayPointCount = maximumDisplayPointCount
        self.preservesStartupWarmupSegments = preservesStartupWarmupSegments
        self.preservesLowConfidenceSegments = preservesLowConfidenceSegments
    }
}
