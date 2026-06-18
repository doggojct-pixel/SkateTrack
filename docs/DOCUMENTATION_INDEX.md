# SkateTrack Documentation Index

**Status:** Active — Task-030b documentation consolidation and directory cleanup  
**Last Updated:** 2026-06-13  
**Purpose:** First documentation entry point for future ChatGPT / Cursor / human handoff.

SkateTrack documentation is intentionally organized into a small set of active source-of-truth files. Historical ADR single files were consolidated into one ADR index so daily workflow does not require reading scattered decision files.

## 1. Read these first for any new task

| Order | File | Purpose |
|---:|---|---|
| 1 | `docs/DOCUMENTATION_INDEX.md` | Documentation map and reading order. |
| 2 | `docs/process/DEVELOPMENT_RULES.md` | Development rules, hotfix workflow, commit policy, layout rules, and scope boundaries. |
| 3 | `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` | Features blocked before Apple Developer Program / production credentials, with unlock conditions and no-overclaim rules. |
| 4 | `docs/release/RELEASE_READINESS_PRE_ADP.md` | Pre-ADP release-readiness gate, required verify scripts, build commands, and source-control hygiene. |
| 5 | `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` | Manual QA matrix for iOS, macOS, localization, accessibility, privacy, GPS, and safety checks. |
| 6 | `docs/adr/ADR-INDEX.md` | Historical ADR index and mapping from old ADR decisions to active consolidated documents. |
| 7 | `docs/reference/FILE_STRUCTURE.md` | Current repository structure and task progress snapshot. |
| 8 | `docs/history/DEV_LOG.md` | Chronological development history; not the primary rules document. |

## 2. Directory layout

| Directory | Role |
|---|---|
| `docs/process/` | Development process and recurring rules. |
| `docs/release/` | Pre-ADP release gate, known limitations, and manual QA. |
| `docs/adr/` | Consolidated ADR index and future ADR entries if truly needed. |
| `docs/reference/` | Repository structure and technical reference maps. |
| `docs/history/` | Append-only development history. |

## 3. Active source-of-truth files

| File | Owns |
|---|---|
| `docs/process/DEVELOPMENT_RULES.md` | Development workflow, hotfix handling, commit / push policy, file-size rules, localization rules, macOS layout principles, documentation update requirements, and prohibited scope creep. |
| `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` | StoreKit, Google Sign-In, Google Drive, CloudKit / iCloud, WeatherKit, TestFlight, custom UTType / document association, real-device GPS validation, Fall Detection diagnostics, Japanese review, and future localization roadmap. |
| `docs/release/RELEASE_READINESS_PRE_ADP.md` | The verification gate before treating `develop` as a Pre-ADP release-readiness checkpoint. |
| `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` | Manual QA checklist by platform / feature / language / privacy boundary. |
| `docs/adr/ADR-INDEX.md` | Historical decision inventory after ADR consolidation. |

## 4. Consolidated / retired documents

The old per-topic ADR single files ADR-0001 through ADR-0011 were intentionally consolidated during Task-030b. They should not remain as active source files. Their decisions are summarized in `docs/adr/ADR-INDEX.md` and routed to the relevant active documents.

The previous stage-specific technical-risk notes for Tasks 026–030 were also consolidated into the active process, release, QA, and ADR index documents.

Historical facts remain available in `docs/history/DEV_LOG.md`, but `DEV_LOG.md` is not the daily source of truth for rules or limitations.

## 5. Documentation rules

- Do not create a new ADR file for every small task.
- Use `docs/process/DEVELOPMENT_RULES.md` for recurring workflow rules.
- Use `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` for blocked / deferred features and unlock criteria.
- Use `docs/release/RELEASE_READINESS_PRE_ADP.md` and `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` for release-readiness and QA gates.
- If a future architectural decision is large enough to require its own ADR, add it under `docs/adr/` and update `docs/adr/ADR-INDEX.md`.

Task-030b verification token: documentation index consolidated.
## Phase 1c Snow Mode Production Notes

- `docs/process/PHASE_1C_SNOW_AGENT_STATE.md` records the active `feature/snow-mode` production implementation boundary. It is separate from the earlier Snow prototype branch and must be read before Snow-Task-002+.
- Snow-Task-001 verification token: production snow sport enum integrated.
- Snow-Task-001a verification token: snow mode public entry debug-gated. Release builds must not expose the Snow Session Start entry until the later production snow tasks are complete.

- `scripts/verify_snow_task_001b_debug_toggle.py` — Verifies DEBUG toggle gating for the Snow Mode Ride start entry.

- Snow-Task-002 verification token: production snow schema and repository boundary integrated. The runtime Core Data model remains programmatic, with `.xcdatamodeld` maintained as a schema reference.
- `scripts/verify_snow_schema.py` — Verifies Snow production value types, Core Data entities, repository, `useSnowSession`, localization, project registration, and no prototype / WatchBridge / `.skatetrack` contamination.

### Phase 1c Snow classifier foundation

- `docs/process/PHASE_1C_SNOW_AGENT_STATE.md` records the active Snow-Task-003 classifier boundary and v0 input limitations.
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` records the v0 classifier limitations caused by the current `MotionSample` shape.
- `scripts/verify_snow_classifier.py` verifies the Snow-Task-003 production classifier foundation.

### Snow-Task-004 Run Boundary Detector

- `Shared/Models/RunBoundaryDetector.swift` and related `RunBoundary*` files implement the production Snow run-boundary state machine.
- `scripts/verify_snow_run_boundary.py` validates the Snow-Task-004 boundaries and fast-path transport run ending.
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` documents the v0 altitude endpoint limitation.

### Snow-Task-005 iPhone Snow UI production wiring

- Snow-Task-005 is implemented on `feature/snow-mode` after verified baseline `c0aeec8` from Snow-Task-004.
- `scripts/verify_snow_iphone_ui.py` is the Snow-Task-005 verification gate.
- `docs/process/PHASE_1C_SNOW_AGENT_STATE.md` records the live data-boundary decision: `SessionRecordingCoordinator` owns lifecycle, `SnowLiveSessionCoordinator` drives classifier / detector, `useSnowSession` stays repository-backed, and `useSessionRecording` exposes live HUD state.
- Snow-Task-005 does not touch `Shared/WatchBridge/*`; real WatchBridge wiring remains Snow-Task-006b after mainline Task-040.

### Snow-Task-006a mock-backed Watch Snow UI

- Snow-Task-006a is implemented on `feature/snow-mode` after verified baseline `4ab2489 Add iPhone Snow live HUD`.
- `scripts/verify_snow_watch_ui.py` is the Snow-Task-006a verification gate.
- `WatchSnowSessionSnapshot` is the production-safe equivalent of the Watch Addendum's prototype session field contract; production code must not introduce `SnowPrototype*` symbols.
- `watchOS/Core/Snow/` owns the Watch Snow data-source boundary, DEBUG mock provider, haptic intent, and transition mapper.
- `watchOS/Features/Snow/` owns the mock-backed Watch Snow UI surfaces and Release fallback.
- Snow-Task-006a does not touch `Shared/WatchBridge/*`; real WatchBridge / WatchConnectivity wiring remains Snow-Task-006b after mainline Task-040.

Snow-Task-006a verification token: mock-backed Watch Snow UI complete without WatchBridge real-data wiring.

### Snow-Task-007 macOS Snow viewer

- Snow-Task-007 is implemented on `feature/snow-mode` after verified baseline `1e68805 Add mock-backed Watch Snow UI`.
- `scripts/verify_snow_macos_viewer.py` is the Snow-Task-007 verification gate.
- `docs/process/PHASE_1C_SNOW_AGENT_STATE.md` records the macOS Snow viewer data-source hierarchy: DEBUG mock, repository-backed Snow sessions, and imported package `packageSchemaPending` before 008.
- `docs/reference/FILE_STRUCTURE.md` lists the macOS Snow analysis boundary and UI files.
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` records that official `.skatetrack` Snow package payload compatibility remains Snow-Task-008.
- `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` records the macOS Snow viewer smoke test.
- Snow-Task-007 does not modify package manifest / payload / reader / writer files, backup / restore flows, iOS source, watchOS source, WatchBridge, or Snow value types.

Snow-Task-007 verification token: read-only macOS Snow viewer complete without package schema scope creep.

### Snow-Task-008a Package Compatibility

- `Shared/Models/SkateTrackPackageSnowPayload.swift` defines the official optional Snow package payload.
- `scripts/verify_snow_package_compatibility.py` verifies schema 1 / 2 compatibility, optional capabilities, optional `snowPayload`, iOS export provider wiring, macOS imported package viewer wiring, and 008a scope guardrails.
- `scripts/create_snow_task008a_review_pack.sh` creates the Snow-Task-008a review pack in `/Users/doggo/Documents/App軟體區/upload/`.
- Snow-Task-008b remains responsible for backup compatibility and Snow Health export provider boundary.


### Snow-Task-008b Backup Compatibility and Health Boundary

- `docs/process/PHASE_1C_SNOW_AGENT_STATE.md` records the Snow-Task-008b boundary: backup schema compatibility plus iOS-only Health provider boundary.
- `docs/reference/FILE_STRUCTURE.md` lists the backup schema files and `iOS/Core/Health/*` provider-boundary files.
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` records that production HealthKit export remains disabled before ADP / entitlement work.
- `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` records the 008b backup / Health boundary QA path.
- `scripts/verify_snow_backup_compatibility.py` is the 008b verification gate.
- `scripts/create_snow_task008b_review_pack.sh` creates the Snow-Task-008b review pack under `/Users/doggo/Documents/App軟體區/upload/`.

### Snow-Task-009 QA Fixtures and Regression Matrix

- `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` contains the Traditional Chinese Snow-Task-009 manual QA checklist.
- `docs/process/PHASE_1C_SNOW_AGENT_STATE.md` records the Task 009 QA / regression state and guardrails.
- `docs/reference/FILE_STRUCTURE.md` lists the Snow QA fixture files, regression tests, generator, verify script, and review-pack script.
- `scripts/verify_snow_regression.py` verifies deterministic fixtures, fixture tests, docs, review script, and runtime scope guardrails.
- `scripts/create_snow_task009_review_pack.sh` creates the Snow-Task-009 review pack under `/Users/doggo/Documents/App軟體區/upload/`.

### Snow-Task-010 Phase 1c Completion Handoff

- `docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md` is the final Phase 1c Snow Mode handoff record for Claude / human review.
- `scripts/verify_snow_phase1c_completion.py` is the final completion verifier.
- `scripts/create_snow_task010_review_pack.sh` creates the final review pack under `/Users/doggo/Documents/App軟體區/upload/`.
- Snow-Task-010 is documentation / verification / handoff only; it must not add runtime Snow feature behavior.
