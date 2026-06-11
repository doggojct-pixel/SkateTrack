// [協作區] HealthReminderBannerView.swift
// 用途：在 Live HUD 顯示 Task-019b App 內健康提醒；不排程系統通知。
// 委派至：useHealthReminders 提供 active reminder event。

import SwiftUI

struct HealthReminderBannerView: View {
    let event: HealthReminderEvent
    let onDismiss: () -> Void

    private var accentColor: Color {
        switch event.kind {
        case .hydration:
            return SkateTrackSessionStartColors.teal
        case .rest:
            return SkateTrackSessionStartColors.amber
        case .cooldownStretch:
            return SkateTrackSessionStartColors.purple
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.kind.systemImageName)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(event.kind.titleKey))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(LocalizedStringKey(event.kind.messageKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(SkateTrackSessionStartColors.card.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("health.reminders.banner.dismiss"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SkateTrackSessionStartColors.card.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.16), radius: 18, x: 0, y: 8)
        .accessibilityIdentifier("health-reminder-banner")
    }
}

#Preview("Health Reminder Banner") {
    HealthReminderBannerView(
        event: HealthReminderEvent(kind: .hydration, activeElapsedTime: 1200),
        onDismiss: {}
    )
    .padding()
    .background(SkateTrackSessionStartColors.navy)
    .preferredColorScheme(.dark)
}
