// [自主區] iOS/Core/SensorEngine/GravityCompensatedMotionSample.swift
// 用途：提供 b17-A replay-only IMU gap interpolation 的重力與 bias 補償樣本。
// 委派至：DeadReckoningEngine replay analysis。

import Foundation

struct GravityCompensatedMotionSample: Sendable, Equatable {
    static let gravitationalAccelerationMetersPerSecondSquared = 9.80665

    let timestamp: Date
    let accelerationMetersPerSecondSquared: ThreeAxisValue
    let gyroscopeRadPS: ThreeAxisValue
    let rawAccelerometerG: ThreeAxisValue
    let accelerometerBiasG: ThreeAxisValue
    let gravityAxisG: ThreeAxisValue

    init(
        sample: MotionSample,
        accelerometerBiasG: ThreeAxisValue = .zero,
        gravityAxisG: ThreeAxisValue = ThreeAxisValue(x: 0, y: 0, z: 1)
    ) {
        self.timestamp = sample.timestamp
        self.rawAccelerometerG = sample.accelerometerG
        self.accelerometerBiasG = accelerometerBiasG
        self.gravityAxisG = gravityAxisG
        self.gyroscopeRadPS = sample.gyroscopeRadPS
        self.accelerationMetersPerSecondSquared = sample.accelerometerG
            .subtracting(accelerometerBiasG)
            .subtracting(gravityAxisG)
            .scaled(by: Self.gravitationalAccelerationMetersPerSecondSquared)
    }
}

extension ThreeAxisValue {
    func scaled(by multiplier: Double) -> ThreeAxisValue {
        ThreeAxisValue(x: x * multiplier, y: y * multiplier, z: z * multiplier)
    }
}
