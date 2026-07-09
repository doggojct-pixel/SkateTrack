// [協作區] Shared/WatchUI/WatchComplicationShellState.swift
// Purpose: Defines a disabled Watch complication readiness shell for Pre-ADP builds.
// Delegates to: watchOS rendering without adding WidgetKit, ClockKit, or timeline runtime.

import Foundation

enum WatchComplicationShellAvailability: String, Codable, Equatable, Sendable {
    case unavailable
    case placeholderOnly

    var statusLocalizationKey: String {
        switch self {
        case .unavailable:
            return "watch.complication.status.unavailable"
        case .placeholderOnly:
            return "watch.complication.status.placeholder"
        }
    }
}

enum WatchComplicationShellSlotKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case currentSpeed
    case elapsedTime
    case distance

    var id: String { rawValue }

    var titleLocalizationKey: String {
        switch self {
        case .currentSpeed:
            return "watch.complication.speed.title"
        case .elapsedTime:
            return "watch.complication.time.title"
        case .distance:
            return "watch.complication.distance.title"
        }
    }

    var detailLocalizationKey: String {
        switch self {
        case .currentSpeed:
            return "watch.complication.speed.detail"
        case .elapsedTime:
            return "watch.complication.time.detail"
        case .distance:
            return "watch.complication.distance.detail"
        }
    }

    var systemImageName: String {
        switch self {
        case .currentSpeed:
            return "speedometer"
        case .elapsedTime:
            return "timer"
        case .distance:
            return "point.topleft.down.curvedto.point.bottomright.up"
        }
    }
}

struct WatchComplicationShellSlot: Identifiable, Codable, Equatable, Sendable {
    let kind: WatchComplicationShellSlotKind
    let isEnabled: Bool
    let titleLocalizationKey: String
    let detailLocalizationKey: String
    let systemImageName: String

    var id: WatchComplicationShellSlotKind { kind }

    init(
        kind: WatchComplicationShellSlotKind,
        isEnabled: Bool = false
    ) {
        self.kind = kind
        self.isEnabled = isEnabled
        self.titleLocalizationKey = kind.titleLocalizationKey
        self.detailLocalizationKey = kind.detailLocalizationKey
        self.systemImageName = kind.systemImageName
    }
}

struct WatchComplicationShellState: Codable, Equatable, Sendable {
    let generatedAt: Date
    let availability: WatchComplicationShellAvailability
    let slots: [WatchComplicationShellSlot]
    let titleLocalizationKey: String
    let detailLocalizationKey: String
    let accessibilityLabelLocalizationKey: String

    init(
        generatedAt: Date = Date(),
        availability: WatchComplicationShellAvailability,
        slots: [WatchComplicationShellSlot],
        titleLocalizationKey: String = "watch.complication.title",
        detailLocalizationKey: String = "watch.complication.detail",
        accessibilityLabelLocalizationKey: String = "watch.complication.accessibility.label"
    ) {
        self.generatedAt = generatedAt
        self.availability = availability
        self.slots = slots
        self.titleLocalizationKey = titleLocalizationKey
        self.detailLocalizationKey = detailLocalizationKey
        self.accessibilityLabelLocalizationKey = accessibilityLabelLocalizationKey
    }

    static func disabled(
        generatedAt: Date = Date()
    ) -> WatchComplicationShellState {
        WatchComplicationShellState(
            generatedAt: generatedAt,
            availability: .unavailable,
            slots: WatchComplicationShellSlotKind.allCases.map {
                WatchComplicationShellSlot(kind: $0)
            }
        )
    }

    var hasPlaceholderSlots: Bool {
        !slots.isEmpty
    }

    var supportsFaceComplicationDistribution: Bool {
        false
    }

    var usesWidgetKitExtension: Bool {
        false
    }

    var usesClockKitExtension: Bool {
        false
    }

    var providesLiveTimeline: Bool {
        false
    }

    var requestsNewCapabilities: Bool {
        false
    }

    var opensAppOnly: Bool {
        true
    }
}
