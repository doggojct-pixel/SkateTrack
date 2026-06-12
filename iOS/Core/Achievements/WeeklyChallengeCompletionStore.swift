// [自主區] WeeklyChallengeCompletionStore.swift
// 用途：以 UserDefaults 保存本機每週挑戰完成紀錄，避免 Task-024b 增加 Core Data migration。
// 委派至：useAchievements 合併本週完成狀態；未來跨裝置同步需另開任務升級。

import Foundation

protocol WeeklyChallengeCompletionStoring: AnyObject, Sendable {
    func loadRecords() -> [String: WeeklyChallengeCompletionRecord]
    func saveRecords(_ records: [String: WeeklyChallengeCompletionRecord])
    func mergeCompletedRecords(_ records: [WeeklyChallengeCompletionRecord]) -> [String: WeeklyChallengeCompletionRecord]
}

final class WeeklyChallengeCompletionStore: WeeklyChallengeCompletionStoring, @unchecked Sendable {
    static let shared = WeeklyChallengeCompletionStore()

    private let userDefaults: UserDefaults
    private let key = "skateTrack.weeklyChallenge.completionRecords.v1"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadRecords() -> [String: WeeklyChallengeCompletionRecord] {
        guard let data = userDefaults.data(forKey: key) else { return [:] }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let records = try decoder.decode([WeeklyChallengeCompletionRecord].self, from: data)
            return Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        } catch {
            return [:]
        }
    }

    func saveRecords(_ records: [String: WeeklyChallengeCompletionRecord]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let sortedRecords = records.values.sorted { $0.completedAt < $1.completedAt }
            let data = try encoder.encode(sortedRecords)
            userDefaults.set(data, forKey: key)
        } catch {
            return
        }
    }

    func mergeCompletedRecords(_ records: [WeeklyChallengeCompletionRecord]) -> [String: WeeklyChallengeCompletionRecord] {
        guard !records.isEmpty else { return loadRecords() }
        var existing = loadRecords()
        for record in records where existing[record.id] == nil {
            existing[record.id] = record
        }
        saveRecords(existing)
        return existing
    }
}
