// [協作區] Tests/iOSTests/WatchBridgeConnectionStateStoreTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchBridgeConnectionStateStoreTests: XCTestCase {
    func testStoreAppliesConnectedDisconnectedUnavailableAndStaleTransitions() {
        let baseDate = Date(timeIntervalSince1970: 2_000)
        var store = WatchBridgeConnectionStateStore(
            initialState: WatchBridgeConnectionStateStore.defaultInitialState(at: baseDate)
        )

        store.apply(.connected(at: baseDate.addingTimeInterval(1), explanation: "connected"))
        XCTAssertEqual(store.state.status, .reachable)
        XCTAssertEqual(store.state.quality, .fresh)

        store.apply(.disconnected(at: baseDate.addingTimeInterval(2), explanation: "disconnected"))
        XCTAssertEqual(store.state.status, .pairedButUnreachable)
        XCTAssertEqual(store.state.quality, .delayed)

        store.apply(.unavailable(at: baseDate.addingTimeInterval(3), explanation: "unavailable"))
        XCTAssertEqual(store.state.status, .unavailable)
        XCTAssertEqual(store.state.quality, .unknown)

        store.apply(.stale(at: baseDate.addingTimeInterval(4), explanation: "stale"))
        XCTAssertEqual(store.state.status, .unavailable)
        XCTAssertEqual(store.state.quality, .stale)
        XCTAssertEqual(store.timeline.events.map(\.kind), [.connected, .disconnected, .unavailable, .stale])
    }

    func testTimelineRetainsMostRecentEvents() {
        var timeline = WatchBridgeConnectionTimeline(maxEventCount: 2)

        timeline.append(.connected(at: Date(timeIntervalSince1970: 10)))
        timeline.append(.disconnected(at: Date(timeIntervalSince1970: 20)))
        timeline.append(.unavailable(at: Date(timeIntervalSince1970: 30)))

        XCTAssertEqual(timeline.events.map(\.kind), [.disconnected, .unavailable])
        XCTAssertTrue(timeline.contains(kind: .unavailable))
        XCTAssertFalse(timeline.contains(kind: .connected))
    }

    func testSnapshotPayloadUsesSendAndReceiveCapabilitiesFromCurrentState() {
        var store = WatchBridgeConnectionStateStore()
        store.apply(.connected(at: Date(timeIntervalSince1970: 100)))
        let connectedPayload = store.snapshotPayload(reportedAt: Date(timeIntervalSince1970: 101))

        XCTAssertTrue(connectedPayload.canSendCommands)
        XCTAssertTrue(connectedPayload.canReceiveSnapshots)

        store.apply(.stale(at: Date(timeIntervalSince1970: 200)))
        let stalePayload = store.snapshotPayload(reportedAt: Date(timeIntervalSince1970: 201))

        XCTAssertFalse(stalePayload.canSendCommands)
        XCTAssertTrue(stalePayload.canReceiveSnapshots)
        XCTAssertEqual(stalePayload.state.quality, .stale)
    }
}
