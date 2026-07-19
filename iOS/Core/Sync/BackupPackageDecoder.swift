// [自主區] BackupPackageDecoder.swift
// 用途：讀取 Task-026a 本機備份檔並產生非破壞性還原預覽，不寫入 Core Data / UserDefaults。
// 委派至：LocalBackupProvider 與 useBackupSync；未來真正 restore 必須另走 Task-026b 後續確認流程。

import Foundation

struct BackupPackageDecoder: Sendable {
    func preview(from fileURL: URL) throws -> BackupRestorePreview {
        let data = try Data(contentsOf: fileURL)
        return try preview(from: data, sourceFileName: fileURL.lastPathComponent)
    }

    func preview(from data: Data, sourceFileName: String = "backup.skatetrack-backup.json") throws -> BackupRestorePreview {
        try validateRawHeader(from: data)
        let payload = try makeDecoder().decode(BackupPackagePayload.self, from: data)
        try BackupPackageManifest.validate(payload.manifest)
        return makePreview(from: payload, sourceFileName: sourceFileName)
    }

    private func validateRawHeader(from data: Data) throws {
        do {
            let raw = try makeDecoder().decode(RawBackupPackageHeader.self, from: data)
            guard raw.manifest.packageType == BackupPackageType.backup.rawValue else {
                throw BackupPackageError.unsupportedPackageType(raw.manifest.packageType)
            }
            guard BackupPackageManifest.supportedSchemaVersions.contains(raw.manifest.schemaVersion) else {
                throw BackupPackageError.unsupportedSchemaVersion(raw.manifest.schemaVersion)
            }
        } catch let error as BackupPackageError {
            throw error
        } catch {
            throw BackupPackageError.invalidBackupPackage
        }
    }

    private func makePreview(
        from payload: BackupPackagePayload,
        sourceFileName: String
    ) -> BackupRestorePreview {
        let sectionsByKey = Dictionary(uniqueKeysWithValues: payload.sections.map { ($0.storeKey, $0) })
        var stores: [BackupRestoreStorePreview] = []
        var issues = payload.manifest.encodingIssues.map {
            BackupRestoreValidationIssue(
                storeKey: BackupPackageStoreKey(rawValue: $0.storeKey),
                stage: $0.stage,
                message: $0.message
            )
        }

        for key in BackupPackageStoreKey.allCases {
            let expectedCount = manifestCount(for: key, manifest: payload.manifest)
            guard let section = sectionsByKey[key] else {
                stores.append(
                    BackupRestoreStorePreview(
                        storeKey: key,
                        expectedItemCount: expectedCount,
                        status: .missing,
                        message: "Section is missing from the backup payload."
                    )
                )
                issues.append(
                    BackupRestoreValidationIssue(
                        storeKey: key,
                        stage: "decode",
                        message: "Missing section: \(key.rawValue)"
                    )
                )
                continue
            }

            let storePreview = decodeSection(section, expectedCount: expectedCount, issues: &issues)
            stores.append(storePreview)
        }

        validateSnowSessions(in: payload, issues: &issues)

        return BackupRestorePreview(
            manifest: payload.manifest,
            stores: stores,
            validationIssues: issues,
            sourceFileName: sourceFileName,
            snowSessionCount: payload.snowSessions?.count
        )
    }

    private func decodeSection(
        _ section: BackupPackageSection,
        expectedCount: Int,
        issues: inout [BackupRestoreValidationIssue]
    ) -> BackupRestoreStorePreview {
        do {
            let decodedCount = try decodedItemCount(for: section)
            guard decodedCount == section.itemCount, decodedCount == expectedCount else {
                let message = "Decoded count \(decodedCount) does not match section count \(section.itemCount) or manifest count \(expectedCount)."
                issues.append(
                    BackupRestoreValidationIssue(
                        storeKey: section.storeKey,
                        stage: "decode",
                        message: message
                    )
                )
                return BackupRestoreStorePreview(
                    storeKey: section.storeKey,
                    expectedItemCount: expectedCount,
                    sectionItemCount: section.itemCount,
                    decodedItemCount: decodedCount,
                    status: .countMismatch,
                    message: message
                )
            }

            return BackupRestoreStorePreview(
                storeKey: section.storeKey,
                expectedItemCount: expectedCount,
                sectionItemCount: section.itemCount,
                decodedItemCount: decodedCount,
                status: .decoded
            )
        } catch {
            issues.append(
                BackupRestoreValidationIssue(
                    storeKey: section.storeKey,
                    stage: "decode",
                    message: error.localizedDescription
                )
            )
            return BackupRestoreStorePreview(
                storeKey: section.storeKey,
                expectedItemCount: expectedCount,
                sectionItemCount: section.itemCount,
                decodedItemCount: 0,
                status: .failed,
                message: error.localizedDescription
            )
        }
    }


    private func validateSnowSessions(
        in payload: BackupPackagePayload,
        issues: inout [BackupRestoreValidationIssue]
    ) {
        guard let snowSessions = payload.snowSessions else {
            return
        }

        if let expectedCount = payload.manifest.storeCounts.snowSessions, expectedCount != snowSessions.count {
            issues.append(
                BackupRestoreValidationIssue(
                    storeKey: nil,
                    stage: "decode",
                    message: "Decoded Snow session count \(snowSessions.count) does not match manifest count \(expectedCount)."
                )
            )
        }
    }

    private func decodedItemCount(for section: BackupPackageSection) throws -> Int {
        let data = Data(section.jsonString.utf8)
        switch section.storeKey {
        case .sessions:
            return try makeDecoder().decode([SessionData].self, from: data).count
        case .equipment:
            return try makeDecoder().decode([EquipmentProfile].self, from: data).count
        case .spots:
            return try makeDecoder().decode([SpotProfile].self, from: data).count
        case .achievements:
            return try makeDecoder().decode([AchievementUnlockRecord].self, from: data).count
        case .weeklyChallengeCompletions:
            return try makeDecoder().decode([WeeklyChallengeCompletionRecord].self, from: data).count
        }
    }

    private func manifestCount(
        for key: BackupPackageStoreKey,
        manifest: BackupPackageManifest
    ) -> Int {
        switch key {
        case .sessions:
            return manifest.storeCounts.sessions
        case .equipment:
            return manifest.storeCounts.equipment
        case .spots:
            return manifest.storeCounts.spots
        case .achievements:
            return manifest.storeCounts.achievements
        case .weeklyChallengeCompletions:
            return manifest.storeCounts.weeklyChallengeCompletions
        }
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private struct RawBackupPackageHeader: Decodable {
    let manifest: RawBackupManifestHeader
}

private struct RawBackupManifestHeader: Decodable {
    let packageType: String
    let schemaVersion: Int
}
