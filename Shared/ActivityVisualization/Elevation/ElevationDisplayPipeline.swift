// [協作區] Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift
// Purpose: Prepares display-only elevation profile points from MotionSample source-of-truth data.
// Delegates to: ActivityFidelityPolicy for trusted altitude bounds and platform-specific iOS/macOS/watchOS renderers.

import Foundation

struct ElevationDisplayPipeline: Equatable, Sendable {
    static let defaultChartSegmentGapSeconds: TimeInterval = 12
    static let smoothingWindowRadius = 5
    static let maximumSmoothingStepMeters = 0.45

    let configuration: ElevationDisplayConfiguration

    init(configuration: ElevationDisplayConfiguration = ElevationDisplayConfiguration()) {
        self.configuration = configuration
    }

    func makeDisplayElevation(
        samples: [MotionSample],
        startDate: Date? = nil,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> ElevationDisplayResult {
        let sortedSamples = samples.sorted { lhs, rhs in lhs.timestamp < rhs.timestamp }
        let selectedSource = selectedElevationDisplaySource(for: sortedSamples)
        let anchorDate = startDate ?? sortedSamples.first?.timestamp
        guard let anchorDate else {
            return emptyResult(rawSampleCount: samples.count, droppedSampleCount: 0, selectedSource: selectedSource)
        }

        let anchor = absoluteElevationDisplayAnchor(for: sortedSamples, fidelityPolicy: fidelityPolicy)
        let rawPoints = elevationPoints(
            from: sortedSamples,
            startDate: anchorDate,
            selectedSource: selectedSource,
            anchor: anchor,
            fidelityPolicy: fidelityPolicy
        )
        let downsampledPoints = downsample(rawPoints, maxCount: configuration.maximumDisplayPointCount)
        let guardedPoints = selectedSource == .barometerRelative
            ? altitudeMicroDipDisplayGuardedPoints(downsampledPoints)
            : downsampledPoints
        let displayPoints = smoothedElevationPoints(guardedPoints)
        let elevationValues = displayPoints.map(\.elevationMeters)
        let droppedSampleCount = max(0, samples.count - rawPoints.count)
        let downsampledPointCount = max(0, rawPoints.count - downsampledPoints.count)
        let displayDerivedAscent = configuration.calculatesDisplayDerivedAscent
            ? displayDerivedTotalAscentMeters(from: displayPoints)
            : nil

        return ElevationDisplayResult(
            points: displayPoints,
            summary: ElevationDisplaySummary(
                quality: quality(for: displayPoints),
                rawSampleCount: samples.count,
                displayPointCount: displayPoints.count,
                elevationRange: elevationRange(for: elevationValues),
                displayDerivedTotalAscentMeters: displayDerivedAscent,
                selectedSource: selectedSource,
                segmentCount: Set(displayPoints.map(\.segmentID)).count,
                hasAbsoluteAnchor: anchor != nil,
                hasSparseData: displayPoints.count < 2
            ),
            diagnostics: ElevationDisplayDiagnostics(
                messages: diagnosticsMessages(
                    rawSampleCount: samples.count,
                    displayPointCount: displayPoints.count,
                    droppedSampleCount: droppedSampleCount,
                    downsampledPointCount: downsampledPointCount,
                    selectedSource: selectedSource,
                    hasAbsoluteAnchor: anchor != nil
                ),
                droppedSampleCount: droppedSampleCount,
                downsampledPointCount: downsampledPointCount
            )
        )
    }

    private func elevationPoints(
        from samples: [MotionSample],
        startDate: Date,
        selectedSource: ElevationDisplaySource,
        anchor: AbsoluteElevationDisplayAnchor?,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> [ElevationDisplayPoint] {
        var segmentID = 0
        var previousIncludedTimestamp: Date?
        var points: [ElevationDisplayPoint] = []

        for (index, sample) in samples.enumerated() {
            guard let elevation = displayElevationMeters(
                for: sample,
                selectedSource: selectedSource,
                anchor: anchor,
                fidelityPolicy: fidelityPolicy
            ), elevation.isFinite else {
                continue
            }

            if shouldStartNewElevationSegment(after: previousIncludedTimestamp, current: sample) {
                segmentID += 1
            }

            points.append(
                ElevationDisplayPoint(
                    id: index,
                    timestamp: sample.timestamp,
                    elapsedSeconds: max(0, sample.timestamp.timeIntervalSince(startDate)),
                    elevationMeters: elevation,
                    source: selectedSource,
                    segmentID: segmentID
                )
            )
            previousIncludedTimestamp = sample.timestamp
        }

        return points
    }

    private func selectedElevationDisplaySource(for samples: [MotionSample]) -> ElevationDisplaySource {
        if samples.contains(where: { trustedBarometerRelativeAltitude(for: $0) != nil }) { return .barometerRelative }
        if samples.contains(where: { trustedDebugAltitude(for: $0) != nil }) { return .debugSimulated }
        return .coreLocationAbsolute
    }

    private struct AbsoluteElevationDisplayAnchor: Equatable, Sendable {
        let offsetMeters: Double
    }

    private func absoluteElevationDisplayAnchor(
        for samples: [MotionSample],
        fidelityPolicy: ActivityFidelityPolicy
    ) -> AbsoluteElevationDisplayAnchor? {
        let absoluteSamples = samples.compactMap { sample -> (Date, Double)? in
            guard let altitude = trustedCoreLocationAbsoluteAltitude(for: sample, fidelityPolicy: fidelityPolicy) else { return nil }
            return (sample.timestamp, altitude)
        }
        let relativeSamples = samples.compactMap { sample -> (Date, Double)? in
            guard let altitude = trustedBarometerRelativeAltitude(for: sample) else { return nil }
            return (sample.timestamp, altitude)
        }

        guard !absoluteSamples.isEmpty, !relativeSamples.isEmpty else { return nil }

        let pairedOffsets = absoluteSamples.compactMap { absoluteTimestamp, absoluteAltitude -> Double? in
            guard let nearestRelative = relativeSamples.min(by: {
                abs($0.0.timeIntervalSince(absoluteTimestamp)) < abs($1.0.timeIntervalSince(absoluteTimestamp))
            }) else { return nil }
            guard abs(nearestRelative.0.timeIntervalSince(absoluteTimestamp)) <= 20 else { return nil }
            return absoluteAltitude - nearestRelative.1
        }

        guard let robustOffset = robustAbsoluteElevationOffsetMeters(from: pairedOffsets)
            ?? fallbackAbsoluteElevationOffsetMeters(absoluteSamples: absoluteSamples, relativeSamples: relativeSamples)
        else { return nil }

        return AbsoluteElevationDisplayAnchor(offsetMeters: robustOffset)
    }

    private func displayElevationMeters(
        for sample: MotionSample,
        selectedSource: ElevationDisplaySource,
        anchor: AbsoluteElevationDisplayAnchor?,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Double? {
        switch selectedSource {
        case .barometerRelative:
            guard let relativeAltitude = trustedBarometerRelativeAltitude(for: sample) else { return nil }
            return anchor.map { $0.offsetMeters + relativeAltitude } ?? relativeAltitude
        case .debugSimulated:
            return trustedDebugAltitude(for: sample)
        case .coreLocationAbsolute, .motionSample, .displayDerived:
            return trustedCoreLocationAbsoluteAltitude(for: sample, fidelityPolicy: fidelityPolicy)
        }
    }

    private func trustedBarometerRelativeAltitude(for sample: MotionSample) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.source == .barometerRelative {
            return diagnostics.isTrustedForElevationGain ? diagnostics.trustedAltitudeMeters : nil
        }
        guard sample.altitudeDiagnostics == nil, sample.altitudeSource == .barometerRelative,
              let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        return altitude
    }

    private func trustedCoreLocationAbsoluteAltitude(
        for sample: MotionSample,
        fidelityPolicy: ActivityFidelityPolicy
    ) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.source == .coreLocationAbsolute {
            return diagnostics.isTrustedForElevationGain ? diagnostics.trustedAltitudeMeters : nil
        }
        guard sample.altitudeDiagnostics == nil, sample.altitudeSource == .coreLocationAbsolute,
              let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        guard let verticalAccuracy = sample.locationDiagnostics?.verticalAccuracyMeters,
              verticalAccuracy <= min(fidelityPolicy.maximumVerticalAccuracyMeters, 8) else { return nil }
        guard sample.locationDiagnostics?.freshnessState != .stale else { return nil }
        return altitude
    }

    private func trustedDebugAltitude(for sample: MotionSample) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.source == .debugSimulated {
            return diagnostics.isTrustedForElevationGain ? diagnostics.trustedAltitudeMeters : nil
        }
        guard sample.altitudeDiagnostics == nil, sample.altitudeSource == .debugSimulated,
              let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        return altitude
    }

    private func robustAbsoluteElevationOffsetMeters(from offsets: [Double]) -> Double? {
        let finiteOffsets = offsets.filter(\.isFinite).sorted()
        guard finiteOffsets.count >= 3 else { return nil }

        let lowerQuartile = finiteOffsets[finiteOffsets.count / 4]
        let medianOffset = finiteOffsets[finiteOffsets.count / 2]
        let upperQuartile = finiteOffsets[(finiteOffsets.count * 3) / 4]

        if upperQuartile - lowerQuartile >= 7, medianOffset - lowerQuartile >= 5 {
            return lowerQuartile
        }

        let trimCount = finiteOffsets.count >= 7 ? max(1, finiteOffsets.count / 5) : 0
        let upperExclusive = finiteOffsets.count - trimCount
        guard trimCount < upperExclusive else { return medianOffset }
        let trimmed = Array(finiteOffsets[trimCount..<upperExclusive])
        return trimmed[trimmed.count / 2]
    }

    private func fallbackAbsoluteElevationOffsetMeters(
        absoluteSamples: [(Date, Double)],
        relativeSamples: [(Date, Double)]
    ) -> Double? {
        guard let firstTimestamp = [absoluteSamples.first?.0, relativeSamples.first?.0].compactMap({ $0 }).min() else { return nil }
        let absoluteWindow = absoluteSamples
            .filter { $0.0.timeIntervalSince(firstTimestamp) <= 90 }
            .map(\.1)
            .filter(\.isFinite)
            .sorted()
        let relativeWindow = relativeSamples
            .filter { $0.0.timeIntervalSince(firstTimestamp) <= 90 }
            .map(\.1)
            .filter(\.isFinite)
            .sorted()
        guard let absoluteMedian = median(absoluteWindow), let relativeMedian = median(relativeWindow) else { return nil }
        return absoluteMedian - relativeMedian
    }

    private func altitudeMicroDipDisplayGuardedPoints(_ points: [ElevationDisplayPoint]) -> [ElevationDisplayPoint] {
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [ElevationDisplayPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 15 else { return sorted }
            let lookback = 8
            let lookahead = 8
            let guardBand = 2
            let minimumDipMeters = 1.35
            let maximumBaselineDisagreementMeters = 0.85
            let maximumGuardSpanSeconds = 34.0

            return sorted.enumerated().map { offset, point in
                let leftStart = max(0, offset - lookback)
                let leftEnd = max(0, offset - guardBand)
                let rightStart = min(sorted.count, offset + guardBand + 1)
                let rightEnd = min(sorted.count, offset + lookahead + 1)
                guard leftEnd - leftStart >= 3, rightEnd - rightStart >= 3 else { return point }
                let leftWindow = Array(sorted[leftStart..<leftEnd])
                let rightWindow = Array(sorted[rightStart..<rightEnd])
                let timeSpan = (rightWindow.last?.elapsedSeconds ?? point.elapsedSeconds)
                    - (leftWindow.first?.elapsedSeconds ?? point.elapsedSeconds)
                guard timeSpan <= maximumGuardSpanSeconds,
                      let leftMedian = median(leftWindow.map(\.elevationMeters).sorted()),
                      let rightMedian = median(rightWindow.map(\.elevationMeters).sorted()),
                      abs(leftMedian - rightMedian) <= maximumBaselineDisagreementMeters else { return point }
                let baseline = (leftMedian + rightMedian) / 2
                guard baseline - point.elevationMeters >= minimumDipMeters else { return point }
                return point.replacingElevationMeters(baseline)
            }
        }
        .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    private func smoothedElevationPoints(_ points: [ElevationDisplayPoint]) -> [ElevationDisplayPoint] {
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [ElevationDisplayPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 3 else { return sorted }
            var previousSmoothedElevation: Double?

            return sorted.enumerated().map { offset, point in
                let lowerBound = max(0, offset - Self.smoothingWindowRadius)
                let upperBound = min(sorted.count - 1, offset + Self.smoothingWindowRadius)
                let windowElevations = sorted[lowerBound...upperBound].map(\.elevationMeters).sorted()
                let median = windowElevations[windowElevations.count / 2]
                let referenceElevation = previousSmoothedElevation ?? median
                let limitedElevation = min(
                    max(median, referenceElevation - Self.maximumSmoothingStepMeters),
                    referenceElevation + Self.maximumSmoothingStepMeters
                )
                previousSmoothedElevation = limitedElevation
                return point.replacingElevationMeters(limitedElevation)
            }
        }
        .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    private func shouldStartNewElevationSegment(after previousTimestamp: Date?, current sample: MotionSample) -> Bool {
        if let previousTimestamp, sample.timestamp.timeIntervalSince(previousTimestamp) > Self.defaultChartSegmentGapSeconds {
            return true
        }
        let source = sample.altitudeDiagnostics?.source ?? sample.altitudeSource ?? .unavailable
        if source == .barometerRelative || source == .debugSimulated { return false }
        guard let diagnostics = sample.locationDiagnostics else { return false }
        if diagnostics.freshnessState == .stale { return true }
        return diagnostics.gpsUpdateIntervalSeconds.map { $0 > Self.defaultChartSegmentGapSeconds } == true
    }

    private func downsample(_ points: [ElevationDisplayPoint], maxCount: Int) -> [ElevationDisplayPoint] {
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

    private func displayDerivedTotalAscentMeters(from points: [ElevationDisplayPoint]) -> Double? {
        guard configuration.calculatesDisplayDerivedAscent, points.count >= 2 else { return nil }
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        let ascent = grouped.values.reduce(0.0) { partial, segmentPoints in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 2 else { return partial }
            return partial + zip(sorted, sorted.dropFirst()).reduce(0.0) { segmentPartial, pair in
                let delta = pair.1.elevationMeters - pair.0.elevationMeters
                return delta > 0 ? segmentPartial + delta : segmentPartial
            }
        }
        return ascent.isFinite ? max(0, ascent) : nil
    }

    private func elevationRange(for values: [Double]) -> ElevationDisplayRange? {
        let finiteValues = values.filter(\.isFinite)
        guard let minimum = finiteValues.min(), let maximum = finiteValues.max() else { return nil }
        return ElevationDisplayRange(minimumMeters: minimum, maximumMeters: maximum)
    }

    private func quality(for points: [ElevationDisplayPoint]) -> ActivityVisualizationQuality {
        if points.isEmpty { return .unavailable }
        if points.count < 2 { return .limited }
        return .usable
    }

    private func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values[values.count / 2]
    }

    private func diagnosticsMessages(
        rawSampleCount: Int,
        displayPointCount: Int,
        droppedSampleCount: Int,
        downsampledPointCount: Int,
        selectedSource: ElevationDisplaySource,
        hasAbsoluteAnchor: Bool
    ) -> [String] {
        var messages: [String] = []
        if rawSampleCount == 0 { messages.append("elevation.noSamples") }
        if displayPointCount < 2 { messages.append("elevation.sparseDisplayPoints") }
        if droppedSampleCount > 0 { messages.append("elevation.droppedInvalidOrUntrustedSamples") }
        if downsampledPointCount > 0 { messages.append("elevation.downsampledForDisplay") }
        if selectedSource == .barometerRelative, hasAbsoluteAnchor { messages.append("elevation.absoluteAnchorApplied") }
        return messages
    }

    private func emptyResult(
        rawSampleCount: Int,
        droppedSampleCount: Int,
        selectedSource: ElevationDisplaySource
    ) -> ElevationDisplayResult {
        ElevationDisplayResult(
            summary: ElevationDisplaySummary(
                quality: .unavailable,
                rawSampleCount: rawSampleCount,
                displayPointCount: 0,
                selectedSource: selectedSource,
                segmentCount: 0,
                hasSparseData: true
            ),
            diagnostics: ElevationDisplayDiagnostics(
                messages: rawSampleCount == 0 ? ["elevation.noSamples"] : ["elevation.sparseDisplayPoints"],
                droppedSampleCount: droppedSampleCount
            )
        )
    }
}

private extension ElevationDisplayPoint {
    func replacingElevationMeters(_ elevationMeters: Double) -> ElevationDisplayPoint {
        ElevationDisplayPoint(
            id: id,
            timestamp: timestamp,
            elapsedSeconds: elapsedSeconds,
            elevationMeters: elevationMeters,
            source: source,
            segmentID: segmentID
        )
    }
}
