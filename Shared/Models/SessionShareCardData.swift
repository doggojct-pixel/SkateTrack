// [協作區] SessionShareCardData.swift
// 用途：定義 Session 分享卡的本機預覽資料，供 Summary、匯出與未來分享流程共用。
// 委派至：useSessionShareCard 產生顯示資料；Task-023b 之後才負責圖片渲染與系統分享。

import Foundation

struct SessionShareCardData: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let sportModeLocalizationKey: String
    let powerTypeLocalizationKey: String
    let dateLine: String
    let durationText: String
    let distanceText: String
    let maxSpeedText: String
    let averageSpeedText: String
    let elevationText: String
    let movingRatioText: String
    let fallCountText: String
    let trickCountText: String
    let routeStatusLocalizationKey: String
    let safetyStatusText: String
    let spotName: String?
    let equipmentName: String?
    let metrics: [SessionShareCardMetricData]

    init(
        id: UUID,
        sportModeLocalizationKey: String,
        powerTypeLocalizationKey: String,
        dateLine: String,
        durationText: String,
        distanceText: String,
        maxSpeedText: String,
        averageSpeedText: String,
        elevationText: String,
        movingRatioText: String,
        fallCountText: String,
        trickCountText: String,
        routeStatusLocalizationKey: String,
        safetyStatusText: String,
        spotName: String?,
        equipmentName: String?,
        metrics: [SessionShareCardMetricData]
    ) {
        self.id = id
        self.sportModeLocalizationKey = sportModeLocalizationKey
        self.powerTypeLocalizationKey = powerTypeLocalizationKey
        self.dateLine = dateLine
        self.durationText = durationText
        self.distanceText = distanceText
        self.maxSpeedText = maxSpeedText
        self.averageSpeedText = averageSpeedText
        self.elevationText = elevationText
        self.movingRatioText = movingRatioText
        self.fallCountText = fallCountText
        self.trickCountText = trickCountText
        self.routeStatusLocalizationKey = routeStatusLocalizationKey
        self.safetyStatusText = safetyStatusText
        self.spotName = Self.nilIfBlank(spotName)
        self.equipmentName = Self.nilIfBlank(equipmentName)
        self.metrics = metrics
    }

    private static func nilIfBlank(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

struct SessionShareCardMetricData: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let labelLocalizationKey: String
    let value: String
    let systemImageName: String
    let accentName: SessionShareCardAccent
}

enum SessionShareCardAccent: String, Codable, Sendable, Equatable {
    case teal
    case purple
    case amber
    case white
}
