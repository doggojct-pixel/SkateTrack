// [協作區] TiltIndicatorView.swift
// 用途：以小型姿態狀態卡呈現目前手機姿態資料；Phase 1a 不將手機絕對角度視為滑板傾角。
// 委派至：LiveHUDView 從 SessionRecordingState.currentTiltDegrees 讀取原始參考值，但本 View 僅做保守顯示。

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
                Text("session.hud.tiltPending")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .accessibilityLabel(Text("session.hud.tiltPending"))
            }

            ZStack(alignment: .center) {
                Capsule()
                    .fill(SkateTrackSessionStartColors.navy3)
                    .frame(height: 8)

                Capsule()
                    .fill(accentColor.opacity(0.35))
                    .frame(width: 2, height: 22)

                Circle()
                    .fill(accentColor.opacity(0.92))
                    .frame(width: 18, height: 18)
                    .shadow(color: accentColor.opacity(0.42), radius: 9, x: 0, y: 0)
            }
            .frame(height: 24)

            Text("session.hud.tiltUncalibrated")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .lineLimit(1)
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
}

#Preview("Tilt") {
    TiltIndicatorView(tiltDegrees: 12, accentColor: SkateTrackSessionStartColors.accent)
        .padding()
        .background(SkateTrackSessionStartColors.navy2)
        .preferredColorScheme(.dark)
}
