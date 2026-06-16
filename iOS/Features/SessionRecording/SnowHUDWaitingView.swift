// [協作區] SnowHUDWaitingView.swift
// 用途：呈現等待、排隊、pendingEnd、停止或步行狀態。

import Foundation
import SwiftUI

struct SnowHUDWaitingView: View {
    let model: SnowWaitingHUDModel
    let accentColor: Color

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(accentColor)
                        .frame(width: 52, height: 52)
                        .background(accentColor.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(model.titleLocalizationKey))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey(model.currentSegmentType.localizationKey))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                if let pendingEndElapsedSeconds = model.pendingEndElapsedSeconds {
                    Text("\(SnowHUDView.formatDuration(pendingEndElapsedSeconds))")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.amber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(SkateTrackSessionStartColors.amber.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityIdentifier("snow-hud-pending-end-elapsed")
                }
            }
            .padding(18)
            .background(SkateTrackSessionStartColors.card.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))

            HStack(spacing: 10) {
                SnowHUDMetricTile(
                    value: optionalMeters(model.lastRunVerticalDropMeters),
                    labelKey: "snow.hud.lastRunVerticalDrop",
                    tintColor: SkateTrackSessionStartColors.mint,
                    accessibilityID: "snow-hud-last-run-vertical"
                )
                SnowHUDMetricTile(
                    value: optionalSpeed(model.lastRunTopSpeedKmh),
                    labelKey: "snow.hud.lastRunTopSpeed",
                    tintColor: SkateTrackSessionStartColors.amber,
                    accessibilityID: "snow-hud-last-run-top-speed"
                )
                SnowHUDMetricTile(
                    value: optionalDuration(model.lastRunDurationSeconds),
                    labelKey: "snow.hud.lastRunDuration",
                    tintColor: SkateTrackSessionStartColors.blueCold,
                    accessibilityID: "snow-hud-last-run-duration"
                )
            }
        }
        .accessibilityIdentifier("snow-hud-waiting")
    }

    private func optionalMeters(_ value: Double?) -> String {
        guard let value else { return "--" }
        return SnowHUDView.formatMeters(value)
    }

    private func optionalSpeed(_ value: Double?) -> String {
        guard let value else { return "--" }
        return SnowHUDView.formatSpeed(value)
    }

    private func optionalDuration(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return SnowHUDView.formatDuration(value)
    }
}
