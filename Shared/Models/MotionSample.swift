// [協作區] Shared/Models/MotionSample.swift
// 用途：定義 GPS、速度、加速度、陀螺儀、高度與定位品質診斷的單筆跨平台感測樣本。
// 委派至：SensorProvider、session recording、fall detection 與後續分析引擎。

import Foundation

struct GeoCoordinate: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct ThreeAxisValue: Codable, Sendable, Equatable {
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

enum LocationSpeedSource: String, Codable, Sendable, Equatable {
    case coreLocation
    case coordinateDerived
    case debugSimulated
    case stale
    case unavailable
}

enum LocationFreshnessState: String, Codable, Sendable, Equatable {
    case fresh
    case recent
    case stale
    case unavailable
}

enum RouteSegmentConfidence: String, Codable, Sendable, Equatable {
    case high
    case medium
    case low
    case unavailable
}

enum HeadingDiagnosticsSource: String, Codable, Sendable, Equatable {
    case coreLocationCourse
    case deviceMagnetometer
    case courseAndDeviceMagnetometer
    case unavailable
}

struct HeadingDiagnostics: Codable, Sendable, Equatable {
    let source: HeadingDiagnosticsSource
    let headingAvailable: Bool
    let courseOverGroundDegrees: Double?
    let courseAccuracyDegrees: Double?
    let coreLocationSpeedKmh: Double?
    let courseReliableForRouteContinuity: Bool
    let deviceHeadingDeferred: Bool
    let deviceHeadingDegrees: Double?
    let deviceHeadingAccuracyDegrees: Double?
    let deviceHeadingTimestamp: Date?
    let deviceHeadingTimestampMillisecondsSince1970: Int64?
    let deviceHeadingAgeSeconds: TimeInterval?
    let deviceHeadingReliableForRouteContinuity: Bool
    let courseDeviceHeadingDeltaDegrees: Double?
    let courseDeviceHeadingAgreement: Bool?

    init(
        source: HeadingDiagnosticsSource = .unavailable,
        headingAvailable: Bool = false,
        courseOverGroundDegrees: Double? = nil,
        courseAccuracyDegrees: Double? = nil,
        coreLocationSpeedKmh: Double? = nil,
        courseReliableForRouteContinuity: Bool = false,
        deviceHeadingDeferred: Bool = true,
        deviceHeadingDegrees: Double? = nil,
        deviceHeadingAccuracyDegrees: Double? = nil,
        deviceHeadingTimestamp: Date? = nil,
        deviceHeadingTimestampMillisecondsSince1970: Int64? = nil,
        deviceHeadingAgeSeconds: TimeInterval? = nil,
        deviceHeadingReliableForRouteContinuity: Bool = false,
        courseDeviceHeadingDeltaDegrees: Double? = nil,
        courseDeviceHeadingAgreement: Bool? = nil
    ) {
        self.source = source
        self.headingAvailable = headingAvailable
        self.courseOverGroundDegrees = courseOverGroundDegrees
        self.courseAccuracyDegrees = courseAccuracyDegrees
        self.coreLocationSpeedKmh = coreLocationSpeedKmh
        self.courseReliableForRouteContinuity = courseReliableForRouteContinuity
        self.deviceHeadingDeferred = deviceHeadingDeferred
        self.deviceHeadingDegrees = deviceHeadingDegrees
        self.deviceHeadingAccuracyDegrees = deviceHeadingAccuracyDegrees
        self.deviceHeadingTimestamp = deviceHeadingTimestamp
        self.deviceHeadingTimestampMillisecondsSince1970 = deviceHeadingTimestampMillisecondsSince1970
        self.deviceHeadingAgeSeconds = deviceHeadingAgeSeconds.map { max(0, $0) }
        self.deviceHeadingReliableForRouteContinuity = deviceHeadingReliableForRouteContinuity
        self.courseDeviceHeadingDeltaDegrees = courseDeviceHeadingDeltaDegrees
        self.courseDeviceHeadingAgreement = courseDeviceHeadingAgreement
    }

    private enum CodingKeys: String, CodingKey {
        case source
        case headingAvailable
        case courseOverGroundDegrees
        case courseAccuracyDegrees
        case coreLocationSpeedKmh
        case courseReliableForRouteContinuity
        case deviceHeadingDeferred
        case deviceHeadingDegrees
        case deviceHeadingAccuracyDegrees
        case deviceHeadingTimestamp
        case deviceHeadingTimestampMillisecondsSince1970
        case deviceHeadingAgeSeconds
        case deviceHeadingReliableForRouteContinuity
        case courseDeviceHeadingDeltaDegrees
        case courseDeviceHeadingAgreement
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            source: try container.decodeIfPresent(HeadingDiagnosticsSource.self, forKey: .source) ?? .unavailable,
            headingAvailable: try container.decodeIfPresent(Bool.self, forKey: .headingAvailable) ?? false,
            courseOverGroundDegrees: try container.decodeIfPresent(Double.self, forKey: .courseOverGroundDegrees),
            courseAccuracyDegrees: try container.decodeIfPresent(Double.self, forKey: .courseAccuracyDegrees),
            coreLocationSpeedKmh: try container.decodeIfPresent(Double.self, forKey: .coreLocationSpeedKmh),
            courseReliableForRouteContinuity: try container.decodeIfPresent(Bool.self, forKey: .courseReliableForRouteContinuity) ?? false,
            deviceHeadingDeferred: try container.decodeIfPresent(Bool.self, forKey: .deviceHeadingDeferred) ?? true,
            deviceHeadingDegrees: try container.decodeIfPresent(Double.self, forKey: .deviceHeadingDegrees),
            deviceHeadingAccuracyDegrees: try container.decodeIfPresent(Double.self, forKey: .deviceHeadingAccuracyDegrees),
            deviceHeadingTimestamp: try container.decodeIfPresent(Date.self, forKey: .deviceHeadingTimestamp),
            deviceHeadingTimestampMillisecondsSince1970: try container.decodeIfPresent(Int64.self, forKey: .deviceHeadingTimestampMillisecondsSince1970),
            deviceHeadingAgeSeconds: try container.decodeIfPresent(TimeInterval.self, forKey: .deviceHeadingAgeSeconds),
            deviceHeadingReliableForRouteContinuity: try container.decodeIfPresent(Bool.self, forKey: .deviceHeadingReliableForRouteContinuity) ?? false,
            courseDeviceHeadingDeltaDegrees: try container.decodeIfPresent(Double.self, forKey: .courseDeviceHeadingDeltaDegrees),
            courseDeviceHeadingAgreement: try container.decodeIfPresent(Bool.self, forKey: .courseDeviceHeadingAgreement)
        )
    }

    var hasReliableHeadingForRouteContinuity: Bool {
        courseReliableForRouteContinuity || deviceHeadingReliableForRouteContinuity
    }
}

enum GPSGapClassification: String, Codable, Sendable, Equatable {
    case normalCadence
    case shortGap
    case backgroundLocationGap
    case extendedSignalLoss
}

struct GPSGapDiagnostics: Codable, Sendable, Equatable {
    static let shortGapThresholdSeconds: TimeInterval = 1.5
    static let backgroundGapThresholdSeconds: TimeInterval = 5
    static let extendedSignalLossThresholdSeconds: TimeInterval = 30

    let classification: GPSGapClassification
    let gapSeconds: TimeInterval?
    let isTimerFusionRepeat: Bool
    let rawLocationAvailable: Bool

    init(
        classification: GPSGapClassification,
        gapSeconds: TimeInterval? = nil,
        isTimerFusionRepeat: Bool = false,
        rawLocationAvailable: Bool = true
    ) {
        self.classification = classification
        self.gapSeconds = gapSeconds.map { max(0, $0) }
        self.isTimerFusionRepeat = isTimerFusionRepeat
        self.rawLocationAvailable = rawLocationAvailable
    }

    static func classification(for gapSeconds: TimeInterval?) -> GPSGapClassification? {
        guard let gapSeconds else { return nil }
        if gapSeconds <= shortGapThresholdSeconds { return .normalCadence }
        if gapSeconds <= backgroundGapThresholdSeconds { return .shortGap }
        if gapSeconds <= extendedSignalLossThresholdSeconds { return .backgroundLocationGap }
        return .extendedSignalLoss
    }
}

enum DeadReckoningReadinessReason: String, Codable, Sendable, Equatable {
    case normalCadence
    case headingUnavailable
    case anchorUnavailable
    case eligibleDiagnosticsOnly
    case r4RouteReconstructionDeferred
}

struct DeadReckoningDiagnostics: Codable, Sendable, Equatable {
    let estimatedRouteActive: Bool
    let eligibleForFutureEstimation: Bool
    let anchorAvailable: Bool
    let gapSeconds: TimeInterval?
    let headingAvailable: Bool
    let reason: DeadReckoningReadinessReason

    init(
        estimatedRouteActive: Bool = false,
        eligibleForFutureEstimation: Bool = false,
        anchorAvailable: Bool = false,
        gapSeconds: TimeInterval? = nil,
        headingAvailable: Bool = false,
        reason: DeadReckoningReadinessReason = .normalCadence
    ) {
        self.estimatedRouteActive = estimatedRouteActive
        self.eligibleForFutureEstimation = eligibleForFutureEstimation
        self.anchorAvailable = anchorAvailable
        self.gapSeconds = gapSeconds.map { max(0, $0) }
        self.headingAvailable = headingAvailable
        self.reason = reason
    }
}


enum DeadReckoningReplayReadinessBlockingReason: String, Codable, Sendable, Equatable, Hashable {
    case noBlockingReason
    case notNeededNormalCadence
    case gapTooShort
    case gapTooLong
    case missingPreGapAnchor
    case missingPostGapAnchor
    case insufficientIMUSamples
    case headingUnavailable
    case headingTooOld
    case headingAccuracyTooPoor
    case diagnosticsUnavailable
    case replayOnlyNotProduction
}

struct DeadReckoningReadinessConfig: Codable, Sendable, Equatable {
    let minimumGapSeconds: TimeInterval
    let maximumReplayGapSeconds: TimeInterval
    let minimumIMUSamplesPerSecond: Double
    let maximumHeadingAgeSeconds: TimeInterval
    let maximumHeadingAccuracyDegrees: Double
    let requirePostGapAnchor: Bool

    init(
        minimumGapSeconds: TimeInterval = 1.5,
        maximumReplayGapSeconds: TimeInterval = 30,
        minimumIMUSamplesPerSecond: Double = 5,
        maximumHeadingAgeSeconds: TimeInterval = 5,
        maximumHeadingAccuracyDegrees: Double = 35,
        requirePostGapAnchor: Bool = true
    ) {
        self.minimumGapSeconds = max(0, minimumGapSeconds)
        self.maximumReplayGapSeconds = max(minimumGapSeconds, maximumReplayGapSeconds)
        self.minimumIMUSamplesPerSecond = max(0, minimumIMUSamplesPerSecond)
        self.maximumHeadingAgeSeconds = max(0, maximumHeadingAgeSeconds)
        self.maximumHeadingAccuracyDegrees = max(0, maximumHeadingAccuracyDegrees)
        self.requirePostGapAnchor = requirePostGapAnchor
    }

    static let conservativeReplayOnly = DeadReckoningReadinessConfig()
}

struct DeadReckoningReadinessGapCandidate: Codable, Sendable, Equatable {
    let sampleID: UUID
    let sampleTimestamp: Date
    let gapClassification: GPSGapClassification
    let gapSeconds: TimeInterval
    let preGapAnchorAvailable: Bool
    let postGapAnchorAvailable: Bool
    let imuSampleCount: Int
    let imuCadenceHz: Double?
    let headingAvailable: Bool
    let headingSource: HeadingDiagnosticsSource?
    let headingAgeSeconds: TimeInterval?
    let headingAccuracyDegrees: Double?
    let eligibleForReplay: Bool
    let blockingReason: DeadReckoningReplayReadinessBlockingReason

    init(
        sampleID: UUID,
        sampleTimestamp: Date,
        gapClassification: GPSGapClassification,
        gapSeconds: TimeInterval,
        preGapAnchorAvailable: Bool,
        postGapAnchorAvailable: Bool,
        imuSampleCount: Int,
        imuCadenceHz: Double? = nil,
        headingAvailable: Bool,
        headingSource: HeadingDiagnosticsSource? = nil,
        headingAgeSeconds: TimeInterval? = nil,
        headingAccuracyDegrees: Double? = nil,
        eligibleForReplay: Bool,
        blockingReason: DeadReckoningReplayReadinessBlockingReason
    ) {
        self.sampleID = sampleID
        self.sampleTimestamp = sampleTimestamp
        self.gapClassification = gapClassification
        self.gapSeconds = max(0, gapSeconds)
        self.preGapAnchorAvailable = preGapAnchorAvailable
        self.postGapAnchorAvailable = postGapAnchorAvailable
        self.imuSampleCount = max(0, imuSampleCount)
        self.imuCadenceHz = imuCadenceHz.map { max(0, $0) }
        self.headingAvailable = headingAvailable
        self.headingSource = headingSource
        self.headingAgeSeconds = headingAgeSeconds.map { max(0, $0) }
        self.headingAccuracyDegrees = headingAccuracyDegrees.map { max(0, $0) }
        self.eligibleForReplay = eligibleForReplay
        self.blockingReason = blockingReason
    }
}

struct DeadReckoningReadinessSummary: Codable, Sendable, Equatable {
    let totalSamples: Int
    let locationFixSampleCount: Int
    let timerFusionSampleCount: Int
    let gapCandidateCount: Int
    let replayEligibleGapCount: Int
    let blockedGapCount: Int
    let blockingReasonCounts: [DeadReckoningReplayReadinessBlockingReason: Int]
    let longestGapSeconds: TimeInterval?
    let medianTimerFusionCadenceHz: Double?
    let medianHeadingAgeSeconds: TimeInterval?
    let candidates: [DeadReckoningReadinessGapCandidate]

    init(
        totalSamples: Int,
        locationFixSampleCount: Int,
        timerFusionSampleCount: Int,
        gapCandidateCount: Int,
        replayEligibleGapCount: Int,
        blockedGapCount: Int,
        blockingReasonCounts: [DeadReckoningReplayReadinessBlockingReason: Int],
        longestGapSeconds: TimeInterval? = nil,
        medianTimerFusionCadenceHz: Double? = nil,
        medianHeadingAgeSeconds: TimeInterval? = nil,
        candidates: [DeadReckoningReadinessGapCandidate]
    ) {
        self.totalSamples = max(0, totalSamples)
        self.locationFixSampleCount = max(0, locationFixSampleCount)
        self.timerFusionSampleCount = max(0, timerFusionSampleCount)
        self.gapCandidateCount = max(0, gapCandidateCount)
        self.replayEligibleGapCount = max(0, replayEligibleGapCount)
        self.blockedGapCount = max(0, blockedGapCount)
        self.blockingReasonCounts = blockingReasonCounts
        self.longestGapSeconds = longestGapSeconds.map { max(0, $0) }
        self.medianTimerFusionCadenceHz = medianTimerFusionCadenceHz.map { max(0, $0) }
        self.medianHeadingAgeSeconds = medianHeadingAgeSeconds.map { max(0, $0) }
        self.candidates = candidates
    }
}

enum DeadReckoningReadinessAnalyzer {
    static func analyze(
        samples: [MotionSample],
        config: DeadReckoningReadinessConfig = .conservativeReplayOnly
    ) -> DeadReckoningReadinessSummary {
        let sortedSamples = samples.sorted { lhs, rhs in
            lhs.timestamp < rhs.timestamp
        }

        let locationFixSampleCount = sortedSamples.filter { $0.sampleSource == .locationFix }.count
        let timerFusionSampleCount = sortedSamples.filter { $0.sampleSource == .timerFusion }.count

        var candidates: [DeadReckoningReadinessGapCandidate] = []
        var timerCadences: [Double] = []
        var headingAges: [TimeInterval] = []

        for sample in sortedSamples {
            guard let diagnostics = sample.locationDiagnostics,
                  let gpsGapDiagnostics = diagnostics.gpsGapDiagnostics,
                  let rawGapSeconds = gpsGapDiagnostics.gapSeconds else {
                continue
            }

            let gapSeconds = max(0, rawGapSeconds)
            let classification = gpsGapDiagnostics.classification
            guard classification != .normalCadence || gapSeconds >= config.minimumGapSeconds else {
                continue
            }

            let gapStart = diagnostics.rawLocationTimestamp ?? sample.timestamp.addingTimeInterval(-gapSeconds)
            let gapEnd = sample.timestamp
            let imuSamples = sortedSamples.filter { candidate in
                candidate.sampleSource == .timerFusion &&
                candidate.timestamp > gapStart &&
                candidate.timestamp <= gapEnd
            }

            let imuCadenceHz: Double?
            if gapSeconds > 0 {
                imuCadenceHz = Double(imuSamples.count) / gapSeconds
            } else {
                imuCadenceHz = nil
            }

            if let imuCadenceHz {
                timerCadences.append(imuCadenceHz)
            }

            let preGapAnchorAvailable = sortedSamples.contains { candidate in
                candidate.timestamp <= gapStart && isTrustedGPSAnchor(candidate)
            }
            let postGapAnchorAvailable = sortedSamples.contains { candidate in
                candidate.timestamp >= gapEnd && isTrustedGPSAnchor(candidate)
            }

            let headingDiagnostics = diagnostics.headingDiagnostics
            let headingAvailable = headingDiagnostics?.hasReliableHeadingForRouteContinuity == true
            let headingAgeSeconds = headingDiagnostics?.deviceHeadingAgeSeconds
            let headingAccuracyDegrees = headingDiagnostics?.deviceHeadingAccuracyDegrees
                ?? headingDiagnostics?.courseAccuracyDegrees

            if let headingAgeSeconds {
                headingAges.append(headingAgeSeconds)
            }

            let blockingReason = readinessBlockingReason(
                gapSeconds: gapSeconds,
                preGapAnchorAvailable: preGapAnchorAvailable,
                postGapAnchorAvailable: postGapAnchorAvailable,
                imuCadenceHz: imuCadenceHz,
                headingAvailable: headingAvailable,
                headingAgeSeconds: headingAgeSeconds,
                headingAccuracyDegrees: headingAccuracyDegrees,
                config: config
            )

            let eligibleForReplay = blockingReason == .noBlockingReason
            candidates.append(
                DeadReckoningReadinessGapCandidate(
                    sampleID: sample.id,
                    sampleTimestamp: sample.timestamp,
                    gapClassification: classification,
                    gapSeconds: gapSeconds,
                    preGapAnchorAvailable: preGapAnchorAvailable,
                    postGapAnchorAvailable: postGapAnchorAvailable,
                    imuSampleCount: imuSamples.count,
                    imuCadenceHz: imuCadenceHz,
                    headingAvailable: headingAvailable,
                    headingSource: headingDiagnostics?.source,
                    headingAgeSeconds: headingAgeSeconds,
                    headingAccuracyDegrees: headingAccuracyDegrees,
                    eligibleForReplay: eligibleForReplay,
                    blockingReason: blockingReason
                )
            )
        }

        var reasonCounts: [DeadReckoningReplayReadinessBlockingReason: Int] = [:]
        for candidate in candidates {
            reasonCounts[candidate.blockingReason, default: 0] += 1
        }

        let replayEligibleGapCount = candidates.filter(\.eligibleForReplay).count
        let longestGapSeconds = candidates.map(\.gapSeconds).max()
        return DeadReckoningReadinessSummary(
            totalSamples: sortedSamples.count,
            locationFixSampleCount: locationFixSampleCount,
            timerFusionSampleCount: timerFusionSampleCount,
            gapCandidateCount: candidates.count,
            replayEligibleGapCount: replayEligibleGapCount,
            blockedGapCount: max(0, candidates.count - replayEligibleGapCount),
            blockingReasonCounts: reasonCounts,
            longestGapSeconds: longestGapSeconds,
            medianTimerFusionCadenceHz: median(timerCadences),
            medianHeadingAgeSeconds: median(headingAges),
            candidates: candidates
        )
    }

    private static func readinessBlockingReason(
        gapSeconds: TimeInterval,
        preGapAnchorAvailable: Bool,
        postGapAnchorAvailable: Bool,
        imuCadenceHz: Double?,
        headingAvailable: Bool,
        headingAgeSeconds: TimeInterval?,
        headingAccuracyDegrees: Double?,
        config: DeadReckoningReadinessConfig
    ) -> DeadReckoningReplayReadinessBlockingReason {
        guard gapSeconds.isFinite else { return .diagnosticsUnavailable }
        if gapSeconds < config.minimumGapSeconds {
            return .gapTooShort
        }
        if gapSeconds > config.maximumReplayGapSeconds {
            return .gapTooLong
        }
        guard preGapAnchorAvailable else {
            return .missingPreGapAnchor
        }
        if config.requirePostGapAnchor, !postGapAnchorAvailable {
            return .missingPostGapAnchor
        }
        guard let imuCadenceHz, imuCadenceHz >= config.minimumIMUSamplesPerSecond else {
            return .insufficientIMUSamples
        }
        guard headingAvailable else {
            return .headingUnavailable
        }
        if let headingAgeSeconds, headingAgeSeconds > config.maximumHeadingAgeSeconds {
            return .headingTooOld
        }
        if let headingAccuracyDegrees, headingAccuracyDegrees > config.maximumHeadingAccuracyDegrees {
            return .headingAccuracyTooPoor
        }
        return .noBlockingReason
    }

    private static func isTrustedGPSAnchor(_ sample: MotionSample) -> Bool {
        guard sample.sampleSource == .locationFix,
              sample.gpsCoordinate != nil else {
            return false
        }

        guard let confidence = sample.locationDiagnostics?.routeSegmentConfidence else {
            return true
        }

        switch confidence {
        case .high, .medium:
            return true
        case .low, .unavailable:
            return false
        }
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }
}


enum DeadReckoningCandidateInterpolationStatus: String, Codable, Sendable, Equatable, Hashable {
    case debugCandidateOnly
    case blockedByReadiness
    case missingAnchors
    case anchorClosureTooLarge
    case noCandidatePoints
}

enum DeadReckoningCandidateInterpolationConfidence: String, Codable, Sendable, Equatable, Hashable {
    case blocked
    case debugLow
    case debugMedium
    case debugHigh
}

enum DeadReckoningCandidateInterpolationWarningReason: String, Codable, Sendable, Equatable, Hashable {
    case noWarning
    case replayOnlyNotProduction
    case anchorClosureModerate
    case headingAccuracyModerate
    case imuCadenceModerate
}

struct DeadReckoningCandidateInterpolationConfig: Codable, Sendable, Equatable {
    let candidatePointIntervalSeconds: TimeInterval
    let maximumCandidatePointCount: Int
    let maximumAnchorClosureDistanceMeters: Double
    let highConfidenceClosureDistanceMeters: Double
    let mediumConfidenceClosureDistanceMeters: Double
    let highConfidenceMinimumIMUCadenceHz: Double
    let highConfidenceMaximumHeadingAccuracyDegrees: Double

    init(
        candidatePointIntervalSeconds: TimeInterval = 1.0,
        maximumCandidatePointCount: Int = 30,
        maximumAnchorClosureDistanceMeters: Double = 80,
        highConfidenceClosureDistanceMeters: Double = 20,
        mediumConfidenceClosureDistanceMeters: Double = 45,
        highConfidenceMinimumIMUCadenceHz: Double = 10,
        highConfidenceMaximumHeadingAccuracyDegrees: Double = 20
    ) {
        self.candidatePointIntervalSeconds = max(0.25, candidatePointIntervalSeconds)
        self.maximumCandidatePointCount = max(1, maximumCandidatePointCount)
        self.maximumAnchorClosureDistanceMeters = max(1, maximumAnchorClosureDistanceMeters)
        self.highConfidenceClosureDistanceMeters = max(1, highConfidenceClosureDistanceMeters)
        self.mediumConfidenceClosureDistanceMeters = max(highConfidenceClosureDistanceMeters, mediumConfidenceClosureDistanceMeters)
        self.highConfidenceMinimumIMUCadenceHz = max(0, highConfidenceMinimumIMUCadenceHz)
        self.highConfidenceMaximumHeadingAccuracyDegrees = max(0, highConfidenceMaximumHeadingAccuracyDegrees)
    }

    static let debugReplayOnly = DeadReckoningCandidateInterpolationConfig()
}

struct DeadReckoningInterpolatedRoutePoint: Codable, Sendable, Equatable {
    let timestamp: Date
    let timestampMillisecondsSince1970: Int64?
    let coordinate: GeoCoordinate
    let progress: Double

    init(timestamp: Date, coordinate: GeoCoordinate, progress: Double) {
        self.timestamp = timestamp
        self.timestampMillisecondsSince1970 = timestamp.millisecondsSince1970
        self.coordinate = coordinate
        self.progress = min(max(progress, 0), 1)
    }
}

struct DeadReckoningCandidateInterpolationResult: Codable, Sendable, Equatable {
    let sampleID: UUID
    let gapStartTimestamp: Date
    let gapEndTimestamp: Date
    let gapSeconds: TimeInterval
    let status: DeadReckoningCandidateInterpolationStatus
    let confidence: DeadReckoningCandidateInterpolationConfidence
    let readinessBlockingReason: DeadReckoningReplayReadinessBlockingReason
    let warningReason: DeadReckoningCandidateInterpolationWarningReason
    let preGapAnchorCoordinate: GeoCoordinate?
    let postGapAnchorCoordinate: GeoCoordinate?
    let anchorClosureDistanceMeters: Double?
    let candidatePointCount: Int
    let candidatePoints: [DeadReckoningInterpolatedRoutePoint]
    let estimatedCandidateDistanceMeters: Double?
    let imuCadenceHz: Double?
    let headingAgeSeconds: TimeInterval?
    let headingAccuracyDegrees: Double?

    init(
        sampleID: UUID,
        gapStartTimestamp: Date,
        gapEndTimestamp: Date,
        gapSeconds: TimeInterval,
        status: DeadReckoningCandidateInterpolationStatus,
        confidence: DeadReckoningCandidateInterpolationConfidence,
        readinessBlockingReason: DeadReckoningReplayReadinessBlockingReason,
        warningReason: DeadReckoningCandidateInterpolationWarningReason,
        preGapAnchorCoordinate: GeoCoordinate? = nil,
        postGapAnchorCoordinate: GeoCoordinate? = nil,
        anchorClosureDistanceMeters: Double? = nil,
        candidatePoints: [DeadReckoningInterpolatedRoutePoint] = [],
        estimatedCandidateDistanceMeters: Double? = nil,
        imuCadenceHz: Double? = nil,
        headingAgeSeconds: TimeInterval? = nil,
        headingAccuracyDegrees: Double? = nil
    ) {
        self.sampleID = sampleID
        self.gapStartTimestamp = gapStartTimestamp
        self.gapEndTimestamp = gapEndTimestamp
        self.gapSeconds = max(0, gapSeconds)
        self.status = status
        self.confidence = confidence
        self.readinessBlockingReason = readinessBlockingReason
        self.warningReason = warningReason
        self.preGapAnchorCoordinate = preGapAnchorCoordinate
        self.postGapAnchorCoordinate = postGapAnchorCoordinate
        self.anchorClosureDistanceMeters = anchorClosureDistanceMeters.map { max(0, $0) }
        self.candidatePointCount = candidatePoints.count
        self.candidatePoints = candidatePoints
        self.estimatedCandidateDistanceMeters = estimatedCandidateDistanceMeters.map { max(0, $0) }
        self.imuCadenceHz = imuCadenceHz.map { max(0, $0) }
        self.headingAgeSeconds = headingAgeSeconds.map { max(0, $0) }
        self.headingAccuracyDegrees = headingAccuracyDegrees.map { max(0, $0) }
    }
}

struct DeadReckoningCandidateInterpolationSummary: Codable, Sendable, Equatable {
    let totalReadinessCandidateCount: Int
    let debugCandidateCount: Int
    let blockedCandidateCount: Int
    let maximumAnchorClosureDistanceMeters: Double?
    let statusCounts: [DeadReckoningCandidateInterpolationStatus: Int]
    let confidenceCounts: [DeadReckoningCandidateInterpolationConfidence: Int]
    let results: [DeadReckoningCandidateInterpolationResult]

    init(
        totalReadinessCandidateCount: Int,
        debugCandidateCount: Int,
        blockedCandidateCount: Int,
        maximumAnchorClosureDistanceMeters: Double? = nil,
        statusCounts: [DeadReckoningCandidateInterpolationStatus: Int],
        confidenceCounts: [DeadReckoningCandidateInterpolationConfidence: Int],
        results: [DeadReckoningCandidateInterpolationResult]
    ) {
        self.totalReadinessCandidateCount = max(0, totalReadinessCandidateCount)
        self.debugCandidateCount = max(0, debugCandidateCount)
        self.blockedCandidateCount = max(0, blockedCandidateCount)
        self.maximumAnchorClosureDistanceMeters = maximumAnchorClosureDistanceMeters.map { max(0, $0) }
        self.statusCounts = statusCounts
        self.confidenceCounts = confidenceCounts
        self.results = results
    }
}

enum DeadReckoningCandidateInterpolationAnalyzer {
    static func analyze(
        samples: [MotionSample],
        readinessSummary: DeadReckoningReadinessSummary? = nil,
        readinessConfig: DeadReckoningReadinessConfig = .conservativeReplayOnly,
        interpolationConfig: DeadReckoningCandidateInterpolationConfig = .debugReplayOnly
    ) -> DeadReckoningCandidateInterpolationSummary {
        let sortedSamples = samples.sorted { lhs, rhs in lhs.timestamp < rhs.timestamp }
        let readiness = readinessSummary ?? DeadReckoningReadinessAnalyzer.analyze(
            samples: sortedSamples,
            config: readinessConfig
        )

        let results = readiness.candidates.map { candidate in
            interpolationResult(
                for: candidate,
                samples: sortedSamples,
                config: interpolationConfig
            )
        }
        var statusCounts: [DeadReckoningCandidateInterpolationStatus: Int] = [:]
        var confidenceCounts: [DeadReckoningCandidateInterpolationConfidence: Int] = [:]
        for result in results {
            statusCounts[result.status, default: 0] += 1
            confidenceCounts[result.confidence, default: 0] += 1
        }
        let debugCandidateCount = results.filter { $0.status == .debugCandidateOnly }.count
        let closureDistances = results.compactMap(\.anchorClosureDistanceMeters)
        return DeadReckoningCandidateInterpolationSummary(
            totalReadinessCandidateCount: readiness.candidates.count,
            debugCandidateCount: debugCandidateCount,
            blockedCandidateCount: max(0, results.count - debugCandidateCount),
            maximumAnchorClosureDistanceMeters: closureDistances.max(),
            statusCounts: statusCounts,
            confidenceCounts: confidenceCounts,
            results: results
        )
    }

    private static func interpolationResult(
        for candidate: DeadReckoningReadinessGapCandidate,
        samples: [MotionSample],
        config: DeadReckoningCandidateInterpolationConfig
    ) -> DeadReckoningCandidateInterpolationResult {
        let gapEnd = candidate.sampleTimestamp
        let gapStart = candidate.sampleTimestamp.addingTimeInterval(-candidate.gapSeconds)
        guard candidate.eligibleForReplay else {
            return DeadReckoningCandidateInterpolationResult(
                sampleID: candidate.sampleID,
                gapStartTimestamp: gapStart,
                gapEndTimestamp: gapEnd,
                gapSeconds: candidate.gapSeconds,
                status: .blockedByReadiness,
                confidence: .blocked,
                readinessBlockingReason: candidate.blockingReason,
                warningReason: .replayOnlyNotProduction,
                imuCadenceHz: candidate.imuCadenceHz,
                headingAgeSeconds: candidate.headingAgeSeconds,
                headingAccuracyDegrees: candidate.headingAccuracyDegrees
            )
        }

        guard let preAnchor = latestTrustedAnchor(beforeOrAt: gapStart, samples: samples),
              let postAnchor = earliestTrustedAnchor(afterOrAt: gapEnd, samples: samples),
              let preCoordinate = preAnchor.gpsCoordinate,
              let postCoordinate = postAnchor.gpsCoordinate else {
            return DeadReckoningCandidateInterpolationResult(
                sampleID: candidate.sampleID,
                gapStartTimestamp: gapStart,
                gapEndTimestamp: gapEnd,
                gapSeconds: candidate.gapSeconds,
                status: .missingAnchors,
                confidence: .blocked,
                readinessBlockingReason: .diagnosticsUnavailable,
                warningReason: .replayOnlyNotProduction,
                imuCadenceHz: candidate.imuCadenceHz,
                headingAgeSeconds: candidate.headingAgeSeconds,
                headingAccuracyDegrees: candidate.headingAccuracyDegrees
            )
        }

        let closureDistance = haversineDistanceMeters(from: preCoordinate, to: postCoordinate)
        guard closureDistance <= config.maximumAnchorClosureDistanceMeters else {
            return DeadReckoningCandidateInterpolationResult(
                sampleID: candidate.sampleID,
                gapStartTimestamp: gapStart,
                gapEndTimestamp: gapEnd,
                gapSeconds: candidate.gapSeconds,
                status: .anchorClosureTooLarge,
                confidence: .blocked,
                readinessBlockingReason: candidate.blockingReason,
                warningReason: .anchorClosureModerate,
                preGapAnchorCoordinate: preCoordinate,
                postGapAnchorCoordinate: postCoordinate,
                anchorClosureDistanceMeters: closureDistance,
                imuCadenceHz: candidate.imuCadenceHz,
                headingAgeSeconds: candidate.headingAgeSeconds,
                headingAccuracyDegrees: candidate.headingAccuracyDegrees
            )
        }

        let pointCount = candidatePointCount(gapSeconds: candidate.gapSeconds, config: config)
        guard pointCount > 0 else {
            return DeadReckoningCandidateInterpolationResult(
                sampleID: candidate.sampleID,
                gapStartTimestamp: gapStart,
                gapEndTimestamp: gapEnd,
                gapSeconds: candidate.gapSeconds,
                status: .noCandidatePoints,
                confidence: .blocked,
                readinessBlockingReason: candidate.blockingReason,
                warningReason: .replayOnlyNotProduction,
                preGapAnchorCoordinate: preCoordinate,
                postGapAnchorCoordinate: postCoordinate,
                anchorClosureDistanceMeters: closureDistance,
                imuCadenceHz: candidate.imuCadenceHz,
                headingAgeSeconds: candidate.headingAgeSeconds,
                headingAccuracyDegrees: candidate.headingAccuracyDegrees
            )
        }

        let candidatePoints = (1...pointCount).map { index in
            let progress = Double(index) / Double(pointCount + 1)
            let timestamp = gapStart.addingTimeInterval(candidate.gapSeconds * progress)
            return DeadReckoningInterpolatedRoutePoint(
                timestamp: timestamp,
                coordinate: interpolateCoordinate(from: preCoordinate, to: postCoordinate, progress: progress),
                progress: progress
            )
        }
        let confidence = confidenceForDebugCandidate(
            closureDistanceMeters: closureDistance,
            imuCadenceHz: candidate.imuCadenceHz,
            headingAccuracyDegrees: candidate.headingAccuracyDegrees,
            config: config
        )
        let warningReason = warningReasonForDebugCandidate(
            closureDistanceMeters: closureDistance,
            imuCadenceHz: candidate.imuCadenceHz,
            headingAccuracyDegrees: candidate.headingAccuracyDegrees,
            config: config
        )
        return DeadReckoningCandidateInterpolationResult(
            sampleID: candidate.sampleID,
            gapStartTimestamp: gapStart,
            gapEndTimestamp: gapEnd,
            gapSeconds: candidate.gapSeconds,
            status: .debugCandidateOnly,
            confidence: confidence,
            readinessBlockingReason: candidate.blockingReason,
            warningReason: warningReason,
            preGapAnchorCoordinate: preCoordinate,
            postGapAnchorCoordinate: postCoordinate,
            anchorClosureDistanceMeters: closureDistance,
            candidatePoints: candidatePoints,
            estimatedCandidateDistanceMeters: closureDistance,
            imuCadenceHz: candidate.imuCadenceHz,
            headingAgeSeconds: candidate.headingAgeSeconds,
            headingAccuracyDegrees: candidate.headingAccuracyDegrees
        )
    }

    private static func candidatePointCount(
        gapSeconds: TimeInterval,
        config: DeadReckoningCandidateInterpolationConfig
    ) -> Int {
        guard gapSeconds.isFinite, gapSeconds > config.candidatePointIntervalSeconds else { return 0 }
        let interiorPointCount = max(1, Int(gapSeconds / config.candidatePointIntervalSeconds) - 1)
        return min(interiorPointCount, config.maximumCandidatePointCount)
    }

    private static func latestTrustedAnchor(beforeOrAt timestamp: Date, samples: [MotionSample]) -> MotionSample? {
        samples.last { sample in
            routeTimestamp(for: sample) <= timestamp && isTrustedGPSAnchor(sample)
        }
    }

    private static func earliestTrustedAnchor(afterOrAt timestamp: Date, samples: [MotionSample]) -> MotionSample? {
        samples.first { sample in
            routeTimestamp(for: sample) >= timestamp && isTrustedGPSAnchor(sample)
        }
    }

    private static func isTrustedGPSAnchor(_ sample: MotionSample) -> Bool {
        guard sample.sampleSource == .locationFix,
              sample.gpsCoordinate != nil else {
            return false
        }
        guard let confidence = sample.locationDiagnostics?.routeSegmentConfidence else {
            return true
        }
        switch confidence {
        case .high, .medium:
            return true
        case .low, .unavailable:
            return false
        }
    }

    private static func routeTimestamp(for sample: MotionSample) -> Date {
        // Task-030c-b15-B-3: candidate interpolation works over persisted sample cadence
        // and remains replay-only; it does not rewrite raw CoreLocation timestamps.
        sample.timestamp
    }

    private static func interpolateCoordinate(
        from start: GeoCoordinate,
        to end: GeoCoordinate,
        progress: Double
    ) -> GeoCoordinate {
        let boundedProgress = min(max(progress, 0), 1)
        return GeoCoordinate(
            latitude: start.latitude + ((end.latitude - start.latitude) * boundedProgress),
            longitude: start.longitude + ((end.longitude - start.longitude) * boundedProgress)
        )
    }

    private static func confidenceForDebugCandidate(
        closureDistanceMeters: Double,
        imuCadenceHz: Double?,
        headingAccuracyDegrees: Double?,
        config: DeadReckoningCandidateInterpolationConfig
    ) -> DeadReckoningCandidateInterpolationConfidence {
        if closureDistanceMeters <= config.highConfidenceClosureDistanceMeters,
           (imuCadenceHz ?? 0) >= config.highConfidenceMinimumIMUCadenceHz,
           (headingAccuracyDegrees ?? .infinity) <= config.highConfidenceMaximumHeadingAccuracyDegrees {
            return .debugHigh
        }
        if closureDistanceMeters <= config.mediumConfidenceClosureDistanceMeters {
            return .debugMedium
        }
        return .debugLow
    }

    private static func warningReasonForDebugCandidate(
        closureDistanceMeters: Double,
        imuCadenceHz: Double?,
        headingAccuracyDegrees: Double?,
        config: DeadReckoningCandidateInterpolationConfig
    ) -> DeadReckoningCandidateInterpolationWarningReason {
        if closureDistanceMeters > config.mediumConfidenceClosureDistanceMeters {
            return .anchorClosureModerate
        }
        if (headingAccuracyDegrees ?? 0) > config.highConfidenceMaximumHeadingAccuracyDegrees {
            return .headingAccuracyModerate
        }
        if (imuCadenceHz ?? 0) < config.highConfidenceMinimumIMUCadenceHz {
            return .imuCadenceModerate
        }
        return .replayOnlyNotProduction
    }

    private static func haversineDistanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let deltaLatitude = (end.latitude - start.latitude) * (.pi / 180)
        let deltaLongitude = (end.longitude - start.longitude) * (.pi / 180)
        let startLatitude = start.latitude * (.pi / 180)
        let endLatitude = end.latitude * (.pi / 180)
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusMeters * centralAngle
    }
}

enum MotionSampleSource: String, Codable, Sendable, Equatable {
    case timerFusion
    case locationFix
    case debugSimulated
}

enum AltitudeSampleSource: String, Codable, Sendable, Equatable, Hashable {
    case coreLocationAbsolute
    case barometerRelative
    case debugSimulated
    case unavailable
}


enum AltitudeTrustClassification: String, Codable, Sendable, Equatable {
    case trusted
    case lowConfidence
    case rejectedOutlier
    case missing
}

enum AltitudeTrustReason: String, Codable, Sendable, Equatable {
    case trusted
    case debugSimulatedTrusted
    case missingAltitude
    case nonFiniteAltitude
    case sourceUnavailable
    case verticalAccuracyUnavailable
    case verticalAccuracyTooPoor
    case startupAltitudeWarmup
    case mixedAbsoluteAndRelativeSource
    case hardAltitudeJump
    case verticalSpeedTooHigh
    case staleLocation
    case lowRouteConfidence
    case firstTrustedAnchor
    case barometerRelativeAccepted
    case coreLocationAbsoluteAccepted
    case fallbackLegacyPolicy
}

struct AltitudePressureDiagnostics: Codable, Sendable, Equatable {
    let rawPressureKilopascals: Double
    let smoothedPressureKilopascals: Double
    let previousSmoothedPressureKilopascals: Double?
    let pressureDeltaKilopascals: Double?
    let filterAlpha: Double
    let spikeSuppressed: Bool

    init(
        rawPressureKilopascals: Double,
        smoothedPressureKilopascals: Double,
        previousSmoothedPressureKilopascals: Double? = nil,
        pressureDeltaKilopascals: Double? = nil,
        filterAlpha: Double,
        spikeSuppressed: Bool = false
    ) {
        self.rawPressureKilopascals = rawPressureKilopascals
        self.smoothedPressureKilopascals = smoothedPressureKilopascals
        self.previousSmoothedPressureKilopascals = previousSmoothedPressureKilopascals
        self.pressureDeltaKilopascals = pressureDeltaKilopascals
        self.filterAlpha = min(max(filterAlpha, 0.001), 1.0)
        self.spikeSuppressed = spikeSuppressed
    }
}

struct AltitudeDiagnostics: Codable, Sendable, Equatable {
    let source: AltitudeSampleSource
    let trustClassification: AltitudeTrustClassification
    let reason: AltitudeTrustReason
    let rawAltitudeMeters: Double?
    let trustedAltitudeMeters: Double?
    let previousTrustedAltitudeMeters: Double?
    let verticalAccuracyMeters: Double?
    let altitudeDeltaMeters: Double?
    let timeDeltaSeconds: TimeInterval?
    let verticalSpeedMetersPerSecond: Double?
    let rejectedByOutlierGuard: Bool
    let updatesTrustedAltitudeAnchor: Bool
    let pressureDiagnostics: AltitudePressureDiagnostics?

    init(
        source: AltitudeSampleSource,
        trustClassification: AltitudeTrustClassification,
        reason: AltitudeTrustReason,
        rawAltitudeMeters: Double? = nil,
        trustedAltitudeMeters: Double? = nil,
        previousTrustedAltitudeMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        altitudeDeltaMeters: Double? = nil,
        timeDeltaSeconds: TimeInterval? = nil,
        verticalSpeedMetersPerSecond: Double? = nil,
        rejectedByOutlierGuard: Bool = false,
        updatesTrustedAltitudeAnchor: Bool = false,
        pressureDiagnostics: AltitudePressureDiagnostics? = nil
    ) {
        self.source = source
        self.trustClassification = trustClassification
        self.reason = reason
        self.rawAltitudeMeters = rawAltitudeMeters
        self.trustedAltitudeMeters = trustedAltitudeMeters
        self.previousTrustedAltitudeMeters = previousTrustedAltitudeMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.altitudeDeltaMeters = altitudeDeltaMeters
        self.timeDeltaSeconds = timeDeltaSeconds.map { max(0, $0) }
        self.verticalSpeedMetersPerSecond = verticalSpeedMetersPerSecond.map { max(0, $0) }
        self.rejectedByOutlierGuard = rejectedByOutlierGuard
        self.updatesTrustedAltitudeAnchor = updatesTrustedAltitudeAnchor
        self.pressureDiagnostics = pressureDiagnostics
    }

    var isTrustedForElevationGain: Bool {
        trustClassification == .trusted && trustedAltitudeMeters != nil && updatesTrustedAltitudeAnchor
    }
}

enum ActivityFidelityProfile: String, Codable, Sendable, Equatable {
    case technicalSkateboard
    case standardSkateboard
    case electricSkateboard
    case inlineRecreation
    case inlineSpeed
    case snowReserved
    case vehicleValidation

    static func defaultProfile(for mode: SportMode, powerType: PowerType = .humanPowered) -> ActivityFidelityProfile {
        switch (mode, powerType) {
        case (.skateboard(.surfskate), _):
            return .technicalSkateboard
        case (.skateboard, .electric):
            return .electricSkateboard
        case (.skateboard, _):
            return .standardSkateboard
        case (.inline(.fitnessSpeed), _):
            return .inlineSpeed
        case (.inline, _):
            return .inlineRecreation
        case (.snow, _):
            return .snowReserved
        }
    }
}

struct ActivityFidelityPolicy: Codable, Sendable, Equatable {
    static let maximumGlobalPlausibleSpeedKmh = 180.0

    let profile: ActivityFidelityProfile
    let preferredHorizontalAccuracyMeters: Double
    let maximumUsableHorizontalAccuracyMeters: Double
    let maximumTrustedUpdateIntervalSeconds: TimeInterval
    let maximumTrustedSegmentDistanceMeters: Double
    let maximumTrustedImpliedSpeedKmh: Double
    let chartMaximumSpeedKmh: Double
    let fallDetectionEnabled: Bool
    let fallDetectionMaximumSpeedKmh: Double
    let maximumElevationStepMeters: Double
    let maximumVerticalAccuracyMeters: Double

    init(profile: ActivityFidelityProfile) {
        self.profile = profile
        switch profile {
        case .technicalSkateboard:
            preferredHorizontalAccuracyMeters = 5
            maximumUsableHorizontalAccuracyMeters = 25
            maximumTrustedUpdateIntervalSeconds = 4
            maximumTrustedSegmentDistanceMeters = 35
            maximumTrustedImpliedSpeedKmh = 45
            chartMaximumSpeedKmh = 60
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 35
            maximumElevationStepMeters = 3
            maximumVerticalAccuracyMeters = 12
        case .standardSkateboard:
            preferredHorizontalAccuracyMeters = 8
            maximumUsableHorizontalAccuracyMeters = 40
            maximumTrustedUpdateIntervalSeconds = 6
            maximumTrustedSegmentDistanceMeters = 80
            maximumTrustedImpliedSpeedKmh = 70
            chartMaximumSpeedKmh = 80
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 45
            maximumElevationStepMeters = 4
            maximumVerticalAccuracyMeters = 15
        case .electricSkateboard:
            preferredHorizontalAccuracyMeters = 10
            maximumUsableHorizontalAccuracyMeters = 60
            maximumTrustedUpdateIntervalSeconds = 8
            maximumTrustedSegmentDistanceMeters = 180
            maximumTrustedImpliedSpeedKmh = 100
            chartMaximumSpeedKmh = 110
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 70
            maximumElevationStepMeters = 5
            maximumVerticalAccuracyMeters = 18
        case .inlineRecreation:
            preferredHorizontalAccuracyMeters = 8
            maximumUsableHorizontalAccuracyMeters = 50
            maximumTrustedUpdateIntervalSeconds = 7
            maximumTrustedSegmentDistanceMeters = 130
            maximumTrustedImpliedSpeedKmh = 85
            chartMaximumSpeedKmh = 90
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 55
            maximumElevationStepMeters = 5
            maximumVerticalAccuracyMeters = 18
        case .inlineSpeed:
            preferredHorizontalAccuracyMeters = 10
            maximumUsableHorizontalAccuracyMeters = 70
            maximumTrustedUpdateIntervalSeconds = 8
            maximumTrustedSegmentDistanceMeters = 240
            maximumTrustedImpliedSpeedKmh = 120
            chartMaximumSpeedKmh = 130
            fallDetectionEnabled = true
            fallDetectionMaximumSpeedKmh = 80
            maximumElevationStepMeters = 6
            maximumVerticalAccuracyMeters = 20
        case .snowReserved:
            preferredHorizontalAccuracyMeters = 12
            maximumUsableHorizontalAccuracyMeters = 80
            maximumTrustedUpdateIntervalSeconds = 8
            maximumTrustedSegmentDistanceMeters = 280
            maximumTrustedImpliedSpeedKmh = 140
            chartMaximumSpeedKmh = 150
            fallDetectionEnabled = false
            fallDetectionMaximumSpeedKmh = 0
            maximumElevationStepMeters = 12
            maximumVerticalAccuracyMeters = 25
        case .vehicleValidation:
            preferredHorizontalAccuracyMeters = 15
            maximumUsableHorizontalAccuracyMeters = 100
            maximumTrustedUpdateIntervalSeconds = 12
            maximumTrustedSegmentDistanceMeters = 500
            maximumTrustedImpliedSpeedKmh = Self.maximumGlobalPlausibleSpeedKmh
            chartMaximumSpeedKmh = Self.maximumGlobalPlausibleSpeedKmh
            fallDetectionEnabled = false
            fallDetectionMaximumSpeedKmh = 0
            maximumElevationStepMeters = 15
            maximumVerticalAccuracyMeters = 35
        }
    }


    var usesStrictSmallAreaLowSpeedGate: Bool {
        switch profile {
        case .technicalSkateboard, .standardSkateboard, .inlineRecreation:
            return true
        case .electricSkateboard, .inlineSpeed, .snowReserved, .vehicleValidation:
            return false
        }
    }

    var displayRouteMaximumHorizontalAccuracyMeters: Double {
        switch profile {
        case .technicalSkateboard:
            return 18
        case .standardSkateboard, .inlineRecreation:
            return 24
        case .electricSkateboard, .inlineSpeed:
            return 70
        case .snowReserved:
            return 90
        case .vehicleValidation:
            return maximumUsableHorizontalAccuracyMeters
        }
    }

    var speedDisplayCorroborationAccuracyMeters: Double {
        switch profile {
        case .technicalSkateboard:
            return max(8, preferredHorizontalAccuracyMeters)
        case .standardSkateboard, .inlineRecreation:
            return max(10, preferredHorizontalAccuracyMeters * 1.25)
        case .electricSkateboard:
            return max(20, preferredHorizontalAccuracyMeters * 1.8)
        case .inlineSpeed:
            return max(24, preferredHorizontalAccuracyMeters * 1.8)
        case .snowReserved:
            return max(30, preferredHorizontalAccuracyMeters * 2.0)
        case .vehicleValidation:
            return max(45, preferredHorizontalAccuracyMeters * 2.5)
        }
    }

    func acceptsSpeed(_ speedKmh: Double) -> Bool {
        speedKmh.isFinite && speedKmh >= 0 && speedKmh <= chartMaximumSpeedKmh
    }

    func acceptsLowSpeedMetricSample(
        speedKmh: Double,
        horizontalAccuracyMeters: Double?,
        speedAccuracyMetersPerSecond: Double?,
        coordinateDerivedSpeedKmh: Double?,
        segmentDistanceMeters: Double?
    ) -> Bool {
        guard acceptsSpeed(speedKmh) else { return false }
        guard let horizontalAccuracyMeters else { return false }

        let strictLowSpeedSuspicionThresholdKmh = 6.0
        let lowSpeedSuspicionThresholdKmh = 7.0
        let localJumpImpliedSpeedThresholdKmh = min(maximumTrustedImpliedSpeedKmh, 18.0)
        let localJumpSegmentThresholdMeters = 8.0
        let smallAreaSegmentThresholdMeters = 2.5
        let accuracyPenaltyThresholdMeters = max(preferredHorizontalAccuracyMeters, 8.0)
        let strictAccuracyPenaltyThresholdMeters = preferredHorizontalAccuracyMeters

        guard horizontalAccuracyMeters <= maximumUsableHorizontalAccuracyMeters else { return false }
        if let coordinateDerivedSpeedKmh,
           coordinateDerivedSpeedKmh > maximumTrustedImpliedSpeedKmh {
            return false
        }
        if let segmentDistanceMeters,
           segmentDistanceMeters > maximumTrustedSegmentDistanceMeters {
            return false
        }

        // Task-030c-b11-r2: keep the strict small-area low-speed gate for human-powered
        // walking/skateboard-like profiles, but do not apply it to electric, snow, speed,
        // or vehicle-validation profiles. High-speed proxy sessions should be judged by
        // their activity-aware route policy rather than by standard-skateboard local-jitter
        // thresholds.
        guard usesStrictSmallAreaLowSpeedGate else { return true }

        // Task-030c-b10-r4: low-speed metrics should not trust Core Location speed alone
        // when the movement is small, the horizontal accuracy is outside the preferred
        // envelope, or the coordinate-implied speed is only weakly corroborated.
        if speedKmh >= strictLowSpeedSuspicionThresholdKmh,
           horizontalAccuracyMeters > strictAccuracyPenaltyThresholdMeters {
            return false
        }

        if speedKmh >= lowSpeedSuspicionThresholdKmh && horizontalAccuracyMeters > accuracyPenaltyThresholdMeters {
            return false
        }

        if let speedAccuracyMetersPerSecond,
           speedAccuracyMetersPerSecond > 1.2,
           speedKmh >= strictLowSpeedSuspicionThresholdKmh {
            return false
        }

        if let coordinateDerivedSpeedKmh,
           speedKmh >= strictLowSpeedSuspicionThresholdKmh,
           coordinateDerivedSpeedKmh >= strictLowSpeedSuspicionThresholdKmh,
           horizontalAccuracyMeters > strictAccuracyPenaltyThresholdMeters {
            return false
        }

        if let coordinateDerivedSpeedKmh,
           coordinateDerivedSpeedKmh >= localJumpImpliedSpeedThresholdKmh,
           horizontalAccuracyMeters > accuracyPenaltyThresholdMeters {
            return false
        }

        if let coordinateDerivedSpeedKmh,
           coordinateDerivedSpeedKmh >= max(speedKmh * 1.6, localJumpImpliedSpeedThresholdKmh),
           horizontalAccuracyMeters > preferredHorizontalAccuracyMeters {
            return false
        }

        if let segmentDistanceMeters,
           segmentDistanceMeters > smallAreaSegmentThresholdMeters,
           horizontalAccuracyMeters > strictAccuracyPenaltyThresholdMeters,
           speedKmh >= strictLowSpeedSuspicionThresholdKmh {
            return false
        }

        if let segmentDistanceMeters,
           segmentDistanceMeters > localJumpSegmentThresholdMeters,
           horizontalAccuracyMeters > preferredHorizontalAccuracyMeters,
           speedKmh >= 5.0 {
            return false
        }

        return true
    }

    func acceptsElevationStep(_ deltaMeters: Double, verticalAccuracyMeters: Double?) -> Bool {
        guard deltaMeters.isFinite, deltaMeters > 0.5, deltaMeters <= maximumElevationStepMeters else { return false }
        guard let verticalAccuracyMeters else { return false }
        return verticalAccuracyMeters <= maximumVerticalAccuracyMeters
    }

    func trustsRouteSegment(
        horizontalAccuracyMeters: Double?,
        freshnessState: LocationFreshnessState,
        updateIntervalSeconds: TimeInterval?,
        segmentDistanceMeters: Double?,
        coordinateDerivedSpeedKmh: Double?
    ) -> Bool {
        guard freshnessState == .fresh || freshnessState == .recent else { return false }
        guard let horizontalAccuracyMeters, horizontalAccuracyMeters <= maximumUsableHorizontalAccuracyMeters else { return false }
        if updateIntervalSeconds.map({ $0 > maximumTrustedUpdateIntervalSeconds }) == true { return false }
        if segmentDistanceMeters.map({ $0 > maximumTrustedSegmentDistanceMeters }) == true { return false }
        if coordinateDerivedSpeedKmh.map({ $0 > maximumTrustedImpliedSpeedKmh }) == true { return false }
        return true
    }
}


struct AltitudePressureFilterConfig: Codable, Sendable, Equatable {
    let smoothingAlpha: Double
    let maxRawPressureStepKilopascals: Double

    init(
        smoothingAlpha: Double = 0.20,
        maxRawPressureStepKilopascals: Double = 0.10
    ) {
        self.smoothingAlpha = min(max(smoothingAlpha, 0.001), 1.0)
        self.maxRawPressureStepKilopascals = max(0.001, maxRawPressureStepKilopascals)
    }

    static let `default` = AltitudePressureFilterConfig()
}

struct AltitudePressureFilter: Sendable, Equatable {
    private var smoothedPressureKilopascals: Double?

    init() {}

    mutating func reset() {
        smoothedPressureKilopascals = nil
    }

    mutating func evaluate(
        rawPressureKilopascals: Double?,
        config: AltitudePressureFilterConfig = .default
    ) -> AltitudePressureDiagnostics? {
        guard let rawPressureKilopascals, rawPressureKilopascals.isFinite else { return nil }

        guard let previousSmoothedPressure = smoothedPressureKilopascals else {
            smoothedPressureKilopascals = rawPressureKilopascals
            return AltitudePressureDiagnostics(
                rawPressureKilopascals: rawPressureKilopascals,
                smoothedPressureKilopascals: rawPressureKilopascals,
                filterAlpha: config.smoothingAlpha,
                spikeSuppressed: false
            )
        }

        let rawDelta = rawPressureKilopascals - previousSmoothedPressure
        let absoluteDelta = abs(rawDelta)
        let spikeSuppressed = absoluteDelta > config.maxRawPressureStepKilopascals
        let clampedPressure: Double
        if spikeSuppressed {
            clampedPressure = previousSmoothedPressure + (rawDelta.sign == .minus ? -config.maxRawPressureStepKilopascals : config.maxRawPressureStepKilopascals)
        } else {
            clampedPressure = rawPressureKilopascals
        }

        let smoothedPressure = (config.smoothingAlpha * clampedPressure)
            + ((1 - config.smoothingAlpha) * previousSmoothedPressure)
        smoothedPressureKilopascals = smoothedPressure

        return AltitudePressureDiagnostics(
            rawPressureKilopascals: rawPressureKilopascals,
            smoothedPressureKilopascals: smoothedPressure,
            previousSmoothedPressureKilopascals: previousSmoothedPressure,
            pressureDeltaKilopascals: rawDelta,
            filterAlpha: config.smoothingAlpha,
            spikeSuppressed: spikeSuppressed
        )
    }
}

struct AltitudeOutlierGuardConfig: Codable, Sendable, Equatable {
    let maxCoreLocationVerticalAccuracyMeters: Double
    let maxCoreLocationVerticalSpeedMetersPerSecond: Double
    let maxBarometerVerticalSpeedMetersPerSecond: Double
    let hardCoreLocationJumpRejectMeters: Double
    let hardBarometerJumpRejectMeters: Double
    let minimumDeltaTimeSeconds: TimeInterval
    let startupWarmupSeconds: TimeInterval

    init(
        maxCoreLocationVerticalAccuracyMeters: Double,
        maxCoreLocationVerticalSpeedMetersPerSecond: Double,
        maxBarometerVerticalSpeedMetersPerSecond: Double = 40,
        hardCoreLocationJumpRejectMeters: Double = 30,
        hardBarometerJumpRejectMeters: Double = 30,
        minimumDeltaTimeSeconds: TimeInterval = 0.2,
        startupWarmupSeconds: TimeInterval = 30
    ) {
        self.maxCoreLocationVerticalAccuracyMeters = max(1, maxCoreLocationVerticalAccuracyMeters)
        self.maxCoreLocationVerticalSpeedMetersPerSecond = max(0.5, maxCoreLocationVerticalSpeedMetersPerSecond)
        self.maxBarometerVerticalSpeedMetersPerSecond = max(1, maxBarometerVerticalSpeedMetersPerSecond)
        self.hardCoreLocationJumpRejectMeters = max(1, hardCoreLocationJumpRejectMeters)
        self.hardBarometerJumpRejectMeters = max(1, hardBarometerJumpRejectMeters)
        self.minimumDeltaTimeSeconds = max(0.001, minimumDeltaTimeSeconds)
        self.startupWarmupSeconds = max(0, startupWarmupSeconds)
    }

    init(policy: ActivityFidelityPolicy) {
        let verticalSpeed: Double
        switch policy.profile {
        case .technicalSkateboard:
            verticalSpeed = 2.0
        case .standardSkateboard, .inlineRecreation:
            verticalSpeed = 3.0
        case .electricSkateboard, .inlineSpeed:
            verticalSpeed = 8.0
        case .snowReserved:
            verticalSpeed = 12.0
        case .vehicleValidation:
            verticalSpeed = 20.0
        }

        self.init(
            maxCoreLocationVerticalAccuracyMeters: policy.maximumVerticalAccuracyMeters,
            maxCoreLocationVerticalSpeedMetersPerSecond: verticalSpeed,
            maxBarometerVerticalSpeedMetersPerSecond: 40.0,
            hardCoreLocationJumpRejectMeters: max(30, policy.maximumElevationStepMeters * 4),
            hardBarometerJumpRejectMeters: max(30, policy.maximumElevationStepMeters * 4)
        )
    }
}

struct AltitudeOutlierGuard: Sendable, Equatable {
    private struct TrustedAnchor: Sendable, Equatable {
        let altitudeMeters: Double
        let timestamp: Date
    }

    private var coreLocationAnchor: TrustedAnchor?
    private var barometerAnchor: TrustedAnchor?
    private var debugAnchor: TrustedAnchor?

    init() {}

    mutating func reset() {
        coreLocationAnchor = nil
        barometerAnchor = nil
        debugAnchor = nil
    }

    mutating func evaluate(
        altitudeMeters: Double?,
        source: AltitudeSampleSource?,
        timestamp: Date,
        verticalAccuracyMeters: Double?,
        locationDiagnostics: LocationFixDiagnostics?,
        sessionStartDate: Date?,
        config: AltitudeOutlierGuardConfig,
        pressureDiagnostics: AltitudePressureDiagnostics? = nil
    ) -> AltitudeDiagnostics {
        let resolvedSource = source ?? .unavailable
        guard resolvedSource != .unavailable else {
            return AltitudeDiagnostics(
                source: .unavailable,
                trustClassification: .missing,
                reason: .sourceUnavailable,
                rawAltitudeMeters: altitudeMeters,
                verticalAccuracyMeters: verticalAccuracyMeters,
                pressureDiagnostics: pressureDiagnostics
            )
        }

        guard let altitudeMeters else {
            return AltitudeDiagnostics(
                source: resolvedSource,
                trustClassification: .missing,
                reason: .missingAltitude,
                verticalAccuracyMeters: verticalAccuracyMeters,
                pressureDiagnostics: pressureDiagnostics
            )
        }

        guard altitudeMeters.isFinite else {
            return AltitudeDiagnostics(
                source: resolvedSource,
                trustClassification: .rejectedOutlier,
                reason: .nonFiniteAltitude,
                rawAltitudeMeters: altitudeMeters,
                verticalAccuracyMeters: verticalAccuracyMeters,
                rejectedByOutlierGuard: true,
                pressureDiagnostics: pressureDiagnostics
            )
        }

        if resolvedSource == .coreLocationAbsolute {
            if locationDiagnostics?.freshnessState == .stale {
                return lowConfidenceDiagnostics(
                    source: resolvedSource,
                    reason: .staleLocation,
                    rawAltitudeMeters: altitudeMeters,
                    verticalAccuracyMeters: verticalAccuracyMeters,
                    pressureDiagnostics: pressureDiagnostics
                )
            }

            if locationDiagnostics?.routeSegmentConfidence == .low || locationDiagnostics?.routeSegmentConfidence == .unavailable {
                let isStartupWarmup = sessionStartDate.map { timestamp.timeIntervalSince($0) <= config.startupWarmupSeconds } ?? false
                return lowConfidenceDiagnostics(
                    source: resolvedSource,
                    reason: isStartupWarmup ? .startupAltitudeWarmup : .lowRouteConfidence,
                    rawAltitudeMeters: altitudeMeters,
                    verticalAccuracyMeters: verticalAccuracyMeters,
                    pressureDiagnostics: pressureDiagnostics
                )
            }

            guard let verticalAccuracyMeters else {
                return lowConfidenceDiagnostics(
                    source: resolvedSource,
                    reason: .verticalAccuracyUnavailable,
                    rawAltitudeMeters: altitudeMeters,
                    verticalAccuracyMeters: nil,
                    pressureDiagnostics: pressureDiagnostics
                )
            }

            guard verticalAccuracyMeters <= config.maxCoreLocationVerticalAccuracyMeters else {
                return lowConfidenceDiagnostics(
                    source: resolvedSource,
                    reason: .verticalAccuracyTooPoor,
                    rawAltitudeMeters: altitudeMeters,
                    verticalAccuracyMeters: verticalAccuracyMeters,
                    pressureDiagnostics: pressureDiagnostics
                )
            }
        }

        let previousAnchor = anchor(for: resolvedSource)
        guard let previousAnchor else {
            setAnchor(TrustedAnchor(altitudeMeters: altitudeMeters, timestamp: timestamp), for: resolvedSource)
            return AltitudeDiagnostics(
                source: resolvedSource,
                trustClassification: .trusted,
                reason: firstTrustedReason(for: resolvedSource),
                rawAltitudeMeters: altitudeMeters,
                trustedAltitudeMeters: altitudeMeters,
                verticalAccuracyMeters: verticalAccuracyMeters,
                updatesTrustedAltitudeAnchor: true,
                pressureDiagnostics: pressureDiagnostics
            )
        }

        let delta = altitudeMeters - previousAnchor.altitudeMeters
        let absoluteDelta = abs(delta)
        let timeDelta = max(timestamp.timeIntervalSince(previousAnchor.timestamp), config.minimumDeltaTimeSeconds)
        let verticalSpeed = absoluteDelta / timeDelta
        let hardJumpThreshold = hardJumpRejectMeters(for: resolvedSource, config: config)
        let verticalSpeedThreshold = maxVerticalSpeedMetersPerSecond(for: resolvedSource, config: config)

        guard absoluteDelta <= hardJumpThreshold else {
            return rejectedDiagnostics(
                source: resolvedSource,
                reason: .hardAltitudeJump,
                rawAltitudeMeters: altitudeMeters,
                previousAnchor: previousAnchor,
                verticalAccuracyMeters: verticalAccuracyMeters,
                altitudeDeltaMeters: delta,
                timeDeltaSeconds: timeDelta,
                verticalSpeedMetersPerSecond: verticalSpeed,
                pressureDiagnostics: pressureDiagnostics
            )
        }

        guard verticalSpeed <= verticalSpeedThreshold else {
            return rejectedDiagnostics(
                source: resolvedSource,
                reason: .verticalSpeedTooHigh,
                rawAltitudeMeters: altitudeMeters,
                previousAnchor: previousAnchor,
                verticalAccuracyMeters: verticalAccuracyMeters,
                altitudeDeltaMeters: delta,
                timeDeltaSeconds: timeDelta,
                verticalSpeedMetersPerSecond: verticalSpeed,
                pressureDiagnostics: pressureDiagnostics
            )
        }

        setAnchor(TrustedAnchor(altitudeMeters: altitudeMeters, timestamp: timestamp), for: resolvedSource)
        return AltitudeDiagnostics(
            source: resolvedSource,
            trustClassification: .trusted,
            reason: acceptedReason(for: resolvedSource),
            rawAltitudeMeters: altitudeMeters,
            trustedAltitudeMeters: altitudeMeters,
            previousTrustedAltitudeMeters: previousAnchor.altitudeMeters,
            verticalAccuracyMeters: verticalAccuracyMeters,
            altitudeDeltaMeters: delta,
            timeDeltaSeconds: timeDelta,
            verticalSpeedMetersPerSecond: verticalSpeed,
            updatesTrustedAltitudeAnchor: true,
            pressureDiagnostics: pressureDiagnostics
        )
    }

    private func lowConfidenceDiagnostics(
        source: AltitudeSampleSource,
        reason: AltitudeTrustReason,
        rawAltitudeMeters: Double,
        verticalAccuracyMeters: Double?,
        pressureDiagnostics: AltitudePressureDiagnostics? = nil
    ) -> AltitudeDiagnostics {
        let previousAnchor = anchor(for: source)
        return AltitudeDiagnostics(
            source: source,
            trustClassification: .lowConfidence,
            reason: reason,
            rawAltitudeMeters: rawAltitudeMeters,
            trustedAltitudeMeters: previousAnchor?.altitudeMeters,
            previousTrustedAltitudeMeters: previousAnchor?.altitudeMeters,
            verticalAccuracyMeters: verticalAccuracyMeters,
            rejectedByOutlierGuard: false,
            updatesTrustedAltitudeAnchor: false,
            pressureDiagnostics: pressureDiagnostics
        )
    }

    private func rejectedDiagnostics(
        source: AltitudeSampleSource,
        reason: AltitudeTrustReason,
        rawAltitudeMeters: Double,
        previousAnchor: TrustedAnchor,
        verticalAccuracyMeters: Double?,
        altitudeDeltaMeters: Double,
        timeDeltaSeconds: TimeInterval,
        verticalSpeedMetersPerSecond: Double,
        pressureDiagnostics: AltitudePressureDiagnostics? = nil
    ) -> AltitudeDiagnostics {
        AltitudeDiagnostics(
            source: source,
            trustClassification: .rejectedOutlier,
            reason: reason,
            rawAltitudeMeters: rawAltitudeMeters,
            trustedAltitudeMeters: previousAnchor.altitudeMeters,
            previousTrustedAltitudeMeters: previousAnchor.altitudeMeters,
            verticalAccuracyMeters: verticalAccuracyMeters,
            altitudeDeltaMeters: altitudeDeltaMeters,
            timeDeltaSeconds: timeDeltaSeconds,
            verticalSpeedMetersPerSecond: verticalSpeedMetersPerSecond,
            rejectedByOutlierGuard: true,
            updatesTrustedAltitudeAnchor: false,
            pressureDiagnostics: pressureDiagnostics
        )
    }

    private func anchor(for source: AltitudeSampleSource) -> TrustedAnchor? {
        switch source {
        case .coreLocationAbsolute:
            return coreLocationAnchor
        case .barometerRelative:
            return barometerAnchor
        case .debugSimulated:
            return debugAnchor
        case .unavailable:
            return nil
        }
    }

    private mutating func setAnchor(_ anchor: TrustedAnchor, for source: AltitudeSampleSource) {
        switch source {
        case .coreLocationAbsolute:
            coreLocationAnchor = anchor
        case .barometerRelative:
            barometerAnchor = anchor
        case .debugSimulated:
            debugAnchor = anchor
        case .unavailable:
            break
        }
    }

    private func firstTrustedReason(for source: AltitudeSampleSource) -> AltitudeTrustReason {
        switch source {
        case .coreLocationAbsolute:
            return .firstTrustedAnchor
        case .barometerRelative:
            return .barometerRelativeAccepted
        case .debugSimulated:
            return .debugSimulatedTrusted
        case .unavailable:
            return .sourceUnavailable
        }
    }

    private func acceptedReason(for source: AltitudeSampleSource) -> AltitudeTrustReason {
        switch source {
        case .coreLocationAbsolute:
            return .coreLocationAbsoluteAccepted
        case .barometerRelative:
            return .barometerRelativeAccepted
        case .debugSimulated:
            return .debugSimulatedTrusted
        case .unavailable:
            return .sourceUnavailable
        }
    }

    private func hardJumpRejectMeters(for source: AltitudeSampleSource, config: AltitudeOutlierGuardConfig) -> Double {
        switch source {
        case .barometerRelative:
            return config.hardBarometerJumpRejectMeters
        case .coreLocationAbsolute, .debugSimulated, .unavailable:
            return config.hardCoreLocationJumpRejectMeters
        }
    }

    private func maxVerticalSpeedMetersPerSecond(
        for source: AltitudeSampleSource,
        config: AltitudeOutlierGuardConfig
    ) -> Double {
        switch source {
        case .barometerRelative:
            return config.maxBarometerVerticalSpeedMetersPerSecond
        case .coreLocationAbsolute:
            return config.maxCoreLocationVerticalSpeedMetersPerSecond
        case .debugSimulated:
            return .greatestFiniteMagnitude
        case .unavailable:
            return 0
        }
    }
}

struct LocationFixDiagnostics: Codable, Sendable, Equatable {
    let horizontalAccuracyMeters: Double?
    let verticalAccuracyMeters: Double?
    let speedAccuracyMetersPerSecond: Double?
    let courseAccuracyDegrees: Double?
    let rawLocationTimestamp: Date?
    let rawLocationTimestampMillisecondsSince1970: Int64?
    let receivedAtTimestamp: Date?
    let receivedAtTimestampMillisecondsSince1970: Int64?
    let gpsUpdateIntervalSeconds: TimeInterval?
    let gpsSegmentDistanceMeters: Double?
    let coordinateDerivedSpeedKmh: Double?
    let speedSource: LocationSpeedSource
    let freshnessState: LocationFreshnessState
    let routeSegmentConfidence: RouteSegmentConfidence
    let headingDiagnostics: HeadingDiagnostics?
    let gpsGapDiagnostics: GPSGapDiagnostics?
    let deadReckoningDiagnostics: DeadReckoningDiagnostics?
    let barometricGPSOutlierDecision: BarometricGPSOutlierDecision?
    let locationAccuracySourceDiagnostics: LocationAccuracySourceDiagnostics?

    init(
        horizontalAccuracyMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        speedAccuracyMetersPerSecond: Double? = nil,
        courseAccuracyDegrees: Double? = nil,
        rawLocationTimestamp: Date? = nil,
        rawLocationTimestampMillisecondsSince1970: Int64? = nil,
        receivedAtTimestamp: Date? = nil,
        receivedAtTimestampMillisecondsSince1970: Int64? = nil,
        gpsUpdateIntervalSeconds: TimeInterval? = nil,
        gpsSegmentDistanceMeters: Double? = nil,
        coordinateDerivedSpeedKmh: Double? = nil,
        speedSource: LocationSpeedSource = .unavailable,
        freshnessState: LocationFreshnessState = .unavailable,
        routeSegmentConfidence: RouteSegmentConfidence = .unavailable,
        headingDiagnostics: HeadingDiagnostics? = nil,
        gpsGapDiagnostics: GPSGapDiagnostics? = nil,
        deadReckoningDiagnostics: DeadReckoningDiagnostics? = nil,
        barometricGPSOutlierDecision: BarometricGPSOutlierDecision? = nil,
        locationAccuracySourceDiagnostics: LocationAccuracySourceDiagnostics? = nil
    ) {
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond
        self.courseAccuracyDegrees = courseAccuracyDegrees
        self.rawLocationTimestamp = rawLocationTimestamp
        self.rawLocationTimestampMillisecondsSince1970 = rawLocationTimestampMillisecondsSince1970
        self.receivedAtTimestamp = receivedAtTimestamp
        self.receivedAtTimestampMillisecondsSince1970 = receivedAtTimestampMillisecondsSince1970
        self.gpsUpdateIntervalSeconds = gpsUpdateIntervalSeconds
        self.gpsSegmentDistanceMeters = gpsSegmentDistanceMeters
        self.coordinateDerivedSpeedKmh = coordinateDerivedSpeedKmh
        self.speedSource = speedSource
        self.freshnessState = freshnessState
        self.routeSegmentConfidence = routeSegmentConfidence
        self.headingDiagnostics = headingDiagnostics
        self.gpsGapDiagnostics = gpsGapDiagnostics
        self.deadReckoningDiagnostics = deadReckoningDiagnostics
        self.barometricGPSOutlierDecision = barometricGPSOutlierDecision
        self.locationAccuracySourceDiagnostics = locationAccuracySourceDiagnostics
    }

    func replacingR4Diagnostics(
        headingDiagnostics: HeadingDiagnostics? = nil,
        gpsGapDiagnostics: GPSGapDiagnostics? = nil,
        deadReckoningDiagnostics: DeadReckoningDiagnostics? = nil,
        barometricGPSOutlierDecision: BarometricGPSOutlierDecision? = nil,
        locationAccuracySourceDiagnostics: LocationAccuracySourceDiagnostics? = nil
    ) -> LocationFixDiagnostics {
        LocationFixDiagnostics(
            horizontalAccuracyMeters: horizontalAccuracyMeters,
            verticalAccuracyMeters: verticalAccuracyMeters,
            speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
            courseAccuracyDegrees: courseAccuracyDegrees,
            rawLocationTimestamp: rawLocationTimestamp,
            rawLocationTimestampMillisecondsSince1970: rawLocationTimestampMillisecondsSince1970,
            receivedAtTimestamp: receivedAtTimestamp,
            receivedAtTimestampMillisecondsSince1970: receivedAtTimestampMillisecondsSince1970,
            gpsUpdateIntervalSeconds: gpsUpdateIntervalSeconds,
            gpsSegmentDistanceMeters: gpsSegmentDistanceMeters,
            coordinateDerivedSpeedKmh: coordinateDerivedSpeedKmh,
            speedSource: speedSource,
            freshnessState: freshnessState,
            routeSegmentConfidence: routeSegmentConfidence,
            headingDiagnostics: headingDiagnostics ?? self.headingDiagnostics,
            gpsGapDiagnostics: gpsGapDiagnostics ?? self.gpsGapDiagnostics,
            deadReckoningDiagnostics: deadReckoningDiagnostics ?? self.deadReckoningDiagnostics,
            barometricGPSOutlierDecision: barometricGPSOutlierDecision ?? self.barometricGPSOutlierDecision,
            locationAccuracySourceDiagnostics: locationAccuracySourceDiagnostics ?? self.locationAccuracySourceDiagnostics
        )
    }
}

struct RouteQualitySummary: Codable, Sendable, Equatable {
    let sampleCount: Int
    let gpsSampleCount: Int
    let uniqueCoordinateCount: Int
    let lowConfidenceSegmentCount: Int
    let staleLocationSampleCount: Int
    let averageGPSUpdateIntervalSeconds: TimeInterval?
    let maxGPSUpdateIntervalSeconds: TimeInterval?
    let maxMotionSampleIntervalSeconds: TimeInterval?
    let longLocationUpdateGapCount: Int?
    let longMotionSampleGapCount: Int?
    let totalGPSDistanceMeters: Double

    init(
        sampleCount: Int,
        gpsSampleCount: Int,
        uniqueCoordinateCount: Int,
        lowConfidenceSegmentCount: Int,
        staleLocationSampleCount: Int,
        averageGPSUpdateIntervalSeconds: TimeInterval? = nil,
        maxGPSUpdateIntervalSeconds: TimeInterval? = nil,
        maxMotionSampleIntervalSeconds: TimeInterval? = nil,
        longLocationUpdateGapCount: Int? = nil,
        longMotionSampleGapCount: Int? = nil,
        totalGPSDistanceMeters: Double = 0
    ) {
        self.sampleCount = max(0, sampleCount)
        self.gpsSampleCount = max(0, gpsSampleCount)
        self.uniqueCoordinateCount = max(0, uniqueCoordinateCount)
        self.lowConfidenceSegmentCount = max(0, lowConfidenceSegmentCount)
        self.staleLocationSampleCount = max(0, staleLocationSampleCount)
        self.averageGPSUpdateIntervalSeconds = averageGPSUpdateIntervalSeconds
        self.maxGPSUpdateIntervalSeconds = maxGPSUpdateIntervalSeconds
        self.maxMotionSampleIntervalSeconds = maxMotionSampleIntervalSeconds
        self.longLocationUpdateGapCount = longLocationUpdateGapCount.map { max(0, $0) }
        self.longMotionSampleGapCount = longMotionSampleGapCount.map { max(0, $0) }
        self.totalGPSDistanceMeters = max(0, totalGPSDistanceMeters)
    }

    static func make(from samples: [MotionSample]) -> RouteQualitySummary {
        var uniqueCoordinates = Set<String>()
        var uniqueLocationFixKeys = Set<String>()
        var lowConfidenceSegmentCount = 0
        var staleLocationSampleCount = 0
        var updateIntervals: [TimeInterval] = []
        var motionSampleIntervals: [TimeInterval] = []
        var totalGPSDistanceMeters = 0.0
        var previousCoordinate: GeoCoordinate?
        var previousTimestamp: Date?
        var previousSampleTimestamp: Date?

        let sortedSamples = samples.sorted { lhs, rhs in
            Self.routeTimestamp(for: lhs) < Self.routeTimestamp(for: rhs)
        }

        for sample in sortedSamples {
            if let previousSampleTimestamp {
                let sampleInterval = max(sample.timestamp.timeIntervalSince(previousSampleTimestamp), 0)
                if sampleInterval > 0 {
                    motionSampleIntervals.append(sampleInterval)
                }
            }
            previousSampleTimestamp = sample.timestamp
            guard let coordinate = sample.gpsCoordinate else { continue }
            uniqueCoordinates.insert(Self.coordinateKey(for: coordinate))

            let locationFixKey = Self.locationFixKey(for: sample, coordinate: coordinate)
            let isNewLocationFix = uniqueLocationFixKeys.insert(locationFixKey).inserted
            guard isNewLocationFix else { continue }

            if let diagnostics = sample.locationDiagnostics {
                if diagnostics.freshnessState == .stale {
                    staleLocationSampleCount += 1
                }
                if diagnostics.routeSegmentConfidence == .low {
                    lowConfidenceSegmentCount += 1
                }
                if let interval = diagnostics.gpsUpdateIntervalSeconds, interval > 0 {
                    updateIntervals.append(interval)
                }
                if let distance = diagnostics.gpsSegmentDistanceMeters, distance > 0 {
                    if Self.isTrustedRouteDistanceSegment(diagnostics) {
                        totalGPSDistanceMeters += distance
                        previousCoordinate = coordinate
                        previousTimestamp = Self.routeTimestamp(for: sample)
                    } else {
                        previousCoordinate = nil
                        previousTimestamp = nil
                    }
                    continue
                }
            }

            guard let lastCoordinate = previousCoordinate else {
                previousCoordinate = coordinate
                previousTimestamp = Self.routeTimestamp(for: sample)
                continue
            }

            let segmentDistance = haversineDistanceMeters(from: lastCoordinate, to: coordinate)
            guard segmentDistance >= 0.5 else { continue }
            totalGPSDistanceMeters += segmentDistance

            if let previousTimestamp {
                let interval = max(Self.routeTimestamp(for: sample).timeIntervalSince(previousTimestamp), 0)
                if interval > 0 {
                    updateIntervals.append(interval)
                }
                if interval > 10 || segmentDistance > 100 {
                    lowConfidenceSegmentCount += 1
                }
            }

            previousCoordinate = coordinate
            previousTimestamp = Self.routeTimestamp(for: sample)
        }

        let averageInterval = updateIntervals.isEmpty ? nil : updateIntervals.reduce(0, +) / Double(updateIntervals.count)
        let longLocationUpdateGapCount = updateIntervals.filter { $0 > 10 }.count
        let longMotionSampleGapCount = motionSampleIntervals.filter { $0 > 5 }.count
        return RouteQualitySummary(
            sampleCount: samples.count,
            gpsSampleCount: samples.filter { $0.gpsCoordinate != nil }.count,
            uniqueCoordinateCount: uniqueCoordinates.count,
            lowConfidenceSegmentCount: lowConfidenceSegmentCount,
            staleLocationSampleCount: staleLocationSampleCount,
            averageGPSUpdateIntervalSeconds: averageInterval,
            maxGPSUpdateIntervalSeconds: updateIntervals.max(),
            maxMotionSampleIntervalSeconds: motionSampleIntervals.max(),
            longLocationUpdateGapCount: longLocationUpdateGapCount,
            longMotionSampleGapCount: longMotionSampleGapCount,
            totalGPSDistanceMeters: totalGPSDistanceMeters
        )
    }

    private static func isTrustedRouteDistanceSegment(_ diagnostics: LocationFixDiagnostics) -> Bool {
        guard diagnostics.routeSegmentConfidence != .low,
              diagnostics.routeSegmentConfidence != .unavailable else { return false }
        let policy = ActivityFidelityPolicy(profile: .standardSkateboard)
        let speedKmh = diagnostics.coordinateDerivedSpeedKmh ?? 0
        guard policy.acceptsLowSpeedMetricSample(
            speedKmh: speedKmh,
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            speedAccuracyMetersPerSecond: diagnostics.speedAccuracyMetersPerSecond,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters
        ) || speedKmh == 0 else { return false }
        return policy.trustsRouteSegment(
            horizontalAccuracyMeters: diagnostics.horizontalAccuracyMeters,
            freshnessState: diagnostics.freshnessState,
            updateIntervalSeconds: diagnostics.gpsUpdateIntervalSeconds,
            segmentDistanceMeters: diagnostics.gpsSegmentDistanceMeters,
            coordinateDerivedSpeedKmh: diagnostics.coordinateDerivedSpeedKmh
        )
    }

    private static func routeTimestamp(for sample: MotionSample) -> Date {
        sample.locationDiagnostics?.rawLocationTimestamp ?? sample.timestamp
    }

    private static func locationFixKey(for sample: MotionSample, coordinate: GeoCoordinate) -> String {
        if let rawTimestamp = sample.locationDiagnostics?.rawLocationTimestampMillisecondsSince1970 {
            return "\(rawTimestamp)-\(coordinateKey(for: coordinate))"
        }
        return "\(sample.timestampMillisecondsSince1970 ?? sample.timestamp.millisecondsSince1970)-\(coordinateKey(for: coordinate))"
    }

    private static func coordinateKey(for coordinate: GeoCoordinate) -> String {
        "\(coordinate.latitude.rounded(toPlaces: 7)),\(coordinate.longitude.rounded(toPlaces: 7))"
    }

    private static func haversineDistanceMeters(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let deltaLatitude = (end.latitude - start.latitude) * (.pi / 180)
        let deltaLongitude = (end.longitude - start.longitude) * (.pi / 180)
        let startLatitude = start.latitude * (.pi / 180)
        let endLatitude = end.latitude * (.pi / 180)
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusMeters * centralAngle
    }
}

struct MotionSample: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let timestampMillisecondsSince1970: Int64?
    let gpsCoordinate: GeoCoordinate?
    let speedKmh: Double
    let accelerometerG: ThreeAxisValue
    let gyroscopeRadPS: ThreeAxisValue
    let altitudeMeters: Double?
    let altitudeSource: AltitudeSampleSource?
    let altitudeDiagnostics: AltitudeDiagnostics?
    let locationDiagnostics: LocationFixDiagnostics?
    let sampleSource: MotionSampleSource?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        timestampMillisecondsSince1970: Int64? = nil,
        gpsCoordinate: GeoCoordinate? = nil,
        speedKmh: Double,
        accelerometerG: ThreeAxisValue,
        gyroscopeRadPS: ThreeAxisValue,
        altitudeMeters: Double? = nil,
        altitudeSource: AltitudeSampleSource? = nil,
        altitudeDiagnostics: AltitudeDiagnostics? = nil,
        locationDiagnostics: LocationFixDiagnostics? = nil,
        sampleSource: MotionSampleSource? = .timerFusion
    ) {
        self.id = id
        self.timestamp = timestamp
        self.timestampMillisecondsSince1970 = timestampMillisecondsSince1970 ?? timestamp.millisecondsSince1970
        self.gpsCoordinate = gpsCoordinate
        self.speedKmh = speedKmh
        self.accelerometerG = accelerometerG
        self.gyroscopeRadPS = gyroscopeRadPS
        self.altitudeMeters = altitudeMeters
        self.altitudeSource = altitudeSource
        self.altitudeDiagnostics = altitudeDiagnostics
        self.locationDiagnostics = locationDiagnostics
        self.sampleSource = sampleSource
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1_000).rounded())
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
