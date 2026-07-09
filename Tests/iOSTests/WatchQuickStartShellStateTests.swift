// [協作區] Tests/iOSTests/WatchQuickStartShellStateTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchQuickStartShellStateTests: XCTestCase {
    func testDisabledShellRequiresIPhoneAuthority() {
        let generatedAt = Date(timeIntervalSince1970: 1_500)
        let state = WatchQuickStartShellState.disabled(
            generatedAt: generatedAt,
            canSendCommands: true
        )

        XCTAssertEqual(state.generatedAt, generatedAt)
        XCTAssertEqual(state.availability, .iPhoneAuthorityRequired)
        XCTAssertEqual(state.availability.statusLocalizationKey, "watch.quickStart.status.iPhoneAuthority")
        XCTAssertEqual(state.authority, .iPhone)
        XCTAssertTrue(state.requiresIPhoneAuthority)
        XCTAssertFalse(state.allowsDirectWatchStart)
        XCTAssertFalse(state.startsSessionFromWatch)
        XCTAssertFalse(state.writesSessionRuntime)
        XCTAssertNil(state.makeStartCommand())
    }

    func testProviderUnavailableStateRemainsDisabled() {
        let state = WatchQuickStartShellState.disabled(canSendCommands: false)

        XCTAssertEqual(state.availability, .providerUnavailable)
        XCTAssertEqual(state.availability.statusLocalizationKey, "watch.quickStart.status.providerUnavailable")
        XCTAssertTrue(state.isProviderAware)
        XCTAssertTrue(state.requiresIPhoneAuthority)
        XCTAssertFalse(state.allowsDirectWatchStart)
        XCTAssertNil(state.makeStartCommand())
    }

    func testQuickStartOptionsArePresentAndDisabled() {
        let state = WatchQuickStartShellState.disabled(canSendCommands: true)
        let kinds = state.options.map(\.kind)

        XCTAssertEqual(kinds, [.lastMode, .outdoorRide, .readyCheck])
        XCTAssertEqual(state.options.map(\.titleLocalizationKey), [
            "watch.quickStart.lastMode.title",
            "watch.quickStart.outdoor.title",
            "watch.quickStart.readyCheck.title",
        ])
        XCTAssertEqual(state.options.map(\.detailLocalizationKey), [
            "watch.quickStart.lastMode.detail",
            "watch.quickStart.outdoor.detail",
            "watch.quickStart.readyCheck.detail",
        ])
        XCTAssertTrue(state.hasQuickStartOptions)
        XCTAssertTrue(state.options.allSatisfy { $0.isEnabled == false })
    }

    func testViewModelInitializerUsesConnectionProviderState() {
        let reachable = WatchActivityViewModel(
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: WatchBridgeConnectionState(status: .reachable, quality: .fresh),
                canSendCommands: true,
                canReceiveSnapshots: true
            )
        )
        let stale = WatchActivityViewModel(
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: WatchBridgeConnectionState(status: .pairedButUnreachable, quality: .stale),
                canSendCommands: false,
                canReceiveSnapshots: false
            )
        )

        XCTAssertEqual(WatchQuickStartShellState(viewModel: reachable).availability, .iPhoneAuthorityRequired)
        XCTAssertEqual(WatchQuickStartShellState(viewModel: stale).availability, .providerUnavailable)
    }
}
