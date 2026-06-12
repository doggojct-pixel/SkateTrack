// [協作區] RootNavigationView.swift
// 用途：集中管理 iOS 主要入口導航，將 Task-012 Start Flow 與 Task-013 Live HUD 接到 App root。
// 委派至：SessionStartView 呈現開始流程，LiveHUDView 呈現記錄中的即時 HUD。

import SwiftUI

enum RootPrimaryScreen: String, CaseIterable, Identifiable {
    case ride
    case history
    case equipment
    case spots
    case achievements

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .ride:
            return "root.nav.ride"
        case .history:
            return "history.title"
        case .equipment:
            return "gear.title"
        case .spots:
            return "spots.title"
        case .achievements:
            return "achievements.title"
        }
    }
}

struct RootNavigationView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel
    @State private var selectedPrimaryScreen: RootPrimaryScreen = .ride
    @State private var isEquipmentDetailPresented = false
    @State private var isSpotDetailPresented = false
    @State private var pendingPostSessionStretchReminderEvent: HealthReminderEvent?
    @State private var postSessionStretchReminderTask: Task<Void, Never>?

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
                    #if DEBUG
                    LiveHUDView(
                        sessionRecording: sessionRecording,
                        subscriptionStatus: subscriptionStatus,
                        onOpenDebugTools: { debugRuntimeOptions.isDebugToolsPresented = true }
                    )
                    .id("live-hud")
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    #else
                    LiveHUDView(
                        sessionRecording: sessionRecording,
                        subscriptionStatus: subscriptionStatus
                    )
                    .id("live-hud")
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    #endif
                } else {
                    switch selectedPrimaryScreen {
                    case .ride:
                        SessionStartView(
                            subscriptionStatus: subscriptionStatus,
                            sessionRecording: sessionRecording,
                            rootNavigationAccessory: AnyView(rootPrimarySwitchControls),
                            onOpenAchievements: { selectedPrimaryScreen = .achievements }
                        )
                        .id("session-start")
                        .transition(.opacity)
                    case .history:
                        SessionHistoryView(subscriptionStatus: subscriptionStatus)
                            .id("session-history")
                            .transition(.opacity)
                    case .equipment:
                        EquipmentListView(
                            subscriptionStatus: subscriptionStatus,
                            isDetailPresented: $isEquipmentDetailPresented
                        )
                        .id("equipment-manager")
                        .transition(.opacity)
                    case .spots:
                        SpotListView(
                            subscriptionStatus: subscriptionStatus,
                            isDetailPresented: $isSpotDetailPresented
                        )
                        .id("spots")
                        .transition(.opacity)
                    case .achievements:
                        AchievementListView(
                            subscriptionStatus: subscriptionStatus,
                            onOpenHistory: { selectedPrimaryScreen = .history },
                            onOpenEquipment: { selectedPrimaryScreen = .equipment },
                            onOpenSpots: { selectedPrimaryScreen = .spots }
                        )
                        .id("achievements")
                        .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !shouldShowLiveHUD && selectedPrimaryScreen != .ride && !isEquipmentDetailPresented && !isSpotDetailPresented {
                rootPrimarySwitch
            }

            #if DEBUG
            if !shouldShowLiveHUD && !isEquipmentDetailPresented && !isSpotDetailPresented {
                debugToolsButton
            }
            #endif

            if let event = pendingPostSessionStretchReminderEvent, !shouldShowLiveHUD, selectedPrimaryScreen == .ride {
                postSessionStretchReminderOverlay(for: event)
                    .zIndex(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.24), value: sessionRecording.state.status)
        .animation(.easeInOut(duration: 0.20), value: selectedPrimaryScreen)
        .animation(.easeInOut(duration: 0.20), value: isEquipmentDetailPresented)
        .animation(.easeInOut(duration: 0.20), value: isSpotDetailPresented)
        .onChange(of: selectedPrimaryScreen) { _, newScreen in
            if newScreen != .equipment {
                isEquipmentDetailPresented = false
            }
            if newScreen != .spots {
                isSpotDetailPresented = false
            }
        }
        .onChange(of: sessionRecording.state.status) { oldStatus, newStatus in
            handleSessionStatusChange(from: oldStatus, to: newStatus)
        }
        .onChange(of: subscriptionStatus.isSubscriber) { _, _ in
            if subscriptionStatus.hasAccess(to: .healthReminders) == false {
                cancelPostSessionStretchReminder(clearEvent: true)
            }
        }
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
        selectedPrimaryScreen == .ride ? 58 : 20
    }

    private var rootPrimarySwitchControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
        (!shouldShowLiveHUD && selectedPrimaryScreen != .ride) ? rootPrimarySwitchTopPadding : 58
    }

    private func handleSessionStatusChange(from oldStatus: SessionRecordingStatus, to newStatus: SessionRecordingStatus) {
        if isLiveSessionStatus(newStatus) {
            cancelPostSessionStretchReminder(clearEvent: true)
            return
        }

        if newStatus == .idle, isLiveSessionStatus(oldStatus) {
            schedulePostSessionStretchReminderIfNeeded()
        } else if newStatus == .failed {
            cancelPostSessionStretchReminder(clearEvent: true)
        }
    }

    private func isLiveSessionStatus(_ status: SessionRecordingStatus) -> Bool {
        switch status {
        case .preparing, .recording, .paused, .ending, .saving:
            return true
        case .idle, .failed:
            return false
        }
    }

    private func schedulePostSessionStretchReminderIfNeeded() {
        cancelPostSessionStretchReminder(clearEvent: true)

        guard subscriptionStatus.hasAccess(to: .healthReminders) else { return }

        let rule = HealthReminderSettingsStore.shared.settings.rule(for: .cooldownStretch)
        guard rule.isEnabled,
              let intervalMinutes = rule.intervalMinutes else {
            return
        }

        let delaySeconds = UInt64(max(1, intervalMinutes) * 60)
        postSessionStretchReminderTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            guard Task.isCancelled == false else { return }
            guard sessionRecording.state.status == .idle else { return }
            guard subscriptionStatus.hasAccess(to: .healthReminders) else { return }

            let latestRule = HealthReminderSettingsStore.shared.settings.rule(for: .cooldownStretch)
            guard latestRule.isEnabled else { return }

            pendingPostSessionStretchReminderEvent = HealthReminderEvent(
                kind: .cooldownStretch,
                activeElapsedTime: 0
            )
        }
    }

    private func dismissPostSessionStretchReminder() {
        cancelPostSessionStretchReminder(clearEvent: true)
    }

    private func postSessionStretchReminderOverlay(for event: HealthReminderEvent) -> some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack {
                Spacer(minLength: 0)

                HealthReminderBannerView(
                    event: event,
                    onDismiss: dismissPostSessionStretchReminder
                )
                .padding(.horizontal, 22)
                .frame(maxWidth: 430)

                Spacer(minLength: 0)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .accessibilityIdentifier("post-session-stretch-reminder-overlay")
    }

    private func cancelPostSessionStretchReminder(clearEvent: Bool) {
        postSessionStretchReminderTask?.cancel()
        postSessionStretchReminderTask = nil
        if clearEvent {
            pendingPostSessionStretchReminderEvent = nil
        }
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
