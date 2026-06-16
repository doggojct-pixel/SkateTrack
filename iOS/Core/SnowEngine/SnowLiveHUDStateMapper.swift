// [協作區] iOS/Core/SnowEngine/SnowLiveHUDStateMapper.swift
// 用途：將 production Snow live state 映射為四種 iPhone Snow HUD 狀態；不直接讀 raw MotionSample。
// 委派至：SnowHUDView、Snow-Task-005 mapper tests。

import Foundation

struct SnowLiveHUDStateMapper: Sendable {
    static func map(
        snowState: SnowLiveSessionState,
        recordingState: SessionRecordingState,
        config: SnowLiveSessionConfig = .productionV0
    ) -> SnowLiveHUDState {
        let snapshot = snowState.latestSnapshot
        let classification = snowState.latestClassification
        let currentSegmentType = snapshot?.currentSegmentType ?? classification?.type ?? .unknown
        let confidence = snapshot?.currentConfidence ?? classification?.confidence ?? 0

        if isLowConfidence(snapshot: snapshot, classification: classification, config: config) {
            return .lowConfidence(
                SnowLowConfidenceHUDModel(
                    currentSegmentType: currentSegmentType,
                    confidence: confidence,
                    reasonCodes: snowState.latestReasonCodes,
                    currentSpeedKmh: snowState.currentSpeedKmh,
                    messageLocalizationKey: "snow.hud.lowConfidence"
                )
            )
        }

        if let snapshot,
           snapshot.state == .active,
           currentSegmentType.defaultCountsTowardSkiDistance {
            return .downhill(
                SnowDownhillHUDModel(
                    runNumber: snapshot.currentRunNumber,
                    currentSpeedKmh: snowState.currentSpeedKmh,
                    maxSpeedThisRunKmh: snowState.maxSpeedThisRunKmh,
                    verticalDropMeters: snapshot.currentRunVerticalDropMeters,
                    skiDistanceMeters: snapshot.currentRunDistanceMeters,
                    elapsedTime: recordingState.elapsedTime
                )
            )
        }

        if currentSegmentType.isLiftTransport {
            return .lift(
                SnowLiftHUDModel(
                    segmentType: currentSegmentType,
                    currentSpeedKmh: snowState.currentSpeedKmh,
                    liftDistanceMeters: snowState.distanceBreakdown.liftDistanceMeters,
                    routeDistanceMeters: snowState.distanceBreakdown.routeDistanceMeters,
                    messageLocalizationKey: "snow.hud.lift.notCounting"
                )
            )
        }

        return .waiting(
            SnowWaitingHUDModel(
                titleLocalizationKey: "snow.hud.waiting.title",
                currentSegmentType: currentSegmentType,
                pendingEndElapsedSeconds: snapshot?.pendingEndElapsedSeconds,
                lastRunVerticalDropMeters: snowState.lastCompletedRun?.verticalDropMeters,
                lastRunTopSpeedKmh: snowState.lastCompletedRun.map { $0.topSpeedMetersPerSecond * 3.6 },
                lastRunDurationSeconds: snowState.lastCompletedRun?.durationSeconds
            )
        )
    }

    static func isLowConfidence(
        snapshot: RunBoundarySnapshot?,
        classification: SnowSegmentClassification?,
        config: SnowLiveSessionConfig = .productionV0
    ) -> Bool {
        guard let snapshot else { return false }

        if config.lowConfidenceAlwaysForUnknown,
           snapshot.currentSegmentType == .unknown {
            return true
        }

        if snapshot.currentConfidence < config.lowConfidenceThreshold {
            return true
        }

        if let classification {
            let reasonCodes = Set(classification.reasonCodes)
            if !reasonCodes.isDisjoint(with: config.lowConfidenceReasonCodes) {
                return true
            }
        }

        return false
    }
}
