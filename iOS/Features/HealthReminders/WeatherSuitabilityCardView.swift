// [協作區] WeatherSuitabilityCardView.swift
// 用途：呈現 Task-022 滑行天氣與本機 rideability 卡片；基本摘要免費可見，完整風險說明沿用 Pro 權限邊界。
// 委派至：useWeatherRisk 提供 mock / disabled provider 報告；SessionStartWeatherSectionView 負責同步 context。

import SwiftUI

struct WeatherSuitabilityCardView: View {
    @ObservedObject var weatherRisk: WeatherRiskViewModel
    let onOpenHealthReminders: () -> Void

    private var report: WeatherRideabilityReport {
        weatherRisk.rideabilityReport
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            contextLine
            summaryMetrics

            if let errorMessageKey = weatherRisk.errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
            }

            if weatherRisk.canViewDetailedRisk {
                detailedRiskRows
            } else {
                lockedDetailedRiskPreview
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(WeatherRideabilityStatusChipView.levelColor(for: report.level).opacity(0.34), lineWidth: 1)
        )
        .shadow(color: WeatherRideabilityStatusChipView.levelColor(for: report.level).opacity(0.13), radius: 22, x: 0, y: 14)
        .accessibilityIdentifier("weather-suitability-card")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: report.snapshot.condition.systemImageName)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(WeatherRideabilityStatusChipView.levelColor(for: report.level))
                .frame(width: 40, height: 40)
                .background(WeatherRideabilityStatusChipView.levelColor(for: report.level).opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text("weather.suitability.title")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    WeatherRideabilityStatusChipView(level: report.level)
                }

                Text(LocalizedStringKey(report.summaryKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStringKey(report.snapshot.source.localizedDescriptionKey))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            }

            Spacer(minLength: 0)

            Button {
                weatherRisk.refresh()
            } label: {
                Image(systemName: weatherRisk.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)
                    .frame(width: 34, height: 34)
                    .background(SkateTrackSessionStartColors.card.opacity(0.78))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("weather.suitability.refresh")
            .accessibilityIdentifier("weather-suitability-refresh")
        }
    }

    private var contextLine: some View {
        HStack(spacing: 8) {
            Image(systemName: report.context.hasSpot ? "mappin.circle.fill" : "location.slash.fill")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
            Text(LocalizedStringKey(report.context.purpose.localizationKey))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            if let spotName = report.spotName, !spotName.isEmpty {
                Text(verbatim: spotName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
            } else {
                Text("weather.context.noSpot")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var summaryMetrics: some View {
        HStack(spacing: 8) {
            metricPill(titleKey: "weather.suitability.temperature", value: String(format: "%.0f°C", report.snapshot.temperatureCelsius))
            metricPill(titleKey: "weather.suitability.uv", value: String(format: "%.0f", report.snapshot.uvIndex))
            metricPill(titleKey: "weather.suitability.rain", value: "\(Int(report.snapshot.precipitationProbability * 100))%")
        }
    }

    private func metricPill(titleKey: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)

            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(SkateTrackSessionStartColors.navy3.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var detailedRiskRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("weather.suitability.details.title")
                .tracking(1.3)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .textCase(.uppercase)

            ForEach(report.factors) { factor in
                WeatherRiskFactorRowView(factor: factor)
            }
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.navy.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("weather-detailed-risk-list")
    }

    private var lockedDetailedRiskPreview: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.purple)
                .frame(width: 32, height: 32)
                .background(SkateTrackSessionStartColors.purple.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("weather.suitability.locked.title")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("weather.suitability.locked.subtitle")
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
                .accessibilityIdentifier("weather-suitability-locked-cta")
            }
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.navy.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("weather-detailed-risk-locked-preview")
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                SkateTrackSessionStartColors.card.opacity(0.94),
                SkateTrackSessionStartColors.navy3.opacity(0.80)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Weather Suitability") {
    WeatherSuitabilityCardView(
        weatherRisk: useWeatherRisk(subscriptionStatus: useSubscriptionStatus()),
        onOpenHealthReminders: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
