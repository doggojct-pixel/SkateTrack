// [協作區] Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift
// 用途：驗證 Task-035d package / backup compatibility；只測 optional Watch metadata，不導入 Watch sample storage。

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SkateTrackPackageWatchCompatibilityTests: XCTestCase {
    func testLegacySchemaOnePackageDecodesWithoutWatchCompatibilityMetadata() throws {
        let payload = try makePackage(schemaVersion: 1, watchSampleCompatibility: nil)
        let data = try SkateTrackPackageWriter().encodedData(for: payload)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertFalse(json.contains("watchSampleCompatibility"))

        let decoded = try SkateTrackPackageReader().decodePackage(from: data)
        XCTAssertEqual(decoded.manifest.schemaVersion, 1)
        XCTAssertTrue(SkateTrackPackageManifest.supportedSchemaVersions.contains(1))
        XCTAssertNil(decoded.manifest.watchSampleCompatibility)
        XCTAssertFalse(decoded.manifest.includesOptionalWatchSampleData)
        XCTAssertEqual(decoded.primarySession?.sampleCount, payload.primarySession?.sampleCount)
    }

    func testOptionalWatchCompatibilityMetadataRoundTripsWithoutSchemaBump() throws {
        let compatibility = SkateTrackWatchSampleCompatibility(
            containsWatchSamples: true,
            storageStrategy: "sidecar-json-optional",
            sourceAttributionPreserved: true,
            displayDerivedOnly: true,
            trustedMetricMutationCount: 0,
            routeGeometryMutationCount: 0
        )
        let payload = try makePackage(watchSampleCompatibility: compatibility)
        let baselinePayload = try makePackage(watchSampleCompatibility: nil)
        let data = try SkateTrackPackageWriter().encodedData(for: payload)
        let baselineData = try SkateTrackPackageWriter().encodedData(for: baselinePayload)
        let decoded = try SkateTrackPackageReader().decodePackage(from: data)
        let baselineDecoded = try SkateTrackPackageReader().decodePackage(from: baselineData)

        XCTAssertEqual(decoded.manifest.schemaVersion, SkateTrackPackageManifest.currentSchemaVersion)
        XCTAssertEqual(decoded.manifest.schemaVersion, baselineDecoded.manifest.schemaVersion)
        XCTAssertEqual(decoded.manifest.watchSampleCompatibility, compatibility)
        XCTAssertTrue(decoded.manifest.includesOptionalWatchSampleData)
        XCTAssertEqual(decoded.manifest.watchSampleCompatibility?.trustedMetricMutationCount, 0)
        XCTAssertEqual(decoded.manifest.watchSampleCompatibility?.routeGeometryMutationCount, 0)
        XCTAssertEqual(decoded.primarySession?.motionSamples, payload.primarySession?.motionSamples)
        XCTAssertNil(decoded.primarySession?.snowPayload)
    }

    func testTask030dImportStillAcceptsLegacyPackageWithoutWatchMetadata() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = PackageCompatibilityImportRepository()
        let coordinator = SkateTrackPackageImportCoordinator(
            repository: repository,
            stagingRootURL: root.appendingPathComponent("staging", isDirectory: true)
        )
        let packageURL = try writePackage(
            sessionID: UUID(),
            fileName: "legacy.skatetrack",
            root: root,
            schemaVersion: 1,
            watchSampleCompatibility: nil
        )

        let candidates = await coordinator.validatePackages(from: [packageURL])

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.validationStatus, .ready)
        XCTAssertTrue(candidates.first?.isImportable ?? false)
        XCTAssertEqual(candidates.first?.manifest?.schemaVersion, 1)
        XCTAssertNil(candidates.first?.manifest?.watchSampleCompatibility)
    }

    func testTask030eReadOnlyViewerReaderStillOpensLegacyPackage() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let packageURL = try writePackage(
            sessionID: UUID(),
            fileName: "viewer-legacy.skatetrack",
            root: root,
            schemaVersion: 1,
            watchSampleCompatibility: nil
        )

        let payload = try SkateTrackPackageReader().readPackage(from: packageURL)

        XCTAssertNil(payload.manifest.watchSampleCompatibility)
        XCTAssertEqual(payload.manifest.schemaVersion, 1)
        XCTAssertEqual(payload.sessions.count, 1)
        XCTAssertEqual(payload.primarySession?.sampleCount, 1)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("Task035dPackageCompatibility_\(UUID().uuidString)", isDirectory: true)
    }

    private func writePackage(
        sessionID: UUID,
        fileName: String,
        root: URL,
        schemaVersion: Int = SkateTrackPackageManifest.currentSchemaVersion,
        watchSampleCompatibility: SkateTrackWatchSampleCompatibility?
    ) throws -> URL {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let payload = try makePackage(
            sessionID: sessionID,
            schemaVersion: schemaVersion,
            watchSampleCompatibility: watchSampleCompatibility
        )
        let url = root.appendingPathComponent(fileName)
        _ = try SkateTrackPackageWriter().write(package: payload, to: url)
        return url
    }

    private func makePackage(
        sessionID: UUID = UUID(),
        schemaVersion: Int = SkateTrackPackageManifest.currentSchemaVersion,
        watchSampleCompatibility: SkateTrackWatchSampleCompatibility?
    ) throws -> SkateTrackPackagePayload {
        let session = try makeSession(id: sessionID)
        let packageSession = SkateTrackPackageSession(session: session, motionSamples: session.motionSamples)
        let capabilities = watchSampleCompatibility == nil
            ? nil
            : [SkateTrackWatchSampleCompatibility.capabilityIdentifier]
        let manifest = SkateTrackPackageManifest(
            schemaVersion: schemaVersion,
            appVersion: "test",
            buildNumber: "1",
            localeIdentifier: "en_US",
            sessionCount: 1,
            includesMotionSamples: true,
            formatCapabilities: capabilities,
            watchSampleCompatibility: watchSampleCompatibility
        )
        return try SkateTrackPackagePayload(manifest: manifest, sessions: [packageSession])
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

private final class PackageCompatibilityImportRepository: SessionRepositoryProtocol, @unchecked Sendable {
    private var sessionsByID: [UUID: SessionData]

    init(existingSessions: [SessionData] = []) {
        sessionsByID = Dictionary(uniqueKeysWithValues: existingSessions.map { ($0.id, $0) })
    }

    func saveCompletedSession(_ session: SessionData) async throws -> SessionData {
        sessionsByID[session.id] = session
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
