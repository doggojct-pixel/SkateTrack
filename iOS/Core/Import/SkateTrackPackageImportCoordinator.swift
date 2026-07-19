// [自主區] iOS/Core/Import/SkateTrackPackageImportCoordinator.swift
// 用途：處理 Task-030d .skatetrack 多檔 staging、驗證、重複偵測與安全提交。
// 委派至：Shared package reader 與 SessionRepository；不合併、不覆寫、不改 schema / route / trusted metrics。

import Foundation

struct SkateTrackPackageImportCoordinator {
    private let fileManager: FileManager
    private let reader: SkateTrackPackageReader
    private let repository: SessionRepositoryProtocol
    private let snowRepository: SnowSessionRepositoryProtocol
    private let stagingRootURL: URL

    init(
        fileManager: FileManager = .default,
        reader: SkateTrackPackageReader = SkateTrackPackageReader(),
        repository: SessionRepositoryProtocol = SessionRepository.shared,
        snowRepository: SnowSessionRepositoryProtocol = SnowSessionRepository.shared,
        stagingRootURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.reader = reader
        self.repository = repository
        self.snowRepository = snowRepository
        self.stagingRootURL = stagingRootURL
            ?? fileManager.temporaryDirectory.appendingPathComponent("SkateTrackImportStaging", isDirectory: true)
    }

    func validatePackages(from urls: [URL]) async -> [SkateTrackImportCandidate] {
        guard !urls.isEmpty else { return [] }
        cleanupStagingDirectory()
        createStagingDirectoryIfNeeded()

        var candidates: [SkateTrackImportCandidate] = []
        for url in urls {
            let candidate = await validateSinglePackage(from: url)
            candidates.append(candidate)
        }
        return await applyingDuplicateClassifications(to: candidates)
    }

    func commitSelectedPackages(
        candidates: [SkateTrackImportCandidate],
        selectedCandidateIDs: Set<UUID>
    ) async -> [SkateTrackImportCommitResult] {
        var results: [SkateTrackImportCommitResult] = []
        let selectedCandidates = candidates.filter { selectedCandidateIDs.contains($0.id) }

        for candidate in selectedCandidates {
            guard candidate.isImportable, let package = candidate.package else {
                results.append(commitResult(candidate, status: .failed, detailKey: "import.error.missingPayload", importedCount: 0))
                continue
            }

            let alreadyExists = await sessionExists(in: package.sessions.map { $0.session.id })
            guard alreadyExists == false else {
                results.append(commitResult(candidate, status: .skippedDuplicate, detailKey: "import.commit.skippedDuplicate", importedCount: 0))
                continue
            }

            do {
                try validateSnowPayloads(in: package)
                try await commit(package: package)
                results.append(
                    commitResult(
                        candidate,
                        status: .imported,
                        detailKey: "import.commit.imported",
                        importedCount: package.sessions.count
                    )
                )
            } catch let error as SnowPackageImportError {
                results.append(commitResult(candidate, status: .failed, detailKey: error.detailKey, importedCount: 0))
            } catch {
                results.append(commitResult(candidate, status: .failed, detailKey: "import.error.commitFailed", importedCount: 0))
            }
        }

        return results
    }

    func cleanupStagingDirectory() {
        try? fileManager.removeItem(at: stagingRootURL)
    }

    private func validateSinglePackage(from url: URL) async -> SkateTrackImportCandidate {
        let displayName = url.lastPathComponent
        let pathKey = url.standardizedFileURL.path

        guard url.pathExtension.lowercased() == "skatetrack" else {
            return invalidCandidate(displayName, pathKey: pathKey, status: .missingRequiredFiles, reason: .wrongFileExtension)
        }

        let canReadWithoutScope = fileManager.isReadableFile(atPath: url.path)
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        guard didAccess || canReadWithoutScope else {
            return invalidCandidate(displayName, pathKey: pathKey, status: .securityScopedAccessFailed, reason: .securityScopedAccessFailed)
        }

        guard let stagedURL = copyToStaging(url: url) else {
            return invalidCandidate(displayName, pathKey: pathKey, status: .stagingCopyFailed, reason: .stagingCopyFailed)
        }

        do {
            let package = try reader.readPackage(from: stagedURL)
            try validateSnowPayloads(in: package)
            let sessions = package.sessions
            let sessionIDs = sessions.map { $0.session.id }
            let startDates = sessions.map { $0.session.startDate }
            let endDates = sessions.map { $0.session.endDate ?? $0.session.startDate }
            return SkateTrackImportCandidate(
                sourceDisplayName: displayName,
                sourcePathKey: pathKey,
                stagedURL: stagedURL,
                validationStatus: .ready,
                failureReason: .none,
                manifest: package.manifest,
                package: package,
                sessionIDs: sessionIDs,
                sessionCount: sessions.count,
                dateRangeStart: startDates.min(),
                dateRangeEnd: endDates.max()
            )
        } catch let error as SkateTrackPackageError {
            let mapped = mapPackageError(error)
            return invalidCandidate(displayName, pathKey: pathKey, status: mapped.status, reason: mapped.reason, stagedURL: stagedURL)
        } catch is SnowPackageImportError {
            return invalidCandidate(
                displayName,
                pathKey: pathKey,
                status: .importBlocked,
                reason: .invalidSnowPayload,
                stagedURL: stagedURL
            )
        } catch {
            return invalidCandidate(displayName, pathKey: pathKey, status: .corruptedPackage, reason: .packageDecodingFailed, stagedURL: stagedURL)
        }
    }

    private func applyingDuplicateClassifications(
        to candidates: [SkateTrackImportCandidate]
    ) async -> [SkateTrackImportCandidate] {
        let pathCounts = Dictionary(grouping: candidates, by: \.sourcePathKey).mapValues(\.count)
        let sessionIDCounts = Dictionary(grouping: candidates.flatMap(\.sessionIDs), by: { $0 }).mapValues(\.count)
        let existingFingerprints = await loadExistingFingerprints()
        var classified: [SkateTrackImportCandidate] = []

        for candidate in candidates {
            guard candidate.validationStatus == .ready else {
                classified.append(candidate)
                continue
            }
            if pathCounts[candidate.sourcePathKey, default: 0] > 1 {
                classified.append(candidate.replacing(status: .duplicateCandidate, reason: .duplicateInBatch))
                continue
            }
            if candidate.sessionIDs.contains(where: { sessionIDCounts[$0, default: 0] > 1 }) {
                classified.append(candidate.replacing(status: .duplicateCandidate, reason: .duplicateInBatch))
                continue
            }
            if await sessionExists(in: candidate.sessionIDs) {
                classified.append(candidate.replacing(status: .alreadyImported, reason: .alreadyImported))
                continue
            }
            if candidateFingerprints(candidate).contains(where: { existingFingerprints.contains($0) }) {
                classified.append(candidate.replacing(status: .duplicateCandidate, reason: .duplicateCandidate))
                continue
            }
            classified.append(candidate)
        }

        return classified
    }

    private func copyToStaging(url: URL) -> URL? {
        let destination = stagingRootURL
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("skatetrack")
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    private func createStagingDirectoryIfNeeded() {
        try? fileManager.createDirectory(at: stagingRootURL, withIntermediateDirectories: true)
    }

    private func invalidCandidate(
        _ displayName: String,
        pathKey: String,
        status: SkateTrackImportValidationStatus,
        reason: SkateTrackImportFailureReason,
        stagedURL: URL? = nil
    ) -> SkateTrackImportCandidate {
        SkateTrackImportCandidate(
            sourceDisplayName: displayName,
            sourcePathKey: pathKey,
            stagedURL: stagedURL,
            validationStatus: status,
            failureReason: reason
        )
    }

    private func mapPackageError(
        _ error: SkateTrackPackageError
    ) -> (status: SkateTrackImportValidationStatus, reason: SkateTrackImportFailureReason) {
        switch error {
        case .unsupportedSchemaVersion:
            return (.unsupportedVersion, .unsupportedSchemaVersion)
        case .unsupportedPackageType:
            return (.invalidManifest, .unsupportedPackageType)
        case .accountDataNotAllowed:
            return (.invalidManifest, .accountDataNotAllowed)
        case .achievementsNotAllowed:
            return (.invalidManifest, .achievementsNotAllowed)
        case .emptySessionExport:
            return (.emptyPackage, .emptyPackage)
        case .packageDecodingFailed:
            return (.corruptedPackage, .packageDecodingFailed)
        case .fileReadFailed:
            return (.corruptedPackage, .fileReadFailed)
        case .packageEncodingFailed, .fileWriteFailed:
            return (.importBlocked, .commitFailed)
        }
    }

    private func sessionExists(in sessionIDs: [UUID]) async -> Bool {
        for sessionID in sessionIDs {
            if (try? await repository.fetchSession(id: sessionID)) != nil {
                return true
            }
        }
        return false
    }

    private func sessionForImport(from packageSession: SkateTrackPackageSession) throws -> SessionData {
        let session = packageSession.session
        guard session.motionSamples.isEmpty, packageSession.motionSamples.isEmpty == false else {
            return session
        }
        return try SessionData(
            id: session.id,
            startDate: session.startDate,
            endDate: session.endDate,
            sportMode: session.sportMode,
            powerType: session.powerType,
            motionSamples: packageSession.motionSamples,
            trickEvents: session.trickEvents,
            fallEvents: session.fallEvents,
            summaryMetrics: session.summaryMetrics,
            routeQualitySummary: session.routeQualitySummary,
            fidelityProfile: session.fidelityProfile,
            debugRecordingDiagnostics: session.debugRecordingDiagnostics,
            equipmentID: session.equipmentID,
            equipmentSnapshot: session.equipmentSnapshot,
            spotID: session.spotID,
            spotSnapshot: session.spotSnapshot
        )
    }

    private func commit(package: SkateTrackPackagePayload) async throws {
        var importedSessionIDs: [UUID] = []
        do {
            for packageSession in package.sessions {
                let session = try sessionForImport(from: packageSession)
                _ = try await repository.saveCompletedSession(session)
                importedSessionIDs.append(session.id)
                try await persistSnowPayloadIfPresent(packageSession.snowPayload)
            }
        } catch {
            await rollbackImportedSessions(importedSessionIDs)
            throw error
        }
    }

    private func persistSnowPayloadIfPresent(
        _ payload: SkateTrackPackageSnowPayload?
    ) async throws {
        guard let payload else { return }
        do {
            for run in payload.runs {
                _ = try await snowRepository.saveRun(run)
            }
            for segment in payload.segments {
                _ = try await snowRepository.saveSegment(segment)
            }
        } catch {
            throw SnowPackageImportError.snowPersistenceFailed
        }
    }

    private func rollbackImportedSessions(_ sessionIDs: [UUID]) async {
        for sessionID in sessionIDs.reversed() {
            try? await snowRepository.deleteSnowData(sessionID: sessionID)
            try? await repository.deleteSession(id: sessionID)
        }
    }

    private func validateSnowPayloads(in package: SkateTrackPackagePayload) throws {
        for packageSession in package.sessions {
            guard let payload = packageSession.snowPayload else { continue }
            guard case .snow = packageSession.session.sportMode,
                  payload.payloadVersion == SkateTrackPackageSnowPayload.currentPayloadVersion,
                  payload.sessionID == packageSession.session.id,
                  payload.runs.allSatisfy({ $0.sessionID == packageSession.session.id }),
                  payload.segments.allSatisfy({ $0.sessionID == packageSession.session.id }) else {
                throw SnowPackageImportError.invalidPayload
            }

            let runIDs = Set(payload.runs.map(\.id))
            let segmentIDs = Set(payload.segments.map(\.id))
            guard runIDs.count == payload.runs.count,
                  segmentIDs.count == payload.segments.count,
                  Set(payload.runs.map(\.runNumber)).count == payload.runs.count,
                  payload.segments.allSatisfy({ $0.runID == nil || runIDs.contains($0.runID!) }),
                  payload.runs.allSatisfy({ Set($0.segmentIDs).isSubset(of: segmentIDs) }) else {
                throw SnowPackageImportError.invalidPayload
            }
        }
    }

    private func commitResult(
        _ candidate: SkateTrackImportCandidate,
        status: SkateTrackImportCommitStatus,
        detailKey: String,
        importedCount: Int
    ) -> SkateTrackImportCommitResult {
        SkateTrackImportCommitResult(
            candidateID: candidate.id,
            sourceDisplayName: candidate.sourceDisplayName,
            status: status,
            detailKey: detailKey,
            importedSessionCount: importedCount
        )
    }

    private func loadExistingFingerprints() async -> Set<SkateTrackImportSessionFingerprint> {
        let sessions = (try? await repository.fetchRecentSessions(limit: 10_000)) ?? []
        return Set(sessions.map(SkateTrackImportSessionFingerprint.init(session:)))
    }

    private func candidateFingerprints(_ candidate: SkateTrackImportCandidate) -> [SkateTrackImportSessionFingerprint] {
        candidate.package?.sessions.map { SkateTrackImportSessionFingerprint(session: $0.session) } ?? []
    }
}

private enum SnowPackageImportError: Error {
    case invalidPayload
    case snowPersistenceFailed

    var detailKey: String {
        switch self {
        case .invalidPayload:
            return "import.error.invalidSnowPayload"
        case .snowPersistenceFailed:
            return "import.error.snowPersistenceFailed"
        }
    }
}

private struct SkateTrackImportSessionFingerprint: Hashable {
    let sportKey: String
    let startTimeSeconds: Int
    let durationSeconds: Int
    let distanceBucket: Int

    init(session: SessionData) {
        sportKey = session.sportMode.modeLocalizationKey
        startTimeSeconds = Int(session.startDate.timeIntervalSince1970.rounded())
        durationSeconds = Int((session.durationSeconds ?? 0).rounded())
        distanceBucket = Int(((session.summaryMetrics?.distanceKilometers ?? 0) * 1_000).rounded())
    }
}
