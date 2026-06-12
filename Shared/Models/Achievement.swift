// [協作區] Shared/Models/Achievement.swift
// 用途：定義 SkateTrack 本機成就目錄、進度與解鎖紀錄的跨平台資料模型。
// 委派至：AchievementEngine、AchievementUnlockStore、useAchievements 與成就 UI。

import Foundation

enum AchievementCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case distance
    case consistency
    case safety
    case exploration
    case gear
    case sharing

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .distance: return "achievements.category.distance"
        case .consistency: return "achievements.category.consistency"
        case .safety: return "achievements.category.safety"
        case .exploration: return "achievements.category.exploration"
        case .gear: return "achievements.category.gear"
        case .sharing: return "achievements.category.sharing"
        }
    }
}

enum AchievementRuleKind: String, Codable, Sendable, CaseIterable {
    case completedSessions
    case weeklyDistanceKilometers
    case totalDistanceKilometers
    case maxSpeedKilometersPerHour
    case uniqueSpotCount
    case gearTrackedSessions
    case noFallSessions
    case shareReadySessions
}

struct AchievementDefinition: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let titleKey: String
    let subtitleKey: String
    let category: AchievementCategory
    let ruleKind: AchievementRuleKind
    let targetValue: Double
    let iconSystemName: String
    let isAdvanced: Bool

    init(
        id: String,
        titleKey: String,
        subtitleKey: String,
        category: AchievementCategory,
        ruleKind: AchievementRuleKind,
        targetValue: Double,
        iconSystemName: String,
        isAdvanced: Bool = false
    ) {
        self.id = id
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.category = category
        self.ruleKind = ruleKind
        self.targetValue = max(1, targetValue)
        self.iconSystemName = iconSystemName
        self.isAdvanced = isAdvanced
    }
}

struct AchievementProgress: Identifiable, Codable, Sendable, Equatable {
    let definition: AchievementDefinition
    let currentValue: Double
    let unlockedAt: Date?

    var id: String { definition.id }

    var completionFraction: Double {
        min(max(currentValue / definition.targetValue, 0), 1)
    }

    var isUnlocked: Bool {
        unlockedAt != nil || currentValue >= definition.targetValue
    }

    var isAdvanced: Bool {
        definition.isAdvanced
    }
}

struct AchievementUnlockRecord: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let unlockedAt: Date
    var seenAt: Date?

    init(id: String, unlockedAt: Date = Date(), seenAt: Date? = nil) {
        self.id = id
        self.unlockedAt = unlockedAt
        self.seenAt = seenAt
    }
}
