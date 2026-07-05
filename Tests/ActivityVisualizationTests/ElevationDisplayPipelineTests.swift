// [協作區] Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift
// Purpose: Verifies the Shared elevation display pipeline shell before platform elevation chart migration.
// Delegates to: MotionSample source-of-truth altitude data, ActivityFidelityPolicy, and future iOS/macOS chart adapters.

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class ElevationDisplayPipelineTests: XCTestCase {
    func testSharedElevationPipelineBuildsAnchoredBarometerProfile() {
        let startDate = Date(timeIntervalSince1970: 3_000)
        let samples = [
            makeAltitudeSample(seconds: 0, altitudeMeters: 100, source: .coreLocationAbsolute, startDate: startDate),
            makeAltitudeSample(seconds: 0, altitudeMeters: 0, source: .barometerRelative, startDate: startDate),
            makeAltitudeSample(seconds: 10, altitudeMeters: 102, source: .coreLocationAbsolute, startDate: startDate),
            makeAltitudeSample(seconds: 10, altitudeMeters: 2, source: .barometerRelative, startDate: startDate)
        ]

        let result = ElevationDisplayPipeline().makeDisplayElevation(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.summary.quality, .usable)
        XCTAssertEqual(result.summary.rawSampleCount, 4)
        XCTAssertEqual(result.summary.displayPointCount, 2)
        XCTAssertEqual(result.summary.selectedSource, .barometerRelative)
        XCTAssertEqual(result.summary.segmentCount, 1)
        XCTAssertEqual(result.summary.hasAbsoluteAnchor, true)
        XCTAssertEqual(result.points.map(\.elapsedSeconds), [0, 10])
        XCTAssertEqual(result.points.map(\.elevationMeters), [100, 102])
        XCTAssertEqual(result.points.map(\.source), [.barometerRelative, .barometerRelative])
        XCTAssertEqual(result.summary.elevationRange?.minimumMeters ?? -1, 100, accuracy: 0.001)
        XCTAssertEqual(result.summary.elevationRange?.maximumMeters ?? -1, 102, accuracy: 0.001)
        XCTAssertEqual(result.summary.displayDerivedTotalAscentMeters ?? -1, 2, accuracy: 0.001)
        XCTAssertTrue(result.diagnostics.messages.contains("elevation.absoluteAnchorApplied"))
    }

    func testSharedElevationPipelineDropsUntrustedCoreLocationSamplesAndSegmentsGaps() {
        let startDate = Date(timeIntervalSince1970: 3_400)
        let samples = [
            makeLegacyAltitudeSample(seconds: 0, altitudeMeters: 30, freshness: .fresh, startDate: startDate),
            makeLegacyAltitudeSample(seconds: 5, altitudeMeters: 31, freshness: .fresh, startDate: startDate),
            makeLegacyAltitudeSample(seconds: 21, altitudeMeters: 33, freshness: .fresh, startDate: startDate),
            makeLegacyAltitudeSample(seconds: 25, altitudeMeters: 90, freshness: .stale, startDate: startDate)
        ]

        let result = ElevationDisplayPipeline().makeDisplayElevation(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.summary.quality, .usable)
        XCTAssertEqual(result.summary.selectedSource, .coreLocationAbsolute)
        XCTAssertEqual(result.summary.displayPointCount, 3)
        XCTAssertEqual(result.summary.segmentCount, 2)
        XCTAssertEqual(result.points.map(\.segmentID), [0, 0, 1])
        XCTAssertEqual(result.diagnostics.droppedSampleCount, 1)
        XCTAssertTrue(result.diagnostics.messages.contains("elevation.droppedInvalidOrUntrustedSamples"))
        XCTAssertEqual(samples[3].altitudeMeters, 90)
    }

    func testSharedElevationPipelineDownsamplesWithoutChangingStoredSamples() {
        let startDate = Date(timeIntervalSince1970: 3_800)
        let samples = (0..<8).map { index in
            makeAltitudeSample(
                seconds: TimeInterval(index * 3),
                altitudeMeters: Double(50 + index),
                source: .debugSimulated,
                startDate: startDate
            )
        }

        let result = ElevationDisplayPipeline(
            configuration: ElevationDisplayConfiguration(maximumDisplayPointCount: 4)
        ).makeDisplayElevation(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.summary.rawSampleCount, 8)
        XCTAssertEqual(result.summary.displayPointCount, 5)
        XCTAssertEqual(result.summary.selectedSource, .debugSimulated)
        XCTAssertEqual(result.points.last?.elapsedSeconds, 21)
        XCTAssertEqual(result.diagnostics.downsampledPointCount, 3)
        XCTAssertTrue(result.diagnostics.messages.contains("elevation.downsampledForDisplay"))
        XCTAssertEqual(samples.last?.altitudeMeters, 57)
    }

    private var policy: ActivityFidelityPolicy {
        ActivityFidelityPolicy(profile: .standardSkateboard)
    }

    private func makeAltitudeSample(
        seconds: TimeInterval,
        altitudeMeters: Double,
        source: AltitudeSampleSource,
        startDate: Date
    ) -> MotionSample {
        MotionSample(
            timestamp: startDate.addingTimeInterval(seconds),
            speedKmh: 6,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            altitudeMeters: altitudeMeters,
            altitudeSource: source,
            altitudeDiagnostics: AltitudeDiagnostics(
                source: source,
                trustClassification: .trusted,
                reason: trustReason(for: source),
                rawAltitudeMeters: altitudeMeters,
                trustedAltitudeMeters: altitudeMeters,
                updatesTrustedAltitudeAnchor: true
            ),
            locationDiagnostics: LocationFixDiagnostics(
                verticalAccuracyMeters: 4,
                gpsUpdateIntervalSeconds: 4,
                speedSource: .coreLocation,
                freshnessState: .fresh,
                routeSegmentConfidence: .high
            ),
            sampleSource: .locationFix
        )
    }

    private func makeLegacyAltitudeSample(
        seconds: TimeInterval,
        altitudeMeters: Double,
        freshness: LocationFreshnessState,
        startDate: Date
    ) -> MotionSample {
        MotionSample(
            timestamp: startDate.addingTimeInterval(seconds),
            speedKmh: 5,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            altitudeMeters: altitudeMeters,
            altitudeSource: .coreLocationAbsolute,
            locationDiagnostics: LocationFixDiagnostics(
                verticalAccuracyMeters: 4,
                gpsUpdateIntervalSeconds: 4,
                speedSource: .coreLocation,
                freshnessState: freshness,
                routeSegmentConfidence: .high
            ),
            sampleSource: .locationFix
        )
    }

    private func trustReason(for source: AltitudeSampleSource) -> AltitudeTrustReason {
        switch source {
        case .barometerRelative:
            return .barometerRelativeAccepted
        case .coreLocationAbsolute:
            return .coreLocationAbsoluteAccepted
        case .debugSimulated:
            return .debugSimulatedTrusted
        case .unavailable:
            return .sourceUnavailable
        }
    }
}
