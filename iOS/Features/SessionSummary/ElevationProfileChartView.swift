// [協作區] ElevationProfileChartView.swift
// 用途：呈現 Task-018c 訂閱者可見的海拔剖面圖表。
// 委派至：SessionAdvancedChartsView 提供已降採樣且 gap-aware 的海拔點，不直接查詢 Repository。

import Charts
import SwiftUI

struct ElevationProfileChartView: View {
    let points: [SessionSummaryChartPoint]

    private var segments: [SessionSummaryChartSegment] {
        makeSegments(from: points)
    }

    var body: some View {
        ChartCard(
            titleKey: "summary.advancedCharts.elevation.title",
            subtitleKey: points.count >= 2 ? "summary.advancedCharts.elevation.subtitle" : "summary.advancedCharts.elevation.empty",
            systemImage: "mountain.2.fill",
            accentColor: SkateTrackSessionStartColors.amber
        ) {
            if points.count >= 2 {
                Chart {
                    ForEach(segments) { segment in
                        ForEach(segment.points) { point in
                            LineMark(
                                x: .value("summary.advancedCharts.axis.time", point.elapsedSeconds / 60),
                                y: .value("summary.advancedCharts.axis.elevation", point.value),
                                series: .value("summary.advancedCharts.segment", segment.id)
                            )
                            .foregroundStyle(SkateTrackSessionStartColors.amber)
                            .interpolationMethod(.linear)
                        }
                    }
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

    private func makeSegments(from points: [SessionSummaryChartPoint]) -> [SessionSummaryChartSegment] {
        Dictionary(grouping: points, by: \.segmentID)
            .map { SessionSummaryChartSegment(id: $0.key, points: $0.value.sorted { $0.elapsedSeconds < $1.elapsedSeconds }) }
            .filter { $0.points.count >= 2 }
            .sorted { $0.id < $1.id }
    }
}
