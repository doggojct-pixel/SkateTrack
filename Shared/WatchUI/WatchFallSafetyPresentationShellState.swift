// [協作區] Shared/WatchUI/WatchFallSafetyPresentationShellState.swift
// Purpose: Defines a Watch fall-safety presentation shell without detection or dispatch behavior.
// Delegates to: watchOS rendering and Task-038a mock-only haptic intent policy.

import Foundation

enum WatchFallSafetyPresentationShellPhase: String, Codable, Equatable, Sendable {
    case hidden
    case presented
    case dismissed
    case falseAlarm

    var statusLocalizationKey: String {
        switch self {
        case .hidden, .presented:
            return "watch.fallSafety.status.shell"
        case .dismissed:
            return "watch.fallSafety.status.dismissed"
        case .falseAlarm:
            return "watch.fallSafety.status.falseAlarm"
        }
    }
}

enum WatchFallSafetyPresentationShellResolution: String, Codable, Equatable, Sendable {
    case manualDismiss
    case falseAlarm
}

struct WatchFallSafetyPresentationShellState: Codable, Equatable, Sendable {
    let generatedAt: Date
    let phase: WatchFallSafetyPresentationShellPhase
    let resolvedAt: Date?
    let resolution: WatchFallSafetyPresentationShellResolution?
    let titleLocalizationKey: String
    let detailLocalizationKey: String
    let limitationLocalizationKey: String
    let dismissButtonLocalizationKey: String
    let falseAlarmButtonLocalizationKey: String
    let accessibilityLabelLocalizationKey: String
    let hapticPolicy: WatchHapticIntentPolicy

    init(
        generatedAt: Date = Date(),
        phase: WatchFallSafetyPresentationShellPhase,
        resolvedAt: Date? = nil,
        resolution: WatchFallSafetyPresentationShellResolution? = nil,
        titleLocalizationKey: String = "watch.fallSafety.title",
        detailLocalizationKey: String = "watch.fallSafety.detail",
        limitationLocalizationKey: String = "watch.fallSafety.limitation",
        dismissButtonLocalizationKey: String = "watch.fallSafety.dismiss",
        falseAlarmButtonLocalizationKey: String = "watch.fallSafety.falseAlarm",
        accessibilityLabelLocalizationKey: String = "watch.fallSafety.accessibility.label",
        hapticPolicy: WatchHapticIntentPolicy = .mockOnly
    ) {
        self.generatedAt = generatedAt
        self.phase = phase
        self.resolvedAt = resolvedAt
        self.resolution = resolution
        self.titleLocalizationKey = titleLocalizationKey
        self.detailLocalizationKey = detailLocalizationKey
        self.limitationLocalizationKey = limitationLocalizationKey
        self.dismissButtonLocalizationKey = dismissButtonLocalizationKey
        self.falseAlarmButtonLocalizationKey = falseAlarmButtonLocalizationKey
        self.accessibilityLabelLocalizationKey = accessibilityLabelLocalizationKey
        self.hapticPolicy = hapticPolicy.targetSupport.allowsDevicePlayback ? .mockOnly : hapticPolicy
    }

    static func hidden(
        generatedAt: Date = Date()
    ) -> WatchFallSafetyPresentationShellState {
        WatchFallSafetyPresentationShellState(
            generatedAt: generatedAt,
            phase: .hidden,
            hapticPolicy: .disabled
        )
    }

    static func presented(
        generatedAt: Date = Date()
    ) -> WatchFallSafetyPresentationShellState {
        WatchFallSafetyPresentationShellState(
            generatedAt: generatedAt,
            phase: .presented,
            hapticPolicy: .mockOnly
        )
    }

    func dismissed(
        at date: Date = Date()
    ) -> WatchFallSafetyPresentationShellState {
        resolved(
            phase: .dismissed,
            resolution: .manualDismiss,
            at: date
        )
    }

    func markedFalseAlarm(
        at date: Date = Date()
    ) -> WatchFallSafetyPresentationShellState {
        resolved(
            phase: .falseAlarm,
            resolution: .falseAlarm,
            at: date
        )
    }

    var isVisible: Bool {
        phase == .presented
    }

    var hasManualDismissPath: Bool {
        true
    }

    var falseAlarmPathPresent: Bool {
        true
    }

    var detectsFalls: Bool {
        false
    }

    var contactsEmergencyServices: Bool {
        false
    }

    var usesHealthKit: Bool {
        false
    }

    var requestsHealthKitPermission: Bool {
        false
    }

    var readsBodyData: Bool {
        false
    }

    var allowsDeviceHapticPlayback: Bool {
        false
    }

    private func resolved(
        phase: WatchFallSafetyPresentationShellPhase,
        resolution: WatchFallSafetyPresentationShellResolution,
        at date: Date
    ) -> WatchFallSafetyPresentationShellState {
        WatchFallSafetyPresentationShellState(
            generatedAt: generatedAt,
            phase: phase,
            resolvedAt: date,
            resolution: resolution,
            hapticPolicy: .mockOnly
        )
    }
}
