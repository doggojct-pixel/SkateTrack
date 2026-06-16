// [協作區] iOS/Core/SnowEngine/SnowLiveSessionConfig.swift
// 用途：集中定義 iPhone Snow Live HUD 的 presentation policy，避免 UI hardcode confidence 門檻。
// 委派至：SnowLiveHUDStateMapper、SnowLiveSessionCoordinator、Snow-Task-005 UI tests。

import Foundation

struct SnowLiveSessionConfig: Sendable, Equatable {
    let classificationWindowSeconds: TimeInterval
    let lowConfidenceThreshold: Double
    let lowConfidenceAlwaysForUnknown: Bool
    let lowConfidenceReasonCodes: Set<String>
    let pendingEndShowsWaitingAfterSeconds: TimeInterval

    static let productionV0 = SnowLiveSessionConfig(
        classificationWindowSeconds: 15,
        lowConfidenceThreshold: SnowClassifierConfig.productionV0.mediumConfidenceThreshold,
        lowConfidenceAlwaysForUnknown: true,
        lowConfidenceReasonCodes: [
            "missingAltitude",
            "insufficientSamples",
            "noRuleMatched",
            "ambiguousGondolaLikeDescent",
        ],
        pendingEndShowsWaitingAfterSeconds: 0
    )
}
