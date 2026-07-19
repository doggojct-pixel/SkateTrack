// [協作區] MacSnowSessionAnalysis.swift
// 用途：定義 macOS Snow viewer 的唯讀 presentation value，不持有 repository、subscription 或 package writer。
// 委派至：MacSnowAnalysisViewModel、MacSnow viewer UI、Snow-Task-008 package mapping。

import Foundation

struct MacSnowSessionAnalysis: Identifiable, Sendable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let startDate: Date
    let endDate: Date?
    let sportMode: SportMode
    let discipline: SnowDiscipline?
    let source: MacSnowAnalysisSource
    let runs: [SnowRun]
    let segments: [SnowSegment]
    let distanceBreakdown: SnowDistanceBreakdown
    let verticalMetrics: SnowVerticalMetrics
    let motionSamples: [MotionSample]
    let topSpeedMetersPerSecond: Double
    let averageRunDurationSeconds: TimeInterval?
    let routePoints: [MacSnowRoutePoint]
    let elevationPoints: [MacSnowElevationPoint]
    let hasLimitedAltitudeData: Bool
    var selectedSegmentID: UUID?

    init(
        id: UUID,
        title: String,
        subtitle: String,
        startDate: Date,
        endDate: Date?,
        sportMode: SportMode,
        discipline: SnowDiscipline?,
        source: MacSnowAnalysisSource,
        runs: [SnowRun],
        segments: [SnowSegment],
        distanceBreakdown: SnowDistanceBreakdown,
        verticalMetrics: SnowVerticalMetrics,
        motionSamples: [MotionSample],
        topSpeedMetersPerSecond: Double,
        averageRunDurationSeconds: TimeInterval?,
        routePoints: [MacSnowRoutePoint],
        elevationPoints: [MacSnowElevationPoint],
        hasLimitedAltitudeData: Bool,
        selectedSegmentID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.startDate = startDate
        self.endDate = endDate
        self.sportMode = sportMode
        self.discipline = discipline
        self.source = source
        self.runs = runs
        self.segments = segments
        self.distanceBreakdown = distanceBreakdown
        self.verticalMetrics = verticalMetrics
        self.motionSamples = motionSamples
        self.topSpeedMetersPerSecond = max(0, topSpeedMetersPerSecond)
        self.averageRunDurationSeconds = averageRunDurationSeconds.map { max(0, $0) }
        self.routePoints = routePoints
        self.elevationPoints = elevationPoints
        self.hasLimitedAltitudeData = hasLimitedAltitudeData
        self.selectedSegmentID = selectedSegmentID
    }

    var durationSeconds: TimeInterval? {
        guard let endDate else { return nil }
        return max(0, endDate.timeIntervalSince(startDate))
    }

    var selectedSegment: SnowSegment? {
        guard let selectedSegmentID else { return nil }
        return segments.first { $0.id == selectedSegmentID }
    }

    var selectedSegmentSelection: MacSnowSegmentSelection? {
        guard let selectedSegment else { return nil }
        return MacSnowSegmentSelection(
            segment: selectedSegment,
            routeSamples: MacSnowRouteFilter.routeSamples(
                for: selectedSegment,
                in: motionSamples
            )
        )
    }

    func selecting(segmentID: UUID?) -> MacSnowSessionAnalysis {
        var copy = self
        copy.selectedSegmentID = segmentID
        return copy
    }
}

struct MacSnowSegmentSelection: Identifiable, Sendable, Equatable {
    let id: UUID
    let segment: SnowSegment
    let routeSamples: [MotionSample]

    init(segment: SnowSegment, routeSamples: [MotionSample]) {
        id = segment.id
        self.segment = segment
        self.routeSamples = routeSamples
    }
}

struct MacSnowRoutePoint: Identifiable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let coordinate: GeoCoordinate
    let altitudeMeters: Double?
    let speedKmh: Double

    init(
        id: UUID = UUID(),
        timestamp: Date,
        coordinate: GeoCoordinate,
        altitudeMeters: Double?,
        speedKmh: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.coordinate = coordinate
        self.altitudeMeters = altitudeMeters
        self.speedKmh = max(0, speedKmh)
    }
}

struct MacSnowElevationPoint: Identifiable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let altitudeMeters: Double

    init(id: UUID = UUID(), timestamp: Date, altitudeMeters: Double) {
        self.id = id
        self.timestamp = timestamp
        self.altitudeMeters = altitudeMeters
    }
}
