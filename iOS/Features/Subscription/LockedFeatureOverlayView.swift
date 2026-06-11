// [協作區] LockedFeatureOverlayView.swift
// 用途：在 Session Start 中顯示鎖定功能提示並導向付費牆。
// 委派至：SessionStartView 決定何時顯示與開啟 SubscriptionPaywallView。

import SwiftUI

struct LockedFeatureOverlayView: View {
    let feature: GatedFeature
    let accentColor: Color
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("subscription.locked_feature.title")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(LocalizedStringKey(feature.localizationKey))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                }

                Spacer(minLength: 0)
            }

            Text("subscription.locked_feature.description")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onUnlock) {
                HStack(spacing: 8) {
                    Text("subscription.paywall.open_cta")
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(accentColor.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("locked-feature-open-paywall")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier("locked-feature-overlay")
    }
}

#Preview("Locked Feature") {
    LockedFeatureOverlayView(
        feature: .inlineFitnessMode,
        accentColor: SkateTrackSessionStartColors.teal,
        onUnlock: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
