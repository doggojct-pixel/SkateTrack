# SkateTrack ADR Index

**Status:** Active index — Task-030b consolidation  
**Last Updated:** 2026-06-13  
**Purpose:** Preserve the historical meaning of old ADRs while moving daily rules and Pre-ADP limitations into consolidated documents.

Task-030b removes the old ADR single files from the active docs tree to reduce fragmentation. Their decisions remain summarized here. Use this index to understand where a decision now lives.

## Active documentation after consolidation

| Active file | Owns |
|---|---|
| `docs/DEVELOPMENT_RULES.md` | Recurring development workflow, scope-control, localization, macOS layout, hotfix, commit, and verification rules. |
| `docs/KNOWN_LIMITATIONS_PRE_ADP.md` | Blocked features, external-service constraints, unlock conditions, and no-overclaim rules. |
| `docs/RELEASE_READINESS_PRE_ADP.md` | Pre-ADP release-readiness gate. |
| `docs/MANUAL_QA_MATRIX_PRE_ADP.md` | Manual QA matrix and release-blocking checks. |
| `docs/DOCUMENTATION_INDEX.md` | Reading order and documentation source-of-truth map. |

## Historical ADR mapping

| Old ADR | Historical decision | Current status | Consolidated into |
|---|---|---|---|
| ADR-0001 Subscription Entitlement Strategy | Paid features use replaceable entitlement providers and DEBUG / local simulation before production StoreKit. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-001 |
| ADR-0002 Developer Account Dependent Services | Google, Drive, WeatherKit, StoreKit, and other external-account services must remain disabled / provider-boundary only before credentials. | Consolidated | `KNOWN_LIMITATIONS_PRE_ADP.md`, `DEVELOPMENT_RULES.md` |
| ADR-0003 GPS-Denied Indoor Recording Strategy | Do not fake indoor speed / route; indoor fallback and ARKit / UWB are deferred. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-008 |
| ADR-0004 Export Targets and Package Strategy | Share-card export, backup package, and portable `.skatetrack` package are separate export types. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-007 |
| ADR-0005 Achievements and Challenges Scope Strategy | Achievements and weekly challenges are local-first; social / remote / Game Center style features are deferred. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` |
| ADR-0006 Backup Provider and Package Strategy | Local backup package and restore preview exist; Drive sync and destructive restore remain blocked. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-003 |
| ADR-0007 Portable `.skatetrack` Package Strategy | `.skatetrack` is a portable local package; macOS viewer is read-only; custom UTType / document association deferred. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-007 |
| ADR-0008 Real-device Background GPS Recording | Background GPS recording is implemented but requires real-device release validation. | Consolidated | `KNOWN_LIMITATIONS_PRE_ADP.md` L-008, `MANUAL_QA_MATRIX_PRE_ADP.md` |
| ADR-0009 Localization and Privacy Copy Strategy | Active languages are English, Traditional Chinese, and Japanese; localization key / placeholder parity is required. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-010 / L-011 |
| ADR-0010 Accessibility, Privacy Copy, and UX Quality Gate | Accessibility and privacy-copy checks are required before release-readiness closure. | Consolidated | `DEVELOPMENT_RULES.md`, `RELEASE_READINESS_PRE_ADP.md`, `MANUAL_QA_MATRIX_PRE_ADP.md` |
| ADR-0011 Pre-ADP Release Readiness Strategy | Task-030 is a Pre-ADP quality gate, not a production-service unlock task. | Consolidated | `RELEASE_READINESS_PRE_ADP.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` |

## Future ADR rule

New ADR files should be rare. Add a new ADR only when a decision is too specific or too consequential to fit into:

- `DEVELOPMENT_RULES.md`
- `KNOWN_LIMITATIONS_PRE_ADP.md`
- `RELEASE_READINESS_PRE_ADP.md`
- `MANUAL_QA_MATRIX_PRE_ADP.md`

If a new ADR is added later, update this index with:

- ADR number and title.
- Decision summary.
- Current status.
- Owning active documentation file.
- Future reopen condition.

Task-030b verification token: ADR index consolidated.
