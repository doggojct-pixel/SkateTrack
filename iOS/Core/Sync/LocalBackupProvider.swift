// [自主區] LocalBackupProvider.swift
// 用途：建立 user-initiated 本機備份檔，不執行 Google Drive upload / download / restore。
// 委派至：useBackupSync；未來 Drive provider 必須替換 provider boundary，不可繞過 hook。

import Foundation

final class LocalBackupProvider: CloudBackupProvider, @unchecked Sendable {
    static let shared = LocalBackupProvider()

    let kind: CloudBackupProviderKind = .localPackage

    private let sessionRepository: SessionRepositoryProtocol
    private let equipmentRepository: EquipmentRepositoryProtocol
    private let spotRepository: SpotRepositoryProtocol
    private let achievementStore: AchievementUnlockStoring
    private let weeklyChallengeStore: WeeklyChallengeCompletionStoring
    private let fileManager: FileManager
    private let exportDirectory: URL

    init(
        sessionRepository: SessionRepositoryProtocol = SessionRepository.shared,
        equipmentRepository: EquipmentRepositoryProtocol = EquipmentRepository.shared,
        spotRepository: SpotRepositoryProtocol = SpotRepository.shared,
        achievementStore: AchievementUnlockStoring = AchievementUnlockStore.shared,
        weeklyChallengeStore: WeeklyChallengeCompletionStoring = WeeklyChallengeCompletionStore.shared,
        fileManager: FileManager = .default,
        exportDirectory: URL = LocalBackupProvider.defaultExportDirectory()
    ) {
        self.sessionRepository = sessionRepository
        self.equipmentRepository = equipmentRepository
        self.spotRepository = spotRepository
        self.achievementStore = achievementStore
        self.weeklyChallengeStore = weeklyChallengeStore
        self.fileManager = fileManager
        self.exportDirectory = exportDirectory
    }

    func currentAvailability() async -> CloudBackupAvailability {
        .available
    }

    func createBackupPackage() async throws -> BackupPackageExportResult {
        let input = await collectBackupInput()
        let encoded = try BackupPackageEncoder().encode(input)
        let fileURL = exportDirectory.appendingPathComponent(fileName(for: encoded.payload.manifest.createdAt))

        do {
            try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
            try encoded.data.write(to: fileURL, options: .atomic)
            return BackupPackageExportResult(
                fileURL: fileURL,
                manifest: encoded.payload.manifest,
                byteCount: encoded.data.count
            )
        } catch {
            throw BackupPackageError.fileWriteFailed
        }
    }

    func previewRestorePackage(from fileURL: URL) async throws -> BackupRestorePreview {
        try BackupPackageDecoder().preview(from: fileURL)
    }

    static func defaultExportDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SkateTrackBackup", isDirectory: true)
    }

    private func collectBackupInput() async -> BackupPackageEncodingInput {
        let sessionResult = await loadStore(.sessions) {
            try await sessionRepository.fetchRecentSessions(limit: Int.max)
        }
        let equipmentResult = await loadStore(.equipment) {
            try await equipmentRepository.fetchEquipment()
        }
        let spotResult = await loadStore(.spots) {
            try await spotRepository.fetchSpots()
        }

        var issues = sessionResult.issues + equipmentResult.issues + spotResult.issues
        let achievements = achievementStore.loadRecords().values.sorted { $0.unlockedAt < $1.unlockedAt }
        let weeklyRecords = weeklyChallengeStore.loadRecords().values.sorted { $0.completedAt < $1.completedAt }

        if achievements.isEmpty == false || weeklyRecords.isEmpty == false {
            issues.append(contentsOf: [])
        }

        return BackupPackageEncodingInput(
            sessions: sessionResult.value,
            equipment: equipmentResult.value,
            spots: spotResult.value,
            achievements: achievements,
            weeklyChallengeCompletions: weeklyRecords,
            preflightIssues: issues
        )
    }

    private func loadStore<T: Sendable>(
        _ key: BackupPackageStoreKey,
        operation: () async throws -> [T]
    ) async -> (value: [T], issues: [BackupPackageStoreIssue]) {
        do {
            return (try await operation(), [])
        } catch {
            return (
                [],
                [BackupPackageStoreIssue(storeKey: key.rawValue, stage: "fetch", message: error.localizedDescription)]
            )
        }
    }

    private func fileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "SkateTrack-Backup-\(formatter.string(from: date)).skatetrack-backup.json"
    }
}
