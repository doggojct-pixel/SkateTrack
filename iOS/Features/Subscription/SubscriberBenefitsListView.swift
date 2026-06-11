// [協作區] SubscriberBenefitsListView.swift
// 用途：呈現訂閱者權益清單，供 Paywall 與未來鎖定功能說明共用。
// 委派至：SubscriptionPaywallView 決定購買 / 模擬操作；本 View 不處理 entitlement 狀態。

import SwiftUI

struct SubscriberBenefitsListView: View {
    let accentColor: Color

    private let benefits: [SubscriberBenefit] = [
        SubscriberBenefit(
            iconName: "lock.open.fill",
            titleKey: "subscription.benefit.inline_modes.title",
            descriptionKey: "subscription.benefit.inline_modes.description"
        ),
        SubscriberBenefit(
            iconName: "clock.arrow.circlepath",
            titleKey: "subscription.benefit.history.title",
            descriptionKey: "subscription.benefit.history.description"
        ),
        SubscriberBenefit(
            iconName: "chart.xyaxis.line",
            titleKey: "subscription.benefit.insights.title",
            descriptionKey: "subscription.benefit.insights.description"
        ),
        SubscriberBenefit(
            iconName: "square.and.arrow.up.fill",
            titleKey: "subscription.benefit.share.title",
            descriptionKey: "subscription.benefit.share.description"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(benefits) { benefit in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: benefit.iconName)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(accentColor)
                        .frame(width: 28, height: 28)
                        .background(accentColor.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(LocalizedStringKey(benefit.titleKey))
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text(LocalizedStringKey(benefit.descriptionKey))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .accessibilityIdentifier("subscriber-benefits-list")
    }
}

private struct SubscriberBenefit: Identifiable {
    let id = UUID()
    let iconName: String
    let titleKey: String
    let descriptionKey: String
}

#Preview("Subscriber Benefits") {
    SubscriberBenefitsListView(accentColor: SkateTrackSessionStartColors.teal)
        .padding()
        .background(SkateTrackSessionStartColors.navy)
        .preferredColorScheme(.dark)
}
