// [協作區] Shared/Models/WeeklyChallenge.swift
// 用途：定義 SkateTrack 本機每週挑戰的跨平台資料模型，供挑戰引擎與 UI 共用。
// 委派至：WeeklyChallengeEngine、useAchievements 與後續 Task-024b 進階挑戰 polish。

import Foundation

enum WeeklyChallengeKind: String, Codable, Sendable, CaseIterable {
    case weeklyDistanceKilometers
    case weeklySessionCount
    case weeklyUniqueSpotCount
    case weeklyNoFallSessionCount
    case weeklyGearTrackedSessionCount
}

struct WeeklyChallengeDefinition: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let titleKey: String
    let subtitleKey: String
    let kind: WeeklyChallengeKind
    let targetValue: Double
    let iconSystemName: String
    let isAdvanced: Bool

    init(
        id: String,
        titleKey: String,
        subtitleKey: String,
        kind: WeeklyChallengeKind,
        targetValue: Double,
        iconSystemName: String,
        isAdvanced: Bool = false
    ) {
        self.id = id
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.kind = kind
        self.targetValue = max(1, targetValue)
        self.iconSystemName = iconSystemName
        self.isAdvanced = isAdvanced
    }
}

struct WeeklyChallengeProgress: Identifiable, Codable, Sendable, Equatable {
    let definition: WeeklyChallengeDefinition
    let currentValue: Double
    let weekStart: Date
    let weekEnd: Date
    let weekIdentifier: String
    let completedAt: Date?

    var id: String { definition.id }

    var completionFraction: Double {
        min(max(currentValue / definition.targetValue, 0), 1)
    }

    var isComplete: Bool {
        completedAt != nil || currentValue >= definition.targetValue
    }

    var isAdvanced: Bool {
        definition.isAdvanced
    }
}
