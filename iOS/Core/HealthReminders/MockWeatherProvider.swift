// [自主區] MockWeatherProvider.swift
// 用途：提供 Task-022 開發期天氣風險假資料，依本機 context 產生穩定 mock 快照。
// 委派至：useWeatherRisk 讀取 mock 快照並交由 WeatherRiskMonitor / WeatherRideabilityEngine 評估。

import Foundation

@MainActor
final class MockWeatherProvider: WeatherProviding {
    private var snapshot: WeatherRiskSnapshot

    init(snapshot: WeatherRiskSnapshot = .mockBaseline) {
        self.snapshot = snapshot
    }

    func currentWeather(for context: WeatherQueryContext) async throws -> WeatherRiskSnapshot {
        var refreshed = adjustedSnapshot(for: context)
        refreshed.observedAt = Date()
        refreshed.contextPurpose = context.purpose
        refreshed.contextSpotName = context.spotName
        return refreshed
    }

    private func adjustedSnapshot(for context: WeatherQueryContext) -> WeatherRiskSnapshot {
        var adjusted = snapshot
        adjusted.source = .mock

        if context.purpose == .spotPreview {
            adjusted.temperatureCelsius += context.hasCoordinate ? -1 : 0
            adjusted.uvIndex += context.hasCoordinate ? 0.5 : 0
            adjusted.precipitationProbability += context.hasSpot ? 0.04 : 0
        }

        switch context.sportMode {
        case .skateboard(.longboard)?:
            adjusted.precipitationProbability += 0.03
        case .skateboard(.surfskate)?:
            adjusted.uvIndex += 0.4
        case .inline(.fitnessSpeed)?:
            adjusted.temperatureCelsius += 0.8
        default:
            break
        }

        adjusted.precipitationProbability = max(0, min(adjusted.precipitationProbability, 0.95))
        adjusted.condition = condition(for: adjusted.precipitationProbability)
        return adjusted
    }

    private func condition(for precipitationProbability: Double) -> WeatherConditionKind {
        if precipitationProbability >= 0.70 { return .heavyRain }
        if precipitationProbability >= 0.35 { return .lightRain }
        if precipitationProbability >= 0.18 { return .cloudy }
        return .sunny
    }
}
