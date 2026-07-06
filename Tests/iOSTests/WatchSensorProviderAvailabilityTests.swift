// [協作區] Tests/iOSTests/WatchSensorProviderAvailabilityTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchSensorProviderAvailabilityTests: XCTestCase {
    func testDisabledProviderReportsDisabledUnavailableState() {
        let provider = WatchSensorDisabledProvider(explanation: "not enabled for this build")
        let date = Date(timeIntervalSince1970: 100)

        let availability = provider.availability(at: date)
        let snapshot = provider.snapshot(at: date, maximumSampleCount: 10)

        XCTAssertEqual(provider.kind, .disabled)
        XCTAssertEqual(availability.status, .disabled)
        XCTAssertEqual(availability.reason, .providerDisabled)
        XCTAssertEqual(availability.checkedAt, date)
        XCTAssertFalse(availability.canProvideWatchOriginatedData)
        XCTAssertFalse(snapshot.isUsable)
        XCTAssertEqual(snapshot.sampleCount, 0)
    }

    func testMockProviderReportsAvailableAndLimitsScriptedSamples() {
        let provider = WatchSensorMockProvider(
            scriptedSamples: [
                Self.sample(id: 1, timestamp: 100),
                Self.sample(id: 2, timestamp: 105),
                Self.sample(id: 3, timestamp: 110)
            ],
            reportedAt: Date(timeIntervalSince1970: 90)
        )

        let snapshot = provider.snapshot(
            at: Date(timeIntervalSince1970: 120),
            maximumSampleCount: 2
        )

        XCTAssertEqual(provider.kind, .mock)
        XCTAssertTrue(snapshot.isUsable)
        XCTAssertEqual(snapshot.providerKind, .mock)
        XCTAssertEqual(snapshot.sampleCount, 2)
        XCTAssertEqual(snapshot.samples.map(\.id), [Self.uuid(2), Self.uuid(3)])
    }

    func testMockProviderReturnsNoSamplesWhenAvailabilityIsUnavailable() {
        let provider = WatchSensorMockProvider(
            scriptedAvailability: .unavailable(
                reason: .runtimeUnavailable,
                at: Date(timeIntervalSince1970: 200),
                explanation: "runtime is unavailable"
            ),
            scriptedSamples: [Self.sample(id: 4, timestamp: 200)]
        )

        let snapshot = provider.snapshot(
            at: Date(timeIntervalSince1970: 210),
            maximumSampleCount: 10
        )

        XCTAssertFalse(snapshot.isUsable)
        XCTAssertEqual(snapshot.availability.status, .unavailable)
        XCTAssertEqual(snapshot.availability.reason, .runtimeUnavailable)
        XCTAssertEqual(snapshot.sampleCount, 0)
    }

    func testSampleConfidenceIsClampedToProviderContractRange() {
        let low = Self.sample(id: 5, timestamp: 300, confidence: -1.0)
        let high = Self.sample(id: 6, timestamp: 305, confidence: 2.0)

        XCTAssertEqual(low.confidence, 0.0)
        XCTAssertEqual(high.confidence, 1.0)
    }

    private static func sample(
        id: Int,
        timestamp: TimeInterval,
        confidence: Double = 0.75
    ) -> WatchSensorSample {
        WatchSensorSample(
            id: uuid(id),
            kind: .motion,
            timestamp: Date(timeIntervalSince1970: timestamp),
            numericValue: Double(id),
            unitSymbol: "unit",
            providerKind: .mock,
            confidence: confidence
        )
    }

    private static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
