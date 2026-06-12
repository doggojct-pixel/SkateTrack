// [自主區] WeatherRideabilityReport.swift
// 用途：定義 Task-022 本機滑行適合度報告，結合天氣風險與場地安全 / 人潮 / 路面因素。
// 委派至：WeatherRideabilityEngine 產生報告，SwiftUI 只呈現報告而不直接評分。

import Foundation

enum WeatherRideabilityFactorKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case heat
    case uv
    case rain
    case surface
    case crowd
    case safety
    case localContext

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .heat: return WeatherRiskFactorKind.heat.titleKey
        case .uv: return WeatherRiskFactorKind.uv.titleKey
        case .rain: return WeatherRiskFactorKind.rain.titleKey
        case .surface: return "weather.rideability.factor.surface.title"
        case .crowd: return "weather.rideability.factor.crowd.title"
        case .safety: return "weather.rideability.factor.safety.title"
        case .localContext: return "weather.rideability.factor.local.title"
        }
    }

    var systemImageName: String {
        switch self {
        case .heat: return WeatherRiskFactorKind.heat.systemImageName
        case .uv: return WeatherRiskFactorKind.uv.systemImageName
        case .rain: return WeatherRiskFactorKind.rain.systemImageName
        case .surface: return "road.lanes"
        case .crowd: return "person.3.fill"
        case .safety: return "shield.lefthalf.filled"
        case .localContext: return "location.circle.fill"
        }
    }
}

struct WeatherRideabilityFactor: Identifiable, Equatable, Sendable {
    let id: WeatherRideabilityFactorKind
    let level: WeatherSuitabilityLevel
    let valueText: String
    let messageKey: String
}

struct WeatherRideabilityReport: Equatable, Sendable {
    var weatherReport: WeatherSuitabilityReport
    var context: WeatherQueryContext
    var spotName: String?
    var level: WeatherSuitabilityLevel
    var factors: [WeatherRideabilityFactor]

    var snapshot: WeatherRiskSnapshot {
        weatherReport.snapshot
    }

    var highestRiskFactor: WeatherRideabilityFactor? {
        factors.max { lhs, rhs in
            lhs.level.priority < rhs.level.priority
        }
    }

    var summaryKey: String {
        switch level {
        case .excellent:
            return "weather.rideability.summary.excellent"
        case .good:
            return "weather.rideability.summary.good"
        case .caution:
            return "weather.rideability.summary.caution"
        case .unsafe:
            return "weather.rideability.summary.unsafe"
        }
    }

    static func baseline(
        settings: HealthReminderSettings,
        monitor: WeatherRiskMonitor = WeatherRiskMonitor()
    ) -> WeatherRideabilityReport {
        let context = WeatherQueryContext.rideStart()
        let weatherReport = monitor.report(for: .mockBaseline, settings: settings)
        return WeatherRideabilityEngine().report(
            weatherReport: weatherReport,
            context: context,
            spot: nil
        )
    }
}
