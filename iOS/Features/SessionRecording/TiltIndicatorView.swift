// [協作區] TiltIndicatorView.swift
// 用途：以小型水平儀視覺化目前滑行傾角，作為 Live HUD 的輔助指標。
// 委派至：LiveHUDView 從 SessionRecordingState.currentTiltDegrees 讀取數值。

import SwiftUI

struct TiltIndicatorView: View {
    let tiltDegrees: Double
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("session.hud.tilt")
                    .tracking(1.4)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(abs(tiltDegrees), format: .number.precision(.fractionLength(0)))°")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            ZStack(alignment: .center) {
                Capsule()
                    .fill(SkateTrackSessionStartColors.navy3)
                    .frame(height: 8)

                Capsule()
                    .fill(accentColor.opacity(0.35))
                    .frame(width: 2, height: 22)

                Circle()
                    .fill(accentColor)
                    .frame(width: 18, height: 18)
                    .shadow(color: accentColor.opacity(0.55), radius: 9, x: 0, y: 0)
                    .offset(x: markerOffset)
            }
            .frame(height: 24)
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
        )
        .accessibilityIdentifier("live-hud-tilt-indicator")
    }

    private var markerOffset: CGFloat {
        let clamped = max(-30, min(30, tiltDegrees))
        return CGFloat(clamped / 30) * 56
    }
}

#Preview("Tilt") {
    TiltIndicatorView(tiltDegrees: 12, accentColor: SkateTrackSessionStartColors.accent)
        .padding()
        .background(SkateTrackSessionStartColors.navy2)
        .preferredColorScheme(.dark)
}
