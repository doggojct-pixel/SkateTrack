# Task-010 Agent Prompt

Implement the SkateTrack iOS Fall Detection Engine according to Build Plan v1.0 Task-010.

Create `FallDetectionEngine.swift` under `iOS/Core/SensorEngine/`. The engine must monitor `MotionSample` data, detect a G-force spike greater than 4g followed by more than 3 seconds of stationary behavior, publish `FallEvent`, start a 15-second SOS countdown, support `cancelFallAlert()`, and publish an SOS trigger event when the countdown expires.

Respect DevProcess rules: mark files `[自主區]`, avoid UI imports, keep the file under 350 lines, and update `FILE_STRUCTURE.md` / `DEV_LOG.md`.
