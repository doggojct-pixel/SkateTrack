// [自主區] Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift
// 用途：驗證 b18-B review-only overlay artifact 與五筆 real-session regression trap。
// 委派至：EstimatedRouteReviewOverlayBuilder 與 b18 product decision checkpoint。

import XCTest
@testable import SkateTrack_iOS

final class EstimatedRouteReviewOverlayTests: XCTestCase {
    func testOverlayIsReviewOnlyAndNeverUserVisible() {
        let overlay = EstimatedRouteReviewOverlayBuilder.makeOverlay(from: makeFiveSessionReviewPack())

        XCTAssertEqual(overlay.taskIdentifier, "Task-030c-b18-B")
        XCTAssertEqual(overlay.sourceTaskIdentifier, "Task-030c-b18-A")
        XCTAssertTrue(overlay.reviewOnly)
        XCTAssertTrue(overlay.exportedReviewArtifactOnly)
        XCTAssertFalse(overlay.routeGeometryIncluded)
        XCTAssertFalse(overlay.normalSessionMapMutationApplied)
        XCTAssertFalse(overlay.productionRouteMutationApplied)
        XCTAssertFalse(overlay.trustedMetricsMutationApplied)
        XCTAssertFalse(overlay.estimatedRouteDisplayEnabled)
        XCTAssertFalse(overlay.persistedOverlayApplied)
        XCTAssertFalse(overlay.userVisibleDisplayAllowed)
        XCTAssertTrue(overlay.records.allSatisfy { $0.reviewArtifactOnly && !$0.userVisibleDisplayAllowed })
    }

    func testRealSessionRegressionTrapsRemainBlockedOrHidden() {
        let overlay = makeOverlayWithRoles()
        let recordsBySession = Dictionary(uniqueKeysWithValues: overlay.records.map { ($0.sessionIdentifier, $0) })

        XCTAssertEqual(recordsBySession["20260701-204949"]?.decisionState, .blocked)
        XCTAssertEqual(recordsBySession["20260701-204705"]?.decisionState, .blocked)
        XCTAssertEqual(recordsBySession["20260701-192842"]?.decisionState, .blocked)
        XCTAssertEqual(recordsBySession["20260629-131547"]?.decisionState, .blocked)
        XCTAssertEqual(recordsBySession["20260629-132410"]?.decisionState, .candidateButHidden)
        XCTAssertTrue(overlay.records.allSatisfy { !$0.estimatedRouteDisplayEnabled })
    }

    func testReviewRolesAreCarriedWithoutPersistenceOrRouteGeometry() {
        let overlay = makeOverlayWithRoles()
        let electricSkateboard = overlay.records.first { $0.sessionIdentifier == "20260701-204949" }
        let motorcycleControl = overlay.records.first { $0.sessionIdentifier == "20260629-132410" }

        XCTAssertEqual(electricSkateboard?.sessionReviewRole, "electricSkateboardCoreCandidate")
        XCTAssertEqual(motorcycleControl?.sessionReviewRole, "motorcycleControl")
        XCTAssertEqual(motorcycleControl?.reviewDisposition, "candidateButHiddenByProductDecision")
        XCTAssertTrue(overlay.records.allSatisfy { !$0.routeGeometryIncluded && !$0.persistedOverlayApplied })
    }

    func testElectricSkateboardCoreCandidateIsNotPromotedToProductDisplay() throws {
        let overlay = makeOverlayWithRoles()
        let record = try XCTUnwrap(overlay.records.first { $0.sessionIdentifier == "20260701-204949" })

        XCTAssertEqual(record.decisionState, .blocked)
        XCTAssertEqual(record.sessionReviewRole, "electricSkateboardCoreCandidate")
        XCTAssertTrue(record.blockingReasons.contains("gapDurationExceededReviewOnlyLimit"))
        XCTAssertTrue(record.blockingReasons.contains("closureErrorExceededCandidateLimit"))
        XCTAssertFalse(record.userVisibleDisplayAllowed)
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
