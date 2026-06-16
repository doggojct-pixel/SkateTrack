// [協作區] iOS/Features/SessionRecording/LiveSpeedTraceView.swift
// 用途：呈現 Live HUD 主速度區的時間 × 速度背景曲線。
// 委派至：LiveHUDView 提供本地暫存速度 samples。

import Foundation
import SwiftUI

struct LiveSpeedTraceSample: Equatable {
    let elapsedTime: TimeInterval
    let speedKilometersPerHour: Double
}

struct LiveSpeedTraceView: View {
    let samples: [LiveSpeedTraceSample]
    let maxSpeedKilometersPerHour: Double
    let accentColor: Color

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(x: 8, y: 14, width: max(1, size.width - 16), height: max(1, size.height - 28))
            var guidePath = Path()
            for index in 0...3 {
                let y = rect.minY + rect.height * CGFloat(index) / 3
                guidePath.move(to: CGPoint(x: rect.minX, y: y))
                guidePath.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            context.stroke(guidePath, with: .color(Color.white.opacity(0.07)), style: StrokeStyle(lineWidth: 1, dash: [4, 12]))

            let traceSamples = Array(samples.filter { $0.elapsedTime.isFinite && $0.speedKilometersPerHour.isFinite }.suffix(90))
            guard traceSamples.count >= 2, let firstSample = traceSamples.first, let lastSample = traceSamples.last else {
                drawWaitingTrace(in: rect, context: context)
                return
            }

            let timeSpan = max(lastSample.elapsedTime - firstSample.elapsedTime, 1)
            let visibleMaxSpeed = max(8, maxSpeedKilometersPerHour, traceSamples.map(\.speedKilometersPerHour).max() ?? 0)
            var linePath = Path()
            var firstPoint: CGPoint = .zero
            var lastPoint: CGPoint = .zero

            for (index, sample) in traceSamples.enumerated() {
                let timeRatio = CGFloat((sample.elapsedTime - firstSample.elapsedTime) / timeSpan)
                let speedRatio = CGFloat(min(max(sample.speedKilometersPerHour / visibleMaxSpeed, 0), 1))
                let point = CGPoint(x: rect.minX + rect.width * timeRatio, y: rect.maxY - rect.height * speedRatio)
                if index == 0 { firstPoint = point; linePath.move(to: point) } else { linePath.addLine(to: point) }
                lastPoint = point
            }

            var fillPath = linePath
            fillPath.addLine(to: CGPoint(x: lastPoint.x, y: rect.maxY))
            fillPath.addLine(to: CGPoint(x: firstPoint.x, y: rect.maxY))
            fillPath.closeSubpath()
            context.fill(fillPath, with: .color(accentColor.opacity(0.14)))
            context.addFilter(.shadow(color: accentColor.opacity(0.36), radius: 9))
            context.stroke(linePath, with: .color(accentColor.opacity(0.82)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
        }
        .opacity(0.96)
        .accessibilityIdentifier("live-hud-speed-trace")
    }

    private func drawWaitingTrace(in rect: CGRect, context: GraphicsContext) {
        let y = rect.maxY - rect.height * 0.18
        var baseline = Path()
        baseline.move(to: CGPoint(x: rect.minX, y: y))
        baseline.addLine(to: CGPoint(x: rect.maxX, y: y))

        var drawingContext = context
        drawingContext.addFilter(
            .shadow(
                color: accentColor.opacity(0.24),
                radius: 7
            )
        )
        drawingContext.stroke(
            baseline,
            with: .color(accentColor.opacity(0.34)),
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                dash: [8, 10]
            )
        )
    }
}
