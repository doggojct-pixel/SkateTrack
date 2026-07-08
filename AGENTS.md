# AGENTS.md — SkateTrack Codex / Agent Operating Rules

This file is the standing instruction set for any AI coding agent working in this repository.
Follow it before modifying code, writing hotfixes, running verification, or suggesting commits.

## 1. Project identity and local paths

- Project: `SkateTrack`
- Local repo path: `/Users/doggo/Documents/App軟體區/SkateTrack`
- Upload/log/output path: `/Users/doggo/Documents/App軟體區/upload`
- Download/apply starting path: `/Users/doggo/Downloads`
- Current Phase 1b build plan: `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1.71`
- Current workflow rules: `SkateTrack_Collaboration_Workflow_and_Engineering_Rules_EN_v1.6`
- File-structure source of truth: `docs/reference/FILE_STRUCTURE.md`
- State source of truth: `docs/process/PHASE_1B_AGENT_STATE.md`
- History source of truth: `docs/history/DEV_LOG.md`
- Known limitations source of truth: `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`
- Snow structure reference, when available: `SNOW_FILE_STRUCTURE.md` is a reference only; it must not unlock Snow production scope.

## 2. Current task state

- Task-037 final merge to `develop` completed at:
  - `develop` post-merge head: `2f414119f3adc7bfd222ffd4d8917a058c48098b`
- Task-038 branch:
  - `task-038-haptics-safety-shells`
- Task-038a completed and pushed at:
  - `TASK038A_COMMIT_HEAD=2e74d510d42002a7cdbf9dfa1ecac30eac3a6fce`
- Task-038b completed and pushed at:
  - `TASK038B_COMMIT_HEAD=f96be0db6d9b30415e1083559dbcaaf0b57df21a`
- Task-038c completed and pushed at:
  - `TASK038C_COMMIT_HEAD=d019aa79e94e296567a8373f6e00cdc60487eada`
- Next expected subtask:
  - `Task-038d — Haptics/Safety Verifier + Manual QA`
- Do not merge `task-038-haptics-safety-shells` into `develop` until Task-038d closure and final merge gates pass.

## 3. BuildPlan alignment

Always align with the current BuildPlan before starting a task.

### Task-038a — Haptic Intent Model — CLOSED

Exit criteria already achieved:

```text
VERIFY_TASK038A_HAPTIC_INTENT_RESULT=PASSED
RATE_LIMIT_PRESENT=YES
DUPLICATE_SUPPRESSION_PRESENT=YES
FAILURE_COUNT=0
```

Do not re-open or rewrite 038a unless a verified regression requires it.

### Task-038b — Health Reminder Shell — CLOSED

Goal: add a non-medical reminder shell if in product scope.

Required boundaries:

```text
VERIFY_TASK038B_HEALTH_REMINDER_SHELL_RESULT=PASSED
MEDICAL_CLAIM_COUNT=0
HEALTHKIT_PRODUCTION_USAGE_COUNT=0
FAILURE_COUNT=0
```

Allowed direction:

- Reminder shell/state only.
- Safe language only.
- Localization/accessibility required for user-facing strings.
- No claim of medical monitoring, diagnosis, prevention, emergency response, clinical accuracy, or always-on safety detection.
- No production HealthKit dependency or live health-data integration.

Do not re-open or rewrite 038b unless a verified regression requires it.

### Task-038c — Fall Safety Presentation Shell — CLOSED

Expected future exit criteria:

```text
VERIFY_TASK038C_FALL_SAFETY_SHELL_RESULT=PASSED
EMERGENCY_PROMISE_COPY_COUNT=0
FALSE_ALARM_PATH_PRESENT=YES
FAILURE_COUNT=0
```

Do not re-open or rewrite 038c unless a verified regression requires it.

### Task-038d — Haptics/Safety Verifier + Manual QA — NEXT

Current direction:

- Docs/verifier-only closure preparation.
- Do not modify Swift, Xcode project, localization runtime, UI/runtime, schema, package, StoreKit, sensor/session, route/speed/elevation, ActivityVisualization, Snow, HealthKit production, WatchKit haptic playback, or emergency/SOS runtime files.
- Manual QA must remain pending until the operator explicitly confirms `MANUAL_QA_HAPTICS_SAFETY=PASSED`.

Expected future exit criteria:

```text
VERIFY_TASK038_HAPTICS_SAFETY_RESULT=PASSED
MANUAL_QA_HAPTICS_SAFETY=PASSED
KNOWN_LIMITATIONS_UPDATED=YES
FAILURE_COUNT=0
COMMIT_PUSH_RESULT=PASSED
```

## 4. Absolute workflow rules

1. Before a new subtask or hotfix, perform a fresh source audit from the current repo state.
2. Do not implement from stale source packs.
3. Do not scope-creep into later subtasks.
4. Do not commit without uploaded green logs.
5. If UI or interaction behavior changes, do not commit without manual QA confirmation.
6. Do not merge into `develop` without successful task closure, task-branch push, and final develop verification.
7. If logs fail, stop and inspect the logs. Do not normalize failures as expected behavior.
8. If a verifier fails because the intended implementation changed structure, first confirm the replacement is correct, then update the verifier safely.
9. If a user reports a manual QA failure inside intended scope, treat it as a blocker until proven otherwise.
10. Keep commands pasted into Terminal usable. Never intentionally end a user-pasted block with `exit 0` or `exit 1`.

## 5. Correct hotfix delivery pattern

Every code-affecting hotfix must be delivered as a one-click apply-plus-verify flow.

The one-click flow must:

1. Start from `/Users/doggo/Downloads`.
2. Use absolute `HOTFIX_ROOT="/Users/doggo/Downloads/<hotfix_dir>"`; do not rely on `$PWD` after `cd`.
3. Confirm branch, expected base HEAD, and source freshness.
4. Apply the payload only inside declared allowed paths.
5. Run allowed-path guards.
6. Run focused verifier scripts.
7. Run `python3 -m py_compile` for new or changed verifier scripts.
8. Run `python3 scripts/verify_localization_keys.py` when localization could be affected.
9. Run `git diff --check`.
10. Run line/header guards.
11. Run forbidden-scope guards.
12. Run project membership checks when Swift files are added, moved, or newly referenced by Xcode targets.
13. Run watchOS build and XCTest gates for implementation, UI, model, provider, runtime, localization, Xcode project, or test changes.
14. Produce uploadable logs under `/Users/doggo/Documents/App軟體區/upload`.
15. Zip the generated run directory next to the directory.
16. If zip succeeds, delete the generated run directory.
17. Delete the extracted hotfix directory under `/Users/doggo/Downloads` after the run.
18. Print explicit final markers.

Required final markers:

```text
APPLY_RESULT=PASSED or equivalent task-specific apply result
TASKXXX_GATES_RAN=YES
ONECLICK_ZIP_EXIT=0
ONECLICK_ZIP_PATH=/Users/doggo/Documents/App軟體區/upload/<task>_<timestamp>_logs.zip
ONECLICK_CLEANUP_EXIT=0
ONECLICK_RUN_DIR_REMOVED=YES
FINAL_ONECLICK_RESULT=PASSED
TERMINAL_REMAINS_OPEN=YES
```

Do not provide apply/verify commands that only create scattered log files.
Do not skip verification.
Do not rely on `grep` when a Python guard is safer across shell environments.
Prefer Python for allowed-path, forbidden-scope, token, and line-count guards.

## 6. Documentation-only / verifier-only exception

Docs-only or verifier-only hotfixes may skip `xcodebuild` and XCTest only when strict path guards prove that no runtime implementation surface changed.

Qualifying examples:

- `AGENTS.md`
- `docs/process/PHASE_1B_AGENT_STATE.md`
- `docs/history/DEV_LOG.md`
- `docs/reference/FILE_STRUCTURE.md`
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`
- `docs/adr/*.md`
- `scripts/verify_*.py` when the script is only a verifier and is not part of app runtime
- README files inside hotfix packages

Non-qualifying examples that still require build/XCTest gates:

- Any `Shared/**/*.swift`, `iOS/**/*.swift`, `macOS/**/*.swift`, `watchOS/**/*.swift`, or `Tests/**/*.swift` change
- Any `SkateTrack.xcodeproj/project.pbxproj` change
- Any `.xcdatamodeld` or programmatic Core Data model change
- Runtime localization files loaded by the app
- Asset catalogs, Info.plist, entitlements, capabilities, signing, or build settings
- UI, view model, hook, provider, repository, engine, route, metric, or persistence behavior

If build/XCTest are skipped, logs must include explicit skip markers, for example:

```text
BUILD_GATE_SKIPPED=YES_AGENTS_ONLY_NON_RUNTIME_SCOPE
XCTEST_GATE_SKIPPED=YES_AGENTS_ONLY_NON_RUNTIME_SCOPE
```

## 7. Commit / push rules

Commit only after uploaded logs are green and manual QA is green when required.

Commit/push scripts must:

1. Reconfirm branch and expected pre-commit HEAD.
2. Re-run focused verifiers or documented skip gates appropriate to scope.
3. Re-run allowed-path guard.
4. Re-run `git diff --check`.
5. Stage only allowed files.
6. Commit with a task-specific message.
7. Push the task branch.
8. Write a timestamped upload log under `/Users/doggo/Documents/App軟體區/upload`.
9. Print final markers and leave Terminal usable.

Core gates:

```text
No green logs → no commit.
No manual QA green when required → no commit.
No successful task-branch push → no merge.
No successful final develop verification → no develop push.
```

## 8. Engineering rules

- Swift files must start with `// [協作區]` or `// [自主區]`.
- Swift hard line limit: 500 lines.
- Prefer splitting Swift files around 350–450 lines.
- New user-facing strings must be localized in:
  - `Shared/Localization/en.lproj/Localizable.strings`
  - `Shared/Localization/zh-Hant.lproj/Localizable.strings`
  - `Shared/Localization/ja.lproj/Localizable.strings`
- Do not hardcode user-facing strings in SwiftUI or models.
- Views must not own package parsing, persistence, file-system logic, external SDK boundaries, or low-level engines.
- Update `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, and `docs/process/PHASE_1B_AGENT_STATE.md` when task state or file structure changes.
- If adding or moving Swift files, verify Xcode project membership:
  - `PBXFileReference`
  - `PBXBuildFile`
  - correct `PBXGroup`
  - correct target `Sources`
  - relative path resolves on disk

## 9. Forbidden scope unless explicitly approved

Do not add, rewrite, or imply any of the following unless the active task explicitly requires it and the BuildPlan permits it:

- Snow provider, Snow metrics, Snow classifier, Snow sport mode, ski/lift/gondola logic, or Phase 1c Snow production work
- Production HealthKit monitoring, clinical health claims, medical detection, diagnosis, prevention, or treatment claims
- Emergency service promises, automatic emergency response, rescue guarantee, or always-on fall-detection safety promise
- Production StoreKit, purchase, subscription, transaction, or entitlement dependencies
- Trick recognition or trick classifier
- Route geometry mutation, route reconstruction, road matching, snap-to-road, map matching, or location correction
- Trusted metric mutation, speed filtering rewrites, elevation ascent recalculation, package schema changes, Core Data schema changes, import/merge/restore mutation
- Signing, capabilities, entitlements, release, TestFlight, ADP, App Store, or production distribution work unless the task explicitly says so

## 10. Watch and ActivityVisualization boundaries

- Shared ActivityVisualization decides display-preparation semantics.
- Platform views decide rendering only.
- Watch UI consumes safe provider outputs and compact outputs.
- Watch UI must not import MapKit for route semantics.
- Watch UI must not recalculate route, speed, elevation, ascent, or segmentation.
- Watch metrics must use safe availability states.
- Inline cadence remains unavailable unless safe source data exists.
- Haptic intent is an intent/policy model only until a later task explicitly permits device playback.

## 11. Manual QA rules

Manual QA is required when a hotfix affects:

- UI layout
- navigation
- watchOS interaction
- session controls
- file/package opening
- charts, carousel, metric cards, or visual states
- localization layout
- accessibility
- destructive actions
- import/export/open flows

Manual QA focus points must be included in the same reply as the apply/verify instructions.
The user must explicitly confirm success before commit.

## 12. Source pack discipline

Before each new subtask, collect a source pack from the current branch/head.
Use the project `FILE_STRUCTURE.md` as the main guide.
Use `SNOW_FILE_STRUCTURE.md` only as a structural/reference guide when the user asks to align with Snow patterns; it must not unlock Snow production work.

A source pack should normally include:

- repo status and current branch/head logs
- BuildPlan and Workflow references when available
- `docs/reference/FILE_STRUCTURE.md`
- `docs/history/DEV_LOG.md`
- `docs/process/PHASE_1B_AGENT_STATE.md`
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`
- affected Swift files
- affected tests
- affected verifier scripts
- localization files when user-facing copy may change
- Xcode project file when files may be added/moved or membership may change

## 13. Current next-step hint for Codex

The next implementation task after this AGENTS.md setup is expected to be:

```text
Task-038d — Haptics/Safety Verifier + Manual QA
```

Before implementing 038d, do a fresh source audit from branch:

```text
task-038-haptics-safety-shells
```

Expected starting HEAD for Task-038d after Task-038c:

```text
d019aa79e94e296567a8373f6e00cdc60487eada
```

Do not start 038d implementation until the source audit confirms the branch/head and working tree are clean.

## 14. Agent response style for this repo

- Be concise but precise.
- State uncertainty instead of guessing.
- Ask for source packs/logs when needed.
- Do not say a task is passed unless logs prove it.
- When producing Terminal commands, leave the prompt usable.
- When producing hotfixes, use one-click apply-plus-verify with zip packaging.
- When a mistake happens, stop, inspect logs, and provide the smallest safe recovery path.
