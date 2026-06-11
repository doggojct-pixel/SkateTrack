// [自主區] HealthReminderSettingsStore.swift
// 用途：保存 Task-019a 健康提醒設定；目前只做本機偏好，不排程通知。
// 委派至：useHealthReminders 對 SwiftUI 暴露可觀察狀態與權限檢查。

import Combine
import Foundation

@MainActor
final class HealthReminderSettingsStore: ObservableObject {
    static let shared = HealthReminderSettingsStore()

    @Published private(set) var settings: HealthReminderSettings

    private let userDefaults: UserDefaults
    private static let storageKey = "com.skatetrack.health_reminders.settings.v1"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.settings = Self.loadSettings(from: userDefaults, key: Self.storageKey)
    }

    func setEnabled(_ isEnabled: Bool, for kind: HealthReminderKind) {
        var nextRule = settings.rule(for: kind)
        nextRule.isEnabled = isEnabled
        save(rule: nextRule)
    }

    func setIntervalMinutes(_ minutes: Int, for kind: HealthReminderKind) {
        var nextRule = settings.rule(for: kind)
        nextRule.intervalMinutes = max(5, min(minutes, 180))
        save(rule: nextRule)
    }

    func setThreshold(_ value: Double, for kind: HealthReminderKind) {
        var nextRule = settings.rule(for: kind)
        nextRule.threshold = value
        save(rule: nextRule)
    }

    func resetToDefaults() {
        settings = .defaults
        persist(settings)
    }

    private func save(rule: HealthReminderRule) {
        var nextSettings = settings
        nextSettings.update(rule)
        settings = nextSettings
        persist(nextSettings)
    }

    private func persist(_ settings: HealthReminderSettings) {
        guard let data = try? JSONEncoder.skateTrackHealthReminderEncoder.encode(settings) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }

    private static func loadSettings(from userDefaults: UserDefaults, key: String) -> HealthReminderSettings {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder.skateTrackHealthReminderDecoder.decode(HealthReminderSettings.self, from: data) else {
            return .defaults
        }

        var normalized = decoded
        for kind in HealthReminderKind.allCases where normalized.rules.contains(where: { $0.kind == kind }) == false {
            normalized.rules.append(.defaultRule(for: kind))
        }
        return normalized
    }
}

private extension JSONEncoder {
    static var skateTrackHealthReminderEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var skateTrackHealthReminderDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
