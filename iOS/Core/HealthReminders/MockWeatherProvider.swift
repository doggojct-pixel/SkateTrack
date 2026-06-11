// [自主區] MockWeatherProvider.swift
// 用途：提供 Task-019c 開發期天氣風險假資料，避免在尚未準備 真實天氣框架 / API 前耦合真實服務。
// 委派至：useWeatherRisk 讀取 mock 快照並交由 WeatherRiskMonitor 評估。

import Foundation

@MainActor
final class MockWeatherProvider: WeatherProviding {
    private var snapshot: WeatherRiskSnapshot

    init(snapshot: WeatherRiskSnapshot = .mockBaseline) {
        self.snapshot = snapshot
    }

    func currentWeather() async throws -> WeatherRiskSnapshot {
        var refreshed = snapshot
        refreshed.observedAt = Date()
        return refreshed
    }
}
