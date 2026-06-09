# Task-011 Acceptance Checklist

- [ ] `SessionStateMachine` rejects `idle → recording` direct transitions.
- [ ] `SessionMetricsAccumulator` updates distance, max speed, average speed, elevation, tilt, and moving ratio from `MotionSample`.
- [ ] `SessionRecordingCoordinator` is the only session lifecycle entry point wiring fusion + fall detection.
- [ ] `startSession(mode:powerType:)` rejects `PowerType.electric` for inline modes.
- [ ] `pauseSession()` / `resumeSession()` preserve valid lifecycle transitions.
- [ ] `requestEndSession()` returns enriched `SessionData` with summary metrics and fall events.
- [ ] `useSessionRecording` exposes `SessionRecordingState` and `SessionRecordingActions` on `@MainActor`.
- [ ] DEBUG mock data mode supports simulator testing without hardware sensors.
- [ ] Core session recording files contain no SwiftUI / UIKit imports.
- [ ] `session.status.*` and `session.error.*` localization keys exist in both languages.
- [ ] `SessionRecordingCoordinatorTests` pass in `SkateTrack-iOSTests`.
- [ ] `scripts/verify_session_recording_coordinator.py` passes.
- [ ] `FILE_STRUCTURE.md` and `DEV_LOG.md` updated.
