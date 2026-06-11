// [協作區] SessionSummaryPlaceholderSectionView.swift
// 用途：呈現 Task-018a/018b 中尚未開啟的 chart / health placeholder 區塊。
// 委派至：後續 Task-018c+ 實作 Swift Charts、HealthKit 與付費進階圖表 gating。

import SwiftUI

struct SessionSummaryPlaceholderSectionView: View {
    let titleKey: String
    let subtitleKey: String
    let systemImage: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(LocalizedStringKey(subtitleKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .background(SkateTrackSessionStartColors.card.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border.opacity(0.8), lineWidth: 1))
        .accessibilityIdentifier("session-summary-placeholder-section")
    }
}
