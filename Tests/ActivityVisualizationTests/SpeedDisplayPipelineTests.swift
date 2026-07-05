// [協作區] Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift
// Purpose: Verifies the Shared speed display pipeline shell before platform chart migration.
// Delegates to: MotionSample source-of-truth speed data, ActivityFidelityPolicy, and future iOS/macOS chart adapters.

import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SpeedDisplayPipelineTests: XCTestCase {
    func testSharedSpeedPipelineBuildsDisplayOnlyPoints() {
        let startDate = Date(timeIntervalSince1970: 1_800)
        let samples = [
            makeSample(seconds: 0, speedKmh: 4, startDate: startDate),
            makeSample(seconds: 5, speedKmh: 8, startDate: startDate),
            makeSample(seconds: 10, speedKmh: 12, startDate: startDate)
        ]

        let result = SpeedDisplayPipeline().makeDisplaySpeed(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.summary.quality, .usable)
        XCTAssertEqual(result.summary.rawSampleCount, 3)
        XCTAssertEqual(result.summary.displayPointCount, 3)
        XCTAssertEqual(result.summary.segmentCount, 1)
        XCTAssertEqual(result.summary.minimumSpeedKilometersPerHour ?? -1, 8, accuracy: 0.001)
        XCTAssertEqual(result.summary.maximumSpeedKilometersPerHour ?? -1, 8, accuracy: 0.001)
        XCTAssertEqual(result.summary.averageDisplaySpeedKilometersPerHour ?? -1, 8, accuracy: 0.001)
        XCTAssertEqual(result.points.map(\.elapsedSeconds), [0, 5, 10])
        XCTAssertEqual(Set(result.points.map(\.source)), [.motionSample])
        XCTAssertEqual(result.diagnostics.droppedSampleCount, 0)
    }

    func testSharedSpeedPipelineDropsInvalidAndOutOfRangeSamplesWithoutMutatingMetrics() {
        let startDate = Date(timeIntervalSince1970: 2_000)
        let samples = [
            makeSample(seconds: 0, speedKmh: -1, startDate: startDate),
            makeSample(seconds: 4, speedKmh: policy.chartMaximumSpeedKmh + 1, startDate: startDate),
            makeSample(seconds: 8, speedKmh: 16, startDate: startDate)
        ]

        let result = SpeedDisplayPipeline().makeDisplaySpeed(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.summary.quality, .limited)
        XCTAssertEqual(result.summary.rawSampleCount, 3)
        XCTAssertEqual(result.summary.displayPointCount, 1)
        XCTAssertEqual(result.points.first?.speedKilometersPerHour, 16)
        XCTAssertEqual(result.diagnostics.droppedSampleCount, 2)
        XCTAssertTrue(result.diagnostics.messages.contains("speed.droppedInvalidOrOutOfRangeSamples"))
        XCTAssertEqual(samples[1].speedKmh, policy.chartMaximumSpeedKmh + 1)
    }

    func testSharedSpeedPipelineSegmentsGapsAndDownsamplesForDisplay() {
        let startDate = Date(timeIntervalSince1970: 2_400)
        let samples = [
            makeSample(seconds: 0, speedKmh: 5, startDate: startDate),
            makeSample(seconds: 4, speedKmh: 6, startDate: startDate),
            makeSample(seconds: 8, speedKmh: 7, startDate: startDate),
            makeSample(seconds: 25, speedKmh: 8, startDate: startDate),
            makeSample(seconds: 29, speedKmh: 9, startDate: startDate),
            makeSample(seconds: 33, speedKmh: 10, startDate: startDate)
        ]

        let result = SpeedDisplayPipeline(
            configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 4)
        ).makeDisplaySpeed(
            samples: samples,
            startDate: startDate,
            fidelityPolicy: policy
        )

        XCTAssertEqual(result.summary.rawSampleCount, 6)
        XCTAssertEqual(result.summary.displayPointCount, 4)
        XCTAssertEqual(result.summary.segmentCount, 2)
        XCTAssertEqual(result.points.map(\.elapsedSeconds).last, 33)
        XCTAssertEqual(Set(result.points.map(\.segmentID)), Set([0, 1]))
        XCTAssertEqual(result.diagnostics.downsampledPointCount, 2)
        XCTAssertTrue(result.diagnostics.messages.contains("speed.downsampledForDisplay"))
    }

    private var policy: ActivityFidelityPolicy {
        ActivityFidelityPolicy(profile: .standardSkateboard)
    }

    private func makeSample(seconds: TimeInterval, speedKmh: Double, startDate: Date) -> MotionSample {
        MotionSample(
            timestamp: startDate.addingTimeInterval(seconds),
            speedKmh: speedKmh,
            accelerometerG: ThreeAxisValue(x: 0, y: 0, z: 1),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            locationDiagnostics: LocationFixDiagnostics(
                gpsUpdateIntervalSeconds: 4,
                speedSource: .coreLocation,
                freshnessState: .fresh,
                routeSegmentConfidence: .high
            ),
            sampleSource: .locationFix
        )
    }
}
