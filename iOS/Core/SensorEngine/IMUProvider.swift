// [自主區] iOS/Core/SensorEngine/IMUProvider.swift
// 用途：封裝 CMMotionManager，以 50Hz 提供加速度計與陀螺儀資料串流。
// 委派至：Task-009 Sensor Fusion Engine 與 Task-010 Fall Detection Engine。

import Combine
import CoreMotion
import Foundation

struct IMUAvailability: Equatable, Sendable {
    let isAccelerometerAvailable: Bool
    let isGyroscopeAvailable: Bool

    var canPublishRawMotion: Bool {
        isAccelerometerAvailable || isGyroscopeAvailable
    }

    static let unavailable = IMUAvailability(
        isAccelerometerAvailable: false,
        isGyroscopeAvailable: false
    )
}

final class IMUProvider {
    static let targetFrequencyHz: Double = 50
    static let targetUpdateInterval: TimeInterval = 1 / targetFrequencyHz

    private let motionManager: CMMotionManager
    private let motionQueue: OperationQueue

    private let accelerometerSubject = PassthroughSubject<CMAccelerometerData, Never>()
    private let gyroscopeSubject = PassthroughSubject<CMGyroData, Never>()
    private let accelerationVectorSubject = CurrentValueSubject<ThreeAxisValue, Never>(.zero)
    private let gyroscopeVectorSubject = CurrentValueSubject<ThreeAxisValue, Never>(.zero)
    private let availabilitySubject: CurrentValueSubject<IMUAvailability, Never>

    private(set) var isRunning = false

    var accelerometerPublisher: AnyPublisher<CMAccelerometerData, Never> {
        accelerometerSubject.eraseToAnyPublisher()
    }

    var gyroscopePublisher: AnyPublisher<CMGyroData, Never> {
        gyroscopeSubject.eraseToAnyPublisher()
    }

    var accelerationVectorPublisher: AnyPublisher<ThreeAxisValue, Never> {
        accelerationVectorSubject.eraseToAnyPublisher()
    }

    var gyroscopeVectorPublisher: AnyPublisher<ThreeAxisValue, Never> {
        gyroscopeVectorSubject.eraseToAnyPublisher()
    }

    var availabilityPublisher: AnyPublisher<IMUAvailability, Never> {
        availabilitySubject.eraseToAnyPublisher()
    }

    init(
        motionManager: CMMotionManager = CMMotionManager(),
        motionQueue: OperationQueue = OperationQueue()
    ) {
        self.motionManager = motionManager
        self.motionQueue = motionQueue
        self.availabilitySubject = CurrentValueSubject(
            IMUAvailability(
                isAccelerometerAvailable: motionManager.isAccelerometerAvailable,
                isGyroscopeAvailable: motionManager.isGyroAvailable
            )
        )
        configureMotionManager()
        configureQueue()
    }

    func startUpdates() {
        guard !isRunning else { return }

        configureMotionManager()
        publishCurrentAvailability()

        let canStartAccelerometer = motionManager.isAccelerometerAvailable
        let canStartGyroscope = motionManager.isGyroAvailable

        guard canStartAccelerometer || canStartGyroscope else {
            publishZeroVectorsForUnavailableSensors()
            return
        }

        isRunning = true

        if canStartAccelerometer {
            startAccelerometerUpdates()
        } else {
            accelerationVectorSubject.send(.zero)
        }

        if canStartGyroscope {
            startGyroscopeUpdates()
        } else {
            gyroscopeVectorSubject.send(.zero)
        }
    }

    func stopUpdates() {
        guard isRunning else { return }

        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        isRunning = false
        accelerationVectorSubject.send(.zero)
        gyroscopeVectorSubject.send(.zero)
    }

    func publishCurrentAvailability() {
        availabilitySubject.send(
            IMUAvailability(
                isAccelerometerAvailable: motionManager.isAccelerometerAvailable,
                isGyroscopeAvailable: motionManager.isGyroAvailable
            )
        )
    }

    private func configureMotionManager() {
        motionManager.accelerometerUpdateInterval = Self.targetUpdateInterval
        motionManager.gyroUpdateInterval = Self.targetUpdateInterval
    }

    private func configureQueue() {
        motionQueue.name = "com.jjf.skateTrack.imuProvider"
        motionQueue.qualityOfService = .userInitiated
    }

    private func startAccelerometerUpdates() {
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, error in
            guard error == nil, let data else { return }

            self?.accelerometerSubject.send(data)
            self?.accelerationVectorSubject.send(Self.vector(from: data.acceleration))
        }
    }

    private func startGyroscopeUpdates() {
        motionManager.startGyroUpdates(to: motionQueue) { [weak self] data, error in
            guard error == nil, let data else { return }

            self?.gyroscopeSubject.send(data)
            self?.gyroscopeVectorSubject.send(Self.vector(from: data.rotationRate))
        }
    }

    private func publishZeroVectorsForUnavailableSensors() {
        accelerationVectorSubject.send(.zero)
        gyroscopeVectorSubject.send(.zero)
    }

    private static func vector(from acceleration: CMAcceleration) -> ThreeAxisValue {
        ThreeAxisValue(x: acceleration.x, y: acceleration.y, z: acceleration.z)
    }

    private static func vector(from rotationRate: CMRotationRate) -> ThreeAxisValue {
        ThreeAxisValue(x: rotationRate.x, y: rotationRate.y, z: rotationRate.z)
    }
}

extension ThreeAxisValue {
    static let zero = ThreeAxisValue(x: 0, y: 0, z: 0)
}
