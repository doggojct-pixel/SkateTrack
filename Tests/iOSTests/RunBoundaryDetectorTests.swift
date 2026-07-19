// [協作區] RunBoundaryDetectorTests.swift
import Foundation
import XCTest
@testable import SkateTrack_iOS

final class RunBoundaryDetectorTests: XCTestCase {
    func testDownhillStartsRunAfterConfirmation() {
        var detector = RunBoundaryDetector(sessionID: UUID())
        let result = feed(&detector, classifications: makeSequence(type: .downhillRun, start: 0, seconds: 3, confidence: 0.84, speedKmh: 24, altitudeDeltaPerSecond: -0.5))
        printFixtureResult(name: "downhillStartsRunAfterConfirmation", detector: detector, events: result)
        XCTAssertEqual(detector.state, .active)
        XCTAssertTrue(result.containsRunStarted)
        XCTAssertEqual(detector.snapshot.currentRunNumber, 1)
        XCTAssertGreaterThan(detector.snapshot.currentRunDistanceMeters, 0)
    }

    func testShortStopResumesWithoutEndingRun() {
        var detector = startedDetector()
        let stopEvents = feed(&detector, classifications: makeSequence(type: .stopped, start: 3, seconds: 4, confidence: 0.88, speedKmh: 0.4, altitudeDeltaPerSecond: 0))
        let resumeEvents = feed(&detector, classifications: makeSequence(type: .downhillRun, start: 7, seconds: 3, confidence: 0.82, speedKmh: 22, altitudeDeltaPerSecond: -0.45))
        let events = stopEvents + resumeEvents
        printFixtureResult(name: "shortStopResumesWithoutEndingRun", detector: detector, events: events)
        XCTAssertEqual(detector.state, .active)
        XCTAssertFalse(events.containsRunEnded)
        XCTAssertGreaterThan(detector.snapshot.currentRunDistanceMeters, 0)
    }

    func testLongStopEndsRunAfterPendingTimeout() {
        var detector = startedDetector()
        let events = feed(&detector, classifications: makeSequence(type: .stopped, start: 3, seconds: 39, confidence: 0.89, speedKmh: 0.3, altitudeDeltaPerSecond: 0))
        printFixtureResult(name: "longStopEndsRun", detector: detector, events: events)
        XCTAssertEqual(detector.state, .between)
        XCTAssertTrue(events.containsRunEnded(reason: .pendingEndTimeout))
        XCTAssertNotNil(detector.snapshot.lastCompletedRun)
    }

    func testHighConfidenceLiftTriggersFastPathRunEnd() {
        var detector = startedDetector()
        let events = feed(&detector, classifications: makeSequence(type: .liftAscent, start: 3, seconds: 5, confidence: 0.86, speedKmh: 7, altitudeDeltaPerSecond: 0.3))
        printFixtureResult(name: "highConfidenceLiftTriggersFastPathRunEnd", detector: detector, events: events)
        XCTAssertEqual(detector.state, .between)
        XCTAssertTrue(events.containsRunEnded(reason: .highConfidenceTransport))
        XCTAssertFalse(events.containsState(.pendingEnd), "high confidence lift fast-path should skip pendingEnd")
    }

    func testPendingEndCancelsWhenDownhillReturns() {
        var detector = startedDetector()
        let pendingEvents = feed(&detector, classifications: makeSequence(type: .stopped, start: 3, seconds: 9, confidence: 0.88, speedKmh: 0.4, altitudeDeltaPerSecond: 0))
        XCTAssertTrue(pendingEvents.containsState(.pendingEnd))
        let resumeEvents = feed(&detector, classifications: makeSequence(type: .downhillRun, start: 12, seconds: 2, confidence: 0.72, speedKmh: 21, altitudeDeltaPerSecond: -0.4))
        let events = pendingEvents + resumeEvents
        printFixtureResult(name: "pendingEndCancelsWhenDownhillReturns", detector: detector, events: events)
        XCTAssertEqual(detector.state, .active)
        XCTAssertTrue(resumeEvents.containsState(.active))
        XCTAssertFalse(events.containsRunEnded)
    }

    func testLowConfidenceUnknownDoesNotStartRun() {
        var detector = RunBoundaryDetector(sessionID: UUID())
        let events = feed(&detector, classifications: makeSequence(type: .unknown, start: 0, seconds: 8, confidence: 0.40, speedKmh: 18, altitudeDeltaPerSecond: -0.3))
        printFixtureResult(name: "lowConfidenceUnknownDoesNotStartRun", detector: detector, events: events)
        XCTAssertEqual(detector.state, .idle)
        XCTAssertFalse(events.containsRunStarted)
        XCTAssertFalse(events.containsRunEnded)
    }

    func testRunEndedSegmentsKeepAltitudeEndpointsNilAndDefaultDistanceCounting() {
        var detector = startedDetector()
        let events = feed(&detector, classifications: makeSequence(type: .liftAscent, start: 3, seconds: 5, confidence: 0.86, speedKmh: 7, altitudeDeltaPerSecond: 0.3))
        guard case let .runEnded(_, segments, _) = events.first(where: { $0.isRunEnded }) else {
            XCTFail("Expected runEnded event")
            return
        }
        printFixtureResult(name: "segmentsKeepAltitudeEndpointsNil", detector: detector, events: events)
        XCTAssertFalse(segments.isEmpty)
        XCTAssertTrue(segments.allSatisfy { $0.startAltitudeMeters == nil && $0.endAltitudeMeters == nil })
        XCTAssertTrue(segments.filter { $0.type == .downhillRun }.allSatisfy { $0.countsTowardSkiDistance })
        XCTAssertTrue(segments.allSatisfy { $0.manualOverride == nil })
    }

    private func startedDetector() -> RunBoundaryDetector {
        var detector = RunBoundaryDetector(sessionID: UUID())
        _ = feed(&detector, classifications: makeSequence(type: .downhillRun, start: 0, seconds: 3, confidence: 0.84, speedKmh: 24, altitudeDeltaPerSecond: -0.5))
        XCTAssertEqual(detector.state, .active)
        return detector
    }

    @discardableResult
    private func feed(_ detector: inout RunBoundaryDetector, classifications: [SnowSegmentClassification]) -> [RunBoundaryEvent] {
        classifications.flatMap { detector.ingest($0) }
    }

    private func printFixtureResult(name: String, detector: RunBoundaryDetector, events: [RunBoundaryEvent]) {
        let eventSummary = events.map(\.fixtureSummary).joined(separator: "|")
        print(
            "RunBoundaryFixtureResult name=\(name) state=\(detector.state.rawValue) currentRun=\(detector.snapshot.currentRunNumber) runStarted=\(events.containsRunStarted) runEnded=\(events.containsRunEnded) pendingElapsed=\(format(detector.snapshot.pendingEndElapsedSeconds)) events=\(eventSummary)"
        )
    }

    private func makeSequence(
        type: SnowSegmentType,
        start: TimeInterval,
        seconds: Int,
        confidence: Double,
        speedKmh: Double,
        altitudeDeltaPerSecond: Double
    ) -> [SnowSegmentClassification] {
        (0..<seconds).map { offset in
            let startDate = baseDate.addingTimeInterval(start + TimeInterval(offset))
            let endDate = startDate.addingTimeInterval(1)
            return SnowSegmentClassification(
                type: type,
                confidence: confidence,
                startDate: startDate,
                endDate: endDate,
                sampleCount: 10,
                averageSpeedKmh: speedKmh,
                maxSpeedKmh: speedKmh + 2,
                altitudeDeltaMeters: altitudeDeltaPerSecond,
                verticalRateMetersPerSecond: altitudeDeltaPerSecond,
                motionEnergyG: type.defaultCountsTowardSkiDistance ? 0.12 : 0.02,
                headingStandardDeviationDegrees: type.defaultCountsTowardSkiDistance ? 18 : 3,
                routeDistanceMeters: speedKmh / 3.6,
                reasonCodes: ["fixture", type.rawValue]
            )
        }
    }

    private var baseDate: Date {
        Date(timeIntervalSince1970: 1_800_000_000)
    }

    private func format(_ value: TimeInterval?) -> String {
        guard let value else { return "nil" }
        return String(format: "%.1f", value)
    }
}

private extension RunBoundaryEvent {
    var isRunStarted: Bool {
        if case .runStarted = self { return true }
        return false
    }

    var isRunEnded: Bool {
        if case .runEnded = self { return true }
        return false
    }

    var fixtureSummary: String {
        switch self {
        case let .stateChanged(from, to):
            return "stateChanged:\(from.rawValue)->\(to.rawValue)"
        case let .runStarted(run):
            return "runStarted:#\(run.runNumber)"
        case let .runEnded(run, segments, reason):
            return "runEnded:#\(run.runNumber):\(reason.rawValue):segments=\(segments.count)"
        }
    }
}

private extension Array where Element == RunBoundaryEvent {
    var containsRunStarted: Bool { contains { $0.isRunStarted } }
    var containsRunEnded: Bool { contains { $0.isRunEnded } }

    func containsRunEnded(reason: RunBoundaryEndReason) -> Bool {
        contains { event in
            if case let .runEnded(_, _, endedReason) = event {
                return endedReason == reason
            }
            return false
        }
    }

    func containsState(_ state: RunBoundaryState) -> Bool {
        contains { event in
            if case let .stateChanged(_, to) = event {
                return to == state
            }
            return false
        }
    }
}
