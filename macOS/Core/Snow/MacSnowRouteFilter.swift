// [協作區] MacSnowRouteFilter.swift
// 用途：提供 macOS Snow viewer 的 segment time-window route / elevation filtering，不修改 SnowSegment 或 MotionSample。
// 委派至：MacSnowSessionAnalysisMapper 與後續 Route + Elevation UI。

import Foundation

enum MacSnowRouteFilter {
    static func routeSamples(
        for segment: SnowSegment?,
        in samples: [MotionSample]
    ) -> [MotionSample] {
        guard let segment else { return samples.sortedByTimestamp }
        let start = segment.startDate
        let end = segment.endDate ?? segment.startDate
        return samples
            .filter { sample in
                sample.timestamp >= start && sample.timestamp <= end
            }
            .sortedByTimestamp
    }

    static func routePoints(from samples: [MotionSample]) -> [MacSnowRoutePoint] {
        samples.sortedByTimestamp.compactMap { sample in
            guard let coordinate = sample.gpsCoordinate else { return nil }
            return MacSnowRoutePoint(
                timestamp: sample.timestamp,
                coordinate: coordinate,
                altitudeMeters: sample.altitudeMeters,
                speedKmh: sample.speedKmh
            )
        }
    }

    static func elevationPoints(from samples: [MotionSample]) -> [MacSnowElevationPoint] {
        samples.sortedByTimestamp.compactMap { sample in
            guard let altitude = sample.altitudeMeters else { return nil }
            return MacSnowElevationPoint(
                timestamp: sample.timestamp,
                altitudeMeters: altitude
            )
        }
    }

    static func hasLimitedAltitudeData(
        segments: [SnowSegment],
        samples: [MotionSample]
    ) -> Bool {
        let hasSampleAltitude = samples.contains { $0.altitudeMeters != nil }
        let hasMissingSegmentAltitude = segments.contains { segment in
            segment.startAltitudeMeters == nil || segment.endAltitudeMeters == nil
        }
        return !hasSampleAltitude || hasMissingSegmentAltitude
    }
}

private extension Array where Element == MotionSample {
    var sortedByTimestamp: [MotionSample] {
        sorted { $0.timestamp < $1.timestamp }
    }
}
