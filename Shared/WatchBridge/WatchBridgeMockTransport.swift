// [協作區] Shared/WatchBridge/WatchBridgeMockTransport.swift

import Foundation

public enum WatchBridgeMockTransportSendResult: Codable, Equatable, Sendable {
    case queued(messageId: UUID)
    case rejected(
        messageId: UUID,
        status: WatchBridgeConnectionStatus,
        quality: WatchBridgeTransportQuality,
        reason: String?
    )
}

public struct WatchBridgeMockTransport: Codable, Equatable, Sendable {
    public private(set) var connectionStore: WatchBridgeConnectionStateStore
    public private(set) var outboundEnvelopes: [WatchBridgeEnvelope]
    public private(set) var rejectedOutboundEnvelopes: [WatchBridgeEnvelope]
    public private(set) var inboundEnvelopes: [WatchBridgeEnvelope]

    public init(
        connectionStore: WatchBridgeConnectionStateStore = WatchBridgeConnectionStateStore(),
        outboundEnvelopes: [WatchBridgeEnvelope] = [],
        rejectedOutboundEnvelopes: [WatchBridgeEnvelope] = [],
        inboundEnvelopes: [WatchBridgeEnvelope] = []
    ) {
        self.connectionStore = connectionStore
        self.outboundEnvelopes = outboundEnvelopes
        self.rejectedOutboundEnvelopes = rejectedOutboundEnvelopes
        self.inboundEnvelopes = inboundEnvelopes
    }

    public var state: WatchBridgeConnectionState {
        connectionStore.state
    }

    public var timeline: WatchBridgeConnectionTimeline {
        connectionStore.timeline
    }

    public var canSend: Bool {
        state.status == .reachable && state.quality != .stale
    }

    @discardableResult
    public mutating func connect(
        at date: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = "mock transport connected"
    ) -> WatchBridgeConnectionState {
        connectionStore.apply(.connected(at: date, endpoint: endpoint, explanation: explanation))
    }

    @discardableResult
    public mutating func disconnect(
        at date: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = "mock transport disconnected"
    ) -> WatchBridgeConnectionState {
        connectionStore.apply(.disconnected(at: date, endpoint: endpoint, explanation: explanation))
    }

    @discardableResult
    public mutating func markUnavailable(
        at date: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = "mock transport unavailable"
    ) -> WatchBridgeConnectionState {
        connectionStore.apply(.unavailable(at: date, endpoint: endpoint, explanation: explanation))
    }

    @discardableResult
    public mutating func markStale(
        at date: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = "mock transport stale"
    ) -> WatchBridgeConnectionState {
        connectionStore.apply(.stale(at: date, endpoint: endpoint, explanation: explanation))
    }

    @discardableResult
    public mutating func receive(
        _ envelope: WatchBridgeEnvelope,
        at date: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch
    ) -> WatchBridgeConnectionState {
        inboundEnvelopes.append(envelope)
        return connectionStore.apply(.messageReceived(at: date, endpoint: endpoint, explanation: "mock transport received envelope"))
    }

    @discardableResult
    public mutating func send(_ envelope: WatchBridgeEnvelope) -> WatchBridgeMockTransportSendResult {
        guard canSend else {
            rejectedOutboundEnvelopes.append(envelope)
            return .rejected(
                messageId: envelope.messageId,
                status: state.status,
                quality: state.quality,
                reason: state.explanation
            )
        }
        outboundEnvelopes.append(envelope)
        return .queued(messageId: envelope.messageId)
    }

    public func snapshotPayload(reportedAt: Date = Date()) -> WatchBridgeConnectionStatusPayload {
        connectionStore.snapshotPayload(reportedAt: reportedAt)
    }
}
