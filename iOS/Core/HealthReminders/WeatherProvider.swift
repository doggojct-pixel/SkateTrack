// [自主區] WeatherProvider.swift
// 用途：定義 Task-019c 可替換天氣來源邊界；目前不接 真實天氣框架、定位或網路 API。
// 委派至：MockWeatherProvider 在開發期提供本機假資料，未來真實 provider 可在此邊界後替換。

import Foundation

@MainActor
protocol WeatherProviding {
    func currentWeather() async throws -> WeatherRiskSnapshot
}

enum WeatherProviderError: Error, Equatable {
    case unavailable
}
