// [自主區] iOS/Core/SensorEngine/GPSAuthorizationHandler.swift
// 用途：封裝 iOS 位置權限請求與狀態判斷，避免 GPSProvider 直接散落權限邏輯。
// 委派至：iOS/Core/SensorEngine/GPSProvider.swift 在開始 GPS 串流前呼叫。

import CoreLocation
import Foundation

protocol GPSAuthorizationHandling: AnyObject {
    var currentStatus: CLAuthorizationStatus { get }

    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func canStartLocationUpdates() -> Bool
    func shouldRequestAuthorization() -> Bool
}

final class GPSAuthorizationHandler: GPSAuthorizationHandling {
    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }

    var currentStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        locationManager.requestAlwaysAuthorization()
    }

    func canStartLocationUpdates() -> Bool {
        guard CLLocationManager.locationServicesEnabled() else { return false }

        switch currentStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        case .denied, .notDetermined, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func shouldRequestAuthorization() -> Bool {
        currentStatus == .notDetermined
    }
}
