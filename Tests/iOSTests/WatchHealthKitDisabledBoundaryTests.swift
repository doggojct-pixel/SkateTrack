// [協作區] Tests/iOSTests/WatchHealthKitDisabledBoundaryTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchHealthKitDisabledBoundaryTests: XCTestCase {
    func testDisabledBoundaryReportsProductionAccessOff() {
        let provider = WatchHealthKitDisabledProvider()
        let date = Date(timeIntervalSince1970: 300)

        let boundary = provider.boundaryAvailability(at: date)

        XCTAssertFalse(provider.isProductionAccessEnabled)
        XCTAssertEqual(boundary.state, .disabled)
        XCTAssertEqual(boundary.reason, .notEnabledForThisBuild)
        XCTAssertEqual(boundary.checkedAt, date)
        XCTAssertFalse(boundary.canRequestProductionAccess)
    }

    func testDisabledBoundaryReturnsNoWatchSensorSamples() {
        let provider = WatchHealthKitDisabledProvider()
        let date = Date(timeIntervalSince1970: 301)

        let availability = provider.availability(at: date)
        let snapshot = provider.snapshot(at: date, maximumSampleCount: 20)

        XCTAssertEqual(provider.kind, .disabled)
        XCTAssertEqual(availability.status, .disabled)
        XCTAssertEqual(availability.reason, .providerDisabled)
        XCTAssertFalse(availability.canProvideWatchOriginatedData)
        XCTAssertFalse(snapshot.isUsable)
        XCTAssertEqual(snapshot.sampleCount, 0)
        XCTAssertTrue(snapshot.samples.isEmpty)
    }

    func testDisabledCopyAvoidsRestrictedClaims() {
        let copy = [
            WatchHealthKitCopy.disabledTitle,
            WatchHealthKitCopy.disabledExplanation,
            WatchHealthKitCopy.capabilityNotice,
            WatchHealthKitCopy.nonClinicalNotice
        ].joined(separator: " ").lowercased()

        let restrictedPhrases = [
            "health " + "monitoring",
            "med" + "ical",
            "diagn" + "osis",
            "heart " + "rate",
            "background health " + "collection"
        ]

        for phrase in restrictedPhrases {
            XCTAssertFalse(copy.contains(phrase))
        }
    }
}
