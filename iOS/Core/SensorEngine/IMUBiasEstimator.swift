// [自主區] iOS/Core/SensorEngine/IMUBiasEstimator.swift
// 用途：提供 b17-A replay-only IMU gap interpolation 的靜止低動態 bias 估計基礎。
// 委派至：DeadReckoningEngine replay analysis 與 GravityCompensatedMotionSample。

import Foundation

struct IMUBiasEstimatorConfig: Sendable, Equatable {
    let minimumStationarySampleCount: Int
    let maximumStationarySpeedKmh: Double
    let maximumGyroscopeMagnitudeRadPS: Double
    let accelerationMagnitudeToleranceG: Double
    let gravityAxisG: ThreeAxisValue

    init(
        minimumStationarySampleCount: Int = 5,
        maximumStationarySpeedKmh: Double = 0.8,
        maximumGyroscopeMagnitudeRadPS: Double = 0.08,
        accelerationMagnitudeToleranceG: Double = 0.08,
        gravityAxisG: ThreeAxisValue = ThreeAxisValue(x: 0, y: 0, z: 1)
    ) {
        self.minimumStationarySampleCount = max(1, minimumStationarySampleCount)
        self.maximumStationarySpeedKmh = max(0, maximumStationarySpeedKmh)
        self.maximumGyroscopeMagnitudeRadPS = max(0, maximumGyroscopeMagnitudeRadPS)
        self.accelerationMagnitudeToleranceG = max(0, accelerationMagnitudeToleranceG)
        self.gravityAxisG = gravityAxisG
    }
}

struct IMUBiasEstimate: Codable, Sendable, Equatable {
    let accelerometerBiasG: ThreeAxisValue
    let sampleCount: Int
    let stationaryWindowDurationSeconds: TimeInterval

    init(accelerometerBiasG: ThreeAxisValue, sampleCount: Int, stationaryWindowDurationSeconds: TimeInterval) {
        self.accelerometerBiasG = accelerometerBiasG
        self.sampleCount = sampleCount
        self.stationaryWindowDurationSeconds = max(0, stationaryWindowDurationSeconds)
    }
}

enum IMUBiasEstimator {
    static func estimateAccelerometerBias(
        from samples: [MotionSample],
        config: IMUBiasEstimatorConfig = IMUBiasEstimatorConfig()
    ) -> IMUBiasEstimate? {
        let stationarySamples = samples.filter { isStationary(sample: $0, config: config) }
        guard stationarySamples.count >= config.minimumStationarySampleCount else { return nil }

        let accumulatedBias = stationarySamples.reduce(ThreeAxisValue.zero) { partial, sample in
            partial.adding(sample.accelerometerG.subtracting(config.gravityAxisG))
        }
        let bias = accumulatedBias.divided(by: Double(stationarySamples.count))
        let duration = stationaryWindowDurationSeconds(from: stationarySamples)
        return IMUBiasEstimate(
            accelerometerBiasG: bias,
            sampleCount: stationarySamples.count,
            stationaryWindowDurationSeconds: duration
        )
    }

    static func isStationary(
        sample: MotionSample,
        config: IMUBiasEstimatorConfig = IMUBiasEstimatorConfig()
    ) -> Bool {
        guard sample.speedKmh <= config.maximumStationarySpeedKmh else { return false }
        guard sample.gyroscopeRadPS.magnitude <= config.maximumGyroscopeMagnitudeRadPS else { return false }
        let accelerationMagnitudeDelta = abs(sample.accelerometerG.magnitude - config.gravityAxisG.magnitude)
        return accelerationMagnitudeDelta <= config.accelerationMagnitudeToleranceG
    }

    private static func stationaryWindowDurationSeconds(from samples: [MotionSample]) -> TimeInterval {
        guard let firstTimestamp = samples.first?.timestamp,
              let lastTimestamp = samples.last?.timestamp else { return 0 }
        return max(0, lastTimestamp.timeIntervalSince(firstTimestamp))
    }
}
