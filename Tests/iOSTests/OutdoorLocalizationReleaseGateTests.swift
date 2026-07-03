// [自主區] Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift
// 用途：驗證 b19 outdoor localization release gate 保守分類與 b18-D 安全邊界。
// 委派至：OutdoorLocalizationReleaseGateBuilder 與 b19 release gate 文件。

import XCTest
@testable import SkateTrack_iOS

final class OutdoorLocalizationReleaseGateTests: XCTestCase {
    func testHighQualityOutdoorEvidenceCanBeReleaseReadyWithoutEstimatedRouteDisplay() {
        let gate = OutdoorLocalizationReleaseGateBuilder.makeGate(from: [highQualityOutdoorEvidence()])

        XCTAssertEqual(gate.taskIdentifier, "Task-030c-b19")
        XCTAssertEqual(gate.decision, .releaseReady)
        XCTAssertEqual(gate.reviewedOutdoorSessionCount, 1)
        XCTAssertTrue(gate.realGPSOnly)
        XCTAssertFalse(gate.generalUserEstimatedRouteDisplayAllowed)
        XCTAssertFalse(gate.estimatedRouteDisplayEnabled)
        XCTAssertFalse(gate.estimatedRouteActive)
        XCTAssertFalse(gate.routeGeometryMutationApplied)
        XCTAssertFalse(gate.trustedMetricsMutationApplied)
        XCTAssertFalse(gate.persistenceSchemaMutationApplied)
    }

    func testModerateRealGPSEvidenceUsesLimitedDisclosure() {
        let gate = OutdoorLocalizationReleaseGateBuilder.makeGate(from: [
            OutdoorLocalizationReleaseEvidence(
                sessionReviewRole: "moderateOutdoorControl",
                trustedGPSCoverageRatio: 0.88,
                startupWarmupSeconds: 12,
                longestGPSGapSeconds: 4,
                horizontalAccuracyP95Meters: 42,
                lowSpeedTrapDurationSeconds: 0,
                headingReliable: true,
                altitudeReliable: true
            )
        ])

        XCTAssertEqual(gate.decision, .limitedDisclosure)
        XCTAssertTrue(gate.disclosureReasons.contains("horizontalAccuracyRequiresDisclosure"))
        XCTAssertFalse(gate.generalUserEstimatedRouteDisplayAllowed)
    }

    func testLowSpeedAndShelteredRegressionEvidenceIsNotReleaseReady() {
        let gate = OutdoorLocalizationReleaseGateBuilder.makeGate(from: [
            OutdoorLocalizationReleaseEvidence(
                sessionReviewRole: "walkingLowSpeedTrap",
                trustedGPSCoverageRatio: 0.84,
                startupWarmupSeconds: 18,
                longestGPSGapSeconds: 7,
                horizontalAccuracyP95Meters: 36,
                lowSpeedTrapDurationSeconds: 24,
                headingReliable: true,
                altitudeReliable: true
            ),
            OutdoorLocalizationReleaseEvidence(
                sessionReviewRole: "surfskateShelteredHighRisk",
                trustedGPSCoverageRatio: 0.82,
                startupWarmupSeconds: 8,
                longestGPSGapSeconds: 9,
                horizontalAccuracyP95Meters: 48,
                lowSpeedTrapDurationSeconds: 0,
                headingReliable: true,
                altitudeReliable: true,
                shelteredOrHighRiskEnvironment: true
            )
        ])

        XCTAssertEqual(gate.decision, .blocked)
        XCTAssertTrue(gate.blockingReasons.contains(.lowSpeedLocalizationTrap))
        XCTAssertTrue(gate.disclosureReasons.contains("shelteredOrHighRiskEnvironment"))
        XCTAssertFalse(gate.estimatedRouteActive)
    }

    func testPoorCoverageOrLongGapIsBlocked() {
        let gate = OutdoorLocalizationReleaseGateBuilder.makeGate(from: [
            OutdoorLocalizationReleaseEvidence(
                sessionReviewRole: "motorcyclePressureTest",
                trustedGPSCoverageRatio: 0.62,
                startupWarmupSeconds: 45,
                longestGPSGapSeconds: 49,
                horizontalAccuracyP95Meters: 90,
                lowSpeedTrapDurationSeconds: 0,
                headingReliable: false,
                altitudeReliable: false
            )
        ])

        XCTAssertEqual(gate.decision, .blocked)
        XCTAssertTrue(gate.blockingReasons.contains(.insufficientTrustedGPSCoverage))
        XCTAssertTrue(gate.blockingReasons.contains(.excessiveGPSGapDuration))
        XCTAssertTrue(gate.blockingReasons.contains(.excessiveHorizontalAccuracy))
        XCTAssertTrue(gate.blockingReasons.contains(.headingQualityInsufficient))
        XCTAssertFalse(gate.trustedMetricsMutationApplied)
    }

    func testEmptyEvidenceIsBlockedAndStillPreservesB18DDecision() {
        let gate = OutdoorLocalizationReleaseGateBuilder.makeGate(from: [])

        XCTAssertEqual(gate.decision, .blocked)
        XCTAssertTrue(gate.blockingReasons.contains(.insufficientTrustedGPSCoverage))
        XCTAssertTrue(gate.blockingReasons.contains(.estimatedRouteDisplayDisabledByProductDecision))
        XCTAssertFalse(gate.generalUserEstimatedRouteDisplayAllowed)
        XCTAssertFalse(gate.estimatedRouteDisplayEnabled)
        XCTAssertFalse(gate.estimatedRouteActive)
        XCTAssertFalse(gate.routeGeometryMutationApplied)
        XCTAssertFalse(gate.persistenceSchemaMutationApplied)
    }

    private func highQualityOutdoorEvidence() -> OutdoorLocalizationReleaseEvidence {
        OutdoorLocalizationReleaseEvidence(
            sessionReviewRole: "outdoorReleaseReadyControl",
            trustedGPSCoverageRatio: 0.96,
            startupWarmupSeconds: 0,
            longestGPSGapSeconds: 1.5,
            horizontalAccuracyP95Meters: 12,
            lowSpeedTrapDurationSeconds: 0,
            headingReliable: true,
            altitudeReliable: true
        )
    }
}
