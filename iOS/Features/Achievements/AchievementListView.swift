// [協作區] AchievementListView.swift
// 用途：呈現 Task-024a 本機成就與每週挑戰入口，不直接碰 Core Data 或 repositories。
// 委派至：useAchievements、AchievementCardView、WeeklyChallengeCardView 與 SubscriptionPaywallView。

import SwiftUI

struct AchievementListView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @StateObject private var viewModel: AchievementsViewModel
    @State private var isPaywallPresented = false

    @MainActor
    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        viewModel: AchievementsViewModel? = nil
    ) {
        self.subscriptionStatus = subscriptionStatus
        _viewModel = StateObject(
            wrappedValue: viewModel ?? AchievementsViewModel(subscriptionStatus: subscriptionStatus)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                            .padding(.top, proxy.safeAreaInsets.top + 24)
                        dashboardStats
                        content
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(30, proxy.safeAreaInsets.bottom + 26))
                }
                .refreshable { await viewModel.reload() }
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: subscriptionStatus.isSubscriber) { _, _ in
            Task { await viewModel.reload() }
        }
        .sheet(isPresented: $isPaywallPresented) {
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: .advancedChallenges
            )
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("achievement-list-view")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3,
                    SkateTrackSessionStartColors.navy2,
                    SkateTrackSessionStartColors.navy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [SkateTrackSessionStartColors.purple.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 16,
                endRadius: 430
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("achievements.eyebrow")
                .tracking(2)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .textCase(.uppercase)

            Text("achievements.title")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("achievements.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dashboardStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statTile(value: unlockedText, labelKey: "achievements.stats.unlocked", accentColor: SkateTrackSessionStartColors.teal)
            statTile(value: distanceText, labelKey: "achievements.stats.distance", accentColor: SkateTrackSessionStartColors.amber)
            statTile(value: "\(viewModel.stats.totalSessions)", labelKey: "achievements.stats.sessions", accentColor: SkateTrackSessionStartColors.purple)
            statTile(value: weeklyDistanceText, labelKey: "achievements.stats.weekly", accentColor: SkateTrackSessionStartColors.accent2)
        }
        .accessibilityIdentifier("achievement-dashboard-stats")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            loadingState
        case let .error(errorKey):
            errorState(errorKey)
        case .content:
            contentSections
        }
    }

    private var contentSections: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("challenges.weekly.title")
            ForEach(viewModel.basicWeeklyChallenges) { challenge in
                WeeklyChallengeCardView(
                    challenge: challenge,
                    hasAdvancedAccess: viewModel.hasAdvancedChallengeAccess,
                    onUnlockAdvanced: { isPaywallPresented = true }
                )
            }

            if !viewModel.advancedWeeklyChallenges.isEmpty {
                ForEach(viewModel.advancedWeeklyChallenges) { challenge in
                    WeeklyChallengeCardView(
                        challenge: challenge,
                        hasAdvancedAccess: viewModel.hasAdvancedChallengeAccess,
                        onUnlockAdvanced: { isPaywallPresented = true }
                    )
                }
            }

            sectionTitle("achievements.basic.title")
            ForEach(viewModel.basicAchievements) { progress in
                AchievementCardView(
                    progress: progress,
                    hasAdvancedAccess: viewModel.hasAdvancedChallengeAccess,
                    onUnlockAdvanced: { isPaywallPresented = true }
                )
            }

            sectionTitle("achievements.advanced.title")
            Text("achievements.advanced.description")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(viewModel.advancedAchievements) { progress in
                AchievementCardView(
                    progress: progress,
                    hasAdvancedAccess: viewModel.hasAdvancedChallengeAccess,
                    onUnlockAdvanced: { isPaywallPresented = true }
                )
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(SkateTrackSessionStartColors.teal)
            Text("achievements.loading")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func errorState(_ key: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("achievements.error.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(LocalizedStringKey(key))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Button("achievements.retry") {
                Task { await viewModel.reload() }
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.teal)
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .tracking(1.2)
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            .textCase(.uppercase)
    }

    private func statTile(value: String, labelKey: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var unlockedText: String {
        "\(viewModel.stats.unlockedCount)/\(viewModel.stats.totalVisibleAchievements)"
    }

    private var distanceText: String {
        UnitFormatter.distance(meters: viewModel.stats.totalDistanceKilometers * 1_000, maximumFractionDigits: 1)
    }

    private var weeklyDistanceText: String {
        UnitFormatter.distance(meters: viewModel.stats.weeklyDistanceKilometers * 1_000, maximumFractionDigits: 1)
    }
}
