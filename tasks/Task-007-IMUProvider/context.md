# Task-007 Context — IMU Provider

Source of truth: SkateTrack Build Plan v1.0, Task-007.

Task-007 establishes the iOS accelerometer and gyroscope provider used later by Sensor Fusion and Fall Detection. It should not create product UI. It is an iOS-only Core layer implementation.

Relevant references:
- PRD v1.2 §5.1.1 sensor table: accelerometer and gyroscope rows.
- UI references: iOS Screen 03 tilt indicator and Watch Screen 07 tilt / gyroscope display.
- DevProcess v1.0: Sensor engine files are `[自主區]`, must avoid UI imports, and must stay under file length limits.
