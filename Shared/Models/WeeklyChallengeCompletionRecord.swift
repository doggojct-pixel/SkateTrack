// [協作區] Shared/Models/WeeklyChallengeCompletionRecord.swift
// 用途：記錄本機每週挑戰完成狀態，讓完成週期可以穩定呈現而不依賴遠端服務。
// 委派至：WeeklyChallengeCompletionStore、WeeklyChallengeEngine 與成就 UI。

import Foundation

struct WeeklyChallengeCompletionRecord: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let challengeID: String
    let weekIdentifier: String
    let completedAt: Date

    init(
        challengeID: String,
        weekIdentifier: String,
        completedAt: Date = Date()
    ) {
        self.challengeID = challengeID
        self.weekIdentifier = weekIdentifier
        self.id = Self.makeID(challengeID: challengeID, weekIdentifier: weekIdentifier)
        self.completedAt = completedAt
    }

    static func makeID(challengeID: String, weekIdentifier: String) -> String {
        "\(challengeID)::\(weekIdentifier)"
    }
}
