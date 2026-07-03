// [自主區] Tests/iOSTests/BarometricGPSOutlierDiagnosticsTests.swift
import CoreLocation
@testable import SkateTrack_iOS
import XCTest

final class BarometricGPSOutlierDiagnosticsTests: XCTestCase {
    func testBarometricConflictIsDiagnosticsOnlyAndWouldRejectIfGateWereEnabled() throws {
        let config = BarometricGPSOutlierDiagnosticConfig(
            minimumSuspiciousJumpMeters: 10,
            maxAltitudeDeltaDiscrepancyMeters: 8
        )
        let previous = makeLocation(latitude: 25.0330, longitude: 121.5650, altitude: 10, timestamp: 100)
        let candidate = makeLocation(latitude: 25.0332, longitude: 121.5652, altitude: 30, timestamp: 101)
        let anchor = BarometricGPSOutlierAnchor(location: previous, barometerAltitudeMeters: 0)

        let decision = BarometricGPSOutlierGuard.evaluate(
            previousAnchor: anchor,
            candidateLocation: candidate,
            candidateBarometerAltitudeMeters: 1,
            config: config
        )

        XCTAssertFalse(decision.productionRouteDecisionApplied)
        XCTAssertTrue(decision.wouldRejectIfGateWereEnabled)
        XCTAssertEqual(decision.diagnosticReason, .barometricAltitudeConflict)
        let gpsAltitudeDeltaMeters = try XCTUnwrap(decision.candidateGPSAltitudeDeltaMeters)
        let barometerAltitudeDeltaMeters = try XCTUnwrap(decision.barometerAltitudeDeltaMeters)
        let discrepancyMeters = try XCTUnwrap(decision.discrepancyMeters)
        XCTAssertEqual(gpsAltitudeDeltaMeters, 20, accuracy: 0.001)
        XCTAssertEqual(barometerAltitudeDeltaMeters, 1, accuracy: 0.001)
        XCTAssertEqual(discrepancyMeters, 19, accuracy: 0.001)
    }

    func testSmallHorizontalJumpDoesNotFlagBarometricConflict() {
        let config = BarometricGPSOutlierDiagnosticConfig(
            minimumSuspiciousJumpMeters: 50,
            maxAltitudeDeltaDiscrepancyMeters: 8
        )
        let previous = makeLocation(latitude: 25.0330, longitude: 121.5650, altitude: 10, timestamp: 100)
        let candidate = makeLocation(latitude: 25.0331, longitude: 121.5651, altitude: 40, timestamp: 101)
        let anchor = BarometricGPSOutlierAnchor(location: previous, barometerAltitudeMeters: 0)

        let decision = BarometricGPSOutlierGuard.evaluate(
            previousAnchor: anchor,
            candidateLocation: candidate,
            candidateBarometerAltitudeMeters: 0,
            config: config
        )

        XCTAssertFalse(decision.productionRouteDecisionApplied)
        XCTAssertFalse(decision.wouldRejectIfGateWereEnabled)
        XCTAssertEqual(decision.diagnosticReason, .horizontalJumpBelowThreshold)
    }

    func testLocationFixDiagnosticsRoundTripsOptionalBarometricDecision() throws {
        let decision = BarometricGPSOutlierDecision(
            wouldRejectIfGateWereEnabled: true,
            diagnosticReason: .barometricAltitudeConflict,
            previousFixTimestamp: Date(timeIntervalSince1970: 100),
            previousFixTimestampMillisecondsSince1970: 100_000,
            candidateFixTimestamp: Date(timeIntervalSince1970: 101),
            candidateFixTimestampMillisecondsSince1970: 101_000,
            candidateHorizontalJumpMeters: 24,
            candidateGPSAltitudeDeltaMeters: 20,
            barometerAltitudeDeltaMeters: 1,
            discrepancyMeters: 19,
            minimumSuspiciousJumpMeters: 10,
            maxAltitudeDeltaDiscrepancyMeters: 8
        )
        let diagnostics = LocationFixDiagnostics(
            horizontalAccuracyMeters: 5,
            verticalAccuracyMeters: 6,
            speedSource: .coreLocation,
            freshnessState: .fresh,
            routeSegmentConfidence: .high,
            barometricGPSOutlierDecision: decision
        )

        let data = try JSONEncoder().encode(diagnostics)
        let decoded = try JSONDecoder().decode(LocationFixDiagnostics.self, from: data)

        XCTAssertEqual(decoded.barometricGPSOutlierDecision, decision)
        XCTAssertFalse(decoded.barometricGPSOutlierDecision?.productionRouteDecisionApplied ?? true)
    }


    func testDecodedProductionDecisionIsForcedFalse() throws {
        let json = #"""
        {
          "productionRouteDecisionApplied": true,
          "wouldRejectIfGateWereEnabled": true,
          "diagnosticReason": "barometricAltitudeConflict",
          "candidateFixTimestamp": 101,
          "candidateFixTimestampMillisecondsSince1970": 101000,
          "minimumSuspiciousJumpMeters": 10,
          "maxAltitudeDeltaDiscrepancyMeters": 8
        }
        """#.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(BarometricGPSOutlierDecision.self, from: json)

        XCTAssertFalse(decoded.productionRouteDecisionApplied)
        XCTAssertTrue(decoded.wouldRejectIfGateWereEnabled)
    }

    func testLegacyLocationDiagnosticsDecodeWithoutBarometricDecision() throws {
        let legacyJSON = #"""
        {
          "horizontalAccuracyMeters": 5.0,
          "verticalAccuracyMeters": 8.0,
          "speedSource": "coreLocation",
          "freshnessState": "fresh",
          "routeSegmentConfidence": "high"
        }
        """#.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(LocationFixDiagnostics.self, from: legacyJSON)

        XCTAssertNil(decoded.barometricGPSOutlierDecision)
        XCTAssertEqual(decoded.routeSegmentConfidence, .high)
    }

    private func makeLocation(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance,
        timestamp: TimeInterval
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 1,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
    }
}
