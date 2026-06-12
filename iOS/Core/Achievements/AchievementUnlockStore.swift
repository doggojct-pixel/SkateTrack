// [自主區] AchievementUnlockStore.swift
// 用途：以 UserDefaults 保存本機成就解鎖紀錄，避免 Task-024a 增加 Core Data migration。
// 委派至：useAchievements 讀寫解鎖狀態；未來雲端同步需另開任務升級。

import Foundation

protocol AchievementUnlockStoring: AnyObject, Sendable {
    func loadRecords() -> [String: AchievementUnlockRecord]
    func saveRecords(_ records: [String: AchievementUnlockRecord])
    func mergeUnlockedRecords(_ records: [AchievementUnlockRecord]) -> [String: AchievementUnlockRecord]
}

final class AchievementUnlockStore: AchievementUnlockStoring, @unchecked Sendable {
    static let shared = AchievementUnlockStore()

    private let userDefaults: UserDefaults
    private let key = "skateTrack.achievement.unlockRecords.v1"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadRecords() -> [String: AchievementUnlockRecord] {
        guard let data = userDefaults.data(forKey: key) else { return [:] }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let records = try decoder.decode([AchievementUnlockRecord].self, from: data)
            return Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        } catch {
            return [:]
        }
    }

    func saveRecords(_ records: [String: AchievementUnlockRecord]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let sortedRecords = records.values.sorted { $0.unlockedAt < $1.unlockedAt }
            let data = try encoder.encode(sortedRecords)
            userDefaults.set(data, forKey: key)
        } catch {
            return
        }
    }

    func mergeUnlockedRecords(_ records: [AchievementUnlockRecord]) -> [String: AchievementUnlockRecord] {
        guard !records.isEmpty else { return loadRecords() }
        var existing = loadRecords()
        for record in records where existing[record.id] == nil {
            existing[record.id] = record
        }
        saveRecords(existing)
        return existing
    }
}
