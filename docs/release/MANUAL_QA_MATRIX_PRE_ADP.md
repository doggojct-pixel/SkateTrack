# SkateTrack Manual QA Matrix — Pre-ADP

**Status:** Task-030e macOS package-viewer QA matrix sync
**Last Updated:** 2026-07-04
**Scope:** Local development builds before Apple Developer Program enrollment and production external-service setup

This matrix describes manual testing required before treating the current `develop` branch as a Pre-ADP release-readiness checkpoint. It does not replace App Store / TestFlight QA after Apple Developer Program enrollment.

## 1. Language matrix

Run the highest-priority flows in all active languages:

| Language | Code | Required |
|---|---:|---:|
| English | `en` | Yes |
| Traditional Chinese | `zh-Hant` | Yes |
| Japanese | `ja` | Yes |

Checks:

- No missing localization keys are visible.
- Long Japanese strings do not cover macOS window controls.
- Long Japanese strings do not overlap iOS Live HUD or action buttons.
- Permission copy does not imply production services are enabled.

## 2. iOS ride recording

| Flow | Steps | Expected result |
|---|---|---|
| Start ride | Open `滑行`, choose sport / mode, start session | Live HUD appears and records real sensor data. |
| Foreground GPS | Use simulator route or outdoor test while app is visible | Speed, distance, and samples update. |
| Background GPS real-device gate | Start session, turn screen off, keep phone in pocket, move 150–300 m for 3–5 min | Completed session has non-zero distance, route points, and speed metrics. This remains a Task-030 release-blocking real-device gate. |
| Stop ride | End session through the normal slide / end flow | Session summary appears and can be saved / reviewed. |
| Safety UI | Confirm emergency contacts / fall alert UI remains accessible | UI is reachable; do not use unsafe human-impact testing. |

## 3. iOS feature surfaces

| Surface | Required checks |
|---|---|
| 歷史紀錄 | Completed sessions are visible; locked / free-limit behavior remains consistent. |
| 我的裝備 | Equipment records and attribution UI still load. |
| 場地 | Local spots, rideability, and manual spot association still load. |
| 成就 | Local achievements and weekly challenge previews still load. |
| 帳號 | Local account simulation and disabled Google Sign-In copy are clear and non-misleading. |
| 本機備份 | Backup package export is local-only; Google Drive is disabled. |
| 還原預覽 | Restore preview is non-destructive and does not overwrite local data. |
| `.skatetrack` 匯出 | Exported package does not include account tokens or cloud credentials. |

## 4. macOS package viewer

Task-030e macOS package viewer QA must cover read-only multi-package browsing and the documentation/verifier foundation. These checks do not approve import, merge, restore, route correction, road matching, or Finder document association.

| Flow | Steps | Expected result |
|---|---|---|
| Launch macOS app | Run `SkateTrack-macOS` | Sidebar appears and does not cover red/yellow/green window buttons. |
| Browser-first open | Open `Session Browser`, use `Open Packages` | Package opening starts from the browser header, not from a primary Import destination. |
| Multi-file open | Select 3–5 `.skatetrack` files from `NSOpenPanel` | Valid packages appear as cards; invalid files surface partial-success failure messages without blocking valid packages. |
| Package cards | Switch between package cards and remove one package card | Selection and removal are in-memory only; no database import, delete, merge, or local-history write occurs. |
| Selected sessions | Select sessions inside an opened package | Right-side detail updates and keeps the macOS layout: compact summary above dashboard/details. |
| Route map context | Open a moving package | Read-only MapKit route context uses package route samples only; no location prompt appears and no user-location blue dot appears. |
| Expanded route inspection | Use `View Larger Route` / equivalent control | Resizable route inspection window opens, pans / zooms, and closes without mutating package data. |
| Route visual parity | Inspect route quality segments | High-confidence, low-confidence, and startup warm-up segments match iOS semantic colors. |
| Speed / elevation | Inspect speed chart, elevation profile, and total ascent | Charts render display-only data without changing trusted metrics or package payloads. |
| Duplicate warning | Reopen an already opened file | Duplicate warning appears as an attention state, not as a destructive blocker. |
| Acknowledge duplicate | Click `已了解` / Acknowledge | Only the transient duplicate-file-path warning visual state clears; packages remain loaded. Reopening the same duplicate file surfaces the warning again. |
| Localization | Check English, Traditional Chinese, and Japanese | No missing keys, placeholder strings, or unit-format mismatch are visible. |
| Accessibility | Use VoiceOver / Accessibility Inspector spot checks | Open, clear, acknowledge, package card, session card, route inspection, speed chart, and elevation chart expose meaningful labels / hints / identifiers. |
| One-click logs | Run Task-030e one-click verification | Summary, verifier, build, line, diff, status, and postpack cleanup logs are included in the zip. |
| One-click cleanup | Inspect upload folder after one-click | The temporary `task030e_*_oneclick_<timestamp>/` run directory is gone and the postpack log records `ONECLICK_RUN_DIR_REMOVED=YES`. |

## 5. Accessibility spot checks

| Platform | Required checks |
|---|---|
| iOS | VoiceOver reads Live HUD status, emergency contact controls, and DEBUG tools with localized labels. |
| macOS | VoiceOver reads package summary, Session detail, route preview, and speed chart with localized labels / hints. |
| All | Accessibility copy does not claim MapKit, road matching, heat maps, Google Drive, CloudKit, or production StoreKit support. |

## 6. Privacy and service boundary checks

| Area | Required check |
|---|---|
| Google Sign-In | UI says Google setup is unavailable / deferred, not completed. |
| Google Drive | Backup UI says Drive sync is blocked / deferred, not active. |
| StoreKit | Paid features continue using DEBUG / local entitlement simulation only. |
| CloudKit / iCloud | No UI claims Apple cloud sync is active. |
| `.skatetrack` | macOS viewer is read-only; no import / merge / restore / winner-selection / local-history claims. |
| GPS | Background GPS copy is careful and still requires real-device validation. |
| Fall Detection | Do not use unsafe human-fall testing; record diagnostics need as deferred. |

## 7. Build and scheme hygiene

Before committing Task-030b or any later task:

- Run iOS simulator build.
- Run macOS build.
- Check `git status --short`.
- Do not commit `.xcscheme` changes from App Language, App Region, or Location Scenario testing.
- Do not commit DerivedData, simulator exports, `.skatetrack` sample files, or unzipped hotfix folders.

## 8. Release-blocking open items

The following block public release claims until completed or explicitly scoped out:

- Real-device background GPS outdoor validation.
- Native Japanese copy review.
- Full VoiceOver walkthrough on real devices.
- Safe Fall Detection diagnostics / controlled test protocol.
- Apple Developer Program enrollment before TestFlight / StoreKit / capabilities work.

Task-030a verification token: manual QA matrix pre-ADP.
Task-030b verification token: consolidated manual QA matrix.

Task-030e-MacViewer-012 manual QA token: multi-package viewer manual QA, duplicate acknowledgement, route inspection, one-click cleanup, read-only no-import boundary.
