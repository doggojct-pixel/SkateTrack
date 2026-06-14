// [協作區] Shared/Models/SnowSessionState.swift
// 用途：定義 Snow Mode 資料邊界狀態，供 useSnowSession 與後續三平台 UI 使用。
// 委派至：SnowSessionRepository、Snow UI、macOS viewer 與 package compatibility。

import Foundation

struct SnowSessionState: Sendable, Equatable {
    enum LoadState: Sendable, Equatable {
        case idle
        case loading
        case empty
        case loaded
        case error(String)
    }

    var sessionID: UUID?
    var loadState: LoadState
    var runs: [SnowRun]
    var segments: [SnowSegment]
    var distanceBreakdown: SnowDistanceBreakdown
    var verticalMetrics: SnowVerticalMetrics

    static let empty = SnowSessionState(
        sessionID: nil,
        loadState: .empty,
        runs: [],
        segments: [],
        distanceBreakdown: .zero,
        verticalMetrics: .zero
    )

    init(
        sessionID: UUID?,
        loadState: LoadState = .idle,
        runs: [SnowRun] = [],
        segments: [SnowSegment] = [],
        distanceBreakdown: SnowDistanceBreakdown? = nil,
        verticalMetrics: SnowVerticalMetrics? = nil
    ) {
        self.sessionID = sessionID
        self.loadState = loadState
        self.runs = runs
        self.segments = segments
        self.distanceBreakdown = distanceBreakdown ?? SnowDistanceBreakdown.make(from: segments)
        self.verticalMetrics = verticalMetrics ?? SnowVerticalMetrics.make(from: segments, runs: runs)
    }
}
