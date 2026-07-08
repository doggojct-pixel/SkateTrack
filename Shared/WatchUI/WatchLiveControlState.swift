// [Collaboration] Shared/WatchUI/WatchLiveControlState.swift
// Purpose: Defines watch live-session control state and command-boundary output for Task-036b.
// Delegates to: WatchBridge mirrored session command contracts owned by Task-033.

import Foundation

enum WatchLiveControlActionKind: String, CaseIterable, Equatable, Sendable {
    case start
    case pause
    case resume
    case stop

    var commandKind: WatchBridgeCommandKind {
        switch self {
        case .start:
            return .startSession
        case .pause:
            return .pauseSession
        case .resume:
            return .resumeSession
        case .stop:
            return .endSession
        }
    }

    var mirroredAction: WatchBridgeMirroredSessionCommandAction {
        switch self {
        case .start:
            return .start
        case .pause:
            return .pause
        case .resume:
            return .resume
        case .stop:
            return .stop
        }
    }

    var titleLocalizationKey: String {
        switch self {
        case .start:
            return "watch.live.controls.start"
        case .pause:
            return "watch.live.controls.pause"
        case .resume:
            return "watch.live.controls.resume"
        case .stop:
            return "watch.live.controls.stop"
        }
    }

    var accessibilityLabelLocalizationKey: String {
        switch self {
        case .start:
            return "watch.live.accessibility.start"
        case .pause:
            return "watch.live.accessibility.pause"
        case .resume:
            return "watch.live.accessibility.resume"
        case .stop:
            return "watch.live.accessibility.stop"
        }
    }
}

struct WatchLiveControlAction: Equatable, Identifiable, Sendable {
    let kind: WatchLiveControlActionKind
    let commandKind: WatchBridgeCommandKind
    let mirroredAction: WatchBridgeMirroredSessionCommandAction
    let titleLocalizationKey: String
    let accessibilityLabelLocalizationKey: String
    let isEnabled: Bool

    var id: String {
        kind.rawValue
    }

    var requiresExistingSession: Bool {
        mirroredAction.requiresExistingSession
    }

    init(
        kind: WatchLiveControlActionKind,
        isEnabled: Bool
    ) {
        self.kind = kind
        self.commandKind = kind.commandKind
        self.mirroredAction = kind.mirroredAction
        self.titleLocalizationKey = kind.titleLocalizationKey
        self.accessibilityLabelLocalizationKey = kind.accessibilityLabelLocalizationKey
        self.isEnabled = isEnabled
    }
}

struct WatchLiveControlState: Equatable, Sendable {
    let sessionState: WatchBridgeSessionState
    let sessionId: UUID?
    let sportModeKey: String?
    let canSendCommands: Bool
    let actions: [WatchLiveControlAction]

    init(viewModel: WatchActivityViewModel) {
        self.init(
            sessionState: viewModel.session.state,
            sessionId: viewModel.session.sessionId,
            sportModeKey: viewModel.session.mode.sportModeKey,
            canSendCommands: viewModel.connection.canSendCommands
        )
    }

    init(
        sessionState: WatchBridgeSessionState,
        sessionId: UUID? = nil,
        sportModeKey: String? = nil,
        canSendCommands: Bool
    ) {
        self.sessionState = sessionState
        self.sessionId = sessionId
        self.sportModeKey = sportModeKey
        self.canSendCommands = canSendCommands
        self.actions = Self.actionKinds(for: sessionState).map { kind in
            WatchLiveControlAction(
                kind: kind,
                isEnabled: Self.isEnabled(
                    kind: kind,
                    canSendCommands: canSendCommands,
                    sessionId: sessionId
                )
            )
        }
    }

    func makeCommand(
        for kind: WatchLiveControlActionKind,
        issuedAt: Date = Date()
    ) -> WatchBridgeCommandEnvelope? {
        guard let action = actions.first(where: { $0.kind == kind }),
              action.isEnabled else {
            return nil
        }

        return WatchBridgeCommandEnvelope(
            kind: action.commandKind,
            issuedAt: issuedAt,
            sessionId: sessionId,
            sportModeKey: sportModeKey,
            reason: kind.titleLocalizationKey
        )
    }

    private static func actionKinds(
        for sessionState: WatchBridgeSessionState
    ) -> [WatchLiveControlActionKind] {
        switch sessionState {
        case .idle, .ready, .ended, .failed:
            return [.start]
        case .preparing, .ending:
            return []
        case .recording:
            return [.pause, .stop]
        case .paused:
            return [.resume, .stop]
        }
    }

    private static func isEnabled(
        kind: WatchLiveControlActionKind,
        canSendCommands: Bool,
        sessionId: UUID?
    ) -> Bool {
        guard canSendCommands else {
            return false
        }

        if kind.mirroredAction.requiresExistingSession {
            return sessionId != nil
        }

        return true
    }
}

enum WatchLiveSessionStatusLocalization {
    static func key(for state: WatchBridgeSessionState) -> String {
        switch state {
        case .idle:
            return "watch.live.status.idle"
        case .preparing:
            return "watch.live.status.preparing"
        case .ready:
            return "watch.live.status.ready"
        case .recording:
            return "watch.live.status.recording"
        case .paused:
            return "watch.live.status.paused"
        case .ending:
            return "watch.live.status.ending"
        case .ended:
            return "watch.live.status.ended"
        case .failed:
            return "watch.live.status.failed"
        }
    }
}

struct WatchLiveSpeedDisplayValue: Equatable, Sendable {
    let valueText: String
    let unitLocalizationKey: String
    let isAvailable: Bool

    init(currentSpeedMetersPerSecond: Double?) {
        guard let metersPerSecond = currentSpeedMetersPerSecond,
              metersPerSecond.isFinite,
              metersPerSecond >= 0 else {
            self.valueText = "--"
            self.unitLocalizationKey = "unit.speed.kmh.short"
            self.isAvailable = false
            return
        }

        self.valueText = String(format: "%.1f", metersPerSecond * 3.6)
        self.unitLocalizationKey = "unit.speed.kmh.short"
        self.isAvailable = true
    }
}

// MARK: - Safe Haptic Intent Model

enum WatchHapticIntentKind: String, CaseIterable, Codable, Equatable, Sendable {
    case sessionStart
    case sessionPause
    case sessionResume
    case sessionEnd
    case commandRejected
    case safetyNotice

    static func sessionControl(_ action: WatchLiveControlActionKind) -> Self {
        switch action {
        case .start:
            return .sessionStart
        case .pause:
            return .sessionPause
        case .resume:
            return .sessionResume
        case .stop:
            return .sessionEnd
        }
    }
}

enum WatchHapticIntentTargetSupport: String, Codable, Equatable, Sendable {
    case unavailable
    case mockOnly
    case deviceSupported

    var allowsDevicePlayback: Bool {
        self == .deviceSupported
    }
}

enum WatchHapticIntentDecisionState: String, Codable, Equatable, Sendable {
    case scheduled
    case mockOnly
    case disabled
    case rateLimited
    case duplicateSuppressed
}

struct WatchHapticIntent: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let kind: WatchHapticIntentKind
    let issuedAt: Date
    let correlationId: String?
    let sourceDescription: String

    init(
        id: String = UUID().uuidString,
        kind: WatchHapticIntentKind,
        issuedAt: Date = Date(),
        correlationId: String? = nil,
        sourceDescription: String
    ) {
        self.id = id
        self.kind = kind
        self.issuedAt = issuedAt
        self.correlationId = correlationId
        self.sourceDescription = sourceDescription
    }

    static func sessionControl(
        _ action: WatchLiveControlActionKind,
        issuedAt: Date = Date(),
        correlationId: String? = nil
    ) -> Self {
        Self(
            id: [WatchHapticIntentKind.sessionControl(action).rawValue, correlationId ?? UUID().uuidString]
                .joined(separator: ":"),
            kind: WatchHapticIntentKind.sessionControl(action),
            issuedAt: issuedAt,
            correlationId: correlationId,
            sourceDescription: "watch live control"
        )
    }

    var duplicateSuppressionKey: String {
        [kind.rawValue, correlationId ?? id].joined(separator: ":")
    }

    var isSensorDerivedClaim: Bool {
        false
    }
}

struct WatchHapticIntentPolicy: Codable, Equatable, Sendable {
    let minimumIntervalSeconds: TimeInterval
    let duplicateSuppressionSeconds: TimeInterval
    let targetSupport: WatchHapticIntentTargetSupport

    init(
        minimumIntervalSeconds: TimeInterval = 1.0,
        duplicateSuppressionSeconds: TimeInterval = 2.0,
        targetSupport: WatchHapticIntentTargetSupport = .mockOnly
    ) {
        self.minimumIntervalSeconds = max(0, minimumIntervalSeconds)
        self.duplicateSuppressionSeconds = max(0, duplicateSuppressionSeconds)
        self.targetSupport = targetSupport
    }

    static let disabled = WatchHapticIntentPolicy(targetSupport: .unavailable)
    static let mockOnly = WatchHapticIntentPolicy(targetSupport: .mockOnly)

    static func deviceSupported(
        minimumIntervalSeconds: TimeInterval = 1.0,
        duplicateSuppressionSeconds: TimeInterval = 2.0
    ) -> Self {
        Self(
            minimumIntervalSeconds: minimumIntervalSeconds,
            duplicateSuppressionSeconds: duplicateSuppressionSeconds,
            targetSupport: .deviceSupported
        )
    }
}

struct WatchHapticIntentDecision: Codable, Equatable, Sendable {
    let intent: WatchHapticIntent
    let state: WatchHapticIntentDecisionState
    let decidedAt: Date
    let reason: String
    let allowsDevicePlayback: Bool

    var shouldPlayOnDevice: Bool {
        state == .scheduled && allowsDevicePlayback
    }
}

struct WatchHapticIntentGate: Sendable {
    let policy: WatchHapticIntentPolicy
    private var lastAcceptedByKind: [WatchHapticIntentKind: Date]
    private var lastAcceptedByDuplicateKey: [String: Date]

    init(
        policy: WatchHapticIntentPolicy = .mockOnly,
        lastAcceptedByKind: [WatchHapticIntentKind: Date] = [:],
        lastAcceptedByDuplicateKey: [String: Date] = [:]
    ) {
        self.policy = policy
        self.lastAcceptedByKind = lastAcceptedByKind
        self.lastAcceptedByDuplicateKey = lastAcceptedByDuplicateKey
    }

    mutating func resolve(
        _ intent: WatchHapticIntent,
        decidedAt: Date = Date()
    ) -> WatchHapticIntentDecision {
        if policy.targetSupport == .unavailable {
            return decision(
                for: intent,
                state: .disabled,
                decidedAt: decidedAt,
                reason: "haptic target unavailable or disabled",
                allowsDevicePlayback: false
            )
        }

        if let lastDuplicate = lastAcceptedByDuplicateKey[intent.duplicateSuppressionKey],
           decidedAt.timeIntervalSince(lastDuplicate) < policy.duplicateSuppressionSeconds {
            return decision(
                for: intent,
                state: .duplicateSuppressed,
                decidedAt: decidedAt,
                reason: "duplicate haptic intent suppressed",
                allowsDevicePlayback: false
            )
        }

        if let lastKind = lastAcceptedByKind[intent.kind],
           decidedAt.timeIntervalSince(lastKind) < policy.minimumIntervalSeconds {
            return decision(
                for: intent,
                state: .rateLimited,
                decidedAt: decidedAt,
                reason: "haptic intent rate limited",
                allowsDevicePlayback: false
            )
        }

        recordAccepted(intent, at: decidedAt)

        if policy.targetSupport == .mockOnly {
            return decision(
                for: intent,
                state: .mockOnly,
                decidedAt: decidedAt,
                reason: "haptic target is mock-only",
                allowsDevicePlayback: false
            )
        }

        return decision(
            for: intent,
            state: .scheduled,
            decidedAt: decidedAt,
            reason: "haptic intent scheduled",
            allowsDevicePlayback: policy.targetSupport.allowsDevicePlayback
        )
    }

    private mutating func recordAccepted(_ intent: WatchHapticIntent, at date: Date) {
        lastAcceptedByKind[intent.kind] = date
        lastAcceptedByDuplicateKey[intent.duplicateSuppressionKey] = date
    }

    private func decision(
        for intent: WatchHapticIntent,
        state: WatchHapticIntentDecisionState,
        decidedAt: Date,
        reason: String,
        allowsDevicePlayback: Bool
    ) -> WatchHapticIntentDecision {
        WatchHapticIntentDecision(
            intent: intent,
            state: state,
            decidedAt: decidedAt,
            reason: reason,
            allowsDevicePlayback: allowsDevicePlayback
        )
    }
}
