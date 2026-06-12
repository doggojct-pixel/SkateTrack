// [協作區 — 邊界適配層] useAchievementDashboard.swift
// 用途：向 Ride page 暴露輕量成就 / 每週挑戰 dashboard 狀態，避免 SessionStartView 直接讀 repository。
// 委派至：AchievementEngine、WeeklyChallengeEngine 與本機 repositories。

import Foundation

struct AchievementDashboardSnapshot: Equatable, Sendable {
    let unlockedCount: Int
    let totalVisibleAchievements: Int
    let weeklyChallengeTitleKey: String
    let weeklyChallengeProgressText: String
    let weeklyChallengeCompletionFraction: Double
    let isWeeklyChallengeComplete: Bool

    static let empty = AchievementDashboardSnapshot(
        unlockedCount: 0,
        totalVisibleAchievements: 0,
        weeklyChallengeTitleKey: "challenges.weekly5K.title",
        weeklyChallengeProgressText: "0.0 / 5.0",
        weeklyChallengeCompletionFraction: 0,
        isWeeklyChallengeComplete: false
    )
}

@MainActor
final class AchievementDashboardViewModel: ObservableObject {
    @Published private(set) var snapshot: AchievementDashboardSnapshot = .empty
    @Published private(set) var isLoading = false

    private let sessionRepository: SessionRepositoryProtocol
    private let equipmentRepository: EquipmentRepositoryProtocol
    private let spotRepository: SpotRepositoryProtocol
    private let unlockStore: AchievementUnlockStoring
    private let subscriptionStatus: SubscriptionStatusViewModel
    private var hasLoaded = false

    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        sessionRepository: SessionRepositoryProtocol = SessionRepository.shared,
        equipmentRepository: EquipmentRepositoryProtocol = EquipmentRepository.shared,
        spotRepository: SpotRepositoryProtocol = SpotRepository.shared,
        unlockStore: AchievementUnlockStoring = AchievementUnlockStore.shared
    ) {
        self.subscriptionStatus = subscriptionStatus
        self.sessionRepository = sessionRepository
        self.equipmentRepository = equipmentRepository
        self.spotRepository = spotRepository
        self.unlockStore = unlockStore
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
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
            let achievements = AchievementEngine.evaluate(
                context: context,
                unlockedRecords: records,
                canEvaluateAdvanced: subscriptionStatus.hasAccess(to: .advancedChallenges)
            )
            let weeklyChallenges = WeeklyChallengeEngine.evaluate(
                context: context,
                completionRecords: [:],
                canEvaluateAdvanced: subscriptionStatus.hasAccess(to: .advancedChallenges)
            )
            snapshot = makeSnapshot(achievements: achievements, weeklyChallenges: weeklyChallenges)
            hasLoaded = true
        } catch {
            hasLoaded = true
            snapshot = .empty
        }
    }

    private func makeSnapshot(
        achievements: [AchievementProgress],
        weeklyChallenges: [WeeklyChallengeProgress]
    ) -> AchievementDashboardSnapshot {
        let visibleAchievements = achievements.filter { !$0.isAdvanced || subscriptionStatus.hasAccess(to: .advancedChallenges) }
        let challenge = weeklyChallenges.first { !$0.isAdvanced } ?? weeklyChallenges.first
        return AchievementDashboardSnapshot(
            unlockedCount: visibleAchievements.filter(\.isUnlocked).count,
            totalVisibleAchievements: visibleAchievements.count,
            weeklyChallengeTitleKey: challenge?.definition.titleKey ?? "challenges.weekly5K.title",
            weeklyChallengeProgressText: challenge.map(Self.progressText) ?? "0.0 / 5.0",
            weeklyChallengeCompletionFraction: challenge?.completionFraction ?? 0,
            isWeeklyChallengeComplete: challenge?.isComplete ?? false
        )
    }

    private static func progressText(for challenge: WeeklyChallengeProgress) -> String {
        String(
            format: "%.1f / %.1f",
            locale: .autoupdatingCurrent,
            challenge.currentValue,
            challenge.definition.targetValue
        )
    }
}

@MainActor
func useAchievementDashboard(
    subscriptionStatus: SubscriptionStatusViewModel,
    sessionRepository: SessionRepositoryProtocol = SessionRepository.shared,
    equipmentRepository: EquipmentRepositoryProtocol = EquipmentRepository.shared,
    spotRepository: SpotRepositoryProtocol = SpotRepository.shared
) -> AchievementDashboardViewModel {
    AchievementDashboardViewModel(
        subscriptionStatus: subscriptionStatus,
        sessionRepository: sessionRepository,
        equipmentRepository: equipmentRepository,
        spotRepository: spotRepository
    )
}
