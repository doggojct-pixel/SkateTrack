// [Collaboration Zone] WatchSnowSummaryView.swift
// Purpose: Mock-backed watchOS Snow day summary.

import SwiftUI

struct WatchSnowSummaryView: View {
    let snapshot: WatchSnowSessionSnapshot

    var body: some View {
        VStack(spacing: 10) {
            WatchSnowHeaderBadge(titleKey: "snow.watch.summary.badge", systemImage: "checkmark.seal.fill", color: WatchSnowPalette.mint)

            HStack(spacing: 8) {
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.runs", value: "\(snapshot.totalRunsToday)", color: WatchSnowPalette.ice)
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.totalDrop", value: snapshot.watchTotalVerticalText, color: WatchSnowPalette.mint)
            }

            HStack(spacing: 8) {
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.skiKm", value: snapshot.watchSkiDistanceText, color: WatchSnowPalette.snow)
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.top", value: snapshot.watchMaxSpeedText, color: WatchSnowPalette.purple)
            }

            Text("snow.watch.summary.mockOnly")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text2)
                .multilineTextAlignment(.center)
        }
        .watchSnowCard()
    }
}
