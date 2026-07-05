// [協作區] Shared/ActivityVisualization/Elevation/ElevationDisplayModels.swift
// Purpose: Defines platform-neutral elevation display model shells without changing altitude semantics.
// Delegates to: Future ElevationDisplayPipeline extraction and platform-specific elevation renderers.

import Foundation

enum ElevationDisplaySource: String, Codable, Sendable, Equatable {
    case motionSample
    case displayDerived
}

struct ElevationDisplayPoint: Identifiable, Equatable, Sendable {
    let id: Int
    let timestamp: Date
    let elapsedSeconds: TimeInterval
    let elevationMeters: Double
    let source: ElevationDisplaySource

    init(
        id: Int,
        timestamp: Date,
        elapsedSeconds: TimeInterval,
        elevationMeters: Double,
        source: ElevationDisplaySource
    ) {
        self.id = id
        self.timestamp = timestamp
        self.elapsedSeconds = elapsedSeconds
        self.elevationMeters = elevationMeters
        self.source = source
    }
}

struct ElevationDisplayRange: Equatable, Sendable {
    let minimumMeters: Double
    let maximumMeters: Double

    init(minimumMeters: Double, maximumMeters: Double) {
        self.minimumMeters = minimumMeters
        self.maximumMeters = maximumMeters
    }
}

struct ElevationDisplaySummary: Equatable, Sendable {
    let quality: ActivityVisualizationQuality
    let rawSampleCount: Int
    let displayPointCount: Int
    let elevationRange: ElevationDisplayRange?
    let displayDerivedTotalAscentMeters: Double?
    let hasSparseData: Bool

    init(
        quality: ActivityVisualizationQuality,
        rawSampleCount: Int,
        displayPointCount: Int,
        elevationRange: ElevationDisplayRange? = nil,
        displayDerivedTotalAscentMeters: Double? = nil,
        hasSparseData: Bool = false
    ) {
        self.quality = quality
        self.rawSampleCount = rawSampleCount
        self.displayPointCount = displayPointCount
        self.elevationRange = elevationRange
        self.displayDerivedTotalAscentMeters = displayDerivedTotalAscentMeters
        self.hasSparseData = hasSparseData
    }
}

struct ElevationDisplayDiagnostics: Equatable, Sendable {
    let messages: [String]
    let droppedSampleCount: Int
    let downsampledPointCount: Int

    init(
        messages: [String] = [],
        droppedSampleCount: Int = 0,
        downsampledPointCount: Int = 0
    ) {
        self.messages = messages
        self.droppedSampleCount = droppedSampleCount
        self.downsampledPointCount = downsampledPointCount
    }
}

struct ElevationDisplayResult: Equatable, Sendable {
    let points: [ElevationDisplayPoint]
    let summary: ElevationDisplaySummary
    let diagnostics: ElevationDisplayDiagnostics

    init(
        points: [ElevationDisplayPoint] = [],
        summary: ElevationDisplaySummary,
        diagnostics: ElevationDisplayDiagnostics = ElevationDisplayDiagnostics()
    ) {
        self.points = points
        self.summary = summary
        self.diagnostics = diagnostics
    }
}

struct ElevationDisplayConfiguration: Equatable, Sendable {
    let maximumDisplayPointCount: Int
    let calculatesDisplayDerivedAscent: Bool

    init(
        maximumDisplayPointCount: Int = 240,
        calculatesDisplayDerivedAscent: Bool = true
    ) {
        self.maximumDisplayPointCount = maximumDisplayPointCount
        self.calculatesDisplayDerivedAscent = calculatesDisplayDerivedAscent
    }
}
