// [自主區] Tests/iOSTests/LocalizationDiagnosticsReviewPackTests.swift
// 用途：驗證 b17 localization diagnostics review pack 的 replay-only 邊界。
// 委派至：LocalizationDiagnosticsReviewBuilder 與 LocalizationDiagnosticsReviewPack。

import XCTest
@testable import SkateTrack_iOS

final class LocalizationDiagnosticsReviewPackTests: XCTestCase {
    func testReviewPackSummarizesB16DiagnosticsWithoutProductionMutation() throws {
        let sample = makeLocationFixSample(
            barometricWouldRejectIfEnabled: true,
            accuracySourceClass: .likelyHighPrecisionGPSOrWiFiRTT,
            headingDiagnostics: makeReliableHeadingDiagnostics()
        )

        let pack = LocalizationDiagnosticsReviewBuilder.makeReviewPack(
            samples: [sample],
            createdAt: Date(timeIntervalSince1970: 1_234)
        )

        XCTAssertEqual(pack.taskIdentifier, "Task-030c-b17-0")
        XCTAssertTrue(pack.diagnosticsOnly)
        XCTAssertTrue(pack.replayReviewOnly)
        XCTAssertFalse(pack.productionRouteMutationApplied)
        XCTAssertEqual(pack.summary.totalSampleCount, 1)
        XCTAssertEqual(pack.summary.locationFixSampleCount, 1)
        XCTAssertEqual(pack.summary.barometricOutlierCandidateCount, 1)
        XCTAssertEqual(pack.summary.passiveAccuracySourceDiagnosticCount, 1)
        XCTAssertEqual(pack.summary.highPrecisionOrWiFiLikeFixCount, 1)
        XCTAssertEqual(pack.summary.headingReplayEligibleCount, 1)
        XCTAssertEqual(pack.summary.estimatedRouteActiveSampleCount, 0)
        XCTAssertEqual(pack.summary.productionRouteDecisionAppliedCount, 0)
        XCTAssertEqual(pack.summary.reviewRisk, .attention)
        XCTAssertFalse(try XCTUnwrap(pack.samples.first).estimatedRouteActive)
        XCTAssertFalse(try XCTUnwrap(pack.samples.first).productionRouteDecisionApplied)
    }

    func testReviewPackStaysNominalForEmptyDiagnostics() {
        let sample = MotionSample(
            timestamp: Date(timeIntervalSince1970: 2_000),
            speedKmh: 0,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            sampleSource: .timerFusion
        )

        let pack = LocalizationDiagnosticsReviewBuilder.makeReviewPack(samples: [sample])

        XCTAssertEqual(pack.summary.totalSampleCount, 1)
        XCTAssertEqual(pack.summary.locationFixSampleCount, 0)
        XCTAssertEqual(pack.summary.barometricOutlierCandidateCount, 0)
        XCTAssertEqual(pack.summary.passiveAccuracySourceDiagnosticCount, 0)
        XCTAssertEqual(pack.summary.headingReplayEligibleCount, 0)
        XCTAssertEqual(pack.summary.reviewRisk, .nominal)
        XCTAssertEqual(pack.samples.first?.headingReliability, .unavailable)
    }

    func testReviewPackForcesSerializedSafetyFlags() throws {
        let summary = LocalizationDiagnosticsReviewSummary(
            totalSampleCount: 1,
            locationFixSampleCount: 1,
            estimatedRouteActiveSampleCount: 1,
            productionRouteDecisionAppliedCount: 1,
            reviewRisk: .reviewRecommended
        )
        let pack = LocalizationDiagnosticsReviewPack(
            createdAt: Date(timeIntervalSince1970: 3_000),
            summary: summary,
            samples: []
        )

        let data = try JSONEncoder().encode(pack)
        let decoded = try JSONDecoder().decode(LocalizationDiagnosticsReviewPack.self, from: data)

        XCTAssertTrue(decoded.diagnosticsOnly)
        XCTAssertTrue(decoded.replayReviewOnly)
        XCTAssertFalse(decoded.productionRouteMutationApplied)
        XCTAssertEqual(decoded.summary.reviewRisk, .reviewRecommended)
    }

    private func makeLocationFixSample(
        barometricWouldRejectIfEnabled: Bool,
        accuracySourceClass: LocationAccuracySourceClass,
        headingDiagnostics: HeadingDiagnostics
    ) -> MotionSample {
        let timestamp = Date(timeIntervalSince1970: 1_000)
        let barometricDecision = BarometricGPSOutlierDecision(
            wouldRejectIfGateWereEnabled: barometricWouldRejectIfEnabled,
            diagnosticReason: .barometricAltitudeConflict,
            candidateFixTimestamp: timestamp,
            candidateFixTimestampMillisecondsSince1970: 1_000_000,
            candidateHorizontalJumpMeters: 30,
            candidateGPSAltitudeDeltaMeters: 18,
            barometerAltitudeDeltaMeters: 2,
            discrepancyMeters: 16,
            minimumSuspiciousJumpMeters: 15,
            maxAltitudeDeltaDiscrepancyMeters: 8
        )
        let locationDiagnostics = LocationFixDiagnostics(
            horizontalAccuracyMeters: 2,
            verticalAccuracyMeters: 4,
            speedSource: .coreLocation,
            freshnessState: .fresh,
            routeSegmentConfidence: .high,
            headingDiagnostics: headingDiagnostics,
            deadReckoningDiagnostics: DeadReckoningDiagnostics(estimatedRouteActive: false),
            barometricGPSOutlierDecision: barometricDecision,
            locationAccuracySourceDiagnostics: LocationAccuracySourceDiagnostics(
                sourceClass: accuracySourceClass,
                horizontalAccuracyMeters: 2,
                verticalAccuracyMeters: 4,
                freshnessState: .fresh,
                routeSegmentConfidence: .high
            )
        )
        return MotionSample(
            timestamp: timestamp,
            gpsCoordinate: GeoCoordinate(latitude: 25.0, longitude: 121.0),
            speedKmh: 12,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            locationDiagnostics: locationDiagnostics,
            sampleSource: .locationFix
        )
    }

    private func makeReliableHeadingDiagnostics() -> HeadingDiagnostics {
        HeadingDiagnostics(
            source: .deviceMagnetometer,
            headingAvailable: true,
            courseOverGroundDegrees: 90,
            courseAccuracyDegrees: 4,
            deviceHeadingDegrees: 92,
            deviceHeadingAccuracyDegrees: 3,
            deviceHeadingTimestamp: Date(timeIntervalSince1970: 999),
            deviceHeadingAgeSeconds: 1,
            deviceHeadingReliableForRouteContinuity: true,
            courseDeviceHeadingDeltaDegrees: 2,
            courseDeviceHeadingAgreement: true
        )
    }
}
