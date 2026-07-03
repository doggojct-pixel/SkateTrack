// [協作區] Shared/Models/EstimatedRouteProductDecisionUpdate.swift
// 用途：定義 b18-D real-session recheck 後的 estimated route 產品決策更新模型。
// 委派至：EstimatedRouteProductDecisionUpdateBuilder 與 b18 product decision checkpoint 文件。

import Foundation

enum EstimatedRouteProductDecisionOutcome: String, Codable, Sendable, Equatable, CaseIterable {
    case keepDisabled
    case continueReviewOnly
    case candidateForFutureControlledExperiment
}

struct EstimatedRouteProductDecisionSessionSummary: Codable, Sendable, Equatable {
    let sessionReviewRole: String
    let recordCount: Int
    let blockedRecordCount: Int
    let hiddenCandidateRecordCount: Int
    let reviewOnlyRecordCount: Int
    let futureProductReviewRecordCount: Int
    let maximumGapDurationSeconds: TimeInterval
    let maximumAnchorClosureErrorMeters: Double?
    let decisionSummary: String
    let userVisibleDisplayAllowed: Bool
    let routeGeometryIncluded: Bool
    let estimatedRouteDisplayEnabled: Bool

    init(
        sessionReviewRole: String,
        recordCount: Int,
        blockedRecordCount: Int,
        hiddenCandidateRecordCount: Int,
        reviewOnlyRecordCount: Int,
        futureProductReviewRecordCount: Int,
        maximumGapDurationSeconds: TimeInterval,
        maximumAnchorClosureErrorMeters: Double?,
        decisionSummary: String
    ) {
        self.sessionReviewRole = sessionReviewRole
        self.recordCount = max(0, recordCount)
        self.blockedRecordCount = max(0, blockedRecordCount)
        self.hiddenCandidateRecordCount = max(0, hiddenCandidateRecordCount)
        self.reviewOnlyRecordCount = max(0, reviewOnlyRecordCount)
        self.futureProductReviewRecordCount = max(0, futureProductReviewRecordCount)
        self.maximumGapDurationSeconds = max(0, maximumGapDurationSeconds)
        self.maximumAnchorClosureErrorMeters = maximumAnchorClosureErrorMeters.map { max(0, $0) }
        self.decisionSummary = decisionSummary
        self.userVisibleDisplayAllowed = false
        self.routeGeometryIncluded = false
        self.estimatedRouteDisplayEnabled = false
    }
}

struct EstimatedRouteProductDecisionUpdate: Codable, Sendable, Equatable {
    let taskIdentifier: String
    let sourceTaskIdentifier: String
    let createdAt: Date
    let outcome: EstimatedRouteProductDecisionOutcome
    let productDecisionCheckpointRequired: Bool
    let reviewedSessionCount: Int
    let requiredSessionRolesCovered: Bool
    let requiredSessionRoles: [String]
    let blockingSessionRoles: [String]
    let candidateSessionRoles: [String]
    let reviewOnlySessionRoles: [String]
    let sessionSummaries: [EstimatedRouteProductDecisionSessionSummary]
    let summaryReasons: [String]
    let generalUserEstimatedRouteDisplayAllowed: Bool
    let debugReviewOnly: Bool
    let routeGeometryIncluded: Bool
    let normalSessionMapMutationApplied: Bool
    let productionRouteMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let estimatedRouteDisplayEnabled: Bool
    let persistedDecisionApplied: Bool
    let userVisibleDisplayAllowed: Bool

    init(
        taskIdentifier: String = "Task-030c-b18-D",
        sourceTaskIdentifier: String = "Task-030c-b18-C",
        createdAt: Date,
        reviewedSessionCount: Int,
        requiredSessionRolesCovered: Bool,
        requiredSessionRoles: [String],
        blockingSessionRoles: [String],
        candidateSessionRoles: [String],
        reviewOnlySessionRoles: [String],
        sessionSummaries: [EstimatedRouteProductDecisionSessionSummary],
        summaryReasons: [String]
    ) {
        self.taskIdentifier = taskIdentifier
        self.sourceTaskIdentifier = sourceTaskIdentifier
        self.createdAt = createdAt
        self.outcome = .keepDisabled
        self.productDecisionCheckpointRequired = true
        self.reviewedSessionCount = max(0, reviewedSessionCount)
        self.requiredSessionRolesCovered = requiredSessionRolesCovered
        self.requiredSessionRoles = requiredSessionRoles.sorted()
        self.blockingSessionRoles = blockingSessionRoles.sorted()
        self.candidateSessionRoles = candidateSessionRoles.sorted()
        self.reviewOnlySessionRoles = reviewOnlySessionRoles.sorted()
        self.sessionSummaries = sessionSummaries.sorted { $0.sessionReviewRole < $1.sessionReviewRole }
        self.summaryReasons = summaryReasons
        self.generalUserEstimatedRouteDisplayAllowed = false
        self.debugReviewOnly = true
        self.routeGeometryIncluded = false
        self.normalSessionMapMutationApplied = false
        self.productionRouteMutationApplied = false
        self.trustedMetricsMutationApplied = false
        self.estimatedRouteDisplayEnabled = false
        self.persistedDecisionApplied = false
        self.userVisibleDisplayAllowed = false
    }
}
