// [協作區] Tests/iOSTests/SkateTrackPackageImportTests.swift
// 用途：驗證 Task-030d iOS 多檔 .skatetrack 匯入驗證、重複偵測與安全提交。

import XCTest
@testable import SkateTrack_iOS

final class SkateTrackPackageImportTests: XCTestCase {
    func testValidMultiplePackagesAreReadyAndSelected() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = ImportFixtureRepository()
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: repository,
            stagingRootURL: root.appendingPathComponent("staging", isDirectory: true)
        )
        let packageA = try writePackage(sessionID: UUID(), fileName: "a.skatetrack", root: root)
        let packageB = try writePackage(sessionID: UUID(), fileName: "b.skatetrack", root: root)

        let candidates = await coordinator.validatePackages(from: [packageA, packageB])

        XCTAssertEqual(candidates.count, 2)
        XCTAssertTrue(candidates.allSatisfy { $0.validationStatus == .ready })
        XCTAssertTrue(candidates.allSatisfy(\.isImportable))
    }

    func testInvalidExtensionIsBlockedBeforeDecode() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("not-a-package.json")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: url)
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: ImportFixtureRepository(),
            stagingRootURL: root.appendingPathComponent("staging", isDirectory: true)
        )

        let candidates = await coordinator.validatePackages(from: [url])

        XCTAssertEqual(candidates.first?.validationStatus, .missingRequiredFiles)
        XCTAssertEqual(candidates.first?.failureReason, .wrongFileExtension)
    }

    func testDuplicateSessionInBatchNeedsReviewAndDoesNotImport() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sessionID = UUID()
        let packageA = try writePackage(sessionID: sessionID, fileName: "a.skatetrack", root: root)
        let packageB = try writePackage(sessionID: sessionID, fileName: "b.skatetrack", root: root)
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: ImportFixtureRepository(),
            stagingRootURL: root.appendingPathComponent("staging", isDirectory: true)
        )

        let candidates = await coordinator.validatePackages(from: [packageA, packageB])

        XCTAssertEqual(candidates.count, 2)
        XCTAssertTrue(candidates.allSatisfy { $0.validationStatus == .duplicateCandidate })
        XCTAssertTrue(candidates.allSatisfy { !$0.isImportable })
    }

    func testExistingSessionIsAlreadyImported() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sessionID = UUID()
        let existingSession = try makeSession(id: sessionID)
        let repository = ImportFixtureRepository(existingSessions: [existingSession])
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: repository,
            stagingRootURL: root.appendingPathComponent("staging", isDirectory: true)
        )
        let package = try writePackage(sessionID: sessionID, fileName: "existing.skatetrack", root: root)

        let candidates = await coordinator.validatePackages(from: [package])

        XCTAssertEqual(candidates.first?.validationStatus, .alreadyImported)
        XCTAssertFalse(candidates.first?.isImportable ?? true)
    }

    func testCommitImportsReadyPackageWithoutOverwritingExisting() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = ImportFixtureRepository()
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: repository,
            stagingRootURL: root.appendingPathComponent("staging", isDirectory: true)
        )
        let package = try writePackage(sessionID: UUID(), fileName: "ready.skatetrack", root: root)
        let candidates = await coordinator.validatePackages(from: [package])
        let candidateID = try XCTUnwrap(candidates.first?.id)

        let results = await coordinator.commitSelectedPackages(candidates: candidates, selectedCandidateIDs: [candidateID])

        XCTAssertEqual(results.first?.status, .imported)
        XCTAssertEqual(repository.savedSessions.count, 1)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("Task030dImportTests_\(UUID().uuidString)", isDirectory: true)
    }

    private func writePackage(sessionID: UUID, fileName: String, root: URL) throws -> URL {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let session = try makeSession(id: sessionID)
        let packageSession = SkateTrackPackageSession(session: session, motionSamples: session.motionSamples)
        let manifest = SkateTrackPackageManifest(
            appVersion: "test",
            buildNumber: "1",
            localeIdentifier: "en_US",
            sessionCount: 1,
            includesMotionSamples: true
        )
        let payload = try SkateTrackPackagePayload(manifest: manifest, sessions: [packageSession])
        let url = root.appendingPathComponent(fileName)
        _ = try SkateTrackPackageWriter().write(package: payload, to: url)
        return url
    }

    private func makeSession(id: UUID) throws -> SessionData {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let samples = [
            MotionSample(
                timestamp: start,
                gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
                speedKmh: 8,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                sampleSource: .locationFix
            )
        ]
        return try SessionData(
            id: id,
            startDate: start,
            endDate: start.addingTimeInterval(300),
            sportMode: .skateboard(.longboard),
            powerType: .electric,
            motionSamples: samples,
            summaryMetrics: SessionSummaryMetrics(
                distanceKilometers: 1.2,
                maxSpeedKilometersPerHour: 18,
                averageSpeedKilometersPerHour: 12,
                elevationGainMeters: 3,
                movingRatio: 0.9
            )
        )
    }
}

private final class ImportFixtureRepository: SessionRepositoryProtocol, @unchecked Sendable {
    private var sessionsByID: [UUID: SessionData]
    private(set) var savedSessions: [SessionData] = []

    init(existingSessions: [SessionData] = []) {
        sessionsByID = Dictionary(uniqueKeysWithValues: existingSessions.map { ($0.id, $0) })
    }

    func saveCompletedSession(_ session: SessionData) async throws -> SessionData {
        sessionsByID[session.id] = session
        savedSessions.append(session)
        return session
    }

    func fetchRecentSessions(limit: Int) async throws -> [SessionData] {
        Array(sessionsByID.values.prefix(limit))
    }

    func fetchSession(id: UUID) async throws -> SessionData {
        guard let session = sessionsByID[id] else { throw RepositoryError.sessionNotFound }
        return session
    }

    func loadMotionSamples(for sessionID: UUID) async throws -> [MotionSample] {
        let session = try await fetchSession(id: sessionID)
        return session.motionSamples
    }

    func deleteSession(id: UUID) async throws {
        sessionsByID.removeValue(forKey: id)
    }

    func exportSessionBundle(id: UUID) async throws -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
    }
}
