// [協作區] Tests/iOSTests/EstimatedRouteReviewPanelTests.swift
// 用途：驗證 b18-C DEBUG-only review panel 的安全邊界與五筆 real-session review 資訊可呈現。
// 委派至：EstimatedRouteReviewPanel 與 EstimatedRouteReviewOverlayBuilder。

#if DEBUG
import SwiftUI
import XCTest
@testable import SkateTrack_iOS

final class EstimatedRouteReviewPanelTests: XCTestCase {
    func testPanelCanBeCreatedForFiveRealSessionRegressionRoles() {
        let overlay = makeOverlayWithRoles()
        let panel = EstimatedRouteReviewPanel(overlay: overlay)

        XCTAssertEqual(overlay.records.count, 5)
        _ = panel.body
        XCTAssertTrue(overlay.records.contains { $0.sessionReviewRole == "electricSkateboardCoreCandidate" })
        XCTAssertTrue(overlay.records.contains { $0.sessionReviewRole == "walkingLowSpeedTrap" })
        XCTAssertTrue(overlay.records.contains { $0.sessionReviewRole == "surfskateShelteredHighRisk" })
        XCTAssertTrue(overlay.records.contains { $0.sessionReviewRole == "motorcyclePressureTest" })
        XCTAssertTrue(overlay.records.contains { $0.sessionReviewRole == "motorcycleControl" })
    }

    func testPanelInputKeepsAllSafetyFlagsDisabled() {
        let overlay = makeOverlayWithRoles()
        _ = EstimatedRouteReviewPanel(overlay: overlay).body

        XCTAssertTrue(overlay.reviewOnly)
        XCTAssertTrue(overlay.exportedReviewArtifactOnly)
        XCTAssertFalse(overlay.routeGeometryIncluded)
        XCTAssertFalse(overlay.normalSessionMapMutationApplied)
        XCTAssertFalse(overlay.productionRouteMutationApplied)
        XCTAssertFalse(overlay.trustedMetricsMutationApplied)
        XCTAssertFalse(overlay.estimatedRouteDisplayEnabled)
        XCTAssertFalse(overlay.persistedOverlayApplied)
        XCTAssertFalse(overlay.userVisibleDisplayAllowed)
        XCTAssertTrue(overlay.records.allSatisfy { !$0.userVisibleDisplayAllowed && !$0.routeGeometryIncluded })
    }

    func testEmptyOverlayCanRenderLocalizedEmptyStateState() {
        let overlay = EstimatedRouteReviewOverlay(
            createdAt: Date(timeIntervalSince1970: 3_000),
            records: []
        )
        let panel = EstimatedRouteReviewPanel(overlay: overlay)

        XCTAssertTrue(overlay.records.isEmpty)
        XCTAssertFalse(overlay.userVisibleDisplayAllowed)
        XCTAssertFalse(overlay.routeGeometryIncluded)
        _ = panel.body
    }

    func testMotorcycleControlCandidateRemainsHiddenInPanelInput() throws {
        let overlay = makeOverlayWithRoles()
        let record = try XCTUnwrap(overlay.records.first { $0.sessionReviewRole == "motorcycleControl" })

        XCTAssertEqual(record.decisionState, .candidateButHidden)
        XCTAssertEqual(record.reviewDisposition, "candidateButHiddenByProductDecision")
        XCTAssertFalse(record.userVisibleDisplayAllowed)
        XCTAssertFalse(record.estimatedRouteDisplayEnabled)
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
#endif
