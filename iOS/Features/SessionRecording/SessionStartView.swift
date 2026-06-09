// [協作區] SessionStartView.swift
// 用途：呈現開始 Session 前的主流程，包含 Home、運動類別、模式選擇與開始 CTA。
// 委派至：Task-013 LiveHUDView 接收已開始的 session 狀態。

import SwiftUI

enum SessionStartSportCategory: String, CaseIterable, Identifiable {
    case skateboard
    case inline

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .skateboard:
            return "sport.skateboard"
        case .inline:
            return "sport.inline"
        }
    }

    var subtitleKey: String {
        switch self {
        case .skateboard:
            return "session.start.skateboard.subtitle"
        case .inline:
            return "session.start.inline.subtitle"
        }
    }

    var iconName: String {
        switch self {
        case .skateboard:
            return "figure.skateboarding"
        case .inline:
            return "figure.roll"
        }
    }

    var accentColor: Color {
        switch self {
        case .skateboard:
            return SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        }
    }
}

enum SkateTrackSessionStartColors {
    static let navy = Color(red: 0.051, green: 0.059, blue: 0.102)
    static let navy2 = Color(red: 0.078, green: 0.090, blue: 0.157)
    static let navy3 = Color(red: 0.110, green: 0.129, blue: 0.251)
    static let panel = Color(red: 0.102, green: 0.122, blue: 0.208)
    static let card = Color(red: 0.129, green: 0.157, blue: 0.267)
    static let accent = Color(red: 0.914, green: 0.271, blue: 0.376)
    static let accent2 = Color(red: 1.000, green: 0.420, blue: 0.420)
    static let teal = Color(red: 0.000, green: 0.831, blue: 0.667)
    static let amber = Color(red: 0.961, green: 0.651, blue: 0.137)
    static let purple = Color(red: 0.608, green: 0.361, blue: 0.965)
    static let blueCold = Color(red: 0.231, green: 0.510, blue: 0.965)
    static let textSecondary = Color(red: 0.659, green: 0.698, blue: 0.800)
    static let textTertiary = Color(red: 0.420, green: 0.478, blue: 0.600)
    static let border = Color.white.opacity(0.08)
}

struct SessionStartView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel

    @State private var selectedCategory: SessionStartSportCategory = .skateboard
    @State private var selectedBoardMode: BoardMode = .streetPark
    @State private var selectedInlineMode: InlineMode = .urbanFreestyle
    @State private var selectedPowerType: PowerType = .humanPowered
    @State private var upgradePromptFeature: GatedFeature?

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    homeHeader

                    SportCategoryPickerView(
                        selectedCategory: $selectedCategory
                    )
                    .onChange(of: selectedCategory) { _, newCategory in
                        if newCategory == .inline {
                            selectedPowerType = .humanPowered
                        }
                    }

                    previewMetricStrip
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

                    #if DEBUG
                    debugSection
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 128)
            }
        }
        .safeAreaInset(edge: .bottom) {
            StartSessionCTAView(
                status: sessionRecording.state.status,
                isLocked: selectedModeLocked,
                accentColor: selectedCategory.accentColor,
                onStart: startSelectedSession,
                onUnlock: showUpgradePrompt
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(bottomBarBackground)
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var backgroundLayer: some View {
        ZStack(alignment: .top) {
            SkateTrackSessionStartColors.navy2
                .ignoresSafeArea()

            RadialGradient(
                colors: [selectedCategory.accentColor.opacity(0.22), .clear],
                center: .top,
                startRadius: 12,
                endRadius: 280
            )
            .frame(height: 260)
            .ignoresSafeArea()
        }
    }

    private var bottomBarBackground: some View {
        LinearGradient(
            colors: [
                SkateTrackSessionStartColors.navy2.opacity(0.28),
                SkateTrackSessionStartColors.navy2.opacity(0.96),
                SkateTrackSessionStartColors.navy.opacity(0.98)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("app.name")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("session-start-app-name")

            Text("home.greeting.morning")
                .tracking(2)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            Text("home.readyToSkate")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.75)

            Text(LocalizedStringKey(sessionRecording.state.status.localizationKey))
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory.accentColor.opacity(0.16))
                .foregroundStyle(selectedCategory.accentColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selectedCategory.accentColor.opacity(0.28), lineWidth: 1))
                .accessibilityIdentifier("session-status-pill")
        }
        .accessibilityIdentifier("session-start-header")
    }

    private var previewMetricStrip: some View {
        HStack(spacing: 8) {
            quickStat(value: "0.0", label: "KM")
            quickStat(value: "—", label: "MAX")
            quickStat(value: "10Hz", label: "SENSOR")
        }
        .accessibilityIdentifier("session-start-preview-metrics")
    }

    private func quickStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)

            Text(label)
                .tracking(1)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(SkateTrackSessionStartColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
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
                    upgradePromptFeature = feature
                }
            )
        }
    }

    private var selectedSportMode: SportMode {
        switch selectedCategory {
        case .skateboard:
            return .skateboard(selectedBoardMode)
        case .inline:
            return .inline(selectedInlineMode)
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

        Task {
            await sessionRecording.actions.startSession(selectedSportMode, selectedPowerType)
        }
    }

    private func showUpgradePrompt() {
        upgradePromptFeature = selectedInlineMode.gatedFeature
    }

    private func upgradePrompt(for feature: GatedFeature) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("mode.locked.subscriberOnly")
                .font(.headline)
                .foregroundStyle(.white)
            Text(LocalizedStringKey(feature.localizationKey))
                .font(.subheadline)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Text("session.start.unlockToStart")
                .font(.footnote.weight(.medium))
                .foregroundStyle(selectedCategory.accentColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selectedCategory.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(selectedCategory.accentColor.opacity(0.24), lineWidth: 1)
        )
        .accessibilityIdentifier("session-start-upgrade-prompt")
    }

    #if DEBUG
    private var debugSection: some View {
        VStack(spacing: 12) {
            SubscriptionDebugPanel(subscriptionStatus: subscriptionStatus)
            SessionRecordingPreviewPanel(sessionRecording: sessionRecording)
        }
        .frame(maxWidth: 360)
        .padding(.top, 4)
    }
    #endif
}

#Preview("Free User") {
    SessionStartView(
        subscriptionStatus: useSubscriptionStatus(),
        sessionRecording: useSessionRecording(coordinator: .makeMockCoordinator())
    )
}
