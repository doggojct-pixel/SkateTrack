// [自主區] WeeklyChallengeEngine.swift
// 用途：計算本機每週挑戰進度，不依賴遠端排行榜、推播或伺服器驗證。
// 委派至：useAchievements 與 WeeklyChallengeCardView；Task-024b 可在此邊界深化挑戰規則。

import Foundation

enum WeeklyChallengeEngine {
    static let definitions: [WeeklyChallengeDefinition] = [
        WeeklyChallengeDefinition(
            id: "weekly_5k",
            titleKey: "challenges.weekly5K.title",
            subtitleKey: "challenges.weekly5K.subtitle",
            kind: .weeklyDistanceKilometers,
            targetValue: 5,
            iconSystemName: "figure.roll"
        ),
        WeeklyChallengeDefinition(
            id: "weekly_3_sessions",
            titleKey: "challenges.weekly3Sessions.title",
            subtitleKey: "challenges.weekly3Sessions.subtitle",
            kind: .weeklySessionCount,
            targetValue: 3,
            iconSystemName: "calendar"
        ),
        WeeklyChallengeDefinition(
            id: "weekly_3_spots_advanced",
            titleKey: "challenges.advanced.spotVariety.title",
            subtitleKey: "challenges.advanced.spotVariety.subtitle",
            kind: .weeklyUniqueSpotCount,
            targetValue: 3,
            iconSystemName: "map.fill",
            isAdvanced: true
        )
    ]

    static func evaluate(
        definitions: [WeeklyChallengeDefinition] = Self.definitions,
        context: AchievementEvaluationContext,
        canEvaluateAdvanced: Bool
    ) -> [WeeklyChallengeProgress] {
        let week = context.calendar.dateInterval(of: .weekOfYear, for: context.now)
        let weekStart = week?.start ?? context.now
        let weekEnd = week?.end ?? context.now

        return definitions.map { definition in
            let rawValue = currentValue(for: definition.kind, context: context)
            return WeeklyChallengeProgress(
                definition: definition,
                currentValue: definition.isAdvanced && !canEvaluateAdvanced ? 0 : rawValue,
                weekStart: weekStart,
                weekEnd: weekEnd
            )
        }
    }

    private static func currentValue(
        for kind: WeeklyChallengeKind,
        context: AchievementEvaluationContext
    ) -> Double {
        switch kind {
        case .weeklyDistanceKilometers:
            return context.weeklyDistanceKilometers
        case .weeklySessionCount:
            return Double(context.sessionsInCurrentWeek.count)
        case .weeklyUniqueSpotCount:
            return Double(Set(context.sessionsInCurrentWeek.compactMap(\.spotID)).count)
        }
    }
}
