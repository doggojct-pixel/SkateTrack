// [協作區] SkateTrackApp.swift
// 用途：定義 SkateTrack iOS App 入口點，並用本地化鍵值顯示 Task-002 驗證用空殼畫面。
// 委派至：後續 Task 的 iOS/Features 與 iOS/Hooks 模組。

import SwiftUI

@main
struct SkateTrackApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("app.name")
                    .font(.largeTitle.bold())
                Text("app.tagline")
                    .font(.headline)
            }
            .padding()
        }
    }
}
