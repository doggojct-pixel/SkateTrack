// [協作區] WeatherRideabilityStatusChipView.swift
// 用途：以統一深色霓虹 chip 呈現滑行適合度狀態。
// 委派至：WeatherSuitabilityCardView、SpotRideabilityCardView 與地圖 / 列表輕量提示共用。

import SwiftUI

struct WeatherRideabilityStatusChipView: View {
    let level: WeatherSuitabilityLevel
    var compact = false

    var body: some View {
        Text(LocalizedStringKey(level.titleKey))
            .font(.system(size: compact ? 8 : 9, weight: .black, design: .monospaced))
            .foregroundStyle(Self.levelColor(for: level))
            .padding(.horizontal, compact ? 6 : 7)
            .padding(.vertical, compact ? 3 : 4)
            .background(Self.levelColor(for: level).opacity(0.16))
            .clipShape(Capsule())
            .accessibilityIdentifier("weather-rideability-status-chip")
    }

    static func levelColor(for level: WeatherSuitabilityLevel) -> Color {
        switch level {
        case .excellent:
            return SkateTrackSessionStartColors.teal
        case .good:
            return SkateTrackSessionStartColors.green
        case .caution:
            return SkateTrackSessionStartColors.amber
        case .unsafe:
            return SkateTrackSessionStartColors.accent2
        }
    }
}
