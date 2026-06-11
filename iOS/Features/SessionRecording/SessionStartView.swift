// [協作區] SessionStartView.swift
// 用途：呈現開始 Session 前的滿版主流程，包含 Home、運動類別、模式選擇與開始 CTA。
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
            return "skateTrack.inlineGlyph"
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
    static let green = Color(red: 0.063, green: 0.725, blue: 0.506)
    static let textSecondary = Color(red: 0.659, green: 0.698, blue: 0.800)
    static let textTertiary = Color(red: 0.420, green: 0.478, blue: 0.600)
    static let border = Color.white.opacity(0.08)
}

// MARK: - InlineSkateGlyphView（直排輪滑行人形圖示）
// 修正版：重畫為清晰的側面步伐姿勢，兩腳各有三顆輪子，左側速度線條。

struct InlineSkateGlyphView: View {
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width / 60, canvasSize.height / 64)
            let xOffset = (canvasSize.width - 60 * scale) / 2
            let yOffset = (canvasSize.height - 64 * scale) / 2

            context.translateBy(x: xOffset, y: yOffset)
            context.scaleBy(x: scale, y: scale)

            let lineRects: [(CGRect, Double)] = [
                (CGRect(x: 6.3, y: 33.3, width: 16.4, height: 2.3), 1.00),
                (CGRect(x: 6.3, y: 38.3, width: 14.8, height: 2.3), 0.92),
                (CGRect(x: 6.3, y: 43.4, width: 13.2, height: 2.3), 0.78)
            ]

            for (rect, opacity) in lineRects {
                context.fill(
                    Path(roundedRect: rect, cornerRadius: rect.height / 2),
                    with: .color(color.opacity(opacity))
                )
            }

            for contour in Self.figureContours {
                context.fill(Self.smoothClosedPath(contour), with: .color(color))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private static func smoothClosedPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 2 else { return path }

        let firstMidpoint = midpoint(points[0], points[1])
        path.move(to: firstMidpoint)

        for index in 1..<points.count {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            path.addQuadCurve(to: midpoint(current, next), control: current)
        }

        path.addQuadCurve(to: firstMidpoint, control: points[0])
        path.closeSubpath()
        return path
    }

    private static func midpoint(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        CGPoint(x: (lhs.x + rhs.x) / 2, y: (lhs.y + rhs.y) / 2)
    }

    private static let figureContours: [[CGPoint]] = [
        [CGPoint(x: 25.85, y: 15.73), CGPoint(x: 24.83, y: 26.99), CGPoint(x: 31.96, y: 19.01), CGPoint(x: 31.57, y: 28.95), CGPoint(x: 41.20, y: 36.46), CGPoint(x: 41.59, y: 41.55), CGPoint(x: 46.37, y: 41.00), CGPoint(x: 49.66, y: 37.01), CGPoint(x: 41.20, y: 28.56), CGPoint(x: 42.06, y: 23.55), CGPoint(x: 47.70, y: 27.62), CGPoint(x: 55.20, y: 24.96), CGPoint(x: 56.84, y: 22.14), CGPoint(x: 46.53, y: 22.14)],
        [CGPoint(x: 41.91, y: 2.58), CGPoint(x: 38.69, y: 4.85), CGPoint(x: 37.99, y: 9.00), CGPoint(x: 40.26, y: 11.89), CGPoint(x: 44.18, y: 12.60), CGPoint(x: 47.31, y: 10.25), CGPoint(x: 48.02, y: 6.65), CGPoint(x: 46.14, y: 3.60)],
        [CGPoint(x: 33.76, y: 34.82), CGPoint(x: 30.08, y: 33.33), CGPoint(x: 26.08, y: 42.48), CGPoint(x: 25.77, y: 46.71), CGPoint(x: 21.46, y: 47.26), CGPoint(x: 20.13, y: 49.21), CGPoint(x: 24.60, y: 49.76), CGPoint(x: 29.22, y: 45.93), CGPoint(x: 32.82, y: 40.37)],
        [CGPoint(x: 15.04, y: 51.48), CGPoint(x: 15.27, y: 53.05), CGPoint(x: 17.39, y: 53.99), CGPoint(x: 28.83, y: 54.77), CGPoint(x: 30.00, y: 53.28), CGPoint(x: 29.37, y: 51.56), CGPoint(x: 16.84, y: 50.39)],
        [CGPoint(x: 36.89, y: 42.33), CGPoint(x: 37.21, y: 44.36), CGPoint(x: 48.25, y: 50.78), CGPoint(x: 49.90, y: 49.92), CGPoint(x: 49.27, y: 47.49), CGPoint(x: 38.62, y: 41.47)],
        [CGPoint(x: 36.89, y: 45.93), CGPoint(x: 35.33, y: 46.71), CGPoint(x: 34.93, y: 48.35), CGPoint(x: 35.72, y: 49.68), CGPoint(x: 37.52, y: 50.07), CGPoint(x: 38.85, y: 48.90), CGPoint(x: 39.01, y: 47.49), CGPoint(x: 38.22, y: 46.32)],
        [CGPoint(x: 17.15, y: 55.08), CGPoint(x: 15.67, y: 56.10), CGPoint(x: 15.51, y: 57.58), CGPoint(x: 16.45, y: 58.91), CGPoint(x: 18.02, y: 59.15), CGPoint(x: 19.19, y: 58.29), CGPoint(x: 19.50, y: 56.57), CGPoint(x: 18.56, y: 55.32)],
        [CGPoint(x: 26.08, y: 56.25), CGPoint(x: 24.91, y: 57.27), CGPoint(x: 24.75, y: 58.52), CGPoint(x: 25.30, y: 59.54), CGPoint(x: 26.87, y: 60.01), CGPoint(x: 28.20, y: 59.15), CGPoint(x: 28.43, y: 57.74), CGPoint(x: 27.57, y: 56.49)],
        [CGPoint(x: 44.18, y: 51.01), CGPoint(x: 43.00, y: 51.87), CGPoint(x: 42.85, y: 53.28), CGPoint(x: 43.79, y: 54.53), CGPoint(x: 45.12, y: 54.69), CGPoint(x: 46.29, y: 53.83), CGPoint(x: 46.45, y: 52.42), CGPoint(x: 45.67, y: 51.25)]
    ]
}

// MARK: - SessionStartView

struct SessionStartView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @ObservedObject var sessionRecording: SessionRecordingViewModel
    private let rootNavigationAccessory: AnyView?

    @State private var selectedCategory: SessionStartSportCategory = .skateboard
    @State private var selectedBoardMode: BoardMode = .streetPark
    @State private var selectedInlineMode: InlineMode = .urbanFreestyle
    @State private var selectedPowerType: PowerType = .humanPowered
    @State private var upgradePromptFeature: GatedFeature?
    @State private var paywallFeature: GatedFeature?
    @State private var isHealthReminderSettingsPresented = false

    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        sessionRecording: SessionRecordingViewModel,
        rootNavigationAccessory: AnyView? = nil
    ) {
        self.subscriptionStatus = subscriptionStatus
        self.sessionRecording = sessionRecording
        self.rootNavigationAccessory = rootNavigationAccessory
    }

    var body: some View {
        GeometryReader { proxy in
            let topPadding = proxy.safeAreaInsets.top + (rootNavigationAccessory == nil ? 52 : 52)
            let bottomPadding = max(12, proxy.safeAreaInsets.bottom - 12)
            let horizontalPadding: CGFloat = 20
            let dockHeight: CGFloat = selectedModeLocked ? 126 : 96

            ZStack(alignment: .bottom) {
                fullScreenBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        homeHeader
                            .padding(.top, topPadding)

                        SportCategoryPickerView(selectedCategory: $selectedCategory)
                            .onChange(of: selectedCategory) { _, newCategory in
                                if newCategory == .inline {
                                    selectedPowerType = .humanPowered
                                }
                            }

                        previewMetricStrip

                        HealthReminderSettingsEntryCardView(
                            subscriptionStatus: subscriptionStatus,
                            onOpen: { isHealthReminderSettingsPresented = true }
                        )

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
                .scrollBounceBehavior(.basedOnSize)

                bottomDock(bottomPadding: bottomPadding, horizontalPadding: horizontalPadding)
            }
            .ignoresSafeArea()
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
        .onChange(of: subscriptionStatus.isSubscriber) { _, isSubscriber in
            if isSubscriber {
                upgradePromptFeature = nil
                paywallFeature = nil
            }
        }
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

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("app.name")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityIdentifier("session-start-app-name")

            if let rootNavigationAccessory {
                rootNavigationAccessory
                    .padding(.top, 2)
                    .padding(.bottom, 2)
                    .accessibilityIdentifier("session-start-root-navigation-accessory")
            }

            Text("home.greeting.morning")
                .tracking(2)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            Text("home.readyToSkate")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)

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
        .background(SkateTrackSessionStartColors.card.opacity(0.90))
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
                    showPaywall(for: feature)
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
