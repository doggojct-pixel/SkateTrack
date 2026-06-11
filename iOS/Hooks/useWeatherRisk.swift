// [協作區 — 邊界適配層] useWeatherRisk.swift
// 用途：向 SwiftUI 暴露 Task-019c 天氣適合度與 Pro 詳細風險狀態，隱藏 provider / monitor 細節。
// 委派至：WeatherProviding 提供可替換天氣來源，WeatherRiskMonitor 產生滑行適合度報告。

import Combine
import SwiftUI

@MainActor
final class WeatherRiskViewModel: ObservableObject {
    @Published private(set) var report: WeatherSuitabilityReport
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var canViewDetailedRisk: Bool

    private let provider: WeatherProviding
    private let monitor: WeatherRiskMonitor
    private let settingsStore: HealthReminderSettingsStore
    private let subscriptionStatus: SubscriptionStatusViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        provider: WeatherProviding? = nil,
        monitor: WeatherRiskMonitor = WeatherRiskMonitor(),
        settingsStore: HealthReminderSettingsStore? = nil,
        subscriptionStatus: SubscriptionStatusViewModel
    ) {
        let resolvedSettingsStore = settingsStore ?? HealthReminderSettingsStore.shared
        self.provider = provider ?? MockWeatherProvider()
        self.monitor = monitor
        self.settingsStore = resolvedSettingsStore
        self.subscriptionStatus = subscriptionStatus
        self.canViewDetailedRisk = subscriptionStatus.hasAccess(to: .healthReminders)
        self.report = monitor.report(
            for: .mockBaseline,
            settings: resolvedSettingsStore.settings
        )

        resolvedSettingsStore.$settings
            .sink { [weak self] settings in
                Task { @MainActor [weak self] in
                    self?.rebuildReport(using: settings)
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

    func refresh() {
        Task { @MainActor in
            await loadWeatherSnapshot()
        }
    }

    func syncAccess() {
        canViewDetailedRisk = subscriptionStatus.hasAccess(to: .healthReminders)
    }

    private func loadWeatherSnapshot() async {
        isLoading = true
        errorMessageKey = nil
        do {
            let snapshot = try await provider.currentWeather()
            report = monitor.report(for: snapshot, settings: settingsStore.settings)
            isLoading = false
        } catch {
            errorMessageKey = "weather.suitability.error"
            isLoading = false
        }
    }

    private func rebuildReport(using settings: HealthReminderSettings) {
        report = monitor.report(for: report.snapshot, settings: settings)
    }
}

@MainActor
func useWeatherRisk(
    provider: WeatherProviding? = nil,
    subscriptionStatus: SubscriptionStatusViewModel
) -> WeatherRiskViewModel {
    WeatherRiskViewModel(provider: provider, subscriptionStatus: subscriptionStatus)
}
