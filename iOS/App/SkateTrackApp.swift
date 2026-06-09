// [協作區] SkateTrackApp.swift
// 用途：定義 SkateTrack iOS App 入口點，並用本地化鍵值顯示目前任務驗證用空殼畫面。
// 委派至：iOS/Hooks/useSubscriptionStatus.swift 提供 DEBUG 訂閱狀態切換。

import SwiftUI

@main
struct SkateTrackApp: App {
    @StateObject private var subscriptionStatus = useSubscriptionStatus()

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("app.name")
                        .font(.largeTitle.bold())
                    Text("app.tagline")
                        .font(.headline)
                }

                #if DEBUG
                SubscriptionDebugPanel(subscriptionStatus: subscriptionStatus)
                    .frame(maxWidth: 320)
                #endif
            }
            .padding()
        }
    }
}
