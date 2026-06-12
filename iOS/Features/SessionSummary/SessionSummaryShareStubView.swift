// [協作區] SessionSummaryShareStubView.swift
// 用途：作為 Task-023a 分享卡區塊的相容 wrapper，取代 Task-018b 的純 stub。
// 委派至：useSessionShareCard 產生資料；Task-023b 才接圖片輸出與系統分享流程。

import SwiftUI

struct SessionSummaryShareStubView: View {
    let content: SessionSummaryContent
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    let onUnlock: () -> Void

    private var shareCard: SessionShareCardViewModel {
        useSessionShareCard(content: content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if subscriptionStatus.hasAccess(to: .sessionShareCard) {
                SessionShareCardPreviewView(card: shareCard.card)
                SessionShareCardActionView(card: shareCard.card)
            } else {
                SessionShareCardLockedView(card: shareCard.card, onUnlock: onUnlock)
            }
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border.opacity(0.8), lineWidth: 1))
        .accessibilityIdentifier("session-summary-share-card-section")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.purple)
                .frame(width: 36, height: 36)
                .background(SkateTrackSessionStartColors.purple.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("summary.share.title")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(LocalizedStringKey(subscriptionStatus.hasAccess(to: .sessionShareCard) ? "subscription.subscriber" : "subscription.pro_badge"))
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(subscriptionStatus.hasAccess(to: .sessionShareCard) ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }

                Text(LocalizedStringKey(subscriptionStatus.hasAccess(to: .sessionShareCard) ? "summary.share.unlocked.subtitle" : "summary.share.locked.sectionSubtitle"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
