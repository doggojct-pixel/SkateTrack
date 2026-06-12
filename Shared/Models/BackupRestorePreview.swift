// [協作區] BackupRestorePreview.swift
// 用途：定義 Task-026b 非破壞性還原預覽結果，不包含任何資料寫回行為。
// 委派至：BackupPackageDecoder、useBackupSync 與 BackupRestorePreviewView 呈現 validation / conflict policy simulation。

import Foundation

enum BackupRestoreStorePreviewStatus: String, Codable, Sendable, Equatable {
    case decoded
    case missing
    case failed
    case countMismatch

    var localizationKey: String {
        switch self {
        case .decoded:
            return "backup.restore.store.status.decoded"
        case .missing:
            return "backup.restore.store.status.missing"
        case .failed:
            return "backup.restore.store.status.failed"
        case .countMismatch:
            return "backup.restore.store.status.count_mismatch"
        }
    }
}

struct BackupRestoreValidationIssue: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let storeKey: BackupPackageStoreKey?
    let stage: String
    let message: String

    init(
        id: UUID = UUID(),
        storeKey: BackupPackageStoreKey? = nil,
        stage: String,
        message: String
    ) {
        self.id = id
        self.storeKey = storeKey
        self.stage = stage
        self.message = message
    }
}

struct BackupRestoreStorePreview: Identifiable, Codable, Sendable, Equatable {
    let storeKey: BackupPackageStoreKey
    let expectedItemCount: Int
    let sectionItemCount: Int?
    let decodedItemCount: Int
    let status: BackupRestoreStorePreviewStatus
    let message: String?

    var id: String { storeKey.rawValue }

    init(
        storeKey: BackupPackageStoreKey,
        expectedItemCount: Int,
        sectionItemCount: Int? = nil,
        decodedItemCount: Int = 0,
        status: BackupRestoreStorePreviewStatus,
        message: String? = nil
    ) {
        self.storeKey = storeKey
        self.expectedItemCount = max(0, expectedItemCount)
        self.sectionItemCount = sectionItemCount.map { max(0, $0) }
        self.decodedItemCount = max(0, decodedItemCount)
        self.status = status
        self.message = message
    }
}

struct BackupRestorePreview: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let manifest: BackupPackageManifest
    let stores: [BackupRestoreStorePreview]
    let validationIssues: [BackupRestoreValidationIssue]
    let sourceFileName: String

    init(
        id: UUID = UUID(),
        manifest: BackupPackageManifest,
        stores: [BackupRestoreStorePreview],
        validationIssues: [BackupRestoreValidationIssue] = [],
        sourceFileName: String
    ) {
        self.id = id
        self.manifest = manifest
        self.stores = stores
        self.validationIssues = validationIssues
        self.sourceFileName = sourceFileName
    }

    var totalDecodedItems: Int {
        stores.reduce(0) { $0 + $1.decodedItemCount }
    }

    var hasValidationIssues: Bool {
        !validationIssues.isEmpty || stores.contains { $0.status != .decoded }
    }
}
