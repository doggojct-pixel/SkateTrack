// [協作區] Shared/WatchBridge/WatchBridgeConnectionStateStore.swift

import Foundation

public struct WatchBridgeConnectionStateStore: Codable, Equatable, Sendable {
    public private(set) var currentState: WatchBridgeConnectionState
    public private(set) var timeline: WatchBridgeConnectionTimeline

    public init(
        initialState: WatchBridgeConnectionState = WatchBridgeConnectionStateStore.defaultInitialState(),
        timeline: WatchBridgeConnectionTimeline = WatchBridgeConnectionTimeline()
    ) {
        self.currentState = initialState
        self.timeline = timeline
    }

    public var state: WatchBridgeConnectionState {
        currentState
    }

    public static func defaultInitialState(at date: Date = Date()) -> WatchBridgeConnectionState {
        WatchBridgeConnectionState(
            status: .unknown,
            quality: .unknown,
            lastUpdatedAt: date,
            lastReceivedMessageAt: nil,
            explanation: "mock connection state has not reported yet"
        )
    }

    @discardableResult
    public mutating func apply(_ event: WatchBridgeConnectionTimelineEvent) -> WatchBridgeConnectionState {
        timeline.append(event)
        currentState = derivedState(for: event)
        return currentState
    }

    public func derivedState(for event: WatchBridgeConnectionTimelineEvent) -> WatchBridgeConnectionState {
        switch event.kind {
        case .connected:
            return makeState(
                status: .reachable,
                quality: .fresh,
                event: event,
                lastReceivedMessageAt: currentState.lastReceivedMessageAt
            )
        case .disconnected:
            return makeState(
                status: .pairedButUnreachable,
                quality: .delayed,
                event: event,
                lastReceivedMessageAt: currentState.lastReceivedMessageAt
            )
        case .unavailable:
            return makeState(
                status: .unavailable,
                quality: .unknown,
                event: event,
                lastReceivedMessageAt: currentState.lastReceivedMessageAt
            )
        case .stale:
            return makeState(
                status: currentState.status,
                quality: .stale,
                event: event,
                lastReceivedMessageAt: currentState.lastReceivedMessageAt
            )
        case .messageReceived:
            return makeState(
                status: .reachable,
                quality: .fresh,
                event: event,
                lastReceivedMessageAt: event.occurredAt
            )
        }
    }

    public func snapshotPayload(
        reportedAt: Date = Date(),
        canSendCommands: Bool? = nil,
        canReceiveSnapshots: Bool? = nil
    ) -> WatchBridgeConnectionStatusPayload {
        let canSend = canSendCommands ?? (currentState.status == .reachable && currentState.quality != .stale)
        let canReceive = canReceiveSnapshots ?? (currentState.status == .reachable)
        return WatchBridgeConnectionStatusPayload(
            state: currentState,
            reportedAt: reportedAt,
            canSendCommands: canSend,
            canReceiveSnapshots: canReceive
        )
    }

    private func makeState(
        status: WatchBridgeConnectionStatus,
        quality: WatchBridgeTransportQuality,
        event: WatchBridgeConnectionTimelineEvent,
        lastReceivedMessageAt: Date?
    ) -> WatchBridgeConnectionState {
        WatchBridgeConnectionState(
            status: status,
            quality: quality,
            lastUpdatedAt: event.occurredAt,
            lastReceivedMessageAt: lastReceivedMessageAt,
            explanation: event.explanation
        )
    }
}
