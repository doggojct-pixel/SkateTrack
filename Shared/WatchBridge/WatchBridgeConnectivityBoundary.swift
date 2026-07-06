// [協作區] Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift

import Foundation

public struct WatchBridgeConnectivityAvailability: Codable, Equatable, Sendable {
    public let state: WatchBridgeConnectionState
    public let runtimeSupported: Bool
    public let runtimeActivated: Bool
    public let paired: Bool?
    public let reachable: Bool
    public let reportedAt: Date
    public let explanation: String?

    public init(
        state: WatchBridgeConnectionState,
        runtimeSupported: Bool,
        runtimeActivated: Bool,
        paired: Bool? = nil,
        reachable: Bool,
        reportedAt: Date = Date(),
        explanation: String? = nil
    ) {
        self.state = state
        self.runtimeSupported = runtimeSupported
        self.runtimeActivated = runtimeActivated
        self.paired = paired
        self.reachable = reachable
        self.reportedAt = reportedAt
        self.explanation = explanation
    }

    public static func simulatorFallback(
        state: WatchBridgeConnectionState,
        reportedAt: Date = Date(),
        explanation: String? = "simulator fallback boundary"
    ) -> Self {
        Self(
            state: state,
            runtimeSupported: false,
            runtimeActivated: true,
            paired: nil,
            reachable: state.status == .reachable,
            reportedAt: reportedAt,
            explanation: explanation
        )
    }

    public static func unavailable(
        at reportedAt: Date = Date(),
        explanation: String? = "connectivity runtime unavailable"
    ) -> Self {
        let state = WatchBridgeConnectionState(
            status: .unavailable,
            quality: .unknown,
            lastUpdatedAt: reportedAt,
            explanation: explanation
        )
        return Self(
            state: state,
            runtimeSupported: false,
            runtimeActivated: false,
            paired: nil,
            reachable: false,
            reportedAt: reportedAt,
            explanation: explanation
        )
    }
}

public enum WatchBridgeConnectivitySendResult: Codable, Equatable, Sendable {
    case queued(messageId: UUID)
    case rejected(messageId: UUID, reason: String)
}

public protocol WatchBridgeConnectivityBoundary {
    var availability: WatchBridgeConnectivityAvailability { get }

    @discardableResult
    mutating func activate(at date: Date) -> WatchBridgeConnectivityAvailability

    @discardableResult
    mutating func refreshAvailability(at date: Date) -> WatchBridgeConnectivityAvailability

    @discardableResult
    mutating func send(_ envelope: WatchBridgeEnvelope) -> WatchBridgeConnectivitySendResult
}

public struct WatchBridgeSimulatorFallbackBoundary: WatchBridgeConnectivityBoundary, Equatable, Sendable {
    public private(set) var mockTransport: WatchBridgeMockTransport
    public private(set) var latestAvailability: WatchBridgeConnectivityAvailability

    public init(
        mockTransport: WatchBridgeMockTransport = WatchBridgeMockTransport(),
        reportedAt: Date = Date()
    ) {
        self.mockTransport = mockTransport
        self.latestAvailability = WatchBridgeConnectivityAvailability.simulatorFallback(
            state: mockTransport.state,
            reportedAt: reportedAt
        )
    }

    public var availability: WatchBridgeConnectivityAvailability {
        latestAvailability
    }

    @discardableResult
    public mutating func activate(at date: Date = Date()) -> WatchBridgeConnectivityAvailability {
        mockTransport.connect(
            at: date,
            endpoint: .simulator,
            explanation: "simulator fallback boundary activated"
        )
        return refreshAvailability(at: date)
    }

    @discardableResult
    public mutating func refreshAvailability(at date: Date = Date()) -> WatchBridgeConnectivityAvailability {
        latestAvailability = WatchBridgeConnectivityAvailability.simulatorFallback(
            state: mockTransport.state,
            reportedAt: date,
            explanation: "simulator fallback boundary"
        )
        return latestAvailability
    }

    @discardableResult
    public mutating func send(_ envelope: WatchBridgeEnvelope) -> WatchBridgeConnectivitySendResult {
        switch mockTransport.send(envelope) {
        case .queued(let messageId):
            refreshAvailability(at: Date())
            return .queued(messageId: messageId)
        case .rejected(_, _, _, let reason):
            refreshAvailability(at: Date())
            return .rejected(
                messageId: envelope.messageId,
                reason: reason ?? "simulator fallback boundary is not reachable"
            )
        }
    }
}
