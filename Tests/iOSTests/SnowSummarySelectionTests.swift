// [協作區] SnowSummarySelectionTests.swift
// 用途：驗證 A008R1 Snow timeline 的確定性選取、session 切換與 inspector 唯讀映射。

import XCTest
@testable import SkateTrack_iOS

final class SnowSummarySelectionTests: XCTestCase {
    func testSameRawRouteFormatsIdenticallyForSummaryTimelineAndInspector() {
        let locale = Locale(identifier: "en_US")
        let routeDistanceMeters = 600.0
        let generalSummary = UnitFormatter.distance(
            meters: routeDistanceMeters,
            locale: locale,
            maximumFractionDigits: 2
        )
        let timeline = SnowSummaryFormatters.distance(routeDistanceMeters, locale: locale)
        let inspector = SnowSummaryFormatters.distance(routeDistanceMeters, locale: locale)

        XCTAssertEqual(timeline, generalSummary)
        XCTAssertEqual(inspector, generalSummary)
        XCTAssertTrue(generalSummary.contains("0.6"))
        XCTAssertFalse(generalSummary.contains("1 km"))
    }

    func testDistanceFormatterAllowsTwoFractionDigitsWithoutForcedTrailingZeroes() {
        let formatter = NumberFormatter.skateTrackDistance(
            locale: Locale(identifier: "en_US"),
            maximumFractionDigits: 2
        )

        XCTAssertEqual(formatter.minimumFractionDigits, 0)
        XCTAssertEqual(formatter.maximumFractionDigits, 2)
        XCTAssertEqual(formatter.string(from: NSNumber(value: 0.6)), "0.6")
        XCTAssertEqual(formatter.string(from: NSNumber(value: 0.61)), "0.61")
    }

    func testUnknownOnlyMovementSelectsExplanatoryStatus() {
        let state = makeUnknownOnlyState(distanceMeters: 600)

        XCTAssertEqual(SnowDaySummaryPresentation.resolve(for: state), .unknownOnly)
        XCTAssertTrue(state.runs.isEmpty)
        XCTAssertEqual(state.distanceBreakdown.skiDistanceMeters, 0, accuracy: 0.001)
        XCTAssertEqual(state.distanceBreakdown.liftDistanceMeters, 0, accuracy: 0.001)
        XCTAssertEqual(state.distanceBreakdown.unknownDistanceMeters, 600, accuracy: 0.001)
    }

    func testTrulyEmptyStateRemainsDistinctFromUnknownOnlyMovement() {
        let state = SnowSessionState(
            sessionID: UUID(),
            loadState: .empty,
            runs: [],
            segments: []
        )

        XCTAssertEqual(SnowDaySummaryPresentation.resolve(for: state), .empty)
    }

    func testClassifiedDownhillStateRetainsMetricTiles() {
        let fixture = makeFixture()

        XCTAssertEqual(
            SnowDaySummaryPresentation.resolve(for: fixture.state),
            .classifiedMetrics
        )
    }

    func testDefaultSelectionUsesFirstOrderedRun() {
        let fixture = makeFixture()

        XCTAssertEqual(
            SnowSummarySelectionModel.resolvedSelection(current: nil, state: fixture.state),
            .run(fixture.firstRun.id)
        )
    }

    func testSegmentSelectionUpdatesInspectorToExactSegment() {
        let fixture = makeFixture()
        let snapshot = SnowSummarySelectionModel.inspectorSnapshot(
            current: .segment(fixture.liftSegment.id),
            state: fixture.state
        )

        XCTAssertEqual(snapshot.selection, .segment(fixture.liftSegment.id))
        XCTAssertEqual(snapshot.context, .segment(.gondolaAscent))
        XCTAssertEqual(snapshot.breakdown.skiDistanceMeters, 0, accuracy: 0.001)
        XCTAssertEqual(snapshot.breakdown.liftDistanceMeters, fixture.liftSegment.distanceMeters, accuracy: 0.001)
        XCTAssertEqual(snapshot.breakdown.routeDistanceMeters, fixture.liftSegment.distanceMeters, accuracy: 0.001)
    }

    func testRunSelectionMapsOnlyAssociatedSegments() {
        let fixture = makeFixture()
        let snapshot = SnowSummarySelectionModel.inspectorSnapshot(
            current: .run(fixture.firstRun.id),
            state: fixture.state
        )

        XCTAssertEqual(snapshot.context, .run(1))
        XCTAssertEqual(snapshot.breakdown.skiDistanceMeters, fixture.downhillSegment.distanceMeters, accuracy: 0.001)
        XCTAssertEqual(snapshot.breakdown.liftDistanceMeters, 0, accuracy: 0.001)
    }

    func testInvalidSelectionFallsBackDeterministically() {
        let fixture = makeFixture()

        XCTAssertEqual(
            SnowSummarySelectionModel.resolvedSelection(
                current: .segment(UUID()),
                state: fixture.state
            ),
            .run(fixture.firstRun.id)
        )
    }

    func testDisplayedSessionChangeDropsOldSelection() {
        let oldFixture = makeFixture()
        let newRun = SnowRun(
            sessionID: UUID(),
            runNumber: 1,
            startDate: Date(timeIntervalSince1970: 2_000),
            endDate: Date(timeIntervalSince1970: 2_120),
            skiDistanceMeters: 500
        )
        let newState = SnowSessionState(
            sessionID: newRun.sessionID,
            loadState: .loaded,
            runs: [newRun],
            segments: []
        )

        XCTAssertEqual(
            SnowSummarySelectionModel.resolvedSelection(
                current: .run(oldFixture.firstRun.id),
                state: newState
            ),
            .run(newRun.id)
        )
    }

    func testEmptyStateIsSafe() {
        let empty = SnowSessionState(
            sessionID: UUID(),
            loadState: .empty,
            runs: [],
            segments: []
        )
        let snapshot = SnowSummarySelectionModel.inspectorSnapshot(current: .segment(UUID()), state: empty)

        XCTAssertNil(SnowSummarySelectionModel.resolvedSelection(current: nil, state: empty))
        XCTAssertNil(snapshot.selection)
        XCTAssertEqual(snapshot.context, .session)
        XCTAssertEqual(snapshot.breakdown, .zero)
    }

    private func makeUnknownOnlyState(distanceMeters: Double) -> SnowSessionState {
        let sessionID = UUID()
        let segment = SnowSegment(
            sessionID: sessionID,
            type: .unknown,
            startDate: Date(timeIntervalSince1970: 3_000),
            endDate: Date(timeIntervalSince1970: 3_060),
            distanceMeters: distanceMeters,
            confidence: 0.32,
            countsTowardSkiDistance: false
        )
        return SnowSessionState(
            sessionID: sessionID,
            loadState: .loaded,
            runs: [],
            segments: [segment]
        )
    }

    private func makeFixture() -> (
        state: SnowSessionState,
        firstRun: SnowRun,
        downhillSegment: SnowSegment,
        liftSegment: SnowSegment
    ) {
        let sessionID = UUID()
        let runID = UUID()
        let downhillID = UUID()
        let firstRun = SnowRun(
            id: runID,
            sessionID: sessionID,
            runNumber: 1,
            startDate: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 1_120),
            skiDistanceMeters: 900,
            verticalDropMeters: 220,
            segmentIDs: [downhillID]
        )
        let downhill = SnowSegment(
            id: downhillID,
            sessionID: sessionID,
            runID: runID,
            type: .downhillRun,
            startDate: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 1_120),
            distanceMeters: 900,
            verticalDeltaMeters: -220,
            confidence: 0.9
        )
        let lift = SnowSegment(
            sessionID: sessionID,
            type: .gondolaAscent,
            startDate: Date(timeIntervalSince1970: 1_130),
            endDate: Date(timeIntervalSince1970: 1_300),
            distanceMeters: 1_100,
            verticalDeltaMeters: 250,
            confidence: 0.88
        )
        return (
            SnowSessionState(
                sessionID: sessionID,
                loadState: .loaded,
                runs: [firstRun],
                segments: [downhill, lift]
            ),
            firstRun,
            downhill,
            lift
        )
    }
}
