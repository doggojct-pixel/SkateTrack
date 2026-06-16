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
            return kCLLocationAccuracyBestForNavigation
        case .stationaryPowerSaving:
            return kCLLocationAccuracyHundredMeters
        }
    }

    var distanceFilter: CLLocationDistance {
        switch self {
        case .activeRide:
            return 1
        case .stationaryPowerSaving:
            return 50
        }
    }

    var activityType: CLActivityType {
        switch self {
        case .activeRide:
            return .fitness
        case .stationaryPowerSaving:
            return .other
        }
    }

    var pausesLocationUpdatesAutomatically: Bool {
        switch self {
        case .activeRide:
            return false
        case .stationaryPowerSaving:
            return true
        }
    }
}

final class GPSProvider: NSObject {
    static let preferredRouteHorizontalAccuracy: CLLocationAccuracy = 35
    static let maximumAcceptedHorizontalAccuracy: CLLocationAccuracy = 250

    private let locationManager: CLLocationManager
    private let authorizationHandler: GPSAuthorizationHandling
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let speedSubject = CurrentValueSubject<Double, Never>(0)
    private let authorizationSubject: CurrentValueSubject<CLAuthorizationStatus, Never>

    private var accuracyMode: GPSAccuracyMode = .stationaryPowerSaving
    private var wantsLocationUpdates = false
    private var wantsBackgroundLocationUpdates = false
    private var wantsSignificantLocationChangeBackup = false
    private var didRequestAlwaysAuthorizationUpgrade = false
    private var lastAcceptedLocation: CLLocation?

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
        wantsBackgroundLocationUpdates = accuracyMode == .activeRide
        wantsSignificantLocationChangeBackup = accuracyMode == .activeRide
        setAccuracyMode(accuracyMode)
        configureBackgroundLocationUpdatesIfNeeded()
        #if DEBUG
        recordLocationManagerSnapshot(reason: "startUpdatingLocationConfigured")
        recordAuthorizationSnapshot(reason: "startUpdatingLocation")
        #endif

        if authorizationHandler.shouldRequestAuthorization() {
            authorizationHandler.requestWhenInUseAuthorization()
            return
        }

        guard authorizationHandler.canStartLocationUpdates() else {
            stopUpdatingLocation()
            return
        }

        requestAlwaysAuthorizationUpgradeIfNeeded()
        locationManager.startUpdatingLocation()
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
            RecordingDebugRecoveryEvent(
                eventType: "startUpdatingLocationCalled",
                reason: "startUpdatingLocation"
            )
        )
        #endif
        startSignificantLocationChangeBackupIfNeeded()
    }

    func stopUpdatingLocation() {
        wantsLocationUpdates = false
        wantsBackgroundLocationUpdates = false
        wantsSignificantLocationChangeBackup = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        configureBackgroundLocationUpdatesIfNeeded()
        #if DEBUG
        recordLocationManagerSnapshot(reason: "stopUpdatingLocation")
        RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
            RecordingDebugRecoveryEvent(
                eventType: "stopUpdatingLocationCalled",
                reason: "stopUpdatingLocation"
            )
        )
        #endif
        lastAcceptedLocation = nil
        speedSubject.send(0)
        setAccuracyMode(.stationaryPowerSaving)
    }

    func setAccuracyMode(_ mode: GPSAccuracyMode) {
        accuracyMode = mode
        locationManager.desiredAccuracy = mode.desiredAccuracy
        locationManager.distanceFilter = mode.distanceFilter
        locationManager.activityType = mode.activityType
        locationManager.pausesLocationUpdatesAutomatically = mode.pausesLocationUpdatesAutomatically
    }

    static func kilometersPerHour(fromMetersPerSecond metersPerSecond: CLLocationSpeed) -> Double {
        max(metersPerSecond, 0) * 3.6
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        setAccuracyMode(accuracyMode)
    }

    private func configureBackgroundLocationUpdatesIfNeeded() {
        let declaration = Self.backgroundLocationModeDeclaration()
        let shouldAllowBackgroundUpdates = wantsBackgroundLocationUpdates && declaration.hasLocationBackgroundMode
        locationManager.allowsBackgroundLocationUpdates = shouldAllowBackgroundUpdates
        locationManager.showsBackgroundLocationIndicator = shouldAllowBackgroundUpdates
        locationManager.pausesLocationUpdatesAutomatically = accuracyMode.pausesLocationUpdatesAutomatically
        #if DEBUG
        if wantsBackgroundLocationUpdates && !declaration.hasLocationBackgroundMode {
            RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
                RecordingDebugRecoveryEvent(
                    eventType: "backgroundLocationDeclarationMissingAtRuntime",
                    reason: declaration.uiBackgroundModesRawDescription ?? "UIBackgroundModesMissing"
                )
            )
        }
        #endif
    }

    private func requestAlwaysAuthorizationUpgradeIfNeeded() {
        guard wantsBackgroundLocationUpdates else { return }
        guard Self.hasBackgroundLocationModeDeclared else { return }
        guard !didRequestAlwaysAuthorizationUpgrade else { return }
        guard authorizationHandler.canRequestAlwaysAuthorizationUpgrade() else { return }

        didRequestAlwaysAuthorizationUpgrade = true
        authorizationHandler.requestAlwaysAuthorization()
    }

    private func startSignificantLocationChangeBackupIfNeeded() {
        guard wantsSignificantLocationChangeBackup else { return }
        locationManager.startMonitoringSignificantLocationChanges()
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordRecoveryEvent(
            RecordingDebugRecoveryEvent(
                eventType: "startMonitoringSignificantLocationChangesCalled",
                reason: "activeRideBackup"
            )
        )
        recordLocationManagerSnapshot(reason: "significantLocationBackupStarted")
        #endif
    }

    private static var hasBackgroundLocationModeDeclared: Bool {
        backgroundLocationModeDeclaration().hasLocationBackgroundMode
    }

    private static func backgroundLocationModeDeclaration() -> RecordingDebugBundleInfoSnapshot {
        let rawValue = backgroundModesRawValue()
        let modes = normalizedBackgroundModes(from: rawValue)
        return RecordingDebugBundleInfoSnapshot(
            bundleIdentifier: Bundle.main.bundleIdentifier,
            bundlePathLastComponent: Bundle.main.bundleURL.lastPathComponent,
            executablePathLastComponent: Bundle.main.executableURL?.lastPathComponent,
            hasUIBackgroundModesKey: rawValue != nil,
            uiBackgroundModesRawDescription: rawValue.map { String(describing: $0) },
            resolvedUIBackgroundModes: modes,
            hasLocationBackgroundMode: modes.contains("location")
        )
    }

    private static func backgroundModesRawValue() -> Any? {
        if let value = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") {
            return value
        }
        if let value = Bundle.main.infoDictionary?["UIBackgroundModes"] {
            return value
        }
        if let value = Bundle.main.localizedInfoDictionary?["UIBackgroundModes"] {
            return value
        }
        let infoPlistURL = Bundle.main.bundleURL.appendingPathComponent("Info.plist")
        return (NSDictionary(contentsOf: infoPlistURL) as? [String: Any])?["UIBackgroundModes"]
    }

    private static func normalizedBackgroundModes(from rawValue: Any?) -> [String] {
        func normalize(_ value: String) -> [String] {
            value
                .components(separatedBy: CharacterSet(charactersIn: ",;()[]\n\t "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        }

        if let modes = rawValue as? [String] {
            return Array(Set(modes.flatMap(normalize))).sorted()
        }
        if let modes = rawValue as? [Any] {
            return Array(Set(modes.flatMap { normalize(String(describing: $0)) })).sorted()
        }
        if let mode = rawValue as? String {
            return Array(Set(normalize(mode))).sorted()
        }
        if let mode = rawValue {
            return Array(Set(normalize(String(describing: mode)))).sorted()
        }
        return []
    }

    private func publishIfAccurate(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0 else {
            #if DEBUG
            RecordingDebugDiagnosticsCollector.shared.recordFilterDecision(accepted: false, reason: "missingHorizontalAccuracy")
            #endif
            return
        }
        guard location.horizontalAccuracy <= Self.maximumAcceptedHorizontalAccuracy else {
            #if DEBUG
            RecordingDebugDiagnosticsCollector.shared.recordFilterDecision(accepted: false, reason: "horizontalAccuracyTooPoor")
            #endif
            return
        }

        // Keep lower-confidence-but-valid fixes during screen-off pocket sessions.
        // Route confidence and diagnostics decide how to render or trust them later.
        let speedKmh = effectiveSpeedKilometersPerHour(for: location)
        lastAcceptedLocation = location
        #if DEBUG
        RecordingDebugDiagnosticsCollector.shared.recordFilterDecision(accepted: true, reason: "acceptedLocationFix")
        #endif
        locationSubject.send(location)
        speedSubject.send(speedKmh)
    }

    private func effectiveSpeedKilometersPerHour(for location: CLLocation) -> Double {
        if location.speed >= 0 {
            return Self.kilometersPerHour(fromMetersPerSecond: location.speed)
        }

        guard let lastAcceptedLocation else { return 0 }
        let elapsedSeconds = location.timestamp.timeIntervalSince(lastAcceptedLocation.timestamp)
        guard elapsedSeconds >= 0.5 else { return 0 }

        let distanceMeters = location.distance(from: lastAcceptedLocation)
        guard distanceMeters >= 1 else { return 0 }

        let derivedSpeedKmh = (distanceMeters / elapsedSeconds) * 3.6
        guard derivedSpeedKmh <= ActivityFidelityPolicy.maximumGlobalPlausibleSpeedKmh else { return 0 }
        return max(derivedSpeedKmh, 0)
    }

    #if DEBUG
    private func recordLocationCallback(eventType: String, locations: [CLLocation], error: Error?) {
        let newest = locations.last
        let now = Date()
        let sourceInfo = newest.flatMap { location -> (Bool?, Bool?) in
            if #available(iOS 15.0, *) {
                return (
                    location.sourceInformation?.isSimulatedBySoftware,
                    location.sourceInformation?.isProducedByAccessory
                )
            }
            return (nil, nil)
        }
        RecordingDebugDiagnosticsCollector.shared.recordLocationCallbackEvent(
            RecordingDebugLocationCallbackEvent(
                timestamp: now,
                eventType: eventType,
                locationBatchCount: locations.count,
                newestLocationTimestamp: newest?.timestamp,
                newestLocationAgeSeconds: newest.map { now.timeIntervalSince($0.timestamp) },
                horizontalAccuracyMeters: newest.flatMap { normalizedAccuracy($0.horizontalAccuracy) },
                verticalAccuracyMeters: newest.flatMap { normalizedAccuracy($0.verticalAccuracy) },
                speedKmh: newest.map { Self.kilometersPerHour(fromMetersPerSecond: max($0.speed, 0)) },
                speedAccuracyMetersPerSecond: newest.flatMap { normalizedAccuracy($0.speedAccuracy) },
                courseDegrees: newest?.course,
                courseAccuracyDegrees: newest.flatMap { location in
                    if #available(iOS 13.4, *) {
                        return normalizedAccuracy(location.courseAccuracy)
                    }
                    return nil
                },
                isSimulatedBySoftware: sourceInfo?.0,
                isProducedByAccessory: sourceInfo?.1,
                errorDescription: error.map { String(describing: $0) }
            )
        )
    }

    private func recordLocationManagerSnapshot(reason: String) {
        RecordingDebugDiagnosticsCollector.shared.recordLocationManagerSnapshot(
            RecordingDebugLocationManagerSnapshot(
                reason: reason,
                desiredAccuracy: locationManager.desiredAccuracy,
                distanceFilterMeters: locationManager.distanceFilter,
                activityType: Self.activityTypeDescription(locationManager.activityType),
                pausesLocationUpdatesAutomatically: locationManager.pausesLocationUpdatesAutomatically,
                allowsBackgroundLocationUpdates: locationManager.allowsBackgroundLocationUpdates,
                showsBackgroundLocationIndicator: locationManager.showsBackgroundLocationIndicator,
                isSignificantLocationChangeMonitoringActive: wantsSignificantLocationChangeBackup,
                wantsLocationUpdates: wantsLocationUpdates,
                wantsBackgroundLocationUpdates: wantsBackgroundLocationUpdates,
                hasBackgroundLocationModeDeclared: Self.hasBackgroundLocationModeDeclared,
                bundleInfo: Self.backgroundLocationModeDeclaration(),
                authorizationStatus: Self.authorizationDescription(locationManager.authorizationStatus),
                accuracyAuthorization: Self.accuracyAuthorizationDescription(locationManager.accuracyAuthorization)
            )
        )
    }

    private func recordAuthorizationSnapshot(reason: String) {
        RecordingDebugDiagnosticsCollector.shared.recordAuthorizationSnapshot(
            RecordingDebugAuthorizationSnapshot(
                reason: reason,
                authorizationStatus: Self.authorizationDescription(locationManager.authorizationStatus),
                accuracyAuthorization: Self.accuracyAuthorizationDescription(locationManager.accuracyAuthorization),
                locationServicesEnabled:
                    locationManager.authorizationStatus != .denied &&
                    locationManager.authorizationStatus != .restricted,
                backgroundRefreshStatus: nil
            )
        )
    }

    private func normalizedAccuracy(_ accuracy: CLLocationAccuracy) -> Double? {
        accuracy >= 0 ? accuracy : nil
    }

    private static func authorizationDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }

    private static func accuracyAuthorizationDescription(_ authorization: CLAccuracyAuthorization) -> String {
        switch authorization {
        case .fullAccuracy: return "fullAccuracy"
        case .reducedAccuracy: return "reducedAccuracy"
        @unknown default: return "unknown"
        }
    }

    private static func activityTypeDescription(_ activityType: CLActivityType) -> String {
        switch activityType {
        case .other: return "other"
        case .automotiveNavigation: return "automotiveNavigation"
        case .fitness: return "fitness"
        case .otherNavigation: return "otherNavigation"
        case .airborne: return "airborne"
        @unknown default: return "unknown"
        }
    }
    #endif

}

extension GPSProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        #if DEBUG
        recordLocationCallback(eventType: "didUpdateLocations", locations: locations, error: nil)
        #endif
        locations.forEach(publishIfAccurate)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationSubject.send(manager.authorizationStatus)
        #if DEBUG
        recordAuthorizationSnapshot(reason: "locationManagerDidChangeAuthorization")
        recordLocationManagerSnapshot(reason: "authorizationChanged")
        #endif

        guard wantsLocationUpdates else { return }

        if authorizationHandler.canStartLocationUpdates() {
            configureBackgroundLocationUpdatesIfNeeded()
            requestAlwaysAuthorizationUpgradeIfNeeded()
            manager.startUpdatingLocation()
            startSignificantLocationChangeBackupIfNeeded()
        } else if !authorizationHandler.shouldRequestAuthorization() {
            stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        recordLocationCallback(eventType: "didFailWithError", locations: [], error: error)
        #endif
        if let locationError = error as? CLError, locationError.code == .denied {
            stopUpdatingLocation()
        }
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        #if DEBUG
        recordLocationCallback(eventType: "didPauseLocationUpdates", locations: [], error: nil)
        recordLocationManagerSnapshot(reason: "didPauseLocationUpdates")
        #endif
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        #if DEBUG
        recordLocationCallback(eventType: "didResumeLocationUpdates", locations: [], error: nil)
        recordLocationManagerSnapshot(reason: "didResumeLocationUpdates")
        #endif
    }
}
