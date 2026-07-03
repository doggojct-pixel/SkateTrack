// [自主區] Tests/iOSTests/DeadReckoningClosureScoringTests.swift
// 用途：驗證 b17-C anchor closure error 與 confidence scoring 的 replay-only eligibility gates。
// 委派至：DeadReckoningClosureScorer、DeadReckoningClosureDiagnostics 與 b17-D review pack。

import XCTest
@testable import SkateTrack_iOS

final class DeadReckoningClosureScoringTests: XCTestCase {
    func testLowClosureErrorIsEligibleReplayCandidate() {
        let diagnostics = DeadReckoningClosureScorer.score(
            gapDurationSeconds: 20,
            estimatedDistanceMeters: 40,
            closureErrorMeters: 5,
            headingReliability: .high,
            imuSampleCoverageRatio: 0.9
        )

        XCTAssertTrue(diagnostics.eligibleForUserVisibleEstimatedRoute)
        XCTAssertTrue(diagnostics.blockingReasons.isEmpty)
        XCTAssertEqual(diagnostics.closureErrorRatio, 0.125, accuracy: 0.000_001)
    }

    func testHighClosureErrorIsBlocked() {
        let diagnostics = DeadReckoningClosureScorer.score(
            gapDurationSeconds: 20,
            estimatedDistanceMeters: 40,
            closureErrorMeters: 30,
            headingReliability: .high,
            imuSampleCoverageRatio: 0.9
        )

        XCTAssertFalse(diagnostics.eligibleForUserVisibleEstimatedRoute)
        XCTAssertTrue(diagnostics.blockingReasons.contains("closureErrorExceededBlockingThreshold"))
    }

    func testMissingHeadingIsBlocked() {
        let diagnostics = DeadReckoningClosureScorer.score(
            gapDurationSeconds: 20,
            estimatedDistanceMeters: 40,
            closureErrorMeters: 5,
            headingReliability: .unavailable,
            imuSampleCoverageRatio: 0.9
        )

        XCTAssertFalse(diagnostics.eligibleForUserVisibleEstimatedRoute)
        XCTAssertTrue(diagnostics.blockingReasons.contains("headingReliabilityInsufficient"))
    }

    func testLowIMUCoverageIsBlocked() {
        let diagnostics = DeadReckoningClosureScorer.score(
            gapDurationSeconds: 20,
            estimatedDistanceMeters: 40,
            closureErrorMeters: 5,
            headingReliability: .high,
            imuSampleCoverageRatio: 0.35
        )

        XCTAssertFalse(diagnostics.eligibleForUserVisibleEstimatedRoute)
        XCTAssertTrue(diagnostics.blockingReasons.contains("imuSampleCoverageInsufficient"))
    }

    func testVeryLongGapIsBlocked() {
        let diagnostics = DeadReckoningClosureScorer.score(
            gapDurationSeconds: 75,
            estimatedDistanceMeters: 40,
            closureErrorMeters: 2,
            headingReliability: .high,
            imuSampleCoverageRatio: 0.9
        )

        XCTAssertFalse(diagnostics.eligibleForUserVisibleEstimatedRoute)
        XCTAssertTrue(diagnostics.blockingReasons.contains("gapDurationExceededOutdoorLimit"))
    }

    func testReplayDiagnosticsReceivesClosureDiagnostics() throws {
        let preAnchor = makeAnchor(timestamp: 0, coordinate: coordinate(eastMeters: 0), speedKmh: 3.6, headingDegrees: 90)
        let postAnchor = makeAnchor(timestamp: 4, coordinate: coordinate(eastMeters: 4), speedKmh: 3.6, headingDegrees: 90)
        let samples = (1...3).map { second in
            makeTimerFusion(timestamp: Double(second), headingDegrees: 90)
        }

        let replayDiagnostics = DeadReckoningEngine.estimateGap(
            preGapAnchor: preAnchor,
            postGapAnchor: postAnchor,
            timerFusionSamples: samples,
            config: DeadReckoningReplayConfig(minimumIMUSampleCount: 2)
        )

        let closureDiagnostics = try XCTUnwrap(replayDiagnostics.closureDiagnostics)
        XCTAssertEqual(closureDiagnostics.closureErrorMeters, try XCTUnwrap(replayDiagnostics.anchorClosureErrorMeters))
        XCTAssertEqual(closureDiagnostics.headingReliability, .high)
        XCTAssertFalse(replayDiagnostics.productionRouteMutationApplied)
        XCTAssertFalse(replayDiagnostics.trustedMetricsMutationApplied)
    }

    private func makeAnchor(
        timestamp: TimeInterval,
        coordinate: GeoCoordinate,
        speedKmh: Double,
        headingDegrees: Double?
    ) -> MotionSample {
        MotionSample(
            timestamp: Date(timeIntervalSince1970: timestamp),
            gpsCoordinate: coordinate,
            speedKmh: speedKmh,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: .zero,
            locationDiagnostics: LocationFixDiagnostics(
                horizontalAccuracyMeters: 5,
                routeSegmentConfidence: .high,
                headingDiagnostics: headingDegrees.map { makeHeadingDiagnostics(headingDegrees: $0) }
            ),
            sampleSource: .locationFix
        )
    }

    private func makeTimerFusion(timestamp: TimeInterval, headingDegrees: Double?) -> MotionSample {
        MotionSample(
            timestamp: Date(timeIntervalSince1970: timestamp),
            speedKmh: 0,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: .zero,
            locationDiagnostics: LocationFixDiagnostics(
                headingDiagnostics: headingDegrees.map { makeHeadingDiagnostics(headingDegrees: $0) }
            ),
            sampleSource: .timerFusion
        )
    }

    private func makeHeadingDiagnostics(headingDegrees: Double) -> HeadingDiagnostics {
        HeadingDiagnostics(
            source: .deviceMagnetometer,
            headingAvailable: true,
            deviceHeadingDeferred: false,
            deviceHeadingDegrees: headingDegrees,
            deviceHeadingAccuracyDegrees: 3,
            deviceHeadingTimestamp: Date(timeIntervalSince1970: 0),
            deviceHeadingAgeSeconds: 1,
            deviceHeadingReliableForRouteContinuity: true
        )
    }

    private func coordinate(eastMeters: Double) -> GeoCoordinate {
        LocalTangentPlane(anchorCoordinate: GeoCoordinate(latitude: 25.0330, longitude: 121.5654))
            .coordinate(eastMeters: eastMeters, northMeters: 0)
    }
}
