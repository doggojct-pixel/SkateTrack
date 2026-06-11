// [協作區] ElevationProfileChartView.swift
// 用途：呈現 Task-018c 訂閱者可見的海拔剖面圖表。
// 委派至：SessionAdvancedChartsView 提供已降採樣的海拔點，不直接查詢 Repository。

import Charts
import SwiftUI

struct ElevationProfileChartView: View {
    let points: [SessionSummaryChartPoint]

    var body: some View {
        ChartCard(
            titleKey: "summary.advancedCharts.elevation.title",
            subtitleKey: points.count >= 2 ? "summary.advancedCharts.elevation.subtitle" : "summary.advancedCharts.elevation.empty",
            systemImage: "mountain.2.fill",
            accentColor: SkateTrackSessionStartColors.amber
        ) {
            if points.count >= 2 {
                Chart(points) { point in
                    LineMark(
                        x: .value("summary.advancedCharts.axis.time", point.elapsedSeconds / 60),
                        y: .value("summary.advancedCharts.axis.elevation", point.value)
                    )
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                    .interpolationMethod(.monotone)

                    AreaMark(
                        x: .value("summary.advancedCharts.axis.time", point.elapsedSeconds / 60),
                        y: .value("summary.advancedCharts.axis.elevation", point.value)
                    )
                    .foregroundStyle(SkateTrackSessionStartColors.amber.opacity(0.14))
                    .interpolationMethod(.monotone)
                }
                .chartXAxisLabel { Text("summary.advancedCharts.axis.time") }
                .chartYAxisLabel { Text("summary.advancedCharts.axis.elevation") }
                .frame(height: 164)
                .accessibilityIdentifier("summary-elevation-profile-chart")
            } else {
                ChartEmptyState(
                    titleKey: "summary.advancedCharts.elevation.empty.title",
                    subtitleKey: "summary.advancedCharts.elevation.empty.detail",
                    systemImage: "mountain.2.fill"
                )
            }
        }
        .accessibilityIdentifier("elevation-profile-chart-view")
    }
}
