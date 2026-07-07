// [Collaboration] Shared/WatchUI/WatchActivityViewModel.swift
// Purpose: Defines display-only Watch UI state from WatchBridge, WatchSensors, and compact ActivityVisualization outputs.
// Delegates to: Shared WatchBridge contracts, Watch sample provider/ingestion/fusion outputs, and ActivityVisualization compact summaries.

import Foundation

struct WatchActivityViewModel: Equatable, Sendable {
    let generatedAt: Date
    let connection: WatchActivityConnectionViewState
    let session: WatchActivitySessionViewState
    let metrics: WatchActivityMetricViewState
    let samples: WatchActivitySampleViewState
    let compactSummary: WatchActivityCompactSummaryViewState

    init(
        connectionStatus: WatchBridgeConnectionStatusPayload? = nil,
        session: WatchBridgeActivitySessionPayload? = nil,
        metrics: WatchBridgeMetricUpdatePayload? = nil,
        sensorSnapshot: WatchSensorProviderSnapshot? = nil,
        ingestion: WatchSampleIngestionResult? = nil,
        fusion: WatchSampleFusionResult? = nil,
        compactSummary: ActivityVisualizationCompactSummary? = nil,
        bridgeDisplay: WatchBridgeCompactActivityDisplayPayload? = nil,
        generatedAt: Date = Date()
    ) {
        self.generatedAt = generatedAt
        self.connection = WatchActivityConnectionViewState(payload: connectionStatus)
        self.session = WatchActivitySessionViewState(payload: session)
        self.metrics = WatchActivityMetricViewState(payload: metrics)
        self.samples = WatchActivitySampleViewState(
            sensorSnapshot: sensorSnapshot,
            ingestion: ingestion,
            fusion: fusion
        )
        self.compactSummary = WatchActivityCompactSummaryViewState(
            compactSummary: compactSummary,
            bridgeDisplay: bridgeDisplay
        )
    }

    init(
        snapshot: WatchBridgeActivitySnapshotPayload,
        sensorSnapshot: WatchSensorProviderSnapshot? = nil,
        ingestion: WatchSampleIngestionResult? = nil,
        fusion: WatchSampleFusionResult? = nil,
        compactSummary: ActivityVisualizationCompactSummary? = nil,
        generatedAt: Date = Date()
    ) {
        self.init(
            connectionStatus: snapshot.connectionStatus,
            session: snapshot.session,
            metrics: snapshot.metrics,
            sensorSnapshot: sensorSnapshot,
            ingestion: ingestion,
            fusion: fusion,
            compactSummary: compactSummary,
            bridgeDisplay: snapshot.display,
            generatedAt: generatedAt
        )
    }
}

struct WatchActivityConnectionViewState: Equatable, Sendable {
    let status: WatchBridgeConnectionStatus
    let quality: WatchBridgeTransportQuality
    let lastUpdatedAt: Date?
    let lastReceivedMessageAt: Date?
    let canSendCommands: Bool
    let canReceiveSnapshots: Bool
    let explanation: String?

    init(payload: WatchBridgeConnectionStatusPayload?) {
        self.status = payload?.state.status ?? .unknown
        self.quality = payload?.state.quality ?? .unknown
        self.lastUpdatedAt = payload?.state.lastUpdatedAt
        self.lastReceivedMessageAt = payload?.state.lastReceivedMessageAt
        self.canSendCommands = payload?.canSendCommands ?? false
        self.canReceiveSnapshots = payload?.canReceiveSnapshots ?? false
        self.explanation = payload?.state.explanation
    }

    var isReachable: Bool {
        status == .reachable
    }

    var isStale: Bool {
        quality == .stale
    }
}

struct WatchActivitySessionViewState: Equatable, Sendable {
    let sessionId: UUID?
    let state: WatchBridgeSessionState
    let mode: WatchBridgeActivityModeDescriptor
    let startedAt: Date?
    let updatedAt: Date?
    let elapsedSeconds: TimeInterval
    let isRecordingAllowed: Bool
    let statusLabel: String?

    init(payload: WatchBridgeActivitySessionPayload?) {
        self.sessionId = payload?.sessionId
        self.state = payload?.state ?? .idle
        self.mode = payload?.mode ?? WatchBridgeActivityModeDescriptor()
        self.startedAt = payload?.startedAt
        self.updatedAt = payload?.updatedAt
        self.elapsedSeconds = payload?.elapsedSeconds ?? 0
        self.isRecordingAllowed = payload?.isRecordingAllowed ?? false
        self.statusLabel = payload?.statusLabel
    }

    var isActive: Bool {
        switch state {
        case .preparing, .ready, .recording, .paused, .ending:
            return true
        case .idle, .ended, .failed:
            return false
        }
    }
}

struct WatchActivityMetricViewState: Equatable, Sendable {
    let sessionId: UUID?
    let updatedAt: Date?
    let elapsedSeconds: TimeInterval
    let distanceMeters: Double?
    let currentSpeedMetersPerSecond: Double?
    let averageSpeedMetersPerSecond: Double?
    let elevationGainMeters: Double?
    let elevationLossMeters: Double?
    let trustLevel: WatchBridgeMetricTrustLevel
    let sourceLabel: String?

    init(payload: WatchBridgeMetricUpdatePayload?) {
        self.sessionId = payload?.sessionId
        self.updatedAt = payload?.updatedAt
        self.elapsedSeconds = payload?.elapsedSeconds ?? 0
        self.distanceMeters = payload?.distanceMeters
        self.currentSpeedMetersPerSecond = payload?.currentSpeedMetersPerSecond
        self.averageSpeedMetersPerSecond = payload?.averageSpeedMetersPerSecond
        self.elevationGainMeters = payload?.elevationGainMeters
        self.elevationLossMeters = payload?.elevationLossMeters
        self.trustLevel = payload?.trustLevel ?? .unknown
        self.sourceLabel = payload?.sourceLabel
    }

    var isTrustedSource: Bool {
        trustLevel == .trustedSource
    }
}

struct WatchActivitySampleViewState: Equatable, Sendable {
    let providerKind: WatchSensorProviderKind
    let availabilityStatus: WatchSensorProviderAvailabilityStatus
    let unavailableReason: WatchSensorProviderUnavailableReason?
    let capturedAt: Date?
    let rawSampleCount: Int
    let ingestedSampleCount: Int
    let ingestionIssueCount: Int
    let fusionDisplayPointCount: Int
    let displayDerivedPointCount: Int
    let conflictCount: Int
    let gapCount: Int

    init(
        sensorSnapshot: WatchSensorProviderSnapshot?,
        ingestion: WatchSampleIngestionResult?,
        fusion: WatchSampleFusionResult?
    ) {
        let attribution = ingestion?.sourceAttribution
        self.providerKind = sensorSnapshot?.providerKind ?? attribution?.providerKind ?? .disabled
        self.availabilityStatus = sensorSnapshot?.availability.status ?? attribution?.availabilityStatus ?? .unavailable
        self.unavailableReason = sensorSnapshot?.availability.reason ?? attribution?.unavailableReason
        self.capturedAt = sensorSnapshot?.capturedAt ?? attribution?.capturedAt
        self.rawSampleCount = sensorSnapshot?.sampleCount ?? 0
        self.ingestedSampleCount = ingestion?.sampleCount ?? 0
        self.ingestionIssueCount = ingestion?.issues.count ?? 0
        self.fusionDisplayPointCount = fusion?.displayPoints.count ?? 0
        self.displayDerivedPointCount = fusion?.displayDerivedPoints.count ?? 0
        self.conflictCount = fusion?.diagnostics.conflictCount ?? 0
        self.gapCount = fusion?.diagnostics.gapCount ?? 0
    }

    var canShowWatchOriginatedData: Bool {
        availabilityStatus == .available
    }
}

struct WatchActivityCompactSummaryViewState: Equatable, Sendable {
    let hasAnyDisplayData: Bool
    let hasCompactRoute: Bool
    let hasSpeedSparkline: Bool
    let hasElevationProfile: Bool
    let routeCard: WatchActivityRouteCompactCardViewState
    let speedCard: WatchActivitySpeedCompactCardViewState
    let elevationCard: WatchActivityElevationCompactCardViewState
    let routePointCount: Int
    let speedPointCount: Int
    let elevationPointCount: Int
    let routeQuality: ActivityVisualizationQuality?
    let speedQuality: ActivityVisualizationQuality?
    let elevationQuality: ActivityVisualizationQuality?
    let routeSegmentCount: Int
    let speedSegmentCount: Int
    let elevationSegmentCount: Int
    let displayDerivedTotalAscentMeters: Double?
    let displayOnly: Bool

    init(
        compactSummary: ActivityVisualizationCompactSummary?,
        bridgeDisplay: WatchBridgeCompactActivityDisplayPayload?
    ) {
        let routeData = compactSummary?.compactRoute.hasDisplayData ?? bridgeDisplay?.hasCompactRoute ?? false
        let speedData = compactSummary?.speedSparkline.hasDisplayData ?? bridgeDisplay?.hasSpeedSparkline ?? false
        let elevationData = compactSummary?.elevationProfile.hasDisplayData ?? bridgeDisplay?.hasElevationProfile ?? false

        self.hasCompactRoute = routeData
        self.hasSpeedSparkline = speedData
        self.hasElevationProfile = elevationData
        self.routePointCount = compactSummary?.routeDisplayPointCount ?? bridgeDisplay?.routePointCount ?? 0
        self.speedPointCount = compactSummary?.speedDisplayPointCount ?? bridgeDisplay?.speedSampleCount ?? 0
        self.elevationPointCount = compactSummary?.elevationDisplayPointCount ?? bridgeDisplay?.elevationSampleCount ?? 0
        self.routeQuality = compactSummary?.routeQuality
        self.speedQuality = compactSummary?.speedQuality
        self.elevationQuality = compactSummary?.elevationQuality
        self.routeSegmentCount = compactSummary?.routeSegmentCount ?? 0
        self.speedSegmentCount = compactSummary?.speedSegmentCount ?? 0
        self.elevationSegmentCount = compactSummary?.elevationSegmentCount ?? 0
        self.displayDerivedTotalAscentMeters = compactSummary?.elevationProfile.displayDerivedTotalAscentMeters
        self.displayOnly = bridgeDisplay?.displayOnly ?? true
        self.hasAnyDisplayData = compactSummary?.hasAnyDisplayData ?? (routeData || speedData || elevationData)
        self.routeCard = WatchActivityRouteCompactCardViewState(
            compactRoute: compactSummary?.compactRoute,
            bridgeDisplay: bridgeDisplay
        )
        self.speedCard = WatchActivitySpeedCompactCardViewState(
            speedSparkline: compactSummary?.speedSparkline,
            bridgeDisplay: bridgeDisplay
        )
        self.elevationCard = WatchActivityElevationCompactCardViewState(
            elevationProfile: compactSummary?.elevationProfile,
            bridgeDisplay: bridgeDisplay
        )
    }
}

enum WatchActivityRouteMiniCardScope: String, Equatable, Sendable {
    case textOnly = "TEXT_ONLY"
}

enum WatchActivityRouteCompactStatus: Equatable, Sendable {
    case recorded
    case qualityInsufficient
    case unavailable
}

struct WatchActivityRouteCompactCardViewState: Equatable, Sendable {
    let scope: WatchActivityRouteMiniCardScope
    let compactRoute: CompactRouteDisplay?
    let hasData: Bool
    let pointCount: Int
    let segmentCount: Int
    let quality: ActivityVisualizationQuality?
    let hasLowConfidenceSegments: Bool
    let hasStartupWarmup: Bool
    let status: WatchActivityRouteCompactStatus

    init(
        compactRoute: CompactRouteDisplay?,
        bridgeDisplay: WatchBridgeCompactActivityDisplayPayload?
    ) {
        let hasCompactRoute = compactRoute?.hasDisplayData ?? bridgeDisplay?.hasCompactRoute ?? false
        let pointCount = compactRoute?.points.count ?? bridgeDisplay?.routePointCount ?? 0
        let quality = compactRoute?.quality

        self.scope = .textOnly
        self.compactRoute = compactRoute
        self.hasData = hasCompactRoute
        self.pointCount = pointCount
        self.segmentCount = compactRoute?.segmentCount ?? 0
        self.quality = quality
        self.hasLowConfidenceSegments = compactRoute?.hasLowConfidenceSegments ?? false
        self.hasStartupWarmup = compactRoute?.hasStartupWarmup ?? false

        if hasCompactRoute || pointCount > 0 {
            self.status = quality == .limited ? .qualityInsufficient : .recorded
        } else {
            self.status = .unavailable
        }
    }
}

struct WatchActivitySpeedCompactCardViewState: Equatable, Sendable {
    let points: [CompactSparklinePoint]
    let hasData: Bool
    let pointCount: Int
    let segmentCount: Int
    let quality: ActivityVisualizationQuality?
    let minimumSpeedKilometersPerHour: Double?
    let maximumSpeedKilometersPerHour: Double?
    let averageDisplaySpeedKilometersPerHour: Double?
    let hasSparseData: Bool

    init(
        speedSparkline: CompactSpeedSparkline?,
        bridgeDisplay: WatchBridgeCompactActivityDisplayPayload?
    ) {
        self.points = speedSparkline?.points ?? []
        self.hasData = speedSparkline?.hasDisplayData ?? bridgeDisplay?.hasSpeedSparkline ?? false
        self.pointCount = speedSparkline?.points.count ?? bridgeDisplay?.speedSampleCount ?? 0
        self.segmentCount = speedSparkline?.segmentCount ?? 0
        self.quality = speedSparkline?.quality
        self.minimumSpeedKilometersPerHour = speedSparkline?.minimumSpeedKilometersPerHour
        self.maximumSpeedKilometersPerHour = speedSparkline?.maximumSpeedKilometersPerHour
        self.averageDisplaySpeedKilometersPerHour = speedSparkline?.averageDisplaySpeedKilometersPerHour
        self.hasSparseData = speedSparkline?.hasSparseData ?? false
    }
}

struct WatchActivityElevationCompactCardViewState: Equatable, Sendable {
    let points: [CompactSparklinePoint]
    let hasData: Bool
    let pointCount: Int
    let segmentCount: Int
    let quality: ActivityVisualizationQuality?
    let ascentMeters: Double?
    let selectedSource: ElevationDisplaySource?
    let hasAbsoluteAnchor: Bool
    let hasSparseData: Bool

    init(
        elevationProfile: CompactElevationProfile?,
        bridgeDisplay: WatchBridgeCompactActivityDisplayPayload?
    ) {
        self.points = elevationProfile?.points ?? []
        self.hasData = elevationProfile?.hasDisplayData ?? bridgeDisplay?.hasElevationProfile ?? false
        self.pointCount = elevationProfile?.points.count ?? bridgeDisplay?.elevationSampleCount ?? 0
        self.segmentCount = elevationProfile?.segmentCount ?? 0
        self.quality = elevationProfile?.quality
        self.ascentMeters = elevationProfile?.displayDerivedTotalAscentMeters
        self.selectedSource = elevationProfile?.selectedSource
        self.hasAbsoluteAnchor = elevationProfile?.hasAbsoluteAnchor ?? false
        self.hasSparseData = elevationProfile?.hasSparseData ?? false
    }
}
