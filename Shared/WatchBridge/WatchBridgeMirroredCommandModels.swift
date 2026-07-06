// [協作區] Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift

import Foundation

public enum WatchBridgeMirroredSessionCommandAction: String, Codable, Equatable, Sendable {
    case start
    case pause
    case resume
    case stop

    public var requiresExistingSession: Bool {
        switch self {
        case .start:
            return false
        case .pause, .resume, .stop:
            return true
        }
    }
}

public enum WatchBridgeMirroredCommandDecisionState: String, Codable, Equatable, Sendable {
    case accepted
    case rejected
    case duplicate
    case stale
}

public enum WatchBridgeMirroredCommandRejectionReason: String, Codable, Equatable, Sendable {
    case unsupportedCommand
    case invalidDirection
    case staleCommand
    case duplicateCommand
    case missingSessionId
    case iPhoneAuthorityRejected
    case unavailable
    case iPhoneActionInProgress
    case outOfOrderCommand
    case watchDisconnected
}

public struct WatchBridgeMirroredSessionCommandPolicy: Codable, Equatable, Sendable {
    public let maximumCommandAgeSeconds: TimeInterval
    public let requiredSource: WatchBridgeEndpoint
    public let requiredDestination: WatchBridgeEndpoint
    public let requiresSessionIdForExistingSessionActions: Bool

    public init(
        maximumCommandAgeSeconds: TimeInterval = 30,
        requiredSource: WatchBridgeEndpoint = .appleWatch,
        requiredDestination: WatchBridgeEndpoint = .iPhone,
        requiresSessionIdForExistingSessionActions: Bool = true
    ) {
        self.maximumCommandAgeSeconds = maximumCommandAgeSeconds
        self.requiredSource = requiredSource
        self.requiredDestination = requiredDestination
        self.requiresSessionIdForExistingSessionActions = requiresSessionIdForExistingSessionActions
    }
}

public struct WatchBridgeMirroredCommandRequest: Codable, Equatable, Sendable {
    public let command: WatchBridgeCommandEnvelope
    public let receivedAt: Date
    public let maximumAgeSeconds: TimeInterval

    public init(
        command: WatchBridgeCommandEnvelope,
        receivedAt: Date = Date(),
        maximumAgeSeconds: TimeInterval = 30
    ) {
        self.command = command
        self.receivedAt = receivedAt
        self.maximumAgeSeconds = maximumAgeSeconds
    }

    public var commandId: UUID {
        command.commandId
    }

    public var action: WatchBridgeMirroredSessionCommandAction? {
        switch command.kind {
        case .startSession:
            return .start
        case .pauseSession:
            return .pause
        case .resumeSession:
            return .resume
        case .endSession:
            return .stop
        case .requestSnapshot, .prepareSession, .cancelSession:
            return nil
        }
    }

    public var idempotencyKey: String {
        [command.commandId.uuidString, command.kind.rawValue, command.sessionId?.uuidString ?? "none"]
            .joined(separator: ":")
    }

    public func isStale(at date: Date) -> Bool {
        date.timeIntervalSince(command.issuedAt) > maximumAgeSeconds
    }
}

public struct WatchBridgeMirroredCommandAuthorityDecision: Codable, Equatable, Sendable {
    public let accepted: Bool
    public let sessionId: UUID?
    public let reason: String?
    public let rejectionReason: WatchBridgeMirroredCommandRejectionReason?

    public init(
        accepted: Bool,
        sessionId: UUID? = nil,
        reason: String? = nil,
        rejectionReason: WatchBridgeMirroredCommandRejectionReason? = nil
    ) {
        self.accepted = accepted
        self.sessionId = sessionId
        self.reason = reason
        self.rejectionReason = rejectionReason
    }

    public static func accept(sessionId: UUID? = nil) -> Self {
        Self(accepted: true, sessionId: sessionId)
    }

    public static func reject(
        reason: String,
        rejectionReason: WatchBridgeMirroredCommandRejectionReason = .iPhoneAuthorityRejected
    ) -> Self {
        Self(accepted: false, reason: reason, rejectionReason: rejectionReason)
    }
}

public struct WatchBridgeMirroredCommandDecision: Codable, Equatable, Sendable {
    public let commandId: UUID
    public let action: WatchBridgeMirroredSessionCommandAction?
    public let state: WatchBridgeMirroredCommandDecisionState
    public let rejectionReason: WatchBridgeMirroredCommandRejectionReason?
    public let message: String?
    public let decidedAt: Date
    public let sessionId: UUID?
    public let idempotencyKey: String

    public init(
        commandId: UUID,
        action: WatchBridgeMirroredSessionCommandAction?,
        state: WatchBridgeMirroredCommandDecisionState,
        rejectionReason: WatchBridgeMirroredCommandRejectionReason? = nil,
        message: String? = nil,
        decidedAt: Date = Date(),
        sessionId: UUID? = nil,
        idempotencyKey: String
    ) {
        self.commandId = commandId
        self.action = action
        self.state = state
        self.rejectionReason = rejectionReason
        self.message = message
        self.decidedAt = decidedAt
        self.sessionId = sessionId
        self.idempotencyKey = idempotencyKey
    }

    public var acknowledgementPayload: WatchBridgeCommandAcknowledgementPayload {
        WatchBridgeCommandAcknowledgementPayload(
            commandId: commandId,
            result: acknowledgementResult,
            acknowledgedAt: decidedAt,
            sessionId: sessionId,
            reason: acknowledgementReason
        )
    }

    private var acknowledgementResult: WatchBridgeCommandResult {
        switch state {
        case .accepted:
            return .accepted
        case .duplicate:
            return .ignored
        case .rejected, .stale:
            return .rejected
        }
    }

    private var acknowledgementReason: String? {
        message ?? rejectionReason?.rawValue
    }
}
