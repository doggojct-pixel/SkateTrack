// [協作區] Shared/Models/DeadReckoningReplayReviewPack.swift
// 用途：定義 b17-D real-session replay review pack 的跨平台資料模型。
// 委派至：DeadReckoningReplayReviewPackBuilder 與 product decision checkpoint。

import Foundation

enum DeadReckoningReplayReviewArtifactKind: String, Codable, Sendable, Equatable {
    case json
    case markdown
    case csv
}

struct DeadReckoningReplayReviewArtifact: Codable, Sendable, Equatable {
    let fileName: String
    let kind: DeadReckoningReplayReviewArtifactKind
    let contents: String

    init(fileName: String, kind: DeadReckoningReplayReviewArtifactKind, contents: String) {
        self.fileName = fileName
        self.kind = kind
        self.contents = contents
    }
}

struct DeadReckoningReplayReviewSessionSummary: Codable, Sendable, Equatable {
    let sessionIdentifier: String
    let totalGapCount: Int
    let replaySucceededGapCount: Int
    let blockedGapCount: Int
    let userVisibleEligibleGapCount: Int
    let reviewRecommendedGapCount: Int
    let maximumClosureErrorMeters: Double?
    let productDecisionCheckpointRequired: Bool
    let b18DisplayWorkBlockedUntilProductDecision: Bool

    init(
        sessionIdentifier: String,
        totalGapCount: Int,
        replaySucceededGapCount: Int,
        blockedGapCount: Int,
        userVisibleEligibleGapCount: Int,
        reviewRecommendedGapCount: Int,
        maximumClosureErrorMeters: Double?,
        productDecisionCheckpointRequired: Bool = true,
        b18DisplayWorkBlockedUntilProductDecision: Bool = true
    ) {
        self.sessionIdentifier = sessionIdentifier
        self.totalGapCount = max(0, totalGapCount)
        self.replaySucceededGapCount = max(0, replaySucceededGapCount)
        self.blockedGapCount = max(0, blockedGapCount)
        self.userVisibleEligibleGapCount = max(0, userVisibleEligibleGapCount)
        self.reviewRecommendedGapCount = max(0, reviewRecommendedGapCount)
        self.maximumClosureErrorMeters = maximumClosureErrorMeters.map { max(0, $0) }
        self.productDecisionCheckpointRequired = productDecisionCheckpointRequired
        self.b18DisplayWorkBlockedUntilProductDecision = b18DisplayWorkBlockedUntilProductDecision
    }
}

struct DeadReckoningReplayReviewGapRecord: Codable, Sendable, Equatable {
    let sessionIdentifier: String
    let gapIndex: Int
    let gapStartTimestamp: Date
    let gapEndTimestamp: Date
    let gapDurationSeconds: TimeInterval
    let replayBlockingReason: DeadReckoningReplayBlockingReason
    let estimateCount: Int
    let estimatedDisplacementMeters: Double
    let anchorClosureErrorMeters: Double?
    let closureErrorRatio: Double?
    let headingReliability: HeadingReliability
    let imuSampleCoverageRatio: Double
    let eligibleForUserVisibleEstimatedRoute: Bool
    let blockingReasons: [String]

    init(
        sessionIdentifier: String,
        gapIndex: Int,
        gapStartTimestamp: Date,
        gapEndTimestamp: Date,
        gapDurationSeconds: TimeInterval,
        replayBlockingReason: DeadReckoningReplayBlockingReason,
        estimateCount: Int,
        estimatedDisplacementMeters: Double,
        anchorClosureErrorMeters: Double?,
        closureErrorRatio: Double?,
        headingReliability: HeadingReliability,
        imuSampleCoverageRatio: Double,
        eligibleForUserVisibleEstimatedRoute: Bool,
        blockingReasons: [String]
    ) {
        self.sessionIdentifier = sessionIdentifier
        self.gapIndex = max(0, gapIndex)
        self.gapStartTimestamp = gapStartTimestamp
        self.gapEndTimestamp = gapEndTimestamp
        self.gapDurationSeconds = max(0, gapDurationSeconds)
        self.replayBlockingReason = replayBlockingReason
        self.estimateCount = max(0, estimateCount)
        self.estimatedDisplacementMeters = max(0, estimatedDisplacementMeters)
        self.anchorClosureErrorMeters = anchorClosureErrorMeters.map { max(0, $0) }
        self.closureErrorRatio = closureErrorRatio.map { max(0, $0.isFinite ? $0 : 0) }
        self.headingReliability = headingReliability
        self.imuSampleCoverageRatio = min(1, max(0, imuSampleCoverageRatio))
        self.eligibleForUserVisibleEstimatedRoute = eligibleForUserVisibleEstimatedRoute
        self.blockingReasons = blockingReasons
    }
}

struct DeadReckoningReplayReviewPack: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let taskIdentifier: String
    let archiveFileName: String
    let createdAt: Date
    let replayReviewOnly: Bool
    let productionRouteMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let estimatedRouteDisplayEnabled: Bool
    let productDecisionCheckpointRequired: Bool
    let b18DisplayWorkBlockedUntilProductDecision: Bool
    let sessionSummaries: [DeadReckoningReplayReviewSessionSummary]
    let gapRecords: [DeadReckoningReplayReviewGapRecord]

    init(
        schemaVersion: Int = 1,
        taskIdentifier: String = "Task-030c-b17-D",
        archiveFileName: String = "Task030c_b17D_ReplayReviewPack.zip",
        createdAt: Date,
        sessionSummaries: [DeadReckoningReplayReviewSessionSummary],
        gapRecords: [DeadReckoningReplayReviewGapRecord]
    ) {
        self.schemaVersion = max(1, schemaVersion)
        self.taskIdentifier = taskIdentifier
        self.archiveFileName = archiveFileName
        self.createdAt = createdAt
        self.replayReviewOnly = true
        self.productionRouteMutationApplied = false
        self.trustedMetricsMutationApplied = false
        self.estimatedRouteDisplayEnabled = false
        self.productDecisionCheckpointRequired = true
        self.b18DisplayWorkBlockedUntilProductDecision = true
        self.sessionSummaries = sessionSummaries
        self.gapRecords = gapRecords
    }
}
