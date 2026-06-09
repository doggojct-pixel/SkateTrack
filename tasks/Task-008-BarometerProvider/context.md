# Task-008 Context — Barometer Provider

Source of truth: SkateTrack Build Plan v1.0, Task-008.

Task-008 establishes the iOS barometer / relative-altitude provider used later by Sensor Fusion and Session Summary elevation charts. It should not create product UI. It is an iOS-only Core layer implementation.

Relevant references:
- PRD v1.2 §5.1.1 sensor table: barometer row.
- UI reference: iOS Screen 04 Session Summary elevation profile.
- DevProcess v1.0: Sensor engine files are `[自主區]`, must avoid UI imports, and must stay under file length limits.
