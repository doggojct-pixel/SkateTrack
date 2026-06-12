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
            id: "weekly_safe_session",
            titleKey: "challenges.weeklySafeSession.title",
            subtitleKey: "challenges.weeklySafeSession.subtitle",
            kind: .weeklyNoFallSessionCount,
            targetValue: 1,
            iconSystemName: "shield.checkered"
        ),
        WeeklyChallengeDefinition(
            id: "weekly_3_spots_advanced",
            titleKey: "challenges.advanced.spotVariety.title",
            subtitleKey: "challenges.advanced.spotVariety.subtitle",
            kind: .weeklyUniqueSpotCount,
            targetValue: 3,
            iconSystemName: "map.fill",
            isAdvanced: true
        ),
        WeeklyChallengeDefinition(
            id: "weekly_gear_flow_advanced",
            titleKey: "challenges.advanced.gearFlow.title",
            subtitleKey: "challenges.advanced.gearFlow.subtitle",
            kind: .weeklyGearTrackedSessionCount,
            targetValue: 3,
            iconSystemName: "wrench.and.screwdriver.fill",
            isAdvanced: true
        )
    ]

    static func evaluate(
        definitions: [WeeklyChallengeDefinition] = Self.definitions,
        context: AchievementEvaluationContext,
        completionRecords: [String: WeeklyChallengeCompletionRecord],
        canEvaluateAdvanced: Bool
    ) -> [WeeklyChallengeProgress] {
        let week = context.calendar.dateInterval(of: .weekOfYear, for: context.now)
        let weekStart = week?.start ?? context.now
        let weekEnd = week?.end ?? context.now
        let weekIdentifier = weekIdentifier(for: weekStart, calendar: context.calendar)

        return definitions.map { definition in
            let rawValue = currentValue(for: definition.kind, context: context)
            let recordID = WeeklyChallengeCompletionRecord.makeID(
                challengeID: definition.id,
                weekIdentifier: weekIdentifier
            )
            let completionRecord = completionRecords[recordID]
            return WeeklyChallengeProgress(
                definition: definition,
                currentValue: definition.isAdvanced && !canEvaluateAdvanced ? 0 : rawValue,
                weekStart: weekStart,
                weekEnd: weekEnd,
                weekIdentifier: weekIdentifier,
                completedAt: definition.isAdvanced && !canEvaluateAdvanced ? nil : completionRecord?.completedAt
            )
        }
    }

    static func newlyCompletedRecords(
        from progress: [WeeklyChallengeProgress],
        existingRecords: [String: WeeklyChallengeCompletionRecord],
        now: Date = Date()
    ) -> [WeeklyChallengeCompletionRecord] {
        progress.compactMap { item in
            guard item.currentValue >= item.definition.targetValue else { return nil }
            let recordID = WeeklyChallengeCompletionRecord.makeID(
                challengeID: item.definition.id,
                weekIdentifier: item.weekIdentifier
            )
            guard existingRecords[recordID] == nil else { return nil }
            return WeeklyChallengeCompletionRecord(
                challengeID: item.definition.id,
                weekIdentifier: item.weekIdentifier,
                completedAt: now
            )
        }
    }

    static func weekIdentifier(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? components.year ?? 0
        let week = components.weekOfYear ?? 0
        return String(format: "%04d-W%02d", year, week)
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
        case .weeklyNoFallSessionCount:
            return Double(context.noFallSessionsInCurrentWeek.count)
        case .weeklyGearTrackedSessionCount:
            return Double(context.gearTrackedSessionsInCurrentWeek.count)
        }
    }
}
