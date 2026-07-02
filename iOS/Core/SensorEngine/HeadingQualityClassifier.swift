// [自主區] iOS/Core/SensorEngine/HeadingQualityClassifier.swift
// 用途：將既有 HeadingDiagnostics 整理成 replay-only heading reliability 分級。
// 委派至：HeadingQualityDiagnostics 與未來 replay-only IMU interpolation。

import Foundation

enum HeadingQualityClassifier {
    static func classify(
        _ diagnostics: HeadingDiagnostics?,
        config: HeadingQualityConfig = .replayReadiness
    ) -> HeadingQualityAssessment {
        guard let diagnostics, diagnostics.headingAvailable else {
            return HeadingQualityAssessment(reliability: .unavailable)
        }

        let candidate = selectedHeadingCandidate(from: diagnostics)
        guard candidate.degrees != nil else {
            return HeadingQualityAssessment(
                reliability: .unavailable,
                courseDeviceHeadingAgreement: diagnostics.courseDeviceHeadingAgreement,
                source: diagnostics.source
            )
        }

        if candidate.accuracyDegrees.map({ $0 < 0 }) == true {
            return HeadingQualityAssessment(
                reliability: .invalid,
                replayReadinessEligible: false,
                selectedHeadingDegrees: candidate.degrees,
                selectedHeadingAccuracyDegrees: candidate.accuracyDegrees,
                selectedHeadingAgeSeconds: candidate.ageSeconds,
                courseDeviceHeadingAgreement: diagnostics.courseDeviceHeadingAgreement,
                source: diagnostics.source
            )
        }

        if candidate.ageSeconds.map({ $0 > config.maxReplayReadinessAgeSeconds }) == true {
            return HeadingQualityAssessment(
                reliability: .tooOld,
                replayReadinessEligible: false,
                selectedHeadingDegrees: candidate.degrees,
                selectedHeadingAccuracyDegrees: candidate.accuracyDegrees,
                selectedHeadingAgeSeconds: candidate.ageSeconds,
                courseDeviceHeadingAgreement: diagnostics.courseDeviceHeadingAgreement,
                source: diagnostics.source
            )
        }

        let reliability = reliabilityForAccuracy(candidate.accuracyDegrees, config: config)
        let agreementAcceptable = diagnostics.courseDeviceHeadingAgreement != false
        let replayReadinessEligible = agreementAcceptable
            && (reliability == .high || reliability == .moderate)
            && diagnostics.hasReliableHeadingForRouteContinuity

        return HeadingQualityAssessment(
            reliability: reliability,
            replayReadinessEligible: replayReadinessEligible,
            selectedHeadingDegrees: candidate.degrees,
            selectedHeadingAccuracyDegrees: candidate.accuracyDegrees,
            selectedHeadingAgeSeconds: candidate.ageSeconds,
            courseDeviceHeadingAgreement: diagnostics.courseDeviceHeadingAgreement,
            source: diagnostics.source
        )
    }

    private static func selectedHeadingCandidate(
        from diagnostics: HeadingDiagnostics
    ) -> (degrees: Double?, accuracyDegrees: Double?, ageSeconds: TimeInterval?) {
        if diagnostics.deviceHeadingDegrees != nil {
            return (
                diagnostics.deviceHeadingDegrees,
                diagnostics.deviceHeadingAccuracyDegrees,
                diagnostics.deviceHeadingAgeSeconds
            )
        }
        return (
            diagnostics.courseOverGroundDegrees,
            diagnostics.courseAccuracyDegrees,
            nil
        )
    }

    private static func reliabilityForAccuracy(
        _ accuracyDegrees: Double?,
        config: HeadingQualityConfig
    ) -> HeadingReliability {
        guard let accuracyDegrees else { return .poor }
        if accuracyDegrees <= config.highAccuracyThresholdDegrees { return .high }
        if accuracyDegrees <= config.moderateAccuracyThresholdDegrees { return .moderate }
        return .poor
    }
}
