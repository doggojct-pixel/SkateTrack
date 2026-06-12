// [協作區] SessionStartHeaderMetricsView.swift
// 用途：拆出 Session Start 頁首與預覽指標，讓主畫面保持在人機協作可讀範圍內。
// 委派至：SessionStartView 組合此檔案；不直接啟動 Session 或讀取 repository。

import SwiftUI

struct SessionStartHeaderView: View {
    let selectedCategory: SessionStartSportCategory
    let statusLocalizationKey: String
    let rootNavigationAccessory: AnyView?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("app.name")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("session-start-app-name")

            if let rootNavigationAccessory {
                rootNavigationAccessory
                    .padding(.top, 2)
                    .padding(.bottom, 2)
                    .background(navigationPositionReader)
                    .accessibilityIdentifier("session-start-root-navigation-accessory")
            }

            Text("home.greeting.morning")
                .tracking(2)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            Text("home.readyToSkate")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(statusLocalizationKey))
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory.accentColor.opacity(0.16))
                .foregroundStyle(selectedCategory.accentColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selectedCategory.accentColor.opacity(0.28), lineWidth: 1))
                .accessibilityIdentifier("session-status-pill")
        }
        .accessibilityIdentifier("session-start-header")
    }

    private var navigationPositionReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: SessionStartNavigationPositionPreferenceKey.self,
                value: proxy.frame(in: .named(SessionStartScrollMetrics.coordinateSpaceName)).minY
            )
        }
        .accessibilityHidden(true)
    }
}

struct SessionStartPreviewMetricStripView: View {
    var body: some View {
        HStack(spacing: 8) {
            quickStat(value: "0.0", label: "KM")
            quickStat(value: "—", label: "MAX")
            quickStat(value: "10Hz", label: "SENSOR")
        }
        .accessibilityIdentifier("session-start-preview-metrics")
    }

    private func quickStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)

            Text(label)
                .tracking(1)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(SkateTrackSessionStartColors.card.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
        )
    }
}
