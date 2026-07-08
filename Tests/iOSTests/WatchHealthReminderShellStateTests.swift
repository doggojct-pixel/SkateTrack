// [協作區] Tests/iOSTests/WatchHealthReminderShellStateTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchHealthReminderShellStateTests: XCTestCase {
    func testDefaultDisabledShellStateIsSafe() {
        let generatedAt = Date(timeIntervalSince1970: 800)
        let state = WatchHealthReminderShellState.disabled(generatedAt: generatedAt)

        XCTAssertEqual(state.generatedAt, generatedAt)
        XCTAssertEqual(state.availability, .disabled)
        XCTAssertEqual(state.availability.statusLocalizationKey, "watch.healthReminder.status.disabled")
        XCTAssertEqual(state.titleLocalizationKey, "watch.healthReminder.title")
        XCTAssertEqual(state.detailLocalizationKey, "watch.healthReminder.detail")
        XCTAssertEqual(state.accessibilityLabelLocalizationKey, "watch.healthReminder.accessibility.label")
        XCTAssertTrue(state.hasReminderCategories)
        XCTAssertFalse(state.allowsLiveBodyData)
        XCTAssertFalse(state.requestsSensorAuthorization)
        XCTAssertFalse(state.usesSensorDetection)
    }

    func testHydrationRestAndStretchReminderModelsArePresent() {
        let state = WatchHealthReminderShellState.disabled()
        let kinds = state.items.map(\.kind)

        XCTAssertEqual(kinds, [.hydration, .rest, .stretch])
        XCTAssertEqual(state.items.map(\.titleLocalizationKey), [
            "watch.healthReminder.hydration.title",
            "watch.healthReminder.rest.title",
            "watch.healthReminder.stretch.title",
        ])
        XCTAssertEqual(state.items.map(\.detailLocalizationKey), [
            "watch.healthReminder.hydration.detail",
            "watch.healthReminder.rest.detail",
            "watch.healthReminder.stretch.detail",
        ])
        XCTAssertTrue(state.items.allSatisfy { $0.isEnabled == false })
    }

    func testReminderCopyKeysAvoidRestrictedClaimLanguage() {
        let state = WatchHealthReminderShellState.disabled()
        let copyKeys = (
            [state.titleLocalizationKey, state.detailLocalizationKey, state.accessibilityLabelLocalizationKey]
                + state.items.flatMap { [$0.titleLocalizationKey, $0.detailLocalizationKey] }
        ).joined(separator: " ").lowercased()
        let restricted = [
            "med" + "ical",
            "diagn" + "osis",
            "tr" + "eat" + "ment",
            "clinic" + "al",
            "emerg" + "ency",
            "res" + "cue",
            "fall " + "detection",
            "health" + "kit",
        ]

        for phrase in restricted {
            XCTAssertFalse(copyKeys.contains(phrase))
        }
    }

    func testShellDoesNotIntroduceProductionHealthDataUsage() {
        let state = WatchHealthReminderShellState.disabled()

        XCTAssertFalse(state.allowsLiveBodyData)
        XCTAssertFalse(state.requestsSensorAuthorization)
        XCTAssertFalse(state.usesSensorDetection)
    }

    func testHapticIntentPolicyStaysMockOnlyAndIntentOnly() {
        let state = WatchHealthReminderShellState.disabled()
        let issuedAt = Date(timeIntervalSince1970: 900)
        var gate = WatchHapticIntentGate(policy: state.hapticPolicy)
        let decision = gate.resolve(
            WatchHapticIntent(
                kind: .safetyNotice,
                issuedAt: issuedAt,
                correlationId: "reminder-shell",
                sourceDescription: "watch reminder shell"
            ),
            decidedAt: issuedAt
        )

        XCTAssertEqual(state.hapticPolicy.targetSupport, .mockOnly)
        XCTAssertFalse(state.allowsDeviceHapticPlayback)
        XCTAssertEqual(decision.state, .mockOnly)
        XCTAssertFalse(decision.shouldPlayOnDevice)
        XCTAssertFalse(decision.intent.isSensorDerivedClaim)
    }
}
