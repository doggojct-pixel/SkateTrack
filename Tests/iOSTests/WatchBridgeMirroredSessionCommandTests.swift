// [協作區] Tests/iOSTests/WatchBridgeMirroredSessionCommandTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchBridgeMirroredSessionCommandTests: XCTestCase {
    func testProcessorAcceptsWatchStartAfterIPhoneAuthorityValidation() {
        let sessionId = UUID(uuidString: "00000000-0000-0000-0000-000000000701")!
        let authority = RecordingAuthority(decision: .accept(sessionId: sessionId))
        var processor = WatchBridgeMirroredCommandProcessor(authority: authority)
        let envelope = makeEnvelope(kind: .startSession, commandId: uuid(1), messageId: uuid(101))

        let roundTrip = processor.processEnvelope(
            envelope,
            receivedAt: Date(timeIntervalSince1970: 120),
            decidedAt: Date(timeIntervalSince1970: 121)
        )

        XCTAssertEqual(roundTrip.decision.state, .accepted)
        XCTAssertEqual(roundTrip.decision.action, .start)
        XCTAssertEqual(roundTrip.decision.sessionId, sessionId)
        XCTAssertEqual(authority.callCount, 1)
        XCTAssertTrue(processor.completedCommandIds.contains(uuid(1)))
        XCTAssertCommandResult(roundTrip, result: .accepted, correlationId: uuid(101))
    }

    func testProcessorRejectsStaleCommandBeforeAuthorityValidation() {
        let authority = RecordingAuthority(decision: .accept())
        var processor = WatchBridgeMirroredCommandProcessor(
            authority: authority,
            policy: WatchBridgeMirroredSessionCommandPolicy(maximumCommandAgeSeconds: 10)
        )
        let envelope = makeEnvelope(
            kind: .startSession,
            commandId: uuid(2),
            messageId: uuid(102),
            issuedAt: Date(timeIntervalSince1970: 100)
        )

        let roundTrip = processor.processEnvelope(
            envelope,
            receivedAt: Date(timeIntervalSince1970: 130),
            decidedAt: Date(timeIntervalSince1970: 130)
        )

        XCTAssertEqual(roundTrip.decision.state, .stale)
        XCTAssertEqual(roundTrip.decision.rejectionReason, .staleCommand)
        XCTAssertEqual(authority.callCount, 0)
        XCTAssertCommandResult(roundTrip, result: .rejected, correlationId: uuid(102))
    }

    func testProcessorIgnoresDuplicateCommandWithoutSecondAuthorityCall() {
        let authority = RecordingAuthority(decision: .accept())
        var processor = WatchBridgeMirroredCommandProcessor(authority: authority)
        let envelope = makeEnvelope(kind: .startSession, commandId: uuid(3), messageId: uuid(103))

        _ = processor.processEnvelope(envelope, decidedAt: Date(timeIntervalSince1970: 140))
        let duplicate = processor.processEnvelope(envelope, decidedAt: Date(timeIntervalSince1970: 145))

        XCTAssertEqual(duplicate.decision.state, .duplicate)
        XCTAssertEqual(duplicate.decision.rejectionReason, .duplicateCommand)
        XCTAssertEqual(authority.callCount, 1)
        XCTAssertCommandResult(duplicate, result: .ignored, correlationId: uuid(103))
    }

    func testProcessorRejectsPauseWithoutAuthoritativeSessionId() {
        let authority = RecordingAuthority(decision: .accept())
        var processor = WatchBridgeMirroredCommandProcessor(authority: authority)
        let envelope = makeEnvelope(kind: .pauseSession, commandId: uuid(4), messageId: uuid(104))

        let roundTrip = processor.processEnvelope(envelope, decidedAt: Date(timeIntervalSince1970: 150))

        XCTAssertEqual(roundTrip.decision.state, .rejected)
        XCTAssertEqual(roundTrip.decision.action, .pause)
        XCTAssertEqual(roundTrip.decision.rejectionReason, .missingSessionId)
        XCTAssertEqual(authority.callCount, 0)
        XCTAssertCommandResult(roundTrip, result: .rejected, correlationId: uuid(104))
    }

    func testProcessorRejectsNonWatchInitiatedCommandDirection() {
        let authority = RecordingAuthority(decision: .accept())
        var processor = WatchBridgeMirroredCommandProcessor(authority: authority)
        let command = WatchBridgeCommandEnvelope(
            commandId: uuid(5),
            kind: .startSession,
            issuedAt: Date(timeIntervalSince1970: 160)
        )
        let envelope = WatchBridgeEnvelope(
            messageId: uuid(105),
            createdAt: Date(timeIntervalSince1970: 160),
            source: .iPhone,
            destination: .appleWatch,
            payload: .command(command)
        )

        let roundTrip = processor.processEnvelope(envelope, decidedAt: Date(timeIntervalSince1970: 161))

        XCTAssertEqual(roundTrip.decision.state, .rejected)
        XCTAssertEqual(roundTrip.decision.rejectionReason, .invalidDirection)
        XCTAssertEqual(authority.callCount, 0)
        XCTAssertCommandResult(roundTrip, result: .rejected, correlationId: uuid(105))
    }

    private func makeEnvelope(
        kind: WatchBridgeCommandKind,
        commandId: UUID,
        messageId: UUID,
        sessionId: UUID? = nil,
        issuedAt: Date = Date(timeIntervalSince1970: 120)
    ) -> WatchBridgeEnvelope {
        let command = WatchBridgeCommandEnvelope(
            commandId: commandId,
            kind: kind,
            issuedAt: issuedAt,
            sessionId: sessionId,
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

private final class RecordingAuthority: WatchBridgeMirroredSessionCommandAuthority {
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
