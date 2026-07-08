// [協作區] Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchFallSafetyPresentationShellStateTests: XCTestCase {
    func testDefaultPresentedShellStateIsSafeAndShellOnly() {
        let generatedAt = Date(timeIntervalSince1970: 1_000)
        let state = WatchFallSafetyPresentationShellState.presented(generatedAt: generatedAt)

        XCTAssertEqual(state.generatedAt, generatedAt)
        XCTAssertEqual(state.phase, .presented)
        XCTAssertTrue(state.isVisible)
        XCTAssertTrue(state.hasManualDismissPath)
        XCTAssertTrue(state.falseAlarmPathPresent)
        XCTAssertFalse(state.detectsFalls)
        XCTAssertFalse(state.contactsEmergencyServices)
        XCTAssertFalse(state.usesHealthKit)
        XCTAssertFalse(state.requestsHealthKitPermission)
        XCTAssertFalse(state.readsBodyData)
        XCTAssertFalse(state.allowsDeviceHapticPlayback)
    }

    func testManualDismissTransitionWorks() {
        let resolvedAt = Date(timeIntervalSince1970: 1_100)
        let state = WatchFallSafetyPresentationShellState.presented()
        let dismissed = state.dismissed(at: resolvedAt)

        XCTAssertEqual(dismissed.phase, .dismissed)
        XCTAssertEqual(dismissed.resolvedAt, resolvedAt)
        XCTAssertEqual(dismissed.resolution, .manualDismiss)
        XCTAssertFalse(dismissed.isVisible)
        XCTAssertFalse(dismissed.detectsFalls)
        XCTAssertFalse(dismissed.contactsEmergencyServices)
        XCTAssertFalse(dismissed.usesHealthKit)
    }

    func testFalseAlarmPathExistsAndWorks() {
        let resolvedAt = Date(timeIntervalSince1970: 1_200)
        let state = WatchFallSafetyPresentationShellState.presented()
        let falseAlarm = state.markedFalseAlarm(at: resolvedAt)

        XCTAssertTrue(state.falseAlarmPathPresent)
        XCTAssertEqual(falseAlarm.phase, .falseAlarm)
        XCTAssertEqual(falseAlarm.resolvedAt, resolvedAt)
        XCTAssertEqual(falseAlarm.resolution, .falseAlarm)
        XCTAssertFalse(falseAlarm.isVisible)
        XCTAssertFalse(falseAlarm.detectsFalls)
        XCTAssertFalse(falseAlarm.contactsEmergencyServices)
        XCTAssertFalse(falseAlarm.usesHealthKit)
    }

    func testSafeLocalizationCopyKeyReferencesArePresent() {
        let state = WatchFallSafetyPresentationShellState.presented()

        XCTAssertEqual(state.titleLocalizationKey, "watch.fallSafety.title")
        XCTAssertEqual(state.detailLocalizationKey, "watch.fallSafety.detail")
        XCTAssertEqual(state.limitationLocalizationKey, "watch.fallSafety.limitation")
        XCTAssertEqual(state.dismissButtonLocalizationKey, "watch.fallSafety.dismiss")
        XCTAssertEqual(state.falseAlarmButtonLocalizationKey, "watch.fallSafety.falseAlarm")
        XCTAssertEqual(state.accessibilityLabelLocalizationKey, "watch.fallSafety.accessibility.label")
        XCTAssertEqual(state.phase.statusLocalizationKey, "watch.fallSafety.status.shell")
    }

    func testNoTransitionTriggersDispatchSensorOrHealthBoundaries() {
        let states = [
            WatchFallSafetyPresentationShellState.hidden(),
            WatchFallSafetyPresentationShellState.presented(),
            WatchFallSafetyPresentationShellState.presented().dismissed(),
            WatchFallSafetyPresentationShellState.presented().markedFalseAlarm(),
        ]

        for state in states {
            XCTAssertFalse(state.detectsFalls)
            XCTAssertFalse(state.contactsEmergencyServices)
            XCTAssertFalse(state.usesHealthKit)
            XCTAssertFalse(state.requestsHealthKitPermission)
            XCTAssertFalse(state.readsBodyData)
            XCTAssertFalse(state.allowsDeviceHapticPlayback)
        }
    }

    func testHapticIntentPolicyStaysMockOrDisabledAndNeverPlaysOnDevice() {
        let presented = WatchFallSafetyPresentationShellState.presented()
        let hidden = WatchFallSafetyPresentationShellState.hidden()
        var gate = WatchHapticIntentGate(policy: presented.hapticPolicy)
        let issuedAt = Date(timeIntervalSince1970: 1_300)
        let decision = gate.resolve(
            WatchHapticIntent(
                kind: .safetyNotice,
                issuedAt: issuedAt,
                correlationId: "fall-safety-shell",
                sourceDescription: "watch fall safety presentation shell"
            ),
            decidedAt: issuedAt
        )

        XCTAssertEqual(presented.hapticPolicy.targetSupport, .mockOnly)
        XCTAssertEqual(hidden.hapticPolicy.targetSupport, .unavailable)
        XCTAssertEqual(decision.state, .mockOnly)
        XCTAssertFalse(decision.shouldPlayOnDevice)
        XCTAssertFalse(decision.intent.isSensorDerivedClaim)
    }
}
