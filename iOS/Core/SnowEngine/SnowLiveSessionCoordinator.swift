// [協作區] iOS/Core/SnowEngine/SnowLiveSessionCoordinator.swift
// 用途：Snow-Task-005 production live driver，連接 MotionSample window、classifier 與 RunBoundaryDetector。
// 委派至：SessionRecordingCoordinator snow mode forwarding、useSnowLiveSession、Snow HUD。

import Combine
import Foundation

protocol SnowLiveSessionCoordinating: AnyObject {
    var statePublisher: AnyPublisher<SnowLiveSessionState, Never> { get }
    var currentState: SnowLiveSessionState { get }

    func start(sessionID: UUID)
    func ingest(_ sample: MotionSample)
    func pause()
    func resume()
    func manuallyEndCurrentRun() async
    func finishSession() async
    func finishSession(
        trustedRouteDistanceMeters: Double,
        sessionStartDate: Date,
        sessionEndDate: Date
    ) async
    func reset()
}

extension SnowLiveSessionCoordinating {
    func finishSession(
        trustedRouteDistanceMeters: Double,
        sessionStartDate: Date,
        sessionEndDate: Date
    ) async {
        await finishSession()
    }
}

final class SnowLiveSessionCoordinator: SnowLiveSessionCoordinating {
    private let classifier: SnowSegmentClassifier
    private let config: SnowLiveSessionConfig
    private let repository: SnowSessionRepositoryProtocol

    private var buffer = SnowClassificationWindowBuffer()
    private var detector: RunBoundaryDetector?
    private var previousClassificationType: SnowSegmentType?
    private var stateSubject = CurrentValueSubject<SnowLiveSessionState, Never>(.empty)

    init(
        classifier: SnowSegmentClassifier = SnowSegmentClassifier(),
        config: SnowLiveSessionConfig = .productionV0,
        repository: SnowSessionRepositoryProtocol = SnowSessionRepository.shared
    ) {
        self.classifier = classifier
        self.config = config
        self.repository = repository
    }

    var statePublisher: AnyPublisher<SnowLiveSessionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: SnowLiveSessionState {
        stateSubject.value
    }

    func start(sessionID: UUID) {
        buffer.reset()
        previousClassificationType = nil
        detector = RunBoundaryDetector(sessionID: sessionID)
        stateSubject.send(
            SnowLiveSessionState(
                sessionID: sessionID,
                isActive: true,
                isPaused: false,
                latestSnapshot: detector?.snapshot,
                latestClassification: nil,
                currentSpeedKmh: 0,
                maxSpeedThisRunKmh: 0,
                currentRunNumber: 0,
                currentRunVerticalDropMeters: 0,
                currentRunDistanceMeters: 0,
                currentRunTopSpeedKmh: 0,
                completedRuns: [],
                inMemorySegments: [],
                distanceBreakdown: .zero,
                lastCompletedRun: nil,
                latestReasonCodes: []
            )
        )
    }

    func ingest(_ sample: MotionSample) {
        guard var detector else { return }

        buffer.append(sample)
        buffer.trim(keepingLast: config.classificationWindowSeconds)

        let classification = classifier.classify(
            samples: buffer.samples,
            previousType: previousClassificationType
        )
        previousClassificationType = classification.type

        let events = detector.ingest(classification)
        self.detector = detector
        publishState(sample: sample, classification: classification, detector: detector, events: events)
        persistEndedRuns(from: events)
    }

    func pause() {
        var state = stateSubject.value
        state.isPaused = true
        stateSubject.send(state)
    }

    func resume() {
        var state = stateSubject.value
        state.isPaused = false
        stateSubject.send(state)
    }

    func manuallyEndCurrentRun() async {
        guard var detector else { return }
        let events = detector.manuallyEndRun()
        self.detector = detector
        publishState(sample: nil, classification: stateSubject.value.latestClassification, detector: detector, events: events)
        await persistEndedRunsAsync(from: events)
    }

    func finishSession() async {
        publishFinishedState()
    }

    func finishSession(
        trustedRouteDistanceMeters: Double,
        sessionStartDate: Date,
        sessionEndDate: Date
    ) async {
        await persistResidualUnknownDistanceIfNeeded(
            trustedRouteDistanceMeters: trustedRouteDistanceMeters,
            sessionStartDate: sessionStartDate,
            sessionEndDate: sessionEndDate
        )
        publishFinishedState()
    }

    private func publishFinishedState() {
        var state = stateSubject.value
        state.isActive = false
        state.isPaused = false
        stateSubject.send(state)
    }

    func reset() {
        buffer.reset()
        detector = nil
        previousClassificationType = nil
        stateSubject.send(.empty)
    }

    private func publishState(
        sample: MotionSample?,
        classification: SnowSegmentClassification?,
        detector: RunBoundaryDetector,
        events: [RunBoundaryEvent]
    ) {
        var state = stateSubject.value
        state.latestSnapshot = detector.snapshot
        state.latestClassification = classification
        state.latestReasonCodes = classification?.reasonCodes ?? state.latestReasonCodes

        if let sample {
            state.currentSpeedKmh = max(0, sample.speedKmh)
            state.maxSpeedThisRunKmh = max(state.maxSpeedThisRunKmh, sample.speedKmh)
        }

        state.currentRunNumber = detector.snapshot.currentRunNumber
        state.currentRunVerticalDropMeters = detector.snapshot.currentRunVerticalDropMeters
        state.currentRunDistanceMeters = detector.snapshot.currentRunDistanceMeters
        state.currentRunTopSpeedKmh = detector.snapshot.currentRunTopSpeedMetersPerSecond * 3.6
        state.lastCompletedRun = detector.snapshot.lastCompletedRun

        for event in events {
            if case let .runEnded(run, segments, _) = event {
                state.completedRuns.append(run)
                state.inMemorySegments.append(contentsOf: segments)
                state.distanceBreakdown = SnowDistanceBreakdown.make(from: state.inMemorySegments)
                state.lastCompletedRun = run
                state.maxSpeedThisRunKmh = 0
            }
        }

        stateSubject.send(state)
    }

    private func persistEndedRuns(from events: [RunBoundaryEvent]) {
        let endedEvents = events.compactMap { event -> (SnowRun, [SnowSegment])? in
            if case let .runEnded(run, segments, _) = event {
                return (run, segments)
            }
            return nil
        }
        guard !endedEvents.isEmpty else { return }

        Task { [repository] in
            for (run, segments) in endedEvents {
                for segment in segments {
                    _ = try? await repository.saveSegment(segment)
                }
                _ = try? await repository.saveRun(run)
            }
        }
    }

    private func persistEndedRunsAsync(from events: [RunBoundaryEvent]) async {
        for event in events {
            guard case let .runEnded(run, segments, _) = event else { continue }
            for segment in segments {
                _ = try? await repository.saveSegment(segment)
            }
            _ = try? await repository.saveRun(run)
        }
    }

    private func persistResidualUnknownDistanceIfNeeded(
        trustedRouteDistanceMeters: Double,
        sessionStartDate: Date,
        sessionEndDate: Date
    ) async {
        guard trustedRouteDistanceMeters.isFinite,
              trustedRouteDistanceMeters > 0,
              let sessionID = stateSubject.value.sessionID,
              let persistedSegments = try? await repository.fetchSegments(sessionID: sessionID) else { return }

        var segmentsByID = Dictionary(uniqueKeysWithValues: persistedSegments.map { ($0.id, $0) })
        for segment in stateSubject.value.inMemorySegments where segment.sessionID == sessionID {
            segmentsByID[segment.id] = segment
        }
        var existingSegments = Array(segmentsByID.values)
        let existingRouteDistanceMeters = existingSegments.reduce(0) { distance, segment in
            segment.distanceMeters.isFinite ? distance + segment.distanceMeters : distance
        }
        let residualDistanceMeters = trustedRouteDistanceMeters - existingRouteDistanceMeters

        guard residualDistanceMeters.isFinite, residualDistanceMeters > 0.001 else {
            publishFinalSegments(existingSegments, sessionID: sessionID)
            return
        }

        let normalizedEndDate = max(sessionStartDate, sessionEndDate)
        let lastSegmentEndDate = existingSegments.compactMap(\.endDate).max() ?? sessionStartDate
        let fallbackStartDate = min(max(lastSegmentEndDate, sessionStartDate), normalizedEndDate)
        let fallback = SnowSegment(
            sessionID: sessionID,
            runID: nil,
            type: .unknown,
            startDate: fallbackStartDate,
            endDate: normalizedEndDate,
            distanceMeters: residualDistanceMeters,
            confidence: 0,
            countsTowardSkiDistance: false,
            manualOverride: false,
            sourceSampleIDs: []
        )

        guard let savedFallback = try? await repository.saveSegment(fallback) else { return }
        existingSegments.append(savedFallback)
        publishFinalSegments(existingSegments, sessionID: sessionID)
    }

    private func publishFinalSegments(_ segments: [SnowSegment], sessionID: UUID) {
        var state = stateSubject.value
        guard state.sessionID == sessionID else { return }
        let orderedSegments = segments.sorted { lhs, rhs in
            lhs.startDate == rhs.startDate
                ? lhs.id.uuidString < rhs.id.uuidString
                : lhs.startDate < rhs.startDate
        }
        state.inMemorySegments = orderedSegments
        state.distanceBreakdown = SnowDistanceBreakdown.make(from: orderedSegments)
        stateSubject.send(state)
    }
}
