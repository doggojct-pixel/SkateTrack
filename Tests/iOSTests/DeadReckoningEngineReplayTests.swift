// [自主區] Tests/iOSTests/DeadReckoningEngineReplayTests.swift
// 用途：驗證 b17-B replay-only DeadReckoningEngine v1 的候選估計與安全邊界。
// 委派至：DeadReckoningEngine、DeadReckoningReplayEstimate 與 b17-C closure scoring。

import XCTest
@testable import SkateTrack_iOS

final class DeadReckoningEngineReplayTests: XCTestCase {
    func testStraightLineSyntheticAccelerationProducesPlausibleDisplacement() throws {
        let preAnchor = makeAnchor(timestamp: 0, coordinate: coordinate(eastMeters: 0), speedKmh: 0, headingDegrees: 90)
        let postAnchor = makeAnchor(timestamp: 5, coordinate: coordinate(eastMeters: 6), speedKmh: 0, headingDegrees: 90)
        let samples = (1...4).map { second in
            makeTimerFusion(timestamp: Double(second), accelerationX: 1, headingDegrees: 90)
        }

        let diagnostics = DeadReckoningEngine.estimateGap(
            preGapAnchor: preAnchor,
            postGapAnchor: postAnchor,
            timerFusionSamples: samples,
            config: DeadReckoningReplayConfig(minimumIMUSampleCount: 2)
        )

        XCTAssertEqual(diagnostics.blockingReason, .noBlockingReason)
        XCTAssertFalse(diagnostics.estimates.isEmpty)
        XCTAssertGreaterThan(try XCTUnwrap(diagnostics.estimates.last).localEastMeters, 5)
        XCTAssertFalse(diagnostics.productionRouteMutationApplied)
        XCTAssertFalse(diagnostics.trustedMetricsMutationApplied)
    }

    func testConstantHeadingAndKnownVelocityApproximateExpectedRoute() throws {
        let preAnchor = makeAnchor(timestamp: 0, coordinate: coordinate(eastMeters: 0), speedKmh: 3.6, headingDegrees: 90)
        let postAnchor = makeAnchor(timestamp: 4, coordinate: coordinate(eastMeters: 4), speedKmh: 3.6, headingDegrees: 90)
        let samples = (1...3).map { second in
            makeTimerFusion(timestamp: Double(second), accelerationX: 0, headingDegrees: 90)
        }

        let diagnostics = DeadReckoningEngine.estimateGap(
            preGapAnchor: preAnchor,
            postGapAnchor: postAnchor,
            timerFusionSamples: samples,
            config: DeadReckoningReplayConfig(minimumIMUSampleCount: 2)
        )

        let finalEstimate = try XCTUnwrap(diagnostics.estimates.last)
        XCTAssertEqual(finalEstimate.localEastMeters, 3, accuracy: 0.25)
        XCTAssertEqual(finalEstimate.confidence, .high)
        XCTAssertEqual(finalEstimate.source, .replayOnlyIMU)
    }

    func testMissingHeadingDowngradesConfidence() throws {
        let preAnchor = makeAnchor(timestamp: 0, coordinate: coordinate(eastMeters: 0), speedKmh: 3.6, headingDegrees: nil)
        let postAnchor = makeAnchor(timestamp: 4, coordinate: coordinate(eastMeters: 4), speedKmh: 3.6, headingDegrees: nil)
        let samples = (1...3).map { second in
            makeTimerFusion(timestamp: Double(second), accelerationX: 0, headingDegrees: nil)
        }

        let diagnostics = DeadReckoningEngine.estimateGap(
            preGapAnchor: preAnchor,
            postGapAnchor: postAnchor,
            timerFusionSamples: samples,
            config: DeadReckoningReplayConfig(minimumIMUSampleCount: 2)
        )

        let firstEstimate = try XCTUnwrap(diagnostics.estimates.first)
        XCTAssertEqual(firstEstimate.confidence, .low)
        XCTAssertEqual(firstEstimate.source, .replayOnlyIMUHeadingUnavailable)
    }

    func testGapLongerThanPolicyLimitIsBlocked() {
        let preAnchor = makeAnchor(timestamp: 0, coordinate: coordinate(eastMeters: 0), speedKmh: 0, headingDegrees: 90)
        let postAnchor = makeAnchor(timestamp: 95, coordinate: coordinate(eastMeters: 5), speedKmh: 0, headingDegrees: 90)
        let samples = (1...10).map { second in
            makeTimerFusion(timestamp: Double(second), accelerationX: 0, headingDegrees: 90)
        }

        let diagnostics = DeadReckoningEngine.estimateGap(
            preGapAnchor: preAnchor,
            postGapAnchor: postAnchor,
            timerFusionSamples: samples
        )

        XCTAssertEqual(diagnostics.blockingReason, .gapTooLong)
        XCTAssertTrue(diagnostics.estimates.isEmpty)
    }

    func testAnchorClosureErrorIsRecorded() throws {
        let preAnchor = makeAnchor(timestamp: 0, coordinate: coordinate(eastMeters: 0), speedKmh: 3.6, headingDegrees: 90)
        let postAnchor = makeAnchor(timestamp: 4, coordinate: coordinate(eastMeters: 4), speedKmh: 3.6, headingDegrees: 90)
        let samples = (1...3).map { second in
            makeTimerFusion(timestamp: Double(second), accelerationX: 0, headingDegrees: 90)
        }

        let diagnostics = DeadReckoningEngine.estimateGap(
            preGapAnchor: preAnchor,
            postGapAnchor: postAnchor,
            timerFusionSamples: samples,
            config: DeadReckoningReplayConfig(minimumIMUSampleCount: 2)
        )

        XCTAssertNotNil(diagnostics.anchorClosureErrorMeters)
        XCTAssertEqual(try XCTUnwrap(diagnostics.anchorClosureErrorMeters), 1, accuracy: 0.35)
    }

    func testDriftRateProducesNamedAccuracyGrowth() throws {
        let preAnchor = makeAnchor(timestamp: 0, coordinate: coordinate(eastMeters: 0), speedKmh: 0, headingDegrees: 90)
        let postAnchor = makeAnchor(timestamp: 5, coordinate: coordinate(eastMeters: 1), speedKmh: 0, headingDegrees: 90)
        let samples = (1...2).map { second in
            makeTimerFusion(timestamp: Double(second), accelerationX: 0, headingDegrees: 90)
        }

        let diagnostics = DeadReckoningEngine.estimateGap(
            preGapAnchor: preAnchor,
            postGapAnchor: postAnchor,
            timerFusionSamples: samples,
            config: DeadReckoningReplayConfig(minimumIMUSampleCount: 2)
        )

        let secondEstimate = try XCTUnwrap(diagnostics.estimates.last)
        XCTAssertEqual(secondEstimate.estimatedHorizontalAccuracyMeters, 6, accuracy: 0.001)
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

    private func makeTimerFusion(
        timestamp: TimeInterval,
        accelerationX: Double,
        headingDegrees: Double?
    ) -> MotionSample {
        let accelerationG = ThreeAxisValue(
            x: accelerationX / GravityCompensatedMotionSample.gravitationalAccelerationMetersPerSecondSquared,
            y: 0,
            z: 1
        )
        return MotionSample(
            timestamp: Date(timeIntervalSince1970: timestamp),
            speedKmh: 0,
            accelerometerG: accelerationG,
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
