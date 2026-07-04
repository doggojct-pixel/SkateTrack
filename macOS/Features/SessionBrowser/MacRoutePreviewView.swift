// [協作區] MacRoutePreviewView.swift
// 用途：在 macOS Session Viewer 中以 read-only MapKit context 顯示 .skatetrack route shape preview。
// 委派至：MacRouteMapContextView；本檔不做路線編輯、road matching、snap-to-road、route reconstruction 或 trusted metrics mutation。

import SwiftUI

struct MacRoutePreviewView: View {
    let points: [MacRoutePoint]
    let summary: MacRouteSummary

    @State private var isRouteInspectorPresented = false

    private var canDrawRoute: Bool {
        points.count >= 2 && summary.quality != .unavailable
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleBar
            routeCanvas
            routePills
            MacRouteVisualLegendView(isCompact: true)
            readOnlyNotice
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
        .sheet(isPresented: $isRouteInspectorPresented) {
            MacRouteInspectionView(points: points, summary: summary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mac.accessibility.route_preview.label"))
        .accessibilityValue(Text(routeAccessibilityValue))
        .accessibilityHint(Text("mac.accessibility.route_preview.hint"))
    }

    private var titleBar: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Label("mac.viewer.route.preview.title", systemImage: "map")
                .font(.headline.bold())
            Spacer(minLength: 12)
            if canDrawRoute {
                Button {
                    isRouteInspectorPresented = true
                } label: {
                    Label("mac.viewer.route.inspect.open", systemImage: "arrow.up.left.and.arrow.down.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Text(LocalizedStringKey(summary.quality.localizationKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(summary.quality.tint)
        }
    }

    private var routeCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.055))

            if canDrawRoute {
                MacRouteMapContextView(points: points, summary: summary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(readOnlyMapBadge, alignment: .topLeading)
                    .overlay(expandedInspectionButton, alignment: .bottomTrailing)
                    .overlay(mapBoundaryOverlay)
            } else {
                emptyRouteState
            }
        }
        .frame(minHeight: 220)
    }

    private var readOnlyMapBadge: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("mac.viewer.route.preview.readonly_mapkit", systemImage: "lock")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.black.opacity(0.52), in: Capsule())
                .foregroundStyle(.white)

            if summary.hasStartupWarmup {
                Label("summary.route.accuracy.startup", systemImage: "scope")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.22), in: Capsule())
                    .foregroundStyle(Color.orange)
            }
        }
        .padding(12)
    }

    private var expandedInspectionButton: some View {
        Button {
            isRouteInspectorPresented = true
        } label: {
            Label("mac.viewer.route.inspect.open", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(.caption.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .padding(12)
    }

    private var mapBoundaryOverlay: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(.white.opacity(0.12), lineWidth: 1)
    }

    private var emptyRouteState: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.system(size: 26, weight: .semibold))
            Text("mac.viewer.route.preview.empty")
                .font(.callout.weight(.semibold))
            Text("mac.viewer.route.preview.empty.subtitle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var routePills: some View {
        HStack(spacing: 10) {
            MacRoutePreviewPill(titleKey: "mac.viewer.route.points", value: "\(summary.routePointCount)")
            MacRoutePreviewPill(titleKey: "mac.viewer.route.unique_points", value: "\(summary.uniqueRoutePointCount)")
            MacRoutePreviewPill(titleKey: "mac.viewer.route.derived_distance", value: formattedDistance(summary.derivedDistanceKilometers))
        }
    }

    private var readOnlyNotice: some View {
        Label("mac.viewer.route.preview.not_mapmatched", systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var routeAccessibilityValue: String {
        let distance = formattedDistance(summary.derivedDistanceKilometers)
        return String(format: String(localized: "mac.accessibility.route_preview.value.format"), summary.routePointCount, summary.uniqueRoutePointCount, distance)
    }

    private func formattedDistance(_ distance: Double) -> String {
        String(format: String(localized: "mac.package.preview.distance.format"), distance)
    }
}

private struct MacRoutePreviewPill: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private extension MacRouteVisualizationQuality {
    var localizationKey: String {
        switch self {
        case .unavailable:
            return "mac.viewer.route.quality.unavailable"
        case .limited:
            return "mac.viewer.route.quality.limited"
        case .usable:
            return "mac.viewer.route.quality.usable"
        }
    }

    var tint: Color {
        switch self {
        case .unavailable:
            return .secondary
        case .limited:
            return .yellow
        case .usable:
            return .green
        }
    }
}
