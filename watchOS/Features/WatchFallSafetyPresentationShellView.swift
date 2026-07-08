// [協作區] watchOS/Features/WatchFallSafetyPresentationShellView.swift
// Purpose: Renders the Task-038c Watch fall-safety presentation shell.
// Delegates to: WatchFallSafetyPresentationShellState for safe state and localized copy keys.

import SwiftUI

struct WatchFallSafetyPresentationShellView: View {
    let state: WatchFallSafetyPresentationShellState
    let accentColor: Color
    let onDismiss: () -> Void
    let onFalseAlarm: () -> Void

    var body: some View {
        if state.isVisible {
            VStack(alignment: .leading, spacing: 8) {
                header

                Text(LocalizedStringKey(state.detailLocalizationKey))
                    .font(.caption2)
                    .foregroundStyle(WatchFallSafetyShellPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedStringKey(state.limitationLocalizationKey))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchFallSafetyShellPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    actionButton(
                        titleKey: state.falseAlarmButtonLocalizationKey,
                        systemImageName: "xmark.circle.fill",
                        foreground: accentColor,
                        action: onFalseAlarm
                    )
                    actionButton(
                        titleKey: state.dismissButtonLocalizationKey,
                        systemImageName: "checkmark.circle.fill",
                        foreground: WatchFallSafetyShellPalette.textSecondary,
                        action: onDismiss
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WatchFallSafetyShellPalette.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accentColor.opacity(0.22), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(LocalizedStringKey(state.accessibilityLabelLocalizationKey)))
            .accessibilityIdentifier("watch-fall-safety-presentation-shell")
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(state.titleLocalizationKey))
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
            Spacer(minLength: 0)
            Text(LocalizedStringKey(state.phase.statusLocalizationKey))
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundStyle(WatchFallSafetyShellPalette.textTertiary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
    }

    private func actionButton(
        titleKey: String,
        systemImageName: String,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            } icon: {
                Image(systemName: systemImageName)
                    .font(.caption2.weight(.bold))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(WatchFallSafetyShellPalette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier("watch-fall-safety-\(titleKey)")
    }
}

private enum WatchFallSafetyShellPalette {
    static let card = Color(red: 0.078, green: 0.112, blue: 0.168).opacity(0.96)
    static let panel = Color(red: 0.100, green: 0.140, blue: 0.205).opacity(0.95)
    static let textSecondary = Color(red: 0.725, green: 0.780, blue: 0.860)
    static let textTertiary = Color(red: 0.500, green: 0.555, blue: 0.680)
}

#Preview {
    WatchFallSafetyPresentationShellView(
        state: .presented(),
        accentColor: .cyan,
        onDismiss: {},
        onFalseAlarm: {}
    )
}
