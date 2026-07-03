// [自主區] iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift
// 用途：依據 b18-B review overlay records 產出 b18-D 產品決策更新。
// 委派至：EstimatedRouteProductDecisionUpdate 與 b18-D release gate 文件。

import Foundation

enum EstimatedRouteProductDecisionUpdateBuilder {
    static let requiredRealSessionRoles = [
        "electricSkateboardCoreCandidate",
        "motorcycleControl",
        "motorcyclePressureTest",
        "surfskateShelteredHighRisk",
        "walkingLowSpeedTrap"
    ]

    static func makeUpdate(
        from overlay: EstimatedRouteReviewOverlay,
        createdAt: Date = Date()
    ) -> EstimatedRouteProductDecisionUpdate {
        let recordsByRole = Dictionary(grouping: overlay.records) { role(for: $0) }
        let summaries = recordsByRole.map { role, records in
            makeSessionSummary(role: role, records: records)
        }

        let blockingRoles = summaries
            .filter { $0.blockedRecordCount > 0 }
            .map(\.sessionReviewRole)
        let candidateRoles = summaries
            .filter { $0.hiddenCandidateRecordCount > 0 || $0.futureProductReviewRecordCount > 0 }
            .map(\.sessionReviewRole)
        let reviewOnlyRoles = summaries
            .filter { $0.reviewOnlyRecordCount > 0 }
            .map(\.sessionReviewRole)
        let coveredRoles = Set(summaries.map(\.sessionReviewRole))
        let requiredCovered = Set(requiredRealSessionRoles).isSubset(of: coveredRoles)

        return EstimatedRouteProductDecisionUpdate(
            createdAt: createdAt,
            reviewedSessionCount: summaries.count,
            requiredSessionRolesCovered: requiredCovered,
            requiredSessionRoles: requiredRealSessionRoles,
            blockingSessionRoles: blockingRoles,
            candidateSessionRoles: candidateRoles,
            reviewOnlySessionRoles: reviewOnlyRoles,
            sessionSummaries: summaries,
            summaryReasons: summaryReasons(summaries: summaries, requiredCovered: requiredCovered)
        )
    }

    private static func role(for record: EstimatedRouteReviewOverlayRecord) -> String {
        record.sessionReviewRole ?? record.sessionIdentifier
    }

    private static func makeSessionSummary(
        role: String,
        records: [EstimatedRouteReviewOverlayRecord]
    ) -> EstimatedRouteProductDecisionSessionSummary {
        let blockedCount = records.filter { $0.decisionState == .blocked }.count
        let hiddenCount = records.filter { $0.decisionState == .candidateButHidden }.count
        let reviewOnlyCount = records.filter { $0.decisionState == .reviewOnly }.count
        let futureReviewCount = records.filter { $0.decisionState == .eligibleForFutureProductReview }.count
        let maxGap = records.map(\.gapDurationSeconds).max() ?? 0
        let maxClosure = records.reduce(Double?.none) { partial, record in
            guard let closure = record.anchorClosureErrorMeters else { return partial }
            guard let current = partial else { return closure }
            return max(current, closure)
        }

        return EstimatedRouteProductDecisionSessionSummary(
            sessionReviewRole: role,
            recordCount: records.count,
            blockedRecordCount: blockedCount,
            hiddenCandidateRecordCount: hiddenCount,
            reviewOnlyRecordCount: reviewOnlyCount,
            futureProductReviewRecordCount: futureReviewCount,
            maximumGapDurationSeconds: maxGap,
            maximumAnchorClosureErrorMeters: maxClosure,
            decisionSummary: decisionSummary(
                role: role,
                blockedCount: blockedCount,
                hiddenCandidateCount: hiddenCount,
                futureReviewCount: futureReviewCount
            )
        )
    }

    private static func decisionSummary(
        role: String,
        blockedCount: Int,
        hiddenCandidateCount: Int,
        futureReviewCount: Int
    ) -> String {
        if blockedCount > 0 {
            return "keepDisabledBlocked:\(role)"
        }
        if hiddenCandidateCount > 0 || futureReviewCount > 0 {
            return "keepDisabledCandidateEvidenceOnly:\(role)"
        }
        return "keepDisabledReviewOnly:\(role)"
    }

    private static func summaryReasons(
        summaries: [EstimatedRouteProductDecisionSessionSummary],
        requiredCovered: Bool
    ) -> [String] {
        var reasons = [
            "generalUserEstimatedRouteDisplayRemainsDisabled",
            "debugReviewOnlyAfterB18D",
            "routeGeometryDisabled",
            "trustedMetricsMutationDisabled",
            "persistenceAndSchemaMutationDisabled"
        ]

        if summaries.contains(where: { $0.sessionReviewRole == "electricSkateboardCoreCandidate" }) {
            reasons.append("electricSkateboardCoreCandidateHasZeroUserVisibleEligibility")
        }
        if summaries.contains(where: { $0.sessionReviewRole == "walkingLowSpeedTrap" }) {
            reasons.append("walkingLowSpeedTrapRemainsBlocked")
        }
        if summaries.contains(where: { $0.sessionReviewRole == "surfskateShelteredHighRisk" }) {
            reasons.append("surfskateShelteredHighRiskRemainsBlocked")
        }
        if summaries.contains(where: { $0.sessionReviewRole == "motorcyclePressureTest" }) {
            reasons.append("motorcyclePressureTestRemainsBlocked")
        }
        if summaries.contains(where: { $0.sessionReviewRole == "motorcycleControl" }) {
            reasons.append("motorcycleControlIsLimitedCandidateEvidenceOnly")
        }
        if !requiredCovered {
            reasons.append("requiredRealSessionRolesNotFullyCovered")
        }

        return reasons
    }
}
