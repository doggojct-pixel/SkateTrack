// [協作區 — 邊界適配層] useBackupSync.swift
// 用途：向 SwiftUI Views 暴露本機備份與 Google Drive disabled 狀態，隱藏 provider / repository 細節。
// 委派至：BackupSyncSettingsView；View 不直接碰 provider、Core Data 或 Google Drive API。

import SwiftUI

@MainActor
final class BackupSyncViewModel: ObservableObject {
    @Published private(set) var isPreparingBackup = false
    @Published private(set) var latestExport: BackupPackageExportResult?
    @Published private(set) var localAvailabilityMessageKey = "backup.status.available"
    @Published private(set) var driveAvailabilityMessageKey = "backup.drive.status.checking"
    @Published private(set) var statusMessageKey = "backup.status.ready"
    @Published private(set) var errorMessageKey: String?

    private let localProvider: CloudBackupProvider
    private let driveProvider: CloudBackupProvider
    private let subscriptionStatus: SubscriptionStatusViewModel

    convenience init() {
        let defaultLocalProvider = LocalBackupProvider.shared
        let defaultDriveProvider = DisabledDriveProvider.shared
        let defaultSubscriptionStatus = useSubscriptionStatus()
        self.init(
            localProvider: defaultLocalProvider,
            driveProvider: defaultDriveProvider,
            subscriptionStatus: defaultSubscriptionStatus
        )
    }

    init(
        localProvider: CloudBackupProvider,
        driveProvider: CloudBackupProvider,
        subscriptionStatus: SubscriptionStatusViewModel
    ) {
        self.localProvider = localProvider
        self.driveProvider = driveProvider
        self.subscriptionStatus = subscriptionStatus
    }

    var canUseGoogleDriveSync: Bool {
        subscriptionStatus.hasAccess(to: .googleDriveSync)
    }

    var cloudAccessMessageKey: String {
        canUseGoogleDriveSync ? "backup.drive.access.pro_unlocked" : "backup.drive.access.pro_required"
    }

    var latestExportFileName: String? {
        latestExport?.fileURL.lastPathComponent
    }

    var latestExportSummaryKey: String {
        guard latestExport != nil else { return "backup.export.none" }
        return "backup.export.ready"
    }

    func refresh() {
        Task { @MainActor in
            localAvailabilityMessageKey = (await localProvider.currentAvailability()).messageKey
            driveAvailabilityMessageKey = (await driveProvider.currentAvailability()).messageKey
            subscriptionStatus.refreshEntitlements()
        }
    }

    func createLocalBackup() {
        guard isPreparingBackup == false else { return }
        isPreparingBackup = true
        errorMessageKey = nil
        statusMessageKey = "backup.status.preparing"

        Task { @MainActor in
            do {
                let export = try await localProvider.createBackupPackage()
                latestExport = export
                statusMessageKey = export.manifest.encodingIssues.isEmpty
                    ? "backup.status.export_ready"
                    : "backup.status.export_ready_with_warnings"
            } catch let error as BackupPackageError {
                errorMessageKey = localizationKey(for: error)
                statusMessageKey = "backup.status.failed"
            } catch {
                errorMessageKey = "backup.error.generic"
                statusMessageKey = "backup.status.failed"
            }
            isPreparingBackup = false
        }
    }

    private func localizationKey(for error: BackupPackageError) -> String {
        switch error {
        case .unsupportedSchemaVersion:
            return "backup.error.unsupported_schema"
        case .packageEncodingFailed:
            return "backup.error.package_encoding"
        case .fileWriteFailed:
            return "backup.error.file_write"
        case .localBackupUnavailable:
            return "backup.error.local_unavailable"
        case .googleDriveUnavailable:
            return "backup.error.drive_unavailable"
        }
    }
}

@MainActor
func useBackupSync() -> BackupSyncViewModel {
    BackupSyncViewModel()
}
