// [協作區] SpotRideabilityCardView.swift
// 用途：在 Spot 詳情顯示本機 mock rideability，基本狀態免費、詳細因素沿用健康提醒 Pro gating。
// 委派至：useWeatherRisk / WeatherRideabilityEngine；不接 WeatherKit、不做網路查詢、不要求定位權限。

import SwiftUI

struct SpotRideabilityCardView: View {
    let spot: SpotProfile
    @ObservedObject var weatherRisk: WeatherRiskViewModel
    let onOpenHealthReminders: () -> Void

    private var report: WeatherRideabilityReport {
        weatherRisk.rideabilityReport
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: report.snapshot.condition.systemImageName)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(WeatherRideabilityStatusChipView.levelColor(for: report.level))
                    .frame(width: 38, height: 38)
                    .background(WeatherRideabilityStatusChipView.levelColor(for: report.level).opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Text("weather.rideability.spot.title")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        WeatherRideabilityStatusChipView(level: report.level)
                    }
                    Text(LocalizedStringKey(report.summaryKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(LocalizedStringKey(report.snapshot.source.localizedDescriptionKey))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                }

                Spacer(minLength: 0)
            }

            if weatherRisk.canViewDetailedRisk {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(report.factors) { factor in
                        WeatherRiskFactorRowView(factor: factor)
                    }
                }
                .padding(12)
                .background(SkateTrackSessionStartColors.navy.opacity(0.36))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                lockedPreview
            }
        }
        .spotRideabilityPanel(level: report.level)
        .onAppear(perform: syncContext)
        .onChange(of: spot) { _, _ in syncContext() }
        .accessibilityIdentifier("spot-rideability-card")
    }

    private var lockedPreview: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.purple)
                .frame(width: 32, height: 32)
                .background(SkateTrackSessionStartColors.purple.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("weather.rideability.spot.locked.title")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("weather.rideability.spot.locked.subtitle")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onOpenHealthReminders) {
                    Text("weather.suitability.locked.cta")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(SkateTrackSessionStartColors.purple.opacity(0.14))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.navy.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func syncContext() {
        weatherRisk.updateContext(.spotPreview(spot), spot: spot)
    }
}

private extension View {
    func spotRideabilityPanel(level: WeatherSuitabilityLevel) -> some View {
        padding(14)
            .background(SkateTrackSessionStartColors.card.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(WeatherRideabilityStatusChipView.levelColor(for: level).opacity(0.34), lineWidth: 1)
            )
    }
}
