// [協作區] iOS/Core/Import/SkateTrackPackageImportModels.swift
// 用途：定義 Task-030d iOS 多檔 .skatetrack 匯入驗證、預覽與提交結果模型。
// 委派至：SkateTrackPackageImportCoordinator 與 useSkateTrackPackageImport；不改變 package schema。

import Foundation

enum SkateTrackImportValidationStatus: String, CaseIterable, Sendable, Equatable {
    case ready
    case alreadyImported
    case duplicateCandidate
    case unsupportedVersion
    case corruptedPackage
    case missingRequiredFiles
    case invalidManifest
    case checksumMismatch
    case importBlocked
    case needsReview
    case securityScopedAccessFailed
    case stagingCopyFailed
    case emptyPackage

    var localizationKey: String {
        switch self {
        case .ready:
            return "import.status.ready"
        case .alreadyImported:
            return "import.status.alreadyImported"
        case .duplicateCandidate:
            return "import.status.duplicateCandidate"
        case .unsupportedVersion:
            return "import.status.unsupportedVersion"
        case .corruptedPackage:
            return "import.status.corruptedPackage"
        case .missingRequiredFiles:
            return "import.status.missingRequiredFiles"
        case .invalidManifest:
            return "import.status.invalidManifest"
        case .checksumMismatch:
            return "import.status.checksumMismatch"
        case .importBlocked:
            return "import.status.blocked"
        case .needsReview:
            return "import.status.needsReview"
        case .securityScopedAccessFailed:
            return "import.status.permissionDenied"
        case .stagingCopyFailed:
            return "import.status.stagingFailed"
        case .emptyPackage:
            return "import.status.emptyPackage"
        }
    }

    var isImportable: Bool {
        self == .ready
    }
}

enum SkateTrackImportFailureReason: String, Sendable, Equatable {
    case none
    case wrongFileExtension
    case securityScopedAccessFailed
    case stagingCopyFailed
    case fileReadFailed
    case packageDecodingFailed
    case unsupportedSchemaVersion
    case unsupportedPackageType
    case accountDataNotAllowed
    case achievementsNotAllowed
    case emptyPackage
    case duplicateInBatch
    case alreadyImported
    case duplicateCandidate
    case missingPayload
    case commitFailed

    var localizationKey: String {
        switch self {
        case .none:
            return "import.detail.ready"
        case .wrongFileExtension:
            return "import.error.invalidExtension"
        case .securityScopedAccessFailed:
            return "import.status.permissionDenied"
        case .stagingCopyFailed:
            return "import.status.stagingFailed"
        case .fileReadFailed:
            return "import.error.fileReadFailed"
        case .packageDecodingFailed:
            return "import.error.packageDecodingFailed"
        case .unsupportedSchemaVersion:
            return "import.status.unsupportedVersion"
        case .unsupportedPackageType:
            return "import.error.unsupportedPackageType"
        case .accountDataNotAllowed:
            return "import.error.accountDataNotAllowed"
        case .achievementsNotAllowed:
            return "import.error.achievementsNotAllowed"
        case .emptyPackage:
            return "import.status.emptyPackage"
        case .duplicateInBatch:
            return "import.detail.duplicateInBatch"
        case .alreadyImported:
            return "import.status.alreadyImported"
        case .duplicateCandidate:
            return "import.status.duplicateCandidate"
        case .missingPayload:
            return "import.error.missingPayload"
        case .commitFailed:
            return "import.error.commitFailed"
        }
    }
}

struct SkateTrackImportCandidate: Identifiable, Equatable, Sendable {
    let id: UUID
    let sourceDisplayName: String
    let sourcePathKey: String
    let stagedURL: URL?
    let validationStatus: SkateTrackImportValidationStatus
    let failureReason: SkateTrackImportFailureReason
    let manifest: SkateTrackPackageManifest?
    let package: SkateTrackPackagePayload?
    let sessionIDs: [UUID]
    let sessionCount: Int
    let dateRangeStart: Date?
    let dateRangeEnd: Date?

    init(
        id: UUID = UUID(),
        sourceDisplayName: String,
        sourcePathKey: String,
        stagedURL: URL? = nil,
        validationStatus: SkateTrackImportValidationStatus,
        failureReason: SkateTrackImportFailureReason,
        manifest: SkateTrackPackageManifest? = nil,
        package: SkateTrackPackagePayload? = nil,
        sessionIDs: [UUID] = [],
        sessionCount: Int = 0,
        dateRangeStart: Date? = nil,
        dateRangeEnd: Date? = nil
    ) {
        self.id = id
        self.sourceDisplayName = sourceDisplayName
        self.sourcePathKey = sourcePathKey
        self.stagedURL = stagedURL
        self.validationStatus = validationStatus
        self.failureReason = failureReason
        self.manifest = manifest
        self.package = package
        self.sessionIDs = sessionIDs
        self.sessionCount = max(0, sessionCount)
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
    }

    var isImportable: Bool {
        validationStatus.isImportable && package != nil
    }

    var detailLocalizationKey: String {
        failureReason.localizationKey
    }

    func replacing(
        status: SkateTrackImportValidationStatus,
        reason: SkateTrackImportFailureReason
    ) -> SkateTrackImportCandidate {
        SkateTrackImportCandidate(
            id: id,
            sourceDisplayName: sourceDisplayName,
            sourcePathKey: sourcePathKey,
            stagedURL: stagedURL,
            validationStatus: status,
            failureReason: reason,
            manifest: manifest,
            package: package,
            sessionIDs: sessionIDs,
            sessionCount: sessionCount,
            dateRangeStart: dateRangeStart,
            dateRangeEnd: dateRangeEnd
        )
    }
}

struct SkateTrackImportBatchSummary: Equatable, Sendable {
    let totalCount: Int
    let readyCount: Int
    let alreadyImportedCount: Int
    let duplicateCandidateCount: Int
    let blockedCount: Int

    init(candidates: [SkateTrackImportCandidate]) {
        totalCount = candidates.count
        readyCount = candidates.filter { $0.validationStatus == .ready }.count
        alreadyImportedCount = candidates.filter { $0.validationStatus == .alreadyImported }.count
        duplicateCandidateCount = candidates.filter { $0.validationStatus == .duplicateCandidate }.count
        blockedCount = candidates.filter { !$0.validationStatus.isImportable }.count
    }
}

enum SkateTrackImportCommitStatus: String, Sendable, Equatable {
    case imported
    case skippedDuplicate
    case failed

    var localizationKey: String {
        switch self {
        case .imported:
            return "import.commit.status.imported"
        case .skippedDuplicate:
            return "import.commit.status.skippedDuplicate"
        case .failed:
            return "import.commit.status.failed"
        }
    }
}

struct SkateTrackImportCommitResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let candidateID: UUID
    let sourceDisplayName: String
    let status: SkateTrackImportCommitStatus
    let detailKey: String
    let importedSessionCount: Int

    init(
        id: UUID = UUID(),
        candidateID: UUID,
        sourceDisplayName: String,
        status: SkateTrackImportCommitStatus,
        detailKey: String,
        importedSessionCount: Int
    ) {
        self.id = id
        self.candidateID = candidateID
        self.sourceDisplayName = sourceDisplayName
        self.status = status
        self.detailKey = detailKey
        self.importedSessionCount = max(0, importedSessionCount)
    }
}

struct SkateTrackImportCommitSummary: Equatable, Sendable {
    let totalSelectedCount: Int
    let importedPackageCount: Int
    let importedSessionCount: Int
    let skippedCount: Int
    let failedCount: Int

    init(results: [SkateTrackImportCommitResult]) {
        totalSelectedCount = results.count
        importedPackageCount = results.filter { $0.status == .imported }.count
        importedSessionCount = results.reduce(0) { $0 + $1.importedSessionCount }
        skippedCount = results.filter { $0.status == .skippedDuplicate }.count
        failedCount = results.filter { $0.status == .failed }.count
    }
}
