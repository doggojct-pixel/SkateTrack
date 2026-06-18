import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SkateTrackPackageSnowCompatibilityTests: XCTestCase {
    func testDecodeSchemaVersion1PackageWithoutSnowFieldsSucceeds() throws {
        let package = try makePackage(schemaVersion: 1, capabilities: nil, snowPayload: nil)
        let data = try SkateTrackPackageWriter().encodedData(for: package)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertFalse(json.contains("capabilities"))
        XCTAssertFalse(json.contains("snowPayload"))

        let decoded = try SkateTrackPackageReader().decodePackage(from: data)
        XCTAssertEqual(decoded.manifest.schemaVersion, 1)
        XCTAssertNil(decoded.manifest.capabilities)
        XCTAssertNil(decoded.primarySession?.snowPayload)
    }

    func testDecodeSchemaVersion2PackageWithoutSnowPayloadSucceeds() throws {
        let package = try makePackage(schemaVersion: 2, capabilities: nil, snowPayload: nil)
        let data = try SkateTrackPackageWriter().encodedData(for: package)
        let decoded = try SkateTrackPackageReader().decodePackage(from: data)

        XCTAssertEqual(decoded.manifest.schemaVersion, 2)
        XCTAssertNil(decoded.manifest.capabilities)
        XCTAssertNil(decoded.primarySession?.snowPayload)
    }

    func testDecodeSchemaVersion2PackageWithSnowPayloadSucceeds() throws {
        let snowPayload = makeSnowPayload()
        let package = try makePackage(
            schemaVersion: 2,
            capabilities: SkateTrackPackageSnowCapability.allRawValues,
            snowPayload: snowPayload
        )
        let data = try SkateTrackPackageWriter().encodedData(for: package)
        let decoded = try SkateTrackPackageReader().decodePackage(from: data)
        let decodedSnowPayload = try XCTUnwrap(decoded.primarySession?.snowPayload)

        XCTAssertEqual(decoded.manifest.schemaVersion, 2)
        XCTAssertEqual(decoded.manifest.capabilities, SkateTrackPackageSnowCapability.allRawValues)
        XCTAssertEqual(decodedSnowPayload.payloadVersion, SkateTrackPackageSnowPayload.currentPayloadVersion)
        XCTAssertEqual(decodedSnowPayload.sessionID, snowPayload.sessionID)
        XCTAssertEqual(decodedSnowPayload.runs, snowPayload.runs)
        XCTAssertEqual(decodedSnowPayload.segments, snowPayload.segments)
        XCTAssertEqual(decodedSnowPayload.distanceBreakdown, snowPayload.distanceBreakdown)
        XCTAssertEqual(decodedSnowPayload.verticalMetrics, snowPayload.verticalMetrics)
    }

    func testDecodeUnknownSchemaVersionFails() throws {
        let package = try makePackage(schemaVersion: 1, capabilities: nil, snowPayload: nil)
        let data = try SkateTrackPackageWriter().encodedData(for: package)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        let unknownSchemaJSON = json.replacingOccurrences(of: "\"schemaVersion\" : 1", with: "\"schemaVersion\" : 99")
        let unknownData = try XCTUnwrap(unknownSchemaJSON.data(using: .utf8))

        do {
            _ = try SkateTrackPackageReader().decodePackage(from: unknownData)
            XCTFail("Expected schema 99 to be rejected")
        } catch let error as SkateTrackPackageError {
            XCTAssertEqual(error, .unsupportedSchemaVersion(99))
        }
    }

    func testSnowPayloadInitializerRejectsEmptyStatePlaceholders() {
        let emptyState = SnowSessionState(
            sessionID: UUID(),
            loadState: .empty,
            runs: [],
            segments: []
        )

        XCTAssertNil(SkateTrackPackageSnowPayload(snowState: emptyState))
    }


    func testExportProviderOmitsSnowPayloadForNonSnowSession() async throws {
        let session = try makeSession(id: UUID(), sportMode: .skateboard(.streetPark))
        let repository = FakeSnowSessionRepository(stateBySessionID: [:])
        let provider = SkateTrackPackageExportProvider(
            snowRepository: repository,
            now: { Date(timeIntervalSince1970: 1_700_001_000) }
        )

        let result = try await provider.createExport(
            content: SessionSummaryContent(session: session, motionSamples: makeSamples(startDate: session.startDate))
        )
        defer { provider.cleanup(result) }

        let decoded = try SkateTrackPackageReader().readPackage(from: result.fileURL)

        XCTAssertEqual(repository.fetchStateCallCount, 0)
        XCTAssertNil(decoded.manifest.capabilities)
        XCTAssertNil(decoded.primarySession?.snowPayload)
    }

    func testExportProviderOmitsSnowPayloadForSnowSessionWithoutRepositoryState() async throws {
        let session = try makeSession(id: UUID(), sportMode: .snow(.skiing))
        let emptyState = SnowSessionState(sessionID: session.id, loadState: .empty, runs: [], segments: [])
        let repository = FakeSnowSessionRepository(stateBySessionID: [session.id: emptyState])
        let provider = SkateTrackPackageExportProvider(
            snowRepository: repository,
            now: { Date(timeIntervalSince1970: 1_700_001_000) }
        )

        let result = try await provider.createExport(
            content: SessionSummaryContent(session: session, motionSamples: makeSamples(startDate: session.startDate))
        )
        defer { provider.cleanup(result) }

        let decoded = try SkateTrackPackageReader().readPackage(from: result.fileURL)

        XCTAssertEqual(repository.fetchStateCallCount, 1)
        XCTAssertNil(decoded.manifest.capabilities)
        XCTAssertNil(decoded.primarySession?.snowPayload)
    }

    func testExportProviderIncludesSnowPayloadForSnowSessionWithRepositoryState() async throws {
        let snowPayload = makeSnowPayload()
        let session = try makeSession(id: snowPayload.sessionID, sportMode: .snow(.skiing))
        let repository = FakeSnowSessionRepository(stateBySessionID: [snowPayload.sessionID: snowPayload.makeSnowSessionState()])
        let generatedAt = Date(timeIntervalSince1970: 1_700_001_000)
        let provider = SkateTrackPackageExportProvider(
            snowRepository: repository,
            now: { generatedAt }
        )

        let result = try await provider.createExport(
            content: SessionSummaryContent(session: session, motionSamples: makeSamples(startDate: session.startDate))
        )
        defer { provider.cleanup(result) }

        let decoded = try SkateTrackPackageReader().readPackage(from: result.fileURL)
        let decodedSnowPayload = try XCTUnwrap(decoded.primarySession?.snowPayload)

        XCTAssertEqual(repository.fetchStateCallCount, 1)
        XCTAssertEqual(result.manifest.capabilities, SkateTrackPackageSnowCapability.allRawValues)
        XCTAssertEqual(decoded.manifest.capabilities, SkateTrackPackageSnowCapability.allRawValues)
        XCTAssertEqual(decodedSnowPayload.sessionID, snowPayload.sessionID)
        XCTAssertEqual(decodedSnowPayload.runs, snowPayload.runs)
        XCTAssertEqual(decodedSnowPayload.segments, snowPayload.segments)
        XCTAssertEqual(decodedSnowPayload.generatedAt, generatedAt)
    }

    private func makePackage(
        schemaVersion: Int,
        capabilities: [String]?,
        snowPayload: SkateTrackPackageSnowPayload?
    ) throws -> SkateTrackPackagePayload {
        let session = try makeSession(id: snowPayload?.sessionID ?? UUID())
        let packageSession = SkateTrackPackageSession(
            id: session.id,
            session: session,
            motionSamples: makeSamples(startDate: session.startDate),
            snowPayload: snowPayload
        )
        let manifest = SkateTrackPackageManifest(
            schemaVersion: schemaVersion,
            appVersion: "test",
            buildNumber: "1",
            createdAt: Date(timeIntervalSince1970: 1_700_000_100),
            localeIdentifier: "en_US",
            sessionCount: 1,
            includesMotionSamples: true,
            capabilities: capabilities
        )
        return try SkateTrackPackagePayload(manifest: manifest, sessions: [packageSession])
    }

    private func makeSession(id: UUID, sportMode: SportMode = .snow(.skiing)) throws -> SessionData {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        return try SessionData(
            id: id,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(240),
            sportMode: sportMode,
            powerType: .humanPowered,
            motionSamples: makeSamples(startDate: startDate)
        )
    }

    private func makeSnowPayload() -> SkateTrackPackageSnowPayload {
        let sessionID = UUID()
        let runID = UUID()
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let segment = SnowSegment(
            id: UUID(),
            sessionID: sessionID,
            runID: runID,
            type: .downhillRun,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(120),
            distanceMeters: 1_200,
            verticalDeltaMeters: -180,
            startAltitudeMeters: 2_100,
            endAltitudeMeters: 1_920,
            averageSpeedMetersPerSecond: 10,
            maxSpeedMetersPerSecond: 18,
            confidence: 0.91,
            countsTowardSkiDistance: true,
            sourceSampleIDs: []
        )
        let run = SnowRun(
            id: runID,
            sessionID: sessionID,
            runNumber: 1,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(120),
            skiDistanceMeters: 1_200,
            verticalDropMeters: 180,
            topSpeedMetersPerSecond: 18,
            averageSpeedMetersPerSecond: 10,
            segmentIDs: [segment.id]
        )
        return SkateTrackPackageSnowPayload(
            sessionID: sessionID,
            runs: [run],
            segments: [segment],
            generatedAt: startDate.addingTimeInterval(240)
        )
    }

    private func makeSamples(startDate: Date) -> [MotionSample] {
        [
            MotionSample(
                timestamp: startDate,
                gpsCoordinate: GeoCoordinate(latitude: 46.8523, longitude: 9.5320),
                speedKmh: 0,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                altitudeMeters: 2_100
            ),
            MotionSample(
                timestamp: startDate.addingTimeInterval(120),
                gpsCoordinate: GeoCoordinate(latitude: 46.8480, longitude: 9.5280),
                speedKmh: 45,
                accelerometerG: ThreeAxisValue(x: 0.1, y: 0.1, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0.1, z: 0),
                altitudeMeters: 1_920
            )
        ]
    }
}


private final class FakeSnowSessionRepository: SnowSessionRepositoryProtocol, @unchecked Sendable {
    private let stateBySessionID: [UUID: SnowSessionState]
    private(set) var fetchStateCallCount = 0

    init(stateBySessionID: [UUID: SnowSessionState]) {
        self.stateBySessionID = stateBySessionID
    }

    @discardableResult
    func saveRun(_ run: SnowRun) async throws -> SnowRun { run }

    @discardableResult
    func saveSegment(_ segment: SnowSegment) async throws -> SnowSegment { segment }

    func fetchRuns(sessionID: UUID) async throws -> [SnowRun] {
        stateBySessionID[sessionID]?.runs ?? []
    }

    func fetchSegments(sessionID: UUID) async throws -> [SnowSegment] {
        stateBySessionID[sessionID]?.segments ?? []
    }

    func fetchRun(id: UUID) async throws -> SnowRun {
        throw RepositoryError.snowRunNotFound
    }

    func fetchSegment(id: UUID) async throws -> SnowSegment {
        throw RepositoryError.snowSegmentNotFound
    }

    func fetchState(sessionID: UUID) async throws -> SnowSessionState {
        fetchStateCallCount += 1
        return stateBySessionID[sessionID] ?? SnowSessionState(sessionID: sessionID, loadState: .empty, runs: [], segments: [])
    }

    func deleteRun(id: UUID) async throws {}

    func deleteSegment(id: UUID) async throws {}

    func deleteSnowData(sessionID: UUID) async throws {}
}
