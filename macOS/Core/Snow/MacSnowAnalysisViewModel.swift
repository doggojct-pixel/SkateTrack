// [協作區] MacSnowAnalysisViewModel.swift
// 用途：持有 macOS Snow viewer 的 observable availability 與 segment selection；analysis 本身保持 struct value。
// 委派至：MacRootView / MacSnowRootView；repository/package adapter 於後續階段注入。

import Combine
import Foundation

@MainActor
final class MacSnowAnalysisViewModel: ObservableObject {
    @Published private(set) var availability: MacSnowAnalysisAvailability
    @Published var selectedSegmentID: UUID? {
        didSet { applySelection() }
    }

    init(availability: MacSnowAnalysisAvailability = .packageSchemaPending) {
        self.availability = availability
    }

    var analysis: MacSnowSessionAnalysis? {
        availability.analysis
    }

    var selectedSegmentSelection: MacSnowSegmentSelection? {
        analysis?.selectedSegmentSelection
    }

    func updateAvailability(_ availability: MacSnowAnalysisAvailability) {
        self.availability = availability
        if availability.analysis?.segments.contains(where: { $0.id == selectedSegmentID }) != true {
            selectedSegmentID = nil
        } else {
            applySelection()
        }
    }

    func showPackageSchemaPending() {
        updateAvailability(.packageSchemaPending)
    }

    #if DEBUG
    func loadMockScenario(_ scenario: MacSnowMockScenario = .resortDay) {
        updateAvailability(MacSnowMockAnalysisProvider.makeAvailability(scenario: scenario))
    }
    #endif

    private func applySelection() {
        guard case let .available(analysis) = availability else { return }
        availability = .available(analysis.selecting(segmentID: selectedSegmentID))
    }
}
