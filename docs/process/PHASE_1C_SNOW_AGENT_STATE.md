# Phase 1c Snow Mode Agent State

**Status:** Active for `feature/snow-mode` production implementation
**Branch:** `feature/snow-mode`
**Baseline:** `develop` at Task-030b documentation consolidation
**Current Task:** Snow-Task-001 — Sport Mode Integration Foundation + Preflight

## Source of Truth

This file records the state required before implementing Phase 1c Snow Sports Mode as production code. It is not a prototype handoff file.

Required references:

- `SkateTrack_BuildPlan_Phase1c_SnowSports_v1.2.1`
- `SkateTrack_Phase1c_WatchDecoupling_Addendum_EN_v1.0`
- `SkateTrack_Phase1c_StatusComparison_ZH_v1.0`
- Active repository docs under `docs/DOCUMENTATION_INDEX.md`, `docs/process`, `docs/release`, `docs/reference`, and `docs/history`

## Production Boundary

Snow Mode production work must extend the existing app model instead of creating a second prototype namespace.

Snow-Task-001 establishes:

- `SnowDiscipline` as the production snow sub-mode enum.
- `SportMode.snow(SnowDiscipline)` as the official sport entry point.
- Explicit `.snow` handling in sport-related switches.
- Start-session category and selector wiring sufficient to start a snow session as real `SessionData`.
- Localization keys for `en`, `zh-Hant`, and `ja`.
- `scripts/verify_snow_sport_enum.py` as the Snow sport integration gate.

## Deferred Until Later Snow Tasks

Snow-Task-001 intentionally does not implement:

- `SnowSegment`, `SnowRun`, `SnowDistanceBreakdown`, or Core Data migration.
- `SnowSegmentClassifier`.
- `RunBoundaryDetector`.
- Snow Live HUD, Snow summary, or macOS Snow viewer data plumbing.
- `.skatetrack` snow package compatibility.
- HealthKit snow export.
- WatchBridge snow real-data wiring.

## Watch Decoupling State

The Watch addendum remains active:

- Snow-Task-006a can build Watch Snow UI against a data-source protocol.
- Snow-Task-006b remains deferred until mainline Task-040 provides final WatchBridge types.
- Snow-Task-001 does not touch `Shared/WatchBridge/*`.

## Current Verification

Run after Snow-Task-001 patches:

```bash
python3 scripts/verify_snow_sport_enum.py
python3 scripts/verify_localization_keys.py
python3 scripts/verify_shared_models.py
```

Snow-Task-001 verification token: production snow sport enum integrated.
