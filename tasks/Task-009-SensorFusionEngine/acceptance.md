# Task-009 Acceptance Checklist

- [ ] `SensorFusionEngine` conforms to `SensorProvider`.
- [ ] Engine exposes `AnyPublisher<MotionSample, Never>`.
- [ ] Engine publishes at 10Hz through `sampleFrequencyHz` / `sampleIntervalSeconds`.
- [ ] Engine starts and stops `GPSProvider`, `IMUProvider`, and `BarometerProvider`.
- [ ] Engine implements `startSession(mode:) async throws` and `stopSession() async -> SessionData`.
- [ ] Engine maps `SportMode` to a sensor priority plan.
- [ ] No `SwiftUI`, `UIKit`, `AppKit`, or `WatchKit` imports.
- [ ] `SensorFusionEngine.swift` stays under 450 lines.
- [ ] `scripts/verify_sensor_fusion_engine.py` passes.
