// [協作區] Tests/iOSTests/WatchBridgeMockTransportTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchBridgeMockTransportTests: XCTestCase {
    func testMockTransportQueuesOutboundEnvelopeOnlyWhenConnected() {
        var transport = WatchBridgeMockTransport()
        let envelope = makeEnvelope(messageId: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!)

        let rejected = transport.send(envelope)
        XCTAssertEqual(
            rejected,
            .rejected(
                messageId: envelope.messageId,
                status: .unknown,
                quality: .unknown,
                reason: "mock connection state has not reported yet"
            )
        )
        XCTAssertEqual(transport.rejectedOutboundEnvelopes.count, 1)
        XCTAssertTrue(transport.outboundEnvelopes.isEmpty)

        transport.connect(at: Date(timeIntervalSince1970: 1_000))
        let queued = transport.send(envelope)

        XCTAssertEqual(queued, .queued(messageId: envelope.messageId))
        XCTAssertEqual(transport.outboundEnvelopes, [envelope])
    }

    func testMockTransportReceiveUpdatesConnectionFreshnessAndInbox() {
        var transport = WatchBridgeMockTransport()
        let receivedAt = Date(timeIntervalSince1970: 3_000)
        let envelope = makeEnvelope(messageId: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!)

        transport.receive(envelope, at: receivedAt)

        XCTAssertEqual(transport.inboundEnvelopes, [envelope])
        XCTAssertEqual(transport.state.status, .reachable)
        XCTAssertEqual(transport.state.quality, .fresh)
        XCTAssertEqual(transport.state.lastReceivedMessageAt, receivedAt)
        XCTAssertTrue(transport.timeline.contains(kind: .messageReceived))
    }

    func testMockTransportMarksDisconnectedUnavailableAndStaleWithoutRuntimeDependency() {
        var transport = WatchBridgeMockTransport()
        transport.connect(at: Date(timeIntervalSince1970: 4_000))
        transport.disconnect(at: Date(timeIntervalSince1970: 4_010))
        XCTAssertEqual(transport.state.status, .pairedButUnreachable)
        XCTAssertEqual(transport.state.quality, .delayed)

        transport.markUnavailable(at: Date(timeIntervalSince1970: 4_020))
        XCTAssertEqual(transport.state.status, .unavailable)
        XCTAssertEqual(transport.state.quality, .unknown)

        transport.markStale(at: Date(timeIntervalSince1970: 4_030))
        XCTAssertEqual(transport.state.status, .unavailable)
        XCTAssertEqual(transport.state.quality, .stale)
        XCTAssertEqual(
            transport.timeline.events.map(\.kind),
            [.connected, .disconnected, .unavailable, .stale]
        )
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
