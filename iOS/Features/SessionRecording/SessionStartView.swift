// [協作區] SessionStartView.swift
// 用途：呈現開始 Session 前的滿版主流程，包含 Home、運動類別、模式選擇與開始 CTA。
// 委派至：Task-013 LiveHUDView 接收已開始的 session 狀態。

import SwiftUI

struct SessionStartView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel
    private let rootNavigationAccessory: AnyView?
    private let onOpenAchievements: () -> Void

    @State private var selectedCategory: SessionStartSportCategory = .skateboard
    @State private var selectedBoardMode: BoardMode = .streetPark
    @State private var selectedInlineMode: InlineMode = .urbanFreestyle
    @State private var selectedSnowDiscipline: SnowDiscipline = .snowboard
    @State private var selectedPowerType: PowerType = .humanPowered
    @State private var upgradePromptFeature: GatedFeature?
    @State private var paywallFeature: GatedFeature?
    @State private var isHealthReminderSettingsPresented = false
    @State private var selectedEquipmentID: UUID?
    @State private var selectedSpotID: UUID?
    @StateObject private var weatherRisk: WeatherRiskViewModel
    @StateObject private var equipmentManager: EquipmentManagerViewModel
    @StateObject private var spotsManager: SpotsViewModel
    @StateObject private var achievementDashboard: AchievementDashboardViewModel
    @State private var scrollOffset: CGFloat = 0
    @State private var navigationRowMinY: CGFloat = .greatestFiniteMagnitude

    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        sessionRecording: SessionRecordingViewModel,
        rootNavigationAccessory: AnyView? = nil,
        onOpenAchievements: @escaping () -> Void = {}
    ) {
        self.subscriptionStatus = subscriptionStatus
        self.sessionRecording = sessionRecording
        self.rootNavigationAccessory = rootNavigationAccessory
        self.onOpenAchievements = onOpenAchievements
        _weatherRisk = StateObject(
            wrappedValue: useWeatherRisk(subscriptionStatus: subscriptionStatus)
        )
        _equipmentManager = StateObject(
            wrappedValue: useEquipmentManager(subscriptionStatus: subscriptionStatus)
        )
        _spotsManager = StateObject(
            wrappedValue: useSpots(subscriptionStatus: subscriptionStatus)
        )
        _achievementDashboard = StateObject(
            wrappedValue: useAchievementDashboard(subscriptionStatus: subscriptionStatus)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let safeTopInset = proxy.safeAreaInsets.top
            let stickyTopInset = max(
                safeTopInset,
                SessionStartScrollMetrics.minimumStickyNavigationTopInset
            )
            let topPadding = safeTopInset + (rootNavigationAccessory == nil ? 52 : 52)
            let bottomPadding = max(12, proxy.safeAreaInsets.bottom - 12)
            let horizontalPadding: CGFloat = 20
            let dockHeight: CGFloat = selectedModeLocked ? 126 : 96

            ZStack(alignment: .bottom) {
                fullScreenBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    scrollOffsetReader

                    VStack(alignment: .leading, spacing: 16) {
                        SessionStartHeaderView(
                            selectedCategory: selectedCategory,
                            statusLocalizationKey: sessionRecording.state.status.localizationKey,
                            rootNavigationAccessory: rootNavigationAccessory
                        )
                        .padding(.top, topPadding)

                        SportCategoryPickerView(selectedCategory: $selectedCategory)
                            .onChange(of: selectedCategory) { _, newCategory in
                                if newCategory == .inline || newCategory == .snow {
                                    selectedPowerType = .humanPowered
                                }
                                clearIncompatibleSelectedEquipment()
                            }

                        SessionEquipmentPickerView(
                            equipment: equipmentManager.equipment,
                            selectedSportMode: selectedSportMode,
                            selectedPowerType: selectedPowerType,
                            hasAccess: equipmentManager.hasManagementAccess,
                            selectedEquipmentID: $selectedEquipmentID,
                            onUnlock: { showPaywall(for: .equipmentManager) }
                        )

                        SessionSpotPickerView(
                            spots: spotsManager.spots,
                            selectedSpotID: $selectedSpotID
                        )

                        SessionStartPreviewMetricStripView()

                        SessionStartAchievementDashboardCardView(
                            dashboard: achievementDashboard,
                            onOpenAchievements: onOpenAchievements
                        )

                        SessionStartWeatherSectionView(
                            weatherRisk: weatherRisk,
                            selectedSportMode: selectedSportMode,
                            selectedSpot: selectedSpotForSession,
                            onOpenHealthReminders: { isHealthReminderSettingsPresented = true }
                        )

                        HealthReminderSettingsEntryCardView(
                            subscriptionStatus: subscriptionStatus,
                            onOpen: { isHealthReminderSettingsPresented = true }
                        )

                        realDeviceRecordingNotice

                        modeSelector

                        if selectedCategory == .skateboard {
                            PowerTypeToggleView(
                                selectedPowerType: $selectedPowerType,
                                accentColor: selectedCategory.accentColor
                            )
                        }

                        if let errorKey = sessionRecording.state.errorMessageKey {
                            Text(LocalizedStringKey(errorKey))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(SkateTrackSessionStartColors.accent2)
                                .accessibilityIdentifier("session-start-error")
                        }

                        if let upgradePromptFeature {
                            upgradePrompt(for: upgradePromptFeature)
                        }

                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, dockHeight + bottomPadding)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
                           alignment: .topLeading)
                }
                .ignoresSafeArea()
                .coordinateSpace(name: SessionStartScrollMetrics.coordinateSpaceName)
                .scrollBounceBehavior(.basedOnSize)
                .onPreferenceChange(SessionStartScrollOffsetPreferenceKey.self) { newValue in
                    guard abs(scrollOffset - newValue) > 0.5 else { return }
                    scrollOffset = newValue
                }
                .onPreferenceChange(SessionStartNavigationPositionPreferenceKey.self) { newValue in
                    guard abs(navigationRowMinY - newValue) > 0.5 else { return }
                    navigationRowMinY = newValue
                }

                if let rootNavigationAccessory {
                    SessionStartStickyRootNavigationView(
                        rootNavigationAccessory: rootNavigationAccessory,
                        topInset: stickyTopInset,
                        navigationRowMinY: navigationRowMinY,
                        isMeasured: navigationRowMinY < .greatestFiniteMagnitude,
                        isPinned: shouldShowStickyRootNavigation(topInset: stickyTopInset)
                    )
                    .zIndex(8)
                }

                bottomDock(bottomPadding: bottomPadding, horizontalPadding: horizontalPadding)
            }
            .ignoresSafeArea()
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .background(SkateTrackSessionStartColors.navy)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $paywallFeature) { feature in
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: feature
            )
        }
        .sheet(isPresented: $isHealthReminderSettingsPresented) {
            HealthReminderSettingsView(subscriptionStatus: subscriptionStatus)
        }
        .task {
            await equipmentManager.refresh()
            await spotsManager.refresh()
            await achievementDashboard.reload()
            clearIncompatibleSelectedEquipment()
            clearUnavailableSelectedSpot()
        }
        .onChange(of: subscriptionStatus.isSubscriber) { _, isSubscriber in
            if isSubscriber {
                upgradePromptFeature = nil
                paywallFeature = nil
            } else {
                selectedEquipmentID = nil
            }
            Task {
                await equipmentManager.refresh()
                await spotsManager.refresh()
                await achievementDashboard.reload()
                clearIncompatibleSelectedEquipment()
                clearUnavailableSelectedSpot()
            }
        }
        .onChange(of: selectedBoardMode) { _, _ in clearIncompatibleSelectedEquipment() }
        .onChange(of: selectedInlineMode) { _, _ in clearIncompatibleSelectedEquipment() }
        .onChange(of: selectedSnowDiscipline) { _, _ in clearIncompatibleSelectedEquipment() }
        .onChange(of: selectedPowerType) { _, _ in clearIncompatibleSelectedEquipment() }
        .onChange(of: equipmentManager.equipment) { _, _ in clearIncompatibleSelectedEquipment() }
        .onChange(of: spotsManager.spots) { _, _ in clearUnavailableSelectedSpot() }
    }

    private func shouldShowStickyRootNavigation(topInset: CGFloat) -> Bool {
        let activationY = topInset + SessionStartScrollMetrics.stickyNavigationActivationPadding
        let hasMeasuredNavigation = navigationRowMinY < .greatestFiniteMagnitude
        return (hasMeasuredNavigation && navigationRowMinY <= activationY)
            || scrollOffset < SessionStartScrollMetrics.stickyNavigationFallbackThreshold
    }

    private var scrollOffsetReader: some View {
        GeometryReader { scrollProxy in
            Color.clear.preference(
                key: SessionStartScrollOffsetPreferenceKey.self,
                value: scrollProxy.frame(in: .named(SessionStartScrollMetrics.coordinateSpaceName)).minY
            )
        }
        .frame(height: 0)
        .accessibilityHidden(true)
    }

    private var fullScreenBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3,
                    SkateTrackSessionStartColors.navy2,
                    SkateTrackSessionStartColors.navy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [selectedCategory.accentColor.opacity(0.34), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )

            RadialGradient(
                colors: [selectedCategory.accentColor.opacity(0.18), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 520
            )
        }
    }


    private var realDeviceRecordingNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)

                Text("session.start.backgroundRecording.title")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("session.start.backgroundRecording.detail")
                .font(.footnote.weight(.medium))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkateTrackSessionStartColors.card.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.teal.opacity(0.28), lineWidth: 1))
        .accessibilityIdentifier("session-start-background-recording-notice")
    }

    private func bottomDock(bottomPadding: CGFloat, horizontalPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            bottomCTA
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, bottomPadding)
        }
        .frame(maxWidth: .infinity)
        .background(bottomBarBackground)
        .accessibilityIdentifier("session-start-bottom-dock")
    }

    private var bottomBarBackground: some View {
        LinearGradient(
            colors: [
                SkateTrackSessionStartColors.navy.opacity(0.0),
                SkateTrackSessionStartColors.navy.opacity(0.88),
                SkateTrackSessionStartColors.navy.opacity(1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .bottom)
    }

    private var bottomCTA: some View {
        StartSessionCTAView(
            status: sessionRecording.state.status,
            isLocked: selectedModeLocked,
            accentColor: selectedCategory.accentColor,
            onStart: startSelectedSession,
            onUnlock: showUpgradePrompt
        )
    }

    @ViewBuilder
    private var modeSelector: some View {
        switch selectedCategory {
        case .skateboard:
            BoardModeSelectorView(
                selectedMode: $selectedBoardMode,
                accentColor: selectedCategory.accentColor
            )
        case .inline:
            InlineModeSelectorView(
                selectedMode: $selectedInlineMode,
                subscriptionStatus: subscriptionStatus,
                accentColor: selectedCategory.accentColor,
                onLockedModeTap: { feature in
                    showPaywall(for: feature)
                }
            )
        case .snow:
            SnowDisciplineSelectorView(
                selectedDiscipline: $selectedSnowDiscipline,
                accentColor: selectedCategory.accentColor
            )
        }
    }

    private var selectedSportMode: SportMode {
        switch selectedCategory {
        case .skateboard:
            return .skateboard(selectedBoardMode)
        case .inline:
            return .inline(selectedInlineMode)
        case .snow:
            return .snow(selectedSnowDiscipline)
        }
    }

    private var selectedModeLocked: Bool {
        guard let feature = selectedInlineMode.gatedFeature, selectedCategory == .inline else {
            return false
        }
        return !subscriptionStatus.hasAccess(to: feature)
    }

    private func startSelectedSession() {
        guard !selectedModeLocked else {
            showUpgradePrompt()
            return
        }
        let equipment = selectedEquipmentForSession
        let spot = selectedSpotForSession
        Task {
            await sessionRecording.actions.startSession(
                selectedSportMode,
                selectedPowerType,
                equipment?.id,
                equipment.map { EquipmentSessionSnapshot(equipment: $0) },
                spot?.id,
                spot.map { SpotSessionSnapshot(spot: $0) }
            )
        }
    }

    private var selectedEquipmentForSession: EquipmentProfile? {
        guard equipmentManager.hasManagementAccess, let selectedEquipmentID else { return nil }
        return equipmentManager.equipment.first {
            $0.id == selectedEquipmentID && $0.isCompatible(with: selectedSportMode, powerType: selectedPowerType)
        }
    }

    private func clearIncompatibleSelectedEquipment() {
        guard selectedEquipmentForSession?.id != selectedEquipmentID else { return }
        selectedEquipmentID = nil
    }

    private var selectedSpotForSession: SpotProfile? {
        guard let selectedSpotID else { return nil }
        return spotsManager.spots.first { $0.id == selectedSpotID }
    }

    private func clearUnavailableSelectedSpot() {
        guard selectedSpotForSession?.id != selectedSpotID else { return }
        selectedSpotID = nil
    }

    private func showUpgradePrompt() {
        guard let feature = selectedInlineMode.gatedFeature else { return }
        showPaywall(for: feature)
    }

    private func showPaywall(for feature: GatedFeature) {
        upgradePromptFeature = feature
        paywallFeature = feature
    }

    private func upgradePrompt(for feature: GatedFeature) -> some View {
        LockedFeatureOverlayView(
            feature: feature,
            accentColor: selectedCategory.accentColor,
            onUnlock: { showPaywall(for: feature) }
        )
        .accessibilityIdentifier("session-start-upgrade-prompt")
    }
}

#Preview("Free User") {
    SessionStartView(
        subscriptionStatus: useSubscriptionStatus(),
        sessionRecording: useSessionRecording(coordinator: .makeMockCoordinator())
    )
}
