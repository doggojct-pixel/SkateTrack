# Task-009 Context — Sensor Fusion Engine

Source of truth: SkateTrack Build Plan v1.0, Task-009.

Task-009 establishes the iOS Sensor Fusion Engine that merges GPS, IMU, and barometer streams into a single 10Hz `MotionSample` publisher. This is core infrastructure only and must not introduce product UI.

Relevant references:
- PRD v1.2 §5.1: `MotionSample` model and sensor table.
- UI reference: iOS Screen 03 Live HUD metrics will later consume this stream.
- DevProcess v1.0: Sensor engine files are `[自主區]`, must avoid UI imports, and must stay below file length limits.
