// [協作區] SnowDistanceInspectorView.swift
// 用途：顯示 SnowDistanceBreakdown 三欄語意，避免 lift / gondola 被誤算為 ski distance。
// 委派至：SnowSessionState.distanceBreakdown；不重新分類、不修改 repository。

import SwiftUI

struct SnowDistanceInspectorView: View {
    let snapshot: SnowSummaryInspectorSnapshot

    private var breakdown: SnowDistanceBreakdown { snapshot.breakdown }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            selectionContext

            HStack(spacing: 10) {
                SnowDistanceInspectorColumn(
                    value: SnowSummaryFormatters.distance(breakdown.skiDistanceMeters),
                    labelKey: "snow.inspector.skiDistance",
                    subtitleKey: "snow.inspector.countedLabel",
                    tintColor: SkateTrackSessionStartColors.ice,
                    accessibilityID: "snow-inspector-ski-distance"
                )
                SnowDistanceInspectorColumn(
                    value: SnowSummaryFormatters.distance(breakdown.liftDistanceMeters),
                    labelKey: "snow.inspector.liftDistance",
                    subtitleKey: "snow.inspector.excludedLabel",
                    tintColor: SkateTrackSessionStartColors.amber,
                    accessibilityID: "snow-inspector-lift-distance"
                )
                SnowDistanceInspectorColumn(
                    value: SnowSummaryFormatters.distance(breakdown.routeDistanceMeters),
                    labelKey: "snow.inspector.routeDistance",
                    subtitleKey: "snow.inspector.totalLabel",
                    tintColor: SkateTrackSessionStartColors.teal,
                    accessibilityID: "snow-inspector-route-distance"
                )
            }

            if breakdown.unknownDistanceMeters > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(SkateTrackSessionStartColors.purple)
                    Text(unknownDistanceText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(SkateTrackSessionStartColors.purple.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("snow-inspector-unknown-distance")
            }
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.80))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.ice.opacity(0.18), lineWidth: 1))
        .accessibilityIdentifier("snow-distance-inspector-view")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("snow.inspector.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("snow.inspector.subtitle")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var selectionContext: some View {
        Group {
            switch snapshot.context {
            case .session:
                Text("snow.inspector.selection.session")
            case let .run(runNumber):
                Text(
                    String(
                        format: NSLocalizedString("snow.inspector.selection.run.format", comment: ""),
                        runNumber
                    )
                )
            case let .segment(type):
                Text(
                    String(
                        format: NSLocalizedString("snow.inspector.selection.segment.format", comment: ""),
                        NSLocalizedString(type.localizationKey, comment: "")
                    )
                )
            }
        }
        .font(.system(size: 11, weight: .black, design: .monospaced))
        .foregroundStyle(SkateTrackSessionStartColors.ice)
        .textCase(.uppercase)
        .accessibilityIdentifier("snow-inspector-selection-context")
    }

    private var unknownDistanceText: LocalizedStringKey {
        LocalizedStringKey(
            String(
                format: NSLocalizedString("snow.inspector.unknownDistance.format", comment: ""),
                SnowSummaryFormatters.distance(breakdown.unknownDistanceMeters)
            )
        )
    }
}

private struct SnowDistanceInspectorColumn: View {
    let value: String
    let labelKey: String
    let subtitleKey: String
    let tintColor: Color
    let accessibilityID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(tintColor)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .textCase(.uppercase)
                .lineLimit(2)
                .minimumScaleFactor(0.74)

            Text(LocalizedStringKey(subtitleKey))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(12)
        .background(SkateTrackSessionStartColors.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(tintColor.opacity(0.20), lineWidth: 1))
        .accessibilityIdentifier(accessibilityID)
    }
}

#Preview("Snow Distance Inspector") {
    SnowDistanceInspectorView(
        snapshot: SnowSummaryInspectorSnapshot(
            selection: nil,
            context: .session,
            breakdown: SnowDistanceBreakdown(
                skiDistanceMeters: 2_420,
                liftDistanceMeters: 1_960,
                routeDistanceMeters: 4_620,
                unknownDistanceMeters: 240
            )
        )
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
