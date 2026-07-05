// [協作區] SpeedTimelineChartView.swift
// 用途：呈現 Task-018c 訂閱者可見的速度時間軸圖表。
// 委派至：SessionAdvancedChartsView 提供 Shared SpeedDisplayResult，不直接查詢 Repository。

import Charts
import SwiftUI

struct SpeedTimelineChartView: View {
    let result: SpeedDisplayResult

    private var points: [SessionSummaryChartPoint] {
        chartPoints(from: result)
    }

    private var segments: [SessionSummaryChartSegment] {
        makeSegments(from: points)
    }

    var body: some View {
        ChartCard(
            titleKey: "summary.advancedCharts.speed.title",
            subtitleKey: points.count >= 2 ? "summary.advancedCharts.speed.subtitle" : "summary.advancedCharts.speed.empty",
            systemImage: "speedometer",
            accentColor: SkateTrackSessionStartColors.teal
        ) {
            if points.count >= 2 {
                Chart {
                    ForEach(segments) { segment in
                        ForEach(segment.points) { point in
                            LineMark(
                                x: .value("summary.advancedCharts.axis.time", point.elapsedSeconds / 60),
                                y: .value("summary.advancedCharts.axis.speed", point.value),
                                series: .value("summary.advancedCharts.segment", segment.id)
                            )
                            .foregroundStyle(SkateTrackSessionStartColors.teal)
                            .interpolationMethod(.linear)
                        }
                    }
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

    private func chartPoints(from result: SpeedDisplayResult) -> [SessionSummaryChartPoint] {
        result.points.map { point in
            SessionSummaryChartPoint(
                id: point.id,
                elapsedSeconds: point.elapsedSeconds,
                value: point.speedKilometersPerHour,
                segmentID: point.segmentID
            )
        }
    }

    private func makeSegments(from points: [SessionSummaryChartPoint]) -> [SessionSummaryChartSegment] {
        Dictionary(grouping: points, by: \.segmentID)
            .map { SessionSummaryChartSegment(id: $0.key, points: $0.value.sorted { $0.elapsedSeconds < $1.elapsedSeconds }) }
            .filter { $0.points.count >= 2 }
            .sorted { $0.id < $1.id }
    }
}
