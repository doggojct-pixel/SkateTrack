// [協作區] SnowSegmentTimelineView.swift
// 用途：顯示 Snow Mode persisted segments timeline，包含 lift / stopped / unknown，不只顯示 downhill。
// 委派至：SnowSessionRepository-backed SnowSessionState；不建立 fixture、不修改 classifier。

import SwiftUI

struct SnowSegmentTimelineView: View {
    let runs: [SnowRun]
    let segments: [SnowSegment]
    @Binding var selection: SnowSummarySelection?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if orderedRuns.isEmpty && orderedSegments.isEmpty {
                Text("snow.timeline.empty")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(orderedRuns) { run in
                        Button {
                            selection = .run(run.id)
                        } label: {
                            SnowRunTimelineRow(
                                run: run,
                                isSelected: selection == .run(run.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(orderedSegments) { segment in
                        Button {
                            selection = .segment(segment.id)
                        } label: {
                            SnowSegmentTimelineRow(
                                segment: segment,
                                isSelected: selection == .segment(segment.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.80))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("snow-segment-timeline-view")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("snow.timeline.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("snow.timeline.subtitle")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var orderedSegments: [SnowSegment] {
        segments.sorted { lhs, rhs in
            if lhs.startDate == rhs.startDate {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.startDate < rhs.startDate
        }
    }

    private var orderedRuns: [SnowRun] {
        runs.sorted { lhs, rhs in
            if lhs.runNumber != rhs.runNumber { return lhs.runNumber < rhs.runNumber }
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}

private struct SnowRunTimelineRow: View {
    let run: SnowRun
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "figure.skiing.downhill")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.ice)
                .frame(width: 30, height: 30)
                .background(SkateTrackSessionStartColors.ice.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("snow.timeline.run")
                    Text("\(run.runNumber)")
                }
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)

                HStack(spacing: 8) {
                    SnowSegmentMiniMetric(
                        value: SnowSummaryFormatters.distance(run.skiDistanceMeters),
                        labelKey: "snow.summary.skiDistance"
                    )
                    SnowSegmentMiniMetric(
                        value: SnowSummaryFormatters.duration(run.durationSeconds),
                        labelKey: "snow.timeline.duration"
                    )
                    SnowSegmentMiniMetric(
                        value: SnowSummaryFormatters.meters(run.verticalDropMeters),
                        labelKey: "snow.summary.verticalDrop"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SkateTrackSessionStartColors.ice.opacity(isSelected ? 0.85 : 0.18), lineWidth: isSelected ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("snow.timeline.selectionHint")
        .accessibilityIdentifier("snow-run-timeline-row-\(run.id.uuidString)")
    }
}

private struct SnowSegmentTimelineRow: View {
    let segment: SnowSegment
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 5) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(accentColor.opacity(0.28))
                    .frame(width: 2, height: 34)
            }
            .padding(.top, 5)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(LocalizedStringKey(segment.type.localizationKey))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(countingStatusKey)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.13))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    SnowSegmentMiniMetric(
                        value: SnowSummaryFormatters.distance(segment.distanceMeters),
                        labelKey: "snow.timeline.distance"
                    )
                    SnowSegmentMiniMetric(
                        value: SnowSummaryFormatters.duration(segment.durationSeconds),
                        labelKey: "snow.timeline.duration"
                    )
                    SnowSegmentMiniMetric(
                        value: SnowSummaryFormatters.confidence(segment.confidence),
                        labelKey: "snow.timeline.confidence"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(isSelected ? 0.85 : 0.18), lineWidth: isSelected ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("snow.timeline.selectionHint")
        .accessibilityIdentifier("snow-segment-timeline-row-\(segment.id.uuidString)")
    }

    private var countingStatusKey: LocalizedStringKey {
        segment.countsTowardSkiDistance ? "snow.timeline.counted" : "snow.timeline.excluded"
    }

    private var accentColor: Color {
        switch segment.type {
        case .downhillRun, .flatTraverse:
            return SkateTrackSessionStartColors.ice
        case .liftAscent, .gondolaAscent, .surfaceLiftAscent:
            return SkateTrackSessionStartColors.amber
        case .walking, .stopped:
            return SkateTrackSessionStartColors.textSecondary
        case .unknown:
            return SkateTrackSessionStartColors.purple
        }
    }
}

private struct SnowSegmentMiniMetric: View {
    let value: String
    let labelKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Snow Segment Timeline") {
    SnowSegmentTimelineView(
        runs: [],
        segments: [
            SnowSegment(
                sessionID: UUID(),
                runID: UUID(),
                type: .downhillRun,
                startDate: Date().addingTimeInterval(-180),
                endDate: Date().addingTimeInterval(-90),
                distanceMeters: 820,
                verticalDeltaMeters: -220,
                confidence: 0.86
            ),
            SnowSegment(
                sessionID: UUID(),
                type: .gondolaAscent,
                startDate: Date().addingTimeInterval(-80),
                endDate: Date(),
                distanceMeters: 1_240,
                verticalDeltaMeters: 260,
                confidence: 0.82
            )
        ],
        selection: .constant(nil)
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
