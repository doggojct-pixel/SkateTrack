// [協作區] SessionShareCardLockedView.swift
// 用途：呈現免費用戶的分享卡鎖定預覽，並導向既有 Paywall。
// 委派至：LockedFeatureOverlayView / SubscriptionPaywallView，不直接處理 entitlement 或 StoreKit。

import SwiftUI

struct SessionShareCardLockedView: View {
    let card: SessionShareCardData
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                SessionShareCardPreviewView(card: card)
                    .blur(radius: 3.5)
                    .opacity(0.72)
                    .allowsHitTesting(false)

                VStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(SkateTrackSessionStartColors.purple)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.32))
                        .clipShape(Circle())

                    Text("summary.share.locked.title")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("summary.share.locked.subtitle")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .background(.black.opacity(0.46))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(14)
            }

            LockedFeatureOverlayView(
                feature: .sessionShareCard,
                accentColor: SkateTrackSessionStartColors.purple,
                onUnlock: onUnlock
            )
        }
        .accessibilityIdentifier("session-share-card-locked-view")
    }
}
