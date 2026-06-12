// [協作區] SessionStartAchievementDashboardCardView.swift
// 用途：在 Ride page 顯示輕量成就 / 每週挑戰 dashboard，不直接讀取 repository。
// 委派至：useAchievementDashboard 提供本機進度，RootNavigationView 處理頁面切換。

import SwiftUI

struct SessionStartAchievementDashboardCardView: View {
    @ObservedObject var dashboard: AchievementDashboardViewModel
    let onOpenAchievements: () -> Void

    var body: some View {
        Button(action: onOpenAchievements) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: dashboard.snapshot.isWeeklyChallengeComplete ? "trophy.fill" : "trophy")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(SkateTrackSessionStartColors.amber)
                        .frame(width: 34, height: 34)
                        .background(SkateTrackSessionStartColors.amber.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("achievements.dashboard.title")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey(dashboard.snapshot.weeklyChallengeTitleKey))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Text(unlockedText)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.teal)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(SkateTrackSessionStartColors.teal.opacity(0.14))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: dashboard.snapshot.weeklyChallengeCompletionFraction)
                        .tint(dashboard.snapshot.isWeeklyChallengeComplete ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.amber)
                    if dashboard.snapshot.isWeeklyChallengeComplete {
                        Text("achievements.dashboard.weeklyComplete")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(SkateTrackSessionStartColors.teal)
                    } else {
                        Text(verbatim: dashboard.snapshot.weeklyChallengeProgressText)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(SkateTrackSessionStartColors.amber)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SkateTrackSessionStartColors.card.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("session-start-achievement-dashboard-card")
        .task { await dashboard.loadIfNeeded() }
    }

    private var unlockedText: String {
        "\(dashboard.snapshot.unlockedCount)/\(dashboard.snapshot.totalVisibleAchievements)"
    }
}
