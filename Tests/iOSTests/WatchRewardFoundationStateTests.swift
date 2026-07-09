// [協作區] Tests/iOSTests/WatchRewardFoundationStateTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchRewardFoundationStateTests: XCTestCase {
    func testLocalShellIsNonMonetizedAndLocalOnly() {
        let generatedAt = Date(timeIntervalSince1970: 1_600)
        let state = WatchRewardFoundationState.localShell(generatedAt: generatedAt)

        XCTAssertEqual(state.generatedAt, generatedAt)
        XCTAssertEqual(state.availability, .localShellOnly)
        XCTAssertTrue(state.hasLocalEntries)
        XCTAssertTrue(state.isLocalOnly)
        XCTAssertFalse(state.usesMonetizationFramework)
        XCTAssertFalse(state.usesProductionMonetization)
        XCTAssertFalse(state.grantsEntitlement)
        XCTAssertFalse(state.unlocksPaidFeatures)
        XCTAssertFalse(state.exposesReleaseClaim)
        XCTAssertFalse(state.syncsRemoteRewardState)
    }

    func testDefaultEntriesArePresentAndUnearned() {
        let state = WatchRewardFoundationState.localShell()
        let kinds = state.entries.map(\.kind)

        XCTAssertEqual(kinds, [.firstSession, .steadyWeek, .safetyReview])
        XCTAssertTrue(state.entries.allSatisfy { $0.isEarned == false })
        XCTAssertTrue(state.entries.allSatisfy { $0.localProgress == 0 })
    }

    func testProgressIsClampedToLocalDisplayRange() {
        let below = WatchRewardFoundationEntry(kind: .firstSession, localProgress: -1)
        let above = WatchRewardFoundationEntry(kind: .steadyWeek, localProgress: 2)
        let invalid = WatchRewardFoundationEntry(kind: .safetyReview, localProgress: .nan)

        XCTAssertEqual(below.localProgress, 0)
        XCTAssertEqual(above.localProgress, 1)
        XCTAssertEqual(invalid.localProgress, 0)
    }

    func testCodableRoundTripPreservesLocalState() throws {
        let state = WatchRewardFoundationState.localShell(
            generatedAt: Date(timeIntervalSince1970: 1_700)
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(WatchRewardFoundationState.self, from: data)

        XCTAssertEqual(decoded, state)
        XCTAssertFalse(decoded.usesMonetizationFramework)
        XCTAssertFalse(decoded.usesProductionMonetization)
    }
}
