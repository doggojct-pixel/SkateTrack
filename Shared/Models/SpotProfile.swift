// [協作區] Shared/Models/SpotProfile.swift
// 用途：定義使用者收藏的滑行場地資料，包含位置、路面評分、備註、照片、收藏與造訪紀錄。
// 委派至：spot management、session linking、route map、rideability 與 macOS filtering。

import Foundation

enum SurfaceRating: Int, Codable, Sendable, CaseIterable, Identifiable {
    case poor = 1
    case fair = 2
    case good = 3
    case excellent = 4

    var id: Int { rawValue }

    var localizationKey: String {
        switch self {
        case .poor: return "spots.surface.poor"
        case .fair: return "spots.surface.fair"
        case .good: return "spots.surface.good"
        case .excellent: return "spots.surface.excellent"
        }
    }
}

enum SpotActivityFamily: String, Codable, Sendable, CaseIterable, Identifiable {
    case skateboard
    case inline
    case mixed

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .skateboard: return "spots.activity.skateboard"
        case .inline: return "spots.activity.inline"
        case .mixed: return "spots.activity.mixed"
        }
    }
}

enum SpotCrowdLevel: String, Codable, Sendable, CaseIterable, Identifiable {
    case quiet
    case moderate
    case busy
    case unknown

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .quiet: return "spots.crowd.quiet"
        case .moderate: return "spots.crowd.moderate"
        case .busy: return "spots.crowd.busy"
        case .unknown: return "spots.crowd.unknown"
        }
    }
}

struct SpotProfile: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var name: String
    var coordinate: GeoCoordinate?
    var radiusMeters: Double
    var activityFamily: SpotActivityFamily
    var surfaceRating: SurfaceRating?
    var safetyRating: Int?
    var crowdLevel: SpotCrowdLevel
    var notes: String?
    var isFavorite: Bool
    var photoAssetIdentifiers: [String]
    var visitCount: Int
    var lastVisitedAt: Date?
    var preferredSportModes: [SportMode]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: GeoCoordinate? = nil,
        radiusMeters: Double = 120,
        activityFamily: SpotActivityFamily = .mixed,
        surfaceRating: SurfaceRating? = nil,
        safetyRating: Int? = nil,
        crowdLevel: SpotCrowdLevel = .unknown,
        notes: String? = nil,
        isFavorite: Bool = false,
        photoAssetIdentifiers: [String] = [],
        visitCount: Int = 0,
        lastVisitedAt: Date? = nil,
        preferredSportModes: [SportMode] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.coordinate = coordinate
        self.radiusMeters = max(20, min(radiusMeters, 1_000))
        self.activityFamily = activityFamily
        self.surfaceRating = surfaceRating
        self.safetyRating = safetyRating.map { max(1, min($0, 5)) }
        self.crowdLevel = crowdLevel
        self.notes = Self.nilIfBlank(notes)
        self.isFavorite = isFavorite
        self.photoAssetIdentifiers = photoAssetIdentifiers
        self.visitCount = max(0, visitCount)
        self.lastVisitedAt = lastVisitedAt
        self.preferredSportModes = preferredSportModes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var hasCoordinate: Bool {
        coordinate != nil
    }

    private static func nilIfBlank(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
