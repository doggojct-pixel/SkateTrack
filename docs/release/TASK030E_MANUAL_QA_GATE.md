# Task-030e macOS Multi-Package Viewer Manual QA Gate

**Status:** Task-030e-MacViewer-013 manual QA gate checklist
**Last Updated:** 2026-07-04
**Scope:** Operator-run manual QA for the read-only macOS `.skatetrack` multi-package viewer before the final merge gate.

This file is the Task-030e manual QA signoff checklist. It does not add product behavior. It exists so the manual gate is explicit, repeatable, and traceable before `Task-030e-MacViewer-014 — Final Merge Gate`.

## 1. Required automated preconditions

Before manual QA can be considered valid, the operator must confirm all of the following logs have passed:

- Apply log reports `APPLY_RESULT=PASSED`.
- Task-030e one-click zip summary reports `ONECLICK_RESULT=PASSED`.
- macOS build reports `xcodebuild_macos_build_EXIT=0`.
- Focused Swift line check reports `LINE_CHECK_RESULT=PASSED` and `LINE_EXIT=0`.
- Documentation whitespace and `git diff --check` report no failures.
- Git status log shows only the expected Task-030e-013 changed files before commit.
- Postpack log reports `ONECLICK_ZIP_EXIT=0`, `ONECLICK_CLEANUP_EXIT=0`, and `ONECLICK_RUN_DIR_REMOVED=YES`.

## 2. Manual QA package set

Use at least these package categories when available:

| Package type | Required result |
|---|---|
| Valid single-session `.skatetrack` package | Opens as a package card and selected session detail renders. |
| Valid multi-session `.skatetrack` package | Package card shows batch/session count and session list is selectable. |
| Multiple valid packages selected together | All valid packages remain loaded in-memory and are independently selectable. |
| Mixed valid / invalid selection | Valid packages remain loaded; invalid files produce partial-success failure messaging. |
| Duplicate file path reopen | Duplicate file-path warning appears as an attention state. |
| Duplicate session identifier package pair | Duplicate session identifier is surfaced as attention, not destructive blocking. |
| Moving route package | Route context, speed chart, elevation profile, and total ascent render display-only data. |
| Legacy / sparse package | Missing route/elevation data uses empty states without crashing or fabricating data. |

## 3. Manual QA checklist

| Gate | Required manual check | Pass condition |
|---|---|---|
| Launch / layout | Launch `SkateTrack-macOS`, open Session Browser | Sidebar and browser layout remain usable; traffic-light window controls are not covered. |
| Browser-first open | Use `Open Packages` from Session Browser | Package opening starts from the browser header, not a primary Import destination. |
| Multi-file open | Select multiple `.skatetrack` files in one open panel | `NSOpenPanel` accepts multi-select and valid packages are all represented as cards. |
| Partial success | Include an invalid file in the selection | Valid packages stay loaded and failed files are disclosed without blocking review. |
| Package cards | Switch cards and remove one card | Selection/removal are in-memory only; no local-history import or package deletion occurs. |
| Selected sessions | Switch sessions in the selected package | Detail panel updates without changing package data. |
| Route context | Inspect a moving route package | Route uses package samples only; no location prompt appears and no user-location blue dot appears. |
| Route visual parity | Inspect route segment colors | High-confidence, low-confidence, and startup warm-up segments match the iOS semantic colors. |
| Expanded inspection | Open and close the larger route inspection window | Window is resizable and read-only; route geometry is not mutated. |
| Speed / elevation | Inspect speed chart, elevation profile, and total ascent | Data is display-only and does not recalculate trusted metrics or rewrite package payloads. |
| Duplicate attention | Reopen an already opened file | Duplicate warning appears as warning/attention, not destructive blocking. |
| Acknowledge duplicate | Click `已了解` / Acknowledge / 確認しました | Only the current duplicate-file-path warning visual state clears; reopening the duplicate surfaces it again. |
| Localization | Spot-check English, Traditional Chinese, and Japanese | No missing keys, placeholder keys, wrong unit formats, or layout-breaking strings appear. |
| Accessibility | Use VoiceOver or Accessibility Inspector spot checks | Open, clear, acknowledge, package card, session card, route inspection, speed chart, and elevation chart expose meaningful labels/hints/identifiers. |
| Boundary scan | Watch for unsupported behavior | No import, merge, duplicate deletion, winner selection, local-history import, route correction, road matching, snap-to-road, location permission, user-location display, Core Data write, package schema change, Watch, WatchBridge, or Task-031 behavior appears. |

## 4. Required uploaded evidence

Upload these artifacts before commit/push:

```text
/Users/doggo/Documents/App軟體區/upload/task030e_013_apply_*.log
/Users/doggo/Documents/App軟體區/upload/task030e_013_oneclick_*.zip
```

The conversation message must also explicitly state whether the manual QA checklist passed. A manual QA failure is a blocker even when automated one-click verification is green.

## 5. Pass condition

Task-030e-MacViewer-013 passes only when:

- The gate confirms no import, no merge, no route geometry mutation, no trusted metrics mutation, no package schema change, no Core Data write, no location permission, and no user-location display.

- The 013 apply log passes.
- The 013 one-click zip passes.
- The one-click postpack cleanup records `ONECLICK_RUN_DIR_REMOVED=YES`.
- The operator explicitly confirms manual QA success in the conversation.
- The final diff remains limited to the manual QA gate documents and verifier scripts.
- No product UI, package schema, Core Data write, route geometry mutation, trusted metric mutation, location permission, user-location display, Watch, WatchBridge, or Task-031 work is introduced.

Task-030e-MacViewer-013 verification token: Manual QA Gate, operator signoff required, task030e_013_oneclick, ONECLICK_RUN_DIR_REMOVED=YES, read-only no-import manual QA boundary.
