// [協作區] watchOS/Core/Snow/WatchBridgeSnowSessionProvider.swift
// Purpose: Adapts real WatchBridge metric state to the stable Watch Snow data-source contract.
// Delegates to: WatchBridgeWatchRuntime for transport and WatchBridgeSnowSnapshotMapper for mapping.

import Combine
import Foundation

@MainActor
final class WatchBridgeSnowSessionProvider: ObservableObject, WatchSnowSessionDataSource {
    @Published private(set) var currentSnapshot: WatchSnowSessionSnapshot

    private let mapper: WatchBridgeSnowSnapshotMapper
    private var cancellables = Set<AnyCancellable>()

    init(
        runtime: WatchBridgeWatchRuntime,
        mapper: WatchBridgeSnowSnapshotMapper = WatchBridgeSnowSnapshotMapper()
    ) {
        self.mapper = mapper
        self.currentSnapshot = mapper.makeSnapshot(from: runtime.latestMetricPayload)
        runtime.statePublisher
            .map(\.activityMetrics)
            .removeDuplicates()
            .sink { [weak self] payload in
                guard let self else { return }
                currentSnapshot = mapper.makeSnapshot(from: payload)
            }
            .store(in: &cancellables)
    }

    var snapshotPublisher: AnyPublisher<WatchSnowSessionSnapshot, Never> {
        $currentSnapshot.eraseToAnyPublisher()
    }

    var lastHapticIntent: WatchSnowHapticIntent? {
        nil
    }

    // A006R1 does not grant the provider recording or run-lifecycle authority.
    func markManeuver() {}
    func endRun() {}
    func startRun() {}
    func pauseSession() {}
    func resumeSession() {}
}
