// [協作區] SnowHUDView.swift
// 用途：iPhone Snow Mode Live HUD 入口，只根據 SnowLiveHUDState 呈現四種狀態。
// 委派至：Snow-Task-005b iPhone Snow UI；不直接讀 MotionSample / classifier / detector。

import Foundation
import SwiftUI

struct SnowHUDView: View {
    let hudState: SnowLiveHUDState
    let recordingState: SessionRecordingState
    let accentColor: Color
    #if DEBUG
    @ObservedObject private var debugRuntimeOptions = DebugRuntimeOptions.shared
    #endif

    var body: some View {
        VStack(spacing: 14) {
            header

            Group {
                switch presentationHUDState {
                case let .downhill(model):
                    SnowHUDDownhillView(model: model, accentColor: accentColor)
                case let .lift(model):
                    SnowHUDLiftView(model: model, accentColor: accentColor)
                case let .waiting(model):
                    SnowHUDWaitingView(model: model, accentColor: accentColor)
                case let .lowConfidence(model):
                    SnowHUDLowConfidenceView(model: model, accentColor: accentColor)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))

            manualMarkingPlaceholder
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.18), value: presentationHUDState)
        .accessibilityIdentifier("snow-hud-view")
    }

    private var presentationHUDState: SnowLiveHUDState {
        #if DEBUG
        SnowHUDQAScenario.presentationState(
            selectedScenario: debugRuntimeOptions.selectedSnowHUDQAScenario,
            selectedSportMode: recordingState.selectedSportMode,
            liveState: hudState
        )
        #else
        hudState
        #endif
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "snowflake")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text("snow.hud.title")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(statusSummaryKey)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .textCase(.uppercase)
            }

            Spacer()

            Text(LocalizedStringKey(recordingState.selectedSportMode?.modeLocalizationKey ?? "snow.sport.title"))
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(accentColor.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(accentColor.opacity(0.22), lineWidth: 1))
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.79))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("snow-hud-header")
    }

    private var statusSummaryKey: LocalizedStringKey {
        switch hudState {
        case .downhill:
            return "snow.hud.downhill.status"
        case .lift:
            return "snow.hud.lift.status"
        case .waiting:
            return "snow.hud.waiting.status"
        case .lowConfidence:
            return "snow.hud.lowConfidence.status"
        }
    }

    private var manualMarkingPlaceholder: some View {
        HStack(spacing: 10) {
            SnowHUDPlaceholderButton(
                titleKey: "snow.hud.markSkiing.placeholder",
                systemImage: "figure.skiing.downhill",
                accentColor: accentColor
            )
            SnowHUDPlaceholderButton(
                titleKey: "snow.hud.markLift.placeholder",
                systemImage: "cablecar.fill",
                accentColor: SkateTrackSessionStartColors.amber
            )
        }
        .accessibilityIdentifier("snow-hud-manual-marking-placeholder")
    }
}

struct SnowHUDMetricTile: View {
    let value: String
    let labelKey: String
    let tintColor: Color
    let accessibilityID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(tintColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(labelKey))
                .tracking(1.15)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(SkateTrackSessionStartColors.card.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier(accessibilityID)
    }
}

struct SnowHUDPlaceholderButton: View {
    let titleKey: String
    let systemImage: String
    let accentColor: Color

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .heavy))
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(accentColor.opacity(0.72))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(SkateTrackSessionStartColors.card.opacity(0.56))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(accentColor.opacity(0.20), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(true)
        .accessibilityHint(Text("snow.hud.manual.placeholder.hint"))
    }
}

extension SnowHUDView {
    static func formatSpeed(_ value: Double) -> String {
        String(format: "%.1f", max(0, value))
    }

    static func formatMeters(_ value: Double) -> String {
        String(format: "%.0f", max(0, value))
    }

    static func formatDuration(_ value: TimeInterval) -> String {
        let totalSeconds = max(0, Int(value.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview("Snow HUD Waiting") {
    SnowHUDView(
        hudState: .waiting(
            SnowWaitingHUDModel(
                titleLocalizationKey: "snow.hud.waiting.title",
                currentSegmentType: .stopped,
                pendingEndElapsedSeconds: nil,
                lastRunVerticalDropMeters: 318,
                lastRunTopSpeedKmh: 47.2,
                lastRunDurationSeconds: 86
            )
        ),
        recordingState: .initial,
        accentColor: SkateTrackSessionStartColors.ice
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
