// [協作區] WatchSnowLaunchRouterTests.swift
// Purpose: Verifies the Watch Snow mock-gallery launch route remains DEBUG-only and opt-in.

import XCTest
@testable import SkateTrack_iOS

final class WatchSnowLaunchRouterTests: XCTestCase {
    func testDefaultLaunchPreservesMainlineRoot() {
        XCTAssertEqual(
            WatchSnowLaunchRouter.resolve(arguments: [], isDebugBuild: true),
            .mainline
        )
    }

    #if DEBUG
    func testDebugLaunchArgumentOpensSnowMockGallery() {
        XCTAssertEqual(
            WatchSnowLaunchRouter.resolve(
                arguments: ["SkateTrack-watchOS", WatchSnowLaunchRouter.mockGalleryArgument],
                isDebugBuild: true
            ),
            .snowMockGallery
        )
    }

    func testReleaseDecisionIgnoresMockGalleryArgument() {
        XCTAssertEqual(
            WatchSnowLaunchRouter.resolve(
                arguments: [WatchSnowLaunchRouter.mockGalleryArgument],
                isDebugBuild: false
            ),
            .mainline
        )
    }
    #endif
}
