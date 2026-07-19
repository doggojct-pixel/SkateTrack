// [協作區] watchOS/Core/WatchBridge/WatchBridgeWatchRuntime.swift
// Purpose: Owns watch-side WatchBridge activation, ordered receive state, and command transport.
// Delegates to: WatchBridgeWCSessionBoundary as the sole WatchConnectivity session owner.

import Combine
import Foundation

@MainActor
final class WatchBridgeWatchRuntime: ObservableObject {
    @Published private(set) var bridgeState = WatchBridgeRuntimeState()

    private var boundary: WatchBridgeWCSessionBoundary?
    private var isActivated = false

    init(boundary: WatchBridgeWCSessionBoundary? = WatchBridgeWCSessionBoundary()) {
        self.boundary = boundary
        self.boundary?.inboundEnvelopeHandler = { [weak self] envelope in
            Task { @MainActor in
                self?.receive(envelope)
            }
        }
    }

    var activityViewModel: WatchActivityViewModel {
        WatchActivityViewModel(
            connectionStatus: bridgeState.connectionStatus,
            session: bridgeState.activitySession,
            metrics: bridgeState.activityMetrics,
            bridgeDisplay: bridgeState.activityDisplay
        )
    }

    var latestMetricPayload: WatchBridgeMetricUpdatePayload? {
        bridgeState.activityMetrics
    }

    var statePublisher: AnyPublisher<WatchBridgeRuntimeState, Never> {
        $bridgeState.eraseToAnyPublisher()
    }

    @discardableResult
    func activate(at date: Date = Date()) -> WatchBridgeConnectivityAvailability? {
        guard !isActivated else { return boundary?.availability }
        isActivated = true
        guard let availability = boundary?.activate(at: date) else { return nil }
        bridgeState.updateConnectionStatus(
            WatchBridgeConnectionStatusPayload(
                state: availability.state,
                reportedAt: availability.reportedAt,
                canSendCommands: availability.reachable,
                canReceiveSnapshots: availability.reachable
            )
        )
        return availability
    }

    @discardableResult
    func send(_ command: WatchBridgeCommandEnvelope) -> WatchBridgeConnectivitySendResult? {
        boundary?.send(
            WatchBridgeEnvelope(
                source: .appleWatch,
                destination: .iPhone,
                payload: .command(command)
            )
        )
    }

    private func receive(_ envelope: WatchBridgeEnvelope) {
        _ = bridgeState.apply(envelope)
    }
}
