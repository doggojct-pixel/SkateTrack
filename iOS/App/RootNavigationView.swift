// [協作區] RootNavigationView.swift
// 用途：集中管理 iOS 主要入口導航，將 Task-012 Start Flow 與 Task-013 Live HUD 接到 App root。
// 委派至：SessionStartView 呈現開始流程，LiveHUDView 呈現記錄中的即時 HUD。

import SwiftUI

struct RootNavigationView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel

    #if DEBUG
    @StateObject private var debugFallDetection = useFallDetection()
    @StateObject private var debugRuntimeOptions = DebugRuntimeOptions.shared
    #endif

    var body: some View {
        ZStack {
            SkateTrackSessionStartColors.navy
                .ignoresSafeArea()

            Group {
                if shouldShowLiveHUD {
                    LiveHUDView(sessionRecording: sessionRecording)
                        .id("live-hud")
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    SessionStartView(
                        subscriptionStatus: subscriptionStatus,
                        sessionRecording: sessionRecording
                    )
                    .id("session-start")
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            #if DEBUG
            debugToolsButton
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.24), value: sessionRecording.state.status)
        .preferredColorScheme(.dark)
        #if DEBUG
        .sheet(isPresented: $debugRuntimeOptions.isDebugToolsPresented) {
            DebugToolsPanelView(
                subscriptionStatus: subscriptionStatus,
                sessionRecording: sessionRecording,
                fallDetection: debugFallDetection,
                emergencyContactStore: .shared
            )
        }
        #endif
    }

    #if DEBUG
    private var debugToolsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    debugRuntimeOptions.isDebugToolsPresented = true
                } label: {
                    Text("DEV")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.amber)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(SkateTrackSessionStartColors.card.opacity(0.82))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(SkateTrackSessionStartColors.amber.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Debug Tools")
                .accessibilityIdentifier(DebugToolAction.openPanel.accessibilityIdentifier)
            }
            .padding(.top, 58)
            .padding(.trailing, 16)
            Spacer()
        }
        .allowsHitTesting(true)
    }
    #endif

    private var shouldShowLiveHUD: Bool {
        switch sessionRecording.state.status {
        case .preparing, .recording, .paused, .ending, .saving:
            return true
        case .idle, .failed:
            return false
        }
    }
}

#Preview("Root Free") {
    RootNavigationView(
        subscriptionStatus: useSubscriptionStatus(),
        sessionRecording: useSessionRecording(coordinator: .makeMockCoordinator())
    )
}
