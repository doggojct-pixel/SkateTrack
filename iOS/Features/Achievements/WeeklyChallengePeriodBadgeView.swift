// [協作區] WeeklyChallengePeriodBadgeView.swift
// 用途：顯示本機每週挑戰的週期與完成狀態，避免 WeeklyChallengeCardView 膨脹。
// 委派至：WeeklyChallengeCardView 傳入 WeeklyChallengeProgress。

import SwiftUI

struct WeeklyChallengePeriodBadgeView: View {
    let challenge: WeeklyChallengeProgress

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: challenge.isComplete ? "checkmark.seal.fill" : "calendar.badge.clock")
                .font(.system(size: 10, weight: .black))
            Text(periodText)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(challenge.isComplete ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.textTertiary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background((challenge.isComplete ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.border).opacity(0.14))
        .clipShape(Capsule())
        .accessibilityIdentifier("weekly-challenge-period-badge")
    }

    private var periodText: String {
        if challenge.isComplete {
            return NSLocalizedString("challenges.period.completed", comment: "")
        }
        let format = NSLocalizedString("challenges.period.format", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, shortDate(challenge.weekStart), shortDate(challenge.weekEnd))
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }
}
