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
        XCTAssertEqual(viewModel.compactSummary.routeCard.scope, .textOnly)
        XCTAssertEqual(viewModel.compactSummary.routeCard.status, .unavailable)
        XCTAssertFalse(viewModel.compactSummary.speedCard.hasData)
        XCTAssertFalse(viewModel.compactSummary.elevationCard.hasData)
        XCTAssertEqual(viewModel.fallback.kind, .ready)
        XCTAssertFalse(viewModel.fallback.isVisible)
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
        XCTAssertEqual(viewModel.compactSummary.routeCard.compactRoute, compactSummary.compactRoute)
        XCTAssertEqual(viewModel.compactSummary.routeCard.status, .recorded)
        XCTAssertEqual(viewModel.compactSummary.speedCard.points, compactSummary.speedSparkline.points)
        XCTAssertEqual(viewModel.compactSummary.speedCard.maximumSpeedKilometersPerHour, 12)
        XCTAssertEqual(viewModel.compactSummary.elevationCard.points, compactSummary.elevationProfile.points)
        XCTAssertEqual(viewModel.compactSummary.elevationCard.ascentMeters, 4)
        XCTAssertTrue(viewModel.compactSummary.hasAnyDisplayData)
        XCTAssertEqual(viewModel.fallback.kind, .ready)
    }

    func testDisconnectedFallbackWhenWatchBridgeIsUnavailable() {
        let baseDate = Date(timeIntervalSince1970: 3_000)
        let payload = WatchBridgeConnectionStatusPayload(
            state: WatchBridgeConnectionState(
                status: .pairedButUnreachable,
                quality: .delayed,
                lastUpdatedAt: baseDate,
                explanation: "watch is not reachable"
            ),
            reportedAt: baseDate,
            canSendCommands: false,
            canReceiveSnapshots: false
        )

        let viewModel = WatchActivityViewModel(connectionStatus: payload)

        XCTAssertTrue(viewModel.connection.isDisconnected)
        XCTAssertEqual(viewModel.fallback.kind, .disconnected)
        XCTAssertTrue(viewModel.fallback.isBlocking)
        XCTAssertEqual(viewModel.fallback.titleLocalizationKey, "watch.fallback.disconnected.title")
        XCTAssertEqual(viewModel.fallback.accessibilityIdentifier, "watch-fallback-disconnected")
    }

    func testNoSamplesFallbackWhenActiveSessionHasNoDisplayData() {
        let baseDate = Date(timeIntervalSince1970: 4_000)
        let session = WatchBridgeActivitySessionPayload(
            state: .recording,
            mode: WatchBridgeActivityModeDescriptor(sportModeKey: "skateboard"),
            updatedAt: baseDate,
            elapsedSeconds: 12,
            isRecordingAllowed: true
        )
        let sensorSnapshot = WatchSensorProviderSnapshot(
            providerKind: .mock,
            availability: .available(at: baseDate),
            capturedAt: baseDate,
            samples: []
        )

        let viewModel = WatchActivityViewModel(
            connectionStatus: Self.connectionStatus(status: .reachable, quality: .fresh, at: baseDate),
            session: session,
            sensorSnapshot: sensorSnapshot
        )

        XCTAssertTrue(viewModel.session.isActive)
        XCTAssertFalse(viewModel.samples.hasAnySampleData)
        XCTAssertFalse(viewModel.compactSummary.hasAnyDisplayData)
        XCTAssertEqual(viewModel.fallback.kind, .noSamples)
        XCTAssertFalse(viewModel.fallback.isBlocking)
        XCTAssertEqual(viewModel.fallback.titleLocalizationKey, "watch.fallback.noSamples.title")
    }

    func testDisabledProviderFallbackWhenProviderIsDisabled() {
        let baseDate = Date(timeIntervalSince1970: 5_000)
        let sensorSnapshot = WatchSensorProviderSnapshot(
            providerKind: .disabled,
            availability: .disabled(at: baseDate, explanation: "disabled for this build"),
            capturedAt: baseDate,
            samples: []
        )

        let viewModel = WatchActivityViewModel(
            connectionStatus: Self.connectionStatus(status: .reachable, quality: .fresh, at: baseDate),
            sensorSnapshot: sensorSnapshot
        )

        XCTAssertTrue(viewModel.samples.isDisabled)
        XCTAssertEqual(viewModel.fallback.kind, .disabledProvider)
        XCTAssertTrue(viewModel.fallback.isBlocking)
        XCTAssertEqual(viewModel.fallback.titleLocalizationKey, "watch.fallback.disabledProvider.title")
    }

    func testStaleDataFallbackWhenTransportQualityIsStale() {
        let baseDate = Date(timeIntervalSince1970: 6_000)
        let viewModel = WatchActivityViewModel(
            connectionStatus: Self.connectionStatus(status: .reachable, quality: .stale, at: baseDate)
        )

        XCTAssertTrue(viewModel.connection.isStale)
        XCTAssertEqual(viewModel.fallback.kind, .staleData)
        XCTAssertFalse(viewModel.fallback.isBlocking)
        XCTAssertEqual(viewModel.fallback.titleLocalizationKey, "watch.fallback.staleData.title")
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
        XCTAssertEqual(viewModel.compactSummary.routeCard.status, .recorded)
        XCTAssertEqual(viewModel.compactSummary.routeCard.pointCount, 5)
        XCTAssertTrue(viewModel.compactSummary.speedCard.hasData)
        XCTAssertEqual(viewModel.compactSummary.speedCard.pointCount, 4)
        XCTAssertFalse(viewModel.compactSummary.elevationCard.hasData)
        XCTAssertEqual(viewModel.compactSummary.elevationCard.pointCount, 3)
    }

    func testTextOnlyRouteCardShowsQualityInsufficientWithoutSemanticForking() {
        let limitedRoute = CompactRouteDisplay(
            points: [
                CompactRoutePoint(
                    id: 1,
                    elapsedSeconds: 1,
                    coordinate: GeoCoordinate(latitude: 25.033, longitude: 121.565),
                    semantic: .lowConfidence
                )
            ],
            quality: .limited,
            segmentCount: 1,
            hasLowConfidenceSegments: true,
            hasStartupWarmup: true
        )
        let compactSummary = ActivityVisualizationCompactSummary(
            routeQuality: .limited,
            routeDisplayPointCount: 1,
            routeSegmentCount: 1,
            compactRoute: limitedRoute
        )

        let viewModel = WatchActivityViewModel(compactSummary: compactSummary)

        XCTAssertEqual(viewModel.compactSummary.routeCard.scope, .textOnly)
        XCTAssertEqual(viewModel.compactSummary.routeCard.compactRoute, limitedRoute)
        XCTAssertEqual(viewModel.compactSummary.routeCard.status, .qualityInsufficient)
        XCTAssertTrue(viewModel.compactSummary.routeCard.hasLowConfidenceSegments)
        XCTAssertTrue(viewModel.compactSummary.routeCard.hasStartupWarmup)
    }


    func testHapticIntentSchedulesDevicePlaybackWithoutSensorClaim() {
        let issuedAt = Date(timeIntervalSince1970: 10)
        let intent = WatchHapticIntent.sessionControl(
            .start,
            issuedAt: issuedAt,
            correlationId: "command-start-1"
        )
        var gate = WatchHapticIntentGate(
            policy: .deviceSupported(minimumIntervalSeconds: 1, duplicateSuppressionSeconds: 5)
        )

        let decision = gate.resolve(intent, decidedAt: issuedAt)

        XCTAssertEqual(intent.kind, .sessionStart)
        XCTAssertEqual(intent.sourceDescription, "watch live control")
        XCTAssertFalse(intent.isSensorDerivedClaim)
        XCTAssertEqual(decision.state, .scheduled)
        XCTAssertTrue(decision.shouldPlayOnDevice)
    }

    func testHapticIntentRateLimitsRepeatedKindWithDifferentCorrelation() {
        let firstDate = Date(timeIntervalSince1970: 20)
        let secondDate = firstDate.addingTimeInterval(0.5)
        var gate = WatchHapticIntentGate(
            policy: .deviceSupported(minimumIntervalSeconds: 3, duplicateSuppressionSeconds: 10)
        )

        let first = gate.resolve(
            .sessionControl(.pause, issuedAt: firstDate, correlationId: "pause-1"),
            decidedAt: firstDate
        )
        let second = gate.resolve(
            .sessionControl(.pause, issuedAt: secondDate, correlationId: "pause-2"),
            decidedAt: secondDate
        )

        XCTAssertEqual(first.state, .scheduled)
        XCTAssertEqual(second.state, .rateLimited)
        XCTAssertFalse(second.shouldPlayOnDevice)
    }

    func testHapticIntentDuplicateSuppressionUsesCorrelationKey() {
        let firstDate = Date(timeIntervalSince1970: 30)
        let secondDate = firstDate.addingTimeInterval(2)
        var gate = WatchHapticIntentGate(
            policy: .deviceSupported(minimumIntervalSeconds: 0.5, duplicateSuppressionSeconds: 8)
        )

        let first = gate.resolve(
            .sessionControl(.resume, issuedAt: firstDate, correlationId: "resume-command"),
            decidedAt: firstDate
        )
        let second = gate.resolve(
            .sessionControl(.resume, issuedAt: secondDate, correlationId: "resume-command"),
            decidedAt: secondDate
        )

        XCTAssertEqual(first.state, .scheduled)
        XCTAssertEqual(second.state, .duplicateSuppressed)
        XCTAssertFalse(second.shouldPlayOnDevice)
    }

    func testHapticIntentFallsBackToMockOnlyWhenDevicePlaybackIsNotAvailable() {
        let issuedAt = Date(timeIntervalSince1970: 40)
        var gate = WatchHapticIntentGate(policy: .mockOnly)

        let decision = gate.resolve(
            .sessionControl(.stop, issuedAt: issuedAt, correlationId: "stop-command"),
            decidedAt: issuedAt
        )

        XCTAssertEqual(decision.state, .mockOnly)
        XCTAssertFalse(decision.shouldPlayOnDevice)
    }

    func testHapticIntentIsDisabledWhenTargetSupportIsUnavailable() {
        let issuedAt = Date(timeIntervalSince1970: 50)
        var gate = WatchHapticIntentGate(policy: .disabled)

        let decision = gate.resolve(
            WatchHapticIntent(
                kind: .safetyNotice,
                issuedAt: issuedAt,
                correlationId: "safe-notice",
                sourceDescription: "non-emergency safety notice"
            ),
            decidedAt: issuedAt
        )

        XCTAssertEqual(decision.state, .disabled)
        XCTAssertFalse(decision.shouldPlayOnDevice)
        XCTAssertFalse(decision.intent.isSensorDerivedClaim)
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

    private static func connectionStatus(
        status: WatchBridgeConnectionStatus,
        quality: WatchBridgeTransportQuality,
        at date: Date
    ) -> WatchBridgeConnectionStatusPayload {
        WatchBridgeConnectionStatusPayload(
            state: WatchBridgeConnectionState(
                status: status,
                quality: quality,
                lastUpdatedAt: date,
                lastReceivedMessageAt: status == .reachable ? date : nil
            ),
            reportedAt: date,
            canSendCommands: status == .reachable && quality != .stale,
            canReceiveSnapshots: status == .reachable
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
