// [協作區] SnowHUDQAScenarioTests.swift
// 用途：驗證 A008R1 iPhone Snow HUD 的四種 DEBUG-only 呈現 fixture 與非 Snow 隔離。

import XCTest
@testable import SkateTrack_iOS

#if DEBUG
final class SnowHUDQAScenarioTests: XCTestCase {
    func testAllFourDeterministicScenarioMappingsExist() {
        XCTAssertEqual(
            Set(SnowHUDQAScenario.allCases),
            Set([.waiting, .downhill, .liftOrGondola, .lowConfidence])
        )

        guard case .waiting = SnowHUDQAScenario.waiting.hudState else {
            return XCTFail("Expected waiting fixture")
        }
        guard case .downhill = SnowHUDQAScenario.downhill.hudState else {
            return XCTFail("Expected downhill fixture")
        }
        guard case let .lift(model) = SnowHUDQAScenario.liftOrGondola.hudState else {
            return XCTFail("Expected lift fixture")
        }
        XCTAssertEqual(model.segmentType, .gondolaAscent)
        guard case let .lowConfidence(model) = SnowHUDQAScenario.lowConfidence.hudState else {
            return XCTFail("Expected low-confidence fixture")
        }
        XCTAssertEqual(model.confidence, 0.35, accuracy: 0.001)
    }

    func testScenarioOverridesOnlySnowPresentation() {
        let liveState = SnowHUDQAScenario.waiting.hudState

        XCTAssertEqual(
            SnowHUDQAScenario.presentationState(
                selectedScenario: .downhill,
                selectedSportMode: .skateboard(.streetPark),
                liveState: liveState
            ),
            liveState
        )
        XCTAssertEqual(
            SnowHUDQAScenario.presentationState(
                selectedScenario: nil,
                selectedSportMode: .snow(.skiing),
                liveState: liveState
            ),
            liveState
        )
        XCTAssertEqual(
            SnowHUDQAScenario.presentationState(
                selectedScenario: .downhill,
                selectedSportMode: .snow(.skiing),
                liveState: liveState
            ),
            SnowHUDQAScenario.downhill.hudState
        )
    }

    func testFixturesDoNotDependOnProductionClassifierConfiguration() {
        let before = SnowHUDQAScenario.lowConfidence.hudState
        _ = SnowLiveSessionConfig.productionV0
        let after = SnowHUDQAScenario.lowConfidence.hudState

        XCTAssertEqual(before, after)
    }
}
#endif
