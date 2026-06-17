// [Collaboration Zone] WatchSnowLiveView.swift
// Purpose: Mock-backed watchOS Snow downhill speed HUD.

import SwiftUI

struct WatchSnowLiveView: View {
    let snapshot: WatchSnowSessionSnapshot

    var body: some View {
        VStack(spacing: 10) {
            WatchSnowHeaderBadge(
                titleKey: "snow.watch.live.badge",
                systemImage: "speedometer",
                color: WatchSnowPalette.ice
            )

            VStack(spacing: 0) {
                Text(snapshot.watchSpeedText)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(WatchSnowPalette.snow)
                    .minimumScaleFactor(0.65)
                Text("km/h")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchSnowPalette.ice)
            }

            HStack(spacing: 8) {
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.run", value: snapshot.watchRunNumberText, color: WatchSnowPalette.ice)
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.drop", value: snapshot.watchCurrentVerticalText, color: WatchSnowPalette.mint)
            }

            Text("snow.watch.live.counting")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text2)
                .multilineTextAlignment(.center)
        }
        .watchSnowCard()
    }
}
