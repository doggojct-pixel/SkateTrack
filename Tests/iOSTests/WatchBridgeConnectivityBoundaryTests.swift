// [協作區] Tests/iOSTests/WatchBridgeConnectivityBoundaryTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchBridgeConnectivityBoundaryTests: XCTestCase {
    func testSimulatorFallbackReportsAvailabilityAfterActivation() {
        var boundary = WatchBridgeSimulatorFallbackBoundary(
            reportedAt: Date(timeIntervalSince1970: 100)
        )

        XCTAssertFalse(boundary.availability.runtimeSupported)
        XCTAssertEqual(boundary.availability.state.status, .unknown)

        let availability = boundary.activate(at: Date(timeIntervalSince1970: 120))

        XCTAssertFalse(availability.runtimeSupported)
        XCTAssertTrue(availability.runtimeActivated)
        XCTAssertTrue(availability.reachable)
        XCTAssertEqual(availability.state.status, .reachable)
        XCTAssertEqual(availability.state.quality, .fresh)
    }

    func testSimulatorFallbackQueuesEnvelopeOnlyAfterActivation() {
        var boundary = WatchBridgeSimulatorFallbackBoundary(
            reportedAt: Date(timeIntervalSince1970: 200)
        )
        let envelope = makeEnvelope(messageId: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!)

        let rejected = boundary.send(envelope)
        XCTAssertEqual(
            rejected,
            .rejected(
                messageId: envelope.messageId,
                reason: "mock connection state has not reported yet"
            )
        )

        boundary.activate(at: Date(timeIntervalSince1970: 210))
        let queued = boundary.send(envelope)

        XCTAssertEqual(queued, .queued(messageId: envelope.messageId))
        XCTAssertEqual(boundary.mockTransport.outboundEnvelopes, [envelope])
    }

    func testConnectivityAvailabilityCanRepresentRuntimeUnavailableFallback() {
        let reportedAt = Date(timeIntervalSince1970: 300)
        let availability = WatchBridgeConnectivityAvailability.unavailable(
            at: reportedAt,
            explanation: "not supported in this environment"
        )

        XCTAssertFalse(availability.runtimeSupported)
        XCTAssertFalse(availability.runtimeActivated)
        XCTAssertFalse(availability.reachable)
        XCTAssertEqual(availability.state.status, .unavailable)
        XCTAssertEqual(availability.reportedAt, reportedAt)
        XCTAssertEqual(availability.explanation, "not supported in this environment")
    }

    private func makeEnvelope(messageId: UUID) -> WatchBridgeEnvelope {
        WatchBridgeEnvelope(
            messageId: messageId,
            source: .iPhone,
            destination: .appleWatch,
            payload: .connectionState(
                WatchBridgeConnectionState(
                    status: .reachable,
                    quality: .fresh,
                    lastUpdatedAt: Date(timeIntervalSince1970: 500)
                )
            )
        )
    }
}
