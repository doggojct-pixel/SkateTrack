// [協作區] MacSnowVerticalDropChartView.swift
// 用途：用 lightweight SwiftUI Path 顯示高度剖面；高度不足時提示 limited data。
// 委派至：MacSnowRouteElevationView；不使用大型地圖、圖表或天氣服務框架。

import SwiftUI

struct MacSnowVerticalDropChartView: View {
    let points: [MacSnowElevationPoint]
    let hasLimitedAltitudeData: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("mac.snow.elevation.title", systemImage: "mountain.2")
                    .font(.caption.weight(.semibold))
                Spacer()
                if hasLimitedAltitudeData {
                    MacSnowStatusPill(
                        titleKey: "mac.snow.elevation.limited",
                        systemImage: "exclamationmark.triangle",
                        tint: MacSnowStyle.amber
                    )
                }
            }

            if points.count >= 2 {
                GeometryReader { proxy in
                    Path { path in
                        let rect = CGRect(origin: .zero, size: proxy.size)
                        let mapped = map(points: points, in: rect)
                        guard let first = mapped.first else { return }
                        path.move(to: first)
                        for point in mapped.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(MacSnowStyle.ice, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: MacSnowStyle.ice.opacity(0.45), radius: 6)
                    .background(MacSnowStyle.mapGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(minHeight: 120)
            } else {
                MacSnowEmptyState(
                    titleKey: "mac.snow.elevation.limited",
                    messageKey: "mac.snow.elevation.limited.message",
                    systemImage: "mountain.2"
                )
            }
        }
    }

    private func map(points: [MacSnowElevationPoint], in rect: CGRect) -> [CGPoint] {
        let sorted = points.sorted { $0.timestamp < $1.timestamp }
        guard let firstDate = sorted.first?.timestamp,
              let lastDate = sorted.last?.timestamp else { return [] }
        let minAltitude = sorted.map(\.altitudeMeters).min() ?? 0
        let maxAltitude = sorted.map(\.altitudeMeters).max() ?? 1
        let timeSpan = max(1, lastDate.timeIntervalSince(firstDate))
        let altitudeSpan = max(1, maxAltitude - minAltitude)
        return sorted.map { point in
            let x = rect.minX + CGFloat(point.timestamp.timeIntervalSince(firstDate) / timeSpan) * rect.width
            let yRatio = (point.altitudeMeters - minAltitude) / altitudeSpan
            let y = rect.maxY - CGFloat(yRatio) * rect.height
            return CGPoint(x: x, y: y)
        }
    }
}
