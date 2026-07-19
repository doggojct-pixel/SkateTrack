// [協作區] SnowLiveHUDStateMapperTests.swift
import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SnowLiveHUDStateMapperTests: XCTestCase {
    func testActiveDownhillMapsToDownhillWhenConfidenceIsAboveConfigThreshold() {
        let snowState = makeSnowState(
            snapshot: makeSnapshot(state: .active, type: .downhillRun, confidence: 0.84),
            classification: makeClassification(type: .downhillRun, confidence: 0.84),
            currentSpeedKmh: 32
        )
        let hudState = SnowLiveHUDStateMapper.map(
            snowState: snowState,
            recordingState: makeRecordingState(elapsedTime: 42),
            config: makeConfig(lowConfidenceThreshold: 0.62)
        )

        guard case let .downhill(model) = hudState else {
            XCTFail("Expected downhill HUD state")
            return
        }
        XCTAssertEqual(model.runNumber, 2)
        XCTAssertEqual(model.currentSpeedKmh, 32)
        XCTAssertEqual(model.elapsedTime, 42)
    }

    func testLiftTransportMapsToLiftWhenNotLowConfidence() {
        let segments = [
            SnowSegment(
                sessionID: sessionID,
                type: .liftAscent,
                startDate: baseDate,
                endDate: baseDate.addingTimeInterval(10),
                distanceMeters: 120,
                confidence: 0.82
            )
        ]
        var snowState = makeSnowState(
            snapshot: makeSnapshot(state: .between, type: .liftAscent, confidence: 0.82),
            classification: makeClassification(type: .liftAscent, confidence: 0.82),
            currentSpeedKmh: 9
        )
        snowState.inMemorySegments = segments
        snowState.distanceBreakdown = SnowDistanceBreakdown.make(from: segments)

        let hudState = SnowLiveHUDStateMapper.map(
            snowState: snowState,
            recordingState: makeRecordingState(),
            config: makeConfig(lowConfidenceThreshold: 0.62)
        )

        guard case let .lift(model) = hudState else {
            XCTFail("Expected lift HUD state")
            return
        }
        XCTAssertEqual(model.segmentType, .liftAscent)
        XCTAssertEqual(model.liftDistanceMeters, 120)
        XCTAssertEqual(model.messageLocalizationKey, "snow.hud.lift.notCounting")
    }

    func testBetweenStoppedMapsToWaitingWhenNotLowConfidence() {
        let lastRun = SnowRun(
            sessionID: sessionID,
            runNumber: 1,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(60),
            skiDistanceMeters: 300,
            verticalDropMeters: 80,
            topSpeedMetersPerSecond: 12
        )
        let snowState = makeSnowState(
            snapshot: makeSnapshot(state: .between, type: .stopped, confidence: 0.88, lastCompletedRun: lastRun),
            classification: makeClassification(type: .stopped, confidence: 0.88),
            currentSpeedKmh: 0,
            lastCompletedRun: lastRun
        )

        let hudState = SnowLiveHUDStateMapper.map(
            snowState: snowState,
            recordingState: makeRecordingState(),
            config: makeConfig(lowConfidenceThreshold: 0.62)
        )

        guard case let .waiting(model) = hudState else {
            XCTFail("Expected waiting HUD state")
            return
        }
        XCTAssertEqual(model.currentSegmentType, .stopped)
        XCTAssertEqual(model.lastRunVerticalDropMeters, 80)
        XCTAssertEqual(model.lastRunTopSpeedKmh ?? -1, 43.2, accuracy: 0.001)
    }

    func testUnknownMapsToLowConfidenceWhenConfigured() {
        let snowState = makeSnowState(
            snapshot: makeSnapshot(state: .idle, type: .unknown, confidence: 0.84),
            classification: makeClassification(type: .unknown, confidence: 0.84),
            currentSpeedKmh: 14
        )

        let hudState = SnowLiveHUDStateMapper.map(
            snowState: snowState,
            recordingState: makeRecordingState(),
            config: makeConfig(lowConfidenceThreshold: 0.20, lowConfidenceAlwaysForUnknown: true)
        )

        guard case let .lowConfidence(model) = hudState else {
            XCTFail("Expected low confidence HUD state")
            return
        }
        XCTAssertEqual(model.currentSegmentType, .unknown)
        XCTAssertEqual(model.confidence, 0.84)
    }

    func testConfidenceBelowInjectedConfigThresholdMapsToLowConfidence() {
        let snowState = makeSnowState(
            snapshot: makeSnapshot(state: .active, type: .downhillRun, confidence: 0.80),
            classification: makeClassification(type: .downhillRun, confidence: 0.80),
            currentSpeedKmh: 30
        )

        let hudState = SnowLiveHUDStateMapper.map(
            snowState: snowState,
            recordingState: makeRecordingState(),
            config: makeConfig(lowConfidenceThreshold: 0.90)
        )

        guard case let .lowConfidence(model) = hudState else {
            XCTFail("Expected low confidence when injected threshold is strict")
            return
        }
        XCTAssertEqual(model.confidence, 0.80)
    }

    func testConfiguredReasonCodeMapsToLowConfidenceEvenWhenConfidenceIsHigh() {
        let snowState = makeSnowState(
            snapshot: makeSnapshot(state: .active, type: .downhillRun, confidence: 0.91),
            classification: makeClassification(type: .downhillRun, confidence: 0.91, reasonCodes: ["missingAltitude"]),
            currentSpeedKmh: 25
        )

        let hudState = SnowLiveHUDStateMapper.map(
            snowState: snowState,
            recordingState: makeRecordingState(),
            config: makeConfig(lowConfidenceThreshold: 0.62, lowConfidenceReasonCodes: ["missingAltitude"])
        )

        guard case let .lowConfidence(model) = hudState else {
            XCTFail("Expected low confidence for configured reason code")
            return
        }
        XCTAssertEqual(model.reasonCodes, ["missingAltitude"])
    }

    private let sessionID = UUID(uuidString: "00000000-0000-0000-0000-000000000501")!
    private let baseDate = Date(timeIntervalSince1970: 1_800_000_500)

    private func makeConfig(
        lowConfidenceThreshold: Double,
        lowConfidenceAlwaysForUnknown: Bool = true,
        lowConfidenceReasonCodes: Set<String> = []
    ) -> SnowLiveSessionConfig {
        SnowLiveSessionConfig(
            classificationWindowSeconds: 15,
            lowConfidenceThreshold: lowConfidenceThreshold,
            lowConfidenceAlwaysForUnknown: lowConfidenceAlwaysForUnknown,
            lowConfidenceReasonCodes: lowConfidenceReasonCodes,
            pendingEndShowsWaitingAfterSeconds: 0
        )
    }

    private func makeSnowState(
        snapshot: RunBoundarySnapshot,
        classification: SnowSegmentClassification,
        currentSpeedKmh: Double,
        lastCompletedRun: SnowRun? = nil
    ) -> SnowLiveSessionState {
        SnowLiveSessionState(
            sessionID: sessionID,
            isActive: true,
            isPaused: false,
            latestSnapshot: snapshot,
            latestClassification: classification,
            currentSpeedKmh: currentSpeedKmh,
            maxSpeedThisRunKmh: max(currentSpeedKmh, snapshot.currentRunTopSpeedMetersPerSecond * 3.6),
            currentRunNumber: snapshot.currentRunNumber,
            currentRunVerticalDropMeters: snapshot.currentRunVerticalDropMeters,
            currentRunDistanceMeters: snapshot.currentRunDistanceMeters,
            currentRunTopSpeedKmh: snapshot.currentRunTopSpeedMetersPerSecond * 3.6,
            completedRuns: lastCompletedRun.map { [$0] } ?? [],
            inMemorySegments: [],
            distanceBreakdown: .zero,
            lastCompletedRun: lastCompletedRun,
            latestReasonCodes: classification.reasonCodes
        )
    }

    private func makeSnapshot(
        state: RunBoundaryState,
        type: SnowSegmentType,
        confidence: Double,
        lastCompletedRun: SnowRun? = nil
    ) -> RunBoundarySnapshot {
        RunBoundarySnapshot(
            sessionID: sessionID,
            state: state,
            currentRunNumber: 2,
            currentRunID: state == .active ? UUID() : nil,
            currentSegmentType: type,
            currentConfidence: confidence,
            currentRunStartedAt: state == .active ? baseDate : nil,
            currentRunDistanceMeters: 240,
            currentRunVerticalDropMeters: 68,
            currentRunTopSpeedMetersPerSecond: 11,
            pendingEndElapsedSeconds: state == .pendingEnd ? 5 : nil,
            lastCompletedRun: lastCompletedRun
        )
    }

    private func makeClassification(
        type: SnowSegmentType,
        confidence: Double,
        reasonCodes: [String]? = nil
    ) -> SnowSegmentClassification {
        SnowSegmentClassification(
            type: type,
            confidence: confidence,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(1),
            sampleCount: 10,
            averageSpeedKmh: 18,
            maxSpeedKmh: 26,
            altitudeDeltaMeters: type.defaultCountsTowardSkiDistance ? -2 : 1,
            verticalRateMetersPerSecond: type.defaultCountsTowardSkiDistance ? -0.4 : 0.2,
            motionEnergyG: type.defaultCountsTowardSkiDistance ? 0.12 : 0.02,
            headingStandardDeviationDegrees: type.defaultCountsTowardSkiDistance ? 18 : 3,
            routeDistanceMeters: 20,
            reasonCodes: reasonCodes ?? ["fixture"]
        )
    }

    private func makeRecordingState(elapsedTime: TimeInterval = 0) -> SessionRecordingState {
        var state = SessionRecordingState.initial
        state.elapsedTime = elapsedTime
        state.status = .recording
        state.selectedSportMode = .snow(.skiing)
        return state
    }
}
