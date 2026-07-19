// [Collaboration Zone] WatchSnowLiftCardView.swift
// Purpose: Mock-backed watchOS Snow lift / gondola exclusion state.

import SwiftUI

struct WatchSnowLiftCardView: View {
    let snapshot: WatchSnowSessionSnapshot

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cablecar.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(WatchSnowPalette.blue)
                .shadow(color: WatchSnowPalette.blue.opacity(0.45), radius: 12)

            Text("snow.watch.lift.title")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(WatchSnowPalette.snow)
                .multilineTextAlignment(.center)

            Text("snow.watch.lift.notCounting")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.ice)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.lift", value: "\(snapshot.watchLiftDistanceText) km", color: WatchSnowPalette.blue)
                WatchSnowMetricChipView(titleKey: "snow.watch.metric.altitude", value: snapshot.watchSlopeAngleText, color: WatchSnowPalette.mint)
            }
        }
        .watchSnowCard()
    }
}
