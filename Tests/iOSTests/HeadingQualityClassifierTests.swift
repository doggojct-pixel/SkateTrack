// [自主區] Tests/iOSTests/HeadingQualityClassifierTests.swift
// 用途：驗證 b16-D heading reliability 分級維持 replay-only 與 diagnostics-only 邊界。
// 委派至：HeadingQualityClassifier 與 HeadingQualityDiagnostics。

import XCTest
@testable import SkateTrack_iOS

final class HeadingQualityClassifierTests: XCTestCase {
    func testHighAccuracyDeviceHeadingIsReplayReady() throws {
        let diagnostics = HeadingDiagnostics(
            source: .courseAndDeviceMagnetometer,
            headingAvailable: true,
            courseOverGroundDegrees: 95,
            courseAccuracyDegrees: 8,
            coreLocationSpeedKmh: 12,
            courseReliableForRouteContinuity: true,
            deviceHeadingDeferred: false,
            deviceHeadingDegrees: 100,
            deviceHeadingAccuracyDegrees: 3,
            deviceHeadingAgeSeconds: 1,
            deviceHeadingReliableForRouteContinuity: true,
            courseDeviceHeadingDeltaDegrees: 5,
            courseDeviceHeadingAgreement: true
        )

        let assessment = HeadingQualityClassifier.classify(diagnostics)

        XCTAssertEqual(assessment.reliability, .high)
        XCTAssertTrue(assessment.replayReadinessEligible)
        let selectedHeadingDegrees = try XCTUnwrap(assessment.selectedHeadingDegrees)
        let selectedHeadingAccuracyDegrees = try XCTUnwrap(assessment.selectedHeadingAccuracyDegrees)
        let selectedHeadingAgeSeconds = try XCTUnwrap(assessment.selectedHeadingAgeSeconds)
        XCTAssertEqual(selectedHeadingDegrees, 100, accuracy: 0.001)
        XCTAssertEqual(selectedHeadingAccuracyDegrees, 3, accuracy: 0.001)
        XCTAssertEqual(selectedHeadingAgeSeconds, 1, accuracy: 0.001)
        XCTAssertEqual(assessment.source, .courseAndDeviceMagnetometer)
    }

    func testModerateCourseHeadingCanRemainReplayReady() throws {
        let diagnostics = HeadingDiagnostics(
            source: .coreLocationCourse,
            headingAvailable: true,
            courseOverGroundDegrees: 180,
            courseAccuracyDegrees: 15,
            coreLocationSpeedKmh: 10,
            courseReliableForRouteContinuity: true,
            deviceHeadingDeferred: true,
            deviceHeadingReliableForRouteContinuity: false
        )

        let assessment = HeadingQualityClassifier.classify(diagnostics)

        XCTAssertEqual(assessment.reliability, .moderate)
        XCTAssertTrue(assessment.replayReadinessEligible)
        let selectedHeadingDegrees = try XCTUnwrap(assessment.selectedHeadingDegrees)
        XCTAssertEqual(selectedHeadingDegrees, 180, accuracy: 0.001)
    }

    func testOldDeviceHeadingIsNotReplayReady() {
        let diagnostics = HeadingDiagnostics(
            source: .deviceMagnetometer,
            headingAvailable: true,
            deviceHeadingDeferred: false,
            deviceHeadingDegrees: 30,
            deviceHeadingAccuracyDegrees: 4,
            deviceHeadingAgeSeconds: 8,
            deviceHeadingReliableForRouteContinuity: true
        )

        let assessment = HeadingQualityClassifier.classify(diagnostics)

        XCTAssertEqual(assessment.reliability, .tooOld)
        XCTAssertFalse(assessment.replayReadinessEligible)
    }

    func testInvalidAccuracyIsNotReplayReady() {
        let diagnostics = HeadingDiagnostics(
            source: .deviceMagnetometer,
            headingAvailable: true,
            deviceHeadingDeferred: false,
            deviceHeadingDegrees: 270,
            deviceHeadingAccuracyDegrees: -1,
            deviceHeadingAgeSeconds: 1,
            deviceHeadingReliableForRouteContinuity: true
        )

        let assessment = HeadingQualityClassifier.classify(diagnostics)

        XCTAssertEqual(assessment.reliability, .invalid)
        XCTAssertFalse(assessment.replayReadinessEligible)
    }

    func testUnavailableHeadingRemainsDiagnosticsOnly() {
        let assessment = HeadingQualityClassifier.classify(nil)

        XCTAssertEqual(assessment.reliability, .unavailable)
        XCTAssertFalse(assessment.replayReadinessEligible)
        XCTAssertNil(assessment.selectedHeadingDegrees)
    }

    func testHeadingQualityAssessmentCodableRoundTrip() throws {
        let assessment = HeadingQualityAssessment(
            reliability: .moderate,
            replayReadinessEligible: true,
            selectedHeadingDegrees: 44,
            selectedHeadingAccuracyDegrees: 12,
            selectedHeadingAgeSeconds: 2,
            courseDeviceHeadingAgreement: true,
            source: .deviceMagnetometer
        )

        let encoded = try JSONEncoder().encode(assessment)
        let decoded = try JSONDecoder().decode(HeadingQualityAssessment.self, from: encoded)

        XCTAssertEqual(decoded, assessment)
    }
}
