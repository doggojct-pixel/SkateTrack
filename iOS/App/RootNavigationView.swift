// [協作區] RootNavigationView.swift
// 用途：集中管理 iOS 主要入口導航，將 Task-012 Start Flow 與 Task-013 Live HUD 接到 App root。
// 委派至：SessionStartView 呈現開始流程，LiveHUDView 呈現記錄中的即時 HUD。

import SwiftUI

enum RootPrimaryScreen: String, CaseIterable, Identifiable {
    case ride
    case history

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .ride:
            return "root.nav.ride"
        case .history:
            return "history.title"
        }
    }
}

struct RootNavigationView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel
    @State private var selectedPrimaryScreen: RootPrimaryScreen = .ride

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
                    switch selectedPrimaryScreen {
                    case .ride:
                        SessionStartView(
                            subscriptionStatus: subscriptionStatus,
                            sessionRecording: sessionRecording,
                            rootNavigationAccessory: AnyView(rootPrimarySwitchControls)
                        )
                        .id("session-start")
                        .transition(.opacity)
                    case .history:
                        SessionHistoryView(subscriptionStatus: subscriptionStatus)
                            .id("session-history")
                            .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !shouldShowLiveHUD && selectedPrimaryScreen == .history {
                rootPrimarySwitch
            }

            #if DEBUG
            debugToolsButton
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.24), value: sessionRecording.state.status)
        .animation(.easeInOut(duration: 0.20), value: selectedPrimaryScreen)
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


    private var rootPrimarySwitch: some View {
        VStack {
            rootPrimarySwitchControls
                .padding(.top, rootPrimarySwitchTopPadding)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .allowsHitTesting(true)
        .accessibilityIdentifier("root-primary-switch")
    }

    private var rootPrimarySwitchTopPadding: CGFloat {
        selectedPrimaryScreen == .history ? 20 : 58
    }

    private var rootPrimarySwitchControls: some View {
        HStack(spacing: 8) {
            ForEach(RootPrimaryScreen.allCases) { screen in
                Button {
                    selectedPrimaryScreen = screen
                } label: {
                    Text(LocalizedStringKey(screen.localizationKey))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(selectedPrimaryScreen == screen ? .white : SkateTrackSessionStartColors.textSecondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(rootPrimarySwitchBackground(for: screen))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedPrimaryScreen == screen ? SkateTrackSessionStartColors.teal.opacity(0.52) : SkateTrackSessionStartColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("root-nav-\(screen.rawValue)")
            }
        }
        .accessibilityIdentifier("root-primary-switch-controls")
    }

    private func rootPrimarySwitchBackground(for screen: RootPrimaryScreen) -> Color {
        selectedPrimaryScreen == screen
            ? SkateTrackSessionStartColors.teal.opacity(0.28)
            : SkateTrackSessionStartColors.card.opacity(0.82)
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
            .padding(.top, debugToolsTopPadding)
            .padding(.trailing, 16)
            Spacer()
        }
        .allowsHitTesting(true)
    }
    #endif

    private var debugToolsTopPadding: CGFloat {
        (!shouldShowLiveHUD && selectedPrimaryScreen == .history) ? rootPrimarySwitchTopPadding : 58
    }

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
