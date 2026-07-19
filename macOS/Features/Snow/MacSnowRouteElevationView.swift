// [協作區] MacSnowRouteElevationView.swift
// 用途：顯示 Snow route + elevation lightweight preview，支援 selected segment time-window filtering。
// 委派至：MacSnowRootView；完整 MapKit segment zoom deferred。

import SwiftUI

struct MacSnowRouteElevationView: View {
    let analysis: MacSnowSessionAnalysis

    private var selectedSamples: [MotionSample] {
        MacSnowRouteFilter.routeSamples(for: analysis.selectedSegment, in: analysis.motionSamples)
    }

    private var routePoints: [MacSnowRoutePoint] {
        MacSnowRouteFilter.routePoints(from: selectedSamples)
    }

    private var elevationPoints: [MacSnowElevationPoint] {
        MacSnowRouteFilter.elevationPoints(from: selectedSamples)
    }

    var body: some View {
        MacSnowSection(
            titleKey: "mac.snow.route.title",
            subtitleKey: "mac.snow.route.subtitle",
            systemImage: "point.topleft.down.curvedto.point.bottomright.up"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if routePoints.count >= 2 {
                    MacSnowRoutePathView(points: routePoints, segments: analysis.segments)
                        .frame(minHeight: 220)
                        .overlay(alignment: .topLeading) {
                            if analysis.selectedSegment != nil {
                                MacSnowStatusPill(
                                    titleKey: "mac.snow.route.selected_segment",
                                    systemImage: "scope",
                                    tint: MacSnowStyle.ice
                                )
                                .padding(10)
                            }
                        }
                } else {
                    MacSnowEmptyState(
                        titleKey: "mac.snow.route.limited",
                        messageKey: "mac.snow.unavailable.no_route",
                        systemImage: "map"
                    )
                }

                MacSnowVerticalDropChartView(
                    points: elevationPoints,
                    hasLimitedAltitudeData: analysis.hasLimitedAltitudeData
                )
            }
        }
    }
}

private struct MacSnowRoutePathView: View {
    let points: [MacSnowRoutePoint]
    let segments: [SnowSegment]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MacSnowStyle.mapGradient)

                Path { path in
                    let mapped = map(points: points, in: CGRect(origin: .zero, size: proxy.size).insetBy(dx: 18, dy: 18))
                    guard let first = mapped.first else { return }
                    path.move(to: first)
                    for point in mapped.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(MacSnowStyle.ice, style: StrokeStyle(lineWidth: MacSnowStyle.routeLineWidth, lineCap: .round, lineJoin: .round))
                .shadow(color: MacSnowStyle.ice.opacity(0.55), radius: 8)

                ForEach(points.prefix(1)) { point in
                    MacSnowRouteMarker(label: "S")
                        .position(position(for: point, in: proxy.size))
                }
                ForEach(points.suffix(1)) { point in
                    MacSnowRouteMarker(label: "F")
                        .position(position(for: point, in: proxy.size))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MacSnowStyle.iceStroke, lineWidth: 1)
        )
    }

    private func position(for point: MacSnowRoutePoint, in size: CGSize) -> CGPoint {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 18, dy: 18)
        return map(points: [point], in: rect).first ?? CGPoint(x: rect.midX, y: rect.midY)
    }

    private func map(points: [MacSnowRoutePoint], in rect: CGRect) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let allPoints = self.points
        let minLat = allPoints.map { $0.coordinate.latitude }.min() ?? 0
        let maxLat = allPoints.map { $0.coordinate.latitude }.max() ?? 1
        let minLon = allPoints.map { $0.coordinate.longitude }.min() ?? 0
        let maxLon = allPoints.map { $0.coordinate.longitude }.max() ?? 1
        let latSpan = max(0.000001, maxLat - minLat)
        let lonSpan = max(0.000001, maxLon - minLon)
        return points.map { point in
            let x = rect.minX + CGFloat((point.coordinate.longitude - minLon) / lonSpan) * rect.width
            let y = rect.maxY - CGFloat((point.coordinate.latitude - minLat) / latSpan) * rect.height
            return CGPoint(x: x, y: y)
        }
    }
}

private struct MacSnowRouteMarker: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .foregroundStyle(.black)
            .frame(width: 20, height: 20)
            .background(MacSnowStyle.ice, in: Circle())
    }
}
