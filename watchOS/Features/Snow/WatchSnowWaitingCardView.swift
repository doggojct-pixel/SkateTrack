// [Collaboration Zone] WatchSnowWaitingCardView.swift
// Purpose: Mock-backed watchOS Snow waiting / queue state.

import SwiftUI

struct WatchSnowWaitingCardView: View {
    let snapshot: WatchSnowSessionSnapshot

    var body: some View {
        VStack(spacing: 10) {
            WatchSnowHeaderBadge(titleKey: "snow.watch.waiting.badge", systemImage: "pause.circle.fill", color: WatchSnowPalette.amber)

            Text("snow.watch.waiting.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(WatchSnowPalette.snow)

            Text("snow.watch.waiting.message")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text2)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.lastRun", value: snapshot.watchLastRunVerticalText, color: WatchSnowPalette.mint)
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.lastTop", value: snapshot.watchLastRunTopSpeedText, color: WatchSnowPalette.ice)
            }
        }
        .watchSnowCard()
    }
}
