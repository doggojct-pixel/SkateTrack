// [自主區] WeatherRideabilityEngine.swift
// 用途：將 Task-019c 天氣風險與 Task-021 本機場地資料整合成滑行適合度；不接真實天氣、不持久化結果。
// 委派至：useWeatherRisk 管理當前 context，WeatherSuitabilityCardView / SpotRideabilityCardView 呈現結果。

import Foundation

final class WeatherRideabilityEngine {
    func report(
        weatherReport: WeatherSuitabilityReport,
        context: WeatherQueryContext,
        spot: SpotProfile?
    ) -> WeatherRideabilityReport {
        var factors = weatherReport.factors.map { factor in
            WeatherRideabilityFactor(
                id: WeatherRideabilityFactorKind(weatherRiskKind: factor.id),
                level: factor.level,
                valueText: factor.valueText,
                messageKey: factor.messageKey
            )
        }

        if let spot {
            factors.append(surfaceFactor(for: spot))
            factors.append(crowdFactor(for: spot))
            if let safetyFactor = safetyFactor(for: spot) {
                factors.append(safetyFactor)
            }
        } else {
            factors.append(
                WeatherRideabilityFactor(
                    id: .localContext,
                    level: .good,
                    valueText: NSLocalizedString("weather.rideability.factor.local.none.value", comment: ""),
                    messageKey: "weather.rideability.factor.local.none"
                )
            )
        }

        let level = factors.map(\.level).max { lhs, rhs in
            lhs.priority < rhs.priority
        } ?? weatherReport.level

        return WeatherRideabilityReport(
            weatherReport: weatherReport,
            context: context,
            spotName: spot?.name ?? context.spotName,
            level: level,
            factors: factors
        )
    }

    private func surfaceFactor(for spot: SpotProfile) -> WeatherRideabilityFactor {
        let rating = spot.surfaceRating
        let level: WeatherSuitabilityLevel
        let messageKey: String
        let valueText: String

        switch rating {
        case .excellent:
            level = .excellent
            messageKey = "weather.rideability.factor.surface.excellent"
            valueText = NSLocalizedString(SurfaceRating.excellent.localizationKey, comment: "")
        case .good:
            level = .good
            messageKey = "weather.rideability.factor.surface.good"
            valueText = NSLocalizedString(SurfaceRating.good.localizationKey, comment: "")
        case .fair:
            level = .caution
            messageKey = "weather.rideability.factor.surface.fair"
            valueText = NSLocalizedString(SurfaceRating.fair.localizationKey, comment: "")
        case .poor:
            level = .unsafe
            messageKey = "weather.rideability.factor.surface.poor"
            valueText = NSLocalizedString(SurfaceRating.poor.localizationKey, comment: "")
        case nil:
            level = .good
            messageKey = "weather.rideability.factor.surface.unknown"
            valueText = NSLocalizedString("spots.surface.unknown", comment: "")
        }

        return WeatherRideabilityFactor(
            id: .surface,
            level: level,
            valueText: valueText,
            messageKey: messageKey
        )
    }

    private func crowdFactor(for spot: SpotProfile) -> WeatherRideabilityFactor {
        let level: WeatherSuitabilityLevel
        let messageKey: String

        switch spot.crowdLevel {
        case .quiet:
            level = .excellent
            messageKey = "weather.rideability.factor.crowd.quiet"
        case .moderate:
            level = .good
            messageKey = "weather.rideability.factor.crowd.moderate"
        case .busy:
            level = .caution
            messageKey = "weather.rideability.factor.crowd.busy"
        case .unknown:
            level = .good
            messageKey = "weather.rideability.factor.crowd.unknown"
        }

        return WeatherRideabilityFactor(
            id: .crowd,
            level: level,
            valueText: NSLocalizedString(spot.crowdLevel.localizationKey, comment: ""),
            messageKey: messageKey
        )
    }

    private func safetyFactor(for spot: SpotProfile) -> WeatherRideabilityFactor? {
        guard let safetyRating = spot.safetyRating else { return nil }
        let level: WeatherSuitabilityLevel
        let messageKey: String

        if safetyRating >= 5 {
            level = .excellent
            messageKey = "weather.rideability.factor.safety.excellent"
        } else if safetyRating >= 4 {
            level = .good
            messageKey = "weather.rideability.factor.safety.good"
        } else if safetyRating >= 2 {
            level = .caution
            messageKey = "weather.rideability.factor.safety.caution"
        } else {
            level = .unsafe
            messageKey = "weather.rideability.factor.safety.unsafe"
        }

        return WeatherRideabilityFactor(
            id: .safety,
            level: level,
            valueText: "\(safetyRating)/5",
            messageKey: messageKey
        )
    }
}

private extension WeatherRideabilityFactorKind {
    init(weatherRiskKind: WeatherRiskFactorKind) {
        switch weatherRiskKind {
        case .heat:
            self = .heat
        case .uv:
            self = .uv
        case .rain:
            self = .rain
        }
    }
}
