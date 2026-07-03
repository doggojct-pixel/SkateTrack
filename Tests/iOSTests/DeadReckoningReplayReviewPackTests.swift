// [自主區] Tests/iOSTests/DeadReckoningReplayReviewPackTests.swift
// 用途：驗證 b17-D real-session replay review pack 的 JSON / Markdown / CSV artifacts 與 safety gates。
// 委派至：DeadReckoningReplayReviewPackBuilder 與 product decision checkpoint。

import XCTest
@testable import SkateTrack_iOS

final class DeadReckoningReplayReviewPackTests: XCTestCase {
    func testReviewPackSummarizesEligibleAndBlockedRealSessionGaps() throws {
        let eligibleDiagnostics = makeReplayDiagnostics(
            gapDurationSeconds: 20,
            blockingReason: .noBlockingReason,
            closureDiagnostics: makeClosureDiagnostics(eligible: true, blockingReasons: [])
        )
        let blockedDiagnostics = makeReplayDiagnostics(
            gapDurationSeconds: 75,
            blockingReason: .gapTooLong,
            closureDiagnostics: nil
        )

        let pack = DeadReckoningReplayReviewPackBuilder.makeReviewPack(
            sessions: [
                DeadReckoningReplayReviewSessionInput(
                    sessionIdentifier: "real-walk-session",
                    replayDiagnostics: [eligibleDiagnostics, blockedDiagnostics]
                )
            ],
            createdAt: Date(timeIntervalSince1970: 100)
        )

        let summary = try XCTUnwrap(pack.sessionSummaries.first)
        XCTAssertEqual(pack.taskIdentifier, "Task-030c-b17-D")
        XCTAssertEqual(pack.archiveFileName, "Task030c_b17D_ReplayReviewPack.zip")
        XCTAssertEqual(summary.totalGapCount, 2)
        XCTAssertEqual(summary.replaySucceededGapCount, 1)
        XCTAssertEqual(summary.blockedGapCount, 1)
        XCTAssertEqual(summary.userVisibleEligibleGapCount, 1)
        XCTAssertEqual(summary.reviewRecommendedGapCount, 1)
        XCTAssertTrue(pack.productDecisionCheckpointRequired)
        XCTAssertTrue(pack.b18DisplayWorkBlockedUntilProductDecision)
    }

    func testReviewPackArtifactsContainJsonMarkdownAndCSV() throws {
        let pack = DeadReckoningReplayReviewPackBuilder.makeReviewPack(
            sessions: [
                DeadReckoningReplayReviewSessionInput(
                    sessionIdentifier: "electric-longboard-session",
                    replayDiagnostics: [makeReplayDiagnostics(closureDiagnostics: makeClosureDiagnostics())]
                )
            ],
            createdAt: Date(timeIntervalSince1970: 200)
        )

        let artifacts = try DeadReckoningReplayReviewPackBuilder.makeArtifacts(for: pack)
        XCTAssertEqual(artifacts.map(\.kind), [.json, .markdown, .csv])
        XCTAssertTrue(artifacts[0].contents.contains("Task-030c-b17-D"))
        XCTAssertTrue(artifacts[1].contents.contains("Product decision checkpoint required"))
        XCTAssertTrue(artifacts[2].contents.contains("gapDurationSeconds,imuSampleCoverageRatio,headingReliability"))
        XCTAssertTrue(artifacts[2].contents.contains("estimatedDisplacementMeters,anchorClosureErrorMeters"))
    }

    func testReviewPackPreservesReplayOnlySafetyFlags() {
        let pack = DeadReckoningReplayReviewPackBuilder.makeReviewPack(
            sessions: [DeadReckoningReplayReviewSessionInput(sessionIdentifier: "safety", replayDiagnostics: [])]
        )

        XCTAssertTrue(pack.replayReviewOnly)
        XCTAssertFalse(pack.productionRouteMutationApplied)
        XCTAssertFalse(pack.trustedMetricsMutationApplied)
        XCTAssertFalse(pack.estimatedRouteDisplayEnabled)
    }

    func testCSVIncludesBlockingReasonsForReview() {
        let diagnostics = makeReplayDiagnostics(
            blockingReason: .insufficientIMUSamples,
            closureDiagnostics: makeClosureDiagnostics(eligible: false, blockingReasons: ["imuSampleCoverageInsufficient"])
        )
        let pack = DeadReckoningReplayReviewPackBuilder.makeReviewPack(
            sessions: [DeadReckoningReplayReviewSessionInput(sessionIdentifier: "blocked", replayDiagnostics: [diagnostics])]
        )
        let csv = DeadReckoningReplayReviewPackBuilder.makeCSV(for: pack)

        XCTAssertTrue(csv.contains("insufficientIMUSamples;imuSampleCoverageInsufficient"))
    }

    private func makeReplayDiagnostics(
        gapDurationSeconds: TimeInterval = 20,
        blockingReason: DeadReckoningReplayBlockingReason = .noBlockingReason,
        closureDiagnostics: DeadReckoningClosureDiagnostics? = nil
    ) -> DeadReckoningReplayDiagnostics {
        let start = Date(timeIntervalSince1970: 1_000)
        let end = start.addingTimeInterval(gapDurationSeconds)
        return DeadReckoningReplayDiagnostics(
            gapStartTimestamp: start,
            gapEndTimestamp: end,
            gapDurationSeconds: gapDurationSeconds,
            blockingReason: blockingReason,
            preGapAnchorCoordinate: GeoCoordinate(latitude: 25.0330, longitude: 121.5654),
            postGapAnchorCoordinate: GeoCoordinate(latitude: 25.0331, longitude: 121.5655),
            anchorClosureErrorMeters: closureDiagnostics?.closureErrorMeters,
            closureDiagnostics: closureDiagnostics,
            estimates: closureDiagnostics == nil ? [] : [makeEstimate(eastMeters: 8), makeEstimate(eastMeters: 16)]
        )
    }

    private func makeClosureDiagnostics(
        eligible: Bool = true,
        blockingReasons: [String] = []
    ) -> DeadReckoningClosureDiagnostics {
        DeadReckoningClosureDiagnostics(
            gapDurationSeconds: 20,
            estimatedDistanceMeters: 16,
            closureErrorMeters: 2,
            closureErrorRatio: 0.125,
            headingReliability: .high,
            imuSampleCoverageRatio: 0.9,
            eligibleForUserVisibleEstimatedRoute: eligible,
            blockingReasons: blockingReasons
        )
    }

    private func makeEstimate(eastMeters: Double) -> DeadReckoningReplayEstimate {
        DeadReckoningReplayEstimate(
            timestamp: Date(timeIntervalSince1970: 1_001 + eastMeters),
            localEastMeters: eastMeters,
            localNorthMeters: 0,
            estimatedCoordinate: GeoCoordinate(latitude: 25.0330, longitude: 121.5654),
            estimatedHorizontalAccuracyMeters: 5,
            source: .replayOnlyIMU,
            confidence: .high
        )
    }
}
