// [協作區] iOS/Features/Debug/DebugFeatureFlag.swift
// 用途：集中定義 DEBUG-only 工具旗標，讓正式 runtime 不再散落多個 debug 入口。
// 委派至：DebugToolsPanelView 呈現，Release build 透過 #if DEBUG 完全排除。

#if DEBUG
import Foundation

enum DebugFeatureFlag: String, CaseIterable, Identifiable, Sendable {
    case simulateFallAlert
    case demoSpeedSession
    case snowModeEntry
    case subscriptionOverride
    case resetEmergencyContacts

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .simulateFallAlert:
            return "debug.tools.simulateFall.title"
        case .demoSpeedSession:
            return "debug.tools.demoSpeed.title"
        case .snowModeEntry:
            return "debug.tools.snowMode.title"
        case .subscriptionOverride:
            return "debug.subscription.title"
        case .resetEmergencyContacts:
            return "debug.tools.resetContacts.title"
        }
    }

    var descriptionKey: String {
        switch self {
        case .simulateFallAlert:
            return "debug.tools.simulateFall.description"
        case .demoSpeedSession:
            return "debug.tools.demoSpeed.description"
        case .snowModeEntry:
            return "debug.tools.snowMode.description"
        case .subscriptionOverride:
            return "debug.tools.subscription.description"
        case .resetEmergencyContacts:
            return "debug.tools.resetContacts.description"
        }
    }
}
#endif
