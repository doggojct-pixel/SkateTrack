// [協作區] SessionAdvancedChartsView.swift
// 用途：組合 iOS Session Summary 進階圖表，並把速度/海拔資料委派至 Shared display pipelines。
// 委派至：SpeedTimelineChartView / ElevationProfileChartView / AdvancedChartsLockedView。

import SwiftUI

struct SessionSummaryChartPoint: Identifiable, Equatable {
    let id: Int
    let elapsedSeconds: Double
    let value: Double
    let segmentID: Int
}

struct SessionSummaryChartSegment: Identifiable, Equatable {
    let id: Int
    let points: [SessionSummaryChartPoint]
}

struct SessionAdvancedChartsView: View {
    let content: SessionSummaryContent
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    let onUnlock: () -> Void

    private var fidelityPolicy: ActivityFidelityPolicy {
        ActivityFidelityPolicy(
            profile: content.session.fidelityProfile
                ?? ActivityFidelityProfile.defaultProfile(for: content.session.sportMode, powerType: content.session.powerType)
        )
    }

    private var speedResult: SpeedDisplayResult {
        SpeedDisplayPipeline(
            configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 120)
        ).makeDisplaySpeed(
            samples: content.motionSamples,
            fidelityPolicy: fidelityPolicy
        )
    }

    private var speedPoints: [SessionSummaryChartPoint] {
        chartPoints(from: speedResult)
    }

    private var elevationResult: ElevationDisplayResult {
        ElevationDisplayPipeline(
            configuration: ElevationDisplayConfiguration(maximumDisplayPointCount: 120)
        ).makeDisplayElevation(
            samples: content.motionSamples,
            fidelityPolicy: fidelityPolicy
        )
    }

    private var elevationPoints: [SessionSummaryChartPoint] {
        chartPoints(from: elevationResult)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if subscriptionStatus.hasAccess(to: .advancedCharts) {
                unlockedCharts
            } else {
                AdvancedChartsLockedView(speedPoints: speedPoints, elevationPoints: elevationPoints, onUnlock: onUnlock)
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
        VStack(spacing: 12) { SpeedTimelineChartView(result: speedResult); ElevationProfileChartView(points: elevationPoints) }
            .accessibilityIdentifier("session-advanced-charts-unlocked")
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

    private func chartPoints(from result: ElevationDisplayResult) -> [SessionSummaryChartPoint] {
        result.points.map { point in
            SessionSummaryChartPoint(
                id: point.id,
                elapsedSeconds: point.elapsedSeconds,
                value: point.elevationMeters,
                segmentID: point.segmentID
            )
        }
    }

}
