// [協作區] MacSnowSegmentTimelineView.swift
// 用途：顯示 Snow segments read-only timeline，點選後只更新本地 selectedSegmentID。
// 委派至：MacSnowRootView / MacSnowSegmentInspectorView；不得 persistence write。

import SwiftUI

struct MacSnowSegmentTimelineView: View {
    let analysis: MacSnowSessionAnalysis
    @Binding var selectedSegmentID: UUID?

    var body: some View {
        MacSnowSection(
            titleKey: "mac.snow.timeline.title",
            subtitleKey: "mac.snow.timeline.subtitle",
            systemImage: "timeline.selection"
        ) {
            if analysis.segments.isEmpty {
                MacSnowEmptyState(
                    titleKey: "mac.snow.timeline.empty",
                    messageKey: "mac.snow.unavailable.no_segments",
                    systemImage: "timeline.selection"
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(analysis.segments) { segment in
                        MacSnowSegmentTimelineRow(
                            segment: segment,
                            isSelected: selectedSegmentID == segment.id
                        ) {
                            selectedSegmentID = segment.id
                        }
                    }
                }
            }
        }
    }
}

private struct MacSnowSegmentTimelineRow: View {
    let segment: SnowSegment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(MacSnowStyle.segmentColor(for: segment.type))
                    .frame(width: 10)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(LocalizedStringKey(segment.type.localizationKey))
                            .font(.callout.weight(.semibold))
                        MacSnowStatusPill(
                            titleKey: segment.countsTowardSkiDistance ? "mac.snow.timeline.counted" : "mac.snow.timeline.excluded",
                            systemImage: segment.countsTowardSkiDistance ? "checkmark.circle" : "minus.circle",
                            tint: segment.countsTowardSkiDistance ? MacSnowStyle.ice : MacSnowStyle.amber
                        )
                    }

                    HStack(spacing: 14) {
                        Label(MacSnowFormatters.distanceMeters(segment.distanceMeters), systemImage: "ruler")
                        Label(MacSnowFormatters.duration(segment.durationSeconds), systemImage: "timer")
                        Label(MacSnowFormatters.percent(segment.confidence), systemImage: "gauge.with.dots.needle.bottom.50percent")
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(MacSnowStyle.text2)
                }

                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(isSelected ? MacSnowStyle.ice : MacSnowStyle.text2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? MacSnowStyle.segmentGradient(for: segment.type) : MacSnowStyle.cardGradient,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? MacSnowStyle.segmentColor(for: segment.type).opacity(0.50) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(segment.type.localizationKey)))
    }
}
