// [協作區] Shared/WatchBridge/WatchBridgeMetricPayloads.swift

import Foundation

public enum WatchBridgeMetricTrustLevel: String, Codable, Equatable, Sendable {
    case trustedSource
    case displayOnlyProjection
    case unavailable
    case unknown
}

public struct WatchBridgeMetricUpdatePayload: Codable, Equatable, Sendable {
    public let sessionId: UUID?
    public let updatedAt: Date
    public let elapsedSeconds: TimeInterval
    public let distanceMeters: Double?
    public let currentSpeedMetersPerSecond: Double?
    public let averageSpeedMetersPerSecond: Double?
    public let elevationGainMeters: Double?
    public let elevationLossMeters: Double?
    public let trustLevel: WatchBridgeMetricTrustLevel
    public let sourceLabel: String?
    public let snowSchemaVersion: String?
    public let snowMaxSpeedThisRunKmh: Double?
    public let snowRunNumber: Int?
    public let snowVerticalDropMeters: Double?
    public let snowTotalVerticalMeters: Double?
    public let snowSlopeAngleDegrees: Double?
    public let snowSegmentType: String?
    public let snowRunCount: Int?
    public let snowTotalSkiDistanceMeters: Double?
    public let snowTotalLiftDistanceMeters: Double?
    public let snowAverageRunDurationSeconds: Double?
    public let snowLastRunVerticalDropMeters: Double?
    public let snowLastRunTopSpeedKmh: Double?
    public let snowLastRunDurationSeconds: Double?

    public init(
        sessionId: UUID? = nil,
        updatedAt: Date = Date(),
        elapsedSeconds: TimeInterval = 0,
        distanceMeters: Double? = nil,
        currentSpeedMetersPerSecond: Double? = nil,
        averageSpeedMetersPerSecond: Double? = nil,
        elevationGainMeters: Double? = nil,
        elevationLossMeters: Double? = nil,
        trustLevel: WatchBridgeMetricTrustLevel = .unknown,
        sourceLabel: String? = nil,
        snowSchemaVersion: String? = nil,
        snowMaxSpeedThisRunKmh: Double? = nil,
        snowRunNumber: Int? = nil,
        snowVerticalDropMeters: Double? = nil,
        snowTotalVerticalMeters: Double? = nil,
        snowSlopeAngleDegrees: Double? = nil,
        snowSegmentType: String? = nil,
        snowRunCount: Int? = nil,
        snowTotalSkiDistanceMeters: Double? = nil,
        snowTotalLiftDistanceMeters: Double? = nil,
        snowAverageRunDurationSeconds: Double? = nil,
        snowLastRunVerticalDropMeters: Double? = nil,
        snowLastRunTopSpeedKmh: Double? = nil,
        snowLastRunDurationSeconds: Double? = nil
    ) {
        self.sessionId = sessionId
        self.updatedAt = updatedAt
        self.elapsedSeconds = elapsedSeconds
        self.distanceMeters = distanceMeters
        self.currentSpeedMetersPerSecond = currentSpeedMetersPerSecond
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
        self.elevationGainMeters = elevationGainMeters
        self.elevationLossMeters = elevationLossMeters
        self.trustLevel = trustLevel
        self.sourceLabel = sourceLabel
        self.snowSchemaVersion = snowSchemaVersion
        self.snowMaxSpeedThisRunKmh = snowMaxSpeedThisRunKmh
        self.snowRunNumber = snowRunNumber
        self.snowVerticalDropMeters = snowVerticalDropMeters
        self.snowTotalVerticalMeters = snowTotalVerticalMeters
        self.snowSlopeAngleDegrees = snowSlopeAngleDegrees
        self.snowSegmentType = snowSegmentType
        self.snowRunCount = snowRunCount
        self.snowTotalSkiDistanceMeters = snowTotalSkiDistanceMeters
        self.snowTotalLiftDistanceMeters = snowTotalLiftDistanceMeters
        self.snowAverageRunDurationSeconds = snowAverageRunDurationSeconds
        self.snowLastRunVerticalDropMeters = snowLastRunVerticalDropMeters
        self.snowLastRunTopSpeedKmh = snowLastRunTopSpeedKmh
        self.snowLastRunDurationSeconds = snowLastRunDurationSeconds
    }
}

public enum WatchBridgeCommandResult: String, Codable, Equatable, Sendable {
    case accepted
    case rejected
    case ignored
    case failed
}

public struct WatchBridgeCommandAcknowledgementPayload: Codable, Equatable, Sendable {
    public let commandId: UUID
    public let result: WatchBridgeCommandResult
    public let acknowledgedAt: Date
    public let sessionId: UUID?
    public let reason: String?

    public init(
        commandId: UUID,
        result: WatchBridgeCommandResult,
        acknowledgedAt: Date = Date(),
        sessionId: UUID? = nil,
        reason: String? = nil
    ) {
        self.commandId = commandId
        self.result = result
        self.acknowledgedAt = acknowledgedAt
        self.sessionId = sessionId
        self.reason = reason
    }
}

public struct WatchBridgeConnectionStatusPayload: Codable, Equatable, Sendable {
    public let state: WatchBridgeConnectionState
    public let reportedAt: Date
    public let canSendCommands: Bool
    public let canReceiveSnapshots: Bool

    public init(
        state: WatchBridgeConnectionState,
        reportedAt: Date = Date(),
        canSendCommands: Bool = false,
        canReceiveSnapshots: Bool = false
    ) {
        self.state = state
        self.reportedAt = reportedAt
        self.canSendCommands = canSendCommands
        self.canReceiveSnapshots = canReceiveSnapshots
    }
}
