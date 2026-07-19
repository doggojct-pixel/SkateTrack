// [協作區] Tests/iOSTests/WatchBridgeRuntimeSnowAdapterTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchBridgeRuntimeFoundationTests: XCTestCase {
    func testInboundDecoderDecodesValidActivityEnvelope() throws {
        let envelope = WatchBridgeRuntimeTestFixtures.metricEnvelope(
            messageId: Self.uuid(1),
            updatedAt: Date(timeIntervalSince1970: 100),
            speed: 4.5
        )
        let data = try JSONEncoder().encode(envelope)

        XCTAssertEqual(try WatchBridgeInboundEnvelopeDecoder().decode(data), envelope)
    }

    func testInboundDecoderRejectsMalformedData() {
        XCTAssertThrowsError(
            try WatchBridgeInboundEnvelopeDecoder().decode(Data("{not-json".utf8))
        )
    }

    func testWCSessionBoundaryDeliversDecodedEnvelopeAndPreservesFreshness() throws {
        guard let boundary = WatchBridgeWCSessionBoundary() else {
            return XCTFail("WatchConnectivity must be supported by the iOS test runtime")
        }
        let receivedAt = Date(timeIntervalSince1970: 150)
        let envelope = WatchBridgeRuntimeTestFixtures.metricEnvelope(
            messageId: Self.uuid(2),
            updatedAt: receivedAt,
            speed: 3
        )
        var delivered: WatchBridgeEnvelope?
        boundary.inboundEnvelopeHandler = { delivered = $0 }

        XCTAssertTrue(
            boundary.handleReceivedMessageData(
                try JSONEncoder().encode(envelope),
                receivedAt: receivedAt
            )
        )
        XCTAssertEqual(delivered, envelope)
        XCTAssertEqual(boundary.availability.state.lastReceivedMessageAt, receivedAt)
    }

    func testWCSessionBoundaryRejectsMalformedDataWithoutCrashing() {
        guard let boundary = WatchBridgeWCSessionBoundary() else {
            return XCTFail("WatchConnectivity must be supported by the iOS test runtime")
        }
        var malformedCallbackCount = 0
        boundary.malformedEnvelopeHandler = { _, _ in malformedCallbackCount += 1 }

        XCTAssertFalse(
            boundary.handleReceivedMessageData(
                Data("not-an-envelope".utf8),
                receivedAt: Date(timeIntervalSince1970: 175)
            )
        )
        XCTAssertEqual(malformedCallbackCount, 1)
    }

    func testOutboundEnvelopeEncodeAndSendPathQueuesAfterActivation() throws {
        let envelope = WatchBridgeRuntimeTestFixtures.metricEnvelope(
            messageId: Self.uuid(3),
            updatedAt: Date(timeIntervalSince1970: 190),
            speed: 2
        )
        let encoded = try JSONEncoder().encode(envelope)
        XCTAssertEqual(try JSONDecoder().decode(WatchBridgeEnvelope.self, from: encoded), envelope)

        var boundary = WatchBridgeSimulatorFallbackBoundary()
        boundary.activate(at: Date(timeIntervalSince1970: 191))
        XCTAssertEqual(boundary.send(envelope), .queued(messageId: envelope.messageId))
        XCTAssertEqual(boundary.mockTransport.outboundEnvelopes, [envelope])
    }

    func testRuntimeAppliesActivitySnapshotComponents() {
        let date = Date(timeIntervalSince1970: 200)
        let sessionId = Self.uuid(4)
        let snapshot = WatchBridgeActivitySnapshotPayload(
            session: WatchBridgeActivitySessionPayload(
                sessionId: sessionId,
                state: .recording,
                mode: WatchBridgeActivityModeDescriptor(sportModeKey: "skateboard"),
                updatedAt: date,
                elapsedSeconds: 12,
                isRecordingAllowed: true
            ),
            metrics: WatchBridgeMetricUpdatePayload(
                sessionId: sessionId,
                updatedAt: date,
                elapsedSeconds: 12,
                distanceMeters: 40,
                currentSpeedMetersPerSecond: 5,
                trustLevel: .trustedSource
            ),
            display: WatchBridgeCompactActivityDisplayPayload(
                generatedAt: date,
                routePointCount: 3,
                hasCompactRoute: true
            ),
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: WatchBridgeConnectionState(
                    status: .reachable,
                    quality: .fresh,
                    lastUpdatedAt: date
                ),
                reportedAt: date,
                canSendCommands: true,
                canReceiveSnapshots: true
            )
        )
        let envelope = WatchBridgeEnvelope(
            messageId: Self.uuid(5),
            createdAt: date,
            source: .iPhone,
            destination: .appleWatch,
            payload: .activitySnapshot(snapshot)
        )
        var state = WatchBridgeRuntimeState()

        XCTAssertEqual(state.apply(envelope), .accepted)
        XCTAssertEqual(state.activitySession, snapshot.session)
        XCTAssertEqual(state.activityMetrics, snapshot.metrics)
        XCTAssertEqual(state.activityDisplay, snapshot.display)
        XCTAssertEqual(state.connectionStatus, snapshot.connectionStatus)
    }

    func testRuntimeRejectsDuplicateMessageIdentifier() {
        let envelope = WatchBridgeRuntimeTestFixtures.metricEnvelope(
            messageId: Self.uuid(6),
            updatedAt: Date(timeIntervalSince1970: 300),
            speed: 2
        )
        var state = WatchBridgeRuntimeState()

        XCTAssertEqual(state.apply(envelope), .accepted)
        XCTAssertEqual(state.apply(envelope), .duplicate)
        XCTAssertEqual(state.activityMetrics?.currentSpeedMetersPerSecond, 2)
    }

    func testRuntimeRejectsOlderMetricPayload() {
        let newer = WatchBridgeRuntimeTestFixtures.metricEnvelope(
            messageId: Self.uuid(7),
            updatedAt: Date(timeIntervalSince1970: 500),
            speed: 7
        )
        let older = WatchBridgeRuntimeTestFixtures.metricEnvelope(
            messageId: Self.uuid(8),
            updatedAt: Date(timeIntervalSince1970: 400),
            speed: 1
        )
        var state = WatchBridgeRuntimeState()

        XCTAssertEqual(state.apply(newer), .accepted)
        XCTAssertEqual(state.apply(older), .stale)
        XCTAssertEqual(state.activityMetrics?.currentSpeedMetersPerSecond, 7)
    }

    func testRuntimeIgnoresEnvelopeForIPhoneDestination() {
        let envelope = WatchBridgeEnvelope(
            messageId: Self.uuid(9),
            source: .appleWatch,
            destination: .iPhone,
            payload: .activityMetrics(
                WatchBridgeMetricUpdatePayload(
                    updatedAt: Date(timeIntervalSince1970: 600),
                    currentSpeedMetersPerSecond: 3
                )
            )
        )
        var state = WatchBridgeRuntimeState()

        XCTAssertEqual(state.apply(envelope), .ignoredDestination)
        XCTAssertNil(state.activityMetrics)
    }

    private static func uuid(_ value: Int) -> UUID {
        WatchBridgeRuntimeTestFixtures.uuid(value)
    }
}

final class WatchBridgeSnowAdapterTests: XCTestCase {
    func testLegacyMetricJSONWithoutSnowFieldsDecodesWithNilExtensions() throws {
        let legacy = LegacyMetricPayload(
            sessionId: Self.uuid(10),
            updatedAt: Date(timeIntervalSince1970: 700),
            elapsedSeconds: 25,
            distanceMeters: 80,
            currentSpeedMetersPerSecond: 5,
            averageSpeedMetersPerSecond: 4,
            elevationGainMeters: nil,
            elevationLossMeters: nil,
            trustLevel: .trustedSource,
            sourceLabel: nil
        )

        let decoded = try JSONDecoder().decode(
            WatchBridgeMetricUpdatePayload.self,
            from: JSONEncoder().encode(legacy)
        )

        XCTAssertEqual(decoded.currentSpeedMetersPerSecond, 5)
        XCTAssertNil(decoded.snowSchemaVersion)
        XCTAssertNil(decoded.snowRunNumber)
        XCTAssertNil(decoded.snowTotalSkiDistanceMeters)
    }

    func testLegacyDecoderIgnoresNewSnowFields() throws {
        let legacy = try JSONDecoder().decode(
            LegacyMetricPayload.self,
            from: JSONEncoder().encode(Self.snowMetricPayload())
        )

        XCTAssertEqual(legacy.currentSpeedMetersPerSecond, 6)
        XCTAssertEqual(legacy.distanceMeters, 1_200)
    }

    func testNonSnowMetricMappingKeepsSnowStateEmpty() {
        let payload = WatchBridgeMetricUpdatePayload(
            currentSpeedMetersPerSecond: 5,
            trustLevel: .trustedSource
        )

        let snapshot = WatchBridgeSnowSnapshotMapper().makeSnapshot(from: payload)

        XCTAssertEqual(snapshot.currentSpeedKmh, 18)
        XCTAssertEqual(snapshot.maxSpeedThisRunKmh, 0)
        XCTAssertNil(snapshot.snowSchemaVersion)
        XCTAssertNil(snapshot.snowRunNumber)
        XCTAssertEqual(snapshot.totalRunsToday, 0)
    }

    func testSnowMetricMappingPopulatesApprovedFields() {
        let snapshot = WatchBridgeSnowSnapshotMapper().makeSnapshot(
            from: Self.snowMetricPayload()
        )

        XCTAssertEqual(snapshot.currentSpeedKmh, 21.6, accuracy: 0.0001)
        XCTAssertEqual(snapshot.maxSpeedThisRunKmh, 48)
        XCTAssertEqual(snapshot.snowRunNumber, 3)
        XCTAssertEqual(snapshot.snowVerticalDropMeters, 126)
        XCTAssertNil(snapshot.snowTotalVerticalMeters)
        XCTAssertNil(snapshot.snowSlopeAngleDegrees)
        XCTAssertEqual(snapshot.snowSegmentType, "downhillRun")
        XCTAssertEqual(snapshot.snowSchemaVersion, "1.1")
        XCTAssertEqual(snapshot.totalRunsToday, 2)
        XCTAssertEqual(snapshot.totalSkiDistanceMeters, 1_050)
        XCTAssertEqual(snapshot.totalLiftDistanceMeters, 430)
        XCTAssertNil(snapshot.averageRunDurationSeconds)
        XCTAssertEqual(snapshot.lastRunVerticalDropMeters, 110)
        XCTAssertEqual(snapshot.lastRunTopSpeedKmh, 44)
        XCTAssertEqual(snapshot.lastRunDurationSeconds, 72)
    }

    func testPartialSnowMetricMappingUsesNilAndZeroSafeDefaults() {
        let payload = WatchBridgeMetricUpdatePayload(
            currentSpeedMetersPerSecond: 2,
            snowSchemaVersion: "1.1",
            snowRunCount: 1
        )

        let snapshot = WatchBridgeSnowSnapshotMapper().makeSnapshot(from: payload)

        XCTAssertEqual(snapshot.currentSpeedKmh, 7.2, accuracy: 0.0001)
        XCTAssertEqual(snapshot.maxSpeedThisRunKmh, 0)
        XCTAssertNil(snapshot.snowRunNumber)
        XCTAssertEqual(snapshot.totalRunsToday, 1)
        XCTAssertEqual(snapshot.totalSkiDistanceMeters, 0)
        XCTAssertNil(snapshot.lastRunDurationSeconds)
    }

    private static func snowMetricPayload() -> WatchBridgeMetricUpdatePayload {
        WatchBridgeMetricUpdatePayload(
            sessionId: uuid(11),
            updatedAt: Date(timeIntervalSince1970: 800),
            elapsedSeconds: 120,
            distanceMeters: 1_200,
            currentSpeedMetersPerSecond: 6,
            averageSpeedMetersPerSecond: 4,
            trustLevel: .trustedSource,
            snowSchemaVersion: "1.1",
            snowMaxSpeedThisRunKmh: 48,
            snowRunNumber: 3,
            snowVerticalDropMeters: 126,
            snowSegmentType: "downhillRun",
            snowRunCount: 2,
            snowTotalSkiDistanceMeters: 1_050,
            snowTotalLiftDistanceMeters: 430,
            snowLastRunVerticalDropMeters: 110,
            snowLastRunTopSpeedKmh: 44,
            snowLastRunDurationSeconds: 72
        )
    }

    private static func uuid(_ value: Int) -> UUID {
        WatchBridgeRuntimeTestFixtures.uuid(value)
    }
}

private enum WatchBridgeRuntimeTestFixtures {
    static func metricEnvelope(
        messageId: UUID,
        updatedAt: Date,
        speed: Double
    ) -> WatchBridgeEnvelope {
        WatchBridgeEnvelope(
            messageId: messageId,
            createdAt: updatedAt,
            source: .iPhone,
            destination: .appleWatch,
            payload: .activityMetrics(
                WatchBridgeMetricUpdatePayload(
                    updatedAt: updatedAt,
                    currentSpeedMetersPerSecond: speed,
                    trustLevel: .trustedSource
                )
            )
        )
    }

    static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}

private struct LegacyMetricPayload: Codable {
    let sessionId: UUID?
    let updatedAt: Date
    let elapsedSeconds: TimeInterval
    let distanceMeters: Double?
    let currentSpeedMetersPerSecond: Double?
    let averageSpeedMetersPerSecond: Double?
    let elevationGainMeters: Double?
    let elevationLossMeters: Double?
    let trustLevel: WatchBridgeMetricTrustLevel
    let sourceLabel: String?
}
