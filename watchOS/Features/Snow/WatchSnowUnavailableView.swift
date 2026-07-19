// [Collaboration Zone] WatchSnowUnavailableView.swift
// Purpose: Release-safe neutral fallback until real WatchBridge Snow data wiring lands in 006b.

import SwiftUI

struct WatchSnowUnavailableView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "snowflake")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(WatchSnowPalette.ice)
            Text("snow.watch.unavailable.title")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(WatchSnowPalette.snow)
            Text("snow.watch.unavailable.message")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchSnowPalette.text2)
                .multilineTextAlignment(.center)
        }
        .padding()
        .watchSnowBackground()
    }
}
