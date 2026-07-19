// [協作區] SnowLiveSessionConfigTests.swift
import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SnowLiveSessionConfigTests: XCTestCase {
    func testProductionLowConfidenceThresholdUsesClassifierMediumConfidenceBoundary() {
        XCTAssertEqual(
            SnowLiveSessionConfig.productionV0.lowConfidenceThreshold,
            SnowClassifierConfig.productionV0.mediumConfidenceThreshold
        )
    }

    func testProductionConfigTreatsUnknownAsLowConfidence() {
        XCTAssertTrue(SnowLiveSessionConfig.productionV0.lowConfidenceAlwaysForUnknown)
    }

    func testProductionConfigIncludesKnownClassifierReasonCodes() {
        let reasonCodes = SnowLiveSessionConfig.productionV0.lowConfidenceReasonCodes
        XCTAssertTrue(reasonCodes.contains("missingAltitude"))
        XCTAssertTrue(reasonCodes.contains("insufficientSamples"))
        XCTAssertTrue(reasonCodes.contains("noRuleMatched"))
        XCTAssertTrue(reasonCodes.contains("ambiguousGondolaLikeDescent"))
    }
}
