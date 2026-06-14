// [協作區] iOS/Features/Debug/DebugToolAction.swift
// 用途：集中描述 DEBUG-only 工具動作，避免測試入口散落在正式 UI 元件內。
// 委派至：DebugToolsPanelView 執行實際操作。

#if DEBUG
import Foundation

enum DebugToolAction: String, Identifiable, Sendable {
    case openPanel
    case simulateFallAlert
    case enableDemoSpeedSession
    case disableDemoSpeedSession
    case toggleSnowModeEntry
    case resetEmergencyContacts

    var id: String { rawValue }

    var accessibilityIdentifier: String {
        switch self {
        case .openPanel:
            return "debug-tools-open-button"
        case .simulateFallAlert:
            return "debug-tools-simulate-fall-button"
        case .enableDemoSpeedSession, .disableDemoSpeedSession:
            return "debug-tools-demo-speed-toggle"
        case .toggleSnowModeEntry:
            return "debug-tools-snow-mode-entry-toggle"
        case .resetEmergencyContacts:
            return "debug-tools-reset-emergency-contacts-button"
        }
    }
}
#endif
