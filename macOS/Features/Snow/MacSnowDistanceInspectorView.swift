// [協作區] MacSnowDistanceInspectorView.swift
// 用途：分離 skiDistance / liftDistance / routeDistance，避免上山交通誤算滑行距離。
// 委派至：MacSnowRootView；不執行健康資料匯出或 package export。

import SwiftUI

struct MacSnowDistanceInspectorView: View {
    let analysis: MacSnowSessionAnalysis

    private var breakdown: SnowDistanceBreakdown { analysis.distanceBreakdown }
    private var total: Double { max(1, breakdown.routeDistanceMeters) }

    var body: some View {
        MacSnowSection(
            titleKey: "mac.snow.distance.title",
            subtitleKey: "mac.snow.distance.subtitle",
            systemImage: "ruler"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                MacSnowDistanceBar(
                    skiRatio: breakdown.skiDistanceMeters / total,
                    liftRatio: breakdown.liftDistanceMeters / total,
                    unknownRatio: breakdown.unknownDistanceMeters / total
                )
                .frame(height: 18)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], alignment: .leading, spacing: 12) {
                    MacSnowDistanceRow(
                        titleKey: "mac.snow.metric.ski_distance",
                        value: MacSnowFormatters.distanceKilometers(breakdown.skiDistanceMeters),
                        noteKey: "mac.snow.distance.ski_note",
                        color: MacSnowStyle.ice
                    )
                    MacSnowDistanceRow(
                        titleKey: "mac.snow.metric.lift_distance",
                        value: MacSnowFormatters.distanceKilometers(breakdown.liftDistanceMeters),
                        noteKey: "mac.snow.distance.lift_note",
                        color: MacSnowStyle.amber
                    )
                    MacSnowDistanceRow(
                        titleKey: "mac.snow.metric.route_distance",
                        value: MacSnowFormatters.distanceKilometers(breakdown.routeDistanceMeters),
                        noteKey: "mac.snow.distance.route_note",
                        color: MacSnowStyle.blue
                    )
                }

                if breakdown.unknownDistanceMeters > 0 {
                    Label {
                        Text(String(format: String(localized: "mac.snow.distance.unknown.format"), MacSnowFormatters.distanceMeters(breakdown.unknownDistanceMeters)))
                    } icon: {
                        Image(systemName: "questionmark.diamond")
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

private struct MacSnowDistanceBar: View {
    let skiRatio: Double
    let liftRatio: Double
    let unknownRatio: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width)
            HStack(spacing: 3) {
                Capsule()
                    .fill(MacSnowStyle.ice.opacity(0.82))
                    .frame(width: max(8, width * normalized(skiRatio)))
                Capsule()
                    .fill(MacSnowStyle.amber.opacity(0.82))
                    .frame(width: max(8, width * normalized(liftRatio)))
                if unknownRatio > 0 {
                    Capsule()
                        .fill(MacSnowStyle.red.opacity(0.72))
                        .frame(width: max(8, width * normalized(unknownRatio)))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func normalized(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

private struct MacSnowDistanceRow: View {
    let titleKey: String
    let value: String
    let noteKey: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 9, height: 9)
                Text(LocalizedStringKey(titleKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MacSnowStyle.text2)
            }
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
            Text(LocalizedStringKey(noteKey))
                .font(.caption)
                .foregroundStyle(MacSnowStyle.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(MacSnowStyle.cardGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
