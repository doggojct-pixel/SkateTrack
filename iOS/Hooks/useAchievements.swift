// [協作區 — 邊界適配層] useAchievements.swift
// 用途：向 SwiftUI 暴露本機成就與每週挑戰狀態，隔離 repository、engine 與 UserDefaults 細節。
// 委派至：AchievementEngine、WeeklyChallengeEngine、AchievementUnlockStore 與本機 repositories。

import Combine
import Foundation

enum AchievementsViewState: Equatable {
    case loading
    case content
    case error(String)
}

struct AchievementDashboardStats: Equatable, Sendable {
    let totalSessions: Int
    let totalDistanceKilometers: Double
    let weeklyDistanceKilometers: Double
    let unlockedCount: Int
    let totalVisibleAchievements: Int
    let equipmentCount: Int
    let spotCount: Int
    let completedWeeklyChallengeCount: Int
}

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published private(set) var viewState: AchievementsViewState = .loading
    @Published private(set) var achievements: [AchievementProgress] = []
    @Published private(set) var weeklyChallenges: [WeeklyChallengeProgress] = []
    @Published private(set) var stats = AchievementDashboardStats(
        totalSessions: 0,
        totalDistanceKilometers: 0,
        weeklyDistanceKilometers: 0,
        unlockedCount: 0,
        totalVisibleAchievements: 0,
        equipmentCount: 0,
        spotCount: 0,
        completedWeeklyChallengeCount: 0
    )

    private let sessionRepository: SessionRepositoryProtocol
    private let equipmentRepository: EquipmentRepositoryProtocol
    private let spotRepository: SpotRepositoryProtocol
    private let unlockStore: AchievementUnlockStoring
    private let weeklyCompletionStore: WeeklyChallengeCompletionStoring
    private let subscriptionStatus: SubscriptionStatusViewModel
    private var hasLoaded = false

    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        sessionRepository: SessionRepositoryProtocol = SessionRepository.shared,
        equipmentRepository: EquipmentRepositoryProtocol = EquipmentRepository.shared,
        spotRepository: SpotRepositoryProtocol = SpotRepository.shared,
        unlockStore: AchievementUnlockStoring = AchievementUnlockStore.shared,
        weeklyCompletionStore: WeeklyChallengeCompletionStoring = WeeklyChallengeCompletionStore.shared
    ) {
        self.subscriptionStatus = subscriptionStatus
        self.sessionRepository = sessionRepository
        self.equipmentRepository = equipmentRepository
        self.spotRepository = spotRepository
        self.unlockStore = unlockStore
        self.weeklyCompletionStore = weeklyCompletionStore
    }

    var hasAdvancedChallengeAccess: Bool {
        subscriptionStatus.hasAccess(to: .advancedChallenges)
    }

    var basicAchievements: [AchievementProgress] {
        achievements.filter { !$0.isAdvanced }
    }

    var advancedAchievements: [AchievementProgress] {
        achievements.filter(\.isAdvanced)
    }

    var basicWeeklyChallenges: [WeeklyChallengeProgress] {
        weeklyChallenges.filter { !$0.isAdvanced }
    }

    var advancedWeeklyChallenges: [WeeklyChallengeProgress] {
        weeklyChallenges.filter(\.isAdvanced)
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        viewState = .loading
        do {
            let sessions = try await sessionRepository.fetchRecentSessions(limit: 500)
            let equipment = try await equipmentRepository.fetchEquipment()
            let spots = try await spotRepository.fetchSpots()
            let context = AchievementEvaluationContext(
                sessions: sessions,
                equipment: equipment,
                spots: spots
            )
            let records = unlockStore.loadRecords()
            let evaluated = AchievementEngine.evaluate(
                context: context,
                unlockedRecords: records,
                canEvaluateAdvanced: hasAdvancedChallengeAccess
            )
            let newlyUnlocked = AchievementEngine.newlyUnlockedRecords(
                from: evaluated,
                existingRecords: records
            )
            let mergedRecords = unlockStore.mergeUnlockedRecords(newlyUnlocked)
            let refreshed = AchievementEngine.evaluate(
                context: context,
                unlockedRecords: mergedRecords,
                canEvaluateAdvanced: hasAdvancedChallengeAccess
            )

            achievements = sortAchievements(refreshed)

            let weeklyRecords = weeklyCompletionStore.loadRecords()
            let evaluatedChallenges = WeeklyChallengeEngine.evaluate(
                context: context,
                completionRecords: weeklyRecords,
                canEvaluateAdvanced: hasAdvancedChallengeAccess
            )
            let newChallengeRecords = WeeklyChallengeEngine.newlyCompletedRecords(
                from: evaluatedChallenges,
                existingRecords: weeklyRecords
            )
            let mergedChallengeRecords = weeklyCompletionStore.mergeCompletedRecords(newChallengeRecords)
            weeklyChallenges = WeeklyChallengeEngine.evaluate(
                context: context,
                completionRecords: mergedChallengeRecords,
                canEvaluateAdvanced: hasAdvancedChallengeAccess
            )
            stats = makeStats(context: context, achievements: achievements, weeklyChallenges: weeklyChallenges)
            hasLoaded = true
            viewState = .content
        } catch let error as RepositoryError {
            hasLoaded = true
            viewState = .error(error.localizationKey)
        } catch {
            hasLoaded = true
            viewState = .error("achievements.error.generic")
        }
    }

    private func sortAchievements(_ progress: [AchievementProgress]) -> [AchievementProgress] {
        progress.sorted { lhs, rhs in
            if lhs.isAdvanced != rhs.isAdvanced { return !lhs.isAdvanced }
            if lhs.isUnlocked != rhs.isUnlocked { return lhs.isUnlocked && !rhs.isUnlocked }
            if lhs.definition.category != rhs.definition.category {
                return lhs.definition.category.rawValue < rhs.definition.category.rawValue
            }
            return lhs.definition.id < rhs.definition.id
        }
    }

    private func makeStats(
        context: AchievementEvaluationContext,
        achievements: [AchievementProgress],
        weeklyChallenges: [WeeklyChallengeProgress]
    ) -> AchievementDashboardStats {
        let visibleAchievements = achievements.filter { !$0.isAdvanced || hasAdvancedChallengeAccess }
        let visibleChallenges = weeklyChallenges.filter { !$0.isAdvanced || hasAdvancedChallengeAccess }
        return AchievementDashboardStats(
            totalSessions: context.sessions.count,
            totalDistanceKilometers: context.totalDistanceKilometers,
            weeklyDistanceKilometers: context.weeklyDistanceKilometers,
            unlockedCount: visibleAchievements.filter(\.isUnlocked).count,
            totalVisibleAchievements: visibleAchievements.count,
            equipmentCount: context.equipment.count,
            spotCount: context.spots.count,
            completedWeeklyChallengeCount: visibleChallenges.filter(\.isComplete).count
        )
    }
}

@MainActor
func useAchievements(
    subscriptionStatus: SubscriptionStatusViewModel,
    sessionRepository: SessionRepositoryProtocol = SessionRepository.shared,
    equipmentRepository: EquipmentRepositoryProtocol = EquipmentRepository.shared,
    spotRepository: SpotRepositoryProtocol = SpotRepository.shared
) -> AchievementsViewModel {
    AchievementsViewModel(
        subscriptionStatus: subscriptionStatus,
        sessionRepository: sessionRepository,
        equipmentRepository: equipmentRepository,
        spotRepository: spotRepository
    )
}
