// [協作區] SnowSummarySelection.swift
// 用途：解析 iPhone Snow summary 的唯讀 run/segment 選取與 inspector 投影。
// 委派至：SessionSummaryView、SnowSegmentTimelineView、SnowDistanceInspectorView；不得寫入 repository。

import Foundation

enum SnowSummarySelection: Hashable, Sendable {
    case run(UUID)
    case segment(UUID)
}

enum SnowSummaryInspectorContext: Equatable, Sendable {
    case session
    case run(Int)
    case segment(SnowSegmentType)
}

struct SnowSummaryInspectorSnapshot: Equatable, Sendable {
    let selection: SnowSummarySelection?
    let context: SnowSummaryInspectorContext
    let breakdown: SnowDistanceBreakdown
}

enum SnowSummarySelectionModel {
    static func resolvedSelection(
        current: SnowSummarySelection?,
        state: SnowSessionState
    ) -> SnowSummarySelection? {
        if let current, contains(current, in: state) {
            return current
        }
        if let run = orderedRuns(state.runs).first {
            return .run(run.id)
        }
        if let segment = orderedSegments(state.segments).first {
            return .segment(segment.id)
        }
        return nil
    }

    static func inspectorSnapshot(
        current: SnowSummarySelection?,
        state: SnowSessionState
    ) -> SnowSummaryInspectorSnapshot {
        let selection = resolvedSelection(current: current, state: state)
        switch selection {
        case let .run(runID):
            guard let run = state.runs.first(where: { $0.id == runID }) else {
                return sessionSnapshot(state: state)
            }
            let segments = state.segments.filter {
                $0.runID == run.id || run.segmentIDs.contains($0.id)
            }
            let breakdown = segments.isEmpty
                ? SnowDistanceBreakdown(
                    skiDistanceMeters: run.skiDistanceMeters,
                    liftDistanceMeters: 0,
                    routeDistanceMeters: run.skiDistanceMeters,
                    unknownDistanceMeters: 0
                )
                : SnowDistanceBreakdown.make(from: segments)
            return SnowSummaryInspectorSnapshot(
                selection: selection,
                context: .run(run.runNumber),
                breakdown: breakdown
            )
        case let .segment(segmentID):
            guard let segment = state.segments.first(where: { $0.id == segmentID }) else {
                return sessionSnapshot(state: state)
            }
            return SnowSummaryInspectorSnapshot(
                selection: selection,
                context: .segment(segment.type),
                breakdown: SnowDistanceBreakdown.make(from: [segment])
            )
        case nil:
            return sessionSnapshot(state: state)
        }
    }

    private static func contains(_ selection: SnowSummarySelection, in state: SnowSessionState) -> Bool {
        switch selection {
        case let .run(id):
            return state.runs.contains { $0.id == id }
        case let .segment(id):
            return state.segments.contains { $0.id == id }
        }
    }

    private static func orderedRuns(_ runs: [SnowRun]) -> [SnowRun] {
        runs.sorted { lhs, rhs in
            if lhs.runNumber != rhs.runNumber { return lhs.runNumber < rhs.runNumber }
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private static func orderedSegments(_ segments: [SnowSegment]) -> [SnowSegment] {
        segments.sorted { lhs, rhs in
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private static func sessionSnapshot(state: SnowSessionState) -> SnowSummaryInspectorSnapshot {
        SnowSummaryInspectorSnapshot(
            selection: nil,
            context: .session,
            breakdown: state.distanceBreakdown
        )
    }
}
