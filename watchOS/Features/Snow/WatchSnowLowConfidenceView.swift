// [Collaboration Zone] WatchSnowLowConfidenceView.swift
// Purpose: Mock-backed watchOS Snow low-confidence state.

import SwiftUI

struct WatchSnowLowConfidenceView: View {
    let snapshot: WatchSnowSessionSnapshot

    var body: some View {
        VStack(spacing: 8) {
            WatchSnowHeaderBadge(titleKey: "snow.watch.lowConfidence.badge", systemImage: "exclamationmark.triangle.fill", color: WatchSnowPalette.red)
            Text("snow.watch.lowConfidence.message")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text2)
                .multilineTextAlignment(.center)
            WatchSnowMetricChipView(titleKey: "snow.watch.metric.confidence", value: "LOW", color: WatchSnowPalette.red)
        }
        .watchSnowCard()
    }
}
