// [協作區] SnowLiveSessionCoordinatorTests.swift
// 用途：驗證 A010R5 no-altitude Snow route 以既有 unknown segment 契約保存 residual distance。

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SnowLiveSessionCoordinatorTests: XCTestCase {
    private let sessionID = UUID(uuidString: "A010A010-A010-4010-8010-A010A010A010")!
    private let startDate = Date(timeIntervalSince1970: 1_720_000_000)

    func testNoAltitudeNonzeroRouteCreatesUnknownFallback() async throws {
        let repository = A010R5SnowRepository()
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)
        makeNoAltitudeSamples().forEach(coordinator.ingest)

        XCTAssertEqual(coordinator.currentState.latestClassification?.type, .unknown)
        XCTAssertTrue(coordinator.currentState.inMemorySegments.isEmpty)

        await finish(coordinator, trustedRouteDistanceMeters: 432.592)
        let segments = await repository.allSegments()

        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments.first?.type, .unknown)
        XCTAssertEqual(segments.first?.distanceMeters ?? 0, 432.592, accuracy: 0.001)
    }

    func testFallbackRouteAndUnknownEqualTrustedRouteWhileSkiAndLiftRemainZero() async {
        let repository = A010R5SnowRepository()
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)

        await finish(coordinator, trustedRouteDistanceMeters: 510.25)
        let breakdown = coordinator.currentState.distanceBreakdown

        XCTAssertEqual(breakdown.routeDistanceMeters, 510.25, accuracy: 0.001)
        XCTAssertEqual(breakdown.unknownDistanceMeters, 510.25, accuracy: 0.001)
        XCTAssertEqual(breakdown.skiDistanceMeters, 0, accuracy: 0.001)
        XCTAssertEqual(breakdown.liftDistanceMeters, 0, accuracy: 0.001)
    }

    func testFallbackPreservesSessionIDAndHasNoRunID() async {
        let repository = A010R5SnowRepository()
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)

        await finish(coordinator, trustedRouteDistanceMeters: 80)
        let segment = await repository.allSegments().first

        XCTAssertEqual(segment?.sessionID, sessionID)
        XCTAssertNil(segment?.runID)
        XCTAssertEqual(segment?.countsTowardSkiDistance, false)
    }

    func testRepeatedFinishIsIdempotent() async {
        let repository = A010R5SnowRepository()
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)

        await finish(coordinator, trustedRouteDistanceMeters: 275)
        await finish(coordinator, trustedRouteDistanceMeters: 275)
        let saveCount = await repository.saveSegmentCallCount()
        let segments = await repository.allSegments()

        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(coordinator.currentState.distanceBreakdown.routeDistanceMeters, 275, accuracy: 0.001)
    }

    func testPartialExistingRouteCreatesOnlyResidualUnknownDistance() async {
        let existing = makeSegment(type: .downhillRun, distanceMeters: 120, countsTowardSkiDistance: true)
        let repository = A010R5SnowRepository(segments: [existing])
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)

        await finish(coordinator, trustedRouteDistanceMeters: 500)
        let segments = await repository.allSegments()
        let fallback = segments.first { $0.id != existing.id }

        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments.first { $0.id == existing.id }?.distanceMeters ?? 0, 120, accuracy: 0.001)
        XCTAssertEqual(fallback?.type, .unknown)
        XCTAssertEqual(fallback?.distanceMeters ?? 0, 380, accuracy: 0.001)
        XCTAssertEqual(coordinator.currentState.distanceBreakdown.routeDistanceMeters, 500, accuracy: 0.001)
        XCTAssertEqual(coordinator.currentState.distanceBreakdown.skiDistanceMeters, 120, accuracy: 0.001)
    }

    func testExistingRouteEqualToTrustedRouteCreatesNoFallback() async {
        let existing = makeSegment(type: .downhillRun, distanceMeters: 500, countsTowardSkiDistance: true)
        let repository = A010R5SnowRepository(segments: [existing])
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)

        await finish(coordinator, trustedRouteDistanceMeters: 500)
        let saveCount = await repository.saveSegmentCallCount()
        let segments = await repository.allSegments()

        XCTAssertEqual(saveCount, 0)
        XCTAssertEqual(segments, [existing])
    }

    func testExistingRouteAboveTrustedRouteCreatesNoNegativeFallback() async {
        let existing = makeSegment(type: .liftAscent, distanceMeters: 600, countsTowardSkiDistance: false)
        let repository = A010R5SnowRepository(segments: [existing])
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)

        await finish(coordinator, trustedRouteDistanceMeters: 500)
        let saveCount = await repository.saveSegmentCallCount()
        let distances = await repository.allSegments().map(\.distanceMeters)

        XCTAssertEqual(saveCount, 0)
        XCTAssertEqual(distances, [600])
    }

    func testZeroAndNonfiniteTrustedRoutesCreateNoFallback() async {
        for trustedRouteDistanceMeters in [0, -1, .nan, .infinity] {
            let repository = A010R5SnowRepository()
            let coordinator = SnowLiveSessionCoordinator(repository: repository)
            coordinator.start(sessionID: sessionID)

            await finish(coordinator, trustedRouteDistanceMeters: trustedRouteDistanceMeters)
            let saveCount = await repository.saveSegmentCallCount()
            let segments = await repository.allSegments()

            XCTAssertEqual(saveCount, 0)
            XCTAssertTrue(segments.isEmpty)
        }
    }

    func testFallbackIsTerminalAndDoesNotClaimSourceSamples() async {
        let existing = makeSegment(type: .downhillRun, distanceMeters: 100, countsTowardSkiDistance: true)
        let repository = A010R5SnowRepository(segments: [existing])
        let coordinator = SnowLiveSessionCoordinator(repository: repository)
        coordinator.start(sessionID: sessionID)

        await finish(coordinator, trustedRouteDistanceMeters: 125)
        let fallback = await repository.allSegments().first { $0.id != existing.id }

        XCTAssertEqual(fallback?.startDate, existing.endDate)
        XCTAssertEqual(fallback?.endDate, startDate.addingTimeInterval(59))
        XCTAssertEqual(fallback?.sourceSampleIDs, [])
        XCTAssertEqual(fallback?.manualOverride, false)
    }

    private func finish(
        _ coordinator: SnowLiveSessionCoordinator,
        trustedRouteDistanceMeters: Double
    ) async {
        await coordinator.finishSession(
            trustedRouteDistanceMeters: trustedRouteDistanceMeters,
            sessionStartDate: startDate,
            sessionEndDate: startDate.addingTimeInterval(59)
        )
    }

    private func makeSegment(
        type: SnowSegmentType,
        distanceMeters: Double,
        countsTowardSkiDistance: Bool
    ) -> SnowSegment {
        SnowSegment(
            sessionID: sessionID,
            type: type,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(30),
            distanceMeters: distanceMeters,
            confidence: 0.9,
            countsTowardSkiDistance: countsTowardSkiDistance
        )
    }

    private func makeNoAltitudeSamples() -> [MotionSample] {
        (0..<35).map { index in
            MotionSample(
                timestamp: startDate.addingTimeInterval(Double(index)),
                gpsCoordinate: GeoCoordinate(
                    latitude: 46 + Double(index) * 0.00002,
                    longitude: 7 + Double(index) * 0.00001
                ),
                speedKmh: 13,
                accelerometerG: ThreeAxisValue(x: 0.08, y: 0.03, z: 1.0),
                gyroscopeRadPS: ThreeAxisValue(x: 0.01, y: 0.02, z: 0.03),
                altitudeMeters: nil
            )
        }
    }
}

private actor A010R5SnowRepository: SnowSessionRepositoryProtocol {
    private var runs: [SnowRun]
    private var segments: [SnowSegment]
    private var segmentSaveCount = 0

    init(runs: [SnowRun] = [], segments: [SnowSegment] = []) {
        self.runs = runs
        self.segments = segments
    }

    func saveRun(_ run: SnowRun) async throws -> SnowRun {
        runs.removeAll { $0.id == run.id }
        runs.append(run)
        return run
    }

    func saveSegment(_ segment: SnowSegment) async throws -> SnowSegment {
        segmentSaveCount += 1
        segments.removeAll { $0.id == segment.id }
        segments.append(segment)
        return segment
    }

    func fetchRuns(sessionID: UUID) async throws -> [SnowRun] {
        runs.filter { $0.sessionID == sessionID }
    }

    func fetchSegments(sessionID: UUID) async throws -> [SnowSegment] {
        segments.filter { $0.sessionID == sessionID }
    }

    func fetchRun(id: UUID) async throws -> SnowRun {
        guard let run = runs.first(where: { $0.id == id }) else { throw RepositoryError.snowRunNotFound }
        return run
    }

    func fetchSegment(id: UUID) async throws -> SnowSegment {
        guard let segment = segments.first(where: { $0.id == id }) else { throw RepositoryError.snowSegmentNotFound }
        return segment
    }

    func fetchState(sessionID: UUID) async throws -> SnowSessionState {
        let matchingRuns = runs.filter { $0.sessionID == sessionID }
        let matchingSegments = segments.filter { $0.sessionID == sessionID }
        return SnowSessionState(
            sessionID: sessionID,
            loadState: matchingRuns.isEmpty && matchingSegments.isEmpty ? .empty : .loaded,
            runs: matchingRuns,
            segments: matchingSegments
        )
    }

    func deleteRun(id: UUID) async throws { runs.removeAll { $0.id == id } }
    func deleteSegment(id: UUID) async throws { segments.removeAll { $0.id == id } }
    func deleteSnowData(sessionID: UUID) async throws {
        runs.removeAll { $0.sessionID == sessionID }
        segments.removeAll { $0.sessionID == sessionID }
    }

    func allSegments() -> [SnowSegment] {
        segments.sorted { $0.startDate < $1.startDate }
    }

    func saveSegmentCallCount() -> Int { segmentSaveCount }
}
