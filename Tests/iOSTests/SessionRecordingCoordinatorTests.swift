import Combine
@testable import SkateTrack_iOS
import XCTest

final class SessionRecordingCoordinatorTests: XCTestCase {
    func testStateMachineRejectsIdleToRecordingTransition() {
        var stateMachine = SessionStateMachine()
        XCTAssertFalse(stateMachine.canTransition(from: .idle, to: .recording))

        XCTAssertThrowsError(try stateMachine.transition(to: .recording)) { error in
            XCTAssertEqual(
                error as? SessionStateTransitionError,
                .invalidTransition(from: .idle, to: .recording)
            )
        }
    }

    func testStateMachineAllowsExpectedLifecycleTransitions() throws {
        var stateMachine = SessionStateMachine()

        try stateMachine.transition(to: .preparing)
        try stateMachine.transition(to: .recording)
        try stateMachine.transition(to: .paused)
        try stateMachine.transition(to: .recording)
        try stateMachine.transition(to: .ending)
        try stateMachine.transition(to: .saving)
        try stateMachine.transition(to: .idle)

        XCTAssertEqual(stateMachine.status, .idle)
    }

    func testMetricsAccumulatorAccumulatesDistanceAndMaxSpeed() {
        var accumulator = SessionMetricsAccumulator()
        accumulator.beginSession(at: Date(timeIntervalSince1970: 0))

        let baseDate = Date(timeIntervalSince1970: 0)
        for index in 0..<10 {
            let timestamp = baseDate.addingTimeInterval(Double(index + 1))
            let sample = MotionSample(
                timestamp: timestamp,
                gpsCoordinate: GeoCoordinate(
                    latitude: 25.033 + (Double(index) * 0.0001),
                    longitude: 121.565 + (Double(index) * 0.0001)
                ),
                speedKmh: Double(index + 1),
                accelerometerG: ThreeAxisValue(x: 0, y: 0.1, z: 0.98),
                gyroscopeRadPS: .zero,
                altitudeMeters: 10 + Double(index)
            )
            accumulator.process(sample)
        }

        let liveMetrics = accumulator.makeLiveMetrics()
        XCTAssertEqual(liveMetrics.maxSpeedKilometersPerHour, 10, accuracy: 0.001)
        XCTAssertGreaterThan(liveMetrics.distanceKilometers, 0)
        XCTAssertEqual(liveMetrics.elapsedTime, 10, accuracy: 0.001)
    }

    func testAltitudeOutlierGuardRejectsImplausibleJumpAndKeepsTrustedAnchorStable() {
        var guardEngine = AltitudeOutlierGuard()
        let config = AltitudeOutlierGuardConfig(
            maxCoreLocationVerticalAccuracyMeters: 15,
            maxCoreLocationVerticalSpeedMetersPerSecond: 3,
            hardCoreLocationJumpRejectMeters: 30
        )
        let start = Date(timeIntervalSince1970: 10_000)
        let diagnostics = LocationFixDiagnostics(
            verticalAccuracyMeters: 8,
            freshnessState: .fresh,
            routeSegmentConfidence: .high
        )

        let first = guardEngine.evaluate(
            altitudeMeters: 10,
            source: .coreLocationAbsolute,
            timestamp: start,
            verticalAccuracyMeters: 8,
            locationDiagnostics: diagnostics,
            sessionStartDate: start,
            config: config
        )

        let spike = guardEngine.evaluate(
            altitudeMeters: 110,
            source: .coreLocationAbsolute,
            timestamp: start.addingTimeInterval(2),
            verticalAccuracyMeters: 8,
            locationDiagnostics: diagnostics,
            sessionStartDate: start,
            config: config
        )

        let recovery = guardEngine.evaluate(
            altitudeMeters: 11,
            source: .coreLocationAbsolute,
            timestamp: start.addingTimeInterval(20),
            verticalAccuracyMeters: 8,
            locationDiagnostics: diagnostics,
            sessionStartDate: start,
            config: config
        )

        XCTAssertEqual(first.trustClassification, .trusted)
        XCTAssertEqual(first.reason, .firstTrustedAnchor)
        XCTAssertEqual(spike.trustClassification, .rejectedOutlier)
        XCTAssertEqual(spike.reason, .hardAltitudeJump)
        XCTAssertEqual(spike.trustedAltitudeMeters!, 10, accuracy: 0.001)
        XCTAssertFalse(spike.updatesTrustedAltitudeAnchor)
        XCTAssertEqual(recovery.trustClassification, .trusted)
        XCTAssertEqual(recovery.previousTrustedAltitudeMeters!, 10, accuracy: 0.001)
        XCTAssertEqual(recovery.trustedAltitudeMeters!, 11, accuracy: 0.001)
    }

    func testAltitudeOutlierGuardClassifiesPoorVerticalAccuracyWithoutDroppingHorizontalSample() {
        var guardEngine = AltitudeOutlierGuard()
        let config = AltitudeOutlierGuardConfig(
            maxCoreLocationVerticalAccuracyMeters: 15,
            maxCoreLocationVerticalSpeedMetersPerSecond: 3
        )
        let timestamp = Date(timeIntervalSince1970: 20_000)
        let diagnostics = LocationFixDiagnostics(
            horizontalAccuracyMeters: 5,
            verticalAccuracyMeters: 45,
            freshnessState: .fresh,
            routeSegmentConfidence: .high
        )

        let altitudeDiagnostics = guardEngine.evaluate(
            altitudeMeters: 42,
            source: .coreLocationAbsolute,
            timestamp: timestamp,
            verticalAccuracyMeters: 45,
            locationDiagnostics: diagnostics,
            sessionStartDate: timestamp,
            config: config
        )
        let sample = MotionSample(
            timestamp: timestamp,
            gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
            speedKmh: 6,
            accelerometerG: .zero,
            gyroscopeRadPS: .zero,
            altitudeMeters: 42,
            altitudeSource: .coreLocationAbsolute,
            altitudeDiagnostics: altitudeDiagnostics,
            locationDiagnostics: diagnostics,
            sampleSource: .locationFix
        )

        XCTAssertEqual(sample.altitudeDiagnostics?.trustClassification, .lowConfidence)
        XCTAssertEqual(sample.altitudeDiagnostics?.reason, .verticalAccuracyTooPoor)
        XCTAssertNotNil(sample.gpsCoordinate, "b12-A must isolate only altitude; horizontal coordinates remain available.")
    }

    func testMetricsAccumulatorIgnoresRejectedAltitudeOutlierButPreservesDistance() {
        var accumulator = SessionMetricsAccumulator()
        let start = Date(timeIntervalSince1970: 30_000)
        accumulator.beginSession(at: start)

        let samples = [
            MotionSample(
                timestamp: start.addingTimeInterval(1),
                gpsCoordinate: GeoCoordinate(latitude: 25.0330, longitude: 121.5650),
                speedKmh: 8,
                accelerometerG: .zero,
                gyroscopeRadPS: .zero,
                altitudeMeters: 10,
                altitudeSource: .coreLocationAbsolute,
                altitudeDiagnostics: AltitudeDiagnostics(
                    source: .coreLocationAbsolute,
                    trustClassification: .trusted,
                    reason: .firstTrustedAnchor,
                    rawAltitudeMeters: 10,
                    trustedAltitudeMeters: 10,
                    updatesTrustedAltitudeAnchor: true
                )
            ),
            MotionSample(
                timestamp: start.addingTimeInterval(2),
                gpsCoordinate: GeoCoordinate(latitude: 25.0331, longitude: 121.5651),
                speedKmh: 8,
                accelerometerG: .zero,
                gyroscopeRadPS: .zero,
                altitudeMeters: 110,
                altitudeSource: .coreLocationAbsolute,
                altitudeDiagnostics: AltitudeDiagnostics(
                    source: .coreLocationAbsolute,
                    trustClassification: .rejectedOutlier,
                    reason: .hardAltitudeJump,
                    rawAltitudeMeters: 110,
                    trustedAltitudeMeters: 10,
                    previousTrustedAltitudeMeters: 10,
                    altitudeDeltaMeters: 100,
                    timeDeltaSeconds: 1,
                    verticalSpeedMetersPerSecond: 100,
                    rejectedByOutlierGuard: true,
                    updatesTrustedAltitudeAnchor: false
                )
            ),
            MotionSample(
                timestamp: start.addingTimeInterval(20),
                gpsCoordinate: GeoCoordinate(latitude: 25.0332, longitude: 121.5652),
                speedKmh: 8,
                accelerometerG: .zero,
                gyroscopeRadPS: .zero,
                altitudeMeters: 11,
                altitudeSource: .coreLocationAbsolute,
                altitudeDiagnostics: AltitudeDiagnostics(
                    source: .coreLocationAbsolute,
                    trustClassification: .trusted,
                    reason: .coreLocationAbsoluteAccepted,
                    rawAltitudeMeters: 11,
                    trustedAltitudeMeters: 11,
                    previousTrustedAltitudeMeters: 10,
                    altitudeDeltaMeters: 1,
                    timeDeltaSeconds: 19,
                    verticalSpeedMetersPerSecond: 1.0 / 19.0,
                    updatesTrustedAltitudeAnchor: true
                )
            )
        ]

        samples.forEach { accumulator.process($0) }

        XCTAssertEqual(accumulator.elevationGainMeters, 1, accuracy: 0.001)
        XCTAssertGreaterThan(accumulator.distanceKilometers, 0, "Altitude rejection must not fracture horizontal distance accumulation.")
    }

    func testStartSessionRejectsElectricInlinePowerType() async {
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: MockSessionSensorEngine(),
            fallDetectionEngine: MockFallDetectionEngine()
        )

        do {
            try await coordinator.startSession(mode: .inline(.urbanFreestyle), powerType: .electric)
            XCTFail("Expected invalidPowerType error")
        } catch let error as SessionRecordingError {
            XCTAssertEqual(error, .invalidPowerType)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestEndSessionReturnsCompleteSessionData() async throws {
        let sensorEngine = MockSessionSensorEngine()
        let repository = MockSessionRepository()
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: sensorEngine,
            fallDetectionEngine: MockFallDetectionEngine(),
            sessionRepository: repository
        )

        try await coordinator.startSession(mode: .skateboard(.streetPark), powerType: .humanPowered)

        let baseDate = Date()
        for index in 0..<3 {
            sensorEngine.emit(
                MotionSample(
                    timestamp: baseDate.addingTimeInterval(Double(index + 1)),
                    gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
                    speedKmh: 10,
                    accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
                    gyroscopeRadPS: .zero
                )
            )
        }

        let sessionData = try await coordinator.requestEndSession()

        XCTAssertEqual(sessionData.sportMode, .skateboard(.streetPark))
        XCTAssertEqual(sessionData.powerType, .humanPowered)
        XCTAssertNotNil(sessionData.endDate)
        XCTAssertNotNil(sessionData.durationSeconds)
        XCTAssertNotNil(sessionData.summaryMetrics)
        XCTAssertEqual(repository.savedSessions.map(\.id), [sessionData.id])
        XCTAssertTrue(sensorEngine.stopCalled)
    }


    func testRequestEndSessionPersistsSelectedSpotSnapshot() async throws {
        let sensorEngine = MockSessionSensorEngine()
        let repository = MockSessionRepository()
        let spotID = UUID()
        let spotSnapshot = SpotSessionSnapshot(
            spotID: spotID,
            name: "Riverside Park",
            activityFamily: .mixed,
            coordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
            radiusMeters: 140
        )
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: sensorEngine,
            fallDetectionEngine: MockFallDetectionEngine(),
            sessionRepository: repository,
            spotVisitTracker: MockSpotVisitTracker()
        )

        try await coordinator.startSession(
            mode: .skateboard(.streetPark),
            powerType: .humanPowered,
            spotID: spotID,
            spotSnapshot: spotSnapshot
        )
        let sessionData = try await coordinator.requestEndSession()

        XCTAssertEqual(sessionData.spotID, spotID)
        XCTAssertEqual(sessionData.spotSnapshot, spotSnapshot)
        XCTAssertEqual(repository.savedSessions.first?.spotSnapshot, spotSnapshot)
    }

    func testRequestEndSessionPublishesOnlyAfterPersistenceSucceeds() async throws {
        let sensorEngine = MockSessionSensorEngine()
        let repository = MockSessionRepository()
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: sensorEngine,
            fallDetectionEngine: MockFallDetectionEngine(),
            sessionRepository: repository
        )
        var publishedSessions: [SessionData] = []
        let cancellable = coordinator.completedSessionPublisher
            .sink { publishedSessions.append($0) }

        try await coordinator.startSession(mode: .skateboard(.streetPark), powerType: .humanPowered)
        let sessionData = try await coordinator.requestEndSession()

        XCTAssertEqual(repository.savedSessions.map(\.id), [sessionData.id])
        XCTAssertEqual(publishedSessions.map(\.id), [sessionData.id])
        cancellable.cancel()
    }

    func testDiscardCurrentSessionDoesNotPersist() async throws {
        let repository = MockSessionRepository()
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: MockSessionSensorEngine(),
            fallDetectionEngine: MockFallDetectionEngine(),
            sessionRepository: repository
        )

        try await coordinator.startSession(mode: .skateboard(.streetPark), powerType: .humanPowered)
        await coordinator.discardCurrentSession()

        XCTAssertTrue(repository.savedSessions.isEmpty)
    }

    func testPersistenceFailurePublishesRepositoryError() async throws {
        let repository = MockSessionRepository()
        repository.saveError = .saveFailed
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: MockSessionSensorEngine(),
            fallDetectionEngine: MockFallDetectionEngine(),
            sessionRepository: repository
        )
        var errorKeys: [String] = []
        let cancellable = coordinator.errorPublisher.sink { errorKeys.append($0) }

        try await coordinator.startSession(mode: .skateboard(.streetPark), powerType: .humanPowered)

        do {
            _ = try await coordinator.requestEndSession()
            XCTFail("Expected repository save failure")
        } catch let error as RepositoryError {
            XCTAssertEqual(error, .saveFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(errorKeys.contains(RepositoryError.saveFailed.localizationKey))
        XCTAssertEqual(coordinator.status, .failed)
        cancellable.cancel()
    }

    func testCoreSessionRecordingFilesDoNotImportUIFrameworks() throws {
        let coreDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("iOS/Core/SessionRecording")

        let forbiddenImports = ["import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"]
        let files = try FileManager.default.contentsOfDirectory(at: coreDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }

        for file in files {
            let contents = try String(contentsOf: file)
            for forbiddenImport in forbiddenImports {
                XCTAssertFalse(
                    contents.contains(forbiddenImport),
                    "\(file.lastPathComponent) must not contain \(forbiddenImport)"
                )
            }
        }
    }
}

private final class MockSessionSensorEngine: SessionSensorProviding {
    let motionSampleSubject = PassthroughSubject<MotionSample, Never>()
    private(set) var stopCalled = false

    var motionSamplePublisher: AnyPublisher<MotionSample, Never> {
        motionSampleSubject.eraseToAnyPublisher()
    }

    func startRecording(mode: SportMode, powerType: PowerType, fidelityProfile: ActivityFidelityProfile?) async throws {}

    func stopRecording() async -> SessionData {
        stopCalled = true
        return try! SessionData(
            startDate: Date(),
            endDate: Date(),
            sportMode: .skateboard(.streetPark),
            powerType: .humanPowered
        )
    }

    func emit(_ sample: MotionSample) {
        motionSampleSubject.send(sample)
    }
}

private final class MockFallDetectionEngine: SessionFallDetecting {
    let fallEventSubject = PassthroughSubject<FallEvent, Never>()
    let sosTriggerSubject = PassthroughSubject<FallEvent, Never>()
    let countdownSubject = CurrentValueSubject<Int?, Never>(nil)
    private(set) var detectedFallEvents: [FallEvent] = []

    var fallEventPublisher: AnyPublisher<FallEvent, Never> {
        fallEventSubject.eraseToAnyPublisher()
    }

    var sosTriggerPublisher: AnyPublisher<FallEvent, Never> {
        sosTriggerSubject.eraseToAnyPublisher()
    }

    var countdownPublisher: AnyPublisher<Int?, Never> {
        countdownSubject.eraseToAnyPublisher()
    }

    func startMonitoring(samples: AnyPublisher<MotionSample, Never>, mode: SportMode) {}

    func stopMonitoring() {}

    func cancelFallAlert() {}
}

private actor MockSpotVisitTracker: SpotVisitTracking {
    @discardableResult
    func applyVisitIfNeeded(to session: SessionData) async throws -> SpotVisitTrackingResult {
        guard let spotID = session.spotID else { return .skippedNoSpot }
        return .applied(spotID: spotID, sessionID: session.id)
    }
}

private final class MockSessionRepository: SessionRepositoryProtocol, @unchecked Sendable {
    var savedSessions: [SessionData] = []
    var saveError: RepositoryError?

    @discardableResult
    func saveCompletedSession(_ session: SessionData) async throws -> SessionData {
        if let saveError {
            throw saveError
        }
        savedSessions.append(session)
        return session
    }

    func fetchRecentSessions(limit: Int) async throws -> [SessionData] {
        Array(savedSessions.prefix(limit))
    }

    func fetchSession(id: UUID) async throws -> SessionData {
        guard let session = savedSessions.first(where: { $0.id == id }) else {
            throw RepositoryError.sessionNotFound
        }
        return session
    }

    func loadMotionSamples(for sessionID: UUID) async throws -> [MotionSample] {
        try await fetchSession(id: sessionID).motionSamples
    }

    func deleteSession(id: UUID) async throws {
        savedSessions.removeAll { $0.id == id }
    }

    func exportSessionBundle(id: UUID) async throws -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
    }
}
