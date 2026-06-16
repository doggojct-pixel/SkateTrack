import XCTest
@testable import SkateTrack_iOS

final class SessionRepositoryTests: XCTestCase {
    func testSaveFetchLoadExportAndDeleteCompletedSession() async throws {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SkateTrackRepositoryTests_\(UUID().uuidString)", isDirectory: true)
        let sampleDirectory = rootDirectory.appendingPathComponent("samples", isDirectory: true)
        let exportDirectory = rootDirectory.appendingPathComponent("exports", isDirectory: true)
        let storeURL = rootDirectory.appendingPathComponent("SkateTrack.sqlite")
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let persistenceController = PersistenceController(inMemory: false, storeURL: storeURL)
        let repository = SessionRepository(
            persistenceController: persistenceController,
            sampleStore: MotionSampleFileStore(rootDirectory: sampleDirectory),
            exportDirectory: exportDirectory
        )

        let session = try makeCompletedSession()
        try await repository.saveCompletedSession(session)

        let recentSessions = try await repository.fetchRecentSessions(limit: 10)
        XCTAssertEqual(recentSessions.count, 1)
        XCTAssertEqual(recentSessions.first?.id, session.id)
        XCTAssertEqual(recentSessions.first?.motionSamples.count, 2)
        XCTAssertEqual(recentSessions.first?.fallEvents.count, 1)

        let fetchedSession = try await repository.fetchSession(id: session.id)
        let fetchedSummaryMetrics = try XCTUnwrap(fetchedSession.summaryMetrics)
        XCTAssertEqual(fetchedSummaryMetrics.distanceKilometers, 0.42, accuracy: 0.001)
        XCTAssertEqual(fetchedSession.motionSamples.map(\.speedKmh), [8, 12])
        XCTAssertEqual(fetchedSession.spotID, session.spotID)
        XCTAssertEqual(fetchedSession.spotSnapshot, session.spotSnapshot)

        let samples = try await repository.loadMotionSamples(for: session.id)
        XCTAssertEqual(samples.count, 2)

        let exportURL = try await repository.exportSessionBundle(id: session.id)
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.appendingPathComponent("session.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.appendingPathComponent("motionSamples.json").path))

        try await repository.deleteSession(id: session.id)
        do {
            _ = try await repository.fetchSession(id: session.id)
            XCTFail("Expected deleted session to be unavailable")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, .sessionNotFound)
        }
    }

    private func makeCompletedSession() throws -> SessionData {
        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let samples = [
            MotionSample(
                timestamp: startDate.addingTimeInterval(1),
                gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
                speedKmh: 8,
                accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
                altitudeMeters: 12
            ),
            MotionSample(
                timestamp: startDate.addingTimeInterval(2),
                gpsCoordinate: GeoCoordinate(latitude: 25.034, longitude: 121.566),
                speedKmh: 12,
                accelerometerG: ThreeAxisValue(x: 0.1, y: 0, z: 1),
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0.1, z: 0),
                altitudeMeters: 13
            )
        ]
        let fallEvent = FallEvent(
            timestamp: startDate.addingTimeInterval(2),
            peakImpactGForce: 4.2,
            locationCoordinate: samples.last?.gpsCoordinate,
            recoveryDurationSeconds: 3,
            sportMode: .skateboard(.streetPark),
            userConfirmed: false
        )
        let spotID = UUID()
        let spotSnapshot = SpotSessionSnapshot(
            spotID: spotID,
            name: "Test Skate Park",
            activityFamily: .mixed,
            coordinate: samples.last?.gpsCoordinate,
            radiusMeters: 150,
            archivedAt: startDate
        )
        return try SessionData(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(60),
            sportMode: .skateboard(.streetPark),
            powerType: .humanPowered,
            motionSamples: samples,
            fallEvents: [fallEvent],
            summaryMetrics: SessionSummaryMetrics(
                distanceKilometers: 0.42,
                maxSpeedKilometersPerHour: 12,
                averageSpeedKilometersPerHour: 10,
                elevationGainMeters: 1,
                movingRatio: 0.8
            ),
            spotID: spotID,
            spotSnapshot: spotSnapshot
        )
    }
}
