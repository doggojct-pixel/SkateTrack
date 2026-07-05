// [協作區] Shared/ActivityVisualization/Speed/SpeedDisplayModels.swift
// Purpose: Defines platform-neutral speed display model shells without changing chart behavior.
// Delegates to: Future SpeedDisplayPipeline extraction and platform-specific chart renderers.

import Foundation

enum SpeedDisplaySource: String, Codable, Sendable, Equatable {
    case motionSample
    case sessionSummary
    case displayDerived
}

struct SpeedDisplayPoint: Identifiable, Equatable, Sendable {
    let id: Int
    let timestamp: Date
    let elapsedSeconds: TimeInterval
    let speedKilometersPerHour: Double
    let source: SpeedDisplaySource
    let segmentID: Int

    init(
        id: Int,
        timestamp: Date,
        elapsedSeconds: TimeInterval,
        speedKilometersPerHour: Double,
        source: SpeedDisplaySource,
        segmentID: Int = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.elapsedSeconds = elapsedSeconds
        self.speedKilometersPerHour = speedKilometersPerHour
        self.source = source
        self.segmentID = segmentID
    }
}

struct SpeedDisplaySummary: Equatable, Sendable {
    let quality: ActivityVisualizationQuality
    let rawSampleCount: Int
    let displayPointCount: Int
    let minimumSpeedKilometersPerHour: Double?
    let maximumSpeedKilometersPerHour: Double?
    let averageDisplaySpeedKilometersPerHour: Double?
    let segmentCount: Int
    let hasSparseData: Bool

    init(
        quality: ActivityVisualizationQuality,
        rawSampleCount: Int,
        displayPointCount: Int,
        minimumSpeedKilometersPerHour: Double? = nil,
        maximumSpeedKilometersPerHour: Double? = nil,
        averageDisplaySpeedKilometersPerHour: Double? = nil,
        segmentCount: Int = 0,
        hasSparseData: Bool = false
    ) {
        self.quality = quality
        self.rawSampleCount = rawSampleCount
        self.displayPointCount = displayPointCount
        self.minimumSpeedKilometersPerHour = minimumSpeedKilometersPerHour
        self.maximumSpeedKilometersPerHour = maximumSpeedKilometersPerHour
        self.averageDisplaySpeedKilometersPerHour = averageDisplaySpeedKilometersPerHour
        self.segmentCount = segmentCount
        self.hasSparseData = hasSparseData
    }
}

struct SpeedDisplayDiagnostics: Equatable, Sendable {
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

struct SpeedDisplayResult: Equatable, Sendable {
    let points: [SpeedDisplayPoint]
    let summary: SpeedDisplaySummary
    let diagnostics: SpeedDisplayDiagnostics

    init(
        points: [SpeedDisplayPoint] = [],
        summary: SpeedDisplaySummary,
        diagnostics: SpeedDisplayDiagnostics = SpeedDisplayDiagnostics()
    ) {
        self.points = points
        self.summary = summary
        self.diagnostics = diagnostics
    }
}

struct SpeedDisplayConfiguration: Equatable, Sendable {
    let maximumDisplayPointCount: Int
    let allowsSessionSummaryFallback: Bool

    init(
        maximumDisplayPointCount: Int = 240,
        allowsSessionSummaryFallback: Bool = true
    ) {
        self.maximumDisplayPointCount = maximumDisplayPointCount
        self.allowsSessionSummaryFallback = allowsSessionSummaryFallback
    }
}
