// [協作區] SessionAdvancedChartsView.swift
// 用途：整合 Task-018c 進階圖表區塊，依訂閱權限顯示鎖定預覽或完整圖表。
// 委派至：useSubscriptionStatus / FeatureFlagEngine 處理付費門禁；SpeedTimelineChartView 與 ElevationProfileChartView 呈現圖表。

import SwiftUI

struct SessionSummaryChartPoint: Identifiable, Equatable {
    let id: Int
    let elapsedSeconds: Double
    let value: Double
}

struct SessionAdvancedChartsView: View {
    let content: SessionSummaryContent
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    let onUnlock: () -> Void

    private var speedPoints: [SessionSummaryChartPoint] {
        chartPoints(from: content.motionSamples) { sample in
            sample.speedKmh.isFinite && sample.speedKmh >= 0 ? sample.speedKmh : nil
        }
    }

    private var elevationPoints: [SessionSummaryChartPoint] {
        chartPoints(from: content.motionSamples) { sample in
            guard let altitude = sample.altitudeMeters, altitude.isFinite else { return nil }
            return altitude
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if subscriptionStatus.hasAccess(to: .advancedCharts) {
                unlockedCharts
            } else {
                AdvancedChartsLockedView(
                    speedPoints: speedPoints,
                    elevationPoints: elevationPoints,
                    onUnlock: onUnlock
                )
            }

            HeartRateZonePlaceholderView()
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border.opacity(0.85), lineWidth: 1))
        .accessibilityIdentifier("session-advanced-charts-view")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)

                Text("summary.advancedCharts.title")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(LocalizedStringKey(subscriptionStatus.hasAccess(to: .advancedCharts) ? "subscription.subscriber" : "subscription.pro_badge"))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(subscriptionStatus.hasAccess(to: .advancedCharts) ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.purple)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }

            Text(LocalizedStringKey(subscriptionStatus.hasAccess(to: .advancedCharts) ? "summary.advancedCharts.unlocked.subtitle" : "summary.advancedCharts.locked.subtitle"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var unlockedCharts: some View {
        VStack(spacing: 12) {
            SpeedTimelineChartView(points: speedPoints)
            ElevationProfileChartView(points: elevationPoints)
        }
        .accessibilityIdentifier("session-advanced-charts-unlocked")
    }

    private func chartPoints(
        from samples: [MotionSample],
        value: (MotionSample) -> Double?
    ) -> [SessionSummaryChartPoint] {
        let sortedSamples = samples.sorted { $0.timestamp < $1.timestamp }
        guard let firstTimestamp = sortedSamples.first?.timestamp else { return [] }

        let rawPoints = sortedSamples.enumerated().compactMap { index, sample -> SessionSummaryChartPoint? in
            guard let value = value(sample), value.isFinite else { return nil }
            return SessionSummaryChartPoint(
                id: index,
                elapsedSeconds: max(0, sample.timestamp.timeIntervalSince(firstTimestamp)),
                value: value
            )
        }

        return downsample(rawPoints, maxCount: 120)
    }

    private func downsample(_ points: [SessionSummaryChartPoint], maxCount: Int) -> [SessionSummaryChartPoint] {
        guard points.count > maxCount, maxCount > 1 else { return points }
        let stride = max(1, Int(ceil(Double(points.count) / Double(maxCount))))
        var sampled = points.enumerated().compactMap { offset, point in
            offset.isMultiple(of: stride) ? point : nil
        }

        if let last = points.last, sampled.last != last {
            sampled.append(last)
        }

        return sampled
    }
}

#Preview("Advanced Charts") {
    let previewSession = try! SessionData(
        startDate: Date().addingTimeInterval(-900),
        endDate: Date(),
        sportMode: .skateboard(.streetPark),
        motionSamples: [],
        summaryMetrics: .zero
    )

    return SessionAdvancedChartsView(
        content: SessionSummaryContent(
            session: previewSession,
            motionSamples: previewSession.motionSamples
        ),
        subscriptionStatus: useSubscriptionStatus(),
        onUnlock: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
