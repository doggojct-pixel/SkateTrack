// [自主區] AchievementEngine.swift
// 用途：根據本機 Session / Equipment / Spot 統計資料計算成就進度，不依賴 SwiftUI。
// 委派至：useAchievements 組合 Repository 資料並保存解鎖狀態。

import Foundation

struct AchievementEvaluationContext: Sendable {
    let sessions: [SessionData]
    let equipment: [EquipmentProfile]
    let spots: [SpotProfile]
    let now: Date
    let calendar: Calendar

    init(
        sessions: [SessionData],
        equipment: [EquipmentProfile],
        spots: [SpotProfile],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.sessions = sessions
        self.equipment = equipment
        self.spots = spots
        self.now = now
        self.calendar = calendar
    }

    var totalDistanceKilometers: Double {
        sessions.reduce(0) { partialResult, session in
            partialResult + (session.summaryMetrics?.distanceKilometers ?? 0)
        }
    }

    var weeklyDistanceKilometers: Double {
        sessionsInCurrentWeek.reduce(0) { partialResult, session in
            partialResult + (session.summaryMetrics?.distanceKilometers ?? 0)
        }
    }

    var maxSpeedKilometersPerHour: Double {
        sessions.map { $0.summaryMetrics?.maxSpeedKilometersPerHour ?? 0 }.max() ?? 0
    }

    var uniqueSpotCount: Int {
        Set(sessions.compactMap(\.spotID)).count
    }

    var gearTrackedSessionCount: Int {
        sessions.filter { $0.equipmentID != nil || $0.equipmentSnapshot != nil }.count
    }

    var noFallSessionCount: Int {
        sessions.filter { $0.endDate != nil && $0.fallEvents.isEmpty }.count
    }

    var shareReadySessionCount: Int {
        sessions.filter { $0.endDate != nil && $0.summaryMetrics != nil }.count
    }

    var sessionsInCurrentWeek: [SessionData] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return sessions.filter { week.contains($0.startDate) }
    }
}

enum AchievementEngine {
    static func evaluate(
        definitions: [AchievementDefinition] = AchievementCatalog.definitions,
        context: AchievementEvaluationContext,
        unlockedRecords: [String: AchievementUnlockRecord],
        canEvaluateAdvanced: Bool
    ) -> [AchievementProgress] {
        definitions.map { definition in
            let currentValue = currentValue(for: definition.ruleKind, context: context)
            let unlockedAt = unlockedRecords[definition.id]?.unlockedAt
            let effectiveCurrentValue = definition.isAdvanced && !canEvaluateAdvanced ? 0 : currentValue
            return AchievementProgress(
                definition: definition,
                currentValue: effectiveCurrentValue,
                unlockedAt: definition.isAdvanced && !canEvaluateAdvanced ? nil : unlockedAt
            )
        }
    }

    static func newlyUnlockedRecords(
        from progress: [AchievementProgress],
        existingRecords: [String: AchievementUnlockRecord],
        now: Date = Date()
    ) -> [AchievementUnlockRecord] {
        progress.compactMap { item in
            guard item.currentValue >= item.definition.targetValue else { return nil }
            guard existingRecords[item.id] == nil else { return nil }
            return AchievementUnlockRecord(id: item.id, unlockedAt: now)
        }
    }

    private static func currentValue(
        for ruleKind: AchievementRuleKind,
        context: AchievementEvaluationContext
    ) -> Double {
        switch ruleKind {
        case .completedSessions:
            return Double(context.sessions.count)
        case .weeklyDistanceKilometers:
            return context.weeklyDistanceKilometers
        case .totalDistanceKilometers:
            return context.totalDistanceKilometers
        case .maxSpeedKilometersPerHour:
            return context.maxSpeedKilometersPerHour
        case .uniqueSpotCount:
            return Double(context.uniqueSpotCount)
        case .gearTrackedSessions:
            return Double(context.gearTrackedSessionCount)
        case .noFallSessions:
            return Double(context.noFallSessionCount)
        case .shareReadySessions:
            return Double(context.shareReadySessionCount)
        }
    }
}
