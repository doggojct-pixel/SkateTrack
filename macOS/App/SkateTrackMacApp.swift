// [協作區] SkateTrackMacApp.swift
// 用途：定義 SkateTrack macOS App 入口點，並用本地化鍵值顯示 Task-002 驗證用空殼畫面。
// 委派至：後續 Task 的 macOS/Features 與 macOS/Core 模組。

import SwiftUI

@main
struct SkateTrackMacApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("app.name")
                    .font(.largeTitle.bold())
                Text("app.tagline")
                    .font(.title3)
            }
            .frame(minWidth: 420, minHeight: 260)
            .padding()
        }
    }
}
