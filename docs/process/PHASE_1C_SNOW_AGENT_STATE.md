# Phase 1c Snow Mode Agent State

**Status:** Active for `feature/snow-mode` production implementation
**Branch:** `feature/snow-mode`
**Baseline:** `develop` at Task-030b documentation consolidation
**Current Task:** Snow-Task-006a complete — mock-backed Watch Snow UI is implemented; Snow-Task-006b real WatchBridge wiring remains deferred until mainline Task-040

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

## Snow-Task-005 iPhone Snow UI State

Snow-Task-005 adds the production iPhone Snow UI boundary on top of the Snow-Task-002 repository, Snow-Task-003 classifier, and Snow-Task-004 run-boundary detector.

Completed scope:

- `SnowLiveSessionConfig` defines the iPhone Snow live UI policy, including `lowConfidenceThreshold`.
- `SnowLiveSessionConfig.productionV0.lowConfidenceThreshold` references `SnowClassifierConfig.productionV0.mediumConfidenceThreshold`; Snow HUD views and mappers must not hardcode confidence literals.
- `SnowLiveSessionCoordinator` drives the verified classifier and detector from MotionSample windows without starting sensors itself.
- `SessionRecordingCoordinator` remains the recording lifecycle owner and only forwards samples to Snow live processing for `.snow(...)` sessions.
- `useSessionRecording` exposes `snowLiveState` and `snowLiveHUDState` for live iPhone UI rendering.
- `useSnowSession` remains repository-backed for persisted Snow history.
- `SnowHUDView` renders the four iPhone live states: downhill, lift / gondola, waiting, and low confidence.
- `SnowDaySummaryView`, `SnowSegmentTimelineView`, and `SnowDistanceInspectorView` render repository-backed Snow summary surfaces.
- `scripts/verify_snow_iphone_ui.py` verifies Snow-Task-005 files, config-driven lowConfidence policy, UI wiring, and scope guardrails.

Snow-Task-005 boundaries:

- Do not modify `RunBoundaryDetector`, `SnowSegmentClassifier`, `SnowClassifierConfig`, `MotionSample`, or Snow-Task-002 value types as part of Snow-Task-005.
- Do not touch `Shared/WatchBridge/*` in Snow-Task-005.
- Do not create `SnowPrototype*` production namespace.
- Do not add `.skatetrack` sample files.

Deferred from Snow-Task-005:

- Manual correction persistence for `SnowSegment.manualOverride`.
- WatchBridge real-data wiring and Watch low-confidence payload mapping until Snow-Task-006b after mainline Task-040.
- True altitude confidence scoring until a later approved `MotionSample` metadata extension.
- Live provisional segment timeline before `runEnded` because v0 detector finalizes segments at run-boundary events.

Snow-Task-005 verification token: production iPhone Snow UI wired to live Snow boundary without classifier/schema/WatchBridge scope creep.

## Snow-Task-006a Mock-backed Watch Snow UI State

Snow-Task-006a implements the watchOS Snow UI as a mock-backed, protocol-driven production surface. It intentionally follows the Watch Decoupling Addendum: Watch UI may be built now, while real WatchBridge wiring remains a later 006b task after mainline Task-040.

Completed scope:

- `WatchSnowSessionSnapshot` defines the production-safe Watch Snow snapshot contract. It mirrors the Addendum's prototype session field intent without using `SnowPrototype*` production names.
- `WatchSnowSessionDataSource` defines the view-facing data boundary for Watch Snow screens.
- `WatchSnowMockScenario` and DEBUG-only `WatchSnowMockSessionProvider` provide local downhill, lift / gondola, waiting, low-confidence, fall-alert, and summary scenarios for simulator QA.
- `WatchSnowHapticIntentObserver` maps snapshot transitions to haptic intent without owning sensors, WatchConnectivity, or WatchBridge transport.
- `WatchSnowRootView` routes DEBUG builds to `WatchSnowMockGalleryView` and Release builds to `WatchSnowUnavailableView`.
- Watch Snow views render live speed, run carousel, lift / gondola, waiting, low confidence, fall alert, summary, controls, and metric chip surfaces from `WatchSnowSessionSnapshot`.
- `scripts/verify_snow_watch_ui.py` verifies the data contract, DEBUG gating, localization, project membership, and 006b deferral guardrails.

Snow-Task-006a boundaries:

- Do not touch `Shared/WatchBridge/*`.
- Do not import `WatchConnectivity`, reference `WCSession`, or add `WatchSessionCoordinator` wiring.
- Do not modify `SessionRecordingCoordinator`, `useSessionRecording`, `useSnowLiveSession`, `SnowLiveSessionCoordinator`, `MotionSample`, `RunBoundaryDetector`, `SnowSegmentClassifier`, or Snow-Task-002 value types.
- Do not create `SnowPrototype*` production symbols.
- Do not add `.skatetrack` samples, HealthKit, emergency contacts, signing, entitlements, or production complication data.

Deferred from Snow-Task-006a:

- `WatchBridgeSnowSessionProvider` and real iPhone-to-Watch Snow metrics streaming.
- Any `MetricUpdateMessage` snow-field extension until mainline Task-040 provides the final WatchBridge structure.
- Real fall detection / SOS integration and health-data handling.
- Release exposure of mock data as if it were production session data.

Snow-Task-006b precondition:

- Mainline `develop` must include the completed Phase 1b Task-040 Watch integration.
- `feature/snow-mode` must be rebased or merged onto post-Task-040 `develop`.
- Any future naming drift between WatchBridge payloads and `WatchSnowSessionSnapshot` must be reconciled in the 006b adapter, not by rewriting the Watch Snow views.

Snow-Task-006a verification token: mock-backed Watch Snow UI complete without WatchBridge real-data wiring.

## Snow-Task-007 macOS Snow Viewer State

Snow-Task-007 adds the macOS Snow viewer as a read-only analysis surface. It is intentionally separated from Snow-Task-008 package compatibility work.

Completed scope:

- `MacSnowSessionAnalysis` is a struct presentation boundary, not a class and not a live subscription owner.
- `MacSnowAnalysisViewModel` is the observable macOS UI state holder.
- `MacSnowAnalysisSource` distinguishes DEBUG mock, Core Data repository-backed, and imported package data sources.
- `MacSnowAnalysisAvailability.packageSchemaPending` represents imported `.skatetrack` packages that do not yet contain official Snow payload fields.
- `MacSnowMockAnalysisProvider` is DEBUG-only and exists for UI QA only.
- `MacSnowRouteFilter` performs timestamp-window route / elevation filtering without adding references to `SnowSegment` or changing `MotionSample`.
- macOS Snow viewer screens render the six required viewer areas: session browser, dashboard, route + elevation, segment timeline, segment inspector, and distance inspector.
- `MacRootView` exposes a DEBUG-only Snow Analysis Preview entry for local validation.
- The viewer body follows the SnowMode visual direction from `SkateTrack_SnowMode_UI_v1.1.1_Pack` rather than the temporary macOS shell visual style.

Data-source hierarchy:

```text
MacSnowAnalysisViewModel
  ├── DEBUG: MacSnowMockAnalysisProvider → MacSnowSessionAnalysis
  ├── Release / Core Data repository-backed Snow session → MacSnowSessionAnalysis
  └── Release / imported .skatetrack without official Snow fields
        → MacSnowAnalysisAvailability.packageSchemaPending
```

Snow-Task-007 boundaries:

- Do not modify package manifest / payload / reader / writer files.
- Do not modify backup / restore / import / export flows.
- Do not modify `Shared/WatchBridge/*` or add WatchConnectivity wiring.
- Do not modify iOS or watchOS source as part of Snow-Task-007.
- Do not modify `MotionSample`, `SnowSegment`, `SnowRun`, `SnowDistanceBreakdown`, `SnowVerticalMetrics`, or `SnowSessionState`.
- Do not add `.skatetrack` fixture files.
- Do not persist manual corrections.
- Do not claim HealthKit, WeatherKit, CloudKit, or official package compatibility.

Deferred from Snow-Task-007:

- Official `.skatetrack` Snow package payload compatibility and package reader / writer support: Snow-Task-008.
- Full package-backed Snow analysis in macOS viewer: Snow-Task-008 after payload fields exist.
- Full MapKit segment-region fitting and true absolute-altitude profile: later GPS / altitude data task.
- Outer macOS shell redesign toward `SkateTrack_macOS_UI_v2`: later main macOS UI integration task.
- Manual correction persistence for Snow segments: later UX / persistence task.

Snow-Task-007 verification token: read-only macOS Snow viewer complete without package schema scope creep.

## Snow-Task-008a Package Compatibility State

Snow-Task-008a adds the package compatibility half of Snow-Task-008. The package manifest now uses schema version 2 while supporting decode of schema versions 1 and 2. Snow package data is optional and capability-declared through `capabilities` with `snow-*` keys.

Rules established by Snow-Task-008a:

- Schema 1 `.skatetrack` packages remain valid and decode without Snow fields.
- Schema 2 packages may contain `SkateTrackPackageSnowPayload` on each package session.
- `snowPayload == nil` means no official Snow analysis payload is available and macOS should continue to show `packageSchemaPending`.
- iOS export may create Snow payload only from real `SnowSessionState` returned by `SnowSessionRepositoryProtocol`.
- macOS imported packages use `MacSnowSessionAnalysisMapper.makeAvailabilityFromPackage(...)` and source `.importedPackage`.
- Backup compatibility and Snow Health export provider boundary remain Snow-Task-008b scope.

