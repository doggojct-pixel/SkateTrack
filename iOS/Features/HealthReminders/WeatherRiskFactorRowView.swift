// [協作區] WeatherRiskFactorRowView.swift
// 用途：呈現單一 weather / rideability 風險因素列，避免 WeatherSuitabilityCardView 膨脹。
// 委派至：WeatherSuitabilityCardView / SpotRideabilityCardView 決定顯示哪些因素。

import SwiftUI

struct WeatherRiskFactorRowView: View {
    let factor: WeatherRideabilityFactor

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: factor.id.systemImageName)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(levelColor)
                .frame(width: 28, height: 28)
                .background(levelColor.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(LocalizedStringKey(factor.id.titleKey))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(verbatim: factor.valueText)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(levelColor)
                }

                Text(LocalizedStringKey(factor.messageKey))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("weather-risk-factor-row")
    }

    private var levelColor: Color {
        WeatherRideabilityStatusChipView.levelColor(for: factor.level)
    }
}
