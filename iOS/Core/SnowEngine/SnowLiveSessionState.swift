// [協作區] iOS/Core/SnowEngine/SnowLiveSessionState.swift
// 用途：iPhone Snow Live HUD 的 production live data contract。
// 委派至：SnowLiveSessionCoordinator、useSnowLiveSession、SnowLiveHUDStateMapper。

import Foundation

struct SnowLiveSessionState: Sendable, Equatable {
    var sessionID: UUID?
    var isActive: Bool
    var isPaused: Bool

    var latestSnapshot: RunBoundarySnapshot?
    var latestClassification: SnowSegmentClassification?

    var currentSpeedKmh: Double
    var maxSpeedThisRunKmh: Double

    var currentRunNumber: Int
    var currentRunVerticalDropMeters: Double
    var currentRunDistanceMeters: Double
    var currentRunTopSpeedKmh: Double

    var completedRuns: [SnowRun]
    var inMemorySegments: [SnowSegment]
    var distanceBreakdown: SnowDistanceBreakdown

    var lastCompletedRun: SnowRun?
    var latestReasonCodes: [String]

    static let empty = SnowLiveSessionState(
        sessionID: nil,
        isActive: false,
        isPaused: false,
        latestSnapshot: nil,
        latestClassification: nil,
        currentSpeedKmh: 0,
        maxSpeedThisRunKmh: 0,
        currentRunNumber: 0,
        currentRunVerticalDropMeters: 0,
        currentRunDistanceMeters: 0,
        currentRunTopSpeedKmh: 0,
        completedRuns: [],
        inMemorySegments: [],
        distanceBreakdown: .zero,
        lastCompletedRun: nil,
        latestReasonCodes: []
    )
}
