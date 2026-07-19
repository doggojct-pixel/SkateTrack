// [協作區] Shared/Models/SnowVerticalMetrics.swift
// 用途：定義 Snow Mode 的垂直落差 / 爬升統計，供 run summary、watchOS 與 macOS viewer 使用。
// 委派至：RunBoundaryDetector、SnowSessionRepository、Snow UI 與 package compatibility。

import Foundation

struct SnowVerticalMetrics: Codable, Sendable, Equatable {
    let totalVerticalDropMeters: Double
    let totalVerticalGainMeters: Double
    let maxAltitudeMeters: Double?
    let minAltitudeMeters: Double?
    let maxSlopeAngleDegrees: Double?

    init(
        totalVerticalDropMeters: Double = 0,
        totalVerticalGainMeters: Double = 0,
        maxAltitudeMeters: Double? = nil,
        minAltitudeMeters: Double? = nil,
        maxSlopeAngleDegrees: Double? = nil
    ) {
        self.totalVerticalDropMeters = max(0, totalVerticalDropMeters)
        self.totalVerticalGainMeters = max(0, totalVerticalGainMeters)
        self.maxAltitudeMeters = maxAltitudeMeters
        self.minAltitudeMeters = minAltitudeMeters
        self.maxSlopeAngleDegrees = maxSlopeAngleDegrees
    }

    static let zero = SnowVerticalMetrics()

    static func make(from segments: [SnowSegment], runs: [SnowRun]) -> SnowVerticalMetrics {
        let altitudeValues = segments.flatMap { segment in
            [segment.startAltitudeMeters, segment.endAltitudeMeters].compactMap { $0 }
        }
        let verticalDrop = runs.reduce(0) { $0 + $1.verticalDropMeters }
        let verticalGain = segments.reduce(0) { partialResult, segment in
            guard let verticalDelta = segment.verticalDeltaMeters, verticalDelta > 0 else { return partialResult }
            return partialResult + verticalDelta
        }
        return SnowVerticalMetrics(
            totalVerticalDropMeters: verticalDrop,
            totalVerticalGainMeters: verticalGain,
            maxAltitudeMeters: altitudeValues.max(),
            minAltitudeMeters: altitudeValues.min(),
            maxSlopeAngleDegrees: nil
        )
    }
}
