// [協作區] Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift
// Purpose: Verifies the umbrella ActivityVisualizationPipeline composes focused display pipelines without semantic drift.
// Delegates to: RouteDisplayPipeline, SpeedDisplayPipeline, ElevationDisplayPipeline, and future compact adapters.

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class ActivityVisualizationPipelineTests: XCTestCase {
    func testUnifiedPipelineMatchesFocusedSubPipelineOutputs() {
        let startDate = Date(timeIntervalSince1970: 4_200)
        let samples = makeSamples(startDate: startDate)
        let configuration = ActivityVisualizationConfiguration(
            route: RouteDisplayConfiguration(maximumDisplayPointCount: 50),
            speed: SpeedDisplayConfiguration(maximumDisplayPointCount: 50),
            elevation: ElevationDisplayConfiguration(maximumDisplayPointCount: 50)
        )

        let result = ActivityVisualizationPipeline(configuration: configuration).makeVisualization(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )
        let expectedRoute = RouteDisplayPipeline(configuration: configuration.route).makeDisplayRoute(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )
        let expectedSpeed = SpeedDisplayPipeline(configuration: configuration.speed).makeDisplaySpeed(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )
        let expectedElevation = ElevationDisplayPipeline(configuration: configuration.elevation).makeDisplayElevation(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.route, expectedRoute)
        XCTAssertEqual(result.speed, expectedSpeed)
        XCTAssertEqual(result.elevation, expectedElevation)
        XCTAssertEqual(result.compactSummary.routeQuality, expectedRoute.summary.quality)
        XCTAssertEqual(result.compactSummary.speedQuality, expectedSpeed.summary.quality)
        XCTAssertEqual(result.compactSummary.elevationQuality, expectedElevation.summary.quality)
    }

    func testUnifiedPipelineAggregatesDiagnosticsWithoutMutatingSamples() {
        let startDate = Date(timeIntervalSince1970: 4_600)
        let samples = [
            makeSample(
                seconds: 0,
                coordinate: GeoCoordinate(latitude: 25.0, longitude: 121.0),
                speedKmh: 8,
                altitudeMeters: 100,
                startDate: startDate
            ),
            makeSample(
                seconds: 5,
                coordinate: GeoCoordinate(latitude: 25.0001, longitude: 121.0001),
                speedKmh: policy.chartMaximumSpeedKmh + 5,
                altitudeMeters: 101,
                startDate: startDate
            )
        ]

        let result = ActivityVisualizationPipeline().makeVisualization(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(
            result.diagnostics.droppedSampleCount,
            result.route.diagnostics.droppedSampleCount
                + result.speed.diagnostics.droppedSampleCount
                + result.elevation.diagnostics.droppedSampleCount
        )
        XCTAssertEqual(
            result.diagnostics.downsampledPointCount,
            result.speed.diagnostics.downsampledPointCount
                + result.elevation.diagnostics.downsampledPointCount
        )
        XCTAssertTrue(result.compactSummary.hasAnyDisplayData)
        XCTAssertEqual(samples[1].speedKmh, policy.chartMaximumSpeedKmh + 5)
    }

    func testUnifiedPipelineEmptySamplesProduceUnavailableCompactSummary() {
        let result = ActivityVisualizationPipeline().makeVisualization(
            samples: [],
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.route.summary.quality, .unavailable)
        XCTAssertEqual(result.speed.summary.quality, .unavailable)
        XCTAssertEqual(result.elevation.summary.quality, .unavailable)
        XCTAssertEqual(result.compactSummary.routeQuality, .unavailable)
        XCTAssertEqual(result.compactSummary.speedQuality, .unavailable)
        XCTAssertEqual(result.compactSummary.elevationQuality, .unavailable)
        XCTAssertFalse(result.compactSummary.hasAnyDisplayData)
    }

    private var policy: ActivityFidelityPolicy {
        ActivityFidelityPolicy(profile: .standardSkateboard)
    }

    private func makeSamples(startDate: Date) -> [MotionSample] {
        [
            makeSample(
                seconds: 0,
                coordinate: GeoCoordinate(latitude: 25.0, longitude: 121.0),
                speedKmh: 8,
                altitudeMeters: 100,
                startDate: startDate
            ),
            makeSample(
                seconds: 5,
                coordinate: GeoCoordinate(latitude: 25.0001, longitude: 121.0001),
                speedKmh: 12,
                altitudeMeters: 102,
                startDate: startDate
            ),
            makeSample(
                seconds: 10,
                coordinate: GeoCoordinate(latitude: 25.0002, longitude: 121.0002),
                speedKmh: 16,
                altitudeMeters: 103,
                startDate: startDate
            )
        ]
    }

    private func makeSample(
        seconds: TimeInterval,
        coordinate: GeoCoordinate,
        speedKmh: Double,
        altitudeMeters: Double,
        startDate: Date
    ) -> MotionSample {
        let timestamp = startDate.addingTimeInterval(seconds)
        let timestampMilliseconds = millisecondsSince1970(for: timestamp)
        return MotionSample(
            timestamp: timestamp,
            timestampMillisecondsSince1970: timestampMilliseconds,
            gpsCoordinate: coordinate,
            speedKmh: speedKmh,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            altitudeMeters: altitudeMeters,
            altitudeSource: .coreLocationAbsolute,
            altitudeDiagnostics: AltitudeDiagnostics(
                source: .coreLocationAbsolute,
                trustClassification: .trusted,
                reason: .coreLocationAbsoluteAccepted,
                rawAltitudeMeters: altitudeMeters,
                trustedAltitudeMeters: altitudeMeters,
                updatesTrustedAltitudeAnchor: true
            ),
            locationDiagnostics: LocationFixDiagnostics(
                horizontalAccuracyMeters: 5,
                verticalAccuracyMeters: 5,
                rawLocationTimestamp: timestamp,
                rawLocationTimestampMillisecondsSince1970: timestampMilliseconds,
                receivedAtTimestamp: timestamp,
                receivedAtTimestampMillisecondsSince1970: timestampMilliseconds,
                gpsUpdateIntervalSeconds: 5,
                coordinateDerivedSpeedKmh: speedKmh,
                speedSource: .coreLocation,
                freshnessState: .fresh,
                routeSegmentConfidence: .high
            ),
            sampleSource: .locationFix
        )
    }

    private func millisecondsSince1970(for date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1_000).rounded())
    }
}
