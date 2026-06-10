// [協作區] LiveHUDView.swift
// 用途：呈現騎乘中的滿版 Live HUD、即時指標、迷你路線與滑動結束控制。
// 委派至：useSessionRecording 提供狀態與 actions；FallDetectionOverlayPresenter 顯示安全警示。

import Foundation
import SwiftUI

struct LiveHUDView: View {
    @ObservedObject var sessionRecording: SessionRecordingViewModel
    @StateObject private var fallDetection = useFallDetection()
    @State private var speedTraceSamples: [LiveSpeedTraceSample] = []

    private let speedTraceTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let topPadding = proxy.safeAreaInsets.top + 44
            let bottomPadding = max(12, proxy.safeAreaInsets.bottom - 12)
            let horizontalPadding: CGFloat = 20
            let dockHeight: CGFloat = 96

            ZStack(alignment: .bottom) {
                liveBackground
                    .ignoresSafeArea()

                ScrollViewReader { reader in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            Color.clear
                                .frame(height: 0)
                                .id("live-hud-top")

                            topBar
                                .padding(.top, topPadding)

                            speedHero
                            metricGrid
                            lowerMetrics

                            if isInlineMode {
                                InlineLiveMetricsView(accentColor: accentColor)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, dockHeight + bottomPadding)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .frame(minHeight: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
                               alignment: .top)
                    }
                    .ignoresSafeArea()
                    .scrollBounceBehavior(.basedOnSize)
                    .onAppear {
                        reader.scrollTo("live-hud-top", anchor: .top)
                    }
                    .onChange(of: sessionRecording.state.status) { _, status in
                        if status == .preparing || status == .recording {
                            reader.scrollTo("live-hud-top", anchor: .top)
                        }
                    }
                }

                controlDock(bottomPadding: bottomPadding, horizontalPadding: horizontalPadding)

                FallDetectionOverlayPresenter(
                    state: fallDetection.state,
                    actions: fallDetection.actions
                )
                .animation(.easeInOut(duration: 0.22), value: fallDetection.state.activeFallEvent)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .background(SkateTrackSessionStartColors.navy)
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("live-hud-view")
        .onReceive(speedTraceTimer) { _ in
            appendSpeedTraceSampleIfNeeded()
        }
        .onChange(of: sessionRecording.state.status) { _, status in
            if status == .idle || status == .failed {
                speedTraceSamples.removeAll(keepingCapacity: true)
            } else if status == .recording {
                appendSpeedTraceSampleIfNeeded()
            }
        }
    }

    private var liveBackground: some View {
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

            motionGrid
                .opacity(0.18)
                .allowsHitTesting(false)

            RadialGradient(
                colors: [accentColor.opacity(0.28), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        }
    }


    private var motionGrid: some View {
        Canvas { context, size in
            let spacing: CGFloat = 28
            let dotSize: CGFloat = 2.4
            var y: CGFloat = 0
            while y <= size.height {
                var x: CGFloat = 0
                while x <= size.width {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.08)))
                    x += spacing
                }
                y += spacing
            }
        }
    }

    private func controlDock(bottomPadding: CGFloat, horizontalPadding: CGFloat) -> some View {
        HStack(spacing: 10) {
            pauseResumeButton
            SlideToEndSessionControl(
                accentColor: accentColor,
                isDisabled: !canControlActiveSession,
                onEnd: endSession
            )
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 18)
        .padding(.bottom, bottomPadding)
        .frame(maxWidth: .infinity)
        .background(controlDockBackground)
        .accessibilityIdentifier("live-hud-control-dock")
    }

    private var controlDockBackground: some View {
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

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 8, height: 8)
                Text(LocalizedStringKey(modeLocalizationKey))
                    .lineLimit(1)
                Text("·")
                Text(LocalizedStringKey(sessionRecording.state.status.localizationKey))
                    .lineLimit(1)
            }
            .tracking(1.1)
            .font(.system(size: 11, weight: .heavy, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(accentColor.opacity(0.88))
            .clipShape(Capsule())
            .accessibilityIdentifier("live-hud-status-badge")

            Spacer()

            Button(action: fallDetection.actions.triggerManualSOS) {
                Text("session.hud.sos")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(SkateTrackSessionStartColors.accent2.opacity(0.88))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("live-hud-sos-button")

            #if DEBUG
            debugSimulateFallButton
            #endif
        }
    }


    #if DEBUG
    private var debugSimulateFallButton: some View {
        Button(action: fallDetection.actions.simulateFallAlert) {
            Text("FALL")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.amber)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(SkateTrackSessionStartColors.amber.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(SkateTrackSessionStartColors.amber.opacity(0.42), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Simulate Fall Alert")
        .accessibilityIdentifier("debug-simulate-fall-button")
    }
    #endif

    private var speedHero: some View {
        VStack(spacing: 14) {
            ZStack {
                LiveSpeedTraceView(
                    samples: speedTraceSamples,
                    maxSpeedKilometersPerHour: max(
                        sessionRecording.state.maxSpeedKilometersPerHour,
                        sessionRecording.state.currentSpeedKilometersPerHour
                    ),
                    accentColor: accentColor
                )
                .frame(height: 172)
                .padding(.horizontal, 2)
                .allowsHitTesting(false)

                LiveSpeedDisplayView(
                    speedKilometersPerHour: sessionRecording.state.currentSpeedKilometersPerHour,
                    maxSpeedKilometersPerHour: sessionRecording.state.maxSpeedKilometersPerHour,
                    accentColor: accentColor
                )
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 184)
            .accessibilityIdentifier("live-hud-speed-trace-area")

            Text(LocalizedStringKey(modeLocalizationKey))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(accentColor.opacity(0.16))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(accentColor.opacity(0.26), lineWidth: 1))
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("live-hud-speed-hero")
    }

    private var metricGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                LiveHUDMetricCardView(
                    value: formattedDistance,
                    labelKey: "session.hud.distance",
                    tintColor: SkateTrackSessionStartColors.teal,
                    accessibilityID: "live-hud-distance"
                )
                LiveHUDMetricCardView(
                    value: formattedElapsedTime,
                    labelKey: "session.hud.time",
                    tintColor: SkateTrackSessionStartColors.amber,
                    accessibilityID: "live-hud-time"
                )
            }

            HStack(spacing: 10) {
                TiltIndicatorView(
                    tiltDegrees: sessionRecording.state.currentTiltDegrees,
                    accentColor: SkateTrackSessionStartColors.blueCold
                )
                LiveHUDMetricCardView(
                    value: "--",
                    labelKey: "session.hud.tricks",
                    tintColor: SkateTrackSessionStartColors.accent,
                    accessibilityID: "live-hud-tricks"
                )
            }
        }
    }

    private var lowerMetrics: some View {
        HStack(spacing: 10) {
            heartRateCard
            modeChip
        }
    }

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("--")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(accentColor)
            Text("session.hud.heartRate")
                .tracking(1.2)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
        }
        .frame(width: 88, alignment: .leading)
        .padding(12)
        .background(SkateTrackSessionStartColors.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("live-hud-heart-rate")
    }

    @ViewBuilder
    private var liveModeIcon: some View {
        if isInlineMode {
            InlineSkateGlyphView(color: accentColor, size: 24)
        } else {
            Image(systemName: "figure.skateboarding")
                .foregroundStyle(accentColor)
        }
    }

    private var modeChip: some View {
        HStack(spacing: 8) {
            liveModeIcon
            Text(LocalizedStringKey(sessionRecording.state.selectedSportMode?.modeLocalizationKey ?? "session.hud.noMode"))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(accentColor.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(accentColor.opacity(0.24), lineWidth: 1))
        .accessibilityIdentifier("live-hud-mode-chip")
    }

    private var pauseResumeButton: some View {
        Button(action: pauseOrResume) {
            Image(systemName: sessionRecording.state.status == .paused ? "play.fill" : "pause.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(SkateTrackSessionStartColors.card.opacity(canControlActiveSession ? 1.0 : 0.48))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!canControlActiveSession)
        .accessibilityIdentifier("live-hud-pause-resume")
    }

    private var canControlActiveSession: Bool {
        sessionRecording.state.status == .recording || sessionRecording.state.status == .paused
    }

    private var accentColor: Color {
        guard let mode = sessionRecording.state.selectedSportMode else {
            return SkateTrackSessionStartColors.accent
        }
        switch mode {
        case .skateboard:
            return SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        }
    }

    private var isInlineMode: Bool {
        if case .inline = sessionRecording.state.selectedSportMode { return true }
        return false
    }

    private var statusDotColor: Color {
        sessionRecording.state.status == .paused ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal
    }

    private var modeLocalizationKey: String {
        sessionRecording.state.selectedSportMode?.modeLocalizationKey ?? "session.hud.noMode"
    }

    private var formattedDistance: String {
        String(format: "%.1f", sessionRecording.state.distanceKilometers)
    }

    private var formattedElapsedTime: String {
        let totalSeconds = max(0, Int(sessionRecording.state.elapsedTime.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func appendSpeedTraceSampleIfNeeded() {
        guard sessionRecording.state.status == .recording else { return }

        let elapsedTime = max(0, sessionRecording.state.elapsedTime)
        let speed = max(0, sessionRecording.state.currentSpeedKilometersPerHour)

        if let last = speedTraceSamples.last, elapsedTime <= last.elapsedTime + 0.25 {
            return
        }

        speedTraceSamples.append(
            LiveSpeedTraceSample(
                elapsedTime: elapsedTime,
                speedKilometersPerHour: speed
            )
        )

        if speedTraceSamples.count > 90 {
            speedTraceSamples.removeFirst(speedTraceSamples.count - 90)
        }
    }

    private func pauseOrResume() {
        Task {
            if sessionRecording.state.status == .paused {
                await sessionRecording.actions.resumeSession()
            } else {
                await sessionRecording.actions.pauseSession()
            }
        }
    }

    private func endSession() {
        Task {
            await sessionRecording.actions.requestEndSession()
        }
    }

}

#Preview("Live HUD Mock") {
    LiveHUDView(sessionRecording: useSessionRecording(coordinator: .makeMockCoordinator()))
}
