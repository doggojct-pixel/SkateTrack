// [協作區] Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift

import Foundation

public protocol WatchBridgeMirroredSessionCommandAuthority: AnyObject {
    func validate(
        _ request: WatchBridgeMirroredCommandRequest,
        action: WatchBridgeMirroredSessionCommandAction,
        at date: Date
    ) -> WatchBridgeMirroredCommandAuthorityDecision
}

public struct WatchBridgeMirroredCommandRoundTrip: Equatable {
    public let decision: WatchBridgeMirroredCommandDecision
    public let acknowledgementEnvelope: WatchBridgeEnvelope

    public init(
        decision: WatchBridgeMirroredCommandDecision,
        acknowledgementEnvelope: WatchBridgeEnvelope
    ) {
        self.decision = decision
        self.acknowledgementEnvelope = acknowledgementEnvelope
    }
}

public struct WatchBridgeMirroredCommandProcessor<Authority: WatchBridgeMirroredSessionCommandAuthority> {
    public private(set) var completedCommandIds: Set<UUID>
    public private(set) var decisions: [WatchBridgeMirroredCommandDecision]
    public let policy: WatchBridgeMirroredSessionCommandPolicy
    public let authority: Authority

    public init(
        authority: Authority,
        policy: WatchBridgeMirroredSessionCommandPolicy = WatchBridgeMirroredSessionCommandPolicy(),
        completedCommandIds: Set<UUID> = [],
        decisions: [WatchBridgeMirroredCommandDecision] = []
    ) {
        self.authority = authority
        self.policy = policy
        self.completedCommandIds = completedCommandIds
        self.decisions = decisions
    }

    @discardableResult
    public mutating func processEnvelope(
        _ envelope: WatchBridgeEnvelope,
        receivedAt: Date = Date(),
        decidedAt: Date = Date()
    ) -> WatchBridgeMirroredCommandRoundTrip {
        let decision: WatchBridgeMirroredCommandDecision

        guard case .command(let command) = envelope.payload else {
            decision = makeEnvelopeRejectionDecision(
                envelope: envelope,
                reason: .unsupportedCommand,
                message: "envelope does not contain a mirrored session command",
                decidedAt: decidedAt
            )
            decisions.append(decision)
            return roundTrip(for: envelope, decision: decision)
        }

        let request = WatchBridgeMirroredCommandRequest(
            command: command,
            receivedAt: receivedAt,
            maximumAgeSeconds: policy.maximumCommandAgeSeconds
        )

        if envelope.source != policy.requiredSource || envelope.destination != policy.requiredDestination {
            decision = reject(
                request,
                action: request.action,
                reason: .invalidDirection,
                message: "mirrored commands must be watch-initiated and validated by iPhone authority",
                decidedAt: decidedAt
            )
        } else {
            decision = process(request, decidedAt: decidedAt)
        }

        return roundTrip(for: envelope, decision: decision)
    }

    @discardableResult
    public mutating func process(
        _ request: WatchBridgeMirroredCommandRequest,
        decidedAt: Date = Date()
    ) -> WatchBridgeMirroredCommandDecision {
        if completedCommandIds.contains(request.commandId) {
            let decision = duplicate(request, decidedAt: decidedAt)
            decisions.append(decision)
            return decision
        }

        guard let action = request.action else {
            let decision = reject(
                request,
                action: nil,
                reason: .unsupportedCommand,
                message: "command kind is not a mirrored session action",
                decidedAt: decidedAt
            )
            markCompleted(request.commandId)
            decisions.append(decision)
            return decision
        }

        if request.isStale(at: decidedAt) {
            let decision = reject(
                request,
                action: action,
                reason: .staleCommand,
                message: "command is older than the mirrored command stale policy",
                decidedAt: decidedAt,
                state: .stale
            )
            markCompleted(request.commandId)
            decisions.append(decision)
            return decision
        }

        if policy.requiresSessionIdForExistingSessionActions,
           action.requiresExistingSession,
           request.command.sessionId == nil {
            let decision = reject(
                request,
                action: action,
                reason: .missingSessionId,
                message: "pause/resume/stop commands require an iPhone-authoritative session id",
                decidedAt: decidedAt
            )
            markCompleted(request.commandId)
            decisions.append(decision)
            return decision
        }

        let authorityDecision = authority.validate(request, action: action, at: decidedAt)
        if authorityDecision.accepted {
            let decision = WatchBridgeMirroredCommandDecision(
                commandId: request.commandId,
                action: action,
                state: .accepted,
                decidedAt: decidedAt,
                sessionId: authorityDecision.sessionId ?? request.command.sessionId,
                idempotencyKey: request.idempotencyKey
            )
            markCompleted(request.commandId)
            decisions.append(decision)
            return decision
        }

        let decision = reject(
            request,
            action: action,
            reason: authorityDecision.rejectionReason ?? .iPhoneAuthorityRejected,
            message: authorityDecision.reason ?? "iPhone authority rejected mirrored command",
            decidedAt: decidedAt,
            sessionId: authorityDecision.sessionId
        )
        markCompleted(request.commandId)
        decisions.append(decision)
        return decision
    }

    private mutating func markCompleted(_ commandId: UUID) {
        completedCommandIds.insert(commandId)
    }

    private func duplicate(
        _ request: WatchBridgeMirroredCommandRequest,
        decidedAt: Date
    ) -> WatchBridgeMirroredCommandDecision {
        WatchBridgeMirroredCommandDecision(
            commandId: request.commandId,
            action: request.action,
            state: .duplicate,
            rejectionReason: .duplicateCommand,
            message: "duplicate mirrored command ignored by idempotency guard",
            decidedAt: decidedAt,
            sessionId: request.command.sessionId,
            idempotencyKey: request.idempotencyKey
        )
    }

    private func reject(
        _ request: WatchBridgeMirroredCommandRequest,
        action: WatchBridgeMirroredSessionCommandAction?,
        reason: WatchBridgeMirroredCommandRejectionReason,
        message: String?,
        decidedAt: Date,
        state: WatchBridgeMirroredCommandDecisionState = .rejected,
        sessionId: UUID? = nil
    ) -> WatchBridgeMirroredCommandDecision {
        WatchBridgeMirroredCommandDecision(
            commandId: request.commandId,
            action: action,
            state: state,
            rejectionReason: reason,
            message: message,
            decidedAt: decidedAt,
            sessionId: sessionId ?? request.command.sessionId,
            idempotencyKey: request.idempotencyKey
        )
    }

    private func makeEnvelopeRejectionDecision(
        envelope: WatchBridgeEnvelope,
        reason: WatchBridgeMirroredCommandRejectionReason,
        message: String,
        decidedAt: Date
    ) -> WatchBridgeMirroredCommandDecision {
        WatchBridgeMirroredCommandDecision(
            commandId: envelope.messageId,
            action: nil,
            state: .rejected,
            rejectionReason: reason,
            message: message,
            decidedAt: decidedAt,
            sessionId: nil,
            idempotencyKey: envelope.messageId.uuidString
        )
    }

    private func roundTrip(
        for envelope: WatchBridgeEnvelope,
        decision: WatchBridgeMirroredCommandDecision
    ) -> WatchBridgeMirroredCommandRoundTrip {
        let acknowledgement = WatchBridgeEnvelope(
            correlationId: envelope.messageId,
            source: policy.requiredDestination,
            destination: policy.requiredSource,
            payload: .commandResult(decision.acknowledgementPayload)
        )
        return WatchBridgeMirroredCommandRoundTrip(
            decision: decision,
            acknowledgementEnvelope: acknowledgement
        )
    }
}
