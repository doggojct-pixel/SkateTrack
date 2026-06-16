// [協作區] SnowDaySummaryView.swift
// 用途：顯示 Snow Mode repository-backed day/session summary，清楚拆分滑行、纜車與路線距離。
// 委派至：useSnowSession / SnowSessionRepository；不讀取 live detector、不修改 persistence。

import SwiftUI

struct SnowDaySummaryView: View {
    let state: SnowSessionState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            switch state.loadState {
            case .loading:
                loadingState
            case let .error(errorKey):
                errorState(errorKey)
            default:
                if state.runs.isEmpty && state.segments.isEmpty {
                    emptyState
                } else {
                    summaryGrid
                }
            }
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.ice.opacity(0.22), lineWidth: 1))
        .accessibilityIdentifier("snow-day-summary-view")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("snow.summary.title")
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("snow.summary.subtitle")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(SkateTrackSessionStartColors.ice)
            Text("snow.summary.loading")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private func errorState(_ errorKey: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("snow.summary.error.title")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.amber)
            Text(LocalizedStringKey(errorKey))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
    }

    private var emptyState: some View {
        Text("snow.summary.empty")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 8)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            SnowSummaryMetricTile(
                value: "\(state.runs.count)",
                labelKey: "snow.summary.runs",
                tintColor: SkateTrackSessionStartColors.ice,
                accessibilityID: "snow-summary-runs"
            )
            SnowSummaryMetricTile(
                value: SnowSummaryFormatters.meters(state.verticalMetrics.totalVerticalDropMeters),
                labelKey: "snow.summary.verticalDrop",
                tintColor: SkateTrackSessionStartColors.ice,
                accessibilityID: "snow-summary-vertical-drop"
            )
            SnowSummaryMetricTile(
                value: SnowSummaryFormatters.distance(state.distanceBreakdown.skiDistanceMeters),
                labelKey: "snow.summary.skiDistance",
                tintColor: SkateTrackSessionStartColors.teal,
                accessibilityID: "snow-summary-ski-distance"
            )
            SnowSummaryMetricTile(
                value: SnowSummaryFormatters.speed(maxTopSpeedKmh),
                labelKey: "snow.summary.topSpeed",
                tintColor: SkateTrackSessionStartColors.purple,
                accessibilityID: "snow-summary-top-speed"
            )
        }
    }

    private var maxTopSpeedKmh: Double {
        state.runs.map { $0.topSpeedMetersPerSecond * 3.6 }.max() ?? 0
    }
}

struct SnowSummaryMetricTile: View {
    let value: String
    let labelKey: String
    let tintColor: Color
    let accessibilityID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(tintColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(labelKey))
                .tracking(1.0)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(SkateTrackSessionStartColors.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier(accessibilityID)
    }
}

enum SnowSummaryFormatters {
    static func distance(_ meters: Double) -> String {
        UnitFormatter.distance(meters: meters, maximumFractionDigits: meters >= 1_000 ? 2 : 0)
    }

    static func meters(_ meters: Double) -> String {
        String(format: "%.0f m", max(0, meters))
    }

    static func speed(_ kmh: Double) -> String {
        String(format: "%.1f km/h", max(0, kmh))
    }

    static func duration(_ seconds: TimeInterval?) -> String {
        guard let seconds else { return NSLocalizedString("general.value.unavailable", comment: "") }
        let totalSeconds = max(0, Int(seconds.rounded()))
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    static func confidence(_ value: Double) -> String {
        String(format: "%.0f%%", min(max(value, 0), 1) * 100)
    }
}

#Preview("Snow Day Summary") {
    SnowDaySummaryView(
        state: SnowSessionState(
            sessionID: UUID(),
            loadState: .loaded,
            runs: [
                SnowRun(
                    sessionID: UUID(),
                    runNumber: 1,
                    startDate: Date().addingTimeInterval(-120),
                    endDate: Date().addingTimeInterval(-40),
                    skiDistanceMeters: 720,
                    verticalDropMeters: 210,
                    topSpeedMetersPerSecond: 13.8
                )
            ],
            segments: []
        )
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
