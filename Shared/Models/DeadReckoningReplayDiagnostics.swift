// [協作區] Shared/Models/DeadReckoningReplayDiagnostics.swift
// 用途：定義 b17-B replay-only IMU dead-reckoning estimate 與診斷輸出模型。
// 委派至：DeadReckoningEngine 與後續 b17-C closure scoring。

import Foundation

enum DeadReckoningEstimateSource: String, Codable, Sendable, Equatable {
    case replayOnlyIMU
    case replayOnlyIMUHeadingUnavailable
    case blocked
}

enum DeadReckoningConfidence: String, Codable, Sendable, Equatable {
    case high
    case moderate
    case low
    case blocked
}

enum DeadReckoningReplayBlockingReason: String, Codable, Sendable, Equatable {
    case noBlockingReason
    case missingPreGapAnchor
    case missingPostGapAnchor
    case gapTooLong
    case insufficientIMUSamples
    case nonFiniteEstimate
    case replayOnlyNotProduction
}

struct DeadReckoningReplayEstimate: Codable, Sendable, Equatable {
    let timestamp: Date
    let timestampMillisecondsSince1970: Int64
    let localEastMeters: Double
    let localNorthMeters: Double
    let estimatedCoordinate: GeoCoordinate?
    let estimatedHorizontalAccuracyMeters: Double
    let source: DeadReckoningEstimateSource
    let confidence: DeadReckoningConfidence

    init(
        timestamp: Date,
        localEastMeters: Double,
        localNorthMeters: Double,
        estimatedCoordinate: GeoCoordinate?,
        estimatedHorizontalAccuracyMeters: Double,
        source: DeadReckoningEstimateSource,
        confidence: DeadReckoningConfidence
    ) {
        self.timestamp = timestamp
        self.timestampMillisecondsSince1970 = Int64((timestamp.timeIntervalSince1970 * 1_000).rounded())
        self.localEastMeters = localEastMeters
        self.localNorthMeters = localNorthMeters
        self.estimatedCoordinate = estimatedCoordinate
        self.estimatedHorizontalAccuracyMeters = max(0, estimatedHorizontalAccuracyMeters)
        self.source = source
        self.confidence = confidence
    }
}

struct DeadReckoningReplayDiagnostics: Codable, Sendable, Equatable {
    let gapStartTimestamp: Date
    let gapEndTimestamp: Date
    let gapDurationSeconds: TimeInterval
    let replayOnly: Bool
    let productionRouteMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let blockingReason: DeadReckoningReplayBlockingReason
    let preGapAnchorCoordinate: GeoCoordinate?
    let postGapAnchorCoordinate: GeoCoordinate?
    let anchorClosureErrorMeters: Double?
    let estimates: [DeadReckoningReplayEstimate]

    init(
        gapStartTimestamp: Date,
        gapEndTimestamp: Date,
        gapDurationSeconds: TimeInterval,
        blockingReason: DeadReckoningReplayBlockingReason = .noBlockingReason,
        preGapAnchorCoordinate: GeoCoordinate? = nil,
        postGapAnchorCoordinate: GeoCoordinate? = nil,
        anchorClosureErrorMeters: Double? = nil,
        estimates: [DeadReckoningReplayEstimate] = []
    ) {
        self.gapStartTimestamp = gapStartTimestamp
        self.gapEndTimestamp = gapEndTimestamp
        self.gapDurationSeconds = max(0, gapDurationSeconds)
        self.replayOnly = true
        self.productionRouteMutationApplied = false
        self.trustedMetricsMutationApplied = false
        self.blockingReason = blockingReason
        self.preGapAnchorCoordinate = preGapAnchorCoordinate
        self.postGapAnchorCoordinate = postGapAnchorCoordinate
        self.anchorClosureErrorMeters = anchorClosureErrorMeters.map { max(0, $0) }
        self.estimates = estimates
    }
}
