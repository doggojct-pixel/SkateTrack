// [Collaboration] Tests/iOSTests/WatchSampleIngestionTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchSampleIngestionTests: XCTestCase {
    func testIngestorSortsSamplesAndPreservesSourceAttribution() {
        let capturedAt = Date(timeIntervalSince1970: 1_000)
        let snapshot = WatchSensorProviderSnapshot(
            providerKind: .mock,
            availability: .available(at: capturedAt),
            capturedAt: capturedAt,
            samples: [
                Self.sample(id: 2, timestamp: 120, kind: .speed, unitSymbol: "m/s"),
                Self.sample(id: 1, timestamp: 100, kind: .motion, unitSymbol: "g")
            ]
        )

        let result = WatchSampleIngestor().ingest(snapshot: snapshot)

        XCTAssertEqual(result.samples.map(\.id), [Self.uuid(1), Self.uuid(2)])
        XCTAssertEqual(result.samples.map(\.timestamp), [
            Date(timeIntervalSince1970: 100),
            Date(timeIntervalSince1970: 120)
        ])
        XCTAssertEqual(result.samples[0].kind, .motion)
        XCTAssertEqual(result.samples[0].unitSymbol, "g")
        XCTAssertEqual(result.samples[1].kind, .speed)
        XCTAssertEqual(result.samples[1].unitSymbol, "m/s")
        XCTAssertEqual(result.samples.map(\.sourceAttribution.providerKind), [.mock, .mock])
        XCTAssertEqual(result.sourceAttribution.capturedAt, capturedAt)
        XCTAssertEqual(result.sourceAttribution.availabilityStatus, .available)
        XCTAssertTrue(result.issues.contains { $0.kind == .outOfOrderSample })
    }

    func testIngestorReportsGapsWithoutDroppingSamples() {
        let snapshot = Self.availableSnapshot(samples: [
            Self.sample(id: 1, timestamp: 100),
            Self.sample(id: 2, timestamp: 145),
            Self.sample(id: 3, timestamp: 150)
        ])

        let result = WatchSampleIngestor().ingest(
            snapshot: snapshot,
            policy: WatchSampleIngestionPolicy(maximumExpectedSampleGap: 30)
        )

        XCTAssertEqual(result.sampleCount, 3)
        XCTAssertEqual(result.issues.filter { $0.kind == .sampleGap }.count, 1)
        XCTAssertEqual(result.issues.first { $0.kind == .sampleGap }?.sampleID, Self.uuid(2))
    }

    func testIngestorDropsDuplicateIDsAndReportsIssue() {
        let duplicatedID = Self.uuid(10)
        let snapshot = Self.availableSnapshot(samples: [
            Self.sample(id: duplicatedID, timestamp: 100, numericValue: 10),
            Self.sample(id: 11, timestamp: 101, numericValue: 11),
            Self.sample(id: duplicatedID, timestamp: 102, numericValue: 12)
        ])

        let result = WatchSampleIngestor().ingest(snapshot: snapshot)

        XCTAssertEqual(result.samples.map(\.id), [duplicatedID, Self.uuid(11)])
        XCTAssertEqual(result.samples.map(\.numericValue), [10, 11])
        XCTAssertEqual(result.issues.filter { $0.kind == .duplicateSample }.count, 1)
        XCTAssertEqual(result.issues.first { $0.kind == .duplicateSample }?.sampleID, duplicatedID)
    }

    func testIngestorRejectsUnavailableSnapshot() {
        let capturedAt = Date(timeIntervalSince1970: 300)
        let snapshot = WatchSensorProviderSnapshot(
            providerKind: .disabled,
            availability: .disabled(at: capturedAt),
            capturedAt: capturedAt,
            samples: [Self.sample(id: 1, timestamp: 300)]
        )

        let result = WatchSampleIngestor().ingest(snapshot: snapshot)

        XCTAssertEqual(result.sampleCount, 0)
        XCTAssertEqual(result.issues.map(\.kind), [.unusableSnapshot])
        XCTAssertEqual(result.sourceAttribution.providerKind, .disabled)
        XCTAssertEqual(result.sourceAttribution.availabilityStatus, .disabled)
        XCTAssertEqual(result.sourceAttribution.unavailableReason, .providerDisabled)
    }

    func testIngestionDoesNotMutateTrustedMetricsOrRouteGeometry() {
        let snapshot = Self.availableSnapshot(samples: [
            Self.sample(id: 1, timestamp: 100),
            Self.sample(id: 2, timestamp: 101)
        ])

        let result = WatchSampleIngestor().ingest(snapshot: snapshot)

        XCTAssertEqual(result.trustedMetricMutationCount, 0)
        XCTAssertEqual(result.routeGeometryMutationCount, 0)
    }

    private static func availableSnapshot(samples: [WatchSensorSample]) -> WatchSensorProviderSnapshot {
        let capturedAt = Date(timeIntervalSince1970: 90)
        return WatchSensorProviderSnapshot(
            providerKind: .mock,
            availability: .available(at: capturedAt),
            capturedAt: capturedAt,
            samples: samples
        )
    }

    private static func sample(
        id: Int,
        timestamp: TimeInterval,
        kind: WatchSensorSampleKind = .motion,
        unitSymbol: String = "unit",
        numericValue: Double? = nil
    ) -> WatchSensorSample {
        sample(
            id: uuid(id),
            timestamp: timestamp,
            kind: kind,
            unitSymbol: unitSymbol,
            numericValue: numericValue ?? Double(id)
        )
    }

    private static func sample(
        id: UUID,
        timestamp: TimeInterval,
        kind: WatchSensorSampleKind = .motion,
        unitSymbol: String = "unit",
        numericValue: Double
    ) -> WatchSensorSample {
        WatchSensorSample(
            id: id,
            kind: kind,
            timestamp: Date(timeIntervalSince1970: timestamp),
            numericValue: numericValue,
            unitSymbol: unitSymbol,
            providerKind: .mock,
            confidence: 0.85
        )
    }

    private static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
