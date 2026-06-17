// [Collaboration Zone] WatchSnowSessionDataSource.swift
// Purpose: Watch Snow UI data-source boundary. Views must consume this boundary
//          instead of direct transport, sensors, recording lifecycle, or persistence.

import Combine
import Foundation

@MainActor
protocol WatchSnowSessionDataSource: AnyObject {
    var currentSnapshot: WatchSnowSessionSnapshot { get }
    var snapshotPublisher: AnyPublisher<WatchSnowSessionSnapshot, Never> { get }
    var lastHapticIntent: WatchSnowHapticIntent? { get }

    func markManeuver()
    func endRun()
    func startRun()
    func pauseSession()
    func resumeSession()
}

#if DEBUG
@MainActor
protocol WatchSnowMockScenarioControlling: AnyObject {
    var selectedScenario: WatchSnowMockScenario { get }

    func selectScenario(_ scenario: WatchSnowMockScenario)
    func toggleSubscriberGate()
}
#endif
