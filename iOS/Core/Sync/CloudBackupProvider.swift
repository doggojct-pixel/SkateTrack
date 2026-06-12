// [協作區] CloudBackupProvider.swift
// 用途：定義 Task-026a 備份 / Drive provider boundary，讓 View 只透過 useBackupSync 存取。
// 委派至：LocalBackupProvider、DisabledDriveProvider 與未來 Google Drive provider。

import Foundation

enum CloudBackupProviderKind: String, Codable, Sendable, Equatable {
    case localPackage
    case googleDrive

    var localizationKey: String {
        switch self {
        case .localPackage:
            return "backup.provider.local_package"
        case .googleDrive:
            return "backup.provider.google_drive"
        }
    }
}

enum CloudBackupAvailability: Sendable, Equatable {
    case available
    case unavailable(messageKey: String)

    var messageKey: String {
        switch self {
        case .available:
            return "backup.status.available"
        case .unavailable(let messageKey):
            return messageKey
        }
    }
}

enum BackupConflictPolicy: String, Codable, Sendable, CaseIterable, Equatable {
    case localWins
    case remoteWins
    case mergeByDate

    var localizationKey: String {
        switch self {
        case .localWins:
            return "backup.conflict.local_wins"
        case .remoteWins:
            return "backup.conflict.remote_wins"
        case .mergeByDate:
            return "backup.conflict.merge_by_date"
        }
    }
}

protocol CloudBackupProvider: AnyObject, Sendable {
    var kind: CloudBackupProviderKind { get }
    func currentAvailability() async -> CloudBackupAvailability
    func createBackupPackage() async throws -> BackupPackageExportResult
}
