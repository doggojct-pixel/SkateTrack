// [Collaboration] Tests/iOSTests/WatchActivityViewModelTests.swift

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class WatchActivityViewModelTests: XCTestCase {
    func testDefaultStateIsIdleUnknownAndDisplayEmpty() {
        let generatedAt = Date(timeIntervalSince1970: 1_000)
        let viewModel = WatchActivityViewModel(generatedAt: generatedAt)

        XCTAssertEqual(viewModel.generatedAt, generatedAt)
        XCTAssertEqual(viewModel.connection.status, .unknown)
        XCTAssertEqual(viewModel.connection.quality, .unknown)
        XCTAssertFalse(viewModel.connection.canSendCommands)
        XCTAssertEqual(viewModel.session.state, .idle)
        XCTAssertFalse(viewModel.session.isActive)
        XCTAssertEqual(viewModel.metrics.trustLevel, .unknown)
        XCTAssertEqual(viewModel.samples.availabilityStatus, .unavailable)
        XCTAssertEqual(viewModel.samples.rawSampleCount, 0)
        XCTAssertFalse(viewModel.compactSummary.hasAnyDisplayData)
        XCTAssertTrue(viewModel.compactSummary.displayOnly)
    }

    func testSnapshotBuildsConnectionSessionMetricsSamplesAndCompactSummaryState() {
        let sessionId = Self.uuid(1)
        let baseDate = Date(timeIntervalSince1970: 2_000)
        let connectionState = WatchBridgeConnectionState(
            status: .reachable,
            quality: .fresh,
            lastUpdatedAt: baseDate,
            lastReceivedMessageAt: baseDate.addingTimeInterval(1),
            explanation: "reachable"
        )
        let snapshot = WatchBridgeActivitySnapshotPayload(
            session: WatchBridgeActivitySessionPayload(
                sessionId: sessionId,
                state: .recording,
                mode: WatchBridgeActivityModeDescriptor(sportModeKey: "skateboard"),
                startedAt: baseDate,
                updatedAt: baseDate.addingTimeInterval(40),
                elapsedSeconds: 40,
                isRecordingAllowed: true,
                statusLabel: "recording"
            ),
            metrics: WatchBridgeMetricUpdatePayload(
                sessionId: sessionId,
                updatedAt: baseDate.addingTimeInterval(40),
                elapsedSeconds: 40,
                distanceMeters: 120,
                currentSpeedMetersPerSecond: 4.2,
                averageSpeedMetersPerSecond: 3.0,
                elevationGainMeters: 5,
                elevationLossMeters: 1,
                trustLevel: .displayOnlyProjection,
                sourceLabel: "watch"
            ),
            display: WatchBridgeCompactActivityDisplayPayload(
                generatedAt: baseDate.addingTimeInterval(41),
                routePointCount: 3,
                speedSampleCount: 2,
                elevationSampleCount: 2,
                hasCompactRoute: true,
                hasSpeedSparkline: true,
                hasElevationProfile: true,
                qualityLabel: "usable",
                displayOnly: true
            ),
            connectionStatus: WatchBridgeConnectionStatusPayload(
                state: connectionState,
                reportedAt: baseDate.addingTimeInterval(42),
                canSendCommands: true,
                canReceiveSnapshots: true
            )
        )
        let sensorSnapshot = Self.sensorSnapshot(capturedAt: baseDate.addingTimeInterval(39))
        let ingestion = WatchSampleIngestor().ingest(snapshot: sensorSnapshot)
        let fusion = WatchSampleFusionEngine().makeDisplayFusion(
            iPhoneSamples: [],
            watchSamples: ingestion.samples
        )
        let compactSummary = Self.compactSummary()

        let viewModel = WatchActivityViewModel(
            snapshot: snapshot,
            sensorSnapshot: sensorSnapshot,
            ingestion: ingestion,
            fusion: fusion,
            compactSummary: compactSummary,
            generatedAt: baseDate.addingTimeInterval(43)
        )

        XCTAssertTrue(viewModel.connection.isReachable)
        XCTAssertTrue(viewModel.connection.canSendCommands)
        XCTAssertEqual(viewModel.session.sessionId, sessionId)
        XCTAssertEqual(viewModel.session.state, .recording)
        XCTAssertTrue(viewModel.session.isActive)
        XCTAssertEqual(viewModel.session.elapsedSeconds, 40)
        XCTAssertEqual(viewModel.metrics.distanceMeters, 120)
        XCTAssertEqual(viewModel.metrics.trustLevel, .displayOnlyProjection)
        XCTAssertFalse(viewModel.metrics.isTrustedSource)
        XCTAssertEqual(viewModel.samples.providerKind, .mock)
        XCTAssertEqual(viewModel.samples.rawSampleCount, 1)
        XCTAssertEqual(viewModel.samples.ingestedSampleCount, 1)
        XCTAssertEqual(viewModel.samples.displayDerivedPointCount, 1)
        XCTAssertEqual(viewModel.compactSummary.routePointCount, 12)
        XCTAssertEqual(viewModel.compactSummary.speedPointCount, 8)
        XCTAssertEqual(viewModel.compactSummary.elevationPointCount, 6)
        XCTAssertEqual(viewModel.compactSummary.routeQuality, .usable)
        XCTAssertEqual(viewModel.compactSummary.displayDerivedTotalAscentMeters, 4)
        XCTAssertTrue(viewModel.compactSummary.hasAnyDisplayData)
    }

    func testBridgeDisplayPayloadProvidesDisplayStateWhenCompactSummaryIsUnavailable() {
        let display = WatchBridgeCompactActivityDisplayPayload(
            routePointCount: 5,
            speedSampleCount: 4,
            elevationSampleCount: 3,
            hasCompactRoute: true,
            hasSpeedSparkline: true,
            hasElevationProfile: false,
            displayOnly: true
        )

        let viewModel = WatchActivityViewModel(bridgeDisplay: display)

        XCTAssertEqual(viewModel.compactSummary.routePointCount, 5)
        XCTAssertEqual(viewModel.compactSummary.speedPointCount, 4)
        XCTAssertEqual(viewModel.compactSummary.elevationPointCount, 3)
        XCTAssertTrue(viewModel.compactSummary.hasCompactRoute)
        XCTAssertTrue(viewModel.compactSummary.hasSpeedSparkline)
        XCTAssertFalse(viewModel.compactSummary.hasElevationProfile)
        XCTAssertTrue(viewModel.compactSummary.hasAnyDisplayData)
        XCTAssertTrue(viewModel.compactSummary.displayOnly)
    }

    private static func sensorSnapshot(capturedAt: Date) -> WatchSensorProviderSnapshot {
        WatchSensorProviderSnapshot(
            providerKind: .mock,
            availability: .available(at: capturedAt),
            capturedAt: capturedAt,
            samples: [
                WatchSensorSample(
                    id: uuid(2),
                    kind: .speed,
                    timestamp: capturedAt.addingTimeInterval(1),
                    numericValue: 12,
                    unitSymbol: "km/h",
                    providerKind: .mock,
                    confidence: 0.9
                )
            ]
        )
    }

    private static func compactSummary() -> ActivityVisualizationCompactSummary {
        ActivityVisualizationCompactSummary(
            routeQuality: .usable,
            speedQuality: .usable,
            elevationQuality: .usable,
            routeDisplayPointCount: 12,
            speedDisplayPointCount: 8,
            elevationDisplayPointCount: 6,
            routeSegmentCount: 2,
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
                segmentCount: 2
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

    private static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
