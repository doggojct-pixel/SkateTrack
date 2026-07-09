// [協作區] watchOS/Features/WatchQuickStartShellView.swift
// Purpose: Renders the Task-039b disabled/provider-aware quick-start shell.
// Delegates to: WatchQuickStartShellState for iPhone-authoritative placeholder behavior.

import SwiftUI

struct WatchQuickStartShellView: View {
    let state: WatchQuickStartShellState
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "bolt.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(state.titleLocalizationKey))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
                Text(LocalizedStringKey(state.availability.statusLocalizationKey))
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WatchQuickStartShellPalette.textTertiary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
            }

            Text(LocalizedStringKey(state.detailLocalizationKey))
                .font(.caption2)
                .foregroundStyle(WatchQuickStartShellPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(state.options) { option in
                    WatchQuickStartShellOptionPill(
                        option: option,
                        accentColor: accentColor
                    )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchQuickStartShellPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(state.accessibilityLabelLocalizationKey)))
        .accessibilityIdentifier("watch-quick-start-shell")
    }
}

private struct WatchQuickStartShellOptionPill: View {
    let option: WatchQuickStartShellOption
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: option.systemImageName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(option.titleLocalizationKey))
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundStyle(WatchQuickStartShellPalette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.54)
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .padding(.vertical, 5)
        .background(WatchQuickStartShellPalette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(option.detailLocalizationKey)))
    }
}

private enum WatchQuickStartShellPalette {
    static let card = Color(red: 0.078, green: 0.120, blue: 0.178).opacity(0.96)
    static let panel = Color(red: 0.096, green: 0.145, blue: 0.220).opacity(0.95)
    static let textSecondary = Color(red: 0.720, green: 0.770, blue: 0.855)
    static let textTertiary = Color(red: 0.500, green: 0.555, blue: 0.690)
}

#Preview {
    WatchQuickStartShellView(
        state: .disabled(canSendCommands: true),
        accentColor: .cyan
    )
}
