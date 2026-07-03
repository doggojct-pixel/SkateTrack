// [協作區] Shared/Models/EstimatedRouteDisplayDecision.swift
// 用途：定義 b18-A in-memory estimated route display decision 的跨平台資料模型。
// 委派至：EstimatedRouteDisplayGate 與 b18 product decision checkpoint。

import Foundation

enum EstimatedRouteDisplayDecisionState: String, Codable, Sendable, Equatable, CaseIterable {
    case blocked
    case reviewOnly
    case candidateButHidden
    case eligibleForFutureProductReview
}

struct EstimatedRouteDisplayDecision: Codable, Sendable, Equatable {
    let taskIdentifier: String
    let sourceTaskIdentifier: String
    let sessionIdentifier: String
    let gapIndex: Int
    let state: EstimatedRouteDisplayDecisionState
    let gapDurationSeconds: TimeInterval
    let imuSampleCoverageRatio: Double
    let headingReliability: HeadingReliability
    let estimatedDisplacementMeters: Double
    let anchorClosureErrorMeters: Double?
    let closureErrorRatio: Double?
    let replayBlockingReason: DeadReckoningReplayBlockingReason
    let productDecisionCheckpointRequired: Bool
    let b18DisplayWorkBlockedUntilProductDecision: Bool
    let inMemoryOnly: Bool
    let productionRouteMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let estimatedRouteDisplayEnabled: Bool
    let persistedDecisionApplied: Bool
    let userVisibleDisplayAllowed: Bool
    let blockingReasons: [String]
    let decisionReasons: [String]

    init(
        taskIdentifier: String = "Task-030c-b18-A",
        sourceTaskIdentifier: String = "Task-030c-b17-D",
        sessionIdentifier: String,
        gapIndex: Int,
        state: EstimatedRouteDisplayDecisionState,
        gapDurationSeconds: TimeInterval,
        imuSampleCoverageRatio: Double,
        headingReliability: HeadingReliability,
        estimatedDisplacementMeters: Double,
        anchorClosureErrorMeters: Double?,
        closureErrorRatio: Double?,
        replayBlockingReason: DeadReckoningReplayBlockingReason,
        blockingReasons: [String],
        decisionReasons: [String]
    ) {
        self.taskIdentifier = taskIdentifier
        self.sourceTaskIdentifier = sourceTaskIdentifier
        self.sessionIdentifier = sessionIdentifier
        self.gapIndex = max(0, gapIndex)
        self.state = state
        self.gapDurationSeconds = max(0, gapDurationSeconds)
        self.imuSampleCoverageRatio = min(1, max(0, imuSampleCoverageRatio))
        self.headingReliability = headingReliability
        self.estimatedDisplacementMeters = max(0, estimatedDisplacementMeters)
        self.anchorClosureErrorMeters = anchorClosureErrorMeters.map { max(0, $0) }
        self.closureErrorRatio = closureErrorRatio.map { max(0, $0.isFinite ? $0 : 0) }
        self.replayBlockingReason = replayBlockingReason
        self.productDecisionCheckpointRequired = true
        self.b18DisplayWorkBlockedUntilProductDecision = true
        self.inMemoryOnly = true
        self.productionRouteMutationApplied = false
        self.trustedMetricsMutationApplied = false
        self.estimatedRouteDisplayEnabled = false
        self.persistedDecisionApplied = false
        self.userVisibleDisplayAllowed = false
        self.blockingReasons = blockingReasons
        self.decisionReasons = decisionReasons
    }
}
