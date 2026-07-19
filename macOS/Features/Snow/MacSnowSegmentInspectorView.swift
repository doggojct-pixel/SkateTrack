// [協作區] MacSnowSegmentInspectorView.swift
// 用途：顯示選定 Snow segment 的唯讀資料、計入 / 排除政策與低信心提示。
// 委派至：MacSnowRootView；manual correction persistence deferred。

import SwiftUI

struct MacSnowSegmentInspectorView: View {
    let analysis: MacSnowSessionAnalysis

    private var segment: SnowSegment? { analysis.selectedSegment }
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 10)]
    }

    var body: some View {
        MacSnowSection(
            titleKey: "mac.snow.inspector.title",
            subtitleKey: "mac.snow.inspector.subtitle",
            systemImage: "sidebar.right"
        ) {
            if let segment {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        MacSnowStatusPill(
                            titleKey: segment.countsTowardSkiDistance ? "mac.snow.inspector.counted" : "mac.snow.inspector.excluded",
                            systemImage: segment.countsTowardSkiDistance ? "checkmark.circle" : "minus.circle",
                            tint: segment.countsTowardSkiDistance ? MacSnowStyle.ice : MacSnowStyle.amber
                        )
                        if segment.confidence < 0.6 {
                            MacSnowStatusPill(
                                titleKey: "mac.snow.timeline.unknown",
                                systemImage: "exclamationmark.triangle",
                                tint: MacSnowStyle.red
                            )
                        }
                    }

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                        MacSnowMetricTile(titleKey: "mac.snow.timeline.distance", value: MacSnowFormatters.distanceMeters(segment.distanceMeters), systemImage: "ruler")
                        MacSnowMetricTile(titleKey: "mac.snow.timeline.duration", value: MacSnowFormatters.duration(segment.durationSeconds), systemImage: "timer")
                        MacSnowMetricTile(titleKey: "mac.snow.inspector.confidence", value: MacSnowFormatters.percent(segment.confidence), systemImage: "gauge.with.dots.needle.bottom.50percent")
                        MacSnowMetricTile(titleKey: "mac.snow.inspector.altitude_delta", value: MacSnowFormatters.signedAltitudeDelta(segment.verticalDeltaMeters), systemImage: "mountain.2")
                        MacSnowMetricTile(titleKey: "mac.snow.inspector.start_altitude", value: MacSnowFormatters.altitude(segment.startAltitudeMeters), systemImage: "arrow.up.to.line")
                        MacSnowMetricTile(titleKey: "mac.snow.inspector.end_altitude", value: MacSnowFormatters.altitude(segment.endAltitudeMeters), systemImage: "arrow.down.to.line")
                        MacSnowMetricTile(titleKey: "mac.snow.inspector.average_speed", value: MacSnowFormatters.speedKmh(fromMetersPerSecond: segment.averageSpeedMetersPerSecond ?? 0), systemImage: "speedometer")
                        MacSnowMetricTile(titleKey: "mac.snow.inspector.max_speed", value: MacSnowFormatters.speedKmh(fromMetersPerSecond: segment.maxSpeedMetersPerSecond ?? 0), systemImage: "bolt")
                    }

                    Label("mac.snow.inspector.manual_placeholder", systemImage: "pencil.slash")
                        .font(.caption)
                        .foregroundStyle(MacSnowStyle.text2)
                }
            } else {
                MacSnowEmptyState(
                    titleKey: "mac.snow.inspector.no_selection.title",
                    messageKey: "mac.snow.inspector.no_selection.message",
                    systemImage: "cursorarrow.click"
                )
            }
        }
    }
}
