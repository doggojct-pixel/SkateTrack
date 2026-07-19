// [自主區] BackupPackageEncoder.swift
// 用途：將 domain models 獨立 encode 成 backup sections，不直接碰 Core Data / NSManagedObject。
// 委派至：LocalBackupProvider 取得資料後建立本機備份檔。

import Foundation

struct BackupPackageEncodingInput: Sendable {
    let sessions: [SessionData]
    let equipment: [EquipmentProfile]
    let spots: [SpotProfile]
    let achievements: [AchievementUnlockRecord]
    let weeklyChallengeCompletions: [WeeklyChallengeCompletionRecord]
    let snowSessions: [SnowBackupSession]?
    let preflightIssues: [BackupPackageStoreIssue]

    init(
        sessions: [SessionData] = [],
        equipment: [EquipmentProfile] = [],
        spots: [SpotProfile] = [],
        achievements: [AchievementUnlockRecord] = [],
        weeklyChallengeCompletions: [WeeklyChallengeCompletionRecord] = [],
        snowSessions: [SnowBackupSession]? = [],
        preflightIssues: [BackupPackageStoreIssue] = []
    ) {
        self.sessions = sessions
        self.equipment = equipment
        self.spots = spots
        self.achievements = achievements
        self.weeklyChallengeCompletions = weeklyChallengeCompletions
        self.snowSessions = snowSessions
        self.preflightIssues = preflightIssues
    }
}

struct BackupPackageEncodingResult: Sendable {
    let payload: BackupPackagePayload
    let data: Data
}

struct BackupPackageEncoder {
    private let appVersion: String
    private let buildNumber: String
    private let localeIdentifier: String
    private let date: Date

    init(
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0",
        buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0",
        localeIdentifier: String = Locale.current.identifier,
        date: Date = Date()
    ) {
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.localeIdentifier = localeIdentifier
        self.date = date
    }

    func encode(_ input: BackupPackageEncodingInput) throws -> BackupPackageEncodingResult {
        var issues = input.preflightIssues
        var sections: [BackupPackageSection] = []

        encodeSection(input.sessions, key: .sessions, issues: &issues, sections: &sections)
        encodeSection(input.equipment, key: .equipment, issues: &issues, sections: &sections)
        encodeSection(input.spots, key: .spots, issues: &issues, sections: &sections)
        encodeSection(input.achievements, key: .achievements, issues: &issues, sections: &sections)
        encodeSection(input.weeklyChallengeCompletions, key: .weeklyChallengeCompletions, issues: &issues, sections: &sections)

        let manifest = BackupPackageManifest(
            appVersion: appVersion,
            buildNumber: buildNumber,
            createdAt: date,
            localeIdentifier: localeIdentifier,
            storeCounts: BackupPackageStoreCounts(
                sessions: input.sessions.count,
                equipment: input.equipment.count,
                spots: input.spots.count,
                achievements: input.achievements.count,
                weeklyChallengeCompletions: input.weeklyChallengeCompletions.count,
                snowSessions: input.snowSessions?.count
            ),
            encodingIssues: issues
        )
        let payload = BackupPackagePayload(manifest: manifest, sections: sections, snowSessions: input.snowSessions)
        let encoder = makeEncoder()
        do {
            return BackupPackageEncodingResult(payload: payload, data: try encoder.encode(payload))
        } catch {
            throw BackupPackageError.packageEncodingFailed
        }
    }

    private func encodeSection<T: Encodable>(
        _ items: [T],
        key: BackupPackageStoreKey,
        issues: inout [BackupPackageStoreIssue],
        sections: inout [BackupPackageSection]
    ) {
        do {
            let data = try makeEncoder().encode(items)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                issues.append(issue(for: key, stage: "encode", errorDescription: "UTF-8 conversion failed"))
                return
            }
            sections.append(BackupPackageSection(storeKey: key, jsonString: jsonString, itemCount: items.count))
        } catch {
            issues.append(issue(for: key, stage: "encode", errorDescription: error.localizedDescription))
        }
    }

    private func issue(
        for key: BackupPackageStoreKey,
        stage: String,
        errorDescription: String
    ) -> BackupPackageStoreIssue {
        BackupPackageStoreIssue(storeKey: key.rawValue, stage: stage, message: errorDescription)
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
