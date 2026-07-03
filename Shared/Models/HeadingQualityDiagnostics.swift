// [協作區] Shared/Models/HeadingQualityDiagnostics.swift
// 用途：定義 heading reliability 與 replay-readiness 診斷結果的跨平台資料模型。
// 委派至：HeadingQualityClassifier 與 replay-only diagnostics。

import Foundation

enum HeadingReliability: String, Codable, Sendable, Equatable {
    case high
    case moderate
    case poor
    case invalid
    case tooOld
    case unavailable
}

struct HeadingQualityConfig: Codable, Sendable, Equatable {
    let highAccuracyThresholdDegrees: Double
    let moderateAccuracyThresholdDegrees: Double
    let maxReplayReadinessAgeSeconds: TimeInterval
    let maxCourseDeviceAgreementDeltaDegrees: Double

    init(
        highAccuracyThresholdDegrees: Double = 5,
        moderateAccuracyThresholdDegrees: Double = 20,
        maxReplayReadinessAgeSeconds: TimeInterval = 5,
        maxCourseDeviceAgreementDeltaDegrees: Double = 45
    ) {
        self.highAccuracyThresholdDegrees = max(0, highAccuracyThresholdDegrees)
        self.moderateAccuracyThresholdDegrees = max(
            self.highAccuracyThresholdDegrees,
            moderateAccuracyThresholdDegrees
        )
        self.maxReplayReadinessAgeSeconds = max(0, maxReplayReadinessAgeSeconds)
        self.maxCourseDeviceAgreementDeltaDegrees = max(0, maxCourseDeviceAgreementDeltaDegrees)
    }

    static let replayReadiness = HeadingQualityConfig()
}

struct HeadingQualityAssessment: Codable, Sendable, Equatable {
    let reliability: HeadingReliability
    let replayReadinessEligible: Bool
    let selectedHeadingDegrees: Double?
    let selectedHeadingAccuracyDegrees: Double?
    let selectedHeadingAgeSeconds: TimeInterval?
    let courseDeviceHeadingAgreement: Bool?
    let source: HeadingDiagnosticsSource

    init(
        reliability: HeadingReliability,
        replayReadinessEligible: Bool = false,
        selectedHeadingDegrees: Double? = nil,
        selectedHeadingAccuracyDegrees: Double? = nil,
        selectedHeadingAgeSeconds: TimeInterval? = nil,
        courseDeviceHeadingAgreement: Bool? = nil,
        source: HeadingDiagnosticsSource = .unavailable
    ) {
        self.reliability = reliability
        self.replayReadinessEligible = replayReadinessEligible
        self.selectedHeadingDegrees = selectedHeadingDegrees
        self.selectedHeadingAccuracyDegrees = selectedHeadingAccuracyDegrees
        self.selectedHeadingAgeSeconds = selectedHeadingAgeSeconds.map { max(0, $0) }
        self.courseDeviceHeadingAgreement = courseDeviceHeadingAgreement
        self.source = source
    }
}
