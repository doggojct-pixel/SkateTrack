# Task-012 Acceptance Criteria

- iOS app launches into the Session Start Flow instead of the old placeholder shell.
- UI shows Skateboard / Inline category selection.
- All four skateboard modes are visible and startable.
- All four inline modes are visible.
- Free users can start Inline Urban / Freestyle.
- Free users cannot start Inline Fitness / Speed, Inline Aggressive, or Inline Slalom.
- Subscriber DEBUG override unlocks the paid inline modes.
- Electric power type only appears for skateboard and is reset to human-powered when switching to inline.
- Start button uses `SessionRecordingActions.startSession`.
- No new View imports CoreLocation or CoreMotion.
- `python3 scripts/verify_session_start_flow.py` passes.
- Existing verification scripts for localization, shared models, feature flags, sensors, fall detection, and Task-011 still pass.
- iOS Build / Run succeeds. watchOS and macOS Build / Run unchanged.
