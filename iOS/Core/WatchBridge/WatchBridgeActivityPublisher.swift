// [協作區] iOS/Core/WatchBridge/WatchBridgeActivityPublisher.swift
// Purpose: Publishes authoritative iPhone recording snapshots through the existing WatchBridge boundary.
// Delegates to: SessionRecordingCoordinator for lifecycle and trusted live metrics.

import Combine
import Foundation

@MainActor
final class WatchBridgeActivityPublisher: ObservableObject {
    private let coordinator: SessionRecordingCoordinator
    private var boundary: any WatchBridgeConnectivityBoundary
    private var cancellables = Set<AnyCancellable>()
    private var latestStatus: SessionRecordingStatus
    private var latestMetrics: LiveSessionMetrics
    private var latestSnowState: SnowLiveSessionState
    private var isActivated = false

    init(
        coordinator: SessionRecordingCoordinator = .shared,
        boundary: (any WatchBridgeConnectivityBoundary)? = nil
    ) {
        self.coordinator = coordinator
        self.boundary = boundary ?? Self.makeDefaultBoundary()
        self.latestStatus = coordinator.status
        self.latestMetrics = .zero
        self.latestSnowState = coordinator.currentSnowLiveState
        installSubscriptions()
    }

    @discardableResult
    func activate(at date: Date = Date()) -> WatchBridgeConnectivityAvailability {
        guard !isActivated else {
            return boundary.availability
        }
        isActivated = true
        let availability = boundary.activate(at: date)
        publishSnapshot(at: date)
        return availability
    }

    private func installSubscriptions() {
        coordinator.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                latestStatus = status
                publishSnapshot(at: Date())
            }
            .store(in: &cancellables)

        coordinator.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                guard let self else { return }
                latestMetrics = metrics
                publishSnapshot(at: Date())
            }
            .store(in: &cancellables)

        coordinator.snowLiveStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snowState in
                guard let self else { return }
                latestSnowState = snowState
                publishSnapshot(at: Date())
            }
            .store(in: &cancellables)
    }

    private func publishSnapshot(at date: Date) {
        guard isActivated else { return }
        let availability = boundary.refreshAvailability(at: date)
        let snapshot = WatchBridgeActivitySnapshotPayload(
            session: makeSessionPayload(at: date),
            metrics: makeMetricPayload(at: date),
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: availability.state,
                reportedAt: date,
                canSendCommands: availability.reachable,
                canReceiveSnapshots: availability.reachable
            )
        )
        let envelope = WatchBridgeEnvelope(
            createdAt: date,
            source: .iPhone,
            destination: .appleWatch,
            payload: .activitySnapshot(snapshot)
        )
        _ = boundary.send(envelope)
    }

    private func makeSessionPayload(at date: Date) -> WatchBridgeActivitySessionPayload {
        WatchBridgeActivitySessionPayload(
            state: bridgeSessionState,
            mode: WatchBridgeActivityModeDescriptor(
                sportModeKey: sportModeKey,
                modeLocalizationKey: coordinator.selectedSportMode?.modeLocalizationKey
            ),
            updatedAt: date,
            elapsedSeconds: latestMetrics.elapsedTime,
            isRecordingAllowed: latestStatus == .recording || latestStatus == .paused
        )
    }

    private func makeMetricPayload(at date: Date) -> WatchBridgeMetricUpdatePayload {
        let snowState = activeSnowState
        let lastRun = snowState?.lastCompletedRun
        return WatchBridgeMetricUpdatePayload(
            sessionId: snowState?.sessionID,
            updatedAt: date,
            elapsedSeconds: latestMetrics.elapsedTime,
            distanceMeters: latestMetrics.distanceKilometers * 1_000,
            currentSpeedMetersPerSecond: latestMetrics.currentSpeedKilometersPerHour / 3.6,
            averageSpeedMetersPerSecond: latestMetrics.averageSpeedKilometersPerHour / 3.6,
            trustLevel: .trustedSource,
            snowSchemaVersion: snowState == nil ? nil : "1.1",
            snowMaxSpeedThisRunKmh: snowState?.maxSpeedThisRunKmh,
            snowRunNumber: snowState.flatMap { $0.currentRunNumber > 0 ? $0.currentRunNumber : nil },
            snowVerticalDropMeters: snowState?.currentRunVerticalDropMeters,
            snowTotalVerticalMeters: nil,
            snowSlopeAngleDegrees: nil,
            snowSegmentType: snowState?.latestClassification?.type.rawValue,
            snowRunCount: snowState?.completedRuns.count,
            snowTotalSkiDistanceMeters: snowState?.distanceBreakdown.skiDistanceMeters,
            snowTotalLiftDistanceMeters: snowState?.distanceBreakdown.liftDistanceMeters,
            snowAverageRunDurationSeconds: nil,
            snowLastRunVerticalDropMeters: lastRun?.verticalDropMeters,
            snowLastRunTopSpeedKmh: lastRun.map { $0.topSpeedMetersPerSecond * 3.6 },
            snowLastRunDurationSeconds: lastRun?.durationSeconds
        )
    }

    private var activeSnowState: SnowLiveSessionState? {
        guard latestStatus == .recording || latestStatus == .paused,
              case .snow = coordinator.selectedSportMode,
              latestSnowState.isActive else {
            return nil
        }
        return latestSnowState
    }

    private var bridgeSessionState: WatchBridgeSessionState {
        switch latestStatus {
        case .idle:
            return .idle
        case .preparing:
            return .preparing
        case .recording:
            return .recording
        case .paused:
            return .paused
        case .ending, .saving:
            return .ending
        case .failed:
            return .failed
        }
    }

    private var sportModeKey: String? {
        guard let mode = coordinator.selectedSportMode else { return nil }
        switch mode {
        case .skateboard:
            return "skateboard"
        case .inline:
            return "inline"
        case .snow:
            return "snow"
        }
    }

    private static func makeDefaultBoundary() -> any WatchBridgeConnectivityBoundary {
        WatchBridgeWCSessionBoundary() ?? WatchBridgeSimulatorFallbackBoundary()
    }
}
