// [協作區] SpotFavoriteLimitBanner.swift
// 用途：呈現免費收藏數限制與本機隱私提示，付費狀態由 useSpots 提供。
// 委派至：SpotsViewModel / SubscriptionPaywallView。

import Foundation
import SwiftUI

struct SpotFavoriteLimitBanner: View {
    let favoriteCount: Int
    let favoriteLimit: Int
    let hasUnlimitedAccess: Bool
    let onUnlock: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hasUnlimitedAccess ? "star.circle.fill" : "lock.circle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(hasUnlimitedAccess ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple)

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(hasUnlimitedAccess ? "spots.favorite.unlimited" : "spots.favorite.limit"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Text("spots.private.default")
                    .font(.caption)
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)

                if !hasUnlimitedAccess {
                    Text(String(format: "%d/%d", favoriteCount, favoriteLimit))
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(SkateTrackSessionStartColors.purple)
                        .accessibilityIdentifier("spots-favorite-limit-count")
                }
            }

            Spacer(minLength: 8)

            if !hasUnlimitedAccess {
                Button(action: onUnlock) {
                    Text("gear.locked.cta")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(SkateTrackSessionStartColors.purple.opacity(0.84))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("spots-favorite-limit-unlock")
            }
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("spots-favorite-limit-banner")
    }
}
