// [自主區] iOS/Core/SensorEngine/SensorCalibrationEngine.swift
// 用途：校正 GPS、IMU 與氣壓計資料，讓 SensorFusionEngine 產生更穩定的 MotionSample。
// 委派至：SensorFusionEngine、FallDetectionEngine 與後續 Session Recording。

import Foundation

enum SensorFusionChannel: String, Sendable, CaseIterable {
    case gps
    case imu
    case barometer
}

struct SensorFusionPriorityPlan: Sendable, Equatable {
    let primary: [SensorFusionChannel]
    let secondary: [SensorFusionChannel]
    let supplemental: [SensorFusionChannel]
}

struct SensorCalibrationSnapshot: Sendable, Equatable {
    let accelerationBias: ThreeAxisValue
    let gyroscopeBias: ThreeAxisValue
    let sampleCount: Int

    var isCalibrated: Bool {
        sampleCount >= SensorCalibrationEngine.minimumCalibrationSamples
    }
}

final class SensorCalibrationEngine {
    static let minimumCalibrationSamples = 25

    private var accelerationSum = ThreeAxisValue.zero
    private var gyroscopeSum = ThreeAxisValue.zero
    private var sampleCount = 0

    var snapshot: SensorCalibrationSnapshot {
        SensorCalibrationSnapshot(
            accelerationBias: accelerationBias,
            gyroscopeBias: gyroscopeBias,
            sampleCount: sampleCount
        )
    }

    func reset() {
        accelerationSum = .zero
        gyroscopeSum = .zero
        sampleCount = 0
    }

    func ingest(acceleration: ThreeAxisValue, gyroscope: ThreeAxisValue) {
        guard sampleCount < Self.minimumCalibrationSamples else { return }

        accelerationSum = accelerationSum.adding(acceleration)
        gyroscopeSum = gyroscopeSum.adding(gyroscope)
        sampleCount += 1
    }

    func calibratedAcceleration(from acceleration: ThreeAxisValue) -> ThreeAxisValue {
        // Keep gravity in the stream so fall detection can compare magnitude against 1g.
        acceleration
    }

    func calibratedGyroscope(from gyroscope: ThreeAxisValue) -> ThreeAxisValue {
        guard snapshot.isCalibrated else { return gyroscope }
        return gyroscope.subtracting(gyroscopeBias)
    }

    func priorityPlan(for mode: SportMode) -> SensorFusionPriorityPlan {
        switch mode {
        case let .skateboard(boardMode):
            return skateboardPriorityPlan(for: boardMode)
        case let .inline(inlineMode):
            return inlinePriorityPlan(for: inlineMode)
        case let .snow(discipline):
            return snowPriorityPlan(for: discipline)
        }
    }

    private var accelerationBias: ThreeAxisValue {
        guard sampleCount > 0 else { return .zero }
        return accelerationSum.divided(by: Double(sampleCount))
    }

    private var gyroscopeBias: ThreeAxisValue {
        guard sampleCount > 0 else { return .zero }
        return gyroscopeSum.divided(by: Double(sampleCount))
    }

    private func skateboardPriorityPlan(for mode: BoardMode) -> SensorFusionPriorityPlan {
        switch mode {
        case .streetPark:
            return SensorFusionPriorityPlan(primary: [.imu], secondary: [.gps], supplemental: [.barometer])
        case .longboard:
            return SensorFusionPriorityPlan(primary: [.gps], secondary: [.imu], supplemental: [.barometer])
        case .surfskate:
            return SensorFusionPriorityPlan(primary: [.imu], secondary: [.gps], supplemental: [.barometer])
        case .freebord:
            return SensorFusionPriorityPlan(primary: [.imu, .barometer], secondary: [.gps], supplemental: [])
        }
    }

    private func inlinePriorityPlan(for mode: InlineMode) -> SensorFusionPriorityPlan {
        switch mode {
        case .urbanFreestyle:
            return SensorFusionPriorityPlan(primary: [.imu], secondary: [.gps], supplemental: [.barometer])
        case .fitnessSpeed:
            return SensorFusionPriorityPlan(primary: [.gps], secondary: [.imu], supplemental: [.barometer])
        case .aggressive:
            return SensorFusionPriorityPlan(primary: [.imu], secondary: [.barometer], supplemental: [.gps])
        case .slalom:
            return SensorFusionPriorityPlan(primary: [.imu], secondary: [.gps], supplemental: [.barometer])
        }
    }

    private func snowPriorityPlan(for discipline: SnowDiscipline) -> SensorFusionPriorityPlan {
        switch discipline {
        case .snowboard, .skiing:
            return SensorFusionPriorityPlan(primary: [.gps, .barometer], secondary: [.imu], supplemental: [])
        }
    }
}

extension ThreeAxisValue {
    func adding(_ value: ThreeAxisValue) -> ThreeAxisValue {
        ThreeAxisValue(x: x + value.x, y: y + value.y, z: z + value.z)
    }

    func subtracting(_ value: ThreeAxisValue) -> ThreeAxisValue {
        ThreeAxisValue(x: x - value.x, y: y - value.y, z: z - value.z)
    }

    func divided(by divisor: Double) -> ThreeAxisValue {
        guard divisor != 0 else { return .zero }
        return ThreeAxisValue(x: x / divisor, y: y / divisor, z: z / divisor)
    }

    var magnitude: Double {
        sqrt((x * x) + (y * y) + (z * z))
    }
}
