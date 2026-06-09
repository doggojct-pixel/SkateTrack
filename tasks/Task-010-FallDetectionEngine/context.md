# Task-010 Context — Fall Detection Engine

Source of truth: SkateTrack Build Plan v1.0, Task-010.

Task-010 establishes the iOS fall detection engine. It monitors fused `MotionSample` data, detects an impact G-force spike followed by post-impact stationary behavior, publishes a `FallEvent`, and runs a cancellable SOS countdown. This is core infrastructure only; the user-facing alert UI is deferred to later tasks.

Relevant references:
- PRD v1.2 §5.2: fall detection and SOS flow.
- UI references: iOS Screen 09 Fall Alert and Watch Screen 11 Fall SOS.
- DevProcess v1.0: Sensor engine files are `[自主區]`, must avoid UI imports, and must stay below file length limits.
