// [協作區] Tests/ActivityVisualizationTests/CompactActivityVisualizationTests.swift
// Purpose: Verifies watch-ready compact activity visualization adapters remain display-only and renderer-free.
// Delegates to: ActivityVisualizationPipeline, compact route/speed/elevation display payloads, and future watchOS consumers.

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class CompactActivityVisualizationTests: XCTestCase {
    func testUnifiedPipelineBuildsCompactRouteSpeedAndElevationPayloads() {
        let startDate = Date(timeIntervalSince1970: 5_200)
        let samples = makeSamples(startDate: startDate)

        let result = ActivityVisualizationPipeline().makeVisualization(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.compactSummary.compactRoute.quality, result.route.summary.quality)
        XCTAssertEqual(result.compactSummary.speedSparkline.quality, result.speed.summary.quality)
        XCTAssertEqual(result.compactSummary.elevationProfile.quality, result.elevation.summary.quality)
        XCTAssertEqual(result.compactSummary.compactRoute.points.first?.coordinate, result.route.points.first?.displayCoordinate)
        XCTAssertEqual(result.compactSummary.speedSparkline.points.first?.value, result.speed.points.first?.speedKilometersPerHour)
        XCTAssertEqual(result.compactSummary.elevationProfile.points.first?.value, result.elevation.points.first?.elevationMeters)
        XCTAssertTrue(result.compactSummary.hasAnyDisplayData)
    }

    func testCompactRouteDisplayCanBeConstructedWithoutFullRouteDisplayResult() {
        let coordinate = GeoCoordinate(latitude: 25.033, longitude: 121.565)
        let point = CompactRoutePoint(
            id: 7,
            elapsedSeconds: 12,
            coordinate: coordinate,
            semantic: .highConfidence
        )
        let compactRoute = CompactRouteDisplay(
            points: [point],
            quality: .usable,
            segmentCount: 1,
            bounds: RouteDisplayBounds(
                minimumLatitude: 25.033,
                maximumLatitude: 25.033,
                minimumLongitude: 121.565,
                maximumLongitude: 121.565
            )
        )

        XCTAssertEqual(compactRoute.points, [point])
        XCTAssertEqual(compactRoute.quality, .usable)
        XCTAssertEqual(compactRoute.segmentCount, 1)
        XCTAssertTrue(compactRoute.hasDisplayData)
    }

    func testCompactSparklineAdaptersDownsampleAndNormalizeDisplayValues() {
        let startDate = Date(timeIntervalSince1970: 5_600)
        let speedPoints = (0..<12).map { index in
            SpeedDisplayPoint(
                id: index,
                timestamp: startDate.addingTimeInterval(Double(index)),
                elapsedSeconds: Double(index),
                speedKilometersPerHour: Double(index + 1),
                source: .motionSample,
                segmentID: 0
            )
        }
        let speed = SpeedDisplayResult(
            points: speedPoints,
            summary: SpeedDisplaySummary(
                quality: .usable,
                rawSampleCount: speedPoints.count,
                displayPointCount: speedPoints.count,
                minimumSpeedKilometersPerHour: 1,
                maximumSpeedKilometersPerHour: 12,
                averageDisplaySpeedKilometersPerHour: 6.5,
                segmentCount: 1
            )
        )

        let sparkline = CompactSpeedSparkline(speed: speed, maximumPointCount: 5)

        XCTAssertEqual(sparkline.points.count, 5)
        XCTAssertEqual(sparkline.points.first?.normalizedValue ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(sparkline.points.last?.normalizedValue ?? -1, 1, accuracy: 0.001)
        XCTAssertEqual(sparkline.maximumSpeedKilometersPerHour, 12)
    }

    func testEmptyCompactSummaryDoesNotRequireWatchUIOrRecordingState() {
        let summary = ActivityVisualizationCompactSummary()

        XCTAssertFalse(summary.hasAnyDisplayData)
        XCTAssertEqual(summary.compactRoute, .empty)
        XCTAssertEqual(summary.speedSparkline, .empty)
        XCTAssertEqual(summary.elevationProfile, .empty)
        XCTAssertEqual(summary.routeQuality, .unavailable)
        XCTAssertEqual(summary.selectedElevationSource, .motionSample)
    }

    private var policy: ActivityFidelityPolicy {
        ActivityFidelityPolicy(profile: .standardSkateboard)
    }

    private func makeSamples(startDate: Date) -> [MotionSample] {
        [
            makeSample(seconds: 0, coordinate: GeoCoordinate(latitude: 25.0, longitude: 121.0), speedKmh: 8, altitudeMeters: 100, startDate: startDate),
            makeSample(seconds: 5, coordinate: GeoCoordinate(latitude: 25.0001, longitude: 121.0001), speedKmh: 12, altitudeMeters: 102, startDate: startDate),
            makeSample(seconds: 10, coordinate: GeoCoordinate(latitude: 25.0002, longitude: 121.0002), speedKmh: 16, altitudeMeters: 104, startDate: startDate)
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
