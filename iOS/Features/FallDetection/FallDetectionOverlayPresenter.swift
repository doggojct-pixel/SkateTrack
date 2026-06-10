// [協作區] iOS/Features/FallDetection/FallDetectionOverlayPresenter.swift
// 用途：將 Fall Alert 高優先 overlay 疊到 Live HUD 上，不把 UI 寫回感測器引擎。
// 委派至：LiveHUDView 提供畫面掛載點。

import SwiftUI

struct FallDetectionOverlayPresenter: View {
    let state: FallDetectionAlertState
    let actions: FallDetectionActions

    var body: some View {
        if let fallEvent = state.activeFallEvent {
            ZStack {
                Color.black.opacity(0.72)
                    .ignoresSafeArea()
                    .accessibilityIdentifier("fall-alert-backdrop")

                RadialGradient(
                    colors: [SkateTrackSessionStartColors.accent.opacity(0.22), .clear],
                    center: .center,
                    startRadius: 30,
                    endRadius: 360
                )
                .ignoresSafeArea()

                FallDetectionAlertView(
                    fallEvent: fallEvent,
                    countdownSecondsRemaining: state.countdownSecondsRemaining ?? 15,
                    onCancel: actions.cancelAlert,
                    onSOSNow: actions.sendSOSNow
                )
                .padding(.horizontal, 22)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .accessibilityIdentifier("fall-detection-overlay")
            .zIndex(40)
        }
    }
}
