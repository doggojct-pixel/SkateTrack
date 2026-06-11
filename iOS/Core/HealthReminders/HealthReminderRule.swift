// [自主區] HealthReminderRule.swift
// 用途：定義 Task-019a 健康提醒設定模型，不處理排程、通知或天氣資料來源。
// 委派至：HealthReminderSettingsStore 保存本機設定；019b/019c 再接 Session banner 與 Weather provider。

import Foundation

enum HealthReminderKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case hydration
    case rest
    case cooldownStretch
    case heatRisk
    case uvRisk

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .hydration:
            return "health.reminders.hydration.title"
        case .rest:
            return "health.reminders.rest.title"
        case .cooldownStretch:
            return "health.reminders.cooldown.title"
        case .heatRisk:
            return "health.reminders.heat.title"
        case .uvRisk:
            return "health.reminders.uv.title"
        }
    }

    var subtitleKey: String {
        switch self {
        case .hydration:
            return "health.reminders.hydration.subtitle"
        case .rest:
            return "health.reminders.rest.subtitle"
        case .cooldownStretch:
            return "health.reminders.cooldown.subtitle"
        case .heatRisk:
            return "health.reminders.heat.subtitle"
        case .uvRisk:
            return "health.reminders.uv.subtitle"
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
        case .heatRisk:
            return "thermometer.sun.fill"
        case .uvRisk:
            return "sun.max.fill"
        }
    }

    var defaultIntervalMinutes: Int? {
        switch self {
        case .hydration:
            return 20
        case .rest:
            return 45
        case .cooldownStretch:
            return 10
        case .heatRisk, .uvRisk:
            return nil
        }
    }

    var defaultThreshold: Double? {
        switch self {
        case .heatRisk:
            return 35
        case .uvRisk:
            return 6
        case .hydration, .rest, .cooldownStretch:
            return nil
        }
    }
}

struct HealthReminderRule: Codable, Identifiable, Equatable, Sendable {
    let kind: HealthReminderKind
    var isEnabled: Bool
    var intervalMinutes: Int?
    var threshold: Double?

    var id: HealthReminderKind { kind }

    static func defaultRule(for kind: HealthReminderKind) -> HealthReminderRule {
        HealthReminderRule(
            kind: kind,
            isEnabled: false,
            intervalMinutes: kind.defaultIntervalMinutes,
            threshold: kind.defaultThreshold
        )
    }
}

struct HealthReminderSettings: Codable, Equatable, Sendable {
    var rules: [HealthReminderRule]
    var lastUpdated: Date

    static var defaults: HealthReminderSettings {
        HealthReminderSettings(
            rules: HealthReminderKind.allCases.map { HealthReminderRule.defaultRule(for: $0) },
            lastUpdated: Date()
        )
    }

    func rule(for kind: HealthReminderKind) -> HealthReminderRule {
        rules.first(where: { $0.kind == kind }) ?? HealthReminderRule.defaultRule(for: kind)
    }

    var enabledRules: [HealthReminderRule] {
        rules.filter(\.isEnabled)
    }

    mutating func update(_ rule: HealthReminderRule) {
        if let index = rules.firstIndex(where: { $0.kind == rule.kind }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
        lastUpdated = Date()
    }
}
