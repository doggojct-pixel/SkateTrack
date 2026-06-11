// [協作區] iOS/Features/FallDetection/FallDetectionOverlayPresenter.swift
// 用途：將 Fall Alert 高優先 overlay 與 SOS 事件提示疊到 Live HUD 上，不把 UI 寫回感測器引擎。
// 委派至：LiveHUDView 提供畫面掛載點。

import SwiftUI

struct FallDetectionOverlayPresenter: View {
    let state: FallDetectionAlertState
    let actions: FallDetectionActions
    let emergencyContacts: [EmergencyContact]
    let onManageContacts: () -> Void

    var body: some View {
        ZStack {
            if let fallEvent = state.activeFallEvent {
                fallAlertOverlay(fallEvent)
            } else if let event = state.latestSOSTriggerEvent {
                sosStatusOverlay(event)
            }
        }
        .zIndex(40)
    }

    private func fallAlertOverlay(_ fallEvent: FallEvent) -> some View {
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
                emergencyContacts: emergencyContacts,
                onCancel: actions.cancelAlert,
                onSOSNow: actions.sendSOSNow,
                onManageContacts: onManageContacts
            )
            .padding(.horizontal, 22)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .accessibilityIdentifier("fall-detection-overlay")
    }

    private func sosStatusOverlay(_ event: SOSTriggerEvent) -> some View {
        VStack {
            SOSTriggerStatusBanner(
                event: event,
                onManageContacts: onManageContacts,
                onDismiss: actions.clearLatestSOS
            )
            .padding(.top, 72)
            .padding(.horizontal, 20)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityIdentifier("sos-trigger-status-overlay")
    }
}

private struct SOSTriggerStatusBanner: View {
    let event: SOSTriggerEvent
    let onManageContacts: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: event.hasEmergencyContacts ? "checkmark.shield.fill" : "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(event.hasEmergencyContacts ? SkateTrackSessionStartColors.teal : SkateTrackSessionStartColors.amber)
                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(event.hasEmergencyContacts ? "sos.event.recorded" : "sos.event.needsContacts"))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(event.hasEmergencyContacts ? contactSummary : NSLocalizedString("sos.event.needsContacts.detail", comment: ""))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("sos-status-dismiss-button")
            }

            Text(event.messagePreview)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .lineLimit(2)

            if !event.hasEmergencyContacts {
                Button(action: onManageContacts) {
                    Label("safety.contacts.setNow", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .buttonStyle(.plain)
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .accessibilityIdentifier("sos-status-manage-contacts-button")
            }
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.navy2.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .shadow(color: SkateTrackSessionStartColors.accent.opacity(0.18), radius: 20, x: 0, y: 10)
    }

    private var contactSummary: String {
        if let primary = event.primaryEmergencyContact {
            return String(format: NSLocalizedString("sos.event.primaryContactFormat", comment: ""), primary.displayName)
        }
        return NSLocalizedString("sos.event.ready", comment: "")
    }
}
