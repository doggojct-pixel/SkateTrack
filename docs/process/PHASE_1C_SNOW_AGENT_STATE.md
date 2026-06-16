# Phase 1c Snow Mode Agent State

**Status:** Active for `feature/snow-mode` production implementation
**Branch:** `feature/snow-mode`
**Baseline:** `develop` at Task-030b documentation consolidation
**Current Task:** Snow-Task-003 — Snow segment classifier foundation

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
- Start-session category and selector wiring sufficient to start a snow session as real `SessionData` when the DEBUG Snow Mode entry toggle is enabled, while later production snow tasks are incomplete.
- Localization keys for `en`, `zh-Hant`, and `ja`.
- `scripts/verify_snow_sport_enum.py` as the Snow sport integration gate.

Snow-Task-001a adds the release-safety gate:

- `SportMode.snow(SnowDiscipline)` remains production code and must not be wrapped in `#if DEBUG`.
- The normal Session Start Snow category is exposed only through `SessionStartSportCategory.userFacingCases`.
- `SessionStartSportCategory.userFacingCases` returns Snow in DEBUG builds and hides Snow in Release builds.
- Debug Tools documents that Snow Mode is a DEBUG-only entry until Snow-Task-002 through Snow-Task-009 finish the production data path.

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
python3 scripts/verify_snow_task_001a_debug_gate.py
python3 scripts/verify_localization_keys.py
python3 scripts/verify_shared_models.py
```

Snow-Task-001 verification token: production snow sport enum integrated.

Snow-Task-001a verification token: snow mode public entry debug-gated.
Snow-Task-001b verification token: snow mode entry controlled by debug toggle.


## Snow-Task-002 Production Data Layer

Snow-Task-002 adds the first production Snow Mode data layer. It intentionally follows the existing SkateTrack persistence architecture: programmatic Core Data model generation in `PersistenceController.makeManagedObjectModel()` is the runtime source of truth, while `Shared/Persistence/SkateTrackDataModel.xcdatamodeld` is kept as the schema reference.

Completed Snow-Task-002 scope:

- Production value types under `Shared/Models`: `SnowSegmentType`, `SnowSegment`, `SnowRun`, `SnowDistanceBreakdown`, `SnowVerticalMetrics`, and `SnowSessionState`.
- Additive Core Data entities: `PersistedSnowRun` and `PersistedSnowSegment`.
- Model version identifier updated to `Phase1cSnowTask002`.
- Migration options remain enabled through `shouldMigrateStoreAutomatically` and `shouldInferMappingModelAutomatically`.
- `SnowSessionRepository` and `SnowSessionEntityMapper` provide Core Data CRUD and aggregate session state.
- `useSnowSession.swift` exposes a repository-backed boundary for later Snow-Task-005 UI work.
- `scripts/verify_snow_schema.py` verifies production schema, repository, localization, project registration, no `.skatetrack`, no `SnowPrototype*`, and no `Shared/WatchBridge/*` contamination.

Snow-Task-002 intentionally does not implement `SnowSegmentClassifier`, `RunBoundaryDetector`, UI, package compatibility, fixtures, HealthKit export, or WatchBridge wiring.

Snow-Task-002 verification token: production snow schema and repository boundary integrated.


## Snow-Task-003 Production Classifier Foundation

Snow-Task-003 adds a v0 rule-based classifier over existing `MotionSample` windows without modifying `MotionSample` or the Snow-Task-002 value types.

Completed Snow-Task-003 scope:

- `SnowClassifierConfig.productionV0` centralizes all agreed threshold values.
- `SnowSegmentClassification` captures classifier output, confidence, trend metrics, derived heading standard deviation, motion energy, route distance, and reason codes.
- `SnowSegmentClassifier` classifies downhill, lift ascent, gondola ascent, surface lift ascent, flat traverse, walking, stopped, and unknown from existing `MotionSample` fields.
- Fixture tests cover clean downhill, lift ascent, gondola ascent, surface lift ascent, stopped, walking, noisy downhill altitude, ambiguous gondola-like descent, and missing-altitude movement.
- `scripts/verify_snow_classifier.py` verifies classifier registration, config thresholds, fixture coverage, known limitations, no `SnowPrototype*`, no `Shared/WatchBridge/*`, no `.skatetrack`, and no `MotionSample` schema expansion.

Known v0 classifier limitations:

- `MotionSample` does not yet persist horizontalAccuracy, verticalAccuracy, heading/course, GPS altitude, or barometer source metadata.
- GPS altitude vs barometer cross-validation is not available in v0.
- Heading standard deviation is derived from consecutive GPS coordinates when possible.
- Stable-heading / low-motion downhill-like movement is classified as `unknown` to avoid over-counting gondola-like movement as ski distance.

Snow-Task-003 intentionally does not implement the run-boundary state machine, UI, package compatibility, WatchBridge wiring, or fixture `.skatetrack` packages.

Snow-Task-003 verification token: production snow segment classifier foundation integrated.

## Snow-Task-004 RunBoundaryDetector State

Snow-Task-004 adds the production run-boundary state machine on top of Snow-Task-003 classifier output. `RunBoundaryDetector` consumes streaming `SnowSegmentClassification` values and emits `RunBoundaryEvent` plus `RunBoundarySnapshot` data for future `useSnowSession` / Snow UI wiring.

Boundaries:
- `RunBoundaryDetector` is pure model-layer logic and does not call `SnowSessionRepository` directly.
- `SnowSegmentClassifier`, `MotionSample`, and Snow-Task-002 value types remain unchanged.
- `SnowSegment.startAltitudeMeters` / `endAltitudeMeters` remain nil in v0 because classifier output only provides `altitudeDeltaMeters`.
- `hardTransportConfirmationSeconds` provides a fast-path run end for high-confidence lift / gondola / surface-lift segments.

Snow-Task-004 verification token: pure RunBoundaryDetector state machine complete.
