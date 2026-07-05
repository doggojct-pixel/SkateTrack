// [協作區] Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift
// Purpose: Defines display-only compact route, speed, and elevation payloads for future watchOS summaries.
// Delegates to: ActivityVisualizationCompactSummary, ActivityVisualizationPipeline, and platform-specific renderers.

import Foundation

struct CompactRoutePoint: Identifiable, Equatable, Sendable {
    let id: Int
    let elapsedSeconds: TimeInterval
    let coordinate: GeoCoordinate
    let semantic: RouteDisplaySemantic

    init(
        id: Int,
        elapsedSeconds: TimeInterval,
        coordinate: GeoCoordinate,
        semantic: RouteDisplaySemantic = .highConfidence
    ) {
        self.id = id
        self.elapsedSeconds = elapsedSeconds
        self.coordinate = coordinate
        self.semantic = semantic
    }
}

struct CompactRouteDisplay: Equatable, Sendable {
    let points: [CompactRoutePoint]
    let quality: ActivityVisualizationQuality
    let segmentCount: Int
    let bounds: RouteDisplayBounds?
    let hasLowConfidenceSegments: Bool
    let hasStartupWarmup: Bool

    var hasDisplayData: Bool { !points.isEmpty }

    init(
        points: [CompactRoutePoint] = [],
        quality: ActivityVisualizationQuality = .unavailable,
        segmentCount: Int = 0,
        bounds: RouteDisplayBounds? = nil,
        hasLowConfidenceSegments: Bool = false,
        hasStartupWarmup: Bool = false
    ) {
        self.points = points
        self.quality = quality
        self.segmentCount = max(0, segmentCount)
        self.bounds = bounds
        self.hasLowConfidenceSegments = hasLowConfidenceSegments
        self.hasStartupWarmup = hasStartupWarmup
    }

    init(route: RouteDisplayResult, maximumPointCount: Int = 48) {
        self.init(
            points: CompactRouteDisplay.compactRoutePoints(
                from: route.points,
                maximumPointCount: maximumPointCount
            ),
            quality: route.summary.quality,
            segmentCount: route.summary.segmentCount,
            bounds: route.summary.bounds,
            hasLowConfidenceSegments: route.summary.hasLowConfidenceSegments,
            hasStartupWarmup: route.summary.hasStartupWarmup
        )
    }

    static let empty = CompactRouteDisplay()

    private static func compactRoutePoints(
        from points: [ActivityRouteDisplayPoint],
        maximumPointCount: Int
    ) -> [CompactRoutePoint] {
        compactSample(points, maximumPointCount: maximumPointCount).map { point in
            CompactRoutePoint(
                id: point.id,
                elapsedSeconds: point.elapsedSeconds,
                coordinate: point.displayCoordinate,
                semantic: point.semantic
            )
        }
    }
}

struct CompactSparklinePoint: Identifiable, Equatable, Sendable {
    let id: Int
    let elapsedSeconds: TimeInterval
    let value: Double
    let normalizedValue: Double
    let segmentID: Int

    init(
        id: Int,
        elapsedSeconds: TimeInterval,
        value: Double,
        normalizedValue: Double,
        segmentID: Int = 0
    ) {
        self.id = id
        self.elapsedSeconds = elapsedSeconds
        self.value = value
        self.normalizedValue = clampedNormalizedValue(normalizedValue)
        self.segmentID = segmentID
    }
}

struct CompactSpeedSparkline: Equatable, Sendable {
    let points: [CompactSparklinePoint]
    let quality: ActivityVisualizationQuality
    let minimumSpeedKilometersPerHour: Double?
    let maximumSpeedKilometersPerHour: Double?
    let averageDisplaySpeedKilometersPerHour: Double?
    let segmentCount: Int
    let hasSparseData: Bool

    var hasDisplayData: Bool { !points.isEmpty }

    init(
        points: [CompactSparklinePoint] = [],
        quality: ActivityVisualizationQuality = .unavailable,
        minimumSpeedKilometersPerHour: Double? = nil,
        maximumSpeedKilometersPerHour: Double? = nil,
        averageDisplaySpeedKilometersPerHour: Double? = nil,
        segmentCount: Int = 0,
        hasSparseData: Bool = false
    ) {
        self.points = points
        self.quality = quality
        self.minimumSpeedKilometersPerHour = minimumSpeedKilometersPerHour
        self.maximumSpeedKilometersPerHour = maximumSpeedKilometersPerHour
        self.averageDisplaySpeedKilometersPerHour = averageDisplaySpeedKilometersPerHour
        self.segmentCount = max(0, segmentCount)
        self.hasSparseData = hasSparseData
    }

    init(speed: SpeedDisplayResult, maximumPointCount: Int = 48) {
        self.init(
            points: CompactSpeedSparkline.compactSpeedPoints(
                from: speed.points,
                maximumPointCount: maximumPointCount
            ),
            quality: speed.summary.quality,
            minimumSpeedKilometersPerHour: speed.summary.minimumSpeedKilometersPerHour,
            maximumSpeedKilometersPerHour: speed.summary.maximumSpeedKilometersPerHour,
            averageDisplaySpeedKilometersPerHour: speed.summary.averageDisplaySpeedKilometersPerHour,
            segmentCount: speed.summary.segmentCount,
            hasSparseData: speed.summary.hasSparseData
        )
    }

    static let empty = CompactSpeedSparkline()

    private static func compactSpeedPoints(
        from points: [SpeedDisplayPoint],
        maximumPointCount: Int
    ) -> [CompactSparklinePoint] {
        let sampledPoints = compactSample(points, maximumPointCount: maximumPointCount)
        let values = sampledPoints.map(\.speedKilometersPerHour)
        return sampledPoints.map { point in
            CompactSparklinePoint(
                id: point.id,
                elapsedSeconds: point.elapsedSeconds,
                value: point.speedKilometersPerHour,
                normalizedValue: normalizedValue(point.speedKilometersPerHour, values: values),
                segmentID: point.segmentID
            )
        }
    }
}

struct CompactElevationProfile: Equatable, Sendable {
    let points: [CompactSparklinePoint]
    let quality: ActivityVisualizationQuality
    let elevationRange: ElevationDisplayRange?
    let displayDerivedTotalAscentMeters: Double?
    let selectedSource: ElevationDisplaySource
    let segmentCount: Int
    let hasAbsoluteAnchor: Bool
    let hasSparseData: Bool

    var hasDisplayData: Bool { !points.isEmpty }

    init(
        points: [CompactSparklinePoint] = [],
        quality: ActivityVisualizationQuality = .unavailable,
        elevationRange: ElevationDisplayRange? = nil,
        displayDerivedTotalAscentMeters: Double? = nil,
        selectedSource: ElevationDisplaySource = .motionSample,
        segmentCount: Int = 0,
        hasAbsoluteAnchor: Bool = false,
        hasSparseData: Bool = false
    ) {
        self.points = points
        self.quality = quality
        self.elevationRange = elevationRange
        self.displayDerivedTotalAscentMeters = displayDerivedTotalAscentMeters
        self.selectedSource = selectedSource
        self.segmentCount = max(0, segmentCount)
        self.hasAbsoluteAnchor = hasAbsoluteAnchor
        self.hasSparseData = hasSparseData
    }

    init(elevation: ElevationDisplayResult, maximumPointCount: Int = 48) {
        self.init(
            points: CompactElevationProfile.compactElevationPoints(
                from: elevation.points,
                maximumPointCount: maximumPointCount
            ),
            quality: elevation.summary.quality,
            elevationRange: elevation.summary.elevationRange,
            displayDerivedTotalAscentMeters: elevation.summary.displayDerivedTotalAscentMeters,
            selectedSource: elevation.summary.selectedSource,
            segmentCount: elevation.summary.segmentCount,
            hasAbsoluteAnchor: elevation.summary.hasAbsoluteAnchor,
            hasSparseData: elevation.summary.hasSparseData
        )
    }

    static let empty = CompactElevationProfile()

    private static func compactElevationPoints(
        from points: [ElevationDisplayPoint],
        maximumPointCount: Int
    ) -> [CompactSparklinePoint] {
        let sampledPoints = compactSample(points, maximumPointCount: maximumPointCount)
        let values = sampledPoints.map(\.elevationMeters)
        return sampledPoints.map { point in
            CompactSparklinePoint(
                id: point.id,
                elapsedSeconds: point.elapsedSeconds,
                value: point.elevationMeters,
                normalizedValue: normalizedValue(point.elevationMeters, values: values),
                segmentID: point.segmentID
            )
        }
    }
}

private func compactSample<Element>(_ elements: [Element], maximumPointCount: Int) -> [Element] {
    guard maximumPointCount > 0, elements.count > maximumPointCount else { return elements }
    guard maximumPointCount > 1 else { return [elements[0]] }

    let lastIndex = elements.count - 1
    let step = Double(lastIndex) / Double(maximumPointCount - 1)
    var sampled: [Element] = []
    sampled.reserveCapacity(maximumPointCount)

    for outputIndex in 0..<maximumPointCount {
        let sourceIndex = min(lastIndex, Int((Double(outputIndex) * step).rounded()))
        sampled.append(elements[sourceIndex])
    }
    return sampled
}

private func normalizedValue(_ value: Double, values: [Double]) -> Double {
    guard let minimum = values.min(), let maximum = values.max() else { return 0 }
    let range = maximum - minimum
    guard range > 0 else { return 0.5 }
    return clampedNormalizedValue((value - minimum) / range)
}

private func clampedNormalizedValue(_ value: Double) -> Double {
    min(1, max(0, value))
}
