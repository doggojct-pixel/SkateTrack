// [協作區] Shared/Models/DeadReckoningClosureDiagnostics.swift
// 用途：定義 b17-C replay-only IMU closure error confidence scoring output model。
// 委派至：DeadReckoningClosureScorer 與 b17-D real-session replay review pack。

import Foundation

struct DeadReckoningClosureDiagnostics: Codable, Sendable, Equatable {
    let gapDurationSeconds: TimeInterval
    let estimatedDistanceMeters: Double
    let closureErrorMeters: Double
    let closureErrorRatio: Double
    let headingReliability: HeadingReliability
    let imuSampleCoverageRatio: Double
    let eligibleForUserVisibleEstimatedRoute: Bool
    let blockingReasons: [String]

    init(
        gapDurationSeconds: TimeInterval,
        estimatedDistanceMeters: Double,
        closureErrorMeters: Double,
        closureErrorRatio: Double,
        headingReliability: HeadingReliability,
        imuSampleCoverageRatio: Double,
        eligibleForUserVisibleEstimatedRoute: Bool,
        blockingReasons: [String]
    ) {
        self.gapDurationSeconds = max(0, gapDurationSeconds)
        self.estimatedDistanceMeters = max(0, estimatedDistanceMeters)
        self.closureErrorMeters = max(0, closureErrorMeters)
        self.closureErrorRatio = max(0, closureErrorRatio.isFinite ? closureErrorRatio : 0)
        self.headingReliability = headingReliability
        self.imuSampleCoverageRatio = min(1, max(0, imuSampleCoverageRatio))
        self.eligibleForUserVisibleEstimatedRoute = eligibleForUserVisibleEstimatedRoute
        self.blockingReasons = blockingReasons
    }
}
