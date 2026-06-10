// [協作區] SkateTrackApp.swift
// 用途：定義 SkateTrack iOS App 入口點，並把 root 導航交給 Task-012 Session Start Flow。
// 委派至：RootNavigationView.swift 管理 iOS 主入口與 SessionRecording / Subscription hooks。

import SwiftUI

@main
struct SkateTrackApp: App {
    @StateObject private var subscriptionStatus = useSubscriptionStatus()
    @StateObject private var sessionRecording = SkateTrackAppDependencies.makeSessionRecordingViewModel()

    var body: some Scene {
        WindowGroup {
            RootNavigationView(
                subscriptionStatus: subscriptionStatus,
                sessionRecording: sessionRecording
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
        }
    }

}

enum SkateTrackAppDependencies {
    @MainActor
    static func makeSessionRecordingViewModel() -> SessionRecordingViewModel {
        #if DEBUG
        return useSessionRecording(coordinator: .makeMockCoordinator())
        #else
        return useSessionRecording()
        #endif
    }
}
