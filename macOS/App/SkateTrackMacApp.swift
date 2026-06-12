// [協作區] SkateTrackMacApp.swift
// 用途：定義 SkateTrack macOS App 入口點，載入獨立 macOS shell。
// 委派至：macOS/App/MacRootView 與 macOS/Features；macOS 導覽結構需獨立於 iOS。

import SwiftUI

@main
struct SkateTrackMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacRootView()
        }
    }
}
