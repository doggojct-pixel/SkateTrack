// [協作區] MacElevationDisplayPipeline.swift
// 用途：為 macOS read-only package viewer 建立顯示用海拔剖面點，不改寫 MotionSample、summaryMetrics 或 package schema。
// 委派至：Task-030e-MacViewer-008-1 Elevation Profile + Total Ascent Display Alignment。
// Safety: creates display-only elevation profile points; never writes derived elevation back to trusted metrics or package data.

import Foundation

enum MacElevationDisplayPipeline {
    private enum ElevationDisplaySource {
        case barometerRelative
        case coreLocationAbsolute
        case debugSimulated
    }

    private struct AbsoluteElevationDisplayAnchor: Equatable {
        let offsetMeters: Double
    }

    static func elevationPoints(session: SessionData, samples: [MotionSample]) -> [MacElevationPoint] {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let firstDate = sortedSamples.first?.timestamp else { return [] }
        let policy = ActivityFidelityPolicy(
            profile: session.fidelityProfile ?? ActivityFidelityProfile.defaultProfile(for: session.sportMode, powerType: session.powerType)
        )
        let source = preferredElevationDisplaySource(for: sortedSamples)
        let anchor = absoluteElevationDisplayAnchor(for: sortedSamples)
        var segmentID = 0
        var previousIncludedTimestamp: Date?

        let points = sortedSamples.enumerated().compactMap { index, sample -> MacElevationPoint? in
            guard let elevation = displayElevationMeters(for: sample, source: source, anchor: anchor, policy: policy), elevation.isFinite else { return nil }
            if shouldStartNewSegment(after: previousIncludedTimestamp, current: sample) { segmentID += 1 }
            previousIncludedTimestamp = sample.timestamp
            return MacElevationPoint(
                id: index,
                timestamp: sample.timestamp,
                elapsedSeconds: max(0, sample.timestamp.timeIntervalSince(firstDate)),
                elevationMeters: elevation,
                segmentID: segmentID
            )
        }

        return downsample(elevationPoints: smoothedElevationPoints(points), maxCount: 180)
    }

    private static func preferredElevationDisplaySource(for samples: [MotionSample]) -> ElevationDisplaySource {
        if samples.contains(where: { trustedBarometerRelativeAltitude(for: $0) != nil }) { return .barometerRelative }
        if samples.contains(where: { trustedDebugAltitude(for: $0) != nil }) { return .debugSimulated }
        return .coreLocationAbsolute
    }

    private static func absoluteElevationDisplayAnchor(for samples: [MotionSample]) -> AbsoluteElevationDisplayAnchor? {
        let absoluteSamples = samples.compactMap { sample -> (Date, Double)? in
            guard let altitude = trustedCoreLocationAbsoluteAltitude(for: sample, policy: nil) else { return nil }
            return (sample.timestamp, altitude)
        }
        let relativeSamples = samples.compactMap { sample -> (Date, Double)? in
            guard let altitude = trustedBarometerRelativeAltitude(for: sample) else { return nil }
            return (sample.timestamp, altitude)
        }
        guard !absoluteSamples.isEmpty, !relativeSamples.isEmpty else { return nil }
        let offsets = absoluteSamples.compactMap { timestamp, altitude -> Double? in
            guard let nearest = relativeSamples.min(by: { abs($0.0.timeIntervalSince(timestamp)) < abs($1.0.timeIntervalSince(timestamp)) }),
                  abs(nearest.0.timeIntervalSince(timestamp)) <= 20 else { return nil }
            return altitude - nearest.1
        }
        guard let offset = robustMedianOffset(from: offsets) else { return nil }
        return AbsoluteElevationDisplayAnchor(offsetMeters: offset)
    }

    private static func displayElevationMeters(for sample: MotionSample, source: ElevationDisplaySource, anchor: AbsoluteElevationDisplayAnchor?, policy: ActivityFidelityPolicy) -> Double? {
        if source == .barometerRelative, let relative = trustedBarometerRelativeAltitude(for: sample) {
            return anchor.map { $0.offsetMeters + relative } ?? relative
        }
        if source == .debugSimulated { return trustedDebugAltitude(for: sample) }
        return trustedCoreLocationAbsoluteAltitude(for: sample, policy: policy)
    }

    private static func trustedBarometerRelativeAltitude(for sample: MotionSample) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.source == .barometerRelative {
            return diagnostics.isTrustedForElevationGain ? diagnostics.trustedAltitudeMeters : nil
        }
        guard sample.altitudeDiagnostics == nil, sample.altitudeSource == .barometerRelative,
              let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        return altitude
    }

    private static func trustedCoreLocationAbsoluteAltitude(for sample: MotionSample, policy: ActivityFidelityPolicy?) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.source == .coreLocationAbsolute {
            return diagnostics.isTrustedForElevationGain ? diagnostics.trustedAltitudeMeters : nil
        }
        guard sample.altitudeDiagnostics == nil, sample.altitudeSource == .coreLocationAbsolute,
              let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        if let policy {
            guard let verticalAccuracy = sample.locationDiagnostics?.verticalAccuracyMeters,
                  verticalAccuracy <= min(policy.maximumVerticalAccuracyMeters, 8) else { return nil }
            guard sample.locationDiagnostics?.freshnessState != .stale else { return nil }
        }
        return altitude
    }

    private static func trustedDebugAltitude(for sample: MotionSample) -> Double? {
        if let diagnostics = sample.altitudeDiagnostics, diagnostics.source == .debugSimulated {
            return diagnostics.isTrustedForElevationGain ? diagnostics.trustedAltitudeMeters : nil
        }
        guard sample.altitudeDiagnostics == nil, sample.altitudeSource == .debugSimulated,
              let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
        return altitude
    }

    private static func robustMedianOffset(from offsets: [Double]) -> Double? {
        let finiteOffsets = offsets.filter(\.isFinite).sorted()
        guard !finiteOffsets.isEmpty else { return nil }
        if finiteOffsets.count >= 3 {
            let lowerQuartile = finiteOffsets[finiteOffsets.count / 4]
            let medianOffset = finiteOffsets[finiteOffsets.count / 2]
            let upperQuartile = finiteOffsets[(finiteOffsets.count * 3) / 4]
            if upperQuartile - lowerQuartile >= 7, medianOffset - lowerQuartile >= 5 { return lowerQuartile }
        }
        return finiteOffsets[finiteOffsets.count / 2]
    }

    private static func smoothedElevationPoints(_ points: [MacElevationPoint]) -> [MacElevationPoint] {
        let grouped = Dictionary(grouping: points, by: \.segmentID)
        return grouped.flatMap { _, segmentPoints -> [MacElevationPoint] in
            let sorted = segmentPoints.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
            guard sorted.count >= 3 else { return sorted }
            var previousValue: Double?
            return sorted.enumerated().map { index, point in
                let values = sorted[max(0, index - 5)...min(sorted.count - 1, index + 5)].map(\.elevationMeters).sorted()
                let median = values[values.count / 2]
                let reference = previousValue ?? median
                let limited = min(max(median, reference - 0.45), reference + 0.45)
                previousValue = limited
                return MacElevationPoint(id: point.id, timestamp: point.timestamp, elapsedSeconds: point.elapsedSeconds, elevationMeters: limited, segmentID: point.segmentID)
            }
        }.sorted { $0.elapsedSeconds < $1.elapsedSeconds }
    }

    private static func shouldStartNewSegment(after previousTimestamp: Date?, current sample: MotionSample) -> Bool {
        if let previousTimestamp, sample.timestamp.timeIntervalSince(previousTimestamp) > 12 { return true }
        let source = sample.altitudeDiagnostics?.source ?? sample.altitudeSource ?? .unavailable
        if source == .barometerRelative || source == .debugSimulated { return false }
        guard let diagnostics = sample.locationDiagnostics else { return false }
        if diagnostics.freshnessState == .stale { return true }
        return diagnostics.gpsUpdateIntervalSeconds.map { $0 > 12 } == true
    }

    private static func downsample(elevationPoints: [MacElevationPoint], maxCount: Int) -> [MacElevationPoint] {
        guard elevationPoints.count > maxCount, maxCount > 0 else { return elevationPoints }
        let stride = max(1, Int(ceil(Double(elevationPoints.count) / Double(maxCount))))
        return elevationPoints.enumerated().compactMap { index, point in index % stride == 0 || index == elevationPoints.count - 1 ? point : nil }
    }
}
