// [自主區] WeatherRiskMonitor.swift
// 用途：依本機天氣快照與健康提醒門檻產生滑行適合度報告；不讀取真實天氣、不排程通知。
// 委派至：useWeatherRisk 管理資料載入，WeatherSuitabilityCardView 呈現報告。

import Foundation

final class WeatherRiskMonitor {
    func report(
        for snapshot: WeatherRiskSnapshot,
        settings: HealthReminderSettings
    ) -> WeatherSuitabilityReport {
        let heatThreshold = settings.rule(for: .heatRisk).threshold ?? HealthReminderKind.heatRisk.defaultThreshold ?? 35
        let uvThreshold = settings.rule(for: .uvRisk).threshold ?? HealthReminderKind.uvRisk.defaultThreshold ?? 6

        let factors = [
            heatFactor(snapshot: snapshot, threshold: heatThreshold),
            uvFactor(snapshot: snapshot, threshold: uvThreshold),
            rainFactor(snapshot: snapshot)
        ]

        let level = factors.map(\.level).max { lhs, rhs in
            lhs.priority < rhs.priority
        } ?? .good

        return WeatherSuitabilityReport(
            snapshot: snapshot,
            level: level,
            factors: factors
        )
    }

    private func heatFactor(snapshot: WeatherRiskSnapshot, threshold: Double) -> WeatherRiskFactor {
        let level: WeatherSuitabilityLevel
        let messageKey: String
        if snapshot.temperatureCelsius >= threshold + 4 {
            level = .unsafe
            messageKey = "weather.risk.heat.unsafe"
        } else if snapshot.temperatureCelsius >= threshold {
            level = .caution
            messageKey = "weather.risk.heat.caution"
        } else if snapshot.temperatureCelsius >= threshold - 4 {
            level = .good
            messageKey = "weather.risk.heat.good"
        } else {
            level = .excellent
            messageKey = "weather.risk.heat.excellent"
        }

        return WeatherRiskFactor(
            id: .heat,
            level: level,
            valueText: String(format: "%.0f°C", snapshot.temperatureCelsius),
            messageKey: messageKey
        )
    }

    private func uvFactor(snapshot: WeatherRiskSnapshot, threshold: Double) -> WeatherRiskFactor {
        let level: WeatherSuitabilityLevel
        let messageKey: String
        if snapshot.uvIndex >= threshold + 3 {
            level = .unsafe
            messageKey = "weather.risk.uv.unsafe"
        } else if snapshot.uvIndex >= threshold {
            level = .caution
            messageKey = "weather.risk.uv.caution"
        } else if snapshot.uvIndex >= max(1, threshold - 2) {
            level = .good
            messageKey = "weather.risk.uv.good"
        } else {
            level = .excellent
            messageKey = "weather.risk.uv.excellent"
        }

        return WeatherRiskFactor(
            id: .uv,
            level: level,
            valueText: String(format: "UV %.0f", snapshot.uvIndex),
            messageKey: messageKey
        )
    }

    private func rainFactor(snapshot: WeatherRiskSnapshot) -> WeatherRiskFactor {
        let probability = max(0, min(snapshot.precipitationProbability, 1))
        let level: WeatherSuitabilityLevel
        let messageKey: String

        if probability >= 0.75 {
            level = .unsafe
            messageKey = "weather.risk.rain.unsafe"
        } else if probability >= 0.45 {
            level = .caution
            messageKey = "weather.risk.rain.caution"
        } else if probability >= 0.20 {
            level = .good
            messageKey = "weather.risk.rain.good"
        } else {
            level = .excellent
            messageKey = "weather.risk.rain.excellent"
        }

        return WeatherRiskFactor(
            id: .rain,
            level: level,
            valueText: "\(Int(probability * 100))%",
            messageKey: messageKey
        )
    }
}
