// [協作區 — 邊界適配層] useWeatherRisk.swift
// 用途：向 SwiftUI 暴露 Task-022 天氣適合度與本機 rideability 狀態，隱藏 provider / monitor / engine 細節。
// 委派至：WeatherProviding 提供可替換天氣來源，WeatherRideabilityEngine 整合場地與天氣因素。

import Combine
import SwiftUI

@MainActor
final class WeatherRiskViewModel: ObservableObject {
    @Published private(set) var report: WeatherSuitabilityReport
    @Published private(set) var rideabilityReport: WeatherRideabilityReport
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var canViewDetailedRisk: Bool

    private let provider: WeatherProviding
    private let monitor: WeatherRiskMonitor
    private let rideabilityEngine: WeatherRideabilityEngine
    private let settingsStore: HealthReminderSettingsStore
    private let subscriptionStatus: SubscriptionStatusViewModel
    private var currentContext: WeatherQueryContext
    private var currentSpot: SpotProfile?
    private var cancellables = Set<AnyCancellable>()

    init(
        provider: WeatherProviding? = nil,
        monitor: WeatherRiskMonitor = WeatherRiskMonitor(),
        rideabilityEngine: WeatherRideabilityEngine = WeatherRideabilityEngine(),
        settingsStore: HealthReminderSettingsStore? = nil,
        subscriptionStatus: SubscriptionStatusViewModel,
        initialContext: WeatherQueryContext = .rideStart(),
        initialSpot: SpotProfile? = nil
    ) {
        let resolvedSettingsStore = settingsStore ?? HealthReminderSettingsStore.shared
        let initialSnapshot = WeatherRiskSnapshot.mockBaseline
        let initialReport = monitor.report(for: initialSnapshot, settings: resolvedSettingsStore.settings)
        self.provider = provider ?? MockWeatherProvider()
        self.monitor = monitor
        self.rideabilityEngine = rideabilityEngine
        self.settingsStore = resolvedSettingsStore
        self.subscriptionStatus = subscriptionStatus
        self.currentContext = initialContext
        self.currentSpot = initialSpot
        self.canViewDetailedRisk = subscriptionStatus.hasAccess(to: .healthReminders)
        self.report = initialReport
        self.rideabilityReport = rideabilityEngine.report(
            weatherReport: initialReport,
            context: initialContext,
            spot: initialSpot
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

    func updateContext(_ context: WeatherQueryContext, spot: SpotProfile?) {
        guard context != currentContext || spot != currentSpot else { return }
        currentContext = context
        currentSpot = spot
        rebuildReport(using: settingsStore.settings)
        refresh()
    }

    func syncAccess() {
        canViewDetailedRisk = subscriptionStatus.hasAccess(to: .healthReminders)
    }

    private func loadWeatherSnapshot() async {
        isLoading = true
        errorMessageKey = nil
        do {
            let snapshot = try await provider.currentWeather(for: currentContext)
            report = monitor.report(for: snapshot, settings: settingsStore.settings)
            rideabilityReport = rideabilityEngine.report(
                weatherReport: report,
                context: currentContext,
                spot: currentSpot
            )
            isLoading = false
        } catch {
            errorMessageKey = "weather.suitability.error"
            isLoading = false
        }
    }

    private func rebuildReport(using settings: HealthReminderSettings) {
        report = monitor.report(for: report.snapshot, settings: settings)
        rideabilityReport = rideabilityEngine.report(
            weatherReport: report,
            context: currentContext,
            spot: currentSpot
        )
    }
}

@MainActor
func useWeatherRisk(
    provider: WeatherProviding? = nil,
    subscriptionStatus: SubscriptionStatusViewModel,
    initialContext: WeatherQueryContext = .rideStart(),
    initialSpot: SpotProfile? = nil
) -> WeatherRiskViewModel {
    WeatherRiskViewModel(
        provider: provider,
        subscriptionStatus: subscriptionStatus,
        initialContext: initialContext,
        initialSpot: initialSpot
    )
}
