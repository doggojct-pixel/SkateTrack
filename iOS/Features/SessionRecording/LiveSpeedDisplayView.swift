// [協作區] LiveSpeedDisplayView.swift
// 用途：呈現 Live HUD 中央大字速度、單位與最高速摘要。
// 委派至：LiveHUDView 依 SessionRecordingState 提供即時速度數值。

import Foundation
import SwiftUI

struct LiveSpeedDisplayView: View {
    let speedKilometersPerHour: Double
    let maxSpeedKilometersPerHour: Double
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(integerPart)
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(decimalPart)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .offset(y: -2)
            }
            .shadow(color: accentColor.opacity(0.35), radius: 18, x: 0, y: 0)
            .accessibilityIdentifier("live-hud-speed")

            Text("unit.speed.kmh")
                .tracking(3)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 5) {
                Text("session.hud.maxSpeed")
                    .tracking(1.5)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)

                Text(formattedMaxSpeedValue)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                Text("unit.speed.kmh.short")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }
        }
    }

    private var integerPart: String {
        let safeValue = max(0, speedKilometersPerHour)
        return String(Int(safeValue.rounded(.down)))
    }

    private var decimalPart: String {
        let safeValue = max(0, speedKilometersPerHour)
        let decimal = Int((safeValue * 10).rounded()) % 10
        return ".\(decimal)"
    }

    private var formattedMaxSpeedValue: String {
        String(format: "%.1f", max(0, maxSpeedKilometersPerHour))
    }
}

#Preview("Speed") {
    LiveSpeedDisplayView(
        speedKilometersPerHour: 38.4,
        maxSpeedKilometersPerHour: 42.1,
        accentColor: SkateTrackSessionStartColors.accent
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
