// [協作區] SnowSegmentClassifierTests.swift
import Foundation
import XCTest
@testable import SkateTrack_iOS

final class SnowSegmentClassifierTests: XCTestCase {
    private let classifier = SnowSegmentClassifier()

    func testFixtureClassificationsMatchExpectedSegmentTypes() {
        let fixtures = SnowClassifierFixture.all
        XCTAssertEqual(fixtures.count, 9)

        for fixture in fixtures {
            let result = classifier.classify(samples: fixture.samples)
            print(
                "SnowClassifierFixtureResult name=\(fixture.name) expected=\(fixture.expectedType.rawValue) actual=\(result.type.rawValue) confidence=\(String(format: "%.2f", result.confidence)) verticalRate=\(format(result.verticalRateMetersPerSecond)) motionEnergy=\(String(format: "%.3f", result.motionEnergyG)) headingStdDev=\(format(result.headingStandardDeviationDegrees)) reasons=\(result.reasonCodes.joined(separator: ","))"
            )
            XCTAssertEqual(result.type, fixture.expectedType, "Fixture \(fixture.name) should classify as \(fixture.expectedType.rawValue), got \(result.type.rawValue). Reasons: \(result.reasonCodes)")
            XCTAssertGreaterThanOrEqual(result.confidence, fixture.minimumConfidence, "Fixture \(fixture.name) confidence too low")
        }
    }

    func testAmbiguousGondolaLikeDescentDoesNotCountAsDownhillRun() {
        let fixture = SnowClassifierFixture.ambiguousGondolaLikeDescent
        let result = classifier.classify(samples: fixture.samples)
        XCTAssertEqual(result.type, .unknown)
        XCTAssertTrue(result.reasonCodes.contains("ambiguousGondolaLikeDescent"))
        XCTAssertLessThan(result.confidence, 0.60)
    }

    func testMissingAltitudeMovingWindowStaysUnknown() {
        let fixture = SnowClassifierFixture.missingAltitudeMoving
        let result = classifier.classify(samples: fixture.samples)
        XCTAssertEqual(result.type, .unknown)
        XCTAssertTrue(result.reasonCodes.contains("missingAltitude"))
    }

    func testProductionConfigCapturesAgreedInitialThresholds() {
        let config = SnowClassifierConfig.productionV0
        XCTAssertEqual(config.altitudeMovingAverageSampleCount, 30)
        XCTAssertEqual(config.trendWindowSeconds, 5)
        XCTAssertEqual(config.hysteresisSeconds, 5)
        XCTAssertEqual(config.ascentWindowSeconds, 10)
        XCTAssertEqual(config.stoppedWindowSeconds, 15)
        XCTAssertEqual(config.downhillMinSpeedKmh, 10, accuracy: 0.001)
        XCTAssertEqual(config.downhillVerticalRateThresholdMetersPerSecond, -0.25, accuracy: 0.001)
        XCTAssertEqual(config.strongDownhillVerticalRateThresholdMetersPerSecond, -0.45, accuracy: 0.001)
        XCTAssertEqual(config.ascentVerticalRateThresholdMetersPerSecond, 0.15, accuracy: 0.001)
        XCTAssertEqual(config.flatVerticalRateAbsThresholdMetersPerSecond, 0.10, accuracy: 0.001)
        XCTAssertEqual(config.gondolaMinSpeedKmh, 8, accuracy: 0.001)
        XCTAssertEqual(config.gondolaMaxSpeedKmh, 30, accuracy: 0.001)
        XCTAssertEqual(config.downhillMotionEnergyThresholdG, 0.08, accuracy: 0.001)
        XCTAssertEqual(config.lowMotionEnergyThresholdG, 0.03, accuracy: 0.001)
        XCTAssertEqual(config.downhillHeadingStandardDeviationThresholdDegrees, 12, accuracy: 0.001)
        XCTAssertEqual(config.stableHeadingStandardDeviationThresholdDegrees, 5, accuracy: 0.001)
    }

    private func format(_ value: Double?) -> String {
        guard let value else { return "nil" }
        return String(format: "%.3f", value)
    }
}

private struct SnowClassifierFixture {
    let name: String
    let expectedType: SnowSegmentType
    let minimumConfidence: Double
    let samples: [MotionSample]

    static var all: [SnowClassifierFixture] {
        [
            cleanDownhill,
            liftAscent,
            gondolaAscent,
            surfaceLiftAscent,
            stopped,
            walking,
            noisyAltitudeDownhill,
            ambiguousGondolaLikeDescent,
            missingAltitudeMoving,
        ]
    }

    static let cleanDownhill = SnowClassifierFixture(
        name: "cleanDownhill",
        expectedType: .downhillRun,
        minimumConfidence: 0.80,
        samples: makeSamples(
            count: 60,
            speedKmh: 24,
            altitudeStart: 1_800,
            altitudeDeltaPerSecond: -0.65,
            accelerationEnergyG: 0.13,
            headingPattern: .turning
        )
    )

    static let liftAscent = SnowClassifierFixture(
        name: "liftAscent",
        expectedType: .liftAscent,
        minimumConfidence: 0.74,
        samples: makeSamples(
            count: 45,
            speedKmh: 7,
            altitudeStart: 1_500,
            altitudeDeltaPerSecond: 0.32,
            accelerationEnergyG: 0.05,
            headingPattern: .mildlyVariable
        )
    )

    static let gondolaAscent = SnowClassifierFixture(
        name: "gondolaAscent",
        expectedType: .gondolaAscent,
        minimumConfidence: 0.80,
        samples: makeSamples(
            count: 45,
            speedKmh: 16,
            altitudeStart: 1_480,
            altitudeDeltaPerSecond: 0.35,
            accelerationEnergyG: 0.01,
            headingPattern: .stable
        )
    )

    static let surfaceLiftAscent = SnowClassifierFixture(
        name: "surfaceLiftAscent",
        expectedType: .surfaceLiftAscent,
        minimumConfidence: 0.76,
        samples: makeSamples(
            count: 45,
            speedKmh: 4,
            altitudeStart: 1_480,
            altitudeDeltaPerSecond: 0.24,
            accelerationEnergyG: 0.04,
            headingPattern: .stable
        )
    )

    static let stopped = SnowClassifierFixture(
        name: "stopped",
        expectedType: .stopped,
        minimumConfidence: 0.84,
        samples: makeSamples(
            count: 35,
            speedKmh: 0.4,
            altitudeStart: 1_620,
            altitudeDeltaPerSecond: 0,
            accelerationEnergyG: 0.005,
            headingPattern: .none
        )
    )

    static let walking = SnowClassifierFixture(
        name: "walking",
        expectedType: .walking,
        minimumConfidence: 0.72,
        samples: makeSamples(
            count: 35,
            speedKmh: 3.5,
            altitudeStart: 1_620,
            altitudeDeltaPerSecond: 0.02,
            accelerationEnergyG: 0.10,
            headingPattern: .mildlyVariable
        )
    )

    static let noisyAltitudeDownhill = SnowClassifierFixture(
        name: "noisyAltitudeDownhill",
        expectedType: .downhillRun,
        minimumConfidence: 0.76,
        samples: makeSamples(
            count: 80,
            speedKmh: 21,
            altitudeStart: 1_900,
            altitudeDeltaPerSecond: -0.55,
            accelerationEnergyG: 0.12,
            headingPattern: .turning,
            altitudeNoiseMeters: 1.8
        )
    )

    static let ambiguousGondolaLikeDescent = SnowClassifierFixture(
        name: "ambiguousGondolaLikeDescent",
        expectedType: .unknown,
        minimumConfidence: 0.40,
        samples: makeSamples(
            count: 55,
            speedKmh: 17,
            altitudeStart: 1_900,
            altitudeDeltaPerSecond: -0.45,
            accelerationEnergyG: 0.01,
            headingPattern: .stable
        )
    )

    static let missingAltitudeMoving = SnowClassifierFixture(
        name: "missingAltitudeMoving",
        expectedType: .unknown,
        minimumConfidence: 0.30,
        samples: makeSamples(
            count: 35,
            speedKmh: 13,
            altitudeStart: nil,
            altitudeDeltaPerSecond: nil,
            accelerationEnergyG: 0.08,
            headingPattern: .mildlyVariable
        )
    )

    private enum HeadingPattern {
        case none
        case stable
        case mildlyVariable
        case turning
    }

    private static func makeSamples(
        count: Int,
        speedKmh: Double,
        altitudeStart: Double?,
        altitudeDeltaPerSecond: Double?,
        accelerationEnergyG: Double,
        headingPattern: HeadingPattern,
        altitudeNoiseMeters: Double = 0
    ) -> [MotionSample] {
        let startDate = Date(timeIntervalSince1970: 1_700_300_000)
        var latitude = 46.0000
        var longitude = 7.0000
        let metersPerSecond = speedKmh / 3.6

        return (0..<count).map { index in
            let timestamp = startDate.addingTimeInterval(Double(index))
            let bearing = bearingDegrees(for: headingPattern, index: index)
            let coordinate = coordinateAfterMoving(
                latitude: &latitude,
                longitude: &longitude,
                distanceMeters: metersPerSecond,
                bearingDegrees: bearing
            )
            let altitude = altitudeStart.flatMap { start in
                altitudeDeltaPerSecond.map { delta in
                    start + (delta * Double(index)) + deterministicNoise(index: index, amplitude: altitudeNoiseMeters)
                }
            }
            let acceleration = accelerationVector(energyG: accelerationEnergyG, index: index)
            return MotionSample(
                timestamp: timestamp,
                gpsCoordinate: headingPattern == .none ? nil : coordinate,
                speedKmh: speedKmh,
                accelerometerG: acceleration,
                gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: accelerationEnergyG / 2),
                altitudeMeters: altitude
            )
        }
    }

    private static func bearingDegrees(for pattern: HeadingPattern, index: Int) -> Double {
        switch pattern {
        case .none, .stable:
            return 35
        case .mildlyVariable:
            return 35 + sin(Double(index) / 5) * 4
        case .turning:
            return 35 + sin(Double(index) / 4) * 22
        }
    }

    private static func coordinateAfterMoving(
        latitude: inout Double,
        longitude: inout Double,
        distanceMeters: Double,
        bearingDegrees: Double
    ) -> GeoCoordinate {
        let bearing = bearingDegrees * .pi / 180
        let deltaNorth = cos(bearing) * distanceMeters
        let deltaEast = sin(bearing) * distanceMeters
        latitude += deltaNorth / 111_111
        longitude += deltaEast / (111_111 * cos(latitude * .pi / 180))
        return GeoCoordinate(latitude: latitude, longitude: longitude)
    }

    private static func accelerationVector(energyG: Double, index: Int) -> ThreeAxisValue {
        let lateral = energyG * sin(Double(index) * 0.7)
        let forward = energyG * cos(Double(index) * 0.5)
        return ThreeAxisValue(x: lateral, y: forward, z: 1)
    }

    private static func deterministicNoise(index: Int, amplitude: Double) -> Double {
        guard amplitude > 0 else { return 0 }
        return sin(Double(index) * 1.7) * amplitude
    }
}
