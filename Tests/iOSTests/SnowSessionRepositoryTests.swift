// [協作區] SnowSessionRepositoryTests.swift
import CoreData
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

    @MainActor
    func testLegacyTask021bStoreMigratesWithoutDestructiveRecreation() async throws {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SkateTrackLegacyMigration_\(UUID().uuidString)", isDirectory: true)
        let storeURL = rootDirectory.appendingPathComponent("SkateTrack.sqlite")
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let legacyModel = makeLegacyTask021bModel()
        XCTAssertEqual(legacyModel.versionIdentifiers, ["Task021b"])
        XCTAssertNil(legacyModel.entitiesByName["PersistedSnowRun"])
        XCTAssertNil(legacyModel.entitiesByName["PersistedSnowSegment"])

        let legacyContainer = NSPersistentContainer(
            name: PersistenceController.modelName,
            managedObjectModel: legacyModel
        )
        let legacyDescription = NSPersistentStoreDescription(url: storeURL)
        legacyDescription.type = NSSQLiteStoreType
        legacyContainer.persistentStoreDescriptions = [legacyDescription]
        try await loadPersistentStores(in: legacyContainer)

        let sessionID = UUID()
        let startDate = Date(timeIntervalSince1970: 1_700_030_000)
        let sportModeData = try JSONEncoder().encode(SportMode.skateboard(.streetPark))
        let legacyRecord = NSEntityDescription.insertNewObject(
            forEntityName: "PersistedSession",
            into: legacyContainer.viewContext
        )
        legacyRecord.setValue(sessionID, forKey: "id")
        legacyRecord.setValue(startDate, forKey: "startDate")
        legacyRecord.setValue(startDate.addingTimeInterval(180), forKey: "endDate")
        legacyRecord.setValue(sportModeData, forKey: "sportModeData")
        legacyRecord.setValue(PowerType.humanPowered.rawValue, forKey: "powerTypeRaw")
        legacyRecord.setValue(1.25, forKey: "distanceKilometers")
        legacyRecord.setValue(31.5, forKey: "maxSpeedKilometersPerHour")
        legacyRecord.setValue(18.75, forKey: "averageSpeedKilometersPerHour")
        legacyRecord.setValue(42.0, forKey: "elevationGainMeters")
        legacyRecord.setValue(0.8, forKey: "movingRatio")
        legacyRecord.setValue(Data("[]".utf8), forKey: "trickEventsData")
        legacyRecord.setValue(startDate, forKey: "createdAt")
        legacyRecord.setValue(startDate, forKey: "updatedAt")
        try legacyContainer.viewContext.save()

        let legacyMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        )
        let legacyStoreUUID = try XCTUnwrap(legacyMetadata[NSStoreUUIDKey] as? String)
        for store in legacyContainer.persistentStoreCoordinator.persistentStores {
            try legacyContainer.persistentStoreCoordinator.remove(store)
        }

        let migratedController = PersistenceController(inMemory: false, storeURL: storeURL)
        let request = NSFetchRequest<NSManagedObject>(entityName: "PersistedSession")
        request.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
        let migratedRecord = try XCTUnwrap(migratedController.viewContext.fetch(request).first)

        XCTAssertEqual(migratedRecord.value(forKey: "id") as? UUID, sessionID)
        XCTAssertEqual(migratedRecord.value(forKey: "startDate") as? Date, startDate)
        XCTAssertEqual(migratedRecord.value(forKey: "sportModeData") as? Data, sportModeData)
        XCTAssertEqual(migratedRecord.value(forKey: "powerTypeRaw") as? String, PowerType.humanPowered.rawValue)
        XCTAssertEqual(migratedRecord.value(forKey: "distanceKilometers") as? Double, 1.25)
        XCTAssertEqual(migratedRecord.value(forKey: "maxSpeedKilometersPerHour") as? Double, 31.5)

        let migratedStore = try XCTUnwrap(
            migratedController.container.persistentStoreCoordinator.persistentStores.first
        )
        let migratedMetadata = migratedController.container.persistentStoreCoordinator.metadata(for: migratedStore)
        XCTAssertEqual(migratedMetadata[NSStoreUUIDKey] as? String, legacyStoreUUID)
        XCTAssertNotNil(migratedController.container.managedObjectModel.entitiesByName["PersistedSnowRun"])
        XCTAssertNotNil(migratedController.container.managedObjectModel.entitiesByName["PersistedSnowSegment"])

        let snowRepository = SnowSessionRepository(persistenceController: migratedController)
        let runID = UUID()
        let snowRun = SnowRun(
            id: runID,
            sessionID: sessionID,
            runNumber: 1,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(90),
            skiDistanceMeters: 640,
            verticalDropMeters: 120,
            topSpeedMetersPerSecond: 14,
            averageSpeedMetersPerSecond: 7,
            segmentIDs: []
        )
        try await snowRepository.saveRun(snowRun)
        let fetchedSnowRun = try await snowRepository.fetchRun(id: runID)
        XCTAssertEqual(fetchedSnowRun, snowRun)
    }

    private func makeLegacyTask021bModel() -> NSManagedObjectModel {
        let model = PersistenceController.makeManagedObjectModel()
        let snowEntityNames = Set(["PersistedSnowRun", "PersistedSnowSegment"])
        model.entities = model.entities.filter { entity in
            guard let name = entity.name else { return true }
            return !snowEntityNames.contains(name)
        }
        model.versionIdentifiers = ["Task021b"]
        return model
    }

    private func loadPersistentStores(in container: NSPersistentContainer) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
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
