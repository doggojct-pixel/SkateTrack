// [Collaboration Zone] WatchSnowMockSessionProvider.swift
// Purpose: DEBUG-only mock data source for Snow-Task-006a Watch Snow UI.
//          It exercises production-safe Watch Snow UI without real sensors,
//          external transport, recording lifecycle, or persistence.

#if DEBUG
import Combine
import Foundation

@MainActor
final class WatchSnowMockSessionProvider: ObservableObject, WatchSnowSessionDataSource, WatchSnowMockScenarioControlling {
    @Published private(set) var currentSnapshot: WatchSnowSessionSnapshot
    @Published private(set) var selectedScenario: WatchSnowMockScenario
    @Published private(set) var lastHapticIntent: WatchSnowHapticIntent?

    private let hapticObserver: WatchSnowHapticIntentObserver
    private let hapticPlayer: WatchSnowHapticPlaying?

    var snapshotPublisher: AnyPublisher<WatchSnowSessionSnapshot, Never> {
        $currentSnapshot.eraseToAnyPublisher()
    }

    init(
        initialScenario: WatchSnowMockScenario = .downhill,
        hapticObserver: WatchSnowHapticIntentObserver = WatchSnowHapticIntentObserver(),
        hapticPlayer: WatchSnowHapticPlaying? = nil
    ) {
        self.selectedScenario = initialScenario
        self.currentSnapshot = WatchSnowMockSnapshotFactory.snapshot(for: initialScenario, isSubscriber: true)
        self.hapticObserver = hapticObserver
        self.hapticPlayer = hapticPlayer
    }

    func selectScenario(_ scenario: WatchSnowMockScenario) {
        selectedScenario = scenario
        publish(WatchSnowMockSnapshotFactory.snapshot(for: scenario, isSubscriber: currentSnapshot.isSubscriber))
    }

    func toggleSubscriberGate() {
        var snapshot = currentSnapshot
        snapshot.isSubscriber.toggle()
        publish(snapshot)
    }

    func markManeuver() {
        lastHapticIntent = .maneuverMarked
        hapticPlayer?.play(.maneuverMarked)
    }

    func endRun() {
        lastHapticIntent = .sessionEnded
        hapticPlayer?.play(.sessionEnded)
        selectScenario(.summary)
    }

    func startRun() {
        selectScenario(.downhill)
    }

    func pauseSession() {
        lastHapticIntent = .paused
        hapticPlayer?.play(.paused)
    }

    func resumeSession() {
        lastHapticIntent = .resumed
        hapticPlayer?.play(.resumed)
    }

    private func publish(_ newSnapshot: WatchSnowSessionSnapshot) {
        let oldSnapshot = currentSnapshot
        currentSnapshot = newSnapshot

        if let intent = hapticObserver.intent(from: oldSnapshot, to: newSnapshot) {
            lastHapticIntent = intent
            hapticPlayer?.play(intent)
        }
    }
}

private enum WatchSnowMockSnapshotFactory {
    static func snapshot(for scenario: WatchSnowMockScenario, isSubscriber: Bool) -> WatchSnowSessionSnapshot {
        switch scenario {
        case .downhill:
            return WatchSnowSessionSnapshot(
                currentSpeedKmh: 42.8,
                maxSpeedThisRunKmh: 62.4,
                snowRunNumber: 4,
                snowVerticalDropMeters: 186,
                snowTotalVerticalMeters: 1240,
                snowSlopeAngleDegrees: nil,
                snowSegmentType: "downhillRun",
                snowSchemaVersion: "1.1",
                totalRunsToday: 8,
                totalSkiDistanceMeters: 9350,
                totalLiftDistanceMeters: 4120,
                averageRunDurationSeconds: 214,
                lastRunVerticalDropMeters: 164,
                lastRunTopSpeedKmh: 58.7,
                lastRunDurationSeconds: 201,
                heartRateBpm: 142,
                fallAlertActive: false,
                fallAlertPeakGForce: nil,
                isSubscriber: isSubscriber
            )
        case .liftOrGondola:
            return WatchSnowSessionSnapshot(
                currentSpeedKmh: 7.2,
                maxSpeedThisRunKmh: 62.4,
                snowRunNumber: 4,
                snowVerticalDropMeters: 186,
                snowTotalVerticalMeters: 1240,
                snowSlopeAngleDegrees: nil,
                snowSegmentType: "gondolaAscent",
                snowSchemaVersion: "1.1",
                totalRunsToday: 8,
                totalSkiDistanceMeters: 9350,
                totalLiftDistanceMeters: 4710,
                averageRunDurationSeconds: 214,
                lastRunVerticalDropMeters: 186,
                lastRunTopSpeedKmh: 62.4,
                lastRunDurationSeconds: 228,
                heartRateBpm: 104,
                fallAlertActive: false,
                fallAlertPeakGForce: nil,
                isSubscriber: isSubscriber
            )
        case .waiting:
            return WatchSnowSessionSnapshot(
                currentSpeedKmh: 0.8,
                maxSpeedThisRunKmh: 62.4,
                snowRunNumber: 5,
                snowVerticalDropMeters: nil,
                snowTotalVerticalMeters: 1240,
                snowSlopeAngleDegrees: nil,
                snowSegmentType: "stopped",
                snowSchemaVersion: "1.1",
                totalRunsToday: 8,
                totalSkiDistanceMeters: 9350,
                totalLiftDistanceMeters: 4710,
                averageRunDurationSeconds: 214,
                lastRunVerticalDropMeters: 186,
                lastRunTopSpeedKmh: 62.4,
                lastRunDurationSeconds: 228,
                heartRateBpm: 98,
                fallAlertActive: false,
                fallAlertPeakGForce: nil,
                isSubscriber: isSubscriber
            )
        case .lowConfidence:
            return WatchSnowSessionSnapshot(
                currentSpeedKmh: 14.5,
                maxSpeedThisRunKmh: 62.4,
                snowRunNumber: 5,
                snowVerticalDropMeters: nil,
                snowTotalVerticalMeters: 1240,
                snowSlopeAngleDegrees: nil,
                snowSegmentType: "unknown",
                snowSchemaVersion: "1.1",
                totalRunsToday: 8,
                totalSkiDistanceMeters: 9350,
                totalLiftDistanceMeters: 4710,
                averageRunDurationSeconds: 214,
                lastRunVerticalDropMeters: 186,
                lastRunTopSpeedKmh: 62.4,
                lastRunDurationSeconds: 228,
                heartRateBpm: 118,
                fallAlertActive: false,
                fallAlertPeakGForce: nil,
                isSubscriber: isSubscriber
            )
        case .fallAlert:
            return WatchSnowSessionSnapshot(
                currentSpeedKmh: 0,
                maxSpeedThisRunKmh: 62.4,
                snowRunNumber: 5,
                snowVerticalDropMeters: nil,
                snowTotalVerticalMeters: 1240,
                snowSlopeAngleDegrees: nil,
                snowSegmentType: "stopped",
                snowSchemaVersion: "1.1",
                totalRunsToday: 8,
                totalSkiDistanceMeters: 9350,
                totalLiftDistanceMeters: 4710,
                averageRunDurationSeconds: 214,
                lastRunVerticalDropMeters: 186,
                lastRunTopSpeedKmh: 62.4,
                lastRunDurationSeconds: 228,
                heartRateBpm: 132,
                fallAlertActive: true,
                fallAlertPeakGForce: 4.2,
                isSubscriber: isSubscriber
            )
        case .summary:
            return WatchSnowSessionSnapshot(
                currentSpeedKmh: 0,
                maxSpeedThisRunKmh: 62.4,
                snowRunNumber: nil,
                snowVerticalDropMeters: nil,
                snowTotalVerticalMeters: 1426,
                snowSlopeAngleDegrees: nil,
                snowSegmentType: "stopped",
                snowSchemaVersion: "1.1",
                totalRunsToday: 9,
                totalSkiDistanceMeters: 10480,
                totalLiftDistanceMeters: 5200,
                averageRunDurationSeconds: 218,
                lastRunVerticalDropMeters: 186,
                lastRunTopSpeedKmh: 62.4,
                lastRunDurationSeconds: 228,
                heartRateBpm: 96,
                fallAlertActive: false,
                fallAlertPeakGForce: nil,
                isSubscriber: isSubscriber
            )
        }
    }
}
#endif
