# Task-013 — Live HUD + Slide-to-End Control

## Goal
Implement the in-session iOS Live HUD that appears after Task-012 starts a session. The HUD must follow iOS UI mockup Screen 03 / 03b, use the dark SkateTrack visual system, read state only through `useSessionRecording`, and end sessions only through `SessionRecordingActions.requestEndSession()`.

## Completed Scope
- Full-screen dark Live HUD container.
- Central speed display with max speed summary.
- Distance, elapsed time, tilt, tricks placeholder, heart-rate placeholder.
- Mini route map view with graceful no-route placeholder.
- Inline-specific cadence / rhythm placeholders.
- Pause / resume control.
- SOS stub entry reserved for Task-014.
- Slide-to-End control requiring at least 85% drag progress.
- Root navigation switches from Session Start to Live HUD while recording, paused, preparing, ending, or saving.

## Deferred Scope
- Fall Alert / SOS flow is Task-014.
- Persistence and summary routing are Task-015 / Task-018.
- Real heart-rate, trick recognition, and inline cadence are later tasks.

## Validation
Run:

```bash
python3 scripts/verify_live_hud.py
python3 scripts/verify_session_start_flow.py
python3 scripts/verify_session_recording_coordinator.py
python3 scripts/verify_localization_keys.py
```

Xcode manual validation:
- Start a skateboard session from Task-012 UI.
- Confirm Live HUD appears.
- Confirm Pause / Resume changes state.
- Drag Slide-to-End below 85%; it must bounce back.
- Drag Slide-to-End past 85%; it should end the session and return to start flow.
- Switch to inline mode and confirm purple theme plus cadence / rhythm placeholders.
