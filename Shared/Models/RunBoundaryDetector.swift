// [協作區] Shared/Models/RunBoundaryDetector.swift
// 用途：Snow-Task-004 v0 streaming run boundary state machine，將 classifier 輸出聚合成 run boundary events。
// 委派至：future useSnowSession live boundary、persistence caller 與 Snow UI。

import Foundation

struct RunBoundaryDetector: Sendable {
    let sessionID: UUID
    let config: RunBoundaryConfig

    private(set) var state: RunBoundaryState = .idle
    private(set) var snapshot: RunBoundarySnapshot

    private var nextRunNumber: Int = 1
    private var currentRunID: UUID?
    private var currentRunStartedAt: Date?
    private var activeSegments: [SnowSegment] = []
    private var pendingClassifications: [SnowSegmentClassification] = []
    private var startCandidateClassifications: [SnowSegmentClassification] = []
    private var resumeCandidateClassifications: [SnowSegmentClassification] = []
    private var startCandidateStartedAt: Date?
    private var pendingEndStartedAt: Date?
    private var resumeCandidateStartedAt: Date?
    private var hardTransportStartedAt: Date?
    private var lastReliableSkiingEndDate: Date?
    private var lastCompletedRun: SnowRun?
    private var latestSegmentType: SnowSegmentType = .unknown
    private var latestConfidence: Double = 0

    init(sessionID: UUID, config: RunBoundaryConfig = .productionV0) {
        self.sessionID = sessionID
        self.config = config
        self.snapshot = .empty(sessionID: sessionID)
    }

    @discardableResult
    mutating func ingest(_ classification: SnowSegmentClassification) -> [RunBoundaryEvent] {
        latestSegmentType = classification.type
        latestConfidence = classification.confidence

        guard classification.startDate != nil, classification.endDate != nil else {
            refreshSnapshot()
            return []
        }

        let events: [RunBoundaryEvent]
        switch state {
        case .idle, .between:
            events = handleIdleOrBetween(classification)
        case .active:
            events = handleActive(classification)
        case .pendingEnd:
            events = handlePendingEnd(classification)
        }
        refreshSnapshot()
        return events
    }

    mutating func manuallyEndRun(at date: Date = Date()) -> [RunBoundaryEvent] {
        guard state == .active || state == .pendingEnd else { return [] }
        let previous = state
        let event = finishCurrentRun(reason: .manualEnd, endDateOverride: date)
        transition(to: .between)
        clearPendingState()
        refreshSnapshot()
        return event.map { [RunBoundaryEvent.stateChanged(from: previous, to: .between), $0] } ?? [.stateChanged(from: previous, to: .between)]
    }

    private mutating func handleIdleOrBetween(_ classification: SnowSegmentClassification) -> [RunBoundaryEvent] {
        guard isSkiingClassification(classification, minimumConfidence: config.startConfidenceThreshold) else {
            resetStartCandidate()
            return []
        }

        if startCandidateStartedAt == nil {
            startCandidateStartedAt = classification.startDate
        }
        startCandidateClassifications.append(classification)

        guard candidateDuration(from: startCandidateStartedAt, through: classification) >= config.startConfirmationSeconds else {
            return []
        }

        return startRun(from: startCandidateClassifications)
    }

    private mutating func handleActive(_ classification: SnowSegmentClassification) -> [RunBoundaryEvent] {
        if isSkiingClassification(classification, minimumConfidence: config.pendingEndCancelConfidenceThreshold) {
            hardTransportStartedAt = nil
            appendPendingToActiveIfNeeded()
            appendSegment(from: classification)
            lastReliableSkiingEndDate = classification.endDate
            clearPendingState(keepingActive: true)
            return []
        }

        if classification.type.isLiftTransport,
           classification.confidence >= config.hardTransportEndConfidenceThreshold {
            if hardTransportStartedAt == nil {
                hardTransportStartedAt = classification.startDate
            }
            pendingClassifications.append(classification)
            if candidateDuration(from: hardTransportStartedAt, through: classification) >= config.hardTransportConfirmationSeconds {
                return finishAndTransitionToBetween(reason: .highConfidenceTransport, from: .active)
            }
            return []
        }

        hardTransportStartedAt = nil
        if pendingEndStartedAt == nil {
            pendingEndStartedAt = classification.startDate
        }
        pendingClassifications.append(classification)

        guard candidateDuration(from: pendingEndStartedAt, through: classification) >= config.pendingEndConfirmationSeconds else {
            return []
        }

        let previous = state
        transition(to: .pendingEnd)
        return [.stateChanged(from: previous, to: .pendingEnd)]
    }

    private mutating func handlePendingEnd(_ classification: SnowSegmentClassification) -> [RunBoundaryEvent] {
        if isSkiingClassification(classification, minimumConfidence: config.pendingEndCancelConfidenceThreshold) {
            if resumeCandidateStartedAt == nil {
                resumeCandidateStartedAt = classification.startDate
            }
            resumeCandidateClassifications.append(classification)

            if candidateDuration(from: resumeCandidateStartedAt, through: classification) >= config.pendingEndCancelSeconds {
                appendPendingToActiveIfNeeded()
                for resumeClassification in resumeCandidateClassifications {
                    appendSegment(from: resumeClassification)
                    lastReliableSkiingEndDate = resumeClassification.endDate
                }
                let previous = state
                transition(to: .active)
                clearPendingState(keepingActive: true)
                return [.stateChanged(from: previous, to: .active)]
            }
            return []
        }

        resumeCandidateStartedAt = nil
        resumeCandidateClassifications.removeAll()

        if classification.type.isLiftTransport,
           classification.confidence >= config.hardTransportEndConfidenceThreshold {
            if hardTransportStartedAt == nil {
                hardTransportStartedAt = classification.startDate
            }
            pendingClassifications.append(classification)
            if candidateDuration(from: hardTransportStartedAt, through: classification) >= config.hardTransportConfirmationSeconds {
                return finishAndTransitionToBetween(reason: .highConfidenceTransport, from: .pendingEnd)
            }
        } else {
            hardTransportStartedAt = nil
            pendingClassifications.append(classification)
        }

        guard candidateDuration(from: pendingEndStartedAt, through: classification) >= config.pendingEndTimeoutSeconds else {
            return []
        }
        return finishAndTransitionToBetween(reason: .pendingEndTimeout, from: .pendingEnd)
    }

    private mutating func startRun(from classifications: [SnowSegmentClassification]) -> [RunBoundaryEvent] {
        let runID = UUID()
        currentRunID = runID
        currentRunStartedAt = classifications.first?.startDate
        activeSegments.removeAll()
        pendingClassifications.removeAll()
        lastReliableSkiingEndDate = classifications.last?.endDate

        for classification in classifications {
            appendSegment(from: classification)
        }

        let previous = state
        transition(to: .active)
        resetStartCandidate()

        let run = makeRun(endDate: nil)
        return [
            .stateChanged(from: previous, to: .active),
            .runStarted(run),
        ]
    }

    private mutating func finishAndTransitionToBetween(reason: RunBoundaryEndReason, from previous: RunBoundaryState) -> [RunBoundaryEvent] {
        guard let ended = finishCurrentRun(reason: reason, endDateOverride: nil) else {
            transition(to: .between)
            clearPendingState()
            return [.stateChanged(from: previous, to: .between)]
        }
        transition(to: .between)
        clearPendingState()
        return [
            .stateChanged(from: previous, to: .between),
            ended,
        ]
    }

    private mutating func finishCurrentRun(reason: RunBoundaryEndReason, endDateOverride: Date?) -> RunBoundaryEvent? {
        guard currentRunID != nil, !activeSegments.isEmpty else { return nil }
        let run = makeRun(endDate: endDateOverride ?? lastReliableSkiingEndDate ?? activeSegments.last?.endDate)
        let segments = activeSegments.map { segment in
            SnowSegment(
                id: segment.id,
                sessionID: segment.sessionID,
                runID: run.id,
                type: segment.type,
                startDate: segment.startDate,
                endDate: segment.endDate,
                distanceMeters: segment.distanceMeters,
                verticalDeltaMeters: segment.verticalDeltaMeters,
                startAltitudeMeters: nil,
                endAltitudeMeters: nil,
                averageSpeedMetersPerSecond: segment.averageSpeedMetersPerSecond,
                maxSpeedMetersPerSecond: segment.maxSpeedMetersPerSecond,
                confidence: segment.confidence,
                countsTowardSkiDistance: segment.countsTowardSkiDistance,
                manualOverride: nil,
                sourceSampleIDs: segment.sourceSampleIDs
            )
        }
        lastCompletedRun = run
        nextRunNumber += 1
        currentRunID = nil
        currentRunStartedAt = nil
        activeSegments.removeAll()
        return .runEnded(run: run, segments: segments, reason: reason)
    }

    private func makeRun(endDate: Date?) -> SnowRun {
        let runID = currentRunID ?? UUID()
        let startDate = currentRunStartedAt ?? activeSegments.first?.startDate ?? Date()
        let durationSeconds = max(0, (endDate ?? activeSegments.last?.endDate ?? startDate).timeIntervalSince(startDate))
        let skiDistanceMeters = activeSegments.reduce(0) { $0 + $1.skiDistanceMeters }
        let topSpeed = activeSegments.compactMap(\.maxSpeedMetersPerSecond).max() ?? 0
        let averageSpeed = durationSeconds > 0 ? skiDistanceMeters / durationSeconds : nil
        let verticalDrop = activeSegments.reduce(0) { total, segment in
            guard segment.countsTowardSkiDistance, let delta = segment.verticalDeltaMeters, delta < 0 else { return total }
            return total + abs(delta)
        }
        return SnowRun(
            id: runID,
            sessionID: sessionID,
            runNumber: nextRunNumber,
            startDate: startDate,
            endDate: endDate,
            skiDistanceMeters: skiDistanceMeters,
            verticalDropMeters: verticalDrop,
            topSpeedMetersPerSecond: topSpeed,
            averageSpeedMetersPerSecond: averageSpeed,
            segmentIDs: activeSegments.map(\.id),
            isManualEnd: false
        )
    }

    private mutating func appendPendingToActiveIfNeeded() {
        for classification in pendingClassifications {
            appendSegment(from: classification)
        }
        pendingClassifications.removeAll()
    }

    private mutating func appendSegment(from classification: SnowSegmentClassification) {
        guard let segment = makeSegment(from: classification) else { return }
        if let last = activeSegments.last,
           last.type == segment.type,
           let lastEnd = last.endDate,
           segment.startDate.timeIntervalSince(lastEnd) <= config.maximumMergeGapSeconds {
            activeSegments[activeSegments.count - 1] = merge(last, with: segment)
        } else {
            activeSegments.append(segment)
        }
    }

    private func makeSegment(from classification: SnowSegmentClassification) -> SnowSegment? {
        guard let startDate = classification.startDate else { return nil }
        return SnowSegment(
            sessionID: sessionID,
            runID: currentRunID,
            type: classification.type,
            startDate: startDate,
            endDate: classification.endDate,
            distanceMeters: classification.routeDistanceMeters,
            verticalDeltaMeters: classification.altitudeDeltaMeters,
            startAltitudeMeters: nil,
            endAltitudeMeters: nil,
            averageSpeedMetersPerSecond: classification.averageSpeedKmh / 3.6,
            maxSpeedMetersPerSecond: classification.maxSpeedKmh / 3.6,
            confidence: classification.confidence,
            countsTowardSkiDistance: classification.type.defaultCountsTowardSkiDistance,
            manualOverride: nil
        )
    }

    private func merge(_ lhs: SnowSegment, with rhs: SnowSegment) -> SnowSegment {
        let startDate = lhs.startDate
        let endDate = rhs.endDate ?? lhs.endDate
        let duration = endDate.map { max(0, $0.timeIntervalSince(startDate)) } ?? 0
        let distance = lhs.distanceMeters + rhs.distanceMeters
        let verticalDelta = optionalSum(lhs.verticalDeltaMeters, rhs.verticalDeltaMeters)
        let averageSpeed = duration > 0 ? distance / duration : lhs.averageSpeedMetersPerSecond
        return SnowSegment(
            id: lhs.id,
            sessionID: lhs.sessionID,
            runID: lhs.runID ?? rhs.runID,
            type: lhs.type,
            startDate: lhs.startDate,
            endDate: endDate,
            distanceMeters: distance,
            verticalDeltaMeters: verticalDelta,
            startAltitudeMeters: nil,
            endAltitudeMeters: nil,
            averageSpeedMetersPerSecond: averageSpeed,
            maxSpeedMetersPerSecond: max(lhs.maxSpeedMetersPerSecond ?? 0, rhs.maxSpeedMetersPerSecond ?? 0),
            confidence: min(lhs.confidence, rhs.confidence),
            countsTowardSkiDistance: lhs.countsTowardSkiDistance,
            manualOverride: nil,
            sourceSampleIDs: lhs.sourceSampleIDs + rhs.sourceSampleIDs
        )
    }

    private func isSkiingClassification(_ classification: SnowSegmentClassification, minimumConfidence: Double) -> Bool {
        classification.confidence >= minimumConfidence && classification.type.defaultCountsTowardSkiDistance
    }

    private func candidateDuration(from startDate: Date?, through classification: SnowSegmentClassification) -> TimeInterval {
        guard let startDate, let endDate = classification.endDate else { return 0 }
        return max(0, endDate.timeIntervalSince(startDate))
    }

    private mutating func transition(to newState: RunBoundaryState) {
        state = newState
    }

    private mutating func resetStartCandidate() {
        startCandidateStartedAt = nil
        startCandidateClassifications.removeAll()
    }

    private mutating func clearPendingState(keepingActive: Bool = false) {
        pendingClassifications.removeAll()
        pendingEndStartedAt = nil
        resumeCandidateStartedAt = nil
        resumeCandidateClassifications.removeAll()
        hardTransportStartedAt = nil
        if !keepingActive {
            resetStartCandidate()
        }
    }

    private mutating func refreshSnapshot() {
        let pendingElapsed = pendingEndStartedAt.flatMap { start -> TimeInterval? in
            guard let end = pendingClassifications.last?.endDate ?? resumeCandidateClassifications.last?.endDate else { return nil }
            return max(0, end.timeIntervalSince(start))
        }
        let run = makeSnapshotRun()
        snapshot = RunBoundarySnapshot(
            sessionID: sessionID,
            state: state,
            currentRunNumber: nextRunNumber,
            currentRunID: currentRunID,
            currentSegmentType: latestSegmentType,
            currentConfidence: latestConfidence,
            currentRunStartedAt: currentRunStartedAt,
            currentRunDistanceMeters: run?.skiDistanceMeters ?? 0,
            currentRunVerticalDropMeters: run?.verticalDropMeters ?? 0,
            currentRunTopSpeedMetersPerSecond: run?.topSpeedMetersPerSecond ?? 0,
            pendingEndElapsedSeconds: pendingElapsed,
            lastCompletedRun: lastCompletedRun
        )
    }

    private func makeSnapshotRun() -> SnowRun? {
        guard currentRunID != nil, !activeSegments.isEmpty else { return nil }
        return makeRun(endDate: activeSegments.last?.endDate)
    }

    private func optionalSum(_ lhs: Double?, _ rhs: Double?) -> Double? {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            return lhs + rhs
        case let (.some(lhs), .none):
            return lhs
        case let (.none, .some(rhs)):
            return rhs
        case (.none, .none):
            return nil
        }
    }
}
