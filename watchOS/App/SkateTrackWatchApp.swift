// [協作區] SkateTrackWatchApp.swift
// 用途：定義 SkateTrack watchOS App 入口點，並用本地化鍵值顯示 Task-002 驗證用空殼畫面。
// 委派至：後續 Task 的 watchOS/Features 與 watchOS/Core 模組。

import SwiftUI

@main
struct SkateTrackWatchApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 4) {
                Text("app.name")
                    .font(.headline)
                Text("app.tagline")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
