// [自主區] iOS/Core/SensorEngine/BarometerProvider.swift
// 用途：封裝 CMAltimeter，提供相對海拔與氣壓資料串流。
// 委派至：Task-009 Sensor Fusion Engine 與後續 Session Summary 海拔剖面。

import Combine
import CoreMotion
import Foundation

enum BarometerProviderState: Equatable, Sendable {
    case idle
    case running
    case unavailable
}

final class BarometerProvider {
    private let altimeter: CMAltimeter
    private let altimeterQueue: OperationQueue

    private let altitudeSubject = PassthroughSubject<CMAltitudeData, Never>()
    private let relativeAltitudeMetersSubject = CurrentValueSubject<Double?, Never>(nil)
    private let pressureKilopascalsSubject = CurrentValueSubject<Double?, Never>(nil)
    private let stateSubject = CurrentValueSubject<BarometerProviderState, Never>(.idle)

    var altitudePublisher: AnyPublisher<CMAltitudeData, Never> {
        altitudeSubject.eraseToAnyPublisher()
    }

    var relativeAltitudeMetersPublisher: AnyPublisher<Double?, Never> {
        relativeAltitudeMetersSubject.eraseToAnyPublisher()
    }

    var pressureKilopascalsPublisher: AnyPublisher<Double?, Never> {
        pressureKilopascalsSubject.eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<BarometerProviderState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var isRelativeAltitudeAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    init(
        altimeter: CMAltimeter = CMAltimeter(),
        altimeterQueue: OperationQueue = OperationQueue()
    ) {
        self.altimeter = altimeter
        self.altimeterQueue = altimeterQueue
        configureQueue()
    }

    func startUpdates() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            publishUnavailableState()
            return
        }

        stateSubject.send(.running)

        altimeter.startRelativeAltitudeUpdates(to: altimeterQueue) { [weak self] data, error in
            guard error == nil, let data else { return }

            self?.altitudeSubject.send(data)
            self?.relativeAltitudeMetersSubject.send(data.relativeAltitude.doubleValue)
            self?.pressureKilopascalsSubject.send(data.pressure.doubleValue)
        }
    }

    func stopUpdates() {
        altimeter.stopRelativeAltitudeUpdates()
        stateSubject.send(.idle)
        relativeAltitudeMetersSubject.send(nil)
        pressureKilopascalsSubject.send(nil)
    }

    private func configureQueue() {
        altimeterQueue.name = "com.jjf.skateTrack.barometerProvider"
        altimeterQueue.qualityOfService = .userInitiated
    }

    private func publishUnavailableState() {
        stateSubject.send(.unavailable)
        relativeAltitudeMetersSubject.send(nil)
        pressureKilopascalsSubject.send(nil)
    }
}
