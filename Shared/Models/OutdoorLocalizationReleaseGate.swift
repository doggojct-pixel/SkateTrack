// [協作區] Shared/Models/OutdoorLocalizationReleaseGate.swift
// 用途：定義 b19 outdoor localization release gate 的保守產品釋出判斷模型。
// 委派至：OutdoorLocalizationReleaseGateBuilder 與 b19 release gate 文件。

import Foundation

enum OutdoorLocalizationReleaseDecision: String, Codable, Sendable, Equatable, CaseIterable {
    case releaseReady
    case limitedDisclosure
    case blocked
}

enum OutdoorLocalizationReleaseBlockingReason: String, Codable, Sendable, Equatable, CaseIterable {
    case insufficientTrustedGPSCoverage
    case excessiveStartupWarmupDrift
    case excessiveGPSGapDuration
    case excessiveHorizontalAccuracy
    case lowSpeedLocalizationTrap
    case headingQualityInsufficient
    case altitudeQualityInsufficient
    case estimatedRouteDisplayDisabledByProductDecision
}

struct OutdoorLocalizationReleasePolicy: Codable, Sendable, Equatable {
    let minimumTrustedGPSCoverageRatio: Double
    let maximumAllowedStartupWarmupSeconds: TimeInterval
    let maximumAllowedGPSGapSeconds: TimeInterval
    let maximumAllowedHorizontalAccuracyMeters: Double
    let maximumLimitedDisclosureHorizontalAccuracyMeters: Double
    let maximumLowSpeedTrapDurationSeconds: TimeInterval
    let altitudeQualityRequiredForElevationClaims: Bool

    init(
        minimumTrustedGPSCoverageRatio: Double = 0.80,
        maximumAllowedStartupWarmupSeconds: TimeInterval = 30,
        maximumAllowedGPSGapSeconds: TimeInterval = 10,
        maximumAllowedHorizontalAccuracyMeters: Double = 25,
        maximumLimitedDisclosureHorizontalAccuracyMeters: Double = 65,
        maximumLowSpeedTrapDurationSeconds: TimeInterval = 20,
        altitudeQualityRequiredForElevationClaims: Bool = true
    ) {
        self.minimumTrustedGPSCoverageRatio = max(0, min(1, minimumTrustedGPSCoverageRatio))
        self.maximumAllowedStartupWarmupSeconds = max(0, maximumAllowedStartupWarmupSeconds)
        self.maximumAllowedGPSGapSeconds = max(0, maximumAllowedGPSGapSeconds)
        self.maximumAllowedHorizontalAccuracyMeters = max(0, maximumAllowedHorizontalAccuracyMeters)
        self.maximumLimitedDisclosureHorizontalAccuracyMeters = max(
            self.maximumAllowedHorizontalAccuracyMeters,
            maximumLimitedDisclosureHorizontalAccuracyMeters
        )
        self.maximumLowSpeedTrapDurationSeconds = max(0, maximumLowSpeedTrapDurationSeconds)
        self.altitudeQualityRequiredForElevationClaims = altitudeQualityRequiredForElevationClaims
    }
}

struct OutdoorLocalizationReleaseEvidence: Codable, Sendable, Equatable {
    let sessionReviewRole: String
    let trustedGPSCoverageRatio: Double
    let startupWarmupSeconds: TimeInterval
    let longestGPSGapSeconds: TimeInterval
    let horizontalAccuracyP95Meters: Double
    let lowSpeedTrapDurationSeconds: TimeInterval
    let headingReliable: Bool
    let altitudeReliable: Bool
    let shelteredOrHighRiskEnvironment: Bool

    init(
        sessionReviewRole: String,
        trustedGPSCoverageRatio: Double,
        startupWarmupSeconds: TimeInterval,
        longestGPSGapSeconds: TimeInterval,
        horizontalAccuracyP95Meters: Double,
        lowSpeedTrapDurationSeconds: TimeInterval,
        headingReliable: Bool,
        altitudeReliable: Bool,
        shelteredOrHighRiskEnvironment: Bool = false
    ) {
        self.sessionReviewRole = sessionReviewRole
        self.trustedGPSCoverageRatio = max(0, min(1, trustedGPSCoverageRatio))
        self.startupWarmupSeconds = max(0, startupWarmupSeconds)
        self.longestGPSGapSeconds = max(0, longestGPSGapSeconds)
        self.horizontalAccuracyP95Meters = max(0, horizontalAccuracyP95Meters)
        self.lowSpeedTrapDurationSeconds = max(0, lowSpeedTrapDurationSeconds)
        self.headingReliable = headingReliable
        self.altitudeReliable = altitudeReliable
        self.shelteredOrHighRiskEnvironment = shelteredOrHighRiskEnvironment
    }
}

struct OutdoorLocalizationReleaseGate: Codable, Sendable, Equatable {
    let taskIdentifier: String
    let decision: OutdoorLocalizationReleaseDecision
    let blockingReasons: [OutdoorLocalizationReleaseBlockingReason]
    let disclosureReasons: [String]
    let reviewedOutdoorSessionCount: Int
    let policy: OutdoorLocalizationReleasePolicy
    let realGPSOnly: Bool
    let generalUserEstimatedRouteDisplayAllowed: Bool
    let estimatedRouteDisplayEnabled: Bool
    let estimatedRouteActive: Bool
    let routeGeometryMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let persistenceSchemaMutationApplied: Bool

    init(
        taskIdentifier: String = "Task-030c-b19",
        decision: OutdoorLocalizationReleaseDecision,
        blockingReasons: [OutdoorLocalizationReleaseBlockingReason],
        disclosureReasons: [String],
        reviewedOutdoorSessionCount: Int,
        policy: OutdoorLocalizationReleasePolicy
    ) {
        self.taskIdentifier = taskIdentifier
        self.decision = decision
        self.blockingReasons = blockingReasons
        self.disclosureReasons = disclosureReasons
        self.reviewedOutdoorSessionCount = max(0, reviewedOutdoorSessionCount)
        self.policy = policy
        self.realGPSOnly = true
        self.generalUserEstimatedRouteDisplayAllowed = false
        self.estimatedRouteDisplayEnabled = false
        self.estimatedRouteActive = false
        self.routeGeometryMutationApplied = false
        self.trustedMetricsMutationApplied = false
        self.persistenceSchemaMutationApplied = false
    }
}
