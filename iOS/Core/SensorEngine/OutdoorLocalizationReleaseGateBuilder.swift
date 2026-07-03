// [自主區] iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift
// 用途：依據 real-GPS localization evidence 產出 b19 outdoor localization release gate 判斷。
// 委派至：OutdoorLocalizationReleaseGate 與 b19 release gate 文件。

import Foundation

enum OutdoorLocalizationReleaseGateBuilder {
    static let conservativePolicy = OutdoorLocalizationReleasePolicy(
        minimumTrustedGPSCoverageRatio: 0.80,
        maximumAllowedStartupWarmupSeconds: 30,
        maximumAllowedGPSGapSeconds: 10,
        maximumAllowedHorizontalAccuracyMeters: 25,
        maximumLimitedDisclosureHorizontalAccuracyMeters: 65,
        maximumLowSpeedTrapDurationSeconds: 20,
        altitudeQualityRequiredForElevationClaims: true
    )

    static func makeGate(
        from evidence: [OutdoorLocalizationReleaseEvidence],
        policy: OutdoorLocalizationReleasePolicy = conservativePolicy
    ) -> OutdoorLocalizationReleaseGate {
        guard !evidence.isEmpty else {
            return OutdoorLocalizationReleaseGate(
                decision: .blocked,
                blockingReasons: [.insufficientTrustedGPSCoverage, .estimatedRouteDisplayDisabledByProductDecision],
                disclosureReasons: ["noOutdoorLocalizationEvidence", "estimatedRouteDisplayDisabledByB18D"],
                reviewedOutdoorSessionCount: 0,
                policy: policy
            )
        }

        let reasons = blockingReasons(for: evidence, policy: policy)
        let disclosureReasons = disclosureReasons(for: evidence, policy: policy, blockingReasons: reasons)
        let decision = releaseDecision(for: reasons, disclosureReasons: disclosureReasons)

        return OutdoorLocalizationReleaseGate(
            decision: decision,
            blockingReasons: reasons,
            disclosureReasons: disclosureReasons,
            reviewedOutdoorSessionCount: evidence.count,
            policy: policy
        )
    }

    private static func blockingReasons(
        for evidence: [OutdoorLocalizationReleaseEvidence],
        policy: OutdoorLocalizationReleasePolicy
    ) -> [OutdoorLocalizationReleaseBlockingReason] {
        var reasons: Set<OutdoorLocalizationReleaseBlockingReason> = [.estimatedRouteDisplayDisabledByProductDecision]

        if evidence.contains(where: { $0.trustedGPSCoverageRatio < policy.minimumTrustedGPSCoverageRatio }) {
            reasons.insert(.insufficientTrustedGPSCoverage)
        }
        if evidence.contains(where: { $0.startupWarmupSeconds > policy.maximumAllowedStartupWarmupSeconds }) {
            reasons.insert(.excessiveStartupWarmupDrift)
        }
        if evidence.contains(where: { $0.longestGPSGapSeconds > policy.maximumAllowedGPSGapSeconds }) {
            reasons.insert(.excessiveGPSGapDuration)
        }
        if evidence.contains(where: { $0.horizontalAccuracyP95Meters > policy.maximumLimitedDisclosureHorizontalAccuracyMeters }) {
            reasons.insert(.excessiveHorizontalAccuracy)
        }
        if evidence.contains(where: { $0.lowSpeedTrapDurationSeconds > policy.maximumLowSpeedTrapDurationSeconds }) {
            reasons.insert(.lowSpeedLocalizationTrap)
        }
        if evidence.contains(where: { !$0.headingReliable }) {
            reasons.insert(.headingQualityInsufficient)
        }
        if policy.altitudeQualityRequiredForElevationClaims && evidence.contains(where: { !$0.altitudeReliable }) {
            reasons.insert(.altitudeQualityInsufficient)
        }

        return reasons.sorted { $0.rawValue < $1.rawValue }
    }

    private static func disclosureReasons(
        for evidence: [OutdoorLocalizationReleaseEvidence],
        policy: OutdoorLocalizationReleasePolicy,
        blockingReasons: [OutdoorLocalizationReleaseBlockingReason]
    ) -> [String] {
        var reasons = ["realGPSOnlyReleaseGate", "estimatedRouteDisplayRemainsDisabled"]

        if evidence.contains(where: { $0.shelteredOrHighRiskEnvironment }) {
            reasons.append("shelteredOrHighRiskEnvironment")
        }
        if evidence.contains(where: { $0.horizontalAccuracyP95Meters > policy.maximumAllowedHorizontalAccuracyMeters }) {
            reasons.append("horizontalAccuracyRequiresDisclosure")
        }
        if evidence.contains(where: { $0.startupWarmupSeconds > 0 }) {
            reasons.append("startupWarmupRequiresDisclosure")
        }
        if blockingReasons.contains(.lowSpeedLocalizationTrap) {
            reasons.append("lowSpeedLocalizationTrapRequiresDisclosure")
        }

        return Array(Set(reasons)).sorted()
    }

    private static func releaseDecision(
        for blockingReasons: [OutdoorLocalizationReleaseBlockingReason],
        disclosureReasons: [String]
    ) -> OutdoorLocalizationReleaseDecision {
        let productOnlyReasons: Set<OutdoorLocalizationReleaseBlockingReason> = [.estimatedRouteDisplayDisabledByProductDecision]
        let nonProductReasons = blockingReasons.filter { !productOnlyReasons.contains($0) }

        if !nonProductReasons.isEmpty {
            return .blocked
        }

        let qualityDisclosureReasons: Set<String> = [
            "horizontalAccuracyRequiresDisclosure",
            "lowSpeedLocalizationTrapRequiresDisclosure",
            "shelteredOrHighRiskEnvironment",
            "startupWarmupRequiresDisclosure"
        ]
        if disclosureReasons.contains(where: { qualityDisclosureReasons.contains($0) }) {
            return .limitedDisclosure
        }
        return .releaseReady
    }
}
