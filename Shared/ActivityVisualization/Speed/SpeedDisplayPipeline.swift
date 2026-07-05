// [協作區] Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift
// Purpose: Prepares display-only speed chart points from MotionSample source-of-truth data.
// Delegates to: ActivityFidelityPolicy for chart bounds and platform-specific iOS/macOS/watchOS renderers.

import Foundation

struct SpeedDisplayPipeline: Equatable, Sendable {
    static let defaultChartSegmentGapSeconds: TimeInterval = 12
    static let smoothingWindowRadius = 2
    static let maximumSmoothingStepKilometersPerHour = 2.2

    let configuration: SpeedDisplayConfiguration

    init(configuration: SpeedDisplayConfiguration = SpeedDisplayConfiguration()) {
        self.configuration = configuration
    }

    func makeDisplaySpeed(
        samples: [MotionSample],
        startDate: Date? = nil,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> SpeedDisplayResult {
        let sortedSamples = samples.sorted { lhs, rhs in lhs.timestamp < rhs.timestamp }
        let anchorDate = startDate ?? sortedSamples.first?.timestamp
        guard let anchorDate else {
            return emptyResult(rawSampleCount: samples.count, droppedSampleCount: 0)
        }

        let rawPoints = speedPoints(
            from: sortedSamples,
            startDate: anchorDate,
            fidelityPolicy: fidelityPolicy
        )
        let downsampledPoints = downsample(rawPoints, maxCount: configuration.maximumDisplayPointCount)
        let displayPoints = smoothedSpeedPoints(downsampledPoints)
        let speedValues = displayPoints.map(\.speedKilometersPerHour)
        let droppedSampleCount = max(0, samples.count - rawPoints.count)
        let downsampledPointCount = max(0, rawPoints.count - downsampledPoints.count)

        return SpeedDisplayResult(
            points: displayPoints,
            summary: SpeedDisplaySummary(
                quality: quality(for: displayPoints),
                rawSampleCount: samples.count,
                displayPointCount: displayPoints.count,
                minimumSpeedKilometersPerHour: speedValues.min(),
                maximumSpeedKilometersPerHour: speedValues.max(),
                averageDisplaySpeedKilometersPerHour: average(speedValues),
                segmentCount: Set(displayPoints.map(\.segmentID)).count,
                hasSparseData: displayPoints.count < 2
            ),
            diagnostics: SpeedDisplayDiagnostics(
                messages: diagnosticsMessages(
                    rawSampleCount: samples.count,
                    displayPointCount: displayPoints.count,
                    droppedSampleCount: droppedSampleCount,
                    downsampledPointCount: downsampledPointCount
                ),
                droppedSampleCount: droppedSampleCount,
                downsampledPointCount: downsampledPointCount
            )
        )
    }

    private func speedPoints(
        from samples: [MotionSample],
        startDate: Date,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> [SpeedDisplayPoint] {
        var segmentID = 0
        var previousIncludedTimestamp: Date?
        var points: [SpeedDisplayPoint] = []

        for (index, sample) in samples.enumerated() {
            guard let speed = displaySpeedKilometersPerHour(for: sample, fidelityPolicy: fidelityPolicy) else {
                continue
            }

            if shouldStartNewChartSegment(after: previousIncludedTimestamp, current: sample) {
                segmentID += 1
            }

            points.append(
                SpeedDisplayPoint(
                    id: index,
                    timestamp: sample.timestamp,
                    elapsedSeconds: max(0, sample.timestamp.timeIntervalSince(startDate)),
                    speedKilometersPerHour: speed,
                    source: .motionSample,
                    segmentID: segmentID
                )
            )
            previousIncludedTimestamp = sample.timestamp
        }

        return points
    }

    private func displaySpeedKilometersPerHour(
        for sample: MotionSample,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Double? {
        guard sample.speedKmh.isFinite, sample.speedKmh >= 0 else { return nil }
        guard sample.speedKmh <= fidelityPolicy.chartMaximumSpeedKmh else { return nil }
        return sample.speedKmh
    }

    private func shouldStartNewChartSegment(after previousTimestamp: Date?, current sample: MotionSample) -> Bool {
        if let previousTimestamp, sample.timestamp.timeIntervalSince(previousTimestamp) > Self.defaultChartSegmentGapSeconds {
            return true
        }
        guard let diagnostics = sample.locationDiagnostics else { return false }
        if diagnostics.freshnessState == .stale { return true }
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > Self.defaultChartSegmentGapSeconds }) == true {
            return true
        }
        return false
    }

    private func smoothedSpeedPoints(_ points: [SpeedDisplayPoint]) -> [SpeedDisplayPoint] {
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [SpeedDisplayPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 3 else { return sorted }
            var previousSmoothedSpeed: Double?

            return sorted.enumerated().map { offset, point in
                let lowerBound = max(0, offset - Self.smoothingWindowRadius)
                let upperBound = min(sorted.count - 1, offset + Self.smoothingWindowRadius)
                let windowSpeeds = sorted[lowerBound...upperBound].map(\.speedKilometersPerHour).sorted()
                let median = windowSpeeds[windowSpeeds.count / 2]
                let referenceSpeed = previousSmoothedSpeed ?? median
                let limitedSpeed = min(
                    max(median, referenceSpeed - Self.maximumSmoothingStepKilometersPerHour),
                    referenceSpeed + Self.maximumSmoothingStepKilometersPerHour
                )
                previousSmoothedSpeed = limitedSpeed
                return SpeedDisplayPoint(
                    id: point.id,
                    timestamp: point.timestamp,
                    elapsedSeconds: point.elapsedSeconds,
                    speedKilometersPerHour: limitedSpeed,
                    source: point.source,
                    segmentID: point.segmentID
                )
            }
        }
        .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    private func downsample(_ points: [SpeedDisplayPoint], maxCount: Int) -> [SpeedDisplayPoint] {
        guard points.count > maxCount, maxCount > 1 else { return points }
        let stride = max(1, Int(ceil(Double(points.count) / Double(maxCount))))
        var sampled = points.enumerated().compactMap { offset, point in
            offset.isMultiple(of: stride) ? point : nil
        }

        if let last = points.last, sampled.last != last {
            sampled.append(last)
        }

        return sampled
    }

    private func quality(for points: [SpeedDisplayPoint]) -> ActivityVisualizationQuality {
        if points.isEmpty { return .unavailable }
        if points.count < 2 { return .limited }
        return .usable
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func diagnosticsMessages(
        rawSampleCount: Int,
        displayPointCount: Int,
        droppedSampleCount: Int,
        downsampledPointCount: Int
    ) -> [String] {
        var messages: [String] = []
        if rawSampleCount == 0 { messages.append("speed.noSamples") }
        if displayPointCount < 2 { messages.append("speed.sparseDisplayPoints") }
        if droppedSampleCount > 0 { messages.append("speed.droppedInvalidOrOutOfRangeSamples") }
        if downsampledPointCount > 0 { messages.append("speed.downsampledForDisplay") }
        return messages
    }

    private func emptyResult(rawSampleCount: Int, droppedSampleCount: Int) -> SpeedDisplayResult {
        SpeedDisplayResult(
            summary: SpeedDisplaySummary(
                quality: .unavailable,
                rawSampleCount: rawSampleCount,
                displayPointCount: 0,
                segmentCount: 0,
                hasSparseData: true
            ),
            diagnostics: SpeedDisplayDiagnostics(
                messages: rawSampleCount == 0 ? ["speed.noSamples"] : ["speed.sparseDisplayPoints"],
                droppedSampleCount: droppedSampleCount
            )
        )
    }
}
