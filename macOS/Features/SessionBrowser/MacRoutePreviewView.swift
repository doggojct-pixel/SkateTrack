// [協作區] MacRoutePreviewView.swift
// 用途：在 macOS Session Viewer 中以輕量 SwiftUI Path 顯示 .skatetrack route shape preview。
// 委派至：Task-028b Route / Chart Visualization Foundation；本檔不引入 system map / chart frameworks，不做路線編輯或 road matching。

import SwiftUI

struct MacRoutePreviewView: View {
    let points: [MacRoutePoint]
    let summary: MacRouteSummary

    private var canDrawRoute: Bool {
        points.count >= 2 && summary.quality != .unavailable
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Label("mac.viewer.route.preview.title", systemImage: "map")
                    .font(.headline.bold())
                Spacer(minLength: 12)
                Text(LocalizedStringKey(summary.quality.localizationKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summary.quality.tint)
            }

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.055))
                    routeGrid(in: geometry.size)

                    if canDrawRoute {
                        routePath(in: geometry.size)
                            .stroke(.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        if let first = points.first,
                           let last = points.last {
                            routeMarker(color: .green, labelKey: "mac.viewer.route.preview.start")
                                .position(point(for: first.coordinate, in: geometry.size))
                            routeMarker(color: .orange, labelKey: "mac.viewer.route.preview.finish")
                                .position(point(for: last.coordinate, in: geometry.size))
                        }
                    } else {
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
                }
            }
            .frame(minHeight: 220)

            HStack(spacing: 10) {
                MacRoutePreviewPill(titleKey: "mac.viewer.route.points", value: "\(summary.routePointCount)")
                MacRoutePreviewPill(titleKey: "mac.viewer.route.unique_points", value: "\(summary.uniqueRoutePointCount)")
                MacRoutePreviewPill(titleKey: "mac.viewer.route.derived_distance", value: formattedDistance(summary.derivedDistanceKilometers))
            }

            Label("mac.viewer.route.preview.not_mapmatched", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mac.accessibility.route_preview.label"))
        .accessibilityValue(Text(routeAccessibilityValue))
        .accessibilityHint(Text("mac.accessibility.route_preview.hint"))
    }

    private var routeAccessibilityValue: String {
        let distance = formattedDistance(summary.derivedDistanceKilometers)
        return String(
            format: String(localized: "mac.accessibility.route_preview.value.format"),
            summary.routePointCount,
            summary.uniqueRoutePointCount,
            distance
        )
    }

    private func formattedDistance(_ distance: Double) -> String {
        String(format: String(localized: "mac.package.preview.distance.format"), distance)
    }

    private func routeMarker(color: Color, labelKey: String) -> some View {
        VStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(.white.opacity(0.82), lineWidth: 1.5))
            Text(LocalizedStringKey(labelKey))
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.black.opacity(0.42), in: Capsule())
        }
    }

    private func routePath(in size: CGSize) -> Path {
        var path = Path()
        for (index, routePoint) in points.enumerated() {
            let cgPoint = point(for: routePoint.coordinate, in: size)
            if index == 0 {
                path.move(to: cgPoint)
            } else {
                path.addLine(to: cgPoint)
            }
        }

        return path
    }

    private func point(for coordinate: GeoCoordinate, in size: CGSize) -> CGPoint {
        guard let bounds else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }

        let horizontalInset = 24.0
        let verticalInset = 24.0
        let drawableWidth = max(size.width - horizontalInset * 2, 1)
        let drawableHeight = max(size.height - verticalInset * 2, 1)
        let longitudeSpan = max(bounds.maxLongitude - bounds.minLongitude, 0.000_001)
        let latitudeSpan = max(bounds.maxLatitude - bounds.minLatitude, 0.000_001)
        let xRatio = (coordinate.longitude - bounds.minLongitude) / longitudeSpan
        let yRatio = 1 - ((coordinate.latitude - bounds.minLatitude) / latitudeSpan)
        return CGPoint(
            x: horizontalInset + min(1, max(0, xRatio)) * drawableWidth,
            y: verticalInset + min(1, max(0, yRatio)) * drawableHeight
        )
    }

    private var bounds: MacRouteBounds? {
        MacRouteBounds(points: points.map(\.coordinate))
    }

    private func routeGrid(in size: CGSize) -> some View {
        Path { path in
            let columns = 4
            let rows = 3
            for column in 1...columns {
                let x = size.width * CGFloat(column) / CGFloat(columns + 1)
                path.move(to: CGPoint(x: x, y: 18))
                path.addLine(to: CGPoint(x: x, y: size.height - 18))
            }
            for row in 1...rows {
                let y = size.height * CGFloat(row) / CGFloat(rows + 1)
                path.move(to: CGPoint(x: 18, y: y))
                path.addLine(to: CGPoint(x: size.width - 18, y: y))
            }
        }
        .stroke(.white.opacity(0.07), style: StrokeStyle(lineWidth: 1, dash: [5, 7]))
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

private struct MacRouteBounds {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    init?(points: [GeoCoordinate]) {
        guard !points.isEmpty else { return nil }
        minLatitude = points.map(\.latitude).min() ?? 0
        maxLatitude = points.map(\.latitude).max() ?? 0
        minLongitude = points.map(\.longitude).min() ?? 0
        maxLongitude = points.map(\.longitude).max() ?? 0
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
