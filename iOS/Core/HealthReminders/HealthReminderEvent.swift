// [自主區] HealthReminderEvent.swift
// 用途：描述 Task-019b App 內健康提醒事件；不排程系統通知、不請求通知權限。
// 委派至：HealthReminderScheduler 產生事件；HealthReminderBannerView 呈現事件。

import Foundation

enum HealthReminderEventKind: String, Codable, Equatable, Identifiable, Sendable {
    case hydration
    case rest
    case cooldownStretch

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .hydration:
            return "health.reminders.banner.hydration.title"
        case .rest:
            return "health.reminders.banner.rest.title"
        case .cooldownStretch:
            return "health.reminders.banner.cooldown.title"
        }
    }

    var messageKey: String {
        switch self {
        case .hydration:
            return "health.reminders.banner.hydration.message"
        case .rest:
            return "health.reminders.banner.rest.message"
        case .cooldownStretch:
            return "health.reminders.banner.cooldown.message"
        }
    }

    var systemImageName: String {
        switch self {
        case .hydration:
            return "drop.fill"
        case .rest:
            return "pause.circle.fill"
        case .cooldownStretch:
            return "figure.cooldown"
        }
    }
}

struct HealthReminderEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: HealthReminderEventKind
    let triggeredAt: Date
    let activeElapsedTime: TimeInterval

    init(
        id: UUID = UUID(),
        kind: HealthReminderEventKind,
        triggeredAt: Date = Date(),
        activeElapsedTime: TimeInterval
    ) {
        self.id = id
        self.kind = kind
        self.triggeredAt = triggeredAt
        self.activeElapsedTime = activeElapsedTime
    }
}
