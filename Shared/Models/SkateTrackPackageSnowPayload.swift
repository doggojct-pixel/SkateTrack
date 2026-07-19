// [協作區] Shared/Models/SkateTrackPackageSnowPayload.swift
// 用途：定義 Snow-Task-008a 官方 .skatetrack Snow payload，供 iOS 匯出與 macOS package viewer 匯入。
// 委派至：SkateTrackPackagePayload、iOS package export provider、MacSnowSessionAnalysisMapper；不得使用 prototype mock 型別。

import Foundation

enum SkateTrackPackageSnowCapability: String, Codable, Sendable, CaseIterable, Equatable {
    case snowSports = "snow-sports-v1"
    case snowSegments = "snow-segments-v1"
    case snowDistanceBreakdown = "snow-distance-breakdown-v1"
    case snowLiftExclusion = "snow-lift-exclusion-v1"

    static var allRawValues: [String] {
        allCases.map(\.rawValue).sorted()
    }
}

struct SkateTrackPackageSnowPayload: Codable, Sendable, Equatable {
    static let currentPayloadVersion = "snow-payload-1.0"

    let payloadVersion: String
    let sessionID: UUID
    let runs: [SnowRun]
    let segments: [SnowSegment]
    let distanceBreakdown: SnowDistanceBreakdown
    let verticalMetrics: SnowVerticalMetrics
    let generatedAt: Date
    let capabilities: [String]

    init(
        payloadVersion: String = SkateTrackPackageSnowPayload.currentPayloadVersion,
        sessionID: UUID,
        runs: [SnowRun] = [],
        segments: [SnowSegment] = [],
        distanceBreakdown: SnowDistanceBreakdown? = nil,
        verticalMetrics: SnowVerticalMetrics? = nil,
        generatedAt: Date = Date(),
        capabilities: [String] = SkateTrackPackageSnowCapability.allRawValues
    ) {
        self.payloadVersion = payloadVersion
        self.sessionID = sessionID
        self.runs = runs.sorted { $0.runNumber < $1.runNumber }
        self.segments = segments.sorted { $0.startDate < $1.startDate }
        self.distanceBreakdown = distanceBreakdown ?? SnowDistanceBreakdown.make(from: segments)
        self.verticalMetrics = verticalMetrics ?? SnowVerticalMetrics.make(from: segments, runs: runs)
        self.generatedAt = generatedAt
        self.capabilities = Self.normalizedCapabilities(capabilities)
    }

    init?(snowState: SnowSessionState, generatedAt: Date = Date()) {
        guard let sessionID = snowState.sessionID else { return nil }
        guard !snowState.runs.isEmpty || !snowState.segments.isEmpty else { return nil }
        self.init(
            sessionID: sessionID,
            runs: snowState.runs,
            segments: snowState.segments,
            distanceBreakdown: snowState.distanceBreakdown,
            verticalMetrics: snowState.verticalMetrics,
            generatedAt: generatedAt
        )
    }

    func makeSnowSessionState() -> SnowSessionState {
        SnowSessionState(
            sessionID: sessionID,
            loadState: segments.isEmpty && runs.isEmpty ? .empty : .loaded,
            runs: runs,
            segments: segments,
            distanceBreakdown: distanceBreakdown,
            verticalMetrics: verticalMetrics
        )
    }

    private static func normalizedCapabilities(_ capabilities: [String]) -> [String] {
        Array(Set(capabilities.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })).sorted()
    }
}
