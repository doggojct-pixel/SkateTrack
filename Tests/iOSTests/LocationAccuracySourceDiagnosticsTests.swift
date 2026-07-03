// [自主區] Tests/iOSTests/LocationAccuracySourceDiagnosticsTests.swift
// 用途：驗證 b16-C 被動 CoreLocation accuracy-source diagnostics 不聲稱確認 Wi-Fi RTT。
// 委派至：LocationAccuracySourceClassifier 與 LocationAccuracySourceDiagnostics。

import XCTest
@testable import SkateTrack_iOS

final class LocationAccuracySourceDiagnosticsTests: XCTestCase {
    func testHighPrecisionAccuracyIsPassiveAndNotConfirmedWiFiRTT() throws {
        let diagnostics = LocationAccuracySourceClassifier.classify(
            horizontalAccuracyMeters: 2.5,
            verticalAccuracyMeters: 4,
            freshnessState: .fresh,
            routeSegmentConfidence: .high
        )

        XCTAssertEqual(diagnostics.sourceClass, .likelyHighPrecisionGPSOrWiFiRTT)
        let horizontalAccuracyMeters = try XCTUnwrap(diagnostics.horizontalAccuracyMeters)
        let verticalAccuracyMeters = try XCTUnwrap(diagnostics.verticalAccuracyMeters)
        XCTAssertEqual(horizontalAccuracyMeters, 2.5, accuracy: 0.001)
        XCTAssertEqual(verticalAccuracyMeters, 4, accuracy: 0.001)
        XCTAssertTrue(diagnostics.passiveInferenceOnly)
        XCTAssertFalse(diagnostics.explicitWiFiAPIUsed)
        XCTAssertFalse(diagnostics.wifiRTTConfirmed)
    }

    func testAccuracyThresholdsRemainPassiveAndConservative() {
        XCTAssertEqual(
            LocationAccuracySourceClassifier.classify(
                horizontalAccuracyMeters: 8,
                verticalAccuracyMeters: nil,
                freshnessState: .fresh,
                routeSegmentConfidence: .high
            ).sourceClass,
            .possibleGoodGPSOrWiFiRTT
        )
        XCTAssertEqual(
            LocationAccuracySourceClassifier.classify(
                horizontalAccuracyMeters: 20,
                verticalAccuracyMeters: nil,
                freshnessState: .recent,
                routeSegmentConfidence: .medium
            ).sourceClass,
            .typicalGPS
        )
        XCTAssertEqual(
            LocationAccuracySourceClassifier.classify(
                horizontalAccuracyMeters: 50,
                verticalAccuracyMeters: nil,
                freshnessState: .recent,
                routeSegmentConfidence: .low
            ).sourceClass,
            .degradedGPS
        )
        XCTAssertEqual(
            LocationAccuracySourceClassifier.classify(
                horizontalAccuracyMeters: 80,
                verticalAccuracyMeters: nil,
                freshnessState: .recent,
                routeSegmentConfidence: .low
            ).sourceClass,
            .cellOrCachedPosition
        )
    }

    func testStaleOrUnavailableFixesDoNotClaimWiFiRTT() {
        let staleDiagnostics = LocationAccuracySourceClassifier.classify(
            horizontalAccuracyMeters: 2,
            verticalAccuracyMeters: nil,
            freshnessState: .stale,
            routeSegmentConfidence: .low
        )
        let unavailableDiagnostics = LocationAccuracySourceClassifier.classify(
            horizontalAccuracyMeters: nil,
            verticalAccuracyMeters: nil,
            freshnessState: .unavailable,
            routeSegmentConfidence: .unavailable
        )

        XCTAssertEqual(staleDiagnostics.sourceClass, .cellOrCachedPosition)
        XCTAssertEqual(unavailableDiagnostics.sourceClass, .unknown)
        XCTAssertFalse(staleDiagnostics.explicitWiFiAPIUsed)
        XCTAssertFalse(staleDiagnostics.wifiRTTConfirmed)
        XCTAssertFalse(unavailableDiagnostics.explicitWiFiAPIUsed)
        XCTAssertFalse(unavailableDiagnostics.wifiRTTConfirmed)
    }

    func testLocationFixDiagnosticsRoundTripsPassiveAccuracySourceDiagnostics() throws {
        let sourceDiagnostics = LocationAccuracySourceDiagnostics(
            sourceClass: .possibleGoodGPSOrWiFiRTT,
            horizontalAccuracyMeters: 6,
            verticalAccuracyMeters: 9,
            freshnessState: .fresh,
            routeSegmentConfidence: .high
        )
        let diagnostics = LocationFixDiagnostics(
            horizontalAccuracyMeters: 6,
            verticalAccuracyMeters: 9,
            freshnessState: .fresh,
            routeSegmentConfidence: .high,
            locationAccuracySourceDiagnostics: sourceDiagnostics
        )

        let data = try JSONEncoder().encode(diagnostics)
        let decoded = try JSONDecoder().decode(LocationFixDiagnostics.self, from: data)

        let decodedSourceDiagnostics = try XCTUnwrap(decoded.locationAccuracySourceDiagnostics)
        XCTAssertEqual(decodedSourceDiagnostics, sourceDiagnostics)
        XCTAssertTrue(decodedSourceDiagnostics.passiveInferenceOnly)
        XCTAssertFalse(decodedSourceDiagnostics.explicitWiFiAPIUsed)
        XCTAssertFalse(decodedSourceDiagnostics.wifiRTTConfirmed)
    }

    func testDecoderForcesPassiveFlagsEvenWhenInputClaimsConfirmedRTT() throws {
        let json = #"""
        {
          "sourceClass": "likelyHighPrecisionGPSOrWiFiRTT",
          "horizontalAccuracyMeters": 2,
          "freshnessState": "fresh",
          "routeSegmentConfidence": "high",
          "passiveInferenceOnly": false,
          "explicitWiFiAPIUsed": true,
          "wifiRTTConfirmed": true
        }
        """#.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(LocationAccuracySourceDiagnostics.self, from: json)

        XCTAssertEqual(decoded.sourceClass, .likelyHighPrecisionGPSOrWiFiRTT)
        XCTAssertTrue(decoded.passiveInferenceOnly)
        XCTAssertFalse(decoded.explicitWiFiAPIUsed)
        XCTAssertFalse(decoded.wifiRTTConfirmed)
    }

    func testLegacyLocationDiagnosticsDecodeWithoutAccuracySourceDiagnostics() throws {
        let json = #"""
        {
          "horizontalAccuracyMeters": 12,
          "freshnessState": "fresh",
          "routeSegmentConfidence": "medium",
          "speedSource": "coreLocation"
        }
        """#.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(LocationFixDiagnostics.self, from: json)

        XCTAssertNil(decoded.locationAccuracySourceDiagnostics)
        let horizontalAccuracyMeters = try XCTUnwrap(decoded.horizontalAccuracyMeters)
        XCTAssertEqual(horizontalAccuracyMeters, 12, accuracy: 0.001)
    }
}
