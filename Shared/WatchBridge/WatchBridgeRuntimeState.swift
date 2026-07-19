// [協作區] Shared/WatchBridge/WatchBridgeRuntimeState.swift
// Purpose: Decodes inbound envelopes and applies ordered, duplicate-safe Watch runtime state.
// Delegates to: WatchBridge payload contracts and platform-specific runtime owners.

import Foundation

public struct WatchBridgeInboundEnvelopeDecoder {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func decode(_ data: Data) throws -> WatchBridgeEnvelope {
        try decoder.decode(WatchBridgeEnvelope.self, from: data)
    }
}

public enum WatchBridgeRuntimeApplyResult: Equatable, Sendable {
    case accepted
    case duplicate
    case stale
    case ignoredDestination
    case unsupportedPayload
}

public struct WatchBridgeRuntimeState: Equatable, Sendable {
    public private(set) var activitySession: WatchBridgeActivitySessionPayload?
    public private(set) var activityMetrics: WatchBridgeMetricUpdatePayload?
    public private(set) var activityDisplay: WatchBridgeCompactActivityDisplayPayload?
    public private(set) var connectionStatus: WatchBridgeConnectionStatusPayload?

    private var activitySessionUpdatedAt: Date?
    private var activityMetricsUpdatedAt: Date?
    private var activityDisplayUpdatedAt: Date?
    private var connectionStatusUpdatedAt: Date?
    private var seenMessageIds: Set<UUID>
    private var seenMessageOrder: [UUID]
    private let duplicateHistoryLimit: Int

    public init(duplicateHistoryLimit: Int = 64) {
        self.activitySession = nil
        self.activityMetrics = nil
        self.activityDisplay = nil
        self.connectionStatus = nil
        self.activitySessionUpdatedAt = nil
        self.activityMetricsUpdatedAt = nil
        self.activityDisplayUpdatedAt = nil
        self.connectionStatusUpdatedAt = nil
        self.seenMessageIds = []
        self.seenMessageOrder = []
        self.duplicateHistoryLimit = max(1, duplicateHistoryLimit)
    }

    @discardableResult
    public mutating func apply(_ envelope: WatchBridgeEnvelope) -> WatchBridgeRuntimeApplyResult {
        guard envelope.destination == .appleWatch || envelope.destination == .simulator else {
            return .ignoredDestination
        }
        guard !seenMessageIds.contains(envelope.messageId) else {
            return .duplicate
        }
        remember(envelope.messageId)

        switch envelope.payload {
        case .activitySession(let payload):
            return applySession(payload) ? .accepted : .stale
        case .activityMetrics(let payload):
            return applyMetrics(payload) ? .accepted : .stale
        case .activityDisplay(let payload):
            return applyDisplay(payload) ? .accepted : .stale
        case .connectionStatus(let payload):
            return applyConnectionStatus(payload) ? .accepted : .stale
        case .activitySnapshot(let payload):
            var accepted = applySession(payload.session)
            accepted = applyMetrics(payload.metrics) || accepted
            if let display = payload.display {
                accepted = applyDisplay(display) || accepted
            }
            if let connectionStatus = payload.connectionStatus {
                accepted = applyConnectionStatus(connectionStatus) || accepted
            }
            return accepted ? .accepted : .stale
        case .connectionState(let state):
            let payload = WatchBridgeConnectionStatusPayload(
                state: state,
                reportedAt: state.lastUpdatedAt,
                canSendCommands: state.status == .reachable,
                canReceiveSnapshots: state.status == .reachable
            )
            return applyConnectionStatus(payload) ? .accepted : .stale
        default:
            return .unsupportedPayload
        }
    }

    public mutating func updateConnectionStatus(_ payload: WatchBridgeConnectionStatusPayload) {
        _ = applyConnectionStatus(payload)
    }

    private mutating func applySession(_ payload: WatchBridgeActivitySessionPayload) -> Bool {
        guard isFresh(payload.updatedAt, comparedWith: activitySessionUpdatedAt) else {
            return false
        }
        activitySession = payload
        activitySessionUpdatedAt = payload.updatedAt
        return true
    }

    private mutating func applyMetrics(_ payload: WatchBridgeMetricUpdatePayload) -> Bool {
        guard isFresh(payload.updatedAt, comparedWith: activityMetricsUpdatedAt) else {
            return false
        }
        activityMetrics = payload
        activityMetricsUpdatedAt = payload.updatedAt
        return true
    }

    private mutating func applyDisplay(_ payload: WatchBridgeCompactActivityDisplayPayload) -> Bool {
        guard isFresh(payload.generatedAt, comparedWith: activityDisplayUpdatedAt) else {
            return false
        }
        activityDisplay = payload
        activityDisplayUpdatedAt = payload.generatedAt
        return true
    }

    private mutating func applyConnectionStatus(_ payload: WatchBridgeConnectionStatusPayload) -> Bool {
        guard isFresh(payload.reportedAt, comparedWith: connectionStatusUpdatedAt) else {
            return false
        }
        connectionStatus = payload
        connectionStatusUpdatedAt = payload.reportedAt
        return true
    }

    private func isFresh(_ incoming: Date, comparedWith current: Date?) -> Bool {
        guard let current else { return true }
        return incoming >= current
    }

    private mutating func remember(_ messageId: UUID) {
        seenMessageIds.insert(messageId)
        seenMessageOrder.append(messageId)
        if seenMessageOrder.count > duplicateHistoryLimit {
            seenMessageIds.remove(seenMessageOrder.removeFirst())
        }
    }
}
