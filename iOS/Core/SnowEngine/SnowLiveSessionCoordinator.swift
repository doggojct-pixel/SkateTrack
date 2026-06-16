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
    func reset()
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
}
