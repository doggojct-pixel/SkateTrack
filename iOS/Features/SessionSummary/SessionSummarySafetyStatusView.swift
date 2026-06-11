// [協作區] SessionSummarySafetyStatusView.swift
// 用途：呈現 Task-018b Session Summary 的跌倒與安全狀態回顧。
// 委派至：SessionSummaryView 提供本機 SessionData；不觸碰 FallDetectionEngine 演算法。

import SwiftUI

struct SessionSummarySafetyStatusView: View {
    let content: SessionSummaryContent

    private var fallEvents: [FallEvent] { content.session.fallEvents }
    private var hasFalls: Bool { !fallEvents.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 10) {
                safetyMetric(
                    value: "\(fallEvents.count)",
                    labelKey: "summary.safety.metric.falls",
                    accentColor: hasFalls ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal
                )

                safetyMetric(
                    value: peakImpactText,
                    labelKey: "summary.safety.metric.impact",
                    accentColor: hasFalls ? SkateTrackSessionStartColors.amber : .white
                )

                safetyMetric(
                    value: "\(confirmedFallCount)",
                    labelKey: "summary.safety.metric.confirmed",
                    accentColor: .white
                )
            }
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border.opacity(0.82), lineWidth: 1))
        .accessibilityIdentifier("session-summary-safety-status")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hasFalls ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(hasFalls ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal)
                .frame(width: 38, height: 38)
                .background((hasFalls ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal).opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(hasFalls ? "summary.safety.falls.title" : "summary.safety.clear.title"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(safetySubtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private func safetyMetric(value: String, labelKey: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .tracking(0.7)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var safetySubtitle: String {
        if hasFalls {
            let format = NSLocalizedString("summary.safety.falls.subtitleFormat", comment: "")
            return String(format: format, locale: .autoupdatingCurrent, fallEvents.count)
        }

        return NSLocalizedString("summary.safety.clear.subtitle", comment: "")
    }

    private var peakImpactText: String {
        guard let peak = fallEvents.map(\.peakImpactGForce).max(), peak.isFinite else {
            return NSLocalizedString("general.value.unavailable", comment: "")
        }

        let format = NSLocalizedString("summary.safety.impactFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, peak)
    }

    private var confirmedFallCount: Int {
        fallEvents.filter(\.userConfirmed).count
    }
}
