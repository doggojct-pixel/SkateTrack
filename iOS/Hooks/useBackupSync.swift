// [協作區 — 邊界適配層] useBackupSync.swift
// 用途：向 SwiftUI Views 暴露本機備份、還原預覽與 Google Drive disabled 狀態，隱藏 provider / repository 細節。
// 委派至：BackupSyncSettingsView；View 不直接碰 provider、Core Data 或 Google Drive API。

import SwiftUI

@MainActor
final class BackupSyncViewModel: ObservableObject {
    @Published private(set) var isPreparingBackup = false
    @Published private(set) var isPreparingRestorePreview = false
    @Published private(set) var latestExport: BackupPackageExportResult?
    @Published private(set) var restorePreview: BackupRestorePreview?
    @Published private(set) var localAvailabilityMessageKey = "backup.status.available"
    @Published private(set) var driveAvailabilityMessageKey = "backup.drive.status.checking"
    @Published private(set) var statusMessageKey = "backup.status.ready"
    @Published private(set) var restorePreviewMessageKey = "backup.restore.preview.status.empty"
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var restorePreviewErrorMessageKey: String?

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

    var restorePreviewFileName: String? {
        restorePreview?.sourceFileName
    }

    var restorePreviewSummaryKey: String {
        guard let restorePreview else { return restorePreviewMessageKey }
        return restorePreview.hasValidationIssues
            ? "backup.restore.preview.status.ready_with_warnings"
            : "backup.restore.preview.status.ready"
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

    func previewRestorePackage(from fileURL: URL) {
        guard isPreparingRestorePreview == false else { return }
        isPreparingRestorePreview = true
        restorePreview = nil
        restorePreviewErrorMessageKey = nil
        restorePreviewMessageKey = "backup.restore.preview.status.checking"

        Task { @MainActor in
            let didAccess = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let preview = try await localProvider.previewRestorePackage(from: fileURL)
                restorePreview = preview
                restorePreviewMessageKey = preview.hasValidationIssues
                    ? "backup.restore.preview.status.ready_with_warnings"
                    : "backup.restore.preview.status.ready"
            } catch let error as BackupPackageError {
                restorePreviewErrorMessageKey = localizationKey(for: error)
                restorePreviewMessageKey = "backup.restore.preview.status.failed"
            } catch {
                restorePreviewErrorMessageKey = "backup.restore.error.preview_failed"
                restorePreviewMessageKey = "backup.restore.preview.status.failed"
            }
            isPreparingRestorePreview = false
        }
    }

    func handleRestoreImporterFailure() {
        restorePreview = nil
        restorePreviewErrorMessageKey = "backup.restore.error.file_import"
        restorePreviewMessageKey = "backup.restore.preview.status.failed"
    }

    func clearRestorePreview() {
        restorePreview = nil
        restorePreviewErrorMessageKey = nil
        restorePreviewMessageKey = "backup.restore.preview.status.empty"
    }

    private func localizationKey(for error: BackupPackageError) -> String {
        switch error {
        case .unsupportedSchemaVersion:
            return "backup.error.unsupported_schema"
        case .unsupportedPackageType:
            return "backup.restore.error.unsupported_package_type"
        case .invalidBackupPackage:
            return "backup.restore.error.invalid_package"
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
