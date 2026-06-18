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

    var localizationKey: String {
        switch self {
        case .sessions:
            return "backup.store.sessions"
        case .equipment:
            return "backup.store.equipment"
        case .spots:
            return "backup.store.spots"
        case .achievements:
            return "backup.store.achievements"
        case .weeklyChallengeCompletions:
            return "backup.store.weekly_challenge_completions"
        }
    }

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

struct SnowBackupSession: Codable, Sendable, Equatable, Identifiable {
    static let currentSchemaVersion = "snow-backup-session-1.0"

    let id: UUID
    let schemaVersion: String
    let sessionID: UUID
    let runs: [SnowRun]
    let segments: [SnowSegment]
    let distanceBreakdown: SnowDistanceBreakdown
    let verticalMetrics: SnowVerticalMetrics
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        schemaVersion: String = SnowBackupSession.currentSchemaVersion,
        sessionID: UUID,
        runs: [SnowRun],
        segments: [SnowSegment],
        distanceBreakdown: SnowDistanceBreakdown? = nil,
        verticalMetrics: SnowVerticalMetrics? = nil,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.sessionID = sessionID
        self.runs = runs
        self.segments = segments
        self.distanceBreakdown = distanceBreakdown ?? SnowDistanceBreakdown.make(from: segments)
        self.verticalMetrics = verticalMetrics ?? SnowVerticalMetrics.make(from: segments, runs: runs)
        self.generatedAt = generatedAt
    }

    init?(snowState: SnowSessionState, generatedAt: Date = Date()) {
        guard let sessionID = snowState.sessionID else { return nil }
        guard snowState.runs.isEmpty == false || snowState.segments.isEmpty == false else { return nil }
        self.init(
            sessionID: sessionID,
            runs: snowState.runs,
            segments: snowState.segments,
            distanceBreakdown: snowState.distanceBreakdown,
            verticalMetrics: snowState.verticalMetrics,
            generatedAt: generatedAt
        )
    }

    func makeSnowSessionState() -> SnowSessionState {
        SnowSessionState(
            sessionID: sessionID,
            loadState: .loaded,
            runs: runs,
            segments: segments,
            distanceBreakdown: distanceBreakdown,
            verticalMetrics: verticalMetrics
        )
    }
}

struct BackupPackagePayload: Codable, Sendable, Equatable {
    let manifest: BackupPackageManifest
    let sections: [BackupPackageSection]
    let snowSessions: [SnowBackupSession]?

    init(
        manifest: BackupPackageManifest,
        sections: [BackupPackageSection],
        snowSessions: [SnowBackupSession]? = nil
    ) {
        self.manifest = manifest
        self.sections = sections
        self.snowSessions = snowSessions
    }

    var hasEncodingIssues: Bool {
        !manifest.encodingIssues.isEmpty
    }

    var isSnowAwareBackup: Bool {
        snowSessions != nil
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
