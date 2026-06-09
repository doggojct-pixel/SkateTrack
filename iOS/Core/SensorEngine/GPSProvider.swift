// [自主區] iOS/Core/SensorEngine/GPSProvider.swift
// 用途：封裝 CLLocationManager，提供過濾後的位置與速度串流給後續感測器融合引擎。
// 委派至：Task-009 Sensor Fusion Engine 與 Task-011 Session Recording 啟動流程。

import Combine
import CoreLocation
import Foundation

enum GPSAccuracyMode: Equatable, Sendable {
    case activeRide
    case stationaryPowerSaving

    var desiredAccuracy: CLLocationAccuracy {
        switch self {
        case .activeRide:
            return kCLLocationAccuracyBest
        case .stationaryPowerSaving:
            return kCLLocationAccuracyHundredMeters
        }
    }

    var distanceFilter: CLLocationDistance {
        switch self {
        case .activeRide:
            return 3
        case .stationaryPowerSaving:
            return 50
        }
    }
}

final class GPSProvider: NSObject {
    static let maximumAcceptedHorizontalAccuracy: CLLocationAccuracy = 20

    private let locationManager: CLLocationManager
    private let authorizationHandler: GPSAuthorizationHandling
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let speedSubject = CurrentValueSubject<Double, Never>(0)
    private let authorizationSubject: CurrentValueSubject<CLAuthorizationStatus, Never>

    private var accuracyMode: GPSAccuracyMode = .stationaryPowerSaving
    private var wantsLocationUpdates = false

    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    var speedKilometersPerHourPublisher: AnyPublisher<Double, Never> {
        speedSubject.eraseToAnyPublisher()
    }

    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationSubject.eraseToAnyPublisher()
    }

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        self.authorizationHandler = GPSAuthorizationHandler(locationManager: locationManager)
        self.authorizationSubject = CurrentValueSubject(locationManager.authorizationStatus)
        super.init()
        configureLocationManager()
    }

    func requestWhenInUseAuthorization() {
        authorizationHandler.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        authorizationHandler.requestAlwaysAuthorization()
    }

    func startUpdatingLocation(accuracyMode: GPSAccuracyMode = .activeRide) {
        wantsLocationUpdates = true
        setAccuracyMode(accuracyMode)

        if authorizationHandler.shouldRequestAuthorization() {
            authorizationHandler.requestWhenInUseAuthorization()
            return
        }

        guard authorizationHandler.canStartLocationUpdates() else {
            stopUpdatingLocation()
            return
        }

        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        wantsLocationUpdates = false
        locationManager.stopUpdatingLocation()
        speedSubject.send(0)
        setAccuracyMode(.stationaryPowerSaving)
    }

    func setAccuracyMode(_ mode: GPSAccuracyMode) {
        accuracyMode = mode
        locationManager.desiredAccuracy = mode.desiredAccuracy
        locationManager.distanceFilter = mode.distanceFilter
    }

    static func kilometersPerHour(fromMetersPerSecond metersPerSecond: CLLocationSpeed) -> Double {
        max(metersPerSecond, 0) * 3.6
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
        setAccuracyMode(accuracyMode)
    }

    private func publishIfAccurate(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0 else { return }
        guard location.horizontalAccuracy <= Self.maximumAcceptedHorizontalAccuracy else { return }

        locationSubject.send(location)
        speedSubject.send(Self.kilometersPerHour(fromMetersPerSecond: location.speed))
    }
}

extension GPSProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach(publishIfAccurate)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationSubject.send(manager.authorizationStatus)

        guard wantsLocationUpdates else { return }

        if authorizationHandler.canStartLocationUpdates() {
            manager.startUpdatingLocation()
        } else if !authorizationHandler.shouldRequestAuthorization() {
            stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .denied {
            stopUpdatingLocation()
        }
    }
}
