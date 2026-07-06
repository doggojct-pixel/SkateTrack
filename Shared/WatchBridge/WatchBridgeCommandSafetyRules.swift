// [協作區] Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift

import Foundation

public struct WatchBridgeCommandSafetyContext: Codable, Equatable, Sendable {
    public let iPhoneActionInProgress: Bool
    public let latestAcceptedCommandIssuedAt: Date?
    public let connectionState: WatchBridgeConnectionState?
    public let requiresReachableWatch: Bool

    public init(
        iPhoneActionInProgress: Bool = false,
        latestAcceptedCommandIssuedAt: Date? = nil,
        connectionState: WatchBridgeConnectionState? = nil,
        requiresReachableWatch: Bool = true
    ) {
        self.iPhoneActionInProgress = iPhoneActionInProgress
        self.latestAcceptedCommandIssuedAt = latestAcceptedCommandIssuedAt
        self.connectionState = connectionState
        self.requiresReachableWatch = requiresReachableWatch
    }
}

public struct WatchBridgeCommandSafetyDecision: Codable, Equatable, Sendable {
    public let canForwardToIPhoneAuthority: Bool
    public let rejectionReason: WatchBridgeMirroredCommandRejectionReason?
    public let message: String?

    public init(
        canForwardToIPhoneAuthority: Bool,
        rejectionReason: WatchBridgeMirroredCommandRejectionReason? = nil,
        message: String? = nil
    ) {
        self.canForwardToIPhoneAuthority = canForwardToIPhoneAuthority
        self.rejectionReason = rejectionReason
        self.message = message
    }

    public static var forwardToIPhoneAuthority: Self {
        Self(canForwardToIPhoneAuthority: true)
    }

    public static func reject(
        _ reason: WatchBridgeMirroredCommandRejectionReason,
        message: String
    ) -> Self {
        Self(
            canForwardToIPhoneAuthority: false,
            rejectionReason: reason,
            message: message
        )
    }
}

public struct WatchBridgeCommandSafetyRules: Codable, Equatable, Sendable {
    public init() {}

    public func evaluate(
        request: WatchBridgeMirroredCommandRequest,
        action: WatchBridgeMirroredSessionCommandAction,
        context: WatchBridgeCommandSafetyContext,
        at date: Date = Date()
    ) -> WatchBridgeCommandSafetyDecision {
        if context.iPhoneActionInProgress {
            return .reject(
                .iPhoneActionInProgress,
                message: "iPhone-side session action is already in progress; Watch command must wait for authority"
            )
        }

        if let latestAccepted = context.latestAcceptedCommandIssuedAt,
           request.command.issuedAt < latestAccepted {
            return .reject(
                .outOfOrderCommand,
                message: "Watch command is older than the latest accepted iPhone-authoritative command"
            )
        }

        if context.requiresReachableWatch,
           let connectionState = context.connectionState,
           !isCommandChannelReachable(connectionState) {
            return .reject(
                .watchDisconnected,
                message: "Watch command channel is not currently reachable enough to accept mirrored control"
            )
        }

        _ = action
        _ = date
        return .forwardToIPhoneAuthority
    }

    private func isCommandChannelReachable(_ state: WatchBridgeConnectionState) -> Bool {
        switch state.status {
        case .reachable, .simulator:
            return state.quality != .stale
        case .unavailable, .pairedButUnreachable, .unknown:
            return false
        }
    }
}

public final class WatchBridgeCommandSafetyAuthority<Authority: WatchBridgeMirroredSessionCommandAuthority>: WatchBridgeMirroredSessionCommandAuthority {
    public let authority: Authority
    public let rules: WatchBridgeCommandSafetyRules
    private let contextProvider: () -> WatchBridgeCommandSafetyContext

    public init(
        authority: Authority,
        rules: WatchBridgeCommandSafetyRules = WatchBridgeCommandSafetyRules(),
        contextProvider: @escaping () -> WatchBridgeCommandSafetyContext
    ) {
        self.authority = authority
        self.rules = rules
        self.contextProvider = contextProvider
    }

    public func validate(
        _ request: WatchBridgeMirroredCommandRequest,
        action: WatchBridgeMirroredSessionCommandAction,
        at date: Date
    ) -> WatchBridgeMirroredCommandAuthorityDecision {
        let safetyDecision = rules.evaluate(
            request: request,
            action: action,
            context: contextProvider(),
            at: date
        )

        guard safetyDecision.canForwardToIPhoneAuthority else {
            return .reject(
                reason: safetyDecision.message ?? "mirrored command rejected by command safety rules",
                rejectionReason: safetyDecision.rejectionReason ?? .iPhoneAuthorityRejected
            )
        }

        return authority.validate(request, action: action, at: date)
    }
}
