// [Collaboration] Tests/iOSTests/WatchSampleFusionRulesTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchSampleFusionRulesTests: XCTestCase {
    func testConflictingWatchSampleKeepsIPhoneTrustedDisplayPoint() {
        let iPhone = Self.iPhoneSample(id: 1, timestamp: 100, value: 10)
        let watch = Self.watchSample(id: 2, timestamp: 101, value: 18)

        let result = WatchSampleFusionEngine().makeDisplayFusion(
            iPhoneSamples: [iPhone],
            watchSamples: [watch],
            policy: WatchSampleFusionPolicy(
                maximumAlignmentInterval: 2,
                maximumDisplayGap: 30,
                minimumConflictDelta: 1
            )
        )

        XCTAssertEqual(result.displayPoints.count, 1)
        XCTAssertEqual(result.displayPoints.first?.source, .iPhoneTrusted)
        XCTAssertEqual(result.displayPoints.first?.numericValue, 10)
        XCTAssertEqual(result.displayDerivedPoints.count, 0)
        XCTAssertEqual(result.diagnostics.conflictCount, 1)
        XCTAssertEqual(result.trustedMetricMutationCount, 0)
    }

    func testWatchSampleInsideIPhoneGapIsDisplayDerivedOnly() {
        let iPhoneSamples = [
            Self.iPhoneSample(id: 1, timestamp: 100, value: 10),
            Self.iPhoneSample(id: 2, timestamp: 160, value: 16)
        ]
        let watch = Self.watchSample(id: 3, timestamp: 130, value: 13)

        let result = WatchSampleFusionEngine().makeDisplayFusion(
            iPhoneSamples: iPhoneSamples,
            watchSamples: [watch],
            policy: WatchSampleFusionPolicy(maximumDisplayGap: 30)
        )

        XCTAssertEqual(result.displayPoints.map(\.source), [
            .iPhoneTrusted,
            .watchDisplayDerived,
            .iPhoneTrusted
        ])
        XCTAssertEqual(result.displayDerivedPoints.map(\.id), [Self.uuid(3)])
        XCTAssertTrue(result.displayDerivedSeparation)
        XCTAssertEqual(result.diagnostics.gapCount, 1)
        XCTAssertTrue(result.diagnostics.diagnostics.contains { $0.kind == .watchContinuityApplied })
        XCTAssertEqual(result.trustedMetricMutationCount, 0)
        XCTAssertEqual(result.routeGeometryMutationCount, 0)
    }

    func testOverlappingNonConflictingWatchSampleIsIgnoredForContinuity() {
        let iPhone = Self.iPhoneSample(id: 1, timestamp: 100, value: 10.0)
        let watch = Self.watchSample(id: 2, timestamp: 100.5, value: 10.1)

        let result = WatchSampleFusionEngine().makeDisplayFusion(
            iPhoneSamples: [iPhone],
            watchSamples: [watch],
            policy: WatchSampleFusionPolicy(
                maximumAlignmentInterval: 2,
                maximumDisplayGap: 30,
                minimumConflictDelta: 1
            )
        )

        XCTAssertEqual(result.displayPoints.map(\.source), [.iPhoneTrusted])
        XCTAssertEqual(result.displayDerivedPoints.count, 0)
        XCTAssertEqual(result.diagnostics.conflictCount, 0)
        XCTAssertTrue(result.diagnostics.diagnostics.contains { $0.kind == .watchSampleIgnored })
    }

    func testPolicyCanDisableWatchDisplayContinuity() {
        let watch = Self.watchSample(id: 1, timestamp: 100, value: 10)

        let result = WatchSampleFusionEngine().makeDisplayFusion(
            iPhoneSamples: [],
            watchSamples: [watch],
            policy: WatchSampleFusionPolicy(allowsWatchDisplayContinuity: false)
        )

        XCTAssertEqual(result.displayPoints.count, 0)
        XCTAssertEqual(result.displayDerivedPoints.count, 0)
        XCTAssertTrue(result.diagnostics.diagnostics.contains { $0.kind == .watchSampleIgnored })
        XCTAssertEqual(result.trustedMetricMutationCount, 0)
        XCTAssertEqual(result.routeGeometryMutationCount, 0)
    }

    private static func iPhoneSample(
        id: Int,
        timestamp: TimeInterval,
        value: Double,
        kind: WatchSensorSampleKind = .speed,
        unitSymbol: String = "km/h"
    ) -> WatchSampleFusionInput {
        WatchSampleFusionInput(
            id: uuid(id),
            kind: kind,
            timestamp: Date(timeIntervalSince1970: timestamp),
            numericValue: value,
            unitSymbol: unitSymbol
        )
    }

    private static func watchSample(
        id: Int,
        timestamp: TimeInterval,
        value: Double,
        kind: WatchSensorSampleKind = .speed,
        unitSymbol: String = "km/h"
    ) -> WatchIngestedSample {
        let capturedAt = Date(timeIntervalSince1970: 90)
        let snapshot = WatchSensorProviderSnapshot(
            providerKind: .mock,
            availability: .available(at: capturedAt),
            capturedAt: capturedAt,
            samples: [
                WatchSensorSample(
                    id: uuid(id),
                    kind: kind,
                    timestamp: Date(timeIntervalSince1970: timestamp),
                    numericValue: value,
                    unitSymbol: unitSymbol,
                    providerKind: .mock,
                    confidence: 0.9
                )
            ]
        )

        return WatchSampleIngestor().ingest(snapshot: snapshot).samples[0]
    }

    private static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
