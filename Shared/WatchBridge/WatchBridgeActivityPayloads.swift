// [協作區] Shared/WatchBridge/WatchBridgeActivityPayloads.swift

import Foundation

public struct WatchBridgeActivityModeDescriptor: Codable, Equatable, Sendable {
    public let sportModeKey: String?
    public let modeLocalizationKey: String?
    public let powerTypeKey: String?
    public let fidelityProfileKey: String?
    public let equipmentKindKey: String?

    public init(
        sportModeKey: String? = nil,
        modeLocalizationKey: String? = nil,
        powerTypeKey: String? = nil,
        fidelityProfileKey: String? = nil,
        equipmentKindKey: String? = nil
    ) {
        self.sportModeKey = sportModeKey
        self.modeLocalizationKey = modeLocalizationKey
        self.powerTypeKey = powerTypeKey
        self.fidelityProfileKey = fidelityProfileKey
        self.equipmentKindKey = equipmentKindKey
    }
}

public struct WatchBridgeActivitySessionPayload: Codable, Equatable, Sendable {
    public let sessionId: UUID?
    public let state: WatchBridgeSessionState
    public let mode: WatchBridgeActivityModeDescriptor
    public let startedAt: Date?
    public let updatedAt: Date
    public let elapsedSeconds: TimeInterval
    public let isRecordingAllowed: Bool
    public let statusLabel: String?

    public init(
        sessionId: UUID? = nil,
        state: WatchBridgeSessionState,
        mode: WatchBridgeActivityModeDescriptor = WatchBridgeActivityModeDescriptor(),
        startedAt: Date? = nil,
        updatedAt: Date = Date(),
        elapsedSeconds: TimeInterval = 0,
        isRecordingAllowed: Bool = false,
        statusLabel: String? = nil
    ) {
        self.sessionId = sessionId
        self.state = state
        self.mode = mode
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.elapsedSeconds = elapsedSeconds
        self.isRecordingAllowed = isRecordingAllowed
        self.statusLabel = statusLabel
    }
}

public struct WatchBridgeCompactActivityDisplayPayload: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let routePointCount: Int
    public let speedSampleCount: Int
    public let elevationSampleCount: Int
    public let hasCompactRoute: Bool
    public let hasSpeedSparkline: Bool
    public let hasElevationProfile: Bool
    public let qualityLabel: String?
    public let displayOnly: Bool

    public init(
        generatedAt: Date = Date(),
        routePointCount: Int = 0,
        speedSampleCount: Int = 0,
        elevationSampleCount: Int = 0,
        hasCompactRoute: Bool = false,
        hasSpeedSparkline: Bool = false,
        hasElevationProfile: Bool = false,
        qualityLabel: String? = nil,
        displayOnly: Bool = true
    ) {
        self.generatedAt = generatedAt
        self.routePointCount = routePointCount
        self.speedSampleCount = speedSampleCount
        self.elevationSampleCount = elevationSampleCount
        self.hasCompactRoute = hasCompactRoute
        self.hasSpeedSparkline = hasSpeedSparkline
        self.hasElevationProfile = hasElevationProfile
        self.qualityLabel = qualityLabel
        self.displayOnly = displayOnly
    }
}

public struct WatchBridgeActivitySnapshotPayload: Codable, Equatable, Sendable {
    public let session: WatchBridgeActivitySessionPayload
    public let metrics: WatchBridgeMetricUpdatePayload
    public let display: WatchBridgeCompactActivityDisplayPayload?
    public let connectionStatus: WatchBridgeConnectionStatusPayload?

    public init(
        session: WatchBridgeActivitySessionPayload,
        metrics: WatchBridgeMetricUpdatePayload,
        display: WatchBridgeCompactActivityDisplayPayload? = nil,
        connectionStatus: WatchBridgeConnectionStatusPayload? = nil
    ) {
        self.session = session
        self.metrics = metrics
        self.display = display
        self.connectionStatus = connectionStatus
    }
}
