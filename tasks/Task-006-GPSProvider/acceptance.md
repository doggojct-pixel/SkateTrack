# Task-006 Acceptance Checklist

- [ ] `GPSProvider.swift` wraps `CLLocationManager` and implements `CLLocationManagerDelegate`.
- [ ] `GPSProvider` exposes `AnyPublisher<CLLocation, Never>` for filtered location updates.
- [ ] `GPSProvider` exposes km/h speed values converted from `CLLocation.speed`.
- [ ] Accuracy mode uses `kCLLocationAccuracyBest` for active rides.
- [ ] Accuracy mode uses `kCLLocationAccuracyHundredMeters` for stationary power saving.
- [ ] Locations with invalid horizontal accuracy or `horizontalAccuracy > 20` are filtered out.
- [ ] `GPSAuthorizationHandler.swift` handles When-In-Use and Always authorization requests.
- [ ] Provider files do not import SwiftUI or UIKit.
- [ ] Provider files are under 300 lines.
- [ ] Permission strings exist in English and Traditional Chinese `Localizable.strings`.
- [ ] `InfoPlist.strings` contains localized location usage descriptions.
- [ ] iOS target has location usage description build settings.
- [ ] iOS builds successfully.
- [ ] watchOS and macOS still build unchanged.
