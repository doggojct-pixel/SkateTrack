// [協作區] Shared/WatchBridge/WatchBridgeEnvelope.swift

import Foundation

public enum WatchBridgeSchema {
    public static let currentVersion = 1
}

public enum WatchBridgeEndpoint: String, Codable, Equatable, Sendable {
    case iPhone
    case appleWatch
    case simulator
    case unknown
}

public struct WatchBridgeEnvelope: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let messageId: UUID
    public let correlationId: UUID?
    public let createdAt: Date
    public let source: WatchBridgeEndpoint
    public let destination: WatchBridgeEndpoint
    public let payload: WatchBridgePayload

    public init(
        schemaVersion: Int = WatchBridgeSchema.currentVersion,
        messageId: UUID = UUID(),
        correlationId: UUID? = nil,
        createdAt: Date = Date(),
        source: WatchBridgeEndpoint,
        destination: WatchBridgeEndpoint,
        payload: WatchBridgePayload
    ) {
        self.schemaVersion = schemaVersion
        self.messageId = messageId
        self.correlationId = correlationId
        self.createdAt = createdAt
        self.source = source
        self.destination = destination
        self.payload = payload
    }

    public func acknowledgement(accepted: Bool, reason: String? = nil) -> WatchBridgeEnvelope {
        WatchBridgeEnvelope(
            correlationId: messageId,
            source: destination,
            destination: source,
            payload: .acknowledgement(
                WatchBridgeAcknowledgement(
                    acknowledgedMessageId: messageId,
                    accepted: accepted,
                    reason: reason
                )
            )
        )
    }
}
