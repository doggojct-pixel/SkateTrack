// [協作區 — 邊界適配層] useHealthReminders.swift
// 用途：向 SwiftUI 暴露健康提醒設定與 Pro 權限狀態，避免 View 直接操作 Store 或 DEBUG 權限。
// 委派至：HealthReminderSettingsStore 保存設定；FeatureFlagEngine / useSubscriptionStatus 判斷付費權限。

import Combine
import SwiftUI

@MainActor
final class HealthReminderViewModel: ObservableObject {
    @Published private(set) var settings: HealthReminderSettings
    @Published private(set) var canEditSettings: Bool

    private let store: HealthReminderSettingsStore
    private let subscriptionStatus: SubscriptionStatusViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        store: HealthReminderSettingsStore? = nil,
        subscriptionStatus: SubscriptionStatusViewModel
    ) {
        let resolvedStore = store ?? HealthReminderSettingsStore.shared
        self.store = resolvedStore
        self.subscriptionStatus = subscriptionStatus
        self.settings = resolvedStore.settings
        self.canEditSettings = subscriptionStatus.hasAccess(to: .healthReminders)

        resolvedStore.$settings
            .sink { [weak self] settings in
                Task { @MainActor [weak self] in
                    self?.settings = settings
                }
            }
            .store(in: &cancellables)

        subscriptionStatus.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.syncAccess()
                }
            }
            .store(in: &cancellables)
    }

    func rule(for kind: HealthReminderKind) -> HealthReminderRule {
        settings.rule(for: kind)
    }

    func setEnabled(_ isEnabled: Bool, for kind: HealthReminderKind) {
        guard canEditSettings else { return }
        store.setEnabled(isEnabled, for: kind)
    }

    func setIntervalMinutes(_ minutes: Int, for kind: HealthReminderKind) {
        guard canEditSettings else { return }
        store.setIntervalMinutes(minutes, for: kind)
    }

    func setThreshold(_ value: Double, for kind: HealthReminderKind) {
        guard canEditSettings else { return }
        store.setThreshold(value, for: kind)
    }

    func resetToDefaults() {
        guard canEditSettings else { return }
        store.resetToDefaults()
    }

    func syncAccess() {
        canEditSettings = subscriptionStatus.hasAccess(to: .healthReminders)
    }
}

@MainActor
func useHealthReminders(
    store: HealthReminderSettingsStore? = nil,
    subscriptionStatus: SubscriptionStatusViewModel
) -> HealthReminderViewModel {
    HealthReminderViewModel(store: store, subscriptionStatus: subscriptionStatus)
}
