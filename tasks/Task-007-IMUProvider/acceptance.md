# Task-007 Acceptance Checklist

- [ ] `IMUProvider.swift` wraps `CMMotionManager`.
- [ ] Accelerometer update interval is 50Hz.
- [ ] Gyroscope update interval is 50Hz.
- [ ] Raw publishers expose `AnyPublisher<CMAccelerometerData, Never>` and `AnyPublisher<CMGyroData, Never>`.
- [ ] Normalized vector publishers safely provide zero vectors when simulator / unavailable sensors cannot publish raw CoreMotion objects.
- [ ] Unsupported sensor states do not crash.
- [ ] No `SwiftUI` or `UIKit` imports.
- [ ] File stays under 300 lines.
- [ ] Zone header exists.
- [ ] iOS target builds.
