// [協作區] LiveHUDMetricCardView.swift
// 用途：提供 Live HUD 共用指標卡，顯示距離、時間、傾角、心率與模式專屬資訊。
// 委派至：LiveHUDView 與 InlineLiveMetricsView 組合騎乘中的即時資訊版面。

import SwiftUI

struct LiveHUDMetricCardView: View {
    let value: String
    let labelKey: String
    let tintColor: Color
    let accessibilityID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(tintColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(LocalizedStringKey(labelKey))
                .tracking(1.2)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(SkateTrackSessionStartColors.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
        )
        .accessibilityIdentifier(accessibilityID)
    }
}

#Preview("Metric Card") {
    LiveHUDMetricCardView(
        value: "38.4",
        labelKey: "session.hud.maxSpeed",
        tintColor: SkateTrackSessionStartColors.accent,
        accessibilityID: "preview-metric"
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
