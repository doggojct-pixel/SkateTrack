// [協作區] Shared/WatchUI/WatchHealthReminderShellState.swift
// Purpose: Defines a general Watch reminder shell for hydration, rest, and stretch prompts.
// Delegates to: watchOS rendering and the Task-038a haptic intent policy model without device playback.

import Foundation

enum WatchHealthReminderShellAvailability: String, Codable, Equatable, Sendable {
    case disabled
    case shellOnly

    var statusLocalizationKey: String {
        switch self {
        case .disabled:
            return "watch.healthReminder.status.disabled"
        case .shellOnly:
            return "watch.healthReminder.status.shellOnly"
        }
    }
}

enum WatchHealthReminderShellKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case hydration
    case rest
    case stretch

    var id: String { rawValue }

    var titleLocalizationKey: String {
        switch self {
        case .hydration:
            return "watch.healthReminder.hydration.title"
        case .rest:
            return "watch.healthReminder.rest.title"
        case .stretch:
            return "watch.healthReminder.stretch.title"
        }
    }

    var detailLocalizationKey: String {
        switch self {
        case .hydration:
            return "watch.healthReminder.hydration.detail"
        case .rest:
            return "watch.healthReminder.rest.detail"
        case .stretch:
            return "watch.healthReminder.stretch.detail"
        }
    }

    var systemImageName: String {
        switch self {
        case .hydration:
            return "drop.fill"
        case .rest:
            return "pause.circle.fill"
        case .stretch:
            return "figure.cooldown"
        }
    }
}

struct WatchHealthReminderShellItem: Identifiable, Codable, Equatable, Sendable {
    let kind: WatchHealthReminderShellKind
    let isEnabled: Bool
    let titleLocalizationKey: String
    let detailLocalizationKey: String
    let systemImageName: String

    var id: WatchHealthReminderShellKind { kind }

    init(
        kind: WatchHealthReminderShellKind,
        isEnabled: Bool = false
    ) {
        self.kind = kind
        self.isEnabled = isEnabled
        self.titleLocalizationKey = kind.titleLocalizationKey
        self.detailLocalizationKey = kind.detailLocalizationKey
        self.systemImageName = kind.systemImageName
    }
}

struct WatchHealthReminderShellState: Codable, Equatable, Sendable {
    let generatedAt: Date
    let availability: WatchHealthReminderShellAvailability
    let items: [WatchHealthReminderShellItem]
    let titleLocalizationKey: String
    let detailLocalizationKey: String
    let accessibilityLabelLocalizationKey: String
    let hapticPolicy: WatchHapticIntentPolicy

    init(
        generatedAt: Date = Date(),
        availability: WatchHealthReminderShellAvailability,
        items: [WatchHealthReminderShellItem],
        titleLocalizationKey: String = "watch.healthReminder.title",
        detailLocalizationKey: String = "watch.healthReminder.detail",
        accessibilityLabelLocalizationKey: String = "watch.healthReminder.accessibility.label",
        hapticPolicy: WatchHapticIntentPolicy = .mockOnly
    ) {
        self.generatedAt = generatedAt
        self.availability = availability
        self.items = items
        self.titleLocalizationKey = titleLocalizationKey
        self.detailLocalizationKey = detailLocalizationKey
        self.accessibilityLabelLocalizationKey = accessibilityLabelLocalizationKey
        self.hapticPolicy = hapticPolicy
    }

    static func disabled(
        generatedAt: Date = Date()
    ) -> WatchHealthReminderShellState {
        WatchHealthReminderShellState(
            generatedAt: generatedAt,
            availability: .disabled,
            items: WatchHealthReminderShellKind.allCases.map {
                WatchHealthReminderShellItem(kind: $0)
            },
            hapticPolicy: .mockOnly
        )
    }

    var allowsLiveBodyData: Bool {
        false
    }

    var requestsSensorAuthorization: Bool {
        false
    }

    var usesSensorDetection: Bool {
        false
    }

    var allowsDeviceHapticPlayback: Bool {
        hapticPolicy.targetSupport.allowsDevicePlayback
    }

    var hasReminderCategories: Bool {
        !items.isEmpty
    }
}
