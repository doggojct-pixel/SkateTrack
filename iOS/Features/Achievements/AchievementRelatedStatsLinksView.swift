// [協作區] AchievementRelatedStatsLinksView.swift
// 用途：在成就頁提供 History / Gear / Spots 統計入口，由 RootNavigationView 處理實際切換。
// 委派至：AchievementListView 傳入導覽閉包，不直接持有 root navigation state。

import SwiftUI

struct AchievementRelatedStatsLinksView: View {
    let onOpenHistory: () -> Void
    let onOpenEquipment: () -> Void
    let onOpenSpots: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("achievements.related.title")
                .tracking(1.1)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                linkButton(
                    titleKey: "achievements.related.history",
                    systemName: "clock.arrow.circlepath",
                    accentColor: SkateTrackSessionStartColors.teal,
                    action: onOpenHistory
                )
                linkButton(
                    titleKey: "achievements.related.gear",
                    systemName: "wrench.and.screwdriver.fill",
                    accentColor: SkateTrackSessionStartColors.amber,
                    action: onOpenEquipment
                )
                linkButton(
                    titleKey: "achievements.related.spots",
                    systemName: "mappin.and.ellipse",
                    accentColor: SkateTrackSessionStartColors.purple,
                    action: onOpenSpots
                )
            }
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("achievement-related-stats-links")
    }

    private func linkButton(
        titleKey: String,
        systemName: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(accentColor)
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(accentColor.opacity(0.13))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
