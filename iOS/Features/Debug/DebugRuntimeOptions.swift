// [協作區] iOS/Features/Debug/DebugRuntimeOptions.swift
// 用途：統一管理 DEBUG-only runtime 選項，不讓 App 入口預設啟用 mock data。
// 委派至：DebugToolsPanelView 綁定，SessionRecordingViewModel 實際套用 session data source。

#if DEBUG
import Combine
import Foundation

@MainActor
final class DebugRuntimeOptions: ObservableObject {
    static let shared = DebugRuntimeOptions()

    static let snowModeEntryUserDefaultsKey = "skateTrack.debug.snowModeEntryEnabled"
    static let snowHUDQAScenarioUserDefaultsKey = "skateTrack.debug.snowHUDQAScenario"

    @Published var isDebugToolsPresented = false
    @Published var isSnowModeEntryEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSnowModeEntryEnabled, forKey: Self.snowModeEntryUserDefaultsKey)
        }
    }
    @Published var selectedSnowHUDQAScenario: SnowHUDQAScenario? {
        didSet {
            if let selectedSnowHUDQAScenario {
                UserDefaults.standard.set(
                    selectedSnowHUDQAScenario.rawValue,
                    forKey: Self.snowHUDQAScenarioUserDefaultsKey
                )
            } else {
                UserDefaults.standard.removeObject(forKey: Self.snowHUDQAScenarioUserDefaultsKey)
            }
        }
    }

    private init() {
        isSnowModeEntryEnabled = UserDefaults.standard.bool(forKey: Self.snowModeEntryUserDefaultsKey)
        selectedSnowHUDQAScenario = UserDefaults.standard
            .string(forKey: Self.snowHUDQAScenarioUserDefaultsKey)
            .flatMap(SnowHUDQAScenario.init(rawValue:))
    }
}
#endif
