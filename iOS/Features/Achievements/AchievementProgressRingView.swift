// [協作區] AchievementProgressRingView.swift
// 用途：呈現成就與每週挑戰的圓形進度視覺元件。
// 委派至：AchievementCardView、WeeklyChallengeCardView。

import SwiftUI

struct AchievementProgressRingView: View {
    let progress: Double
    let accentColor: Color
    let isComplete: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 5)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: isComplete ? "checkmark" : "lock.open.fill")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(isComplete ? accentColor : SkateTrackSessionStartColors.textTertiary)
        }
        .frame(width: 34, height: 34)
        .accessibilityIdentifier("achievement-progress-ring")
    }
}
