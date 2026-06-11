// [協作區] RestorePurchaseButton.swift
// 用途：提供付費牆中的恢復購買入口；Task-016b 僅刷新本機 entitlement，真實 AppStore.sync() 留給 Task-016c。
// 委派至：useSubscriptionStatus 執行 entitlement refresh，不直接碰 StoreKit。

import SwiftUI

struct RestorePurchaseButton: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    let accentColor: Color

    @State private var didRequestRestore = false

    var body: some View {
        VStack(spacing: 6) {
            Button {
                didRequestRestore = true
                subscriptionStatus.requestRestorePurchases()
            } label: {
                Text("subscription.restore.cta")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("subscription-restore-button")

            Text(LocalizedStringKey(didRequestRestore ? "subscription.restore.local_result" : "subscription.restore.deferred_note"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Restore Purchase") {
    RestorePurchaseButton(
        subscriptionStatus: useSubscriptionStatus(),
        accentColor: SkateTrackSessionStartColors.teal
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
