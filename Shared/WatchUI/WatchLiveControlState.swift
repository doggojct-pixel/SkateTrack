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
