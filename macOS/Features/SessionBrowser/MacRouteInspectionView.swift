// [協作區] macOS/Features/SessionBrowser/MacRouteInspectionView.swift
// 用途：提供 Task-030e-007B macOS read-only expanded route inspection sheet 與 iOS route visual parity legend。
// 委派至：MacRoutePreviewView / MacRouteMapContextView；只檢視既有 route samples，不做路線修正、定位請求或資料寫入。

import SwiftUI

struct MacRouteInspectionView: View {
    let points: [MacRoutePoint]
    let summary: MacRouteSummary

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.2)
            content
        }
        .frame(minWidth: 860, minHeight: 680)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("mac.accessibility.route_inspection.label"))
        .accessibilityHint(Text("mac.accessibility.route_inspection.hint"))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Label("mac.viewer.route.inspect.title", systemImage: "map.fill")
                    .font(.title3.weight(.bold))
                Text("mac.viewer.route.inspect.subtitle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 16)
            Button("mac.viewer.route.inspect.close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(22)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                mapPanel
                MacRouteVisualLegendView(isCompact: false)
                metadataPanel
                readOnlyPanel
            }
            .padding(22)
        }
    }

    private var mapPanel: some View {
        ZStack(alignment: .topLeading) {
            MacRouteMapContextView(points: points, summary: summary)
                .frame(minHeight: 430)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(mapBorder)
            VStack(alignment: .leading, spacing: 8) {
                Label("mac.viewer.route.inspect.fit_bounds", systemImage: "arrow.down.right.and.arrow.up.left")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.58), in: Capsule())
                    .foregroundStyle(.white)
                if summary.hasStartupWarmup {
                    Label("summary.route.accuracy.startup", systemImage: "scope")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.orange.opacity(0.22), in: Capsule())
                        .foregroundStyle(Color.orange)
                }
            }
            .padding(14)
        }
    }

    private var mapBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(.white.opacity(0.14), lineWidth: 1)
    }

    private var metadataPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("mac.viewer.route.inspect.metadata.title", systemImage: "list.bullet.rectangle")
                .font(.headline)
            LazyVGrid(columns: metadataColumns, alignment: .leading, spacing: 12) {
                MacRouteInspectionMetricView(titleKey: "mac.viewer.route.inspect.metadata.samples", value: "\(summary.routePointCount)")
                MacRouteInspectionMetricView(titleKey: "mac.viewer.route.inspect.metadata.unique", value: "\(summary.uniqueRoutePointCount)")
                MacRouteInspectionMetricView(titleKey: "mac.viewer.route.inspect.metadata.distance", value: formattedDistance(summary.derivedDistanceKilometers))
                MacRouteInspectionMetricView(titleKey: "mac.viewer.route.inspect.metadata.quality", value: NSLocalizedString(qualityKey(for: summary.quality), comment: ""))
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var readOnlyPanel: some View {
        Label("mac.viewer.route.inspect.readonly", systemImage: "lock.shield")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var metadataColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 148), spacing: 12)]
    }

    private func formattedDistance(_ distance: Double) -> String {
        String(format: String(localized: "mac.package.preview.distance.format"), distance)
    }

    private func qualityKey(for quality: MacRouteVisualizationQuality) -> String {
        switch quality {
        case .unavailable:
            return "mac.viewer.route.quality.unavailable"
        case .limited:
            return "mac.viewer.route.quality.limited"
        case .usable:
            return "mac.viewer.route.quality.usable"
        }
    }
}

struct MacRouteVisualLegendView: View {
    let isCompact: Bool

    private var visibleStyles: [MacRouteVisualStyle] {
        [.trustedGreenRoute, .brightOrangeAccent, .fluorescentPinkGlow, .startMarker, .finishMarker]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !isCompact {
                Label("mac.viewer.route.legend.title", systemImage: "paintpalette")
                    .font(.headline)
            }
            legendRows
            if !isCompact {
                Text("mac.viewer.route.visual_parity.note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(isCompact ? 0 : 14)
        .background(legendBackground)
    }

    private var legendRows: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            ForEach(visibleStyles, id: \.legendKey) { style in
                MacRouteLegendChip(style: style, isCompact: isCompact)
            }
        }
    }

    @ViewBuilder
    private var legendBackground: some View {
        if isCompact {
            EmptyView()
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
        }
    }
}

private struct MacRouteLegendChip: View {
    let style: MacRouteVisualStyle
    let isCompact: Bool

    var body: some View {
        Label {
            Text(LocalizedStringKey(style.legendKey))
                .font(isCompact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .lineLimit(1)
        } icon: {
            if style.isRouteLine {
                Capsule()
                    .fill(style.swiftUIColor)
                    .frame(width: isCompact ? 16 : 20, height: isCompact ? 5 : 6)
                    .shadow(color: style.swiftUIColor.opacity(0.32), radius: 4, x: 0, y: 0)
            } else {
                Circle()
                    .fill(style.swiftUIColor)
                    .frame(width: isCompact ? 8 : 10, height: isCompact ? 8 : 10)
                    .shadow(color: style.swiftUIColor.opacity(0.32), radius: 4, x: 0, y: 0)
            }
        }
        .padding(.horizontal, isCompact ? 7 : 9)
        .padding(.vertical, isCompact ? 5 : 7)
        .background(.white.opacity(0.055), in: Capsule())
    }
}

private struct MacRouteInspectionMetricView: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospacedDigit().weight(.bold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
