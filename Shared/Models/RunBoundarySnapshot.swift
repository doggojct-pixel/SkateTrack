// [協作區] Shared/Models/RunBoundarySnapshot.swift
// 用途：提供 RunBoundaryDetector 的即時狀態快照，供後續 Snow UI / useSnowSession boundary 使用。
// 委派至：RunBoundaryDetector、Snow-Task-005 iPhone Snow UI 與 fixture tests。

import Foundation

struct RunBoundarySnapshot: Sendable, Equatable {
    let sessionID: UUID
    let state: RunBoundaryState
    let currentRunNumber: Int
    let currentRunID: UUID?
    let currentSegmentType: SnowSegmentType
    let currentConfidence: Double
    let currentRunStartedAt: Date?
    let currentRunDistanceMeters: Double
    let currentRunVerticalDropMeters: Double
    let currentRunTopSpeedMetersPerSecond: Double
    let pendingEndElapsedSeconds: TimeInterval?
    let lastCompletedRun: SnowRun?

    static func empty(sessionID: UUID) -> RunBoundarySnapshot {
        RunBoundarySnapshot(
            sessionID: sessionID,
            state: .idle,
            currentRunNumber: 1,
            currentRunID: nil,
            currentSegmentType: .unknown,
            currentConfidence: 0,
            currentRunStartedAt: nil,
            currentRunDistanceMeters: 0,
            currentRunVerticalDropMeters: 0,
            currentRunTopSpeedMetersPerSecond: 0,
            pendingEndElapsedSeconds: nil,
            lastCompletedRun: nil
        )
    }
}
