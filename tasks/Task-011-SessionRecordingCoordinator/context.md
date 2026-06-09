# Task-011 Context — Session Recording Coordinator + Hook

Source of truth: SkateTrack Build Plan Task 011-020 pack, Task-011.

Task-011 establishes the iOS session lifecycle coordinator and SwiftUI hook. It wraps Task-006 through Task-010 sensor engines so Views can start, pause, resume, and end sessions without touching sensor internals directly.

Relevant references:
- PRD v1.2 §5.1, §5.5, §13.1, §14.1: session recording lifecycle and live metrics.
- DevProcess v1.0 §4.1, §4.2, principles B/C/D/E: hook boundary, autonomous core zone, living docs.
- UI references: no direct screen in Task-011; outputs feed iOS Screen 03/03b/04/05 in later tasks.
