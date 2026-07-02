
import SwiftUI

struct SessionSummaryChartPoint: Identifiable, Equatable {
    let id: Int
    let elapsedSeconds: Double
    let value: Double
    let segmentID: Int
}

struct SessionSummaryChartSegment: Identifiable, Equatable {
    let id: Int
    let points: [SessionSummaryChartPoint]
}

struct SessionAdvancedChartsView: View {
    let content: SessionSummaryContent
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    let onUnlock: () -> Void

    private var fidelityPolicy: ActivityFidelityPolicy {
        ActivityFidelityPolicy(
            profile: content.session.fidelityProfile
                ?? ActivityFidelityProfile.defaultProfile(for: content.session.sportMode, powerType: content.session.powerType)
        )
    }

    private var speedPoints: [SessionSummaryChartPoint] {
        smoothedSpeedPoints(chartPoints(from: content.motionSamples) { displaySpeedKilometersPerHour(for: $0) })
    }

    private var elevationPoints: [SessionSummaryChartPoint] {
        let source = preferredElevationDisplaySource(for: content.motionSamples)
        let anchor = absoluteElevationDisplayAnchor(for: content.motionSamples)
        let rawPoints = chartPoints(from: content.motionSamples) { displayElevationMeters(for: $0, source: source, anchor: anchor) }
        let sourceGuardedPoints = source == .barometerRelative ? altitudeMicroDipDisplayGuardedPoints(rawPoints) : rawPoints
        return smoothedElevationPoints(sourceGuardedPoints)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if subscriptionStatus.hasAccess(to: .advancedCharts) {
                unlockedCharts
            } else {
                AdvancedChartsLockedView(speedPoints: speedPoints, elevationPoints: elevationPoints, onUnlock: onUnlock)
            }

            HeartRateZonePlaceholderView()
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border.opacity(0.85), lineWidth: 1))
        .accessibilityIdentifier("session-advanced-charts-view")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)

                Text("summary.advancedCharts.title")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(LocalizedStringKey(subscriptionStatus.hasAccess(to: .advancedCharts) ? "subscription.subscriber" : "subscription.pro_badge"))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(subscriptionStatus.hasAccess(to: .advancedCharts) ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }

            Text(LocalizedStringKey(subscriptionStatus.hasAccess(to: .advancedCharts) ? "summary.advancedCharts.unlocked.subtitle" : "summary.advancedCharts.locked.subtitle"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var unlockedCharts: some View {
        VStack(spacing: 12) { SpeedTimelineChartView(points: speedPoints); ElevationProfileChartView(points: elevationPoints) }
            .accessibilityIdentifier("session-advanced-charts-unlocked")
    }

    private func displaySpeedKilometersPerHour(for sample: MotionSample) -> Double? {
        // Task-030c-b13-A-4: chart display falls back to metric-eligible diagnostics speed.
        SessionSummaryDisplayMetrics.displaySpeedKilometersPerHour(for: sample, policy: fidelityPolicy)
    }

    private enum ElevationDisplaySource {
        case barometerRelative
        case coreLocationAbsolute
        case debugSimulated
    }

    private func preferredElevationDisplaySource(for samples: [MotionSample]) -> ElevationDisplaySource {
        if samples.contains(where: { trustedBarometerRelativeAltitude(for: $0) != nil }) { return .barometerRelative }
        if samples.contains(where: { trustedDebugAltitude(for: $0) != nil }) { return .debugSimulated }
        return .coreLocationAbsolute
    }

    private struct AbsoluteElevationDisplayAnchor: Equatable {
        let offsetMeters: Double
    }

    private func absoluteElevationDisplayAnchor(for samples: [MotionSample]) -> AbsoluteElevationDisplayAnchor? {
        let sorted = samples.sorted { $0.timestamp < $1.timestamp }
        let absoluteSamples = sorted.compactMap { sample -> (Date, Double)? in
            guard let altitude = trustedCoreLocationAbsoluteAltitude(for: sample) else { return nil }
            return (sample.timestamp, altitude)
        }
        let relativeSamples = sorted.compactMap { sample -> (Date, Double)? in
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

        guard let robustOffset = robustAbsoluteElevationOffsetMeters(from: pairedOffsets) ?? fallbackAbsoluteElevationOffsetMeters(absoluteSamples: absoluteSamples, relativeSamples: relativeSamples) else { return nil }
        return AbsoluteElevationDisplayAnchor(offsetMeters: robustOffset)
    }

    private func robustAbsoluteElevationOffsetMeters(from offsets: [Double]) -> Double? {
        let finiteOffsets = offsets.filter(\.isFinite).sorted()
        guard finiteOffsets.count >= 3 else { return nil }

        let lowerQuartile = finiteOffsets[finiteOffsets.count / 4]
        let medianOffset = finiteOffsets[finiteOffsets.count / 2]
        let upperQuartile = finiteOffsets[(finiteOffsets.count * 3) / 4]

        // Task-030c-b13-A-4: when CoreLocation altitude offsets are multi-modal,
        // the median can be pulled into a late high-altitude drift cluster. Use
        // the lower stable quartile only when the spread clearly indicates that
        // absolute altitude samples disagree by several meters. This is a
        // generic drift guard, not a per-session correction.
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

    private func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values[values.count / 2]
    }

    private func displayElevationMeters(
        for sample: MotionSample,
        source: ElevationDisplaySource,
        anchor: AbsoluteElevationDisplayAnchor?
    ) -> Double? {
        if source == .barometerRelative,
           let relativeAltitude = trustedBarometerRelativeAltitude(for: sample) {
            // Task-030c-b13-A-4: display stable relative altitude against a robust absolute anchor when available.
            return anchor.map { $0.offsetMeters + relativeAltitude } ?? relativeAltitude
        }

        if source == .debugSimulated {
            return trustedDebugAltitude(for: sample)
        }

        return trustedCoreLocationAbsoluteAltitude(for: sample)
    }

    private func trustedBarometerRelativeAltitude(for sample: MotionSample) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.source == .barometerRelative {
            return diagnostics.isTrustedForElevationGain ? diagnostics.trustedAltitudeMeters : nil
        }
        guard sample.altitudeDiagnostics == nil, sample.altitudeSource == .barometerRelative,
              let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        return altitude
    }

    private func trustedCoreLocationAbsoluteAltitude(for sample: MotionSample) -> Double? {
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

    private func chartPoints(
        from samples: [MotionSample],
        value: (MotionSample) -> Double?
    ) -> [SessionSummaryChartPoint] {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let firstTimestamp = sortedSamples.first?.timestamp else { return [] }

        var segmentID = 0
        var previousIncludedTimestamp: Date?
        var points: [SessionSummaryChartPoint] = []

        for (index, sample) in sortedSamples.enumerated() {
            guard let value = value(sample), value.isFinite else { continue }

            if shouldStartNewChartSegment(after: previousIncludedTimestamp, current: sample) {
                segmentID += 1
            }

            points.append(SessionSummaryChartPoint(id: index, elapsedSeconds: max(0, sample.timestamp.timeIntervalSince(firstTimestamp)), value: value, segmentID: segmentID))
            previousIncludedTimestamp = sample.timestamp
        }

        return downsample(points, maxCount: 120)
    }

    private func smoothedSpeedPoints(_ points: [SessionSummaryChartPoint]) -> [SessionSummaryChartPoint] {
        smooth(points, windowRadius: 2, maximumStepValue: 2.2)
    }

    private func smoothedElevationPoints(_ points: [SessionSummaryChartPoint]) -> [SessionSummaryChartPoint] {
        // Task-030c-b13-A-4: display-only smoothing reduces short altitude spikes without rewriting stored samples.
        smooth(points, windowRadius: 5, maximumStepValue: 0.45)
    }
    private func altitudeMicroDipDisplayGuardedPoints(_ points: [SessionSummaryChartPoint]) -> [SessionSummaryChartPoint] {
        // Task-030c-b14-B-1: display-only guard for very short barometer notches; does not rewrite MotionSample, elevation gain summaries, route geometry, or exported diagnostics.
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [SessionSummaryChartPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 15 else { return sorted }
            let lookback = 8, lookahead = 8, guardBand = 2, minimumDipMeters = 1.35
            let maximumBaselineDisagreementMeters = 0.85, maximumGuardSpanSeconds = 34.0
            return sorted.enumerated().map { offset, point in
                let leftStart = max(0, offset - lookback), leftEnd = max(0, offset - guardBand)
                let rightStart = min(sorted.count, offset + guardBand + 1), rightEnd = min(sorted.count, offset + lookahead + 1)
                guard leftEnd - leftStart >= 3, rightEnd - rightStart >= 3 else { return point }
                let leftWindow = Array(sorted[leftStart..<leftEnd]), rightWindow = Array(sorted[rightStart..<rightEnd])
                let timeSpan = (rightWindow.last?.elapsedSeconds ?? point.elapsedSeconds) - (leftWindow.first?.elapsedSeconds ?? point.elapsedSeconds)
                guard timeSpan <= maximumGuardSpanSeconds, let leftMedian = median(leftWindow.map(\.value).sorted()), let rightMedian = median(rightWindow.map(\.value).sorted()),
                      abs(leftMedian - rightMedian) <= maximumBaselineDisagreementMeters else { return point }
                let baseline = (leftMedian + rightMedian) / 2
                guard baseline - point.value >= minimumDipMeters else { return point }
                return SessionSummaryChartPoint(id: point.id, elapsedSeconds: point.elapsedSeconds, value: baseline, segmentID: point.segmentID)
            }
        }.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }
    private func smooth(
        _ points: [SessionSummaryChartPoint],
        windowRadius: Int,
        maximumStepValue: Double
    ) -> [SessionSummaryChartPoint] {
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [SessionSummaryChartPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 3 else { return sorted }
            var previousSmoothedValue: Double?
            return sorted.enumerated().map { offset, point in
                let lowerBound = max(0, offset - windowRadius)
                let upperBound = min(sorted.count - 1, offset + windowRadius)
                let windowValues = sorted[lowerBound...upperBound].map(\.value).sorted()
                let median = windowValues[windowValues.count / 2]
                let referenceValue = previousSmoothedValue ?? median
                let limitedValue = min(max(median, referenceValue - maximumStepValue), referenceValue + maximumStepValue)
                previousSmoothedValue = limitedValue
                return SessionSummaryChartPoint(id: point.id, elapsedSeconds: point.elapsedSeconds, value: limitedValue, segmentID: point.segmentID)
            }
        }
        .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    private func shouldStartNewChartSegment(after previousTimestamp: Date?, current sample: MotionSample) -> Bool {
        if let previousTimestamp, sample.timestamp.timeIntervalSince(previousTimestamp) > 12 { return true }
        // Task-030c-b14-B-1: barometer/debug altitude charts are independent from GPS fix cadence.
        if [AltitudeSampleSource.barometerRelative, .debugSimulated].contains(sample.altitudeDiagnostics?.source ?? sample.altitudeSource ?? .unavailable) { return false }
        guard let diagnostics = sample.locationDiagnostics else { return false }
        if diagnostics.freshnessState == .stale { return true }
        // Task-030c-b11-r2: low-confidence means uncertain, not missing. Keep charts
        // continuous across fresh uncertain segments; real stale fixes and long update gaps
        // remain the only chart-break triggers.
        if diagnostics.gpsUpdateIntervalSeconds.map({ $0 > 12 }) == true { return true }
        return false
    }

    private func downsample(_ points: [SessionSummaryChartPoint], maxCount: Int) -> [SessionSummaryChartPoint] {
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
}
