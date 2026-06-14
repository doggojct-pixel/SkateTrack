import XCTest
@testable import SkateTrack_iOS

final class SnowSessionRepositoryTests: XCTestCase {
    func testSaveFetchStateAndDeleteSnowSessionData() async throws {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SkateTrackSnowRepositoryTests_\(UUID().uuidString)", isDirectory: true)
        let storeURL = rootDirectory.appendingPathComponent("SkateTrack.sqlite")
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let persistenceController = PersistenceController(inMemory: false, storeURL: storeURL)
        let repository = SnowSessionRepository(persistenceController: persistenceController)
        let sessionID = UUID()
        let runID = UUID()
        let segmentID = UUID()
        let startDate = Date(timeIntervalSince1970: 1_700_010_000)

        let segment = SnowSegment(
            id: segmentID,
            sessionID: sessionID,
            runID: runID,
            type: .downhillRun,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(72),
            distanceMeters: 420,
            verticalDeltaMeters: -88,
            startAltitudeMeters: 1_560,
            endAltitudeMeters: 1_472,
            averageSpeedMetersPerSecond: 5.8,
            maxSpeedMetersPerSecond: 13.4,
            confidence: 0.92,
            manualOverride: nil,
            sourceSampleIDs: [UUID(), UUID()]
        )
        let run = SnowRun(
            id: runID,
            sessionID: sessionID,
            runNumber: 1,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(72),
            skiDistanceMeters: 420,
            verticalDropMeters: 88,
            topSpeedMetersPerSecond: 13.4,
            averageSpeedMetersPerSecond: 5.8,
            segmentIDs: [segmentID],
            isManualEnd: false
        )

        try await repository.saveSegment(segment)
        try await repository.saveRun(run)

        let fetchedSegments = try await repository.fetchSegments(sessionID: sessionID)
        XCTAssertEqual(fetchedSegments, [segment])
        let fetchedRuns = try await repository.fetchRuns(sessionID: sessionID)
        XCTAssertEqual(fetchedRuns, [run])

        let state = try await repository.fetchState(sessionID: sessionID)
        XCTAssertEqual(state.loadState, .loaded)
        XCTAssertEqual(state.distanceBreakdown.skiDistanceMeters, 420, accuracy: 0.001)
        XCTAssertEqual(state.distanceBreakdown.routeDistanceMeters, 420, accuracy: 0.001)
        XCTAssertEqual(state.verticalMetrics.totalVerticalDropMeters, 88, accuracy: 0.001)

        try await repository.deleteSnowData(sessionID: sessionID)
        let emptyState = try await repository.fetchState(sessionID: sessionID)
        XCTAssertEqual(emptyState.loadState, .empty)
    }

    func testExistingSessionRepositoryStillWorksAfterSnowSchemaExpansion() async throws {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SkateTrackSnowMigrationRegression_\(UUID().uuidString)", isDirectory: true)
        let sampleDirectory = rootDirectory.appendingPathComponent("samples", isDirectory: true)
        let storeURL = rootDirectory.appendingPathComponent("SkateTrack.sqlite")
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let persistenceController = PersistenceController(inMemory: false, storeURL: storeURL)
        let sessionRepository = SessionRepository(
            persistenceController: persistenceController,
            sampleStore: MotionSampleFileStore(rootDirectory: sampleDirectory),
            exportDirectory: rootDirectory.appendingPathComponent("exports", isDirectory: true)
        )

        let session = try makeCompletedSession()
        try await sessionRepository.saveCompletedSession(session)

        let fetchedSession = try await sessionRepository.fetchSession(id: session.id)
        XCTAssertEqual(fetchedSession.id, session.id)
        XCTAssertEqual(fetchedSession.sportMode, session.sportMode)
        XCTAssertEqual(fetchedSession.motionSamples.count, 1)
    }

    private func makeCompletedSession() throws -> SessionData {
        let startDate = Date(timeIntervalSince1970: 1_700_020_000)
        let samples = [
            MotionSample(
                timestamp: startDate.addingTimeInterval(1),
                gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
                speedKmh: 12,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                altitudeMeters: 1_420
            )
        ]
        return try SessionData(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(60),
            sportMode: .snow(.skiing),
            powerType: .humanPowered,
            motionSamples: samples,
            summaryMetrics: SessionSummaryMetrics(
                distanceKilometers: 0.2,
                maxSpeedKilometersPerHour: 12,
                averageSpeedKilometersPerHour: 8,
                elevationGainMeters: 0,
                movingRatio: 0.7
            )
        )
    }

}
