// [自主區] iOS/Core/SensorEngine/LocalizationDiagnosticsReviewBuilder.swift
// 用途：將 b16-A～D 診斷彙整成 replay-only review pack。
// 委派至：LocalizationDiagnosticsReviewPack 與未來 b17 review/export workflow。

import Foundation

enum LocalizationDiagnosticsReviewBuilder {
    static func makeReviewPack(
        samples: [MotionSample],
        createdAt: Date = Date(),
        headingQualityConfig: HeadingQualityConfig = .replayReadiness
    ) -> LocalizationDiagnosticsReviewPack {
        let reviewSamples = samples.map { sample in
            makeReviewSample(from: sample, headingQualityConfig: headingQualityConfig)
        }
        let summary = makeSummary(totalSampleCount: samples.count, reviewSamples: reviewSamples)
        return LocalizationDiagnosticsReviewPack(
            createdAt: createdAt,
            summary: summary,
            samples: reviewSamples
        )
    }

    private static func makeReviewSample(
        from sample: MotionSample,
        headingQualityConfig: HeadingQualityConfig
    ) -> LocalizationDiagnosticsReviewSample {
        let diagnostics = sample.locationDiagnostics
        let headingAssessment = HeadingQualityClassifier.classify(
            diagnostics?.headingDiagnostics,
            config: headingQualityConfig
        )
        return LocalizationDiagnosticsReviewSample(
            sampleID: sample.id,
            timestamp: sample.timestamp,
            timestampMillisecondsSince1970: sample.timestampMillisecondsSince1970,
            routeSegmentConfidence: diagnostics?.routeSegmentConfidence ?? .unavailable,
            freshnessState: diagnostics?.freshnessState ?? .unavailable,
            barometricOutlierWouldRejectIfEnabled: diagnostics?.barometricGPSOutlierDecision?.wouldRejectIfGateWereEnabled ?? false,
            accuracySourceClass: diagnostics?.locationAccuracySourceDiagnostics?.sourceClass,
            headingReliability: headingAssessment.reliability,
            headingReplayReadinessEligible: headingAssessment.replayReadinessEligible,
            estimatedRouteActive: diagnostics?.deadReckoningDiagnostics?.estimatedRouteActive ?? false,
            productionRouteDecisionApplied: diagnostics?.barometricGPSOutlierDecision?.productionRouteDecisionApplied ?? false
        )
    }

    private static func makeSummary(
        totalSampleCount: Int,
        reviewSamples: [LocalizationDiagnosticsReviewSample]
    ) -> LocalizationDiagnosticsReviewSummary {
        let locationFixSampleCount = reviewSamples.filter { $0.routeSegmentConfidence != .unavailable }.count
        let barometricOutlierCandidateCount = reviewSamples.filter { $0.barometricOutlierWouldRejectIfEnabled }.count
        let passiveAccuracySourceDiagnosticCount = reviewSamples.filter { $0.accuracySourceClass != nil }.count
        let highPrecisionOrWiFiLikeFixCount = reviewSamples.filter { sample in
            sample.accuracySourceClass == .likelyHighPrecisionGPSOrWiFiRTT
                || sample.accuracySourceClass == .possibleGoodGPSOrWiFiRTT
        }.count
        let headingReplayEligibleCount = reviewSamples.filter { $0.headingReplayReadinessEligible }.count
        let estimatedRouteActiveSampleCount = reviewSamples.filter { $0.estimatedRouteActive }.count
        let productionRouteDecisionAppliedCount = reviewSamples.filter { $0.productionRouteDecisionApplied }.count
        let reviewRisk = risk(
            barometricOutlierCandidateCount: barometricOutlierCandidateCount,
            estimatedRouteActiveSampleCount: estimatedRouteActiveSampleCount,
            productionRouteDecisionAppliedCount: productionRouteDecisionAppliedCount
        )

        return LocalizationDiagnosticsReviewSummary(
            totalSampleCount: totalSampleCount,
            locationFixSampleCount: locationFixSampleCount,
            barometricOutlierCandidateCount: barometricOutlierCandidateCount,
            passiveAccuracySourceDiagnosticCount: passiveAccuracySourceDiagnosticCount,
            highPrecisionOrWiFiLikeFixCount: highPrecisionOrWiFiLikeFixCount,
            headingReplayEligibleCount: headingReplayEligibleCount,
            estimatedRouteActiveSampleCount: estimatedRouteActiveSampleCount,
            productionRouteDecisionAppliedCount: productionRouteDecisionAppliedCount,
            reviewRisk: reviewRisk
        )
    }

    private static func risk(
        barometricOutlierCandidateCount: Int,
        estimatedRouteActiveSampleCount: Int,
        productionRouteDecisionAppliedCount: Int
    ) -> LocalizationDiagnosticsReviewRisk {
        if estimatedRouteActiveSampleCount > 0 || productionRouteDecisionAppliedCount > 0 {
            return .reviewRecommended
        }
        if barometricOutlierCandidateCount > 0 {
            return .attention
        }
        return .nominal
    }
}
