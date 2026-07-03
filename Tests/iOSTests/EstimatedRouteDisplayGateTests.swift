// [自主區] Tests/iOSTests/EstimatedRouteDisplayGateTests.swift
// 用途：驗證 b18-A in-memory estimated route display gate、named constants 與 safety boundaries。
// 委派至：EstimatedRouteDisplayGate 與 b18 product decision checkpoint。

import XCTest
@testable import SkateTrack_iOS

final class EstimatedRouteDisplayGateTests: XCTestCase {
    func testShortHighQualityGapBecomesCandidateButHidden() {
        let decision = EstimatedRouteDisplayGate.makeDecision(for: makeRecord(gapDurationSeconds: 5))

        XCTAssertEqual(decision.taskIdentifier, "Task-030c-b18-A")
        XCTAssertEqual(decision.sourceTaskIdentifier, "Task-030c-b17-D")
        XCTAssertEqual(decision.state, .candidateButHidden)
        XCTAssertTrue(decision.inMemoryOnly)
        XCTAssertFalse(decision.productionRouteMutationApplied)
        XCTAssertFalse(decision.trustedMetricsMutationApplied)
        XCTAssertFalse(decision.estimatedRouteDisplayEnabled)
        XCTAssertFalse(decision.persistedDecisionApplied)
        XCTAssertFalse(decision.userVisibleDisplayAllowed)
        XCTAssertTrue(decision.productDecisionCheckpointRequired)
        XCTAssertTrue(decision.b18DisplayWorkBlockedUntilProductDecision)
    }

    func testThirtySecondHighQualityGapIsFutureProductReviewOnly() {
        let decision = EstimatedRouteDisplayGate.makeDecision(for: makeRecord(gapDurationSeconds: 20))

        XCTAssertEqual(decision.state, .eligibleForFutureProductReview)
        XCTAssertTrue(decision.decisionReasons.contains("passesThirtySecondReviewGate"))
        XCTAssertTrue(decision.decisionReasons.contains("futureProductReviewOnly"))
        XCTAssertFalse(decision.userVisibleDisplayAllowed)
    }

    func testLongGapIsBlockedEvenWhenOtherEvidenceLooksGood() {
        let decision = EstimatedRouteDisplayGate.makeDecision(for: makeRecord(gapDurationSeconds: 41.5))

        XCTAssertEqual(decision.state, .blocked)
        XCTAssertTrue(decision.blockingReasons.contains("gapDurationExceededReviewOnlyLimit"))
        XCTAssertFalse(decision.estimatedRouteDisplayEnabled)
    }

    func testLargeClosureErrorIsBlockedForElectricSkateboardCoreCandidate() {
        let decision = EstimatedRouteDisplayGate.makeDecision(for: makeRecord(
            sessionIdentifier: "20260701-204949",
            gapDurationSeconds: 5,
            anchorClosureErrorMeters: 309.8,
            closureErrorRatio: 1.4
        ))

        XCTAssertEqual(decision.state, .blocked)
        XCTAssertTrue(decision.blockingReasons.contains("closureErrorExceededCandidateLimit"))
        XCTAssertTrue(decision.blockingReasons.contains("closureErrorRatioExceededCandidateLimit"))
    }

    func testWalkingLowSpeedTrapWithPoorHeadingIsBlocked() {
        let decision = EstimatedRouteDisplayGate.makeDecision(for: makeRecord(
            sessionIdentifier: "20260701-204705",
            headingReliability: .poor
        ))

        XCTAssertEqual(decision.state, .blocked)
        XCTAssertTrue(decision.blockingReasons.contains("headingReliabilityInsufficient"))
    }

    func testPolicyUsesTwoTierSixSecondAndThirtySecondGates() {
        XCTAssertEqual(EstimatedRouteDisplayGatePolicy.maximumCandidateGapDurationSeconds, 6)
        XCTAssertEqual(EstimatedRouteDisplayGatePolicy.maximumReviewOnlyGapDurationSeconds, 30)
        XCTAssertEqual(EstimatedRouteDisplayGatePolicy.maximumCandidateClosureErrorMeters, 8)
        XCTAssertEqual(EstimatedRouteDisplayGatePolicy.maximumCandidateClosureErrorRatio, 0.25)
        XCTAssertEqual(EstimatedRouteDisplayGatePolicy.minimumCandidateIMUSampleCoverageRatio, 0.80)
        XCTAssertTrue(EstimatedRouteDisplayGatePolicy.acceptsCandidateHeadingReliability(.high))
        XCTAssertTrue(EstimatedRouteDisplayGatePolicy.acceptsCandidateHeadingReliability(.moderate))
        XCTAssertFalse(EstimatedRouteDisplayGatePolicy.acceptsCandidateHeadingReliability(.poor))
    }

    private func makeRecord(
        sessionIdentifier: String = "review-session",
        gapDurationSeconds: TimeInterval = 5,
        replayBlockingReason: DeadReckoningReplayBlockingReason = .noBlockingReason,
        anchorClosureErrorMeters: Double? = 2,
        closureErrorRatio: Double? = 0.1,
        headingReliability: HeadingReliability = .high,
        imuSampleCoverageRatio: Double = 0.9,
        blockingReasons: [String] = []
    ) -> DeadReckoningReplayReviewGapRecord {
        DeadReckoningReplayReviewGapRecord(
            sessionIdentifier: sessionIdentifier,
            gapIndex: 0,
            gapStartTimestamp: Date(timeIntervalSince1970: 1_000),
            gapEndTimestamp: Date(timeIntervalSince1970: 1_000 + gapDurationSeconds),
            gapDurationSeconds: gapDurationSeconds,
            replayBlockingReason: replayBlockingReason,
            estimateCount: 3,
            estimatedDisplacementMeters: 12,
            anchorClosureErrorMeters: anchorClosureErrorMeters,
            closureErrorRatio: closureErrorRatio,
            headingReliability: headingReliability,
            imuSampleCoverageRatio: imuSampleCoverageRatio,
            eligibleForUserVisibleEstimatedRoute: false,
            blockingReasons: blockingReasons
        )
    }
}
