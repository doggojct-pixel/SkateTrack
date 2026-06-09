// [協作區] RootNavigationView.swift
// 用途：集中管理 iOS 主要入口導航，將 Task-012 Session Start Flow 接到 App root。
// 委派至：iOS/Features/SessionRecording/SessionStartView.swift 呈現開始 Session 的主要 UI。

import SwiftUI

struct RootNavigationView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel

    var body: some View {
        NavigationStack {
            SessionStartView(
                subscriptionStatus: subscriptionStatus,
                sessionRecording: sessionRecording
            )
        }
    }
}

#Preview("Root Free") {
    RootNavigationView(
        subscriptionStatus: useSubscriptionStatus(),
        sessionRecording: useSessionRecording(coordinator: .makeMockCoordinator())
    )
}
