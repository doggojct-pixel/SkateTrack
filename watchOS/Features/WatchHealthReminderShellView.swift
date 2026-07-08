// [協作區] watchOS/Features/WatchHealthReminderShellView.swift
// Purpose: Renders the Task-038b general Watch reminder shell.
// Delegates to: WatchHealthReminderShellState for safe state and localized copy keys.

import SwiftUI

struct WatchHealthReminderShellView: View {
    let state: WatchHealthReminderShellState
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "heart.text.square.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(state.titleLocalizationKey))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Spacer(minLength: 0)
                Text(LocalizedStringKey(state.availability.statusLocalizationKey))
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(WatchHealthReminderShellPalette.textTertiary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }

            Text(LocalizedStringKey(state.detailLocalizationKey))
                .font(.caption2)
                .foregroundStyle(WatchHealthReminderShellPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(state.items) { item in
                    WatchHealthReminderShellItemPill(
                        item: item,
                        accentColor: accentColor
                    )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchHealthReminderShellPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.24), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(state.accessibilityLabelLocalizationKey)))
        .accessibilityIdentifier("watch-health-reminder-shell")
    }
}

private struct WatchHealthReminderShellItemPill: View {
    let item: WatchHealthReminderShellItem
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: item.systemImageName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)
            Text(LocalizedStringKey(item.titleLocalizationKey))
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundStyle(WatchHealthReminderShellPalette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .frame(maxWidth: .infinity, minHeight: 38)
        .padding(.vertical, 5)
        .background(WatchHealthReminderShellPalette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(item.detailLocalizationKey)))
    }
}

private enum WatchHealthReminderShellPalette {
    static let card = Color(red: 0.082, green: 0.126, blue: 0.196).opacity(0.96)
    static let panel = Color(red: 0.100, green: 0.146, blue: 0.235).opacity(0.95)
    static let textSecondary = Color(red: 0.720, green: 0.765, blue: 0.860)
    static let textTertiary = Color(red: 0.500, green: 0.555, blue: 0.690)
}

#Preview {
    WatchHealthReminderShellView(
        state: .disabled(),
        accentColor: .cyan
    )
}
