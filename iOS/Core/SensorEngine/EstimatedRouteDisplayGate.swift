// [自主區] iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift
// 用途：以 b18-A in-memory gate 將 b17-D replay review gaps 轉成安全封鎖的 display decision。
// 委派至：EstimatedRouteDisplayDecision 與 DEBUG-only review UI。

import Foundation

enum EstimatedRouteDisplayGatePolicy {
    static let maximumCandidateGapDurationSeconds: TimeInterval = 6
    static let maximumReviewOnlyGapDurationSeconds: TimeInterval = 30
    static let maximumCandidateClosureErrorMeters: Double = 8
    static let maximumCandidateClosureErrorRatio: Double = 0.25
    static let minimumCandidateIMUSampleCoverageRatio: Double = 0.80

    static func acceptsCandidateHeadingReliability(_ reliability: HeadingReliability) -> Bool {
        reliability == .high || reliability == .moderate
    }
}

enum EstimatedRouteDisplayGate {
    static func makeDecision(for record: DeadReckoningReplayReviewGapRecord) -> EstimatedRouteDisplayDecision {
        let hardBlockingReasons = hardBlockingReasons(for: record)
        let state = decisionState(for: record, hardBlockingReasons: hardBlockingReasons)
        let decisionReasons = decisionReasons(for: record, state: state, hardBlockingReasons: hardBlockingReasons)
        let combinedBlockingReasons = Array(Set(record.blockingReasons + hardBlockingReasons)).sorted()

        return EstimatedRouteDisplayDecision(
            sessionIdentifier: record.sessionIdentifier,
            gapIndex: record.gapIndex,
            state: state,
            gapDurationSeconds: record.gapDurationSeconds,
            imuSampleCoverageRatio: record.imuSampleCoverageRatio,
            headingReliability: record.headingReliability,
            estimatedDisplacementMeters: record.estimatedDisplacementMeters,
            anchorClosureErrorMeters: record.anchorClosureErrorMeters,
            closureErrorRatio: record.closureErrorRatio,
            replayBlockingReason: record.replayBlockingReason,
            blockingReasons: combinedBlockingReasons,
            decisionReasons: decisionReasons
        )
    }

    static func makeDecisions(for pack: DeadReckoningReplayReviewPack) -> [EstimatedRouteDisplayDecision] {
        pack.gapRecords.map(makeDecision(for:))
    }

    private static func decisionState(
        for record: DeadReckoningReplayReviewGapRecord,
        hardBlockingReasons: [String]
    ) -> EstimatedRouteDisplayDecisionState {
        guard hardBlockingReasons.isEmpty else { return .blocked }

        if passesCandidateGate(record) {
            return .candidateButHidden
        }

        if passesFutureProductReviewGate(record) {
            return .eligibleForFutureProductReview
        }

        return .reviewOnly
    }

    private static func passesCandidateGate(_ record: DeadReckoningReplayReviewGapRecord) -> Bool {
        record.gapDurationSeconds <= EstimatedRouteDisplayGatePolicy.maximumCandidateGapDurationSeconds
            && passesCommonQualityGate(record)
    }

    private static func passesFutureProductReviewGate(_ record: DeadReckoningReplayReviewGapRecord) -> Bool {
        record.gapDurationSeconds <= EstimatedRouteDisplayGatePolicy.maximumReviewOnlyGapDurationSeconds
            && passesCommonQualityGate(record)
    }

    private static func passesCommonQualityGate(_ record: DeadReckoningReplayReviewGapRecord) -> Bool {
        guard record.replayBlockingReason == .noBlockingReason else { return false }
        guard record.blockingReasons.isEmpty else { return false }
        guard EstimatedRouteDisplayGatePolicy.acceptsCandidateHeadingReliability(record.headingReliability) else { return false }
        guard record.imuSampleCoverageRatio >= EstimatedRouteDisplayGatePolicy.minimumCandidateIMUSampleCoverageRatio else { return false }
        guard let closureErrorMeters = record.anchorClosureErrorMeters else { return false }
        guard closureErrorMeters <= EstimatedRouteDisplayGatePolicy.maximumCandidateClosureErrorMeters else { return false }
        guard let closureErrorRatio = record.closureErrorRatio else { return false }
        return closureErrorRatio <= EstimatedRouteDisplayGatePolicy.maximumCandidateClosureErrorRatio
    }

    private static func hardBlockingReasons(for record: DeadReckoningReplayReviewGapRecord) -> [String] {
        var reasons = record.blockingReasons

        if record.replayBlockingReason != .noBlockingReason {
            reasons.append("replayBlockingReason:\(record.replayBlockingReason.rawValue)")
        }
        if record.gapDurationSeconds > EstimatedRouteDisplayGatePolicy.maximumReviewOnlyGapDurationSeconds {
            reasons.append("gapDurationExceededReviewOnlyLimit")
        }
        if !EstimatedRouteDisplayGatePolicy.acceptsCandidateHeadingReliability(record.headingReliability) {
            reasons.append("headingReliabilityInsufficient")
        }
        if record.imuSampleCoverageRatio < EstimatedRouteDisplayGatePolicy.minimumCandidateIMUSampleCoverageRatio {
            reasons.append("imuSampleCoverageInsufficient")
        }
        if record.anchorClosureErrorMeters == nil || record.closureErrorRatio == nil {
            reasons.append("closureEvidenceMissing")
        } else {
            if record.anchorClosureErrorMeters ?? 0 > EstimatedRouteDisplayGatePolicy.maximumCandidateClosureErrorMeters {
                reasons.append("closureErrorExceededCandidateLimit")
            }
            if record.closureErrorRatio ?? 0 > EstimatedRouteDisplayGatePolicy.maximumCandidateClosureErrorRatio {
                reasons.append("closureErrorRatioExceededCandidateLimit")
            }
        }

        return Array(Set(reasons)).sorted()
    }

    private static func decisionReasons(
        for record: DeadReckoningReplayReviewGapRecord,
        state: EstimatedRouteDisplayDecisionState,
        hardBlockingReasons: [String]
    ) -> [String] {
        switch state {
        case .blocked:
            return ["blockedBySafetyGate"] + hardBlockingReasons
        case .candidateButHidden:
            return [
                "passesSixSecondCandidateGate",
                "hiddenByB18ProductDecision",
                "userVisibleDisplayDisabled"
            ]
        case .eligibleForFutureProductReview:
            return [
                "passesThirtySecondReviewGate",
                "exceedsSixSecondCandidateGate",
                "futureProductReviewOnly"
            ]
        case .reviewOnly:
            return [
                "reviewOnlyEvidence",
                "doesNotPassCandidateGate",
                "userVisibleDisplayDisabled",
                "gapDuration:\(Int(record.gapDurationSeconds.rounded()))s"
            ]
        }
    }
}
