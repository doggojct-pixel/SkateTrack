// [協作區] MacSpeedSparklineView.swift
// 用途：在 macOS Session Viewer 中以輕量 SwiftUI Path 顯示速度趨勢預覽。
// 委派至：Task-028b 可替換為更完整的視覺化元件；本檔不引入額外圖表、地圖或外部服務。

import SwiftUI

struct MacSpeedSparklineView: View {
    let points: [MacSpeedPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("mac.viewer.sparkline.title", systemImage: "waveform.path.ecg")
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
                    if points.count >= 2 {
                        speedPath(in: geometry.size)
                            .stroke(.cyan, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    } else {
                        Text("mac.viewer.sparkline.empty")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(height: 104)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var maxSpeedLabel: String {
        let maxSpeed = points.map(\.speedKmh).max() ?? 0
        return String(format: String(localized: "mac.package.preview.speed.format"), maxSpeed)
    }

    private func speedPath(in size: CGSize) -> Path {
        let horizontalInset = 14.0
        let verticalInset = 14.0
        let drawingWidth = max(size.width - horizontalInset * 2, 1)
        let drawingHeight = max(size.height - verticalInset * 2, 1)
        let maxElapsed = max(points.last?.elapsedSeconds ?? 0, 1)
        let maxSpeed = max(points.map(\.speedKmh).max() ?? 0, 1)

        var path = Path()
        for (index, point) in points.enumerated() {
            let x = horizontalInset + (point.elapsedSeconds / maxElapsed) * drawingWidth
            let y = verticalInset + drawingHeight - (point.speedKmh / maxSpeed) * drawingHeight
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
