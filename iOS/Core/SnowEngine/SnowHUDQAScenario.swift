// [協作區] SnowHUDQAScenario.swift
// 用途：提供 DEBUG-only、確定性的 iPhone Snow HUD 呈現情境，不修改 classifier 或可信指標。
// 委派至：DebugRuntimeOptions 與 SnowHUDView；不得寫入 session、repository 或 package。

#if DEBUG
import Foundation

enum SnowHUDQAScenario: String, CaseIterable, Identifiable, Sendable {
    case waiting
    case downhill
    case liftOrGondola
    case lowConfidence

    var id: String { rawValue }

    var titleLocalizationKey: String {
        switch self {
        case .waiting:
            return "debug.tools.snowHUDScenario.waiting"
        case .downhill:
            return "debug.tools.snowHUDScenario.downhill"
        case .liftOrGondola:
            return "debug.tools.snowHUDScenario.lift"
        case .lowConfidence:
            return "debug.tools.snowHUDScenario.lowConfidence"
        }
    }

    var hudState: SnowLiveHUDState {
        switch self {
        case .waiting:
            return .waiting(
                SnowWaitingHUDModel(
                    titleLocalizationKey: "snow.hud.waiting.title",
                    currentSegmentType: .stopped,
                    pendingEndElapsedSeconds: nil,
                    lastRunVerticalDropMeters: 186,
                    lastRunTopSpeedKmh: 62.4,
                    lastRunDurationSeconds: 228
                )
            )
        case .downhill:
            return .downhill(
                SnowDownhillHUDModel(
                    runNumber: 4,
                    currentSpeedKmh: 42.8,
                    maxSpeedThisRunKmh: 62.4,
                    verticalDropMeters: 186,
                    skiDistanceMeters: 1_250,
                    elapsedTime: 228
                )
            )
        case .liftOrGondola:
            return .lift(
                SnowLiftHUDModel(
                    segmentType: .gondolaAscent,
                    currentSpeedKmh: 7.2,
                    liftDistanceMeters: 950,
                    routeDistanceMeters: 2_210,
                    messageLocalizationKey: "snow.hud.lift.notCounting"
                )
            )
        case .lowConfidence:
            return .lowConfidence(
                SnowLowConfidenceHUDModel(
                    currentSegmentType: .unknown,
                    confidence: 0.35,
                    reasonCodes: ["qa_fixture_low_confidence"],
                    currentSpeedKmh: 14.5,
                    messageLocalizationKey: "snow.hud.lowConfidence"
                )
            )
        }
    }

    static func presentationState(
        selectedScenario: SnowHUDQAScenario?,
        selectedSportMode: SportMode?,
        liveState: SnowLiveHUDState
    ) -> SnowLiveHUDState {
        guard let selectedScenario,
              let selectedSportMode,
              case .snow = selectedSportMode else {
            return liveState
        }
        return selectedScenario.hudState
    }
}
#endif
