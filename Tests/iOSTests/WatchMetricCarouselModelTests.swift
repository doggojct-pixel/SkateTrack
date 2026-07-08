// [協作區] Tests/iOSTests/WatchMetricCarouselModelTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchMetricCarouselModelTests: XCTestCase {
    func testCarouselModelUsesCompactSpeedAndElevationProviderOutputs() {
        let selection = WatchMetricProviderSelector().makeSelection(
            for: Self.viewModel(sportModeKey: "skateboard", compactSummary: Self.compactSummary())
        )

        let model = WatchMetricCarouselModel(selection: selection)
        let speed = model.cards.first { $0.kind == .speed }
        let elevation = model.cards.first { $0.kind == .elevation }

        XCTAssertEqual(model.cards.map(\.kind), [.route, .speed, .elevation])
        XCTAssertTrue(model.hasRenderableCompactSpeed)
        XCTAssertTrue(model.hasRenderableCompactElevation)
        XCTAssertEqual(speed?.source, .compactSpeedSparkline)
        XCTAssertEqual(elevation?.source, .compactElevationProfile)
        XCTAssertEqual(speed?.sparklinePoints, Self.compactSummary().speedSparkline.points)
        XCTAssertEqual(elevation?.sparklinePoints, Self.compactSummary().elevationProfile.points)
        XCTAssertEqual(speed?.valueText, "18.4")
        XCTAssertEqual(elevation?.valueText, "7")
    }

    func testCarouselModelShowsUnavailableStateWhenCompactDataIsMissing() {
        let selection = WatchMetricProviderSelector().makeSelection(
            for: Self.viewModel(sportModeKey: "inline")
        )

        let model = WatchMetricCarouselModel(selection: selection)

        XCTAssertEqual(model.cards.map(\.kind), [.route, .speed, .elevation, .cadence])
        XCTAssertFalse(model.hasRenderableCompactSpeed)
        XCTAssertFalse(model.hasRenderableCompactElevation)
        XCTAssertTrue(model.cards.allSatisfy { $0.displayState == .unavailable })
        XCTAssertTrue(model.cards.allSatisfy { $0.detailLocalizationKey == "watch.metric.card.unavailable" })
        XCTAssertTrue(model.cards.allSatisfy { $0.valueText == "--" })
        XCTAssertTrue(model.cards.allSatisfy { $0.sparklinePoints.isEmpty })
        XCTAssertNil(model.cards.first { $0.kind == .cadence }?.unitLocalizationKey)
    }

    func testInlineCadenceCardAvoidsFalsePrecisionWhenCompactDataExists() {
        let selection = WatchMetricProviderSelector().makeSelection(
            for: Self.viewModel(sportModeKey: "inline", compactSummary: Self.compactSummary())
        )

        let model = WatchMetricCarouselModel(selection: selection)
        let cadence = model.cards.first { $0.kind == .cadence }

        XCTAssertEqual(model.cards.map(\.kind), [.route, .speed, .elevation, .cadence])
        XCTAssertEqual(cadence?.titleLocalizationKey, "session.hud.inline.cadence")
        XCTAssertEqual(cadence?.displayState, .unavailable)
        XCTAssertEqual(cadence?.detailLocalizationKey, "watch.metric.card.unavailable")
        XCTAssertEqual(cadence?.valueText, "--")
        XCTAssertNil(cadence?.unitLocalizationKey)
        XCTAssertTrue(cadence?.sparklinePoints.isEmpty == true)
    }

    func testCarouselModelKeepsSafeCardsForDefaultPreparationViewModel() {
        let selection = WatchMetricProviderSelector().makeSelection(
            for: WatchActivityViewModel(generatedAt: Self.baseDate)
        )

        let model = WatchMetricCarouselModel(selection: selection)

        XCTAssertTrue(model.hasCards)
        XCTAssertEqual(model.cards.map(\.kind), [.route, .speed, .elevation])
        XCTAssertEqual(model.cards.map(\.valueText), ["--", "--", "--"])
        XCTAssertTrue(model.cards.allSatisfy { $0.displayState == .unavailable })
        XCTAssertFalse(model.hasRenderableCompactSpeed)
        XCTAssertFalse(model.hasRenderableCompactElevation)
    }

    func testCarouselModelPreservesLockedProviderOutputWithoutStoreKitDependency() {
        let output = WatchMetricProviderOutput(
            identifier: "watch.metric.locked.speed",
            kind: .speed,
            titleLocalizationKey: "watch.compact.speed.title",
            accessibilityIdentifier: "watch-metric-provider-locked-speed",
            availability: .locked(.lockedByEntitlementBoundary),
            source: .unavailable,
            compactRoute: nil,
            speedSparkline: Self.compactSummary().speedSparkline,
            elevationProfile: nil
        )
        let selection = WatchMetricProviderSelectionResult(
            activityMode: .skateboard,
            providerIdentifier: "watch.metric.provider.locked.stub",
            outputs: [output],
            availability: .available
        )

        let model = WatchMetricCarouselModel(selection: selection)

        XCTAssertEqual(model.cards.count, 1)
        XCTAssertEqual(model.cards[0].displayState, .locked)
        XCTAssertEqual(model.cards[0].detailLocalizationKey, "watch.metric.card.locked")
        XCTAssertEqual(model.cards[0].valueText, "--")
        XCTAssertTrue(model.cards[0].sparklinePoints.isEmpty)
    }

    func testCarouselModelKeepsUnsupportedModeEmptyAndSafe() {
        let selection = WatchMetricProviderSelector().makeSelection(
            for: Self.viewModel(sportModeKey: "future_mode")
        )

        let model = WatchMetricCarouselModel(selection: selection)

        XCTAssertFalse(model.hasCards)
        XCTAssertEqual(model.cards, [])
        XCTAssertEqual(model.selectionAvailability, .unsupportedMode("future_mode"))
        XCTAssertNil(model.providerIdentifier)
    }

    private static let baseDate = Date(timeIntervalSince1970: 7_001)

    private static func viewModel(
        sportModeKey: String,
        compactSummary: ActivityVisualizationCompactSummary? = nil
    ) -> WatchActivityViewModel {
        WatchActivityViewModel(
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: WatchBridgeConnectionState(
                    status: .reachable,
                    quality: .fresh,
                    lastUpdatedAt: baseDate,
                    lastReceivedMessageAt: baseDate,
                    explanation: "test"
                ),
                reportedAt: baseDate,
                canSendCommands: true,
                canReceiveSnapshots: true
            ),
            session: WatchBridgeActivitySessionPayload(
                sessionId: UUID(uuidString: "00000000-0000-0000-0000-000000000137"),
                state: .recording,
                mode: WatchBridgeActivityModeDescriptor(sportModeKey: sportModeKey),
                startedAt: baseDate,
                updatedAt: baseDate,
                elapsedSeconds: 37,
                isRecordingAllowed: true,
                statusLabel: "recording"
            ),
            compactSummary: compactSummary,
            generatedAt: baseDate
        )
    }

    private static func compactSummary() -> ActivityVisualizationCompactSummary {
        ActivityVisualizationCompactSummary(
            routeQuality: .usable,
            speedQuality: .usable,
            elevationQuality: .usable,
            routeDisplayPointCount: 2,
            speedDisplayPointCount: 2,
            elevationDisplayPointCount: 2,
            routeSegmentCount: 1,
            speedSegmentCount: 1,
            elevationSegmentCount: 1,
            selectedElevationSource: .motionSample,
            compactRoute: CompactRouteDisplay(
                points: [
                    CompactRoutePoint(
                        id: 1,
                        elapsedSeconds: 1,
                        coordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
                        semantic: .highConfidence
                    ),
                    CompactRoutePoint(
                        id: 2,
                        elapsedSeconds: 2,
                        coordinate: GeoCoordinate(latitude: 25.034, longitude: 121.566),
                        semantic: .highConfidence
                    ),
                ],
                quality: .usable,
                segmentCount: 1
            ),
            speedSparkline: CompactSpeedSparkline(
                points: [
                    CompactSparklinePoint(
                        id: 1,
                        elapsedSeconds: 1,
                        value: 12.2,
                        normalizedValue: 0.2,
                        segmentID: 0
                    ),
                    CompactSparklinePoint(
                        id: 2,
                        elapsedSeconds: 2,
                        value: 18.4,
                        normalizedValue: 1,
                        segmentID: 0
                    ),
                ],
                quality: .usable,
                maximumSpeedKilometersPerHour: 18.4,
                segmentCount: 1
            ),
            elevationProfile: CompactElevationProfile(
                points: [
                    CompactSparklinePoint(
                        id: 1,
                        elapsedSeconds: 1,
                        value: 100,
                        normalizedValue: 0.2,
                        segmentID: 0
                    ),
                    CompactSparklinePoint(
                        id: 2,
                        elapsedSeconds: 2,
                        value: 106.8,
                        normalizedValue: 1,
                        segmentID: 0
                    ),
                ],
                quality: .usable,
                displayDerivedTotalAscentMeters: 6.8,
                selectedSource: .motionSample,
                segmentCount: 1
            )
        )
    }
}
