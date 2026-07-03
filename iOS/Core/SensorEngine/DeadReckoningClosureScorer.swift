// [自主區] iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift
// 用途：提供 b17-C replay-only IMU anchor-closure error 與 user-visible eligibility scoring。
// 委派至：DeadReckoningEngine、b17-D real-session replay review pack 與 b18 display safety gate。

import Foundation

struct DeadReckoningClosureScoringPolicy: Sendable, Equatable {
    let shortGapEligibilitySeconds: TimeInterval
    let maximumOutdoorUserVisibleGapSeconds: TimeInterval
    let possibleClosureErrorAbsoluteMeters: Double
    let possibleClosureErrorDistanceRatio: Double
    let blockingClosureErrorAbsoluteMeters: Double
    let blockingClosureErrorDistanceRatio: Double
    let longGapLowClosureAbsoluteMeters: Double
    let longGapLowClosureDistanceRatio: Double
    let minimumIMUSampleCoverageRatio: Double

    init(
        shortGapEligibilitySeconds: TimeInterval = 30,
        maximumOutdoorUserVisibleGapSeconds: TimeInterval = 60,
        possibleClosureErrorAbsoluteMeters: Double = 8,
        possibleClosureErrorDistanceRatio: Double = 0.25,
        blockingClosureErrorAbsoluteMeters: Double = 15,
        blockingClosureErrorDistanceRatio: Double = 0.5,
        longGapLowClosureAbsoluteMeters: Double = 5,
        longGapLowClosureDistanceRatio: Double = 0.1,
        minimumIMUSampleCoverageRatio: Double = 0.7
    ) {
        self.shortGapEligibilitySeconds = max(0, shortGapEligibilitySeconds)
        self.maximumOutdoorUserVisibleGapSeconds = max(
            self.shortGapEligibilitySeconds,
            maximumOutdoorUserVisibleGapSeconds
        )
        self.possibleClosureErrorAbsoluteMeters = max(0, possibleClosureErrorAbsoluteMeters)
        self.possibleClosureErrorDistanceRatio = max(0, possibleClosureErrorDistanceRatio)
        self.blockingClosureErrorAbsoluteMeters = max(
            self.possibleClosureErrorAbsoluteMeters,
            blockingClosureErrorAbsoluteMeters
        )
        self.blockingClosureErrorDistanceRatio = max(
            self.possibleClosureErrorDistanceRatio,
            blockingClosureErrorDistanceRatio
        )
        self.longGapLowClosureAbsoluteMeters = max(0, longGapLowClosureAbsoluteMeters)
        self.longGapLowClosureDistanceRatio = max(0, longGapLowClosureDistanceRatio)
        self.minimumIMUSampleCoverageRatio = min(1, max(0, minimumIMUSampleCoverageRatio))
    }

    static let conservativeOutdoorReplay = DeadReckoningClosureScoringPolicy()
}

enum DeadReckoningClosureScorer {
    static func score(
        replayDiagnostics: DeadReckoningReplayDiagnostics,
        headingReliability: HeadingReliability,
        imuSampleCoverageRatio: Double,
        policy: DeadReckoningClosureScoringPolicy = .conservativeOutdoorReplay
    ) -> DeadReckoningClosureDiagnostics? {
        guard let closureErrorMeters = replayDiagnostics.anchorClosureErrorMeters,
              !replayDiagnostics.estimates.isEmpty else {
            return nil
        }

        let estimatedDistanceMeters = pathDistanceMeters(for: replayDiagnostics.estimates)
        return score(
            gapDurationSeconds: replayDiagnostics.gapDurationSeconds,
            estimatedDistanceMeters: estimatedDistanceMeters,
            closureErrorMeters: closureErrorMeters,
            headingReliability: headingReliability,
            imuSampleCoverageRatio: imuSampleCoverageRatio,
            policy: policy
        )
    }

    static func score(
        gapDurationSeconds: TimeInterval,
        estimatedDistanceMeters: Double,
        closureErrorMeters: Double,
        headingReliability: HeadingReliability,
        imuSampleCoverageRatio: Double,
        policy: DeadReckoningClosureScoringPolicy = .conservativeOutdoorReplay
    ) -> DeadReckoningClosureDiagnostics {
        let sanitizedGapDurationSeconds = max(0, gapDurationSeconds)
        let sanitizedEstimatedDistanceMeters = max(0, estimatedDistanceMeters)
        let sanitizedClosureErrorMeters = max(0, closureErrorMeters)
        let sanitizedCoverageRatio = min(1, max(0, imuSampleCoverageRatio))
        let ratioDenominator = max(sanitizedEstimatedDistanceMeters, 1)
        let closureErrorRatio = sanitizedClosureErrorMeters / ratioDenominator
        var blockingReasons: [String] = []

        if sanitizedGapDurationSeconds > policy.maximumOutdoorUserVisibleGapSeconds {
            blockingReasons.append("gapDurationExceededOutdoorLimit")
        } else if sanitizedGapDurationSeconds > policy.shortGapEligibilitySeconds {
            let longGapLowClosureThreshold = max(
                policy.longGapLowClosureAbsoluteMeters,
                policy.longGapLowClosureDistanceRatio * sanitizedEstimatedDistanceMeters
            )
            if sanitizedClosureErrorMeters > longGapLowClosureThreshold {
                blockingReasons.append("longGapRequiresVeryLowClosureError")
            }
        }

        let possibleThreshold = max(
            policy.possibleClosureErrorAbsoluteMeters,
            policy.possibleClosureErrorDistanceRatio * sanitizedEstimatedDistanceMeters
        )
        let blockingThreshold = max(
            policy.blockingClosureErrorAbsoluteMeters,
            policy.blockingClosureErrorDistanceRatio * sanitizedEstimatedDistanceMeters
        )
        if sanitizedClosureErrorMeters > blockingThreshold {
            blockingReasons.append("closureErrorExceededBlockingThreshold")
        } else if sanitizedClosureErrorMeters > possibleThreshold {
            blockingReasons.append("closureErrorExceededEligibilityThreshold")
        }

        if !isHeadingReliableForUserVisibleRoute(headingReliability) {
            blockingReasons.append("headingReliabilityInsufficient")
        }

        if sanitizedCoverageRatio < policy.minimumIMUSampleCoverageRatio {
            blockingReasons.append("imuSampleCoverageInsufficient")
        }

        return DeadReckoningClosureDiagnostics(
            gapDurationSeconds: sanitizedGapDurationSeconds,
            estimatedDistanceMeters: sanitizedEstimatedDistanceMeters,
            closureErrorMeters: sanitizedClosureErrorMeters,
            closureErrorRatio: closureErrorRatio,
            headingReliability: headingReliability,
            imuSampleCoverageRatio: sanitizedCoverageRatio,
            eligibleForUserVisibleEstimatedRoute: blockingReasons.isEmpty,
            blockingReasons: blockingReasons
        )
    }

    private static func isHeadingReliableForUserVisibleRoute(_ reliability: HeadingReliability) -> Bool {
        switch reliability {
        case .high, .moderate:
            return true
        case .poor, .invalid, .tooOld, .unavailable:
            return false
        }
    }

    private static func pathDistanceMeters(for estimates: [DeadReckoningReplayEstimate]) -> Double {
        guard !estimates.isEmpty else { return 0 }
        var totalDistanceMeters = 0.0
        var previousEastMeters = 0.0
        var previousNorthMeters = 0.0
        for estimate in estimates {
            let eastDelta = estimate.localEastMeters - previousEastMeters
            let northDelta = estimate.localNorthMeters - previousNorthMeters
            totalDistanceMeters += sqrt((eastDelta * eastDelta) + (northDelta * northDelta))
            previousEastMeters = estimate.localEastMeters
            previousNorthMeters = estimate.localNorthMeters
        }
        return totalDistanceMeters
    }
}
