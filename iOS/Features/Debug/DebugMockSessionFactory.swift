// [協作區] iOS/Features/Debug/DebugMockSessionFactory.swift
// 用途：集中管理 mock speed / demo session 切換，避免 App 正常 Debug runtime 自動吃假資料。
// 委派至：DebugToolsPanelView；SwiftUI Preview 仍可使用 makeMockCoordinator()。

#if DEBUG
import Foundation

@MainActor
enum DebugMockSessionFactory {
    static func makeDemoSpeedCoordinator() -> SessionRecordingCoordinator {
        .makeMockCoordinator()
    }

    static func setDemoSpeedSessionEnabled(
        _ isEnabled: Bool,
        on sessionRecording: SessionRecordingViewModel
    ) {
        sessionRecording.setDebugDemoSpeedSessionEnabled(isEnabled)
    }
}
#endif
