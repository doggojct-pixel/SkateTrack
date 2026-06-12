// [協作區] DisabledDriveProvider.swift
// 用途：在沒有 Google OAuth / Drive scope / credentials 前誠實回報 Google Drive 備份不可用。
// 委派至：useBackupSync 與 BackupSyncSettingsView 呈現 disabled 狀態。

import Foundation

final class DisabledDriveProvider: CloudBackupProvider, @unchecked Sendable {
    static let shared = DisabledDriveProvider()

    let kind: CloudBackupProviderKind = .googleDrive

    func currentAvailability() async -> CloudBackupAvailability {
        .unavailable(messageKey: "backup.drive.status.credentials_missing")
    }

    func createBackupPackage() async throws -> BackupPackageExportResult {
        throw BackupPackageError.googleDriveUnavailable
    }
}
