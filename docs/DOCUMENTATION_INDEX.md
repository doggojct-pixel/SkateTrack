# SkateTrack Documentation Index

**Status:** Active — Task-030b documentation consolidation  
**Last Updated:** 2026-06-13  
**Purpose:** This file is the first documentation entry point for future ChatGPT / Cursor / human handoff.

SkateTrack documentation is intentionally consolidated into a small set of active source-of-truth files. Older ADR single files and stage-specific technical-risk notes have been summarized into the active files below to avoid fragmented instructions.

## 1. Read these first for any new task

| Order | File | Purpose |
|---:|---|---|
| 1 | `docs/DOCUMENTATION_INDEX.md` | Documentation map and reading order. |
| 2 | `docs/DEVELOPMENT_RULES.md` | Day-to-day development rules, hotfix workflow, commit policy, layout rules, and scope boundaries. |
| 3 | `docs/KNOWN_LIMITATIONS_PRE_ADP.md` | Features blocked before Apple Developer Program / production credentials, with unlock conditions and no-overclaim rules. |
| 4 | `docs/RELEASE_READINESS_PRE_ADP.md` | Pre-ADP release-readiness gate, required verify scripts, build commands, and source-control hygiene. |
| 5 | `docs/MANUAL_QA_MATRIX_PRE_ADP.md` | Manual QA matrix for iOS, macOS, localization, accessibility, privacy, GPS, and safety checks. |
| 6 | `docs/FILE_STRUCTURE.md` | Current repository structure and task progress snapshot. |
| 7 | `docs/decisions/ADR-INDEX.md` | Historical ADR index and mapping from old ADR decisions to the active consolidated documents. |

## 2. Living history files

| File | Role | Rule |
|---|---|---|
| `docs/DEV_LOG.md` | Chronological development history. | Append-only whenever practical; do not use it as the primary rules document. |
| `docs/FILE_STRUCTURE.md` | Current source tree map and progress snapshot. | Update when adding, removing, or consolidating files. |

## 3. Active policy files

| File | Owns |
|---|---|
| `docs/DEVELOPMENT_RULES.md` | Development workflow, hotfix handling, commit / push policy, file-size rules, localization rules, macOS layout principles, documentation update requirements, and prohibited scope creep. |
| `docs/KNOWN_LIMITATIONS_PRE_ADP.md` | StoreKit, Google Sign-In, Google Drive, CloudKit / iCloud, WeatherKit, TestFlight, custom UTType / document association, real-device GPS validation, Fall Detection diagnostics, Japanese review, and future localization roadmap. |
| `docs/RELEASE_READINESS_PRE_ADP.md` | The verification gate before treating `develop` as a Pre-ADP release-readiness checkpoint. |
| `docs/MANUAL_QA_MATRIX_PRE_ADP.md` | Manual QA checklist by platform / feature / language / privacy boundary. |
| `docs/decisions/ADR-INDEX.md` | Historical decision inventory after ADR consolidation. |

## 4. Consolidated / removed documents

The following old ADR single files were intentionally consolidated during Task-030b and should not remain as active source files:

- `docs/decisions/ADR-0001-subscription-entitlement-strategy.md`
- `docs/decisions/ADR-0002-developer-account-dependent-services.md`
- `docs/decisions/ADR-0003-gps-denied-indoor-recording-strategy.md`
- `docs/decisions/ADR-0004-export-targets-and-package-strategy.md`
- `docs/decisions/ADR-0005-achievements-and-challenges-scope-strategy.md`
- `docs/decisions/ADR-0006-backup-provider-and-package-strategy.md`
- `docs/decisions/ADR-0007-portable-skatetrack-package-strategy.md`
- `docs/decisions/ADR-0008-real-device-background-gps-recording.md`
- `docs/decisions/ADR-0009-localization-and-privacy-copy-strategy.md`
- `docs/decisions/ADR-0010-accessibility-privacy-quality-gate.md`
- `docs/decisions/ADR-0011-pre-adp-release-readiness-strategy.md`

The stage-specific file `docs/Task026-030_TechRisk_Solutions.md` was also consolidated into the active files above and should not remain as an active root document.

Historical facts from those files are preserved in `docs/decisions/ADR-INDEX.md`, `docs/DEVELOPMENT_RULES.md`, `docs/KNOWN_LIMITATIONS_PRE_ADP.md`, `docs/RELEASE_READINESS_PRE_ADP.md`, and `docs/MANUAL_QA_MATRIX_PRE_ADP.md`.

## 5. Documentation rules

- Do not create a new ADR file for every small task.
- Use `docs/DEVELOPMENT_RULES.md` for recurring workflow rules.
- Use `docs/KNOWN_LIMITATIONS_PRE_ADP.md` for blocked / deferred features and unlock criteria.
- Use `docs/RELEASE_READINESS_PRE_ADP.md` and `docs/MANUAL_QA_MATRIX_PRE_ADP.md` for release-readiness and QA gates.
- If a future architectural decision is large enough to require its own ADR, add it to `docs/decisions/ADR-INDEX.md` and explain why it is not just another rule or known limitation.

Task-030b verification token: documentation index consolidated.
