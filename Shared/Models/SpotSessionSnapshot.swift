// [協作區] Shared/Models/SpotSessionSnapshot.swift
// 用途：保存 Session 當下的場地歸屬快照，讓歷史紀錄不依賴仍存在的 SpotProfile。
// 委派至：SessionData、SessionEntityMapper、History、Summary 與未來 export/report。

import Foundation

struct SpotSessionSnapshot: Codable, Sendable, Equatable {
    let spotID: UUID
    let name: String
    let activityFamily: SpotActivityFamily
    let coordinate: GeoCoordinate?
    let radiusMeters: Double
    let archivedAt: Date

    init(
        spotID: UUID,
        name: String,
        activityFamily: SpotActivityFamily,
        coordinate: GeoCoordinate?,
        radiusMeters: Double,
        archivedAt: Date = Date()
    ) {
        self.spotID = spotID
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.activityFamily = activityFamily
        self.coordinate = coordinate
        self.radiusMeters = max(20, min(radiusMeters, 1_000))
        self.archivedAt = archivedAt
    }

    init(spot: SpotProfile, archivedAt: Date = Date()) {
        self.init(
            spotID: spot.id,
            name: spot.name,
            activityFamily: spot.activityFamily,
            coordinate: spot.coordinate,
            radiusMeters: spot.radiusMeters,
            archivedAt: archivedAt
        )
    }

    var displayName: String {
        name.isEmpty ? NSLocalizedString("spots.untitled", comment: "") : name
    }
}
