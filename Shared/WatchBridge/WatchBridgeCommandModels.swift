// [協作區] Shared/WatchBridge/WatchBridgeCommandModels.swift

import Foundation

public enum WatchBridgeCommandKind: String, Codable, Equatable, Sendable {
    case requestSnapshot
    case prepareSession
    case startSession
    case pauseSession
    case resumeSession
    case endSession
    case cancelSession
}

public enum WatchBridgeSessionState: String, Codable, Equatable, Sendable {
    case idle
    case preparing
    case ready
    case recording
    case paused
    case ending
    case ended
    case failed
}

public struct WatchBridgeCommandEnvelope: Codable, Equatable, Sendable {
    public let commandId: UUID
    public let kind: WatchBridgeCommandKind
    public let issuedAt: Date
    public let sessionId: UUID?
    public let sportModeKey: String?
    public let reason: String?

    public init(
        commandId: UUID = UUID(),
        kind: WatchBridgeCommandKind,
        issuedAt: Date = Date(),
        sessionId: UUID? = nil,
        sportModeKey: String? = nil,
        reason: String? = nil
    ) {
        self.commandId = commandId
        self.kind = kind
        self.issuedAt = issuedAt
        self.sessionId = sessionId
        self.sportModeKey = sportModeKey
        self.reason = reason
    }
}
