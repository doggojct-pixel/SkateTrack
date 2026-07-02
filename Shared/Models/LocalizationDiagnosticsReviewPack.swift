// [協作區] Shared/Models/LocalizationDiagnosticsReviewPack.swift
// 用途：定義 b16 localization diagnostics review pack 的跨平台資料模型。
// 委派至：LocalizationDiagnosticsReviewBuilder 與 replay-only review workflows。

import Foundation

enum LocalizationDiagnosticsReviewRisk: String, Codable, Sendable, Equatable {
    case nominal
    case attention
    case reviewRecommended
}

struct LocalizationDiagnosticsReviewSummary: Codable, Sendable, Equatable {
    let totalSampleCount: Int
    let locationFixSampleCount: Int
    let barometricOutlierCandidateCount: Int
    let passiveAccuracySourceDiagnosticCount: Int
    let highPrecisionOrWiFiLikeFixCount: Int
    let headingReplayEligibleCount: Int
    let estimatedRouteActiveSampleCount: Int
    let productionRouteDecisionAppliedCount: Int
    let reviewRisk: LocalizationDiagnosticsReviewRisk

    init(
        totalSampleCount: Int,
        locationFixSampleCount: Int,
        barometricOutlierCandidateCount: Int = 0,
        passiveAccuracySourceDiagnosticCount: Int = 0,
        highPrecisionOrWiFiLikeFixCount: Int = 0,
        headingReplayEligibleCount: Int = 0,
        estimatedRouteActiveSampleCount: Int = 0,
        productionRouteDecisionAppliedCount: Int = 0,
        reviewRisk: LocalizationDiagnosticsReviewRisk
    ) {
        self.totalSampleCount = max(0, totalSampleCount)
        self.locationFixSampleCount = max(0, locationFixSampleCount)
        self.barometricOutlierCandidateCount = max(0, barometricOutlierCandidateCount)
        self.passiveAccuracySourceDiagnosticCount = max(0, passiveAccuracySourceDiagnosticCount)
        self.highPrecisionOrWiFiLikeFixCount = max(0, highPrecisionOrWiFiLikeFixCount)
        self.headingReplayEligibleCount = max(0, headingReplayEligibleCount)
        self.estimatedRouteActiveSampleCount = max(0, estimatedRouteActiveSampleCount)
        self.productionRouteDecisionAppliedCount = max(0, productionRouteDecisionAppliedCount)
        self.reviewRisk = reviewRisk
    }
}

struct LocalizationDiagnosticsReviewSample: Codable, Sendable, Equatable {
    let sampleID: UUID
    let timestamp: Date
    let timestampMillisecondsSince1970: Int64?
    let routeSegmentConfidence: RouteSegmentConfidence
    let freshnessState: LocationFreshnessState
    let barometricOutlierWouldRejectIfEnabled: Bool
    let accuracySourceClass: LocationAccuracySourceClass?
    let headingReliability: HeadingReliability
    let headingReplayReadinessEligible: Bool
    let estimatedRouteActive: Bool
    let productionRouteDecisionApplied: Bool

    init(
        sampleID: UUID,
        timestamp: Date,
        timestampMillisecondsSince1970: Int64? = nil,
        routeSegmentConfidence: RouteSegmentConfidence = .unavailable,
        freshnessState: LocationFreshnessState = .unavailable,
        barometricOutlierWouldRejectIfEnabled: Bool = false,
        accuracySourceClass: LocationAccuracySourceClass? = nil,
        headingReliability: HeadingReliability = .unavailable,
        headingReplayReadinessEligible: Bool = false,
        estimatedRouteActive: Bool = false,
        productionRouteDecisionApplied: Bool = false
    ) {
        self.sampleID = sampleID
        self.timestamp = timestamp
        self.timestampMillisecondsSince1970 = timestampMillisecondsSince1970
        self.routeSegmentConfidence = routeSegmentConfidence
        self.freshnessState = freshnessState
        self.barometricOutlierWouldRejectIfEnabled = barometricOutlierWouldRejectIfEnabled
        self.accuracySourceClass = accuracySourceClass
        self.headingReliability = headingReliability
        self.headingReplayReadinessEligible = headingReplayReadinessEligible
        self.estimatedRouteActive = false
        self.productionRouteDecisionApplied = false
    }
}

struct LocalizationDiagnosticsReviewPack: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let taskIdentifier: String
    let createdAt: Date
    let createdAtMillisecondsSince1970: Int64?
    let diagnosticsOnly: Bool
    let replayReviewOnly: Bool
    let productionRouteMutationApplied: Bool
    let summary: LocalizationDiagnosticsReviewSummary
    let samples: [LocalizationDiagnosticsReviewSample]

    init(
        schemaVersion: Int = 1,
        taskIdentifier: String = "Task-030c-b17",
        createdAt: Date,
        summary: LocalizationDiagnosticsReviewSummary,
        samples: [LocalizationDiagnosticsReviewSample]
    ) {
        self.schemaVersion = max(1, schemaVersion)
        self.taskIdentifier = taskIdentifier
        self.createdAt = createdAt
        self.createdAtMillisecondsSince1970 = Int64((createdAt.timeIntervalSince1970 * 1_000).rounded())
        self.diagnosticsOnly = true
        self.replayReviewOnly = true
        self.productionRouteMutationApplied = false
        self.summary = summary
        self.samples = samples
    }
}
