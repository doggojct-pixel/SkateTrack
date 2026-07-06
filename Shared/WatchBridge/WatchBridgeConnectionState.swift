// [協作區] Shared/WatchBridge/WatchBridgeConnectionState.swift

import Foundation

public enum WatchBridgeConnectionStatus: String, Codable, Equatable, Sendable {
    case unavailable
    case reachable
    case pairedButUnreachable
    case simulator
    case unknown
}

public enum WatchBridgeTransportQuality: String, Codable, Equatable, Sendable {
    case fresh
    case delayed
    case stale
    case unknown
}

public struct WatchBridgeConnectionState: Codable, Equatable, Sendable {
    public let status: WatchBridgeConnectionStatus
    public let quality: WatchBridgeTransportQuality
    public let lastUpdatedAt: Date
    public let lastReceivedMessageAt: Date?
    public let explanation: String?

    public init(
        status: WatchBridgeConnectionStatus,
        quality: WatchBridgeTransportQuality = .unknown,
        lastUpdatedAt: Date = Date(),
        lastReceivedMessageAt: Date? = nil,
        explanation: String? = nil
    ) {
        self.status = status
        self.quality = quality
        self.lastUpdatedAt = lastUpdatedAt
        self.lastReceivedMessageAt = lastReceivedMessageAt
        self.explanation = explanation
    }
}
