// [協作區] Tests/iOSTests/WatchMetricProviderTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchMetricProviderTests: XCTestCase {
    func testBaseProviderSelectedForSkateboardAndUsesCompactOutputs() {
        let viewModel = Self.viewModel(
            sportModeKey: "skateboard",
            compactSummary: Self.compactSummary()
        )

        let selection = WatchMetricProviderSelector().makeSelection(for: viewModel)

        XCTAssertEqual(selection.activityMode, .skateboard)
        XCTAssertTrue(selection.hasProvider)
        XCTAssertEqual(selection.providerIdentifier, "watch.metric.provider.base")
        XCTAssertEqual(selection.outputs.map(\.kind), [.route, .speed, .elevation])
        XCTAssertTrue(selection.outputs.allSatisfy(\.isRenderable))
        XCTAssertEqual(selection.outputs.first { $0.kind == .route }?.source, .compactRouteDisplay)
        XCTAssertEqual(selection.outputs.first { $0.kind == .speed }?.source, .compactSpeedSparkline)
        XCTAssertEqual(selection.outputs.first { $0.kind == .elevation }?.source, .compactElevationProfile)
        XCTAssertEqual(
            selection.outputs.first { $0.kind == .speed }?.speedSparkline?.points ?? [],
            Self.compactSummary().speedSparkline.points
        )
        XCTAssertEqual(
            selection.outputs.first { $0.kind == .elevation }?.elevationProfile?.points ?? [],
            Self.compactSummary().elevationProfile.points
        )
    }

    func testBaseProviderSelectedForInlineWithUnavailableOutputsWhenCompactDataIsMissing() {
        let viewModel = Self.viewModel(sportModeKey: "inline")

        let selection = WatchMetricProviderSelector().makeSelection(for: viewModel)

        XCTAssertEqual(selection.activityMode, .inline)
        XCTAssertEqual(selection.providerIdentifier, "watch.metric.provider.base")
        XCTAssertEqual(selection.outputs.map(\.kind), [.route, .speed, .elevation, .cadence])
        XCTAssertTrue(selection.outputs.allSatisfy { output in
            output.availability == .unavailable(.missingCompactOutput)
        })
        XCTAssertTrue(selection.outputs.allSatisfy { $0.source == .unavailable })
        XCTAssertEqual(
            selection.outputs.first { $0.kind == .cadence }?.titleLocalizationKey,
            "session.hud.inline.cadence"
        )
    }

    func testInlineCadenceStaysUnavailableEvenWhenCompactSpeedAndElevationExist() {
        let viewModel = Self.viewModel(
            sportModeKey: "inline",
            compactSummary: Self.compactSummary()
        )

        let selection = WatchMetricProviderSelector().makeSelection(for: viewModel)
        let cadence = selection.outputs.first { $0.kind == .cadence }

        XCTAssertEqual(selection.outputs.map(\.kind), [.route, .speed, .elevation, .cadence])
        XCTAssertEqual(cadence?.availability, .unavailable(.missingCompactOutput))
        XCTAssertEqual(cadence?.source, .unavailable)
        XCTAssertNil(cadence?.speedSparkline)
        XCTAssertNil(cadence?.elevationProfile)
        XCTAssertNil(cadence?.compactRoute)
    }

    func testDefaultPreparationModeKeepsBaseProviderWithUnavailableOutputs() {
        let selection = WatchMetricProviderSelector().makeSelection(
            for: WatchActivityViewModel(generatedAt: Self.baseDate)
        )

        XCTAssertEqual(selection.activityMode, .skateboard)
        XCTAssertEqual(selection.providerIdentifier, "watch.metric.provider.base")
        XCTAssertEqual(selection.outputs.map(\.kind), [.route, .speed, .elevation])
        XCTAssertTrue(selection.outputs.allSatisfy { output in
            output.availability == .unavailable(.missingCompactOutput)
        })
    }

    func testUnsupportedModeHasNoProviderAndReturnsSafeUnavailableState() {
        let viewModel = Self.viewModel(sportModeKey: "future_mode")

        let selection = WatchMetricProviderSelector().makeSelection(for: viewModel)

        XCTAssertEqual(selection.activityMode, .unsupported(rawValue: "future_mode"))
        XCTAssertFalse(selection.hasProvider)
        XCTAssertNil(selection.providerIdentifier)
        XCTAssertEqual(selection.outputs, [])
        XCTAssertEqual(selection.availability, .unsupportedMode("future_mode"))
    }

    func testCustomProviderCanSupportFutureModeWithoutChangingBaseProvider() {
        let viewModel = Self.viewModel(sportModeKey: "future_mode")
        let selector = WatchMetricProviderSelector(providers: [FutureModeMetricProvider()])

        let selection = selector.makeSelection(for: viewModel)

        XCTAssertEqual(selection.providerIdentifier, "watch.metric.provider.future.stub")
        XCTAssertEqual(selection.outputs.count, 1)
        XCTAssertEqual(selection.outputs[0].availability, .unavailable(.missingCompactOutput))
        XCTAssertFalse(WatchBaseMetricProvider().supports(activityMode: .unsupported(rawValue: "future_mode")))
    }

    func testDisabledProviderFallbackDisablesMetricOutputs() {
        let viewModel = Self.viewModel(
            sportModeKey: "skateboard",
            sensorSnapshot: WatchSensorProviderSnapshot(
                providerKind: .disabled,
                availability: .disabled(at: Self.baseDate, explanation: "disabled for this build"),
                capturedAt: Self.baseDate,
                samples: []
            ),
            compactSummary: Self.compactSummary()
        )

        let selection = WatchMetricProviderSelector().makeSelection(for: viewModel)

        XCTAssertEqual(selection.providerIdentifier, "watch.metric.provider.base")
        XCTAssertEqual(selection.outputs.count, 3)
        XCTAssertTrue(selection.outputs.allSatisfy { output in
            output.availability == .disabled(.providerDisabled)
        })
    }

    func testStaleBridgeMakesOutputsUnavailableEvenWhenCompactDataExists() {
        let viewModel = Self.viewModel(
            sportModeKey: "skateboard",
            connectionQuality: .stale,
            compactSummary: Self.compactSummary()
        )

        let selection = WatchMetricProviderSelector().makeSelection(for: viewModel)

        XCTAssertEqual(selection.providerIdentifier, "watch.metric.provider.base")
        XCTAssertTrue(selection.outputs.allSatisfy { output in
            output.availability == .unavailable(.staleData)
        })
    }


    func testLockedEntitlementBoundaryLocksConfiguredMetricWithoutProductionDependency() {
        let viewModel = Self.viewModel(
            sportModeKey: "skateboard",
            compactSummary: Self.compactSummary()
        )

        let selection = WatchMetricProviderSelector().makeSelection(
            for: viewModel,
            entitlementBoundary: .freeLocked(metricIdentifiers: ["watch.metric.speed"])
        )
        let route = selection.outputs.first { $0.kind == .route }
        let speed = selection.outputs.first { $0.kind == .speed }
        let elevation = selection.outputs.first { $0.kind == .elevation }

        XCTAssertEqual(selection.providerIdentifier, "watch.metric.provider.base")
        XCTAssertEqual(route?.availability, .available)
        XCTAssertEqual(speed?.availability, .locked(.lockedByEntitlementBoundary))
        XCTAssertEqual(speed?.source, .unavailable)
        XCTAssertNil(speed?.speedSparkline)
        XCTAssertNil(speed?.compactRoute)
        XCTAssertNil(speed?.elevationProfile)
        XCTAssertEqual(elevation?.availability, .available)
    }

    func testSubscriberEntitlementBoundaryLeavesMetricUnlocked() {
        let viewModel = Self.viewModel(
            sportModeKey: "skateboard",
            compactSummary: Self.compactSummary()
        )

        let selection = WatchMetricProviderSelector().makeSelection(
            for: viewModel,
            entitlementBoundary: .subscriberUnlocked(lockedMetricIdentifiers: ["watch.metric.speed"])
        )
        let speed = selection.outputs.first { $0.kind == .speed }

        XCTAssertEqual(speed?.availability, .available)
        XCTAssertEqual(speed?.source, .compactSpeedSparkline)
        XCTAssertNotNil(speed?.speedSparkline)
    }

    func testDisabledProviderFallbackIsNotOverriddenByEntitlementBoundary() {
        let viewModel = Self.viewModel(
            sportModeKey: "skateboard",
            sensorSnapshot: WatchSensorProviderSnapshot(
                providerKind: .disabled,
                availability: .disabled(at: Self.baseDate, explanation: "disabled for this build"),
                capturedAt: Self.baseDate,
                samples: []
            ),
            compactSummary: Self.compactSummary()
        )

        let selection = WatchMetricProviderSelector().makeSelection(
            for: viewModel,
            entitlementBoundary: .freeLocked(metricIdentifiers: ["watch.metric.speed"])
        )

        XCTAssertEqual(selection.outputs.first { $0.kind == .speed }?.availability, .disabled(.providerDisabled))
        XCTAssertTrue(selection.outputs.allSatisfy { output in
            output.availability == .disabled(.providerDisabled)
        })
    }

    private struct FutureModeMetricProvider: WatchMetricProviding {
        let providerIdentifier = "watch.metric.provider.future.stub"

        func supports(activityMode: WatchMetricActivityMode) -> Bool {
            if case .unsupported(rawValue: "future_mode") = activityMode { return true }
            return false
        }

        func makeMetricOutputs(context: WatchMetricProviderContext) -> [WatchMetricProviderOutput] {
            [
                WatchMetricProviderOutput(
                    identifier: "watch.metric.future.stub",
                    kind: .route,
                    titleLocalizationKey: "watch.compact.route.title",
                    accessibilityIdentifier: "watch-metric-provider-future-stub",
                    availability: .unavailable(.missingCompactOutput),
                    source: .unavailable,
                    compactRoute: nil,
                    speedSparkline: nil,
                    elevationProfile: nil
                )
            ]
        }
    }

    private static let baseDate = Date(timeIntervalSince1970: 7_000)

    private static func viewModel(
        sportModeKey: String,
        connectionQuality: WatchBridgeTransportQuality = .fresh,
        sensorSnapshot: WatchSensorProviderSnapshot? = nil,
        compactSummary: ActivityVisualizationCompactSummary? = nil
    ) -> WatchActivityViewModel {
        WatchActivityViewModel(
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: WatchBridgeConnectionState(
                    status: .reachable,
                    quality: connectionQuality,
                    lastUpdatedAt: baseDate,
                    lastReceivedMessageAt: baseDate,
                    explanation: "test"
                ),
                reportedAt: baseDate,
                canSendCommands: true,
                canReceiveSnapshots: true
            ),
            session: WatchBridgeActivitySessionPayload(
                sessionId: UUID(uuidString: "00000000-0000-0000-0000-000000000037"),
                state: .recording,
                mode: WatchBridgeActivityModeDescriptor(sportModeKey: sportModeKey),
                startedAt: baseDate,
                updatedAt: baseDate,
                elapsedSeconds: 37,
                isRecordingAllowed: true,
                statusLabel: "recording"
            ),
            sensorSnapshot: sensorSnapshot,
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
                    )
                ],
                quality: .usable,
                segmentCount: 1
            ),
            speedSparkline: CompactSpeedSparkline(
                points: [
                    CompactSparklinePoint(
                        id: 1,
                        elapsedSeconds: 1,
                        value: 12,
                        normalizedValue: 1,
                        segmentID: 0
                    )
                ],
                quality: .usable,
                maximumSpeedKilometersPerHour: 12,
                segmentCount: 1
            ),
            elevationProfile: CompactElevationProfile(
                points: [
                    CompactSparklinePoint(
                        id: 1,
                        elapsedSeconds: 1,
                        value: 100,
                        normalizedValue: 0.5,
                        segmentID: 0
                    )
                ],
                quality: .usable,
                displayDerivedTotalAscentMeters: 4,
                selectedSource: .motionSample,
                segmentCount: 1
            )
        )
    }
}
