// [協作區] Shared/WatchUI/WatchQuickStartShellState.swift
// Purpose: Defines a disabled/provider-aware Watch quick-start shell for Task-039b.
// Delegates to: iPhone-authoritative session start behavior owned by existing WatchBridge/session runtime.

import Foundation

enum WatchQuickStartShellAvailability: String, Codable, Equatable, Sendable {
    case providerUnavailable
    case iPhoneAuthorityRequired

    var statusLocalizationKey: String {
        switch self {
        case .providerUnavailable:
            return "watch.quickStart.status.providerUnavailable"
        case .iPhoneAuthorityRequired:
            return "watch.quickStart.status.iPhoneAuthority"
        }
    }
}

enum WatchQuickStartAuthority: String, Codable, Equatable, Sendable {
    case iPhone
}

enum WatchQuickStartShellOptionKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case lastMode
    case outdoorRide
    case readyCheck

    var id: String { rawValue }

    var titleLocalizationKey: String {
        switch self {
        case .lastMode:
            return "watch.quickStart.lastMode.title"
        case .outdoorRide:
            return "watch.quickStart.outdoor.title"
        case .readyCheck:
            return "watch.quickStart.readyCheck.title"
        }
    }

    var detailLocalizationKey: String {
        switch self {
        case .lastMode:
            return "watch.quickStart.lastMode.detail"
        case .outdoorRide:
            return "watch.quickStart.outdoor.detail"
        case .readyCheck:
            return "watch.quickStart.readyCheck.detail"
        }
    }

    var systemImageName: String {
        switch self {
        case .lastMode:
            return "arrow.clockwise.circle.fill"
        case .outdoorRide:
            return "figure.outdoor.cycle"
        case .readyCheck:
            return "checkmark.seal.fill"
        }
    }
}

struct WatchQuickStartShellOption: Identifiable, Codable, Equatable, Sendable {
    let kind: WatchQuickStartShellOptionKind
    let isEnabled: Bool
    let titleLocalizationKey: String
    let detailLocalizationKey: String
    let systemImageName: String

    var id: WatchQuickStartShellOptionKind { kind }

    init(
        kind: WatchQuickStartShellOptionKind,
        isEnabled: Bool = false
    ) {
        self.kind = kind
        self.isEnabled = isEnabled
        self.titleLocalizationKey = kind.titleLocalizationKey
        self.detailLocalizationKey = kind.detailLocalizationKey
        self.systemImageName = kind.systemImageName
    }
}

struct WatchQuickStartShellState: Codable, Equatable, Sendable {
    let generatedAt: Date
    let availability: WatchQuickStartShellAvailability
    let authority: WatchQuickStartAuthority
    let options: [WatchQuickStartShellOption]
    let titleLocalizationKey: String
    let detailLocalizationKey: String
    let accessibilityLabelLocalizationKey: String

    init(
        generatedAt: Date = Date(),
        availability: WatchQuickStartShellAvailability,
        authority: WatchQuickStartAuthority = .iPhone,
        options: [WatchQuickStartShellOption],
        titleLocalizationKey: String = "watch.quickStart.title",
        detailLocalizationKey: String = "watch.quickStart.detail",
        accessibilityLabelLocalizationKey: String = "watch.quickStart.accessibility.label"
    ) {
        self.generatedAt = generatedAt
        self.availability = availability
        self.authority = authority
        self.options = options
        self.titleLocalizationKey = titleLocalizationKey
        self.detailLocalizationKey = detailLocalizationKey
        self.accessibilityLabelLocalizationKey = accessibilityLabelLocalizationKey
    }

    init(viewModel: WatchActivityViewModel) {
        self = Self.disabled(
            generatedAt: viewModel.generatedAt,
            canSendCommands: viewModel.connection.canSendCommands
        )
    }

    static func disabled(
        generatedAt: Date = Date(),
        canSendCommands: Bool = false
    ) -> WatchQuickStartShellState {
        WatchQuickStartShellState(
            generatedAt: generatedAt,
            availability: canSendCommands ? .iPhoneAuthorityRequired : .providerUnavailable,
            options: WatchQuickStartShellOptionKind.allCases.map {
                WatchQuickStartShellOption(kind: $0)
            }
        )
    }

    var isProviderAware: Bool {
        true
    }

    var requiresIPhoneAuthority: Bool {
        authority == .iPhone
    }

    var allowsDirectWatchStart: Bool {
        false
    }

    var startsSessionFromWatch: Bool {
        false
    }

    var writesSessionRuntime: Bool {
        false
    }

    var hasQuickStartOptions: Bool {
        !options.isEmpty
    }

    func makeStartCommand(_ issuedAt: Date = Date()) -> WatchBridgeCommandEnvelope? {
        nil
    }
}
