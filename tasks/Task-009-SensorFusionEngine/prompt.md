# Task-009 Agent Prompt

Implement the SkateTrack iOS Sensor Fusion Engine according to Build Plan v1.0 Task-009.

Create `SensorFusionEngine.swift` and `SensorCalibrationEngine.swift` under `iOS/Core/SensorEngine/`. The engine must consume the existing GPS, IMU, and barometer providers, publish `MotionSample` at 10Hz, conform to `SensorProvider`, and expose `startSession(mode:) async throws` plus `stopSession() async -> SessionData`.

Respect DevProcess rules: mark files `[自主區]`, avoid UI imports, keep files under line limits, and update `FILE_STRUCTURE.md` / `DEV_LOG.md`.
