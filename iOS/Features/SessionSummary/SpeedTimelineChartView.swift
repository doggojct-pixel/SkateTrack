// [協作區] SpeedTimelineChartView.swift
// 用途：呈現 Task-018c 訂閱者可見的速度時間軸圖表。
// 委派至：SessionAdvancedChartsView 提供已降採樣的速度點，不直接查詢 Repository。

import Charts
import SwiftUI

struct SpeedTimelineChartView: View {
    let points: [SessionSummaryChartPoint]

    var body: some View {
        ChartCard(
            titleKey: "summary.advancedCharts.speed.title",
            subtitleKey: points.count >= 2 ? "summary.advancedCharts.speed.subtitle" : "summary.advancedCharts.speed.empty",
            systemImage: "speedometer",
            accentColor: SkateTrackSessionStartColors.teal
        ) {
            if points.count >= 2 {
                Chart(points) { point in
                    LineMark(
                        x: .value("summary.advancedCharts.axis.time", point.elapsedSeconds / 60),
                        y: .value("summary.advancedCharts.axis.speed", point.value)
                    )
                    .foregroundStyle(SkateTrackSessionStartColors.teal)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("summary.advancedCharts.axis.time", point.elapsedSeconds / 60),
                        y: .value("summary.advancedCharts.axis.speed", point.value)
                    )
                    .foregroundStyle(SkateTrackSessionStartColors.teal.opacity(0.16))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxisLabel { Text("summary.advancedCharts.axis.time") }
                .chartYAxisLabel { Text("summary.advancedCharts.axis.speed") }
                .frame(height: 164)
                .accessibilityIdentifier("summary-speed-timeline-chart")
            } else {
                ChartEmptyState(
                    titleKey: "summary.advancedCharts.speed.empty.title",
                    subtitleKey: "summary.advancedCharts.speed.empty.detail",
                    systemImage: "speedometer"
                )
            }
        }
        .accessibilityIdentifier("speed-timeline-chart-view")
    }
}
