// [自主區] HealthReminderScheduler.swift
// 用途：依照 Session active time 與健康提醒設定產生 App 內提醒事件。
// 委派至：useHealthReminders 連接 SessionRecordingState；不排程系統通知、不碰感測器演算法。

import Foundation

@MainActor
final class HealthReminderScheduler {
    private var firedReminderKeys = Set<String>()
    private var lastStatus: SessionRecordingStatus = .idle

    func nextEvent(
        status: SessionRecordingStatus,
        activeElapsedTime: TimeInterval,
        settings: HealthReminderSettings,
        canUseReminders: Bool
    ) -> HealthReminderEvent? {
        defer { lastStatus = status }

        guard canUseReminders else {
            resetIfSessionEnded(status)
            return nil
        }

        switch status {
        case .recording:
            return dueEvent(for: .hydration, elapsedTime: activeElapsedTime, settings: settings)
                ?? dueEvent(for: .rest, elapsedTime: activeElapsedTime, settings: settings)
        case .ending, .saving:
            return nil
        case .idle, .failed:
            reset()
            return nil
        case .preparing, .paused:
            return nil
        }
    }

    func reset() {
        firedReminderKeys.removeAll(keepingCapacity: true)
        lastStatus = .idle
    }

    private func dueEvent(
        for kind: HealthReminderKind,
        elapsedTime: TimeInterval,
        settings: HealthReminderSettings
    ) -> HealthReminderEvent? {
        let rule = settings.rule(for: kind)
        guard rule.isEnabled,
              let intervalMinutes = rule.intervalMinutes,
              intervalMinutes > 0 else {
            return nil
        }

        let intervalSeconds = TimeInterval(intervalMinutes * 60)
        guard elapsedTime >= intervalSeconds else { return nil }

        let bucket = max(1, Int(elapsedTime / intervalSeconds))
        let key = "\(kind.rawValue):\(bucket)"
        guard firedReminderKeys.contains(key) == false else { return nil }
        firedReminderKeys.insert(key)

        switch kind {
        case .hydration:
            return HealthReminderEvent(kind: .hydration, activeElapsedTime: elapsedTime)
        case .rest:
            return HealthReminderEvent(kind: .rest, activeElapsedTime: elapsedTime)
        case .cooldownStretch, .heatRisk, .uvRisk:
            return nil
        }
    }

    private func cooldownEventIfNeeded(
        elapsedTime: TimeInterval,
        settings: HealthReminderSettings
    ) -> HealthReminderEvent? {
        let rule = settings.rule(for: .cooldownStretch)
        let key = "cooldownStretch:completed"
        guard rule.isEnabled,
              firedReminderKeys.contains(key) == false,
              lastStatus == .recording || lastStatus == .paused || lastStatus == .ending else {
            return nil
        }

        firedReminderKeys.insert(key)
        return HealthReminderEvent(kind: .cooldownStretch, activeElapsedTime: elapsedTime)
    }

    private func resetIfSessionEnded(_ status: SessionRecordingStatus) {
        if status == .idle || status == .failed {
            reset()
        }
    }
}
