// [協作區] SessionStartWeatherSectionView.swift
// 用途：在 Session Start 中同步目前運動模式 / 選取場地給 weather boundary，避免主 View 膨脹。
// 委派至：WeatherSuitabilityCardView 呈現本機 mock rideability；不請定位權限、不接真實天氣服務。

import SwiftUI

struct SessionStartWeatherSectionView: View {
    @ObservedObject var weatherRisk: WeatherRiskViewModel
    let selectedSportMode: SportMode
    let selectedSpot: SpotProfile?
    let onOpenHealthReminders: () -> Void

    var body: some View {
        WeatherSuitabilityCardView(
            weatherRisk: weatherRisk,
            onOpenHealthReminders: onOpenHealthReminders
        )
        .onAppear(perform: syncContext)
        .onChange(of: selectedSportMode) { _, _ in syncContext() }
        .onChange(of: selectedSpot) { _, _ in syncContext() }
        .accessibilityIdentifier("session-start-weather-section")
    }

    private func syncContext() {
        weatherRisk.updateContext(
            .rideStart(sportMode: selectedSportMode, selectedSpot: selectedSpot),
            spot: selectedSpot
        )
    }
}
