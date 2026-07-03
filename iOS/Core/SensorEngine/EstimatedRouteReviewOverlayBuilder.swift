// [自主區] iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift
// 用途：將 b18-A in-memory display decisions 轉成 b18-B review-only overlay artifact。
// 委派至：EstimatedRouteReviewOverlay 與 DEBUG-only review UI。

import Foundation

enum EstimatedRouteReviewOverlayBuilder {
    static func makeOverlay(
        from pack: DeadReckoningReplayReviewPack,
        sessionReviewRoles: [String: String] = [:],
        createdAt: Date = Date()
    ) -> EstimatedRouteReviewOverlay {
        let decisions = EstimatedRouteDisplayGate.makeDecisions(for: pack)
        let records = decisions.map { decision in
            makeRecord(
                from: decision,
                sessionReviewRole: sessionReviewRoles[decision.sessionIdentifier]
            )
        }

        return EstimatedRouteReviewOverlay(createdAt: createdAt, records: records)
    }

    static func makeRecord(
        from decision: EstimatedRouteDisplayDecision,
        sessionReviewRole: String? = nil
    ) -> EstimatedRouteReviewOverlayRecord {
        EstimatedRouteReviewOverlayRecord(
            sourceDecisionTaskIdentifier: decision.taskIdentifier,
            sessionIdentifier: decision.sessionIdentifier,
            sessionReviewRole: sessionReviewRole,
            gapIndex: decision.gapIndex,
            decisionState: decision.state,
            reviewDisposition: reviewDisposition(for: decision.state),
            gapDurationSeconds: decision.gapDurationSeconds,
            headingReliability: decision.headingReliability,
            imuSampleCoverageRatio: decision.imuSampleCoverageRatio,
            estimatedDisplacementMeters: decision.estimatedDisplacementMeters,
            anchorClosureErrorMeters: decision.anchorClosureErrorMeters,
            closureErrorRatio: decision.closureErrorRatio,
            replayBlockingReason: decision.replayBlockingReason,
            blockingReasons: decision.blockingReasons,
            decisionReasons: decision.decisionReasons
        )
    }

    private static func reviewDisposition(for state: EstimatedRouteDisplayDecisionState) -> String {
        switch state {
        case .blocked:
            return "blockedRegressionTrap"
        case .reviewOnly:
            return "reviewOnlyEvidence"
        case .candidateButHidden:
            return "candidateButHiddenByProductDecision"
        case .eligibleForFutureProductReview:
            return "futureProductReviewOnly"
        }
    }
}
