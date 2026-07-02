// [自主區] iOS/Core/SensorEngine/DeadReckoningEngine.swift
// 用途：提供 b17-B replay-only IMU gap interpolation candidate engine。
// 委派至：b17-C closure scoring、b17-D real-session replay review pack。

import Foundation

struct DeadReckoningReplayConfig: Sendable, Equatable {
    let maximumReplayGapSeconds: TimeInterval
    let minimumIMUSampleCount: Int
    let defaultAnchorHorizontalAccuracyMeters: Double

    init(
        maximumReplayGapSeconds: TimeInterval = 30,
        minimumIMUSampleCount: Int = 2,
        defaultAnchorHorizontalAccuracyMeters: Double = 8
    ) {
        self.maximumReplayGapSeconds = max(0, maximumReplayGapSeconds)
        self.minimumIMUSampleCount = max(1, minimumIMUSampleCount)
        self.defaultAnchorHorizontalAccuracyMeters = max(0, defaultAnchorHorizontalAccuracyMeters)
    }

    static let conservativeReplayOnly = DeadReckoningReplayConfig()
}

enum DeadReckoningEngine {
    // Conservative initial value based on walking/skating IMU integration analysis.
    // This value must be revisited after b17-D real-session closure data is available.
    private static let estimatedPositionDriftRateMetersPerSecond: Double = 0.5

    static func estimateGap(
        preGapAnchor: MotionSample,
        postGapAnchor: MotionSample,
        timerFusionSamples: [MotionSample],
        biasEstimate: IMUBiasEstimate? = nil,
        config: DeadReckoningReplayConfig = .conservativeReplayOnly
    ) -> DeadReckoningReplayDiagnostics {
        let gapDurationSeconds = max(0, postGapAnchor.timestamp.timeIntervalSince(preGapAnchor.timestamp))
        guard let preCoordinate = preGapAnchor.gpsCoordinate else {
            return blockedDiagnostics(
                preGapAnchor: preGapAnchor,
                postGapAnchor: postGapAnchor,
                gapDurationSeconds: gapDurationSeconds,
                reason: .missingPreGapAnchor
            )
        }
        guard let postCoordinate = postGapAnchor.gpsCoordinate else {
            return blockedDiagnostics(
                preGapAnchor: preGapAnchor,
                postGapAnchor: postGapAnchor,
                gapDurationSeconds: gapDurationSeconds,
                reason: .missingPostGapAnchor
            )
        }
        guard gapDurationSeconds <= config.maximumReplayGapSeconds else {
            return blockedDiagnostics(
                preGapAnchor: preGapAnchor,
                postGapAnchor: postGapAnchor,
                gapDurationSeconds: gapDurationSeconds,
                reason: .gapTooLong,
                preCoordinate: preCoordinate,
                postCoordinate: postCoordinate
            )
        }

        let gapSamples = timerFusionSamples
            .filter { sample in
                sample.sampleSource == .timerFusion &&
                sample.timestamp > preGapAnchor.timestamp &&
                sample.timestamp < postGapAnchor.timestamp
            }
            .sorted { lhs, rhs in lhs.timestamp < rhs.timestamp }
        guard gapSamples.count >= config.minimumIMUSampleCount else {
            return blockedDiagnostics(
                preGapAnchor: preGapAnchor,
                postGapAnchor: postGapAnchor,
                gapDurationSeconds: gapDurationSeconds,
                reason: .insufficientIMUSamples,
                preCoordinate: preCoordinate,
                postCoordinate: postCoordinate
            )
        }

        let plane = LocalTangentPlane(anchorCoordinate: preCoordinate)
        let anchorAccuracy = preGapAnchor.locationDiagnostics?.horizontalAccuracyMeters
            ?? config.defaultAnchorHorizontalAccuracyMeters
        let accelerometerBiasG = biasEstimate?.accelerometerBiasG
            ?? IMUBiasEstimator.estimateAccelerometerBias(from: gapSamples)?.accelerometerBiasG
            ?? .zero
        let headingAssessment = selectedHeadingAssessment(preGapAnchor: preGapAnchor, gapSamples: gapSamples)
        var velocity = initialVelocityMetersPerSecond(
            speedKmh: preGapAnchor.speedKmh,
            headingDegrees: headingAssessment.selectedHeadingDegrees
                ?? fallbackBearingDegrees(from: preCoordinate, to: postCoordinate)
        )
        var localPosition = LocalTangentMeters(eastMeters: 0, northMeters: 0)
        var previousTimestamp = preGapAnchor.timestamp
        let source: DeadReckoningEstimateSource = headingAssessment.replayReadinessEligible
            ? .replayOnlyIMU
            : .replayOnlyIMUHeadingUnavailable
        let confidence = confidence(for: headingAssessment)

        var estimates: [DeadReckoningReplayEstimate] = []
        for sample in gapSamples {
            let deltaTimeSeconds = max(0, sample.timestamp.timeIntervalSince(previousTimestamp))
            previousTimestamp = sample.timestamp
            let compensatedSample = GravityCompensatedMotionSample(
                sample: sample,
                accelerometerBiasG: accelerometerBiasG
            )
            velocity = LocalTangentMeters(
                eastMeters: velocity.eastMeters + compensatedSample.accelerationMetersPerSecondSquared.x * deltaTimeSeconds,
                northMeters: velocity.northMeters + compensatedSample.accelerationMetersPerSecondSquared.y * deltaTimeSeconds
            )
            localPosition = LocalTangentMeters(
                eastMeters: localPosition.eastMeters + velocity.eastMeters * deltaTimeSeconds,
                northMeters: localPosition.northMeters + velocity.northMeters * deltaTimeSeconds
            )
            guard localPosition.eastMeters.isFinite,
                  localPosition.northMeters.isFinite else {
                return blockedDiagnostics(
                    preGapAnchor: preGapAnchor,
                    postGapAnchor: postGapAnchor,
                    gapDurationSeconds: gapDurationSeconds,
                    reason: .nonFiniteEstimate,
                    preCoordinate: preCoordinate,
                    postCoordinate: postCoordinate
                )
            }
            let elapsedSeconds = max(0, sample.timestamp.timeIntervalSince(preGapAnchor.timestamp))
            let estimatedAccuracy = anchorAccuracy + (elapsedSeconds * estimatedPositionDriftRateMetersPerSecond)
            estimates.append(
                DeadReckoningReplayEstimate(
                    timestamp: sample.timestamp,
                    localEastMeters: localPosition.eastMeters,
                    localNorthMeters: localPosition.northMeters,
                    estimatedCoordinate: plane.coordinate(for: localPosition),
                    estimatedHorizontalAccuracyMeters: estimatedAccuracy,
                    source: source,
                    confidence: confidence
                )
            )
        }

        let closureError = closureErrorMeters(
            estimates: estimates,
            postCoordinate: postCoordinate,
            plane: plane
        )
        return DeadReckoningReplayDiagnostics(
            gapStartTimestamp: preGapAnchor.timestamp,
            gapEndTimestamp: postGapAnchor.timestamp,
            gapDurationSeconds: gapDurationSeconds,
            blockingReason: .noBlockingReason,
            preGapAnchorCoordinate: preCoordinate,
            postGapAnchorCoordinate: postCoordinate,
            anchorClosureErrorMeters: closureError,
            estimates: estimates
        )
    }

    private static func blockedDiagnostics(
        preGapAnchor: MotionSample,
        postGapAnchor: MotionSample,
        gapDurationSeconds: TimeInterval,
        reason: DeadReckoningReplayBlockingReason,
        preCoordinate: GeoCoordinate? = nil,
        postCoordinate: GeoCoordinate? = nil
    ) -> DeadReckoningReplayDiagnostics {
        DeadReckoningReplayDiagnostics(
            gapStartTimestamp: preGapAnchor.timestamp,
            gapEndTimestamp: postGapAnchor.timestamp,
            gapDurationSeconds: gapDurationSeconds,
            blockingReason: reason,
            preGapAnchorCoordinate: preCoordinate,
            postGapAnchorCoordinate: postCoordinate,
            anchorClosureErrorMeters: nil,
            estimates: []
        )
    }

    private static func selectedHeadingAssessment(
        preGapAnchor: MotionSample,
        gapSamples: [MotionSample]
    ) -> HeadingQualityAssessment {
        let diagnostics = ([preGapAnchor] + gapSamples)
            .compactMap { $0.locationDiagnostics?.headingDiagnostics }
            .first
        return HeadingQualityClassifier.classify(diagnostics)
    }

    private static func initialVelocityMetersPerSecond(
        speedKmh: Double,
        headingDegrees: Double?
    ) -> LocalTangentMeters {
        let speedMetersPerSecond = max(0, speedKmh) / 3.6
        guard let headingDegrees else {
            return LocalTangentMeters(eastMeters: 0, northMeters: 0)
        }
        let headingRadians = headingDegrees * .pi / 180
        return LocalTangentMeters(
            eastMeters: sin(headingRadians) * speedMetersPerSecond,
            northMeters: cos(headingRadians) * speedMetersPerSecond
        )
    }

    private static func confidence(for assessment: HeadingQualityAssessment) -> DeadReckoningConfidence {
        guard assessment.replayReadinessEligible else { return .low }
        switch assessment.reliability {
        case .high:
            return .high
        case .moderate:
            return .moderate
        case .poor, .invalid, .tooOld, .unavailable:
            return .low
        }
    }

    private static func fallbackBearingDegrees(from start: GeoCoordinate, to end: GeoCoordinate) -> Double {
        let startLatitude = start.latitude * .pi / 180
        let endLatitude = end.latitude * .pi / 180
        let deltaLongitude = (end.longitude - start.longitude) * .pi / 180
        let y = sin(deltaLongitude) * cos(endLatitude)
        let x = cos(startLatitude) * sin(endLatitude)
            - sin(startLatitude) * cos(endLatitude) * cos(deltaLongitude)
        let degrees = atan2(y, x) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }

    private static func closureErrorMeters(
        estimates: [DeadReckoningReplayEstimate],
        postCoordinate: GeoCoordinate,
        plane: LocalTangentPlane
    ) -> Double? {
        guard let finalEstimate = estimates.last else { return nil }
        let postLocal = plane.localMeters(for: postCoordinate)
        let eastDelta = postLocal.eastMeters - finalEstimate.localEastMeters
        let northDelta = postLocal.northMeters - finalEstimate.localNorthMeters
        return sqrt((eastDelta * eastDelta) + (northDelta * northDelta))
    }
}
