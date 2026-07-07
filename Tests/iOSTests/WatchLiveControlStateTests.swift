// [Collaboration] Tests/iOSTests/WatchLiveControlStateTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchLiveControlStateTests: XCTestCase {
    func testIdleStateShowsEnabledStartAndBuildsStartCommand() {
        let issuedAt = Date(timeIntervalSince1970: 1_000)
        let state = WatchLiveControlState(
            sessionState: .idle,
            sportModeKey: "skateboard",
            canSendCommands: true
        )

        XCTAssertEqual(state.actions.map(\.kind), [.start])
        XCTAssertEqual(state.actions.first?.commandKind, .startSession)
        XCTAssertEqual(state.actions.first?.mirroredAction, .start)
        XCTAssertEqual(state.actions.first?.titleLocalizationKey, "watch.live.controls.start")
        XCTAssertTrue(state.actions.first?.isEnabled == true)

        let command = state.makeCommand(for: .start, issuedAt: issuedAt)
        XCTAssertEqual(command?.kind, .startSession)
        XCTAssertNil(command?.sessionId)
        XCTAssertEqual(command?.sportModeKey, "skateboard")
        XCTAssertEqual(command?.issuedAt, issuedAt)
    }

    func testRecordingStateShowsPauseStopAndUsesCommandBoundary() {
        let sessionId = Self.uuid(36)
        let state = WatchLiveControlState(
            sessionState: .recording,
            sessionId: sessionId,
            sportModeKey: "longboard",
            canSendCommands: true
        )

        XCTAssertEqual(state.actions.map(\.kind), [.pause, .stop])
        XCTAssertEqual(state.actions.map(\.commandKind), [.pauseSession, .endSession])
        XCTAssertEqual(state.actions.map(\.mirroredAction), [.pause, .stop])
        XCTAssertTrue(state.actions.allSatisfy(\.isEnabled))

        let pause = state.makeCommand(for: .pause)
        let stop = state.makeCommand(for: .stop)
        XCTAssertEqual(pause?.kind, .pauseSession)
        XCTAssertEqual(pause?.sessionId, sessionId)
        XCTAssertEqual(stop?.kind, .endSession)
        XCTAssertEqual(stop?.sessionId, sessionId)
    }

    func testPausedStateShowsResumeStop() {
        let sessionId = Self.uuid(37)
        let state = WatchLiveControlState(
            sessionState: .paused,
            sessionId: sessionId,
            canSendCommands: true
        )

        XCTAssertEqual(state.actions.map(\.kind), [.resume, .stop])
        XCTAssertEqual(state.makeCommand(for: .resume)?.kind, .resumeSession)
        XCTAssertEqual(state.makeCommand(for: .stop)?.kind, .endSession)
    }

    func testDisconnectedStateKeepsVisibleControlsDisabled() {
        let state = WatchLiveControlState(
            sessionState: .recording,
            sessionId: Self.uuid(38),
            canSendCommands: false
        )

        XCTAssertEqual(state.actions.map(\.kind), [.pause, .stop])
        XCTAssertFalse(state.actions.contains(where: \.isEnabled))
        XCTAssertNil(state.makeCommand(for: .pause))
        XCTAssertNil(state.makeCommand(for: .stop))
    }

    func testExistingSessionActionsRequireAuthoritativeSessionId() {
        let state = WatchLiveControlState(
            sessionState: .recording,
            sessionId: nil,
            canSendCommands: true
        )

        XCTAssertEqual(state.actions.map(\.kind), [.pause, .stop])
        XCTAssertFalse(state.actions.contains(where: \.isEnabled))
        XCTAssertNil(state.makeCommand(for: .pause))
    }

    func testViewModelInitializerUsesConnectionAndSessionState() {
        let sessionId = Self.uuid(39)
        let viewModel = WatchActivityViewModel(
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: WatchBridgeConnectionState(status: .reachable, quality: .fresh),
                canSendCommands: true,
                canReceiveSnapshots: true
            ),
            session: WatchBridgeActivitySessionPayload(
                sessionId: sessionId,
                state: .paused,
                mode: WatchBridgeActivityModeDescriptor(sportModeKey: "inline"),
                isRecordingAllowed: true
            )
        )

        let state = WatchLiveControlState(viewModel: viewModel)

        XCTAssertEqual(state.sessionState, .paused)
        XCTAssertEqual(state.sessionId, sessionId)
        XCTAssertEqual(state.sportModeKey, "inline")
        XCTAssertEqual(state.actions.map(\.kind), [.resume, .stop])
        XCTAssertEqual(state.makeCommand(for: .resume)?.sportModeKey, "inline")
    }

    func testSpeedDisplayFormatsMetersPerSecondAsKilometersPerHour() {
        let available = WatchLiveSpeedDisplayValue(currentSpeedMetersPerSecond: 5.5)
        XCTAssertEqual(available.valueText, "19.8")
        XCTAssertEqual(available.unitLocalizationKey, "unit.speed.kmh.short")
        XCTAssertTrue(available.isAvailable)

        let unavailable = WatchLiveSpeedDisplayValue(currentSpeedMetersPerSecond: nil)
        XCTAssertEqual(unavailable.valueText, "--")
        XCTAssertFalse(unavailable.isAvailable)
    }

    private static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
