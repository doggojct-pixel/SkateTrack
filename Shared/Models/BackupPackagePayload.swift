// [協作區] Shared/Models/BackupPackagePayload.swift
// 用途：定義 SkateTrack 本機備份 payload envelope，以 section JSON 字串保存各資料 store。
// 委派至：BackupPackageEncoder 與未來 Task-026b restore preview validation。

import Foundation

enum BackupPackageStoreKey: String, Codable, Sendable, CaseIterable, Identifiable {
    case sessions
    case equipment
    case spots
    case achievements
    case weeklyChallengeCompletions

    var id: String { rawValue }

    var fileName: String {
        switch self {
        case .sessions:
            return "sessions.json"
        case .equipment:
            return "equipment.json"
        case .spots:
            return "spots.json"
        case .achievements:
            return "achievements.json"
        case .weeklyChallengeCompletions:
            return "weekly-challenge-completions.json"
        }
    }
}

struct BackupPackageSection: Codable, Sendable, Equatable, Identifiable {
    let storeKey: BackupPackageStoreKey
    let fileName: String
    let jsonString: String
    let itemCount: Int

    var id: String { storeKey.rawValue }

    init(storeKey: BackupPackageStoreKey, jsonString: String, itemCount: Int) {
        self.storeKey = storeKey
        self.fileName = storeKey.fileName
        self.jsonString = jsonString
        self.itemCount = max(0, itemCount)
    }
}

struct BackupPackagePayload: Codable, Sendable, Equatable {
    let manifest: BackupPackageManifest
    let sections: [BackupPackageSection]

    var hasEncodingIssues: Bool {
        !manifest.encodingIssues.isEmpty
    }
}

struct BackupPackageExportResult: Identifiable, Sendable, Equatable {
    let id: UUID
    let fileURL: URL
    let manifest: BackupPackageManifest
    let byteCount: Int

    init(
        id: UUID = UUID(),
        fileURL: URL,
        manifest: BackupPackageManifest,
        byteCount: Int
    ) {
        self.id = id
        self.fileURL = fileURL
        self.manifest = manifest
        self.byteCount = max(0, byteCount)
    }
}
