// [協作區] SnowHUDDownhillView.swift
// 用途：呈現 Snow Live HUD 的 downhill / counted skiing 狀態。

import SwiftUI

struct SnowHUDDownhillView: View {
    let model: SnowDownhillHUDModel
    let accentColor: Color

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(SnowHUDView.formatSpeed(model.currentSpeedKmh))
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.56)
                    .lineLimit(1)
                    .shadow(color: accentColor.opacity(0.45), radius: 18, x: 0, y: 8)
                Text("session.hud.speedUnit")
                    .tracking(2)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(SkateTrackSessionStartColors.card.opacity(0.82))
                    RadialGradient(
                        colors: [accentColor.opacity(0.24), .clear],
                        center: .topTrailing,
                        startRadius: 12,
                        endRadius: 260
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(accentColor.opacity(0.22), lineWidth: 1))
            .accessibilityIdentifier("snow-hud-downhill-speed")

            HStack(spacing: 10) {
                SnowHUDMetricTile(
                    value: "#\(max(1, model.runNumber))",
                    labelKey: "snow.hud.runNumber",
                    tintColor: accentColor,
                    accessibilityID: "snow-hud-run-number"
                )
                SnowHUDMetricTile(
                    value: SnowHUDView.formatMeters(model.verticalDropMeters),
                    labelKey: "snow.hud.verticalDropMeters",
                    tintColor: SkateTrackSessionStartColors.mint,
                    accessibilityID: "snow-hud-vertical-drop"
                )
            }

            HStack(spacing: 10) {
                SnowHUDMetricTile(
                    value: SnowHUDView.formatMeters(model.skiDistanceMeters),
                    labelKey: "snow.hud.skiDistanceMeters",
                    tintColor: SkateTrackSessionStartColors.teal,
                    accessibilityID: "snow-hud-ski-distance"
                )
                SnowHUDMetricTile(
                    value: SnowHUDView.formatSpeed(model.maxSpeedThisRunKmh),
                    labelKey: "snow.hud.maxSpeedThisRun",
                    tintColor: SkateTrackSessionStartColors.amber,
                    accessibilityID: "snow-hud-max-speed-this-run"
                )
                SnowHUDMetricTile(
                    value: SnowHUDView.formatDuration(model.elapsedTime),
                    labelKey: "session.hud.time",
                    tintColor: SkateTrackSessionStartColors.blueCold,
                    accessibilityID: "snow-hud-elapsed-time"
                )
            }
        }
        .accessibilityIdentifier("snow-hud-downhill")
    }
}
