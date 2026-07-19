// [協作區] SnowHUDLowConfidenceView.swift
// 用途：呈現 config-driven low confidence Snow HUD 狀態，不硬編碼 confidence 門檻。

import SwiftUI

struct SnowHUDLowConfidenceView: View {
    let model: SnowLowConfidenceHUDModel
    let accentColor: Color

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(SkateTrackSessionStartColors.amber)
                        .frame(width: 54, height: 54)
                        .background(SkateTrackSessionStartColors.amber.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(model.messageLocalizationKey))
                            .font(.system(size: 21, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("snow.hud.lowConfidence.description")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                if !model.reasonCodes.isEmpty {
                    reasonChips
                }
            }
            .padding(18)
            .background(SkateTrackSessionStartColors.card.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(SkateTrackSessionStartColors.amber.opacity(0.26), lineWidth: 1))

            HStack(spacing: 10) {
                SnowHUDMetricTile(
                    value: SnowHUDView.formatSpeed(model.currentSpeedKmh),
                    labelKey: "session.hud.currentSpeed",
                    tintColor: accentColor,
                    accessibilityID: "snow-hud-low-confidence-speed"
                )
                SnowHUDMetricTile(
                    value: confidencePercent,
                    labelKey: "snow.hud.confidence",
                    tintColor: SkateTrackSessionStartColors.amber,
                    accessibilityID: "snow-hud-low-confidence-score"
                )
                SnowHUDMetricTile(
                    value: model.currentSegmentType.rawValue,
                    labelKey: "snow.hud.segmentType",
                    tintColor: SkateTrackSessionStartColors.blueCold,
                    accessibilityID: "snow-hud-low-confidence-segment"
                )
            }
        }
        .accessibilityIdentifier("snow-hud-low-confidence")
    }

    private var confidencePercent: String {
        let clamped = min(1, max(0, model.confidence))
        return String(format: "%.0f%%", clamped * 100)
    }

    private var reasonChips: some View {
        FlowLayout(spacing: 7) {
            ForEach(model.reasonCodes.prefix(4), id: \.self) { reason in
                Text(reason)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(SkateTrackSessionStartColors.amber.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    private let content: Content

    init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
