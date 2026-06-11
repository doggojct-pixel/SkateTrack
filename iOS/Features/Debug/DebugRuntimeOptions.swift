// [協作區] iOS/Features/Debug/DebugRuntimeOptions.swift
// 用途：統一管理 DEBUG-only runtime 選項，不讓 App 入口預設啟用 mock data。
// 委派至：DebugToolsPanelView 綁定，SessionRecordingViewModel 實際套用 session data source。

#if DEBUG
import Combine
import Foundation

@MainActor
final class DebugRuntimeOptions: ObservableObject {
    static let shared = DebugRuntimeOptions()

    @Published var isDebugToolsPresented = false

    private init() {}
}
#endif
