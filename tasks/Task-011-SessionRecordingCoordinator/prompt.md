# Task-011 Agent Prompt

Implement SkateTrack Task-011: Session Recording Coordinator + Hook according to the Build Plan Task 011-020 pack.

Create `SessionStateMachine.swift`, `SessionMetricsAccumulator.swift`, and `SessionRecordingCoordinator.swift` under `iOS/Core/SessionRecording/`. Create `useSessionRecording.swift` under `iOS/Hooks/`. Extend `SessionData` and add `SessionSummaryMetrics.swift`.

The coordinator must be the only session lifecycle entry point, wire `SensorFusionEngine` and `FallDetectionEngine`, accumulate live metrics, validate electric power type for skateboard-only usage, and return enriched `SessionData` on stop. Views must use `useSessionRecording` only.

Respect DevProcess rules: zone headers, bilingual localization, 500-line file cap, no SwiftUI in core zone, update docs, add unit tests and verification script.
