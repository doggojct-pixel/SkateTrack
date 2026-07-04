# SkateTrack Development Rules

**Status:** Active source of truth — Task-030e final merge gate
**Last Updated:** 2026-07-04
**Scope:** Human / ChatGPT / Cursor collaboration rules for SkateTrack development.

This document consolidates recurring development rules that were previously scattered across ADRs, DevProcess notes, build-plan discussions, and task handoffs. Use this file before starting any new task.

## 1. Branch and source-control rules

- Work on `develop`.
- Do not touch `main` unless the user explicitly requests a release / merge task.
- Pull latest before preparing a context package or applying a hotfix:

```bash
cd "/Users/doggo/Documents/App軟體區/SkateTrack"
git checkout develop
git pull --ff-only
git status --short
```

- Do not commit compile fixes, warning fixes, or UI polish as separate commits inside the same task stage.
- Within a task / stage, accumulate hotfixes until verify / build / manual QA pass, then commit once.
- Before commit, always check signing and capability drift:

```bash
git --no-pager diff -- SkateTrack.xcodeproj/project.pbxproj | grep -n "DEVELOPMENT_TEAM\|CODE_SIGN\|PROVISIONING\|PRODUCT_BUNDLE_IDENTIFIER" || true
```

- Also check for accidental document-association / capability drift when a task touches project settings:

```bash
git --no-pager diff -- SkateTrack.xcodeproj/project.pbxproj | grep -n "UTExportedTypeDeclarations\|CFBundleDocumentTypes\|com.apple.developer" || true
```

- Do not commit local Xcode scheme state from App Language, App Region, or Location Scenario testing.

## 2. Hotfix package rules

- Hotfix zip files must contain only files added or modified by that hotfix.
- Do not package the whole repository.
- One-click verification scripts must zip their generated logs and then delete the temporary output directory, leaving the uploadable zip as the durable artifact. Record `ONECLICK_CLEANUP_EXIT=0` and `ONECLICK_RUN_DIR_REMOVED=YES` when cleanup succeeds.
- If files must be removed, provide explicit `git rm` commands in the handoff rather than relying on zip extraction.
- Do not ask the user to manually add Swift files to Xcode unless there is no safe alternative.
- New Swift files must be added to `SkateTrack.xcodeproj/project.pbxproj` for the correct target membership.
- Never modify signing, provisioning, Bundle ID, or entitlements unless a task explicitly requires it and the user approves.

## 3. Documentation update rules

Every completed task or stage should update:

- `docs/history/DEV_LOG.md` for chronological history.
- `docs/reference/FILE_STRUCTURE.md` when files are added, removed, or consolidated.
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` when a feature is blocked / deferred.
- `docs/process/DEVELOPMENT_RULES.md` only when a recurring rule changes.
- `docs/adr/ADR-INDEX.md` when a decision changes status or a future ADR is added.

If a task excludes functionality that a reader might reasonably expect, document the deferred items with:

- What was not done.
- Why it was not done.
- The future unlock condition.
- The suggested future task.
- What must not be claimed in UI, docs, or release notes.

## 4. File-size and readability rules

- Swift source files should generally remain under 500 lines.
- Split large Views / ViewModels / Providers when they become difficult to review.
- Resource and documentation files do not follow the 500-line Swift limit.
- `Localizable.strings`, `InfoPlist.strings`, Markdown docs, and generated-style resource files are governed by consistency checks, not the Swift 500-line rule.

## 5. Localization rules

Active languages:

- English: `en`
- Traditional Chinese: `zh-Hant`
- Japanese: `ja`

Localization requirements:

- User-visible strings should go through localization resources.
- `Localizable.strings` keys must match across all active languages.
- Placeholder counts and formats must match across languages.
- Permission strings should be checked in `InfoPlist.strings` where applicable.
- Japanese localization is first-pass and requires native review before public App Store release.
- Do not add `pt-BR` or `es` before the deferred localization roadmap is explicitly unlocked.

## 6. Manual test checklist style

When providing manual QA steps:

- Use clear Traditional Chinese feature names for user-facing flows.
- Keep file names, commands, scheme names, and technical identifiers in English when appropriate.
- Explicitly list expected behavior and non-goals.
- Treat Xcode warnings as actionable unless they are clearly simulator / system console noise.
- For Task-030e manual closure, use `docs/release/TASK030E_MANUAL_QA_GATE.md` as the source-controlled checklist and require explicit operator signoff before commit/push.

## 7. Runtime scope boundaries

Do not change these unless a task explicitly asks for it:

- Launch Screen.
- AppIcon.
- Bottom dock.
- watchOS runtime.
- macOS runtime, unless the task is macOS-specific.
- Core GPS / IMU / SensorFusion / FallDetection algorithms, unless the task is explicitly about those systems.

Do not claim unsupported features in UI, docs, release notes, or QA handoff.

Do not reintroduce:

- Mock speed into normal runtime.
- Fake route drawing.
- Fake background SMS behavior.
- UI copy that implies cloud, subscription, or production services are complete when they are not.

## 8. Apple Developer Program / external-service boundary

Before Apple Developer Program and production credentials are available:

- StoreKit production must remain blocked behind local / DEBUG entitlement simulation.
- Google Sign-In production must remain blocked behind provider boundaries.
- Google Drive sync must remain blocked behind disabled providers.
- CloudKit / iCloud must not be added.
- WeatherKit production must not be added.
- TestFlight / App Store submission must not be claimed.
- Custom `.skatetrack` UTType / Finder open-with / document association must not be added.

Use `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` as the source of truth for unlock conditions.

## 9. Package / backup rules

- Backup packages and portable `.skatetrack` export packages are different package types.
- Backup restore remains non-destructive preview only unless a future restore-execution task explicitly implements confirmation and conflict policy.
- macOS `.skatetrack` viewer remains read-only.
- Do not write imported `.skatetrack` packages into a database during the current Pre-ADP phase.
- Do not implement merge / restore / persistent package library as a side effect of viewer work.

## 10. macOS layout rules

The macOS layout principle established during Task-028a / Task-028b is active:

- Left sidebar is only for functional navigation.
- Do not put package data or session content into the left sidebar.
- Right side is the work area.
- Right top section should be a low-height summary.
- Right lower section should contain the main dashboard / details / route / chart content.
- Avoid iOS-style large-card stacking on macOS.
- Avoid an empty middle column that contains only one card.
- Ensure content does not cover macOS red / yellow / green window controls.
- Long Japanese text must wrap or truncate safely without hiding critical data.

## 11. GPS and safety testing rules

- Simulator GPS success does not replace real-device outdoor background GPS validation.
- iPhone 13 Pro or equivalent lock-screen / pocket test remains a Pre-ADP release gate.
- Fall Detection must not be validated through unsafe human hard-fall testing.
- Fall Detection diagnostics / safe test mode must be added before stronger public safety claims.

## 12. Verification gate rule

When a task includes a verify script, run it before build / commit. When a task changes release readiness or documentation structure, run the task-specific docs verifier when available and the release-readiness verifier:

```bash
python3 scripts/verify_task030e_documentation_sync.py
python3 scripts/verify_task030e_manual_qa_gate.py
python3 scripts/verify_task030_release_readiness.py
```

For Task-030e macOS package-viewer work, also run:

```bash
bash scripts/run_task030e_macos_multi_package_viewer_oneclick.sh
```

Task-030b verification token: consolidated development rules.

Task-030e-MacViewer-012 verification token: one-click temporary output directory cleanup, documentation sync gate, Task-030e docs verifier.

Task-030e-MacViewer-013 verification token: Manual QA Gate, source-controlled checklist, operator signoff required, no UI / schema / route mutation.


## Task-030e final merge gate rule

Task-030e final merge gate work is governed by `docs/release/TASK030E_FINAL_MERGE_GATE.md` and `scripts/verify_task030e_final_merge_gate.py`. The gate is docs/tooling/merge-readiness only and must not add product UI, package schema changes, Core Data writes, route geometry mutation, trusted metrics mutation, location permission, user-location display, Watch behavior, or Task-031 implementation.

Before any merge back to `develop`, the assistant must review 014 apply / one-click logs, confirm manual QA carry-forward, confirm `origin/develop` ancestry or request rebase/merge-from-develop and reverification, and leave `main` untouched unless the user explicitly requests a release.

Task-030e-MacViewer-014 verification token: Task-030e final merge gate, docs/release/TASK030E_FINAL_MERGE_GATE.md, verify_task030e_final_merge_gate.py, leave `main` untouched.
