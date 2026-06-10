// [協作區] iOS/Features/FallDetection/FallDetectionAlertView.swift
// 用途：呈現跌倒偵測高優先警示 UI、15 秒倒數、我沒事取消與立即 SOS。
// 委派至：FallDetectionOverlayPresenter 提供狀態與 actions。

import Foundation
import SwiftUI

struct FallDetectionAlertView: View {
    let fallEvent: FallEvent
    let countdownSecondsRemaining: Int
    let onCancel: () -> Void
    let onSOSNow: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            warningIcon

            Text("fall.alert.title")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.accent)
                .multilineTextAlignment(.center)

            Text("fall.alert.message")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 270)

            countdownRing
            impactBadge
            actionButtons
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: 340)
        .background(alertCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34).stroke(SkateTrackSessionStartColors.accent.opacity(0.34), lineWidth: 1.5))
        .shadow(color: SkateTrackSessionStartColors.accent.opacity(0.28), radius: 36, x: 0, y: 0)
        .accessibilityIdentifier("fall-detection-alert-view")
    }

    private var warningIcon: some View {
        ZStack {
            Circle().fill(SkateTrackSessionStartColors.accent.opacity(0.14))
            Circle().stroke(SkateTrackSessionStartColors.accent, lineWidth: 3)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.accent)
        }
        .frame(width: 118, height: 118)
        .shadow(color: SkateTrackSessionStartColors.accent.opacity(0.45), radius: 28, x: 0, y: 0)
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(SkateTrackSessionStartColors.card.opacity(0.92), lineWidth: 7)
            Circle()
                .trim(from: 0, to: countdownProgress)
                .stroke(SkateTrackSessionStartColors.amber, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.25), value: countdownSecondsRemaining)
            VStack(spacing: 0) {
                Text("\(max(0, countdownSecondsRemaining))")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                Text("fall.alert.countdown")
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)
            }
        }
        .frame(width: 88, height: 88)
        .accessibilityIdentifier("fall-alert-countdown")
    }

    private var impactBadge: some View {
        HStack(spacing: 6) {
            Text("fall.alert.impact")
            Text(String(format: "%.1fg", fallEvent.peakImpactGForce))
                .foregroundStyle(.white)
            Text("·")
            Text(locationKey)
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .foregroundStyle(SkateTrackSessionStartColors.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(SkateTrackSessionStartColors.accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(SkateTrackSessionStartColors.accent.opacity(0.28), lineWidth: 1))
        .accessibilityIdentifier("fall-alert-impact-badge")
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onCancel) {
                Label("fall.alert.imOkay", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .background(SkateTrackSessionStartColors.teal)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .shadow(color: SkateTrackSessionStartColors.teal.opacity(0.34), radius: 16, x: 0, y: 8)
            .accessibilityIdentifier("fall-alert-im-okay-button")

            Button(action: onSOSNow) {
                Label("fall.alert.sosNow", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.accent)
            .background(.clear)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(SkateTrackSessionStartColors.accent.opacity(0.55), lineWidth: 1.4))
            .accessibilityIdentifier("fall-alert-sos-now-button")
        }
        .frame(maxWidth: 250)
    }

    private var alertCardBackground: some View {
        ZStack {
            SkateTrackSessionStartColors.navy2.opacity(0.97)
            RadialGradient(
                colors: [SkateTrackSessionStartColors.accent.opacity(0.18), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 260
            )
        }
    }

    private var countdownProgress: CGFloat {
        CGFloat(min(max(Double(countdownSecondsRemaining) / 15.0, 0), 1))
    }

    private var locationKey: LocalizedStringKey {
        fallEvent.locationCoordinate == nil ? "fall.alert.locationUnavailable" : "fall.alert.locationSaved"
    }
}

#Preview("Fall Alert") {
    FallDetectionAlertView(
        fallEvent: FallEvent(
            timestamp: Date(),
            peakImpactGForce: 6.2,
            locationCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
            sportMode: .skateboard(.streetPark)
        ),
        countdownSecondsRemaining: 10,
        onCancel: {},
        onSOSNow: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
