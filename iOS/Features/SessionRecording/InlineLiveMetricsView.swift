// [協作區] InlineLiveMetricsView.swift
// 用途：顯示直排輪 Live HUD 專屬 cadence / rhythm 指標，無資料時 graceful placeholder。
// 委派至：LiveHUDView 在 SportMode.inline 時呈現。

import SwiftUI

struct InlineLiveMetricsView: View {
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            LiveHUDMetricCardView(
                value: "--",
                labelKey: "session.hud.inline.cadence",
                tintColor: accentColor,
                accessibilityID: "live-hud-inline-cadence"
            )

            LiveHUDMetricCardView(
                value: "--",
                labelKey: "session.hud.inline.rhythm",
                tintColor: SkateTrackSessionStartColors.green,
                accessibilityID: "live-hud-inline-rhythm"
            )
        }
        .overlay(alignment: .bottomLeading) {
            Text("session.hud.inline.placeholder")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .padding(.leading, 12)
                .padding(.bottom, -16)
        }
        .accessibilityIdentifier("live-hud-inline-metrics")
    }
}

#Preview("Inline Metrics") {
    InlineLiveMetricsView(accentColor: SkateTrackSessionStartColors.purple)
        .padding()
        .background(SkateTrackSessionStartColors.navy2)
        .preferredColorScheme(.dark)
}
