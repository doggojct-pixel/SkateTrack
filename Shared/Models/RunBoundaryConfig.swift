// [協作區] Shared/Models/RunBoundaryConfig.swift
// 用途：集中定義 Snow Mode RunBoundaryDetector v0 狀態轉換門檻。
// 委派至：RunBoundaryDetector、Snow-Task-004 fixture tests 與後續實機校準。

import Foundation

struct RunBoundaryConfig: Codable, Sendable, Equatable {
    let startConfirmationSeconds: TimeInterval
    let startConfidenceThreshold: Double
    let pendingEndConfirmationSeconds: TimeInterval
    let pendingEndCancelSeconds: TimeInterval
    let pendingEndCancelConfidenceThreshold: Double
    let pendingEndTimeoutSeconds: TimeInterval
    let hardTransportEndConfidenceThreshold: Double
    let hardTransportConfirmationSeconds: TimeInterval
    let maximumMergeGapSeconds: TimeInterval

    static let productionV0 = RunBoundaryConfig(
        startConfirmationSeconds: 3,
        startConfidenceThreshold: 0.70,
        pendingEndConfirmationSeconds: 8,
        pendingEndCancelSeconds: 2,
        pendingEndCancelConfidenceThreshold: 0.62,
        pendingEndTimeoutSeconds: 30,
        hardTransportEndConfidenceThreshold: 0.78,
        hardTransportConfirmationSeconds: 5,
        maximumMergeGapSeconds: 2
    )
}
