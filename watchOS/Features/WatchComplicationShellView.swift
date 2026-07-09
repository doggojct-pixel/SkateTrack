// [協作區] watchOS/Features/WatchComplicationShellView.swift
// Purpose: Renders the Task-039a disabled complication readiness shell.
// Delegates to: WatchComplicationShellState for placeholder state and localized copy keys.

import SwiftUI

struct WatchComplicationShellView: View {
    let state: WatchComplicationShellState
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "clock.fill")
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
                    .foregroundStyle(WatchComplicationShellPalette.textTertiary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)
            }

            Text(LocalizedStringKey(state.detailLocalizationKey))
                .font(.caption2)
                .foregroundStyle(WatchComplicationShellPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(state.slots) { slot in
                    WatchComplicationShellSlotPill(
                        slot: slot,
                        accentColor: accentColor
                    )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchComplicationShellPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(state.accessibilityLabelLocalizationKey)))
        .accessibilityIdentifier("watch-complication-shell")
    }
}

private struct WatchComplicationShellSlotPill: View {
    let slot: WatchComplicationShellSlot
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: slot.systemImageName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(slot.titleLocalizationKey))
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundStyle(WatchComplicationShellPalette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.54)
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .padding(.vertical, 5)
        .background(WatchComplicationShellPalette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(slot.detailLocalizationKey)))
    }
}

private enum WatchComplicationShellPalette {
    static let card = Color(red: 0.080, green: 0.118, blue: 0.180).opacity(0.96)
    static let panel = Color(red: 0.098, green: 0.140, blue: 0.220).opacity(0.95)
    static let textSecondary = Color(red: 0.720, green: 0.770, blue: 0.855)
    static let textTertiary = Color(red: 0.500, green: 0.555, blue: 0.690)
}

#Preview {
    WatchComplicationShellView(
        state: .disabled(),
        accentColor: .cyan
    )
}
