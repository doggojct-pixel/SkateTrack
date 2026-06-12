// [自主區] WeatherQueryContext.swift
// 用途：描述 Task-022 天氣查詢目的與本機場地脈絡；不讀取定位、不接網路、不包含 API key。
// 委派至：WeatherProviding 依 context 產生 mock / disabled 快照，未來真實 provider 可在此邊界後替換。

import Foundation

enum WeatherQueryPurpose: String, Codable, Sendable {
    case rideStart
    case spotPreview

    var localizationKey: String {
        switch self {
        case .rideStart:
            return "weather.context.rideStart"
        case .spotPreview:
            return "weather.context.spotPreview"
        }
    }
}

struct WeatherQueryContext: Codable, Equatable, Sendable {
    var purpose: WeatherQueryPurpose
    var coordinate: GeoCoordinate?
    var spotID: UUID?
    var spotName: String?
    var sportMode: SportMode?

    init(
        purpose: WeatherQueryPurpose = .rideStart,
        coordinate: GeoCoordinate? = nil,
        spotID: UUID? = nil,
        spotName: String? = nil,
        sportMode: SportMode? = nil
    ) {
        self.purpose = purpose
        self.coordinate = coordinate
        self.spotID = spotID
        self.spotName = spotName?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sportMode = sportMode
    }

    static func rideStart(
        sportMode: SportMode? = nil,
        selectedSpot: SpotProfile? = nil
    ) -> WeatherQueryContext {
        WeatherQueryContext(
            purpose: .rideStart,
            coordinate: selectedSpot?.coordinate,
            spotID: selectedSpot?.id,
            spotName: selectedSpot?.name,
            sportMode: sportMode
        )
    }

    static func spotPreview(_ spot: SpotProfile) -> WeatherQueryContext {
        WeatherQueryContext(
            purpose: .spotPreview,
            coordinate: spot.coordinate,
            spotID: spot.id,
            spotName: spot.name,
            sportMode: spot.preferredSportModes.first
        )
    }

    var hasSpot: Bool {
        spotID != nil
    }

    var hasCoordinate: Bool {
        coordinate != nil
    }
}
