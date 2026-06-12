// [自主區] DisabledWeatherProvider.swift
// 用途：代表真實天氣服務尚未啟用時的明確 provider fallback；不接 WeatherKit、不打網路、不請定位權限。
// 委派至：useWeatherRisk 顯示 disabled/local-only 狀態，未來由 WeatherKitWeatherProvider 或其他 provider 替換。

import Foundation

@MainActor
final class DisabledWeatherProvider: WeatherProviding {
    func currentWeather(for context: WeatherQueryContext) async throws -> WeatherRiskSnapshot {
        var snapshot = WeatherRiskSnapshot.disabledFallback
        snapshot.observedAt = Date()
        snapshot.contextPurpose = context.purpose
        snapshot.contextSpotName = context.spotName
        return snapshot
    }
}
