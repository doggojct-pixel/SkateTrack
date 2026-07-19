// [Collaboration Zone] WatchSnowControlView.swift
// Purpose: Mock-backed watchOS Snow controls. Actions go through data-source boundary closures only.

import SwiftUI

struct WatchSnowControlView: View {
    let snapshot: WatchSnowSessionSnapshot
    let lastHapticIntent: WatchSnowHapticIntent?
    let markManeuver: () -> Void
    let startRun: () -> Void
    let pauseSession: () -> Void
    let resumeSession: () -> Void
    let endRun: () -> Void
    let toggleSubscriberGate: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            WatchSnowHeaderBadge(titleKey: "snow.watch.control.badge", systemImage: "switch.2", color: WatchSnowPalette.ice)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                controlButton("snow.watch.control.start", "play.fill", WatchSnowPalette.mint, action: startRun)
                controlButton("snow.watch.control.pause", "pause.fill", WatchSnowPalette.amber, action: pauseSession)
                controlButton("snow.watch.control.resume", "arrow.clockwise", WatchSnowPalette.ice, action: resumeSession)
                controlButton("snow.watch.control.mark", "figure.snowboarding", WatchSnowPalette.purple, action: markManeuver)
                controlButton("snow.watch.control.end", "stop.fill", WatchSnowPalette.red, action: endRun)
                controlButton(snapshot.isSubscriber ? "snow.watch.control.subscriber" : "snow.watch.control.free", snapshot.isSubscriber ? "sparkles" : "lock.fill", WatchSnowPalette.blue, action: toggleSubscriberGate)
            }

            if let lastHapticIntent {
                Text(LocalizedStringKey(lastHapticIntent.titleKey))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchSnowPalette.text2)
                    .multilineTextAlignment(.center)
            } else {
                Text("snow.watch.control.mockOnly")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchSnowPalette.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .watchSnowCard()
    }

    private func controlButton(
        _ titleKey: String,
        _ systemImage: String,
        _ color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .black))
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.13)))
        }
        .buttonStyle(.plain)
    }
}
