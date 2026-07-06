// [協作區] Shared/WatchBridge/WatchBridgePayloads.swift

import Foundation

public enum WatchBridgePayload: Codable, Equatable, Sendable {
    case command(WatchBridgeCommandEnvelope)
    case sessionSnapshot(WatchBridgeSessionSnapshot)
    case compactActivity(WatchBridgeCompactActivitySnapshot)
    case activitySession(WatchBridgeActivitySessionPayload)
    case activityMetrics(WatchBridgeMetricUpdatePayload)
    case activityDisplay(WatchBridgeCompactActivityDisplayPayload)
    case activitySnapshot(WatchBridgeActivitySnapshotPayload)
    case commandResult(WatchBridgeCommandAcknowledgementPayload)
    case connectionStatus(WatchBridgeConnectionStatusPayload)
    case acknowledgement(WatchBridgeAcknowledgement)
    case connectionState(WatchBridgeConnectionState)
    case error(WatchBridgeErrorPayload)
}

public struct WatchBridgeSessionSnapshot: Codable, Equatable, Sendable {
    public let sessionId: UUID?
    public let state: WatchBridgeSessionState
    public let sportModeKey: String?
    public let startedAt: Date?
    public let updatedAt: Date
    public let elapsedSeconds: TimeInterval
    public let distanceMeters: Double?
    public let speedMetersPerSecond: Double?

    public init(
        sessionId: UUID? = nil,
        state: WatchBridgeSessionState,
        sportModeKey: String? = nil,
        startedAt: Date? = nil,
        updatedAt: Date = Date(),
        elapsedSeconds: TimeInterval = 0,
        distanceMeters: Double? = nil,
        speedMetersPerSecond: Double? = nil
    ) {
        self.sessionId = sessionId
        self.state = state
        self.sportModeKey = sportModeKey
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.elapsedSeconds = elapsedSeconds
        self.distanceMeters = distanceMeters
        self.speedMetersPerSecond = speedMetersPerSecond
    }
}

public struct WatchBridgeCompactActivitySnapshot: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let routePointCount: Int
    public let speedSampleCount: Int
    public let elevationSampleCount: Int
    public let qualityLabel: String?

    public init(
        generatedAt: Date = Date(),
        routePointCount: Int = 0,
        speedSampleCount: Int = 0,
        elevationSampleCount: Int = 0,
        qualityLabel: String? = nil
    ) {
        self.generatedAt = generatedAt
        self.routePointCount = routePointCount
        self.speedSampleCount = speedSampleCount
        self.elevationSampleCount = elevationSampleCount
        self.qualityLabel = qualityLabel
    }
}

public struct WatchBridgeAcknowledgement: Codable, Equatable, Sendable {
    public let acknowledgedMessageId: UUID
    public let accepted: Bool
    public let reason: String?

    public init(acknowledgedMessageId: UUID, accepted: Bool, reason: String? = nil) {
        self.acknowledgedMessageId = acknowledgedMessageId
        self.accepted = accepted
        self.reason = reason
    }
}

public struct WatchBridgeErrorPayload: Codable, Equatable, Sendable {
    public let code: String
    public let message: String
    public let recoverable: Bool

    public init(code: String, message: String, recoverable: Bool = true) {
        self.code = code
        self.message = message
        self.recoverable = recoverable
    }
}
