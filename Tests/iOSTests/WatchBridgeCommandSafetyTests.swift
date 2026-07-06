// [協作區] Tests/iOSTests/WatchBridgeCommandSafetyTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchBridgeCommandSafetyTests: XCTestCase {
    func testRejectsSimultaneousIPhoneActionBeforeAuthorityValidation() {
        let baseAuthority = SafetyRecordingAuthority(decision: .accept())
        let safetyAuthority = WatchBridgeCommandSafetyAuthority(
            authority: baseAuthority,
            contextProvider: {
                WatchBridgeCommandSafetyContext(
                    iPhoneActionInProgress: true,
                    connectionState: Self.reachableState()
                )
            }
        )
        var processor = WatchBridgeMirroredCommandProcessor(authority: safetyAuthority)

        let roundTrip = processor.processEnvelope(
            makeEnvelope(kind: .startSession, commandId: uuid(21), messageId: uuid(121)),
            decidedAt: Date(timeIntervalSince1970: 122)
        )

        XCTAssertEqual(roundTrip.decision.state, .rejected)
        XCTAssertEqual(roundTrip.decision.rejectionReason, .iPhoneActionInProgress)
        XCTAssertEqual(baseAuthority.callCount, 0)
        XCTAssertCommandResult(roundTrip, result: .rejected, correlationId: uuid(121))
    }

    func testRejectsOutOfOrderWatchCommandBeforeAuthorityValidation() {
        let baseAuthority = SafetyRecordingAuthority(decision: .accept())
        let safetyAuthority = WatchBridgeCommandSafetyAuthority(
            authority: baseAuthority,
            contextProvider: {
                WatchBridgeCommandSafetyContext(
                    latestAcceptedCommandIssuedAt: Date(timeIntervalSince1970: 200),
                    connectionState: Self.reachableState()
                )
            }
        )
        var processor = WatchBridgeMirroredCommandProcessor(authority: safetyAuthority)

        let roundTrip = processor.processEnvelope(
            makeEnvelope(
                kind: .startSession,
                commandId: uuid(22),
                messageId: uuid(122),
                issuedAt: Date(timeIntervalSince1970: 190)
            ),
            decidedAt: Date(timeIntervalSince1970: 191)
        )

        XCTAssertEqual(roundTrip.decision.state, .rejected)
        XCTAssertEqual(roundTrip.decision.rejectionReason, .outOfOrderCommand)
        XCTAssertEqual(baseAuthority.callCount, 0)
        XCTAssertCommandResult(roundTrip, result: .rejected, correlationId: uuid(122))
    }

    func testRejectsDisconnectedWatchStateWithoutAuthorityValidation() {
        let baseAuthority = SafetyRecordingAuthority(decision: .accept())
        let safetyAuthority = WatchBridgeCommandSafetyAuthority(
            authority: baseAuthority,
            contextProvider: {
                WatchBridgeCommandSafetyContext(
                    connectionState: WatchBridgeConnectionState(
                        status: .pairedButUnreachable,
                        quality: .delayed,
                        lastUpdatedAt: Date(timeIntervalSince1970: 220),
                        explanation: "paired watch is currently unreachable"
                    )
                )
            }
        )
        var processor = WatchBridgeMirroredCommandProcessor(authority: safetyAuthority)

        let roundTrip = processor.processEnvelope(
            makeEnvelope(
                kind: .startSession,
                commandId: uuid(23),
                messageId: uuid(123),
                issuedAt: Date(timeIntervalSince1970: 221)
            ),
            decidedAt: Date(timeIntervalSince1970: 222)
        )

        XCTAssertEqual(roundTrip.decision.state, .rejected)
        XCTAssertEqual(roundTrip.decision.rejectionReason, .watchDisconnected)
        XCTAssertEqual(baseAuthority.callCount, 0)
        XCTAssertCommandResult(roundTrip, result: .rejected, correlationId: uuid(123))
    }

    func testForwardsReachableInOrderWatchCommandToIPhoneAuthority() {
        let sessionId = uuid(724)
        let baseAuthority = SafetyRecordingAuthority(decision: .accept(sessionId: sessionId))
        let safetyAuthority = WatchBridgeCommandSafetyAuthority(
            authority: baseAuthority,
            contextProvider: {
                WatchBridgeCommandSafetyContext(
                    latestAcceptedCommandIssuedAt: Date(timeIntervalSince1970: 230),
                    connectionState: Self.reachableState(at: Date(timeIntervalSince1970: 240))
                )
            }
        )
        var processor = WatchBridgeMirroredCommandProcessor(authority: safetyAuthority)

        let roundTrip = processor.processEnvelope(
            makeEnvelope(
                kind: .startSession,
                commandId: uuid(24),
                messageId: uuid(124),
                issuedAt: Date(timeIntervalSince1970: 241)
            ),
            decidedAt: Date(timeIntervalSince1970: 242)
        )

        XCTAssertEqual(roundTrip.decision.state, .accepted)
        XCTAssertEqual(roundTrip.decision.sessionId, sessionId)
        XCTAssertEqual(baseAuthority.callCount, 1)
        XCTAssertCommandResult(roundTrip, result: .accepted, correlationId: uuid(124))
    }

    private func makeEnvelope(
        kind: WatchBridgeCommandKind,
        commandId: UUID,
        messageId: UUID,
        issuedAt: Date = Date(timeIntervalSince1970: 120)
    ) -> WatchBridgeEnvelope {
        let command = WatchBridgeCommandEnvelope(
            commandId: commandId,
            kind: kind,
            issuedAt: issuedAt,
            sportModeKey: "inline-skate"
        )
        return WatchBridgeEnvelope(
            messageId: messageId,
            createdAt: issuedAt,
            source: .appleWatch,
            destination: .iPhone,
            payload: .command(command)
        )
    }

    private static func reachableState(at date: Date = Date(timeIntervalSince1970: 120)) -> WatchBridgeConnectionState {
        WatchBridgeConnectionState(
            status: .reachable,
            quality: .fresh,
            lastUpdatedAt: date,
            lastReceivedMessageAt: date,
            explanation: "reachable command safety test state"
        )
    }

    private func XCTAssertCommandResult(
        _ roundTrip: WatchBridgeMirroredCommandRoundTrip,
        result: WatchBridgeCommandResult,
        correlationId: UUID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(roundTrip.acknowledgementEnvelope.correlationId, correlationId, file: file, line: line)
        XCTAssertEqual(roundTrip.acknowledgementEnvelope.source, .iPhone, file: file, line: line)
        XCTAssertEqual(roundTrip.acknowledgementEnvelope.destination, .appleWatch, file: file, line: line)
        guard case .commandResult(let payload) = roundTrip.acknowledgementEnvelope.payload else {
            XCTFail("Expected command result payload", file: file, line: line)
            return
        }
        XCTAssertEqual(payload.result, result, file: file, line: line)
    }

    private func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}

private final class SafetyRecordingAuthority: WatchBridgeMirroredSessionCommandAuthority {
    private let decision: WatchBridgeMirroredCommandAuthorityDecision
    private(set) var callCount = 0

    init(decision: WatchBridgeMirroredCommandAuthorityDecision) {
        self.decision = decision
    }

    func validate(
        _ request: WatchBridgeMirroredCommandRequest,
        action: WatchBridgeMirroredSessionCommandAction,
        at date: Date
    ) -> WatchBridgeMirroredCommandAuthorityDecision {
        callCount += 1
        return decision
    }
}
