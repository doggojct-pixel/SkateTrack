// [自主區] WeatherProvider.swift
// 用途：定義 Task-022 可替換天氣來源邊界；目前只允許 mock / disabled provider，不接 WeatherKit、定位或網路 API。
// 委派至：MockWeatherProvider 與 DisabledWeatherProvider；未來真實 provider 必須在此邊界後替換。

import Foundation

@MainActor
protocol WeatherProviding {
    func currentWeather(for context: WeatherQueryContext) async throws -> WeatherRiskSnapshot
}

extension WeatherProviding {
    func currentWeather() async throws -> WeatherRiskSnapshot {
        try await currentWeather(for: .rideStart())
    }
}

enum WeatherProviderError: Error, Equatable {
    case unavailable
    case externalServiceNotConfigured
}
