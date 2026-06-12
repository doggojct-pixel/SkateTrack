// [協作區] AchievementCardView.swift
// 用途：呈現單一成就的進度、解鎖狀態與進階挑戰鎖定狀態。
// 委派至：AchievementListView 管理資料來源與 Paywall routing。

import SwiftUI

struct AchievementCardView: View {
    let progress: AchievementProgress
    let hasAdvancedAccess: Bool
    let onUnlockAdvanced: () -> Void

    private var isLockedAdvanced: Bool {
        progress.isAdvanced && !hasAdvancedAccess
    }

    private var accentColor: Color {
        if isLockedAdvanced { return SkateTrackSessionStartColors.purple }
        return progress.isUnlocked ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.amber
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 13) {
                icon
                bodyText
                Spacer(minLength: 0)
                AchievementProgressRingView(
                    progress: isLockedAdvanced ? 0.18 : progress.completionFraction,
                    accentColor: accentColor,
                    isComplete: progress.isUnlocked && !isLockedAdvanced
                )
            }

            if isLockedAdvanced {
                advancedLockedCTA
            } else {
                progressBar
            }
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("achievement-card-\(progress.id)")
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accentColor.opacity(0.16))
                .frame(width: 42, height: 42)
            Image(systemName: isLockedAdvanced ? "lock.fill" : progress.definition.iconSystemName)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(accentColor)
        }
    }

    private var bodyText: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(LocalizedStringKey(progress.definition.titleKey))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if progress.isAdvanced {
                    Text("achievements.badge.advanced")
                        .tracking(1)
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(SkateTrackSessionStartColors.purple.opacity(0.14))
                        .clipShape(Capsule())
                }
            }

            Text(LocalizedStringKey(isLockedAdvanced ? "achievements.advanced.locked.subtitle" : progress.definition.subtitleKey))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(progressText)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
        }
    }

    private var progressBar: some View {
        ProgressView(value: progress.completionFraction)
            .tint(accentColor)
            .accessibilityIdentifier("achievement-progress-bar")
    }

    private var advancedLockedCTA: some View {
        Button(action: onUnlockAdvanced) {
            HStack {
                Image(systemName: "lock.open.fill")
                Text("achievements.advanced.unlock")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(SkateTrackSessionStartColors.purple.opacity(0.36))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("achievement-advanced-unlock-button")
    }

    private var progressText: String {
        if isLockedAdvanced {
            return NSLocalizedString("achievements.progress.locked", comment: "")
        }
        if progress.isUnlocked {
            return NSLocalizedString("achievements.progress.unlocked", comment: "")
        }
        let format = NSLocalizedString("achievements.progress.format", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, progress.currentValue, progress.definition.targetValue)
    }

    private var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                SkateTrackSessionStartColors.card.opacity(isLockedAdvanced ? 0.72 : 0.92),
                SkateTrackSessionStartColors.navy2.opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
