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
