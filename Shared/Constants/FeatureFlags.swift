// [協作區] FeatureFlags.swift
// 用途：集中定義 SkateTrack Phase 1a 受限功能，供訂閱門禁與 UI 狀態共用。
// 委派至：iOS/Core/Subscription/FeatureFlagEngine.swift 判斷實際存取權。

import Foundation

enum GatedFeature: String, CaseIterable, Codable, Identifiable, Sendable {
    case unlimitedHistory
    case advancedCharts
    case healthReminders
    case equipmentManager
    case spotManagement
    case googleDriveSync
    case inlineFitnessMode
    case inlineAggressiveMode
    case inlineSlalomMode
    case sessionShareCard
    case advancedChallenges

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .unlimitedHistory:
            return "feature.unlimited_history"
        case .advancedCharts:
            return "feature.advanced_charts"
        case .healthReminders:
            return "feature.health_reminders"
        case .equipmentManager:
            return "feature.equipment_manager"
        case .spotManagement:
            return "feature.spot_management"
        case .googleDriveSync:
            return "feature.google_drive_sync"
        case .inlineFitnessMode:
            return "feature.inline_fitness_mode"
        case .inlineAggressiveMode:
            return "feature.inline_aggressive_mode"
        case .inlineSlalomMode:
            return "feature.inline_slalom_mode"
        case .sessionShareCard:
            return "feature.session_share_card"
        case .advancedChallenges:
            return "feature.advanced_challenges"
        }
    }
}

enum FreeFeature: String, CaseIterable, Codable, Identifiable, Sendable {
    case basicDashboard
    case basicSessionRecording
    case basicHistoryPreview
    case basicModeSelection

    var id: String { rawValue }
}
