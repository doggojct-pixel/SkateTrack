// [協作區] StartSessionCTAView.swift
// 用途：呈現開始 Session CTA、付費鎖定提示與感測器 preparing 狀態。
// 委派至：SessionStartView 決定真正開始 Session 或導向付費牆 stub。

import SwiftUI

struct StartSessionCTAView: View {
    let status: SessionRecordingStatus
    let isLocked: Bool
    let accentColor: Color
    let onStart: () -> Void
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Button(action: isLocked ? onUnlock : onStart) {
                HStack(spacing: 10) {
                    if status == .preparing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: isLocked ? "lock.fill" : "play.fill")
                    }

                    Text(LocalizedStringKey(buttonTitleKey))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: accentColor.opacity(buttonShadowOpacity), radius: 20, x: 0, y: 8)
            }
            .disabled(status == .preparing || status == .recording || status == .saving)
            .accessibilityIdentifier("session-start-cta")

            HStack(spacing: 6) {
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 6, height: 6)

                Text(LocalizedStringKey(statusCaptionKey))
                    .tracking(1)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .textCase(.uppercase)
            }

            if isLocked {
                Text("session.start.unlockToStart")
                    .font(.footnote)
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }
        }
    }

    private var buttonTitleKey: String {
        if isLocked {
            return "subscription.subscribe_cta"
        }

        switch status {
        case .preparing:
            return "session.status.preparing"
        case .recording:
            return "session.status.recording"
        case .saving:
            return "session.status.saving"
        default:
            return "session.start.cta"
        }
    }

    private var statusCaptionKey: String {
        switch status {
        case .recording:
            return "session.status.recording"
        case .preparing:
            return "session.status.preparing"
        case .saving:
            return "session.status.saving"
        default:
            return "session.status.idle"
        }
    }

    private var buttonBackground: LinearGradient {
        let colors: [Color]
        if status == .preparing || status == .recording || status == .saving {
            colors = [Color.gray.opacity(0.62), Color.gray.opacity(0.40)]
        } else {
            colors = [accentColor, accentColor.opacity(0.72)]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var statusDotColor: Color {
        status == .recording ? SkateTrackSessionStartColors.accent : SkateTrackSessionStartColors.textTertiary
    }

    private var buttonShadowOpacity: Double {
        status == .idle && !isLocked ? 0.36 : 0.0
    }
}

#Preview("Start CTA") {
    StartSessionCTAView(
        status: .idle,
        isLocked: false,
        accentColor: SkateTrackSessionStartColors.accent,
        onStart: {},
        onUnlock: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy2)
    .preferredColorScheme(.dark)
}
