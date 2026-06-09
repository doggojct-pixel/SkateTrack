# Task-008 Acceptance Checklist

- [ ] `BarometerProvider.swift` wraps `CMAltimeter`.
- [ ] Provider exposes `AnyPublisher<CMAltitudeData, Never>`.
- [ ] Relative altitude is only started when `CMAltimeter.isRelativeAltitudeAvailable()` is true.
- [ ] Unsupported devices do not crash and report unavailable state.
- [ ] No `SwiftUI` or `UIKit` imports.
- [ ] File stays under 200 lines.
- [ ] Zone header exists.
- [ ] iOS target builds.
