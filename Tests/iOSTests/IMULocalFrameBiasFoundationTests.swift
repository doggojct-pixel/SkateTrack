// [自主區] Tests/iOSTests/IMULocalFrameBiasFoundationTests.swift
// 用途：驗證 b17-A local tangent frame、IMU bias estimator 與 gravity compensation foundation。
// 委派至：LocalTangentPlane、IMUBiasEstimator 與 GravityCompensatedMotionSample。

import XCTest
@testable import SkateTrack_iOS

final class IMULocalFrameBiasFoundationTests: XCTestCase {
    func testLocalTangentPlaneRoundTripNearTaipeiLatitude() {
        let anchor = GeoCoordinate(latitude: 25.0330, longitude: 121.5654)
        let plane = LocalTangentPlane(anchorCoordinate: anchor)
        let expectedLocalMeters = LocalTangentMeters(eastMeters: 42.5, northMeters: -17.25)

        let coordinate = plane.coordinate(for: expectedLocalMeters)
        let roundTrippedLocalMeters = plane.localMeters(for: coordinate)

        XCTAssertEqual(roundTrippedLocalMeters.eastMeters, expectedLocalMeters.eastMeters, accuracy: 0.001)
        XCTAssertEqual(roundTrippedLocalMeters.northMeters, expectedLocalMeters.northMeters, accuracy: 0.001)
    }

    func testIMUBiasEstimatorConvergesOnKnownSyntheticBias() throws {
        let knownBiasG = ThreeAxisValue(x: 0.03, y: -0.02, z: 0.01)
        let samples = stationarySamples(
            count: 12,
            accelerometerBiasG: knownBiasG,
            speedKmh: 0.2,
            gyroscopeRadPS: ThreeAxisValue(x: 0.01, y: 0.01, z: 0.01)
        )

        let estimate = try XCTUnwrap(IMUBiasEstimator.estimateAccelerometerBias(from: samples))

        XCTAssertEqual(estimate.accelerometerBiasG.x, knownBiasG.x, accuracy: 0.000_001)
        XCTAssertEqual(estimate.accelerometerBiasG.y, knownBiasG.y, accuracy: 0.000_001)
        XCTAssertEqual(estimate.accelerometerBiasG.z, knownBiasG.z, accuracy: 0.000_001)
        XCTAssertEqual(estimate.sampleCount, 12)
        XCTAssertEqual(estimate.stationaryWindowDurationSeconds, 11, accuracy: 0.001)
    }

    func testIMUBiasEstimatorRefusesHighMotionSamples() {
        let highMotionSamples = stationarySamples(
            count: 12,
            accelerometerBiasG: ThreeAxisValue(x: 0.03, y: 0.02, z: 0.01),
            speedKmh: 9,
            gyroscopeRadPS: ThreeAxisValue(x: 0.2, y: 0, z: 0)
        )

        let estimate = IMUBiasEstimator.estimateAccelerometerBias(from: highMotionSamples)

        XCTAssertNil(estimate)
    }

    func testGravityCompensatedMotionSampleRemovesBiasAndGravity() {
        let bias = ThreeAxisValue(x: 0.02, y: -0.01, z: 0.03)
        let dynamicAccelerationG = ThreeAxisValue(x: 0.10, y: 0, z: 0)
        let sample = makeSample(
            timestamp: Date(timeIntervalSince1970: 100),
            accelerometerG: ThreeAxisValue(x: 0.12, y: -0.01, z: 1.03),
            gyroscopeRadPS: ThreeAxisValue(x: 0, y: 0, z: 0),
            speedKmh: 0
        )

        let compensated = GravityCompensatedMotionSample(sample: sample, accelerometerBiasG: bias)

        XCTAssertEqual(
            compensated.accelerationMetersPerSecondSquared.x,
            dynamicAccelerationG.x * GravityCompensatedMotionSample.gravitationalAccelerationMetersPerSecondSquared,
            accuracy: 0.000_001
        )
        XCTAssertEqual(compensated.accelerationMetersPerSecondSquared.y, 0, accuracy: 0.000_001)
        XCTAssertEqual(compensated.accelerationMetersPerSecondSquared.z, 0, accuracy: 0.000_001)
    }

    private func stationarySamples(
        count: Int,
        accelerometerBiasG: ThreeAxisValue,
        speedKmh: Double,
        gyroscopeRadPS: ThreeAxisValue
    ) -> [MotionSample] {
        (0..<count).map { index in
            makeSample(
                timestamp: Date(timeIntervalSince1970: Double(index)),
                accelerometerG: ThreeAxisValue(
                    x: accelerometerBiasG.x,
                    y: accelerometerBiasG.y,
                    z: 1 + accelerometerBiasG.z
                ),
                gyroscopeRadPS: gyroscopeRadPS,
                speedKmh: speedKmh
            )
        }
    }

    private func makeSample(
        timestamp: Date,
        accelerometerG: ThreeAxisValue,
        gyroscopeRadPS: ThreeAxisValue,
        speedKmh: Double
    ) -> MotionSample {
        MotionSample(
            timestamp: timestamp,
            gpsCoordinate: nil,
            speedKmh: speedKmh,
            accelerometerG: accelerometerG,
            gyroscopeRadPS: gyroscopeRadPS,
            altitudeMeters: nil,
            altitudeSource: nil,
            altitudeDiagnostics: nil,
            locationDiagnostics: nil,
            sampleSource: .timerFusion
        )
    }
}
