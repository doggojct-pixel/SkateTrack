// [協作區] HistoryLimitPaywallBanner.swift
// 用途：顯示免費版最近 5 筆歷史限制，並導向 Task-016b Paywall。
// 委派至：SessionHistoryView 控制 Paywall sheet，useSubscriptionStatus 維持付費權限邊界。

import SwiftUI

struct HistoryLimitPaywallBanner: View {
    let lockedCount: Int
    let onUnlock: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(SkateTrackSessionStartColors.purple.opacity(0.22))
                    .frame(width: 42, height: 42)
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("history.limit.title")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(String(format: NSLocalizedString("history.limit.subtitleFormat", comment: ""), lockedCount))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(action: onUnlock) {
                Text("history.limit.cta")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(SkateTrackSessionStartColors.purple.opacity(0.86))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.purple.opacity(0.24), lineWidth: 1))
        .accessibilityIdentifier("history-limit-paywall-banner")
    }
}
