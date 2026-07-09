// [協作區] Tests/iOSTests/WatchComplicationShellStateTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchComplicationShellStateTests: XCTestCase {
    func testDefaultDisabledShellStateIsSafe() {
        let generatedAt = Date(timeIntervalSince1970: 1_400)
        let state = WatchComplicationShellState.disabled(generatedAt: generatedAt)

        XCTAssertEqual(state.generatedAt, generatedAt)
        XCTAssertEqual(state.availability, .unavailable)
        XCTAssertEqual(state.availability.statusLocalizationKey, "watch.complication.status.unavailable")
        XCTAssertEqual(state.titleLocalizationKey, "watch.complication.title")
        XCTAssertEqual(state.detailLocalizationKey, "watch.complication.detail")
        XCTAssertEqual(state.accessibilityLabelLocalizationKey, "watch.complication.accessibility.label")
        XCTAssertTrue(state.hasPlaceholderSlots)
        XCTAssertFalse(state.supportsFaceComplicationDistribution)
        XCTAssertFalse(state.usesWidgetKitExtension)
        XCTAssertFalse(state.usesClockKitExtension)
        XCTAssertFalse(state.providesLiveTimeline)
        XCTAssertFalse(state.requestsNewCapabilities)
        XCTAssertTrue(state.opensAppOnly)
    }

    func testPlaceholderSlotsArePresentAndDisabled() {
        let state = WatchComplicationShellState.disabled()
        let kinds = state.slots.map(\.kind)

        XCTAssertEqual(kinds, [.currentSpeed, .elapsedTime, .distance])
        XCTAssertEqual(state.slots.map(\.titleLocalizationKey), [
            "watch.complication.speed.title",
            "watch.complication.time.title",
            "watch.complication.distance.title",
        ])
        XCTAssertEqual(state.slots.map(\.detailLocalizationKey), [
            "watch.complication.speed.detail",
            "watch.complication.time.detail",
            "watch.complication.distance.detail",
        ])
        XCTAssertTrue(state.slots.allSatisfy { $0.isEnabled == false })
    }

    func testShellDoesNotIntroduceComplicationRuntimeOrCapabilities() {
        let state = WatchComplicationShellState.disabled()

        XCTAssertFalse(state.supportsFaceComplicationDistribution)
        XCTAssertFalse(state.usesWidgetKitExtension)
        XCTAssertFalse(state.usesClockKitExtension)
        XCTAssertFalse(state.providesLiveTimeline)
        XCTAssertFalse(state.requestsNewCapabilities)
        XCTAssertTrue(state.opensAppOnly)
    }

    func testCopyKeysAvoidReleaseReadinessClaims() {
        let state = WatchComplicationShellState.disabled()
        let copyKeys = (
            [state.titleLocalizationKey, state.detailLocalizationKey, state.accessibilityLabelLocalizationKey]
                + state.slots.flatMap { [$0.titleLocalizationKey, $0.detailLocalizationKey] }
        ).joined(separator: " ").lowercased()
        let restricted = [
            "production",
            "release",
            "store",
            "widgetkit",
            "clockkit",
            "timeline",
            "face distribution",
        ]

        for phrase in restricted {
            XCTAssertFalse(copyKeys.contains(phrase))
        }
    }
}
