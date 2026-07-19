// [協作區] SkateTrackPackageSnowImportRoundTripTests.swift
// 用途：以實體暫存 repositories 驗證 A008R1 package Snow 匯入持久化、回滾與匯出 round trip。

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SkateTrackPackageSnowImportRoundTripTests: XCTestCase {
    func testV1NonSnowImportRemainsUnchanged() async throws {
        let environment = makeEnvironment()
        defer { try? FileManager.default.removeItem(at: environment.root) }
        let packageURL = try writeV1NonSnowPackage(root: environment.root)

        let result = try await importSingle(
            url: packageURL,
            repository: environment.sessionRepository,
            snowRepository: environment.snowRepository,
            stagingRoot: environment.stagingRoot
        )
        let imported = try await environment.sessionRepository.fetchSession(id: result.sessionID)
        let snowState = try await environment.snowRepository.fetchState(sessionID: result.sessionID)

        XCTAssertEqual(result.commit.status, .imported)
        XCTAssertEqual(imported.id, result.sessionID)
        XCTAssertTrue(snowState.runs.isEmpty)
        XCTAssertTrue(snowState.segments.isEmpty)
    }

    func testV2WithoutSnowPayloadImportsBaseSessionOnly() async throws {
        let environment = makeEnvironment()
        defer { try? FileManager.default.removeItem(at: environment.root) }
        let packageURL = try copyFixture(
            named: "qa_snow_package_v2_without_payload.json",
            to: environment.root
        )

        let result = try await importSingle(
            url: packageURL,
            repository: environment.sessionRepository,
            snowRepository: environment.snowRepository,
            stagingRoot: environment.stagingRoot
        )
        let imported = try await environment.sessionRepository.fetchSession(id: result.sessionID)
        let snowState = try await environment.snowRepository.fetchState(sessionID: result.sessionID)

        XCTAssertEqual(result.commit.status, .imported)
        XCTAssertEqual(imported.id, result.sessionID)
        XCTAssertTrue(snowState.runs.isEmpty)
        XCTAssertTrue(snowState.segments.isEmpty)
    }

    func testV2SnowPayloadPersistsRunsSegmentsAndSessionAssociation() async throws {
        let environment = makeEnvironment()
        defer { try? FileManager.default.removeItem(at: environment.root) }
        let packageURL = try copyFixture(
            named: "qa_snow_package_v2_with_payload.json",
            to: environment.root
        )
        let expectedPackage = try SkateTrackPackageReader().readPackage(from: packageURL)
        let expectedSnow = try XCTUnwrap(expectedPackage.primarySession?.snowPayload)

        let result = try await importSingle(
            url: packageURL,
            repository: environment.sessionRepository,
            snowRepository: environment.snowRepository,
            stagingRoot: environment.stagingRoot
        )
        let fetched = try await environment.snowRepository.fetchState(sessionID: result.sessionID)

        XCTAssertEqual(result.commit.status, .imported)
        XCTAssertEqual(fetched.sessionID, result.sessionID)
        XCTAssertEqual(fetched.runs.count, expectedSnow.runs.count)
        XCTAssertEqual(fetched.segments.count, expectedSnow.segments.count)
        XCTAssertTrue(fetched.runs.allSatisfy { $0.sessionID == result.sessionID })
        XCTAssertTrue(fetched.segments.allSatisfy { $0.sessionID == result.sessionID })
        XCTAssertEqual(fetched.runs, expectedSnow.runs)
        XCTAssertEqual(fetched.segments, expectedSnow.segments)
    }

    func testImportedSnowPackageExportsWithSemanticRoundTrip() async throws {
        let environment = makeEnvironment()
        defer { try? FileManager.default.removeItem(at: environment.root) }
        let packageURL = try copyFixture(
            named: "qa_snow_package_v2_with_payload.json",
            to: environment.root
        )
        let original = try SkateTrackPackageReader().readPackage(from: packageURL)
        let originalSnow = try XCTUnwrap(original.primarySession?.snowPayload)
        let result = try await importSingle(
            url: packageURL,
            repository: environment.sessionRepository,
            snowRepository: environment.snowRepository,
            stagingRoot: environment.stagingRoot
        )
        let importedSession = try await environment.sessionRepository.fetchSession(id: result.sessionID)
        let provider = SkateTrackPackageExportProvider(
            snowRepository: environment.snowRepository,
            now: { Date(timeIntervalSince1970: 2_000_000_000) }
        )

        let export = try await provider.createExport(
            content: SessionSummaryContent(session: importedSession, motionSamples: importedSession.motionSamples)
        )
        defer { provider.cleanup(export) }
        let roundTripped = try SkateTrackPackageReader().readPackage(from: export.fileURL)
        let roundTrippedSnow = try XCTUnwrap(roundTripped.primarySession?.snowPayload)

        XCTAssertEqual(roundTrippedSnow.sessionID, originalSnow.sessionID)
        XCTAssertEqual(roundTrippedSnow.runs, originalSnow.runs)
        XCTAssertEqual(roundTrippedSnow.segments, originalSnow.segments)
        XCTAssertEqual(roundTrippedSnow.distanceBreakdown, originalSnow.distanceBreakdown)
        XCTAssertEqual(roundTrippedSnow.verticalMetrics, originalSnow.verticalMetrics)
    }

    func testUnknownOnlySnowRouteExportsAndImportsUnderCurrentSchema() async throws {
        let source = makeEnvironment()
        let destination = makeEnvironment()
        defer {
            try? FileManager.default.removeItem(at: source.root)
            try? FileManager.default.removeItem(at: destination.root)
        }
        let sessionID = UUID()
        let startDate = Date(timeIntervalSince1970: 1_900_000_000)
        let routeDistanceMeters = 432.592
        let session = try SessionData(
            id: sessionID,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(59),
            sportMode: .snow(.skiing),
            summaryMetrics: SessionSummaryMetrics(
                distanceKilometers: routeDistanceMeters / 1_000,
                maxSpeedKilometersPerHour: 29.1,
                averageSpeedKilometersPerHour: 24.7,
                elevationGainMeters: 0,
                movingRatio: 0.97
            )
        )
        let unknownSegment = SnowSegment(
            sessionID: sessionID,
            runID: nil,
            type: .unknown,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(59),
            distanceMeters: routeDistanceMeters,
            confidence: 0,
            countsTowardSkiDistance: false,
            manualOverride: false
        )
        try await source.sessionRepository.saveCompletedSession(session)
        try await source.snowRepository.saveSegment(unknownSegment)
        let provider = SkateTrackPackageExportProvider(
            snowRepository: source.snowRepository,
            now: { Date(timeIntervalSince1970: 1_900_000_100) }
        )

        let export = try await provider.createExport(
            content: SessionSummaryContent(session: session, motionSamples: [])
        )
        defer { provider.cleanup(export) }
        let exported = try SkateTrackPackageReader().readPackage(from: export.fileURL)
        let exportedSnow = try XCTUnwrap(exported.primarySession?.snowPayload)

        XCTAssertEqual(exported.manifest.schemaVersion, SkateTrackPackageManifest.currentSchemaVersion)
        XCTAssertEqual(exportedSnow.segments, [unknownSegment])
        XCTAssertEqual(exportedSnow.distanceBreakdown.routeDistanceMeters, routeDistanceMeters, accuracy: 0.001)
        XCTAssertEqual(exportedSnow.distanceBreakdown.unknownDistanceMeters, routeDistanceMeters, accuracy: 0.001)
        XCTAssertEqual(exportedSnow.distanceBreakdown.skiDistanceMeters, 0, accuracy: 0.001)
        XCTAssertEqual(exportedSnow.distanceBreakdown.liftDistanceMeters, 0, accuracy: 0.001)

        let imported = try await importSingle(
            url: export.fileURL,
            repository: destination.sessionRepository,
            snowRepository: destination.snowRepository,
            stagingRoot: destination.stagingRoot
        )
        let importedState = try await destination.snowRepository.fetchState(sessionID: imported.sessionID)

        XCTAssertEqual(imported.commit.status, .imported)
        XCTAssertEqual(importedState.segments, [unknownSegment])
        XCTAssertEqual(importedState.distanceBreakdown.routeDistanceMeters, routeDistanceMeters, accuracy: 0.001)
        XCTAssertEqual(importedState.distanceBreakdown.unknownDistanceMeters, routeDistanceMeters, accuracy: 0.001)
        XCTAssertEqual(importedState.distanceBreakdown.skiDistanceMeters, 0, accuracy: 0.001)
        XCTAssertEqual(importedState.distanceBreakdown.liftDistanceMeters, 0, accuracy: 0.001)
    }

    func testSnowPersistenceFailureRollsBackBaseSession() async throws {
        let environment = makeEnvironment()
        defer { try? FileManager.default.removeItem(at: environment.root) }
        let packageURL = try copyFixture(
            named: "qa_snow_package_v2_with_payload.json",
            to: environment.root
        )
        let package = try SkateTrackPackageReader().readPackage(from: packageURL)
        let sessionID = try XCTUnwrap(package.primarySession?.session.id)
        let failingSnowRepository = FailingSnowSessionRepository(base: environment.snowRepository)
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: environment.sessionRepository,
            snowRepository: failingSnowRepository,
            stagingRootURL: environment.stagingRoot
        )
        let candidates = await coordinator.validatePackages(from: [packageURL])
        let candidate = try XCTUnwrap(candidates.first)

        let results = await coordinator.commitSelectedPackages(
            candidates: candidates,
            selectedCandidateIDs: [candidate.id]
        )

        XCTAssertEqual(results.first?.status, .failed)
        XCTAssertEqual(results.first?.detailKey, "import.error.snowPersistenceFailed")
        do {
            _ = try await environment.sessionRepository.fetchSession(id: sessionID)
            XCTFail("A failed Snow persistence attempt must not leave the base session imported")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, .sessionNotFound)
        }
        let snowState = try await environment.snowRepository.fetchState(sessionID: sessionID)
        XCTAssertTrue(snowState.runs.isEmpty)
        XCTAssertTrue(snowState.segments.isEmpty)
    }

    private func importSingle(
        url: URL,
        repository: SessionRepository,
        snowRepository: SnowSessionRepositoryProtocol,
        stagingRoot: URL
    ) async throws -> (commit: SkateTrackImportCommitResult, sessionID: UUID) {
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: repository,
            snowRepository: snowRepository,
            stagingRootURL: stagingRoot
        )
        let candidates = await coordinator.validatePackages(from: [url])
        let candidate = try XCTUnwrap(candidates.first)
        XCTAssertEqual(candidate.validationStatus, .ready)
        let results = await coordinator.commitSelectedPackages(
            candidates: candidates,
            selectedCandidateIDs: [candidate.id]
        )
        return (try XCTUnwrap(results.first), try XCTUnwrap(candidate.sessionIDs.first))
    }

    private func makeEnvironment() -> ImportTestEnvironment {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("A008R1SnowImport_\(UUID().uuidString)", isDirectory: true)
        let controller = PersistenceController(inMemory: true)
        let repository = SessionRepository(
            persistenceController: controller,
            sampleStore: MotionSampleFileStore(
                rootDirectory: root.appendingPathComponent("samples", isDirectory: true)
            ),
            exportDirectory: root.appendingPathComponent("exports", isDirectory: true)
        )
        return ImportTestEnvironment(
            root: root,
            stagingRoot: root.appendingPathComponent("staging", isDirectory: true),
            sessionRepository: repository,
            snowRepository: SnowSessionRepository(persistenceController: controller)
        )
    }

    private func copyFixture(named name: String, to root: URL) throws -> URL {
        let source = fixtureURL(named: name)
        let destination = root.appendingPathComponent(name).deletingPathExtension().appendingPathExtension("skatetrack")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func fixtureURL(named name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Snow")
            .appendingPathComponent(name)
    }

    private func writeV1NonSnowPackage(root: URL) throws -> URL {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let sessionID = UUID()
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let session = try SessionData(
            id: sessionID,
            startDate: start,
            endDate: start.addingTimeInterval(300),
            sportMode: .skateboard(.streetPark),
            powerType: .humanPowered,
            motionSamples: []
        )
        let packageSession = SkateTrackPackageSession(session: session, motionSamples: [])
        let manifest = SkateTrackPackageManifest(
            schemaVersion: 1,
            appVersion: "a008r1-test",
            buildNumber: "1",
            localeIdentifier: "en_US",
            sessionCount: 1,
            includesMotionSamples: false
        )
        let payload = try SkateTrackPackagePayload(manifest: manifest, sessions: [packageSession])
        let url = root.appendingPathComponent("v1-non-snow.skatetrack")
        _ = try SkateTrackPackageWriter().write(package: payload, to: url)
        return url
    }
}

private struct ImportTestEnvironment {
    let root: URL
    let stagingRoot: URL
    let sessionRepository: SessionRepository
    let snowRepository: SnowSessionRepository
}

private final class FailingSnowSessionRepository: SnowSessionRepositoryProtocol, @unchecked Sendable {
    private let base: SnowSessionRepositoryProtocol

    init(base: SnowSessionRepositoryProtocol) {
        self.base = base
    }

    func saveRun(_ run: SnowRun) async throws -> SnowRun {
        throw RepositoryError.saveFailed
    }

    func saveSegment(_ segment: SnowSegment) async throws -> SnowSegment {
        throw RepositoryError.saveFailed
    }

    func fetchRuns(sessionID: UUID) async throws -> [SnowRun] {
        try await base.fetchRuns(sessionID: sessionID)
    }

    func fetchSegments(sessionID: UUID) async throws -> [SnowSegment] {
        try await base.fetchSegments(sessionID: sessionID)
    }

    func fetchRun(id: UUID) async throws -> SnowRun { try await base.fetchRun(id: id) }
    func fetchSegment(id: UUID) async throws -> SnowSegment { try await base.fetchSegment(id: id) }
    func fetchState(sessionID: UUID) async throws -> SnowSessionState { try await base.fetchState(sessionID: sessionID) }
    func deleteRun(id: UUID) async throws { try await base.deleteRun(id: id) }
    func deleteSegment(id: UUID) async throws { try await base.deleteSegment(id: id) }
    func deleteSnowData(sessionID: UUID) async throws { try await base.deleteSnowData(sessionID: sessionID) }
}
