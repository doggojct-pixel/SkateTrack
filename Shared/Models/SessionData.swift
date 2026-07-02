// [協作區] Shared/Models/SessionData.swift
// 用途：定義 SkateTrack session 根容器，集中保存模式、動力、感測樣本、招式與跌倒事件。
// 委派至：SensorProvider、SyncProvider、history、summary、export 與 macOS analysis。

import Foundation



enum DebugRecordingTestContextLabel: String, Codable, CaseIterable, Identifiable, Sendable, Equatable {
    case unspecified
    case handheldScreenOn
    case handheldAutoLock
    case lockedPocketWalk
    case windshieldDrive
    case vehicleScreenOff
    case electricLongboardLockedPocket
    case scooterLockedPocket

    var id: String { rawValue }
}

struct RecordingDebugBuildIdentity: Codable, Sendable, Equatable {
    static let currentDebugBuildTaskID = "Task-030c-b15-A"

    let debugBuildTaskID: String
    let gitBranchName: String?
    let diagnosticsSchemaVersion: Int
    let appVersion: String?
    let buildNumber: String?
    let platform: String?
    let osVersionMajorMinor: String?

    init(
        debugBuildTaskID: String = RecordingDebugBuildIdentity.currentDebugBuildTaskID,
        gitBranchName: String? = "task-030c-gps-route-fidelity",
        diagnosticsSchemaVersion: Int = 1,
        appVersion: String? = nil,
        buildNumber: String? = nil,
        platform: String? = nil,
        osVersionMajorMinor: String? = nil
    ) {
        self.debugBuildTaskID = debugBuildTaskID
        self.gitBranchName = gitBranchName
        self.diagnosticsSchemaVersion = diagnosticsSchemaVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.platform = platform
        self.osVersionMajorMinor = osVersionMajorMinor
    }
}

struct RecordingDebugRuntimeSnapshot: Codable, Sendable, Equatable {
    let timestamp: Date
    let secondsSinceSessionStart: TimeInterval?
    let appState: String?
    let scenePhase: String?
    let isProtectedDataAvailable: Bool?
    let backgroundRefreshStatus: String?
    let isLowPowerModeEnabled: Bool?
    let thermalState: String?
    let isIdleTimerDisabled: Bool?

    init(
        timestamp: Date = Date(),
        secondsSinceSessionStart: TimeInterval? = nil,
        appState: String? = nil,
        scenePhase: String? = nil,
        isProtectedDataAvailable: Bool? = nil,
        backgroundRefreshStatus: String? = nil,
        isLowPowerModeEnabled: Bool? = nil,
        thermalState: String? = nil,
        isIdleTimerDisabled: Bool? = nil
    ) {
        self.timestamp = timestamp
        self.secondsSinceSessionStart = secondsSinceSessionStart
        self.appState = appState
        self.scenePhase = scenePhase
        self.isProtectedDataAvailable = isProtectedDataAvailable
        self.backgroundRefreshStatus = backgroundRefreshStatus
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.thermalState = thermalState
        self.isIdleTimerDisabled = isIdleTimerDisabled
    }
}

struct RecordingDebugTestContext: Codable, Sendable, Equatable {
    let label: DebugRecordingTestContextLabel
    let note: String?

    init(label: DebugRecordingTestContextLabel = .unspecified, note: String? = nil) {
        self.label = label
        self.note = note
    }
}

struct RecordingDebugLifecycleEvent: Codable, Sendable, Equatable {
    let timestamp: Date
    let eventType: String
    let runtime: RecordingDebugRuntimeSnapshot?

    init(timestamp: Date = Date(), eventType: String, runtime: RecordingDebugRuntimeSnapshot? = nil) {
        self.timestamp = timestamp
        self.eventType = eventType
        self.runtime = runtime
    }
}

struct RecordingDebugHeartbeat: Codable, Sendable, Equatable {
    let timestamp: Date
    let elapsedSessionSeconds: TimeInterval?
    let isRecordingActive: Bool
    let sessionStatus: String
    let motionSampleCount: Int
    let locationFixCount: Int
    let timerFusionCount: Int
    let lastMotionSampleAgeSeconds: TimeInterval?
    let lastLocationFixAgeSeconds: TimeInterval?
    let lastTimerFusionAgeSeconds: TimeInterval?
    let runtime: RecordingDebugRuntimeSnapshot?

    init(
        timestamp: Date = Date(),
        elapsedSessionSeconds: TimeInterval? = nil,
        isRecordingActive: Bool,
        sessionStatus: String,
        motionSampleCount: Int,
        locationFixCount: Int,
        timerFusionCount: Int,
        lastMotionSampleAgeSeconds: TimeInterval? = nil,
        lastLocationFixAgeSeconds: TimeInterval? = nil,
        lastTimerFusionAgeSeconds: TimeInterval? = nil,
        runtime: RecordingDebugRuntimeSnapshot? = nil
    ) {
        self.timestamp = timestamp
        self.elapsedSessionSeconds = elapsedSessionSeconds
        self.isRecordingActive = isRecordingActive
        self.sessionStatus = sessionStatus
        self.motionSampleCount = max(0, motionSampleCount)
        self.locationFixCount = max(0, locationFixCount)
        self.timerFusionCount = max(0, timerFusionCount)
        self.lastMotionSampleAgeSeconds = lastMotionSampleAgeSeconds
        self.lastLocationFixAgeSeconds = lastLocationFixAgeSeconds
        self.lastTimerFusionAgeSeconds = lastTimerFusionAgeSeconds
        self.runtime = runtime
    }
}


struct RecordingDebugBundleInfoSnapshot: Codable, Sendable, Equatable {
    let bundleIdentifier: String?
    let bundlePathLastComponent: String?
    let executablePathLastComponent: String?
    let hasUIBackgroundModesKey: Bool
    let uiBackgroundModesRawDescription: String?
    let resolvedUIBackgroundModes: [String]
    let hasLocationBackgroundMode: Bool

    init(
        bundleIdentifier: String? = nil,
        bundlePathLastComponent: String? = nil,
        executablePathLastComponent: String? = nil,
        hasUIBackgroundModesKey: Bool = false,
        uiBackgroundModesRawDescription: String? = nil,
        resolvedUIBackgroundModes: [String] = [],
        hasLocationBackgroundMode: Bool = false
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.bundlePathLastComponent = bundlePathLastComponent
        self.executablePathLastComponent = executablePathLastComponent
        self.hasUIBackgroundModesKey = hasUIBackgroundModesKey
        self.uiBackgroundModesRawDescription = uiBackgroundModesRawDescription
        self.resolvedUIBackgroundModes = resolvedUIBackgroundModes
        self.hasLocationBackgroundMode = hasLocationBackgroundMode
    }
}

struct RecordingDebugLocationManagerSnapshot: Codable, Sendable, Equatable {
    let timestamp: Date
    let reason: String
    let desiredAccuracy: Double?
    let distanceFilterMeters: Double?
    let activityType: String?
    let pausesLocationUpdatesAutomatically: Bool?
    let allowsBackgroundLocationUpdates: Bool?
    let showsBackgroundLocationIndicator: Bool?
    let isSignificantLocationChangeMonitoringActive: Bool?
    let wantsLocationUpdates: Bool?
    let wantsBackgroundLocationUpdates: Bool?
    let hasBackgroundLocationModeDeclared: Bool?
    let bundleInfo: RecordingDebugBundleInfoSnapshot?
    let authorizationStatus: String?
    let accuracyAuthorization: String?

    init(
        timestamp: Date = Date(),
        reason: String,
        desiredAccuracy: Double? = nil,
        distanceFilterMeters: Double? = nil,
        activityType: String? = nil,
        pausesLocationUpdatesAutomatically: Bool? = nil,
        allowsBackgroundLocationUpdates: Bool? = nil,
        showsBackgroundLocationIndicator: Bool? = nil,
        isSignificantLocationChangeMonitoringActive: Bool? = nil,
        wantsLocationUpdates: Bool? = nil,
        wantsBackgroundLocationUpdates: Bool? = nil,
        hasBackgroundLocationModeDeclared: Bool? = nil,
        bundleInfo: RecordingDebugBundleInfoSnapshot? = nil,
        authorizationStatus: String? = nil,
        accuracyAuthorization: String? = nil
    ) {
        self.timestamp = timestamp
        self.reason = reason
        self.desiredAccuracy = desiredAccuracy
        self.distanceFilterMeters = distanceFilterMeters
        self.activityType = activityType
        self.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
        self.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        self.showsBackgroundLocationIndicator = showsBackgroundLocationIndicator
        self.isSignificantLocationChangeMonitoringActive = isSignificantLocationChangeMonitoringActive
        self.wantsLocationUpdates = wantsLocationUpdates
        self.wantsBackgroundLocationUpdates = wantsBackgroundLocationUpdates
        self.hasBackgroundLocationModeDeclared = hasBackgroundLocationModeDeclared
        self.bundleInfo = bundleInfo
        self.authorizationStatus = authorizationStatus
        self.accuracyAuthorization = accuracyAuthorization
    }
}

struct RecordingDebugAuthorizationSnapshot: Codable, Sendable, Equatable {
    let timestamp: Date
    let reason: String
    let authorizationStatus: String
    let accuracyAuthorization: String?
    let locationServicesEnabled: Bool?
    let backgroundRefreshStatus: String?

    init(
        timestamp: Date = Date(),
        reason: String,
        authorizationStatus: String,
        accuracyAuthorization: String? = nil,
        locationServicesEnabled: Bool? = nil,
        backgroundRefreshStatus: String? = nil
    ) {
        self.timestamp = timestamp
        self.reason = reason
        self.authorizationStatus = authorizationStatus
        self.accuracyAuthorization = accuracyAuthorization
        self.locationServicesEnabled = locationServicesEnabled
        self.backgroundRefreshStatus = backgroundRefreshStatus
    }
}

struct RecordingDebugLocationCallbackEvent: Codable, Sendable, Equatable {
    let timestamp: Date
    let eventType: String
    let locationBatchCount: Int?
    let newestLocationTimestamp: Date?
    let newestLocationAgeSeconds: TimeInterval?
    let horizontalAccuracyMeters: Double?
    let verticalAccuracyMeters: Double?
    let speedKmh: Double?
    let speedAccuracyMetersPerSecond: Double?
    let courseDegrees: Double?
    let courseAccuracyDegrees: Double?
    let isSimulatedBySoftware: Bool?
    let isProducedByAccessory: Bool?
    let errorDescription: String?

    init(
        timestamp: Date = Date(),
        eventType: String,
        locationBatchCount: Int? = nil,
        newestLocationTimestamp: Date? = nil,
        newestLocationAgeSeconds: TimeInterval? = nil,
        horizontalAccuracyMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        speedKmh: Double? = nil,
        speedAccuracyMetersPerSecond: Double? = nil,
        courseDegrees: Double? = nil,
        courseAccuracyDegrees: Double? = nil,
        isSimulatedBySoftware: Bool? = nil,
        isProducedByAccessory: Bool? = nil,
        errorDescription: String? = nil
    ) {
        self.timestamp = timestamp
        self.eventType = eventType
        self.locationBatchCount = locationBatchCount.map { max(0, $0) }
        self.newestLocationTimestamp = newestLocationTimestamp
        self.newestLocationAgeSeconds = newestLocationAgeSeconds
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.speedKmh = speedKmh
        self.speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond
        self.courseDegrees = courseDegrees
        self.courseAccuracyDegrees = courseAccuracyDegrees
        self.isSimulatedBySoftware = isSimulatedBySoftware
        self.isProducedByAccessory = isProducedByAccessory
        self.errorDescription = errorDescription
    }
}

struct RecordingDebugGapEvent: Codable, Sendable, Equatable {
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: TimeInterval
    let gapType: String
    let appStateAtEnd: String?
    let authorizationStatus: String?
    let accuracyAuthorization: String?
    let lastKnownHorizontalAccuracyMeters: Double?
    let lastKnownSpeedKmh: Double?
    let lastKnownSpeedAccuracyMetersPerSecond: Double?
    let lastLocationAgeAtEndSeconds: TimeInterval?
    let lastMotionAgeAtEndSeconds: TimeInterval?
    let motionLoopAlsoPaused: Bool?
    let timerFusionAlsoPaused: Bool?
    let restartAttempted: Bool?
    let restartRecovered: Bool?

    init(
        startedAt: Date,
        endedAt: Date,
        durationSeconds: TimeInterval,
        gapType: String,
        appStateAtEnd: String? = nil,
        authorizationStatus: String? = nil,
        accuracyAuthorization: String? = nil,
        lastKnownHorizontalAccuracyMeters: Double? = nil,
        lastKnownSpeedKmh: Double? = nil,
        lastKnownSpeedAccuracyMetersPerSecond: Double? = nil,
        lastLocationAgeAtEndSeconds: TimeInterval? = nil,
        lastMotionAgeAtEndSeconds: TimeInterval? = nil,
        motionLoopAlsoPaused: Bool? = nil,
        timerFusionAlsoPaused: Bool? = nil,
        restartAttempted: Bool? = nil,
        restartRecovered: Bool? = nil
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = max(0, durationSeconds)
        self.gapType = gapType
        self.appStateAtEnd = appStateAtEnd
        self.authorizationStatus = authorizationStatus
        self.accuracyAuthorization = accuracyAuthorization
        self.lastKnownHorizontalAccuracyMeters = lastKnownHorizontalAccuracyMeters
        self.lastKnownSpeedKmh = lastKnownSpeedKmh
        self.lastKnownSpeedAccuracyMetersPerSecond = lastKnownSpeedAccuracyMetersPerSecond
        self.lastLocationAgeAtEndSeconds = lastLocationAgeAtEndSeconds
        self.lastMotionAgeAtEndSeconds = lastMotionAgeAtEndSeconds
        self.motionLoopAlsoPaused = motionLoopAlsoPaused
        self.timerFusionAlsoPaused = timerFusionAlsoPaused
        self.restartAttempted = restartAttempted
        self.restartRecovered = restartRecovered
    }
}

struct RecordingDebugRecoveryEvent: Codable, Sendable, Equatable {
    let timestamp: Date
    let eventType: String
    let reason: String
    let previousGapSeconds: TimeInterval?
    let secondsUntilFirstRecoveredLocation: TimeInterval?
    let locationFixCountBefore: Int?
    let locationFixCountAfter: Int?

    init(
        timestamp: Date = Date(),
        eventType: String,
        reason: String,
        previousGapSeconds: TimeInterval? = nil,
        secondsUntilFirstRecoveredLocation: TimeInterval? = nil,
        locationFixCountBefore: Int? = nil,
        locationFixCountAfter: Int? = nil
    ) {
        self.timestamp = timestamp
        self.eventType = eventType
        self.reason = reason
        self.previousGapSeconds = previousGapSeconds
        self.secondsUntilFirstRecoveredLocation = secondsUntilFirstRecoveredLocation
        self.locationFixCountBefore = locationFixCountBefore
        self.locationFixCountAfter = locationFixCountAfter
    }
}

struct RecordingDebugFilterDecisionSummary: Codable, Sendable, Equatable {
    let acceptedLocationFixCount: Int
    let rejectedLocationFixCount: Int
    let rejectionReasons: [String: Int]

    init(acceptedLocationFixCount: Int = 0, rejectedLocationFixCount: Int = 0, rejectionReasons: [String: Int] = [:]) {
        self.acceptedLocationFixCount = max(0, acceptedLocationFixCount)
        self.rejectedLocationFixCount = max(0, rejectedLocationFixCount)
        self.rejectionReasons = rejectionReasons
    }
}

struct RecordingDebugAltitudeDiagnostics: Codable, Sendable, Equatable {
    let altitudeSourceCounts: [String: Int]
    let coreLocationAltitudeAcceptedCount: Int
    let coreLocationAltitudeRejectedCount: Int
    let barometerRelativeAltitudeAcceptedCount: Int
    let maxSingleAltitudeJumpMeters: Double?
    let maxVerticalAccuracyMeters: Double?
    let altitudeRejectionReasons: [String: Int]

    init(
        altitudeSourceCounts: [String: Int] = [:],
        coreLocationAltitudeAcceptedCount: Int = 0,
        coreLocationAltitudeRejectedCount: Int = 0,
        barometerRelativeAltitudeAcceptedCount: Int = 0,
        maxSingleAltitudeJumpMeters: Double? = nil,
        maxVerticalAccuracyMeters: Double? = nil,
        altitudeRejectionReasons: [String: Int] = [:]
    ) {
        self.altitudeSourceCounts = altitudeSourceCounts
        self.coreLocationAltitudeAcceptedCount = max(0, coreLocationAltitudeAcceptedCount)
        self.coreLocationAltitudeRejectedCount = max(0, coreLocationAltitudeRejectedCount)
        self.barometerRelativeAltitudeAcceptedCount = max(0, barometerRelativeAltitudeAcceptedCount)
        self.maxSingleAltitudeJumpMeters = maxSingleAltitudeJumpMeters
        self.maxVerticalAccuracyMeters = maxVerticalAccuracyMeters
        self.altitudeRejectionReasons = altitudeRejectionReasons
    }
}

struct RecordingDebugDiagnostics: Codable, Sendable, Equatable {
    let buildIdentity: RecordingDebugBuildIdentity
    let testContext: RecordingDebugTestContext?
    let diagnosticsStartedAt: Date
    let diagnosticsEndedAt: Date?
    let diagnosticsStatus: String?
    let appLifecycleEvents: [RecordingDebugLifecycleEvent]
    let recordingHeartbeats: [RecordingDebugHeartbeat]
    let authorizationSnapshots: [RecordingDebugAuthorizationSnapshot]
    let locationManagerSnapshots: [RecordingDebugLocationManagerSnapshot]
    let locationCallbackEvents: [RecordingDebugLocationCallbackEvent]
    let gapEvents: [RecordingDebugGapEvent]
    let recoveryEvents: [RecordingDebugRecoveryEvent]
    let filterDecisionSummary: RecordingDebugFilterDecisionSummary?
    let altitudeDiagnostics: RecordingDebugAltitudeDiagnostics?

    init(
        buildIdentity: RecordingDebugBuildIdentity = RecordingDebugBuildIdentity(),
        testContext: RecordingDebugTestContext? = nil,
        diagnosticsStartedAt: Date,
        diagnosticsEndedAt: Date? = nil,
        diagnosticsStatus: String? = nil,
        appLifecycleEvents: [RecordingDebugLifecycleEvent] = [],
        recordingHeartbeats: [RecordingDebugHeartbeat] = [],
        authorizationSnapshots: [RecordingDebugAuthorizationSnapshot] = [],
        locationManagerSnapshots: [RecordingDebugLocationManagerSnapshot] = [],
        locationCallbackEvents: [RecordingDebugLocationCallbackEvent] = [],
        gapEvents: [RecordingDebugGapEvent] = [],
        recoveryEvents: [RecordingDebugRecoveryEvent] = [],
        filterDecisionSummary: RecordingDebugFilterDecisionSummary? = nil,
        altitudeDiagnostics: RecordingDebugAltitudeDiagnostics? = nil
    ) {
        self.buildIdentity = buildIdentity
        self.testContext = testContext
        self.diagnosticsStartedAt = diagnosticsStartedAt
        self.diagnosticsEndedAt = diagnosticsEndedAt
        self.diagnosticsStatus = diagnosticsStatus
        self.appLifecycleEvents = appLifecycleEvents
        self.recordingHeartbeats = recordingHeartbeats
        self.authorizationSnapshots = authorizationSnapshots
        self.locationManagerSnapshots = locationManagerSnapshots
        self.locationCallbackEvents = locationCallbackEvents
        self.gapEvents = gapEvents
        self.recoveryEvents = recoveryEvents
        self.filterDecisionSummary = filterDecisionSummary
        self.altitudeDiagnostics = altitudeDiagnostics
    }
}

struct SessionData: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let sportMode: SportMode
    let powerType: PowerType
    let motionSamples: [MotionSample]
    let trickEvents: [TrickEvent]
    let fallEvents: [FallEvent]
    let summaryMetrics: SessionSummaryMetrics?
    let routeQualitySummary: RouteQualitySummary?
    let fidelityProfile: ActivityFidelityProfile?
    let debugRecordingDiagnostics: RecordingDebugDiagnostics?
    let equipmentID: UUID?
    let equipmentSnapshot: EquipmentSessionSnapshot?
    let spotID: UUID?
    let spotSnapshot: SpotSessionSnapshot?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        sportMode: SportMode,
        powerType: PowerType = .humanPowered,
        motionSamples: [MotionSample] = [],
        trickEvents: [TrickEvent] = [],
        fallEvents: [FallEvent] = [],
        summaryMetrics: SessionSummaryMetrics? = nil,
        routeQualitySummary: RouteQualitySummary? = nil,
        fidelityProfile: ActivityFidelityProfile? = nil,
        debugRecordingDiagnostics: RecordingDebugDiagnostics? = nil,
        equipmentID: UUID? = nil,
        equipmentSnapshot: EquipmentSessionSnapshot? = nil,
        spotID: UUID? = nil,
        spotSnapshot: SpotSessionSnapshot? = nil
    ) throws {
        guard powerType.isValid(for: sportMode) else {
            throw PowerTypeValidationError.electricPowerRequiresSkateboardMode
        }

        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.sportMode = sportMode
        self.powerType = powerType
        self.motionSamples = motionSamples
        self.trickEvents = trickEvents
        self.fallEvents = fallEvents
        self.summaryMetrics = summaryMetrics
        self.routeQualitySummary = routeQualitySummary
        self.fidelityProfile = fidelityProfile ?? ActivityFidelityProfile.defaultProfile(for: sportMode, powerType: powerType)
        self.debugRecordingDiagnostics = debugRecordingDiagnostics
        self.equipmentID = equipmentID
        self.equipmentSnapshot = equipmentSnapshot
        self.spotID = spotID
        self.spotSnapshot = spotSnapshot
    }

    var durationSeconds: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    var isPowerConfigurationValid: Bool {
        powerType.isValid(for: sportMode)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case sportMode
        case powerType
        case motionSamples
        case trickEvents
        case fallEvents
        case summaryMetrics
        case routeQualitySummary
        case fidelityProfile
        case debugRecordingDiagnostics
        case equipmentID
        case equipmentSnapshot
        case spotID
        case spotSnapshot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSportMode = try container.decode(SportMode.self, forKey: .sportMode)
        let decodedPowerType = try container.decode(PowerType.self, forKey: .powerType)

        guard decodedPowerType.isValid(for: decodedSportMode) else {
            throw DecodingError.dataCorruptedError(
                forKey: .powerType,
                in: container,
                debugDescription: "Electric power type requires a skateboard sport mode."
            )
        }

        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        sportMode = decodedSportMode
        powerType = decodedPowerType
        motionSamples = try container.decode([MotionSample].self, forKey: .motionSamples)
        trickEvents = try container.decode([TrickEvent].self, forKey: .trickEvents)
        fallEvents = try container.decode([FallEvent].self, forKey: .fallEvents)
        summaryMetrics = try container.decodeIfPresent(SessionSummaryMetrics.self, forKey: .summaryMetrics)
        routeQualitySummary = try container.decodeIfPresent(RouteQualitySummary.self, forKey: .routeQualitySummary)
        fidelityProfile = try container.decodeIfPresent(ActivityFidelityProfile.self, forKey: .fidelityProfile)
            ?? ActivityFidelityProfile.defaultProfile(for: decodedSportMode, powerType: decodedPowerType)
        debugRecordingDiagnostics = try container.decodeIfPresent(RecordingDebugDiagnostics.self, forKey: .debugRecordingDiagnostics)
        equipmentID = try container.decodeIfPresent(UUID.self, forKey: .equipmentID)
        equipmentSnapshot = try container.decodeIfPresent(EquipmentSessionSnapshot.self, forKey: .equipmentSnapshot)
        spotID = try container.decodeIfPresent(UUID.self, forKey: .spotID)
        spotSnapshot = try container.decodeIfPresent(SpotSessionSnapshot.self, forKey: .spotSnapshot)
    }
}
