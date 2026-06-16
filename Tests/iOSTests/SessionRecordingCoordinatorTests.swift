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


    func testSnowSessionStartsLiveCoordinatorAndForwardsSamples() async throws {
        let sensorEngine = MockSessionSensorEngine()
        let snowLiveCoordinator = MockSnowLiveSessionCoordinator()
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: sensorEngine,
            fallDetectionEngine: MockFallDetectionEngine(),
            snowLiveCoordinator: snowLiveCoordinator
        )

        try await coordinator.startSession(mode: .snow(.skiing), powerType: .humanPowered)

        XCTAssertEqual(snowLiveCoordinator.startedSessionIDs.count, 1)
        XCTAssertTrue(snowLiveCoordinator.currentState.isActive)
        XCTAssertEqual(snowLiveCoordinator.currentState.sessionID, snowLiveCoordinator.startedSessionIDs.first)

        let sample = MotionSample(
            timestamp: Date(timeIntervalSince1970: 10),
            gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
            speedKmh: 18,
            accelerometerG: ThreeAxisValue(x: 0.05, y: 0.12, z: 0.98),
            gyroscopeRadPS: ThreeAxisValue(x: 0.01, y: 0.02, z: 0.03),
            altitudeMeters: 120
        )
        sensorEngine.emit(sample)

        XCTAssertEqual(snowLiveCoordinator.ingestedSamples, [sample])

        try await coordinator.pauseSession()
        XCTAssertEqual(snowLiveCoordinator.pauseCount, 1)
        XCTAssertTrue(snowLiveCoordinator.currentState.isPaused)

        try await coordinator.resumeSession()
        XCTAssertEqual(snowLiveCoordinator.resumeCount, 1)
        XCTAssertFalse(snowLiveCoordinator.currentState.isPaused)

        let sessionData = try await coordinator.requestEndSession()
        XCTAssertEqual(sessionData.sportMode, .snow(.skiing))
        XCTAssertEqual(sessionData.id, snowLiveCoordinator.startedSessionIDs.first)
        XCTAssertEqual(snowLiveCoordinator.finishCount, 1)
    }

    func testNonSnowSessionDoesNotForwardSamplesToSnowLiveCoordinator() async throws {
        let sensorEngine = MockSessionSensorEngine()
        let snowLiveCoordinator = MockSnowLiveSessionCoordinator()
        let coordinator = SessionRecordingCoordinator(
            sensorEngine: sensorEngine,
            fallDetectionEngine: MockFallDetectionEngine(),
            snowLiveCoordinator: snowLiveCoordinator
        )

        try await coordinator.startSession(mode: .skateboard(.streetPark), powerType: .humanPowered)

        let sample = MotionSample(
            timestamp: Date(timeIntervalSince1970: 10),
            gpsCoordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
            speedKmh: 18,
            accelerometerG: ThreeAxisValue(x: 0.05, y: 0.12, z: 0.98),
            gyroscopeRadPS: ThreeAxisValue(x: 0.01, y: 0.02, z: 0.03),
            altitudeMeters: 120
        )
        sensorEngine.emit(sample)

        XCTAssertTrue(snowLiveCoordinator.startedSessionIDs.isEmpty)
        XCTAssertTrue(snowLiveCoordinator.ingestedSamples.isEmpty)
        XCTAssertEqual(snowLiveCoordinator.pauseCount, 0)
        XCTAssertEqual(snowLiveCoordinator.resumeCount, 0)

        _ = try await coordinator.requestEndSession()
        XCTAssertEqual(snowLiveCoordinator.finishCount, 0)
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
    private var currentMode: SportMode = .skateboard(.streetPark)

    var motionSamplePublisher: AnyPublisher<MotionSample, Never> {
        motionSampleSubject.eraseToAnyPublisher()
    }

    func startRecording(mode: SportMode) async throws {
        currentMode = mode
    }

    func stopRecording() async -> SessionData {
        stopCalled = true
        return try! SessionData(
            startDate: Date(),
            endDate: Date(),
            sportMode: currentMode,
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


private final class MockSnowLiveSessionCoordinator: SnowLiveSessionCoordinating {
    private let subject = CurrentValueSubject<SnowLiveSessionState, Never>(.empty)
    private(set) var startedSessionIDs: [UUID] = []
    private(set) var ingestedSamples: [MotionSample] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var finishCount = 0
    private(set) var resetCount = 0

    var statePublisher: AnyPublisher<SnowLiveSessionState, Never> {
        subject.eraseToAnyPublisher()
    }

    var currentState: SnowLiveSessionState {
        subject.value
    }

    func start(sessionID: UUID) {
        startedSessionIDs.append(sessionID)
        var state = SnowLiveSessionState.empty
        state.sessionID = sessionID
        state.isActive = true
        subject.send(state)
    }

    func ingest(_ sample: MotionSample) {
        ingestedSamples.append(sample)
        var state = subject.value
        state.currentSpeedKmh = sample.speedKmh
        subject.send(state)
    }

    func pause() {
        pauseCount += 1
        var state = subject.value
        state.isPaused = true
        subject.send(state)
    }

    func resume() {
        resumeCount += 1
        var state = subject.value
        state.isPaused = false
        subject.send(state)
    }

    func manuallyEndCurrentRun() async {}

    func finishSession() async {
        finishCount += 1
        var state = subject.value
        state.isActive = false
        state.isPaused = false
        subject.send(state)
    }

    func reset() {
        resetCount += 1
        subject.send(.empty)
    }
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
