// [協作區] Shared/Models/SpotProfile.swift
// 用途：定義使用者收藏的滑行場地資料，包含位置、路面評分、備註、照片與造訪紀錄。
// 委派至：spot management、session linking、route map 與 macOS filtering。

import Foundation

enum SurfaceRating: Int, Codable, Sendable, CaseIterable {
    case poor = 1
    case fair = 2
    case good = 3
    case excellent = 4
}

struct SpotProfile: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var name: String
    var coordinate: GeoCoordinate?
    var surfaceRating: SurfaceRating?
    var notes: String?
    var photoAssetIdentifiers: [String]
    var visitCount: Int
    var lastVisitedAt: Date?
    var preferredSportModes: [SportMode]

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: GeoCoordinate? = nil,
        surfaceRating: SurfaceRating? = nil,
        notes: String? = nil,
        photoAssetIdentifiers: [String] = [],
        visitCount: Int = 0,
        lastVisitedAt: Date? = nil,
        preferredSportModes: [SportMode] = []
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.surfaceRating = surfaceRating
        self.notes = notes
        self.photoAssetIdentifiers = photoAssetIdentifiers
        self.visitCount = visitCount
        self.lastVisitedAt = lastVisitedAt
        self.preferredSportModes = preferredSportModes
    }
}
