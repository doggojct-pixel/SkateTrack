// [自主區] WeatherRiskSnapshot.swift
// 用途：定義 Task-019c 天氣風險快照與滑行適合度報告模型；不接真實 真實天氣框架或網路 API。
// 委派至：WeatherRiskMonitor 依本機健康提醒門檻產生風險說明，WeatherSuitabilityCardView 負責呈現。

import Foundation

enum WeatherSuitabilityLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case excellent
    case good
    case caution
    case unsafe

    var id: String { rawValue }

    var priority: Int {
        switch self {
        case .excellent: return 0
        case .good: return 1
        case .caution: return 2
        case .unsafe: return 3
        }
    }

    var titleKey: String {
        switch self {
        case .excellent: return "weather.suitability.level.excellent"
        case .good: return "weather.suitability.level.good"
        case .caution: return "weather.suitability.level.caution"
        case .unsafe: return "weather.suitability.level.unsafe"
        }
    }

    var summaryKey: String {
        switch self {
        case .excellent: return "weather.suitability.summary.excellent"
        case .good: return "weather.suitability.summary.good"
        case .caution: return "weather.suitability.summary.caution"
        case .unsafe: return "weather.suitability.summary.unsafe"
        }
    }
}

enum WeatherConditionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case sunny
    case cloudy
    case lightRain
    case heavyRain

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .sunny: return "weather.condition.sunny"
        case .cloudy: return "weather.condition.cloudy"
        case .lightRain: return "weather.condition.lightRain"
        case .heavyRain: return "weather.condition.heavyRain"
        }
    }

    var systemImageName: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .lightRain: return "cloud.drizzle.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        }
    }
}

enum WeatherRiskSource: String, Codable, Sendable {
    case mock
    case disabled
    case futureProvider

    var localizedDescriptionKey: String {
        switch self {
        case .mock: return "weather.source.mock"
        case .disabled: return "weather.source.disabled"
        case .futureProvider: return "weather.source.future"
        }
    }
}

enum WeatherRiskFactorKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case heat
    case uv
    case rain

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .heat: return "weather.risk.heat.title"
        case .uv: return "weather.risk.uv.title"
        case .rain: return "weather.risk.rain.title"
        }
    }

    var systemImageName: String {
        switch self {
        case .heat: return "thermometer.sun.fill"
        case .uv: return "sun.max.fill"
        case .rain: return "cloud.rain.fill"
        }
    }
}

struct WeatherRiskSnapshot: Codable, Equatable, Sendable {
    var observedAt: Date
    var temperatureCelsius: Double
    var uvIndex: Double
    var precipitationProbability: Double
    var condition: WeatherConditionKind
    var source: WeatherRiskSource
    var contextPurpose: WeatherQueryPurpose
    var contextSpotName: String?

    static var mockBaseline: WeatherRiskSnapshot {
        WeatherRiskSnapshot(
            observedAt: Date(),
            temperatureCelsius: 32,
            uvIndex: 7,
            precipitationProbability: 0.24,
            condition: .sunny,
            source: .mock,
            contextPurpose: .rideStart,
            contextSpotName: nil
        )
    }

    static var disabledFallback: WeatherRiskSnapshot {
        WeatherRiskSnapshot(
            observedAt: Date(),
            temperatureCelsius: 28,
            uvIndex: 4,
            precipitationProbability: 0.10,
            condition: .cloudy,
            source: .disabled,
            contextPurpose: .rideStart,
            contextSpotName: nil
        )
    }
}

struct WeatherRiskFactor: Identifiable, Equatable, Sendable {
    let id: WeatherRiskFactorKind
    let level: WeatherSuitabilityLevel
    let valueText: String
    let messageKey: String
}

struct WeatherSuitabilityReport: Equatable, Sendable {
    var snapshot: WeatherRiskSnapshot
    var level: WeatherSuitabilityLevel
    var factors: [WeatherRiskFactor]

    var highestRiskFactor: WeatherRiskFactor? {
        factors.max { lhs, rhs in
            lhs.level.priority < rhs.level.priority
        }
    }
}
