// [自主區] iOS/Core/SensorEngine/SensorFusionEngine.swift
// 用途：將 GPS、IMU 與氣壓計資料融合為 10Hz MotionSample 串流。
// 委派至：Session Recording、Live HUD、FallDetectionEngine 與後續資料管線。

import Combine
import CoreLocation
import Foundation

enum SensorFusionEngineError: Error, Sendable {
    case sessionAlreadyRunning
}

final class SensorFusionEngine: SensorProvider {
    static let sampleFrequencyHz: Double = 10
    static let sampleIntervalSeconds: TimeInterval = 1 / sampleFrequencyHz

    private let gpsProvider: GPSProvider
    private let imuProvider: IMUProvider
    private let barometerProvider: BarometerProvider
    private let calibrationEngine: SensorCalibrationEngine
    private let sampleQueue = DispatchQueue(label: "com.jjf.skateTrack.sensorFusionEngine")
    private let stateLock = NSLock()

    private let motionSampleSubject = PassthroughSubject<MotionSample, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var sampleTimer: DispatchSourceTimer?

    private var currentMode: SportMode?
    private var currentPriorityPlan: SensorFusionPriorityPlan?
    private var sessionStartDate: Date?
    private var sessionSamples: [MotionSample] = []
    private var latestCoordinate: GeoCoordinate?
    private var latestSpeedKmh: Double = 0
    private var latestAcceleration = ThreeAxisValue.zero
    private var latestGyroscope = ThreeAxisValue.zero
    private var latestAltitudeMeters: Double?

    var motionSamplePublisher: AnyPublisher<MotionSample, Never> {
        motionSampleSubject.eraseToAnyPublisher()
    }

    init(
        gpsProvider: GPSProvider = GPSProvider(),
        imuProvider: IMUProvider = IMUProvider(),
        barometerProvider: BarometerProvider = BarometerProvider(),
        calibrationEngine: SensorCalibrationEngine = SensorCalibrationEngine()
    ) {
        self.gpsProvider = gpsProvider
        self.imuProvider = imuProvider
        self.barometerProvider = barometerProvider
        self.calibrationEngine = calibrationEngine
    }

    func startSession(mode: SportMode) async throws {
        let alreadyRunning = stateLock.withLock {
            sessionStartDate != nil
        }

        guard !alreadyRunning else {
            throw SensorFusionEngineError.sessionAlreadyRunning
        }

        resetSessionState(mode: mode)
        bindProviderStreams()
        startProviderUpdates(for: mode)
        startSampleTimer()
    }

    func stopSession() async -> SessionData {
        stopSampleTimer()
        stopProviderUpdates()
        cancellables.removeAll()

        let snapshot = sessionSnapshot()
        resetTransientState()

        return try! SessionData(
            startDate: snapshot.startDate,
            endDate: Date(),
            sportMode: snapshot.mode,
            motionSamples: snapshot.samples
        )
    }

    func startRecording(mode: SportMode) async throws {
        try await startSession(mode: mode)
    }

    func stopRecording() async -> SessionData {
        await stopSession()
    }

    func priorityPlan(for mode: SportMode) -> SensorFusionPriorityPlan {
        calibrationEngine.priorityPlan(for: mode)
    }

    private func resetSessionState(mode: SportMode) {
        stateLock.withLock {
            currentMode = mode
            currentPriorityPlan = calibrationEngine.priorityPlan(for: mode)
            sessionStartDate = Date()
            sessionSamples = []
            latestCoordinate = nil
            latestSpeedKmh = 0
            latestAcceleration = .zero
            latestGyroscope = .zero
            latestAltitudeMeters = nil
            calibrationEngine.reset()
        }
    }

    private func bindProviderStreams() {
        cancellables.removeAll()

        gpsProvider.locationPublisher
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)

        gpsProvider.speedKilometersPerHourPublisher
            .sink { [weak self] speedKmh in
                self?.updateSpeed(speedKmh)
            }
            .store(in: &cancellables)

        imuProvider.accelerationVectorPublisher
            .sink { [weak self] acceleration in
                self?.updateAcceleration(acceleration)
            }
            .store(in: &cancellables)

        imuProvider.gyroscopeVectorPublisher
            .sink { [weak self] gyroscope in
                self?.updateGyroscope(gyroscope)
            }
            .store(in: &cancellables)

        barometerProvider.relativeAltitudeMetersPublisher
            .sink { [weak self] altitude in
                self?.updateAltitude(altitude)
            }
            .store(in: &cancellables)
    }

    private func startProviderUpdates(for mode: SportMode) {
        let plan = calibrationEngine.priorityPlan(for: mode)
        let gpsMode: GPSAccuracyMode = plan.primary.contains(.gps) ? .activeRide : .stationaryPowerSaving

        gpsProvider.startUpdatingLocation(accuracyMode: gpsMode)
        imuProvider.startUpdates()
        barometerProvider.startUpdates()
    }

    private func stopProviderUpdates() {
        gpsProvider.stopUpdatingLocation()
        imuProvider.stopUpdates()
        barometerProvider.stopUpdates()
    }

    private func startSampleTimer() {
        let timer = DispatchSource.makeTimerSource(queue: sampleQueue)
        timer.schedule(deadline: .now(), repeating: Self.sampleIntervalSeconds)
        timer.setEventHandler { [weak self] in
            self?.publishCurrentMotionSample()
        }
        sampleTimer = timer
        timer.resume()
    }

    private func stopSampleTimer() {
        sampleTimer?.cancel()
        sampleTimer = nil
    }

    private func publishCurrentMotionSample() {
        let sample = makeMotionSample()

        stateLock.withLock {
            sessionSamples.append(sample)
        }

        motionSampleSubject.send(sample)
    }

    private func makeMotionSample() -> MotionSample {
        let snapshot = stateLock.withLock { () -> (
            coordinate: GeoCoordinate?,
            speedKmh: Double,
            acceleration: ThreeAxisValue,
            gyroscope: ThreeAxisValue,
            altitude: Double?,
            calibratedAcceleration: ThreeAxisValue,
            calibratedGyroscope: ThreeAxisValue
        ) in
            let coordinate = latestCoordinate
            let speedKmh = latestSpeedKmh
            let acceleration = latestAcceleration
            let gyroscope = latestGyroscope
            let altitude = latestAltitudeMeters
            calibrationEngine.ingest(acceleration: acceleration, gyroscope: gyroscope)
            let calibratedAcceleration = calibrationEngine.calibratedAcceleration(from: acceleration)
            let calibratedGyroscope = calibrationEngine.calibratedGyroscope(from: gyroscope)

            return (
                coordinate,
                speedKmh,
                acceleration,
                gyroscope,
                altitude,
                calibratedAcceleration,
                calibratedGyroscope
            )
        }

        return MotionSample(
            timestamp: Date(),
            gpsCoordinate: snapshot.coordinate,
            speedKmh: snapshot.speedKmh,
            accelerometerG: snapshot.calibratedAcceleration,
            gyroscopeRadPS: snapshot.calibratedGyroscope,
            altitudeMeters: snapshot.altitude
        )
    }

    private func updateLocation(_ location: CLLocation) {
        stateLock.withLock {
            latestCoordinate = GeoCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    private func updateSpeed(_ speedKmh: Double) {
        stateLock.withLock {
            latestSpeedKmh = speedKmh
        }
    }

    private func updateAcceleration(_ acceleration: ThreeAxisValue) {
        stateLock.withLock {
            latestAcceleration = acceleration
        }
    }

    private func updateGyroscope(_ gyroscope: ThreeAxisValue) {
        stateLock.withLock {
            latestGyroscope = gyroscope
        }
    }

    private func updateAltitude(_ altitude: Double?) {
        stateLock.withLock {
            latestAltitudeMeters = altitude
        }
    }

    private func sessionSnapshot() -> (startDate: Date, mode: SportMode, samples: [MotionSample]) {
        stateLock.withLock {
            let startDate = sessionStartDate ?? Date()
            let mode = currentMode ?? .skateboard(.streetPark)
            let samples = sessionSamples
            return (startDate, mode, samples)
        }
    }

    private func resetTransientState() {
        stateLock.withLock {
            currentMode = nil
            currentPriorityPlan = nil
            sessionStartDate = nil
            latestCoordinate = nil
            latestSpeedKmh = 0
            latestAcceleration = .zero
            latestGyroscope = .zero
            latestAltitudeMeters = nil
        }
    }
}
