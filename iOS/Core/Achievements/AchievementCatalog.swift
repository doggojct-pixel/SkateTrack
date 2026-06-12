// [自主區] AchievementCatalog.swift
// 用途：集中定義 Task-024a 本機成就目錄，避免 UI 或 hooks 硬編規則。
// 委派至：AchievementEngine 評估進度，useAchievements 暴露給 SwiftUI。

import Foundation

enum AchievementCatalog {
    static let definitions: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_ride",
            titleKey: "achievements.firstRide.title",
            subtitleKey: "achievements.firstRide.subtitle",
            category: .consistency,
            ruleKind: .completedSessions,
            targetValue: 1,
            iconSystemName: "flag.checkered"
        ),
        AchievementDefinition(
            id: "five_k_week",
            titleKey: "achievements.fiveKWeek.title",
            subtitleKey: "achievements.fiveKWeek.subtitle",
            category: .distance,
            ruleKind: .weeklyDistanceKilometers,
            targetValue: 5,
            iconSystemName: "calendar.badge.clock"
        ),
        AchievementDefinition(
            id: "distance_25",
            titleKey: "achievements.distance25.title",
            subtitleKey: "achievements.distance25.subtitle",
            category: .distance,
            ruleKind: .totalDistanceKilometers,
            targetValue: 25,
            iconSystemName: "point.topleft.down.curvedto.point.bottomright.up"
        ),
        AchievementDefinition(
            id: "speed_spark",
            titleKey: "achievements.speedSpark.title",
            subtitleKey: "achievements.speedSpark.subtitle",
            category: .distance,
            ruleKind: .maxSpeedKilometersPerHour,
            targetValue: 20,
            iconSystemName: "bolt.fill"
        ),
        AchievementDefinition(
            id: "spot_explorer",
            titleKey: "achievements.spotExplorer.title",
            subtitleKey: "achievements.spotExplorer.subtitle",
            category: .exploration,
            ruleKind: .uniqueSpotCount,
            targetValue: 3,
            iconSystemName: "mappin.and.ellipse"
        ),
        AchievementDefinition(
            id: "gear_tracker",
            titleKey: "achievements.gearTracker.title",
            subtitleKey: "achievements.gearTracker.subtitle",
            category: .gear,
            ruleKind: .gearTrackedSessions,
            targetValue: 3,
            iconSystemName: "wrench.and.screwdriver.fill"
        ),
        AchievementDefinition(
            id: "safety_first",
            titleKey: "achievements.safetyFirst.title",
            subtitleKey: "achievements.safetyFirst.subtitle",
            category: .safety,
            ruleKind: .noFallSessions,
            targetValue: 1,
            iconSystemName: "shield.checkered"
        ),
        AchievementDefinition(
            id: "share_ready",
            titleKey: "achievements.shareReady.title",
            subtitleKey: "achievements.shareReady.subtitle",
            category: .sharing,
            ruleKind: .shareReadySessions,
            targetValue: 1,
            iconSystemName: "square.and.arrow.up.fill"
        ),
        AchievementDefinition(
            id: "distance_100_advanced",
            titleKey: "achievements.advanced.distance100.title",
            subtitleKey: "achievements.advanced.distance100.subtitle",
            category: .distance,
            ruleKind: .totalDistanceKilometers,
            targetValue: 100,
            iconSystemName: "flame.fill",
            isAdvanced: true
        ),
        AchievementDefinition(
            id: "ten_sessions_advanced",
            titleKey: "achievements.advanced.tenSessions.title",
            subtitleKey: "achievements.advanced.tenSessions.subtitle",
            category: .consistency,
            ruleKind: .completedSessions,
            targetValue: 10,
            iconSystemName: "sparkles",
            isAdvanced: true
        )
    ]
}
