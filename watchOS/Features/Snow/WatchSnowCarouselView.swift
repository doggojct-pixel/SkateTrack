// [Collaboration Zone] WatchSnowCarouselView.swift
// Purpose: Mock-backed watchOS Snow run / vertical carousel card.

import SwiftUI

struct WatchSnowCarouselView: View {
    let snapshot: WatchSnowSessionSnapshot

    var body: some View {
        VStack(spacing: 10) {
            WatchSnowHeaderBadge(
                titleKey: snapshot.isSubscriber ? "snow.watch.carousel.subscriber" : "snow.watch.carousel.free",
                systemImage: snapshot.isSubscriber ? "sparkles" : "lock.fill",
                color: snapshot.isSubscriber ? WatchSnowPalette.purple : WatchSnowPalette.amber
            )

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snapshot.watchRunNumberText)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(WatchSnowPalette.ice)
                Text("snow.watch.carousel.runSuffix")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(WatchSnowPalette.text2)
            }

            WatchSnowMetricChipView(titleKey: "snow.watch.metric.thisRunDrop", value: snapshot.watchCurrentVerticalText, color: WatchSnowPalette.mint)
            WatchSnowMetricChipView(titleKey: "snow.watch.metric.maxSpeed", value: "\(snapshot.watchMaxSpeedText) km/h", color: WatchSnowPalette.snow)
        }
        .watchSnowCard()
    }
}
