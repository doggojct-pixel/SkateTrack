// [協作區] AdvancedChartsLockedView.swift
// 用途：呈現 Task-018c 免費用戶的進階圖表鎖定預覽，並導向 Task-016b Paywall。
// 委派至：LockedFeatureOverlayView 與 SubscriptionPaywallView，不直接寫入 DEBUG 訂閱狀態。

import SwiftUI

struct AdvancedChartsLockedView: View {
    let speedPoints: [SessionSummaryChartPoint]
    let elevationPoints: [SessionSummaryChartPoint]
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            previewRows

            LockedFeatureOverlayView(
                feature: .advancedCharts,
                accentColor: SkateTrackSessionStartColors.purple,
                onUnlock: onUnlock
            )
        }
        .accessibilityIdentifier("advanced-charts-locked-view")
    }

    private var previewRows: some View {
        VStack(spacing: 8) {
            lockedPreviewRow(
                titleKey: "summary.advancedCharts.speed.title",
                subtitleKey: speedPoints.count >= 2 ? "summary.advancedCharts.locked.preview.speed" : "summary.advancedCharts.speed.empty",
                systemImage: "speedometer",
                accentColor: SkateTrackSessionStartColors.teal
            )

            lockedPreviewRow(
                titleKey: "summary.advancedCharts.elevation.title",
                subtitleKey: elevationPoints.count >= 2 ? "summary.advancedCharts.locked.preview.elevation" : "summary.advancedCharts.elevation.empty",
                systemImage: "mountain.2.fill",
                accentColor: SkateTrackSessionStartColors.amber
            )
        }
    }

    private func lockedPreviewRow(
        titleKey: String,
        subtitleKey: String,
        systemImage: String,
        accentColor: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(LocalizedStringKey(subtitleKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.purple)
        }
        .padding(13)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
