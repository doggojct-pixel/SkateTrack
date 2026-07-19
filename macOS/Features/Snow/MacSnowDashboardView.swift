// [協作區] MacSnowDashboardView.swift
// 用途：顯示 macOS Snow viewer 的當日摘要與核心 read-only metrics。
// 委派至：MacSnowRootView；資料來源必須先經 MacSnowSessionAnalysis。

import SwiftUI

struct MacSnowDashboardView: View {
    let analysis: MacSnowSessionAnalysis

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 164), spacing: 12)]
    }

    var body: some View {
        MacSnowSection(
            titleKey: "mac.snow.dashboard.title",
            subtitleKey: "mac.snow.dashboard.subtitle",
            systemImage: "snowflake"
        ) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.runs",
                    value: "\(analysis.runs.count)",
                    systemImage: "flag.checkered"
                )
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.ski_distance",
                    value: MacSnowFormatters.distanceKilometers(analysis.distanceBreakdown.skiDistanceMeters),
                    systemImage: "figure.skiing.downhill",
                    footnoteKey: "mac.snow.distance.ski_note"
                )
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.vertical_drop",
                    value: MacSnowFormatters.distanceMeters(analysis.verticalMetrics.totalVerticalDropMeters),
                    systemImage: "arrow.down.right.and.arrow.up.left"
                )
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.top_speed",
                    value: MacSnowFormatters.speedKmh(fromMetersPerSecond: analysis.topSpeedMetersPerSecond),
                    systemImage: "speedometer"
                )
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.lift_distance",
                    value: MacSnowFormatters.distanceKilometers(analysis.distanceBreakdown.liftDistanceMeters),
                    systemImage: "cablecar"
                )
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.route_distance",
                    value: MacSnowFormatters.distanceKilometers(analysis.distanceBreakdown.routeDistanceMeters),
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up"
                )
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.duration",
                    value: MacSnowFormatters.duration(analysis.durationSeconds),
                    systemImage: "timer"
                )
                MacSnowMetricTile(
                    titleKey: "mac.snow.metric.average_run_duration",
                    value: MacSnowFormatters.duration(analysis.averageRunDurationSeconds),
                    systemImage: "clock.arrow.circlepath"
                )
            }

            HStack(spacing: 8) {
                MacSnowStatusPill(
                    titleKey: analysis.source == .debugMock ? "mac.snow.guardrail.debug_mock" : "mac.snow.guardrail.read_only",
                    systemImage: analysis.source == .debugMock ? "ladybug" : "lock"
                )

                if analysis.hasLimitedAltitudeData {
                    MacSnowStatusPill(
                        titleKey: "mac.snow.elevation.limited",
                        systemImage: "exclamationmark.triangle",
                        tint: MacSnowStyle.amber
                    )
                }
            }
        }
    }
}
