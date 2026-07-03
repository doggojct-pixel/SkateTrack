// [協作區] Shared/Models/EstimatedRouteReviewOverlay.swift
// 用途：定義 b18-B review-only estimated route overlay artifact 的跨平台資料模型。
// 委派至：EstimatedRouteReviewOverlayBuilder 與 DEBUG-only review UI。

import Foundation

struct EstimatedRouteReviewOverlayRecord: Codable, Sendable, Equatable {
    let sourceDecisionTaskIdentifier: String
    let sessionIdentifier: String
    let sessionReviewRole: String?
    let gapIndex: Int
    let decisionState: EstimatedRouteDisplayDecisionState
    let reviewDisposition: String
    let gapDurationSeconds: TimeInterval
    let headingReliability: HeadingReliability
    let imuSampleCoverageRatio: Double
    let estimatedDisplacementMeters: Double
    let anchorClosureErrorMeters: Double?
    let closureErrorRatio: Double?
    let replayBlockingReason: DeadReckoningReplayBlockingReason
    let reviewArtifactOnly: Bool
    let routeGeometryIncluded: Bool
    let productionRouteMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let estimatedRouteDisplayEnabled: Bool
    let persistedOverlayApplied: Bool
    let userVisibleDisplayAllowed: Bool
    let blockingReasons: [String]
    let decisionReasons: [String]

    init(
        sourceDecisionTaskIdentifier: String,
        sessionIdentifier: String,
        sessionReviewRole: String?,
        gapIndex: Int,
        decisionState: EstimatedRouteDisplayDecisionState,
        reviewDisposition: String,
        gapDurationSeconds: TimeInterval,
        headingReliability: HeadingReliability,
        imuSampleCoverageRatio: Double,
        estimatedDisplacementMeters: Double,
        anchorClosureErrorMeters: Double?,
        closureErrorRatio: Double?,
        replayBlockingReason: DeadReckoningReplayBlockingReason,
        blockingReasons: [String],
        decisionReasons: [String]
    ) {
        self.sourceDecisionTaskIdentifier = sourceDecisionTaskIdentifier
        self.sessionIdentifier = sessionIdentifier
        self.sessionReviewRole = sessionReviewRole
        self.gapIndex = max(0, gapIndex)
        self.decisionState = decisionState
        self.reviewDisposition = reviewDisposition
        self.gapDurationSeconds = max(0, gapDurationSeconds)
        self.headingReliability = headingReliability
        self.imuSampleCoverageRatio = min(1, max(0, imuSampleCoverageRatio))
        self.estimatedDisplacementMeters = max(0, estimatedDisplacementMeters)
        self.anchorClosureErrorMeters = anchorClosureErrorMeters.map { max(0, $0) }
        self.closureErrorRatio = closureErrorRatio.map { max(0, $0.isFinite ? $0 : 0) }
        self.replayBlockingReason = replayBlockingReason
        self.reviewArtifactOnly = true
        self.routeGeometryIncluded = false
        self.productionRouteMutationApplied = false
        self.trustedMetricsMutationApplied = false
        self.estimatedRouteDisplayEnabled = false
        self.persistedOverlayApplied = false
        self.userVisibleDisplayAllowed = false
        self.blockingReasons = blockingReasons
        self.decisionReasons = decisionReasons
    }
}

struct EstimatedRouteReviewOverlay: Codable, Sendable, Equatable {
    let taskIdentifier: String
    let sourceTaskIdentifier: String
    let createdAt: Date
    let reviewOnly: Bool
    let exportedReviewArtifactOnly: Bool
    let routeGeometryIncluded: Bool
    let normalSessionMapMutationApplied: Bool
    let productionRouteMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let estimatedRouteDisplayEnabled: Bool
    let persistedOverlayApplied: Bool
    let userVisibleDisplayAllowed: Bool
    let productDecisionCheckpointRequired: Bool
    let records: [EstimatedRouteReviewOverlayRecord]

    init(
        taskIdentifier: String = "Task-030c-b18-B",
        sourceTaskIdentifier: String = "Task-030c-b18-A",
        createdAt: Date,
        records: [EstimatedRouteReviewOverlayRecord]
    ) {
        self.taskIdentifier = taskIdentifier
        self.sourceTaskIdentifier = sourceTaskIdentifier
        self.createdAt = createdAt
        self.reviewOnly = true
        self.exportedReviewArtifactOnly = true
        self.routeGeometryIncluded = false
        self.normalSessionMapMutationApplied = false
        self.productionRouteMutationApplied = false
        self.trustedMetricsMutationApplied = false
        self.estimatedRouteDisplayEnabled = false
        self.persistedOverlayApplied = false
        self.userVisibleDisplayAllowed = false
        self.productDecisionCheckpointRequired = true
        self.records = records
    }
}
