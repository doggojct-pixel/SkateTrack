
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
        smoothedSpeedPoints(chartPoints(from: content.motionSamples) { trustedDisplaySpeedKilometersPerHour(for: $0) })
    }

    private var elevationPoints: [SessionSummaryChartPoint] {
        let source = preferredElevationDisplaySource(for: content.motionSamples)
        return normalizedElevationPoints(chartPoints(from: content.motionSamples) { trustedDisplayElevationMeters(for: $0, source: source) })
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

    private func trustedDisplaySpeedKilometersPerHour(for sample: MotionSample) -> Double? {
        guard sample.speedKmh.isFinite, sample.speedKmh >= 0 else { return nil }
        if sample.sampleSource == .debugSimulated {
            return fidelityPolicy.acceptsSpeed(sample.speedKmh) ? sample.speedKmh : nil
        }

        guard let diagnostics = sample.locationDiagnostics else {
            return fidelityPolicy.acceptsSpeed(sample.speedKmh) ? sample.speedKmh : nil
        }
        guard diagnostics.routeSegmentConfidence != .unavailable else { return nil }
        guard diagnostics.freshnessState == .fresh || diagnostics.freshnessState == .recent else { return nil }
        guard fidelityPolicy.acceptsLowSpeedMetricSample(
            speedKmh: sample.speedKmh,
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            speedAccuracyMetersPerSecond: diagnostics.speedAccuracyMetersPerSecond,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters
        ) else { return nil }
        guard fidelityPolicy.trustsRouteSegment(
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            freshnessState: diagnostics.freshnessState,
            updateIntervalSeconds: diagnostics.gpsUpdateIntervalSeconds,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh
        ) else { return nil }

        // Task-030c-b10-r5: summary charts should not present one-off Core Location
        // instantaneous speed pulses as the rider's displayed timeline. Keep raw speed in
        // diagnostics; require either a precise fix or corroborated coordinate-derived speed.
        if sample.speedKmh >= 5.5 {
            let horizontalAccuracy = diagnostics.horizontalAccuracyMeters ?? .infinity
            let speedAccuracy = diagnostics.speedAccuracyMetersPerSecond ?? .infinity
            let coordinateSpeed = diagnostics.coordinateDerivedSpeedKmh ?? sample.speedKmh
            let isPreciseFix = horizontalAccuracy <= fidelityPolicy.speedDisplayCorroborationAccuracyMeters
            let isSpeedAccurate = speedAccuracy <= 1.1
            let isCoordinateCorroborated = abs(coordinateSpeed - sample.speedKmh) <= max(2.0, sample.speedKmh * 0.35)
            if !(isPreciseFix && (isSpeedAccurate || isCoordinateCorroborated)) {
                return nil
            }
        }

        return sample.speedKmh
    }

    private enum ElevationDisplaySource {
        case barometerRelative
        case coreLocationAbsolute
        case debugSimulated
    }

    private func preferredElevationDisplaySource(for samples: [MotionSample]) -> ElevationDisplaySource {
        if samples.contains(where: { ($0.altitudeDiagnostics?.source == .barometerRelative && ($0.altitudeDiagnostics?.trustedAltitudeMeters?.isFinite ?? false)) || ($0.altitudeSource == .barometerRelative && ($0.altitudeMeters?.isFinite ?? false)) }) { return .barometerRelative }
        if samples.contains(where: { ($0.altitudeDiagnostics?.source == .debugSimulated && ($0.altitudeDiagnostics?.trustedAltitudeMeters?.isFinite ?? false)) || ($0.altitudeSource == .debugSimulated && ($0.altitudeMeters?.isFinite ?? false)) }) { return .debugSimulated }
        return .coreLocationAbsolute
    }

    private func trustedDisplayElevationMeters(for sample: MotionSample, source: ElevationDisplaySource) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.isTrustedForElevationGain, let trustedAltitude = diagnostics.trustedAltitudeMeters, trustedAltitude.isFinite {
            return ((source == .barometerRelative && diagnostics.source == .barometerRelative) || (source == .debugSimulated && diagnostics.source == .debugSimulated) || (source == .coreLocationAbsolute && diagnostics.source == .coreLocationAbsolute)) ? trustedAltitude : nil
        }
        guard let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        switch source {
        case .barometerRelative:
            return sample.altitudeSource == .barometerRelative ? altitude : nil
        case .debugSimulated:
            return sample.altitudeSource == .debugSimulated ? altitude : nil
        case .coreLocationAbsolute:
            guard sample.altitudeSource == .coreLocationAbsolute else { return nil }
            guard let verticalAccuracy = sample.locationDiagnostics?.verticalAccuracyMeters,
                  verticalAccuracy <= min(fidelityPolicy.maximumVerticalAccuracyMeters, 5) else { return nil }
            guard sample.locationDiagnostics?.freshnessState != .stale else { return nil }
            return altitude
        }
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
        smooth(points, windowRadius: 2, maximumStepKmh: 2.2)
    }

    private func normalizedElevationPoints(_ points: [SessionSummaryChartPoint]) -> [SessionSummaryChartPoint] {
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [SessionSummaryChartPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard let baseline = sorted.first?.value else { return sorted }
            return sorted.map { point in
                SessionSummaryChartPoint(id: point.id, elapsedSeconds: point.elapsedSeconds, value: point.value - baseline, segmentID: point.segmentID)
            }
        }
        .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    private func smooth(
        _ points: [SessionSummaryChartPoint],
        windowRadius: Int,
        maximumStepKmh: Double
    ) -> [SessionSummaryChartPoint] {
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [SessionSummaryChartPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 3 else { return sorted }
            return sorted.enumerated().map { offset, point in
                let lowerBound = max(0, offset - windowRadius)
                let upperBound = min(sorted.count - 1, offset + windowRadius)
                let windowValues = sorted[lowerBound...upperBound].map(\.value).sorted()
                let median = windowValues[windowValues.count / 2]
                let previousValue = offset > 0 ? sorted[offset - 1].value : median
                let limitedValue = min(max(median, previousValue - maximumStepKmh), previousValue + maximumStepKmh)
                return SessionSummaryChartPoint(id: point.id, elapsedSeconds: point.elapsedSeconds, value: limitedValue, segmentID: point.segmentID)
            }
        }
        .sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    private func shouldStartNewChartSegment(after previousTimestamp: Date?, current sample: MotionSample) -> Bool {
        if let previousTimestamp, sample.timestamp.timeIntervalSince(previousTimestamp) > 12 {
            return true
        }

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
