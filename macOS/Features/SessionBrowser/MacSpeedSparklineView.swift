// [協作區] MacSpeedSparklineView.swift
// 用途：在 macOS Session Viewer 中以輕量 SwiftUI Path 顯示速度趨勢預覽。
// 委派至：Task-028b Route / Chart Visualization Foundation；本檔不引入 system chart / map frameworks 或外部服務。

import SwiftUI

struct MacSpeedSparklineView: View {
    let result: SpeedDisplayResult

    private var points: [MacSpeedSparklinePoint] {
        sparklinePoints(from: result)
    }

    private var segments: [MacSpeedSparklineSegment] {
        Dictionary(grouping: points, by: \.segmentID)
            .map { MacSpeedSparklineSegment(id: $0.key, points: $0.value.sorted { $0.elapsedSeconds < $1.elapsedSeconds }) }
            .filter { $0.points.count >= 2 }
            .sorted { $0.id < $1.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("mac.viewer.chart.speed.title", systemImage: "waveform.path.ecg")
                    .font(.headline.bold())
                Spacer()
                Text(maxSpeedLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.055))
                    gridLines(in: geometry.size)
                    if segments.isEmpty {
                        Text("mac.viewer.sparkline.empty")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(segments) { segment in
                            speedPath(points: segment.points, in: geometry.size)
                                .stroke(.cyan, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
            }
            .frame(height: 132)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mac.accessibility.speed_chart.label"))
        .accessibilityValue(Text(maxSpeedLabel))
        .accessibilityHint(Text("mac.accessibility.speed_chart.hint"))
        .accessibilityIdentifier("mac-speed-chart")
    }

    private var maxSpeedLabel: String {
        let maxSpeed = points.map(\.speedKilometersPerHour).max() ?? 0
        return String(format: String(localized: "mac.package.preview.speed.format"), maxSpeed)
    }

    private func sparklinePoints(from result: SpeedDisplayResult) -> [MacSpeedSparklinePoint] {
        result.points.map { point in
            MacSpeedSparklinePoint(
                id: point.id,
                timestamp: point.timestamp,
                elapsedSeconds: point.elapsedSeconds,
                speedKilometersPerHour: point.speedKilometersPerHour,
                segmentID: point.segmentID
            )
        }
    }

    private func speedPath(points segmentPoints: [MacSpeedSparklinePoint], in size: CGSize) -> Path {
        let horizontalInset = 14.0
        let verticalInset = 14.0
        let drawingWidth = max(size.width - horizontalInset * 2, 1)
        let drawingHeight = max(size.height - verticalInset * 2, 1)
        let maxElapsed = max(points.last?.elapsedSeconds ?? 0, 1)
        let maxSpeed = max(points.map(\.speedKilometersPerHour).max() ?? 0, 1)

        var path = Path()
        for (index, point) in segmentPoints.enumerated() {
            let x = horizontalInset + (point.elapsedSeconds / maxElapsed) * drawingWidth
            let y = verticalInset + drawingHeight - (point.speedKilometersPerHour / maxSpeed) * drawingHeight
            let cgPoint = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: cgPoint)
            } else {
                path.addLine(to: cgPoint)
            }
        }
        return path
    }

    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            let rows = 3
            for row in 1...rows {
                let y = size.height * CGFloat(row) / CGFloat(rows + 1)
                path.move(to: CGPoint(x: 14, y: y))
                path.addLine(to: CGPoint(x: size.width - 14, y: y))
            }
        }
        .stroke(.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
    }
}

private struct MacSpeedSparklinePoint: Identifiable, Equatable {
    let id: Int
    let timestamp: Date
    let elapsedSeconds: TimeInterval
    let speedKilometersPerHour: Double
    let segmentID: Int
}

private struct MacSpeedSparklineSegment: Identifiable, Equatable {
    let id: Int
    let points: [MacSpeedSparklinePoint]
}

struct MacElevationProfileView: View {
    let points: [MacElevationPoint]

    private var segments: [MacElevationChartSegment] {
        Dictionary(grouping: points, by: \.segmentID)
            .map { MacElevationChartSegment(id: $0.key, points: $0.value.sorted { $0.elapsedSeconds < $1.elapsedSeconds }) }
            .filter { $0.points.count >= 2 }
            .sorted { $0.id < $1.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("mac.viewer.chart.elevation.title", systemImage: "mountain.2")
                    .font(.headline.bold())
                Spacer()
                Text(elevationRangeLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.055))
                    gridLines(in: geometry.size)
                    if segments.isEmpty {
                        Text("mac.viewer.chart.elevation.empty")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(segments) { segment in
                            elevationPath(points: segment.points, in: geometry.size)
                                .stroke(.orange, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
            }
            .frame(height: 132)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mac.accessibility.elevation_chart.label"))
        .accessibilityValue(Text(elevationRangeLabel))
        .accessibilityHint(Text("mac.viewer.chart.elevation.hint"))
        .accessibilityIdentifier("mac-elevation-chart")
    }

    private var elevationRangeLabel: String {
        let values = points.map(\.elevationMeters).filter(\.isFinite)
        guard let minimum = values.min(), let maximum = values.max() else {
            return String(localized: "mac.package.preview.value.none")
        }
        return String(format: String(localized: "mac.viewer.chart.elevation.range.format"), formatElevation(minimum), formatElevation(maximum))
    }

    private func elevationPath(points: [MacElevationPoint], in size: CGSize) -> Path {
        let horizontalInset = 14.0
        let verticalInset = 14.0
        let drawingWidth = max(size.width - horizontalInset * 2, 1)
        let drawingHeight = max(size.height - verticalInset * 2, 1)
        let allValues = self.points.map(\.elevationMeters).filter(\.isFinite)
        let minElevation = allValues.min() ?? 0
        let maxElevation = allValues.max() ?? minElevation + 1
        let elevationRange = max(maxElevation - minElevation, 1)
        let maxElapsed = max(self.points.last?.elapsedSeconds ?? 0, 1)

        var path = Path()
        for (index, point) in points.enumerated() {
            let x = horizontalInset + (point.elapsedSeconds / maxElapsed) * drawingWidth
            let normalizedY = (point.elevationMeters - minElevation) / elevationRange
            let y = verticalInset + drawingHeight - normalizedY * drawingHeight
            let cgPoint = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: cgPoint)
            } else {
                path.addLine(to: cgPoint)
            }
        }
        return path
    }

    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            let rows = 3
            for row in 1...rows {
                let y = size.height * CGFloat(row) / CGFloat(rows + 1)
                path.move(to: CGPoint(x: 14, y: y))
                path.addLine(to: CGPoint(x: size.width - 14, y: y))
            }
        }
        .stroke(.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
    }

    private func formatElevation(_ meters: Double) -> String {
        String(format: String(localized: "unit.length.meter.valueFormat"), meters)
    }
}

private struct MacElevationChartSegment: Identifiable {
    let id: Int
    let points: [MacElevationPoint]
}
