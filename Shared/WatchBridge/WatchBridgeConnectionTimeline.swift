// [協作區] Shared/WatchBridge/WatchBridgeConnectionTimeline.swift

import Foundation

public enum WatchBridgeConnectionEventKind: String, Codable, Equatable, Sendable {
    case connected
    case disconnected
    case unavailable
    case stale
    case messageReceived
}

public struct WatchBridgeConnectionTimelineEvent: Codable, Equatable, Sendable {
    public let kind: WatchBridgeConnectionEventKind
    public let occurredAt: Date
    public let endpoint: WatchBridgeEndpoint
    public let explanation: String?

    public init(
        kind: WatchBridgeConnectionEventKind,
        occurredAt: Date = Date(),
        endpoint: WatchBridgeEndpoint = .unknown,
        explanation: String? = nil
    ) {
        self.kind = kind
        self.occurredAt = occurredAt
        self.endpoint = endpoint
        self.explanation = explanation
    }

    public static func connected(
        at occurredAt: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = nil
    ) -> Self {
        Self(kind: .connected, occurredAt: occurredAt, endpoint: endpoint, explanation: explanation)
    }

    public static func disconnected(
        at occurredAt: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = nil
    ) -> Self {
        Self(kind: .disconnected, occurredAt: occurredAt, endpoint: endpoint, explanation: explanation)
    }

    public static func unavailable(
        at occurredAt: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = nil
    ) -> Self {
        Self(kind: .unavailable, occurredAt: occurredAt, endpoint: endpoint, explanation: explanation)
    }

    public static func stale(
        at occurredAt: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = nil
    ) -> Self {
        Self(kind: .stale, occurredAt: occurredAt, endpoint: endpoint, explanation: explanation)
    }

    public static func messageReceived(
        at occurredAt: Date = Date(),
        endpoint: WatchBridgeEndpoint = .appleWatch,
        explanation: String? = nil
    ) -> Self {
        Self(kind: .messageReceived, occurredAt: occurredAt, endpoint: endpoint, explanation: explanation)
    }
}

public struct WatchBridgeConnectionTimeline: Codable, Equatable, Sendable {
    public private(set) var events: [WatchBridgeConnectionTimelineEvent]
    public let maxEventCount: Int

    public init(events: [WatchBridgeConnectionTimelineEvent] = [], maxEventCount: Int = 32) {
        self.events = Array(events.suffix(max(1, maxEventCount)))
        self.maxEventCount = max(1, maxEventCount)
    }

    public var latestEvent: WatchBridgeConnectionTimelineEvent? {
        events.last
    }

    public mutating func append(_ event: WatchBridgeConnectionTimelineEvent) {
        events.append(event)
        if events.count > maxEventCount {
            events.removeFirst(events.count - maxEventCount)
        }
    }

    public func contains(kind: WatchBridgeConnectionEventKind) -> Bool {
        events.contains { $0.kind == kind }
    }

    public func events(matching kind: WatchBridgeConnectionEventKind) -> [WatchBridgeConnectionTimelineEvent] {
        events.filter { $0.kind == kind }
    }
}
