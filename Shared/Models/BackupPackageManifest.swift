// [協作區] Shared/Models/BackupPackageManifest.swift
// 用途：定義 SkateTrack 本機備份 package manifest 與 schema 版本策略。
// 委派至：BackupPackageEncoder、LocalBackupProvider、未來 Task-026b restore preview 與 Task-027 package reader。

import Foundation

enum BackupPackageType: String, Codable, Sendable, Equatable {
    case backup
}

struct BackupPackageManifest: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 2
    static let supportedSchemaVersions: Set<Int> = [1, 2]

    let packageType: BackupPackageType
    let schemaVersion: Int
    let appVersion: String
    let buildNumber: String
    let createdAt: Date
    let localeIdentifier: String
    let storeCounts: BackupPackageStoreCounts
    let encodingIssues: [BackupPackageStoreIssue]

    init(
        packageType: BackupPackageType = .backup,
        schemaVersion: Int = BackupPackageManifest.currentSchemaVersion,
        appVersion: String,
        buildNumber: String,
        createdAt: Date = Date(),
        localeIdentifier: String,
        storeCounts: BackupPackageStoreCounts,
        encodingIssues: [BackupPackageStoreIssue] = []
    ) {
        self.packageType = packageType
        self.schemaVersion = schemaVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.createdAt = createdAt
        self.localeIdentifier = localeIdentifier
        self.storeCounts = storeCounts
        self.encodingIssues = encodingIssues
    }

    static func decode(from data: Data) throws -> BackupPackageManifest {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let raw = try decoder.decode(BackupPackageManifest.self, from: data)
        try validate(raw)
        return raw
    }

    static func validate(_ manifest: BackupPackageManifest) throws {
        guard supportedSchemaVersions.contains(manifest.schemaVersion) else {
            throw BackupPackageError.unsupportedSchemaVersion(manifest.schemaVersion)
        }

        guard manifest.packageType == .backup else {
            throw BackupPackageError.unsupportedPackageType(manifest.packageType.rawValue)
        }
    }
}

struct BackupPackageStoreCounts: Codable, Sendable, Equatable {
    let sessions: Int
    let equipment: Int
    let spots: Int
    let achievements: Int
    let weeklyChallengeCompletions: Int
    let snowSessions: Int?

    init(
        sessions: Int = 0,
        equipment: Int = 0,
        spots: Int = 0,
        achievements: Int = 0,
        weeklyChallengeCompletions: Int = 0,
        snowSessions: Int? = nil
    ) {
        self.sessions = max(0, sessions)
        self.equipment = max(0, equipment)
        self.spots = max(0, spots)
        self.achievements = max(0, achievements)
        self.weeklyChallengeCompletions = max(0, weeklyChallengeCompletions)
        self.snowSessions = snowSessions.map { max(0, $0) }
    }
}

struct BackupPackageStoreIssue: Codable, Sendable, Equatable, Identifiable {
    let id: UUID
    let storeKey: String
    let stage: String
    let message: String

    init(id: UUID = UUID(), storeKey: String, stage: String, message: String) {
        self.id = id
        self.storeKey = storeKey
        self.stage = stage
        self.message = message
    }
}

enum BackupPackageError: Error, Sendable, Equatable {
    case unsupportedSchemaVersion(Int)
    case unsupportedPackageType(String)
    case invalidBackupPackage
    case packageEncodingFailed
    case fileWriteFailed
    case localBackupUnavailable
    case googleDriveUnavailable
}
