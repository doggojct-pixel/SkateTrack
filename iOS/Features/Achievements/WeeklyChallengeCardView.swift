// [協作區] WeeklyChallengeCardView.swift
// 用途：呈現 Task-024a 本機每週挑戰預覽，進階挑戰仍走訂閱 gating。
// 委派至：AchievementListView 管理 refresh、Paywall 與資料來源。

import SwiftUI

struct WeeklyChallengeCardView: View {
    let challenge: WeeklyChallengeProgress
    let hasAdvancedAccess: Bool
    let onUnlockAdvanced: () -> Void

    private var isLockedAdvanced: Bool {
        challenge.isAdvanced && !hasAdvancedAccess
    }

    private var accentColor: Color {
        if isLockedAdvanced { return SkateTrackSessionStartColors.purple }
        return challenge.isComplete ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.amber
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isLockedAdvanced ? "lock.fill" : challenge.definition.iconSystemName)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(accentColor)
                    .frame(width: 38, height: 38)
                    .background(accentColor.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(LocalizedStringKey(challenge.definition.titleKey))
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        if challenge.isAdvanced {
                            Text("achievements.badge.advanced")
                                .tracking(1)
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(SkateTrackSessionStartColors.purple)
                        }
                    }

                    WeeklyChallengePeriodBadgeView(challenge: challenge)

                    Text(LocalizedStringKey(isLockedAdvanced ? "challenges.advanced.locked.subtitle" : challenge.definition.subtitleKey))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if isLockedAdvanced {
                Button(action: onUnlockAdvanced) {
                    Text("challenges.advanced.unlock")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(SkateTrackSessionStartColors.purple.opacity(0.34))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: challenge.completionFraction)
                        .tint(accentColor)
                    Text(progressText)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("weekly-challenge-card-\(challenge.id)")
    }

    private var progressText: String {
        if challenge.isComplete {
            return NSLocalizedString("challenges.progress.complete", comment: "")
        }
        let format = NSLocalizedString("challenges.progress.format", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, challenge.currentValue, challenge.definition.targetValue)
    }
}
