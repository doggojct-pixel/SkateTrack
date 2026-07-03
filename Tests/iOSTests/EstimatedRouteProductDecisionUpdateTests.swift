// [自主區] Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift
// 用途：驗證 b18-D real-session recheck 產品決策仍維持 estimated route display 關閉。
// 委派至：EstimatedRouteProductDecisionUpdateBuilder 與 b18-D release gate 文件。

import XCTest
@testable import SkateTrack_iOS

final class EstimatedRouteProductDecisionUpdateTests: XCTestCase {
    func testB18DUpdateKeepsGeneralUserEstimatedRouteDisplayDisabled() {
        let update = makeDecisionUpdate()

        XCTAssertEqual(update.taskIdentifier, "Task-030c-b18-D")
        XCTAssertEqual(update.sourceTaskIdentifier, "Task-030c-b18-C")
        XCTAssertEqual(update.outcome, .keepDisabled)
        XCTAssertTrue(update.productDecisionCheckpointRequired)
        XCTAssertTrue(update.debugReviewOnly)
        XCTAssertFalse(update.generalUserEstimatedRouteDisplayAllowed)
        XCTAssertFalse(update.routeGeometryIncluded)
        XCTAssertFalse(update.normalSessionMapMutationApplied)
        XCTAssertFalse(update.productionRouteMutationApplied)
        XCTAssertFalse(update.trustedMetricsMutationApplied)
        XCTAssertFalse(update.estimatedRouteDisplayEnabled)
        XCTAssertFalse(update.persistedDecisionApplied)
        XCTAssertFalse(update.userVisibleDisplayAllowed)
    }

    func testFiveRealSessionRolesAreRepresentedWithoutRequiringNewSessions() {
        let update = makeDecisionUpdate()

        XCTAssertEqual(update.reviewedSessionCount, 5)
        XCTAssertTrue(update.requiredSessionRolesCovered)
        XCTAssertEqual(Set(update.requiredSessionRoles), Set([
            "electricSkateboardCoreCandidate",
            "motorcycleControl",
            "motorcyclePressureTest",
            "surfskateShelteredHighRisk",
            "walkingLowSpeedTrap"
        ]))
        XCTAssertEqual(Set(update.sessionSummaries.map(\.sessionReviewRole)), Set(update.requiredSessionRoles))
    }

    func testRegressionTrapRolesRemainBlockedOrDecisionOnly() throws {
        let update = makeDecisionUpdate()

        XCTAssertTrue(update.blockingSessionRoles.contains("electricSkateboardCoreCandidate"))
        XCTAssertTrue(update.blockingSessionRoles.contains("walkingLowSpeedTrap"))
        XCTAssertTrue(update.blockingSessionRoles.contains("surfskateShelteredHighRisk"))
        XCTAssertTrue(update.blockingSessionRoles.contains("motorcyclePressureTest"))
        XCTAssertFalse(update.blockingSessionRoles.contains("motorcycleControl"))
        XCTAssertTrue(update.candidateSessionRoles.contains("motorcycleControl"))
        XCTAssertFalse(update.generalUserEstimatedRouteDisplayAllowed)

        let electricSummary = try XCTUnwrap(
            update.sessionSummaries.first { $0.sessionReviewRole == "electricSkateboardCoreCandidate" }
        )
        XCTAssertGreaterThan(electricSummary.blockedRecordCount, 0)
        XCTAssertFalse(electricSummary.userVisibleDisplayAllowed)
        XCTAssertFalse(electricSummary.routeGeometryIncluded)
    }

    func testSummaryReasonsRecordB18DProductDecision() {
        let update = makeDecisionUpdate()

        XCTAssertTrue(update.summaryReasons.contains("generalUserEstimatedRouteDisplayRemainsDisabled"))
        XCTAssertTrue(update.summaryReasons.contains("electricSkateboardCoreCandidateHasZeroUserVisibleEligibility"))
        XCTAssertTrue(update.summaryReasons.contains("walkingLowSpeedTrapRemainsBlocked"))
        XCTAssertTrue(update.summaryReasons.contains("surfskateShelteredHighRiskRemainsBlocked"))
        XCTAssertTrue(update.summaryReasons.contains("motorcyclePressureTestRemainsBlocked"))
        XCTAssertTrue(update.summaryReasons.contains("motorcycleControlIsLimitedCandidateEvidenceOnly"))
        XCTAssertFalse(update.summaryReasons.contains("requiredRealSessionRolesNotFullyCovered"))
    }

    private func makeDecisionUpdate() -> EstimatedRouteProductDecisionUpdate {
        EstimatedRouteProductDecisionUpdateBuilder.makeUpdate(
            from: makeOverlayWithRoles(),
            createdAt: Date(timeIntervalSince1970: 3_000)
        )
    }

    private func makeOverlayWithRoles() -> EstimatedRouteReviewOverlay {
        EstimatedRouteReviewOverlayBuilder.makeOverlay(
            from: makeFiveSessionReviewPack(),
            sessionReviewRoles: [
                "20260629-131547": "motorcyclePressureTest",
                "20260629-132410": "motorcycleControl",
                "20260701-192842": "surfskateShelteredHighRisk",
                "20260701-204705": "walkingLowSpeedTrap",
                "20260701-204949": "electricSkateboardCoreCandidate"
            ],
            createdAt: Date(timeIntervalSince1970: 2_000)
        )
    }

    private func makeFiveSessionReviewPack() -> DeadReckoningReplayReviewPack {
        DeadReckoningReplayReviewPack(
            createdAt: Date(timeIntervalSince1970: 1_000),
            sessionSummaries: [],
            gapRecords: [
                makeRecord(sessionIdentifier: "20260629-131547", gapDurationSeconds: 49, closureError: 8_222.8),
                makeRecord(sessionIdentifier: "20260629-132410", gapDurationSeconds: 5, closureError: 2, ratio: 0.1),
                makeRecord(sessionIdentifier: "20260701-192842", gapDurationSeconds: 9, closureError: 61, ratio: 1.0),
                makeRecord(sessionIdentifier: "20260701-204705", gapDurationSeconds: 10.5, closureError: 529.5, ratio: 2.0, heading: .poor),
                makeRecord(sessionIdentifier: "20260701-204949", gapDurationSeconds: 41.5, closureError: 309.8, ratio: 1.4)
            ]
        )
    }

    private func makeRecord(
        sessionIdentifier: String,
        gapDurationSeconds: TimeInterval,
        closureError: Double,
        ratio: Double = 0.5,
        heading: HeadingReliability = .high
    ) -> DeadReckoningReplayReviewGapRecord {
        DeadReckoningReplayReviewGapRecord(
            sessionIdentifier: sessionIdentifier,
            gapIndex: 0,
            gapStartTimestamp: Date(timeIntervalSince1970: 1_000),
            gapEndTimestamp: Date(timeIntervalSince1970: 1_000 + gapDurationSeconds),
            gapDurationSeconds: gapDurationSeconds,
            replayBlockingReason: .noBlockingReason,
            estimateCount: 3,
            estimatedDisplacementMeters: 12,
            anchorClosureErrorMeters: closureError,
            closureErrorRatio: ratio,
            headingReliability: heading,
            imuSampleCoverageRatio: 0.9,
            eligibleForUserVisibleEstimatedRoute: false,
            blockingReasons: []
        )
    }
}
