// [Collaboration Zone] WatchSnowFallAlertView.swift
// Purpose: Mock-only watchOS Snow fall safety presentation. No SOS integration is wired in 006a.

import Foundation
import SwiftUI

struct WatchSnowFallAlertView: View {
    let snapshot: WatchSnowSessionSnapshot

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(WatchSnowPalette.red)
                .shadow(color: WatchSnowPalette.red.opacity(0.55), radius: 12)
            Text("snow.watch.fall.title")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(WatchSnowPalette.snow)
                .multilineTextAlignment(.center)
            Text("snow.watch.fall.message")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text2)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.impact", value: String(format: "%.1fG", snapshot.fallAlertPeakGForce ?? 0), color: WatchSnowPalette.red)
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.status", value: "SOS", color: WatchSnowPalette.amber)
            }
        }
        .watchSnowCard()
    }
}
