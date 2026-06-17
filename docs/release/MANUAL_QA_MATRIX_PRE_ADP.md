# SkateTrack Manual QA Matrix — Pre-ADP

**Status:** Task-030b consolidated QA matrix  
**Last Updated:** 2026-06-13  
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

| Flow | Steps | Expected result |
|---|---|---|
| Launch macOS app | Run `SkateTrack-macOS` | Sidebar appears and does not cover red/yellow/green window buttons. |
| Import package | Select a `.skatetrack` file from NSOpenPanel | Package preview displays manifest and validation. |
| Session Browser | Open `Session 瀏覽器` after import | Right side shows compact package summary above dashboard. |
| Route preview | Open moving package | Lightweight route shape appears with start/end markers. |
| Speed chart | Open moving package | Lightweight speed chart appears. |
| Empty / stationary package | Open old zero-distance package | Viewer shows limited / unavailable route state without crashing. |
| Locked areas | Open analytics / video overlay / cloud sync | Coming-soon cards remain locked and non-misleading. |

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
| `.skatetrack` | macOS viewer is read-only; no import / merge / restore claims. |
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

## 9. Phase 1c Snow Mode iPhone UI smoke test

Snow Mode remains DEBUG-gated until the Phase 1c production path is complete. For local development builds on `feature/snow-mode`, verify:

| Flow | Steps | Expected result |
|---|---|---|
| Snow entry gate | Open Debug Tools and toggle the Snow Mode entry | Snow entry is hidden when the toggle is off and visible when the toggle is on. |
| Start Snow session | Select Snow / Skiing or Snowboarding from Session Start | Session starts without crash and routes to the Snow live HUD. |
| Snow live HUD | Start a simulator Snow session | Snow-specific HUD appears. In simulator-only testing, waiting / low-confidence or zero-data states are acceptable. |
| Existing HUD preservation | Start Skateboard or Inline session | Existing Live HUD appears unchanged and pause / resume / end controls still work. |
| Snow summary empty state | End a simulator Snow session without real snow movement | Snow summary / timeline / distance inspector appear without crash and may show zero / empty values. |
| Scope boundary | Inspect behavior after Snow UI test | No Watch UI / WatchBridge behavior should change. |

Task-005 manual QA token: Snow iPhone UI smoke test complete.

## 10. Phase 1c Snow Mode Watch mock UI smoke test

Snow-Task-006a provides a DEBUG-only mock-backed Watch Snow UI. It is not real WatchBridge data wiring.

| Flow | Steps | Expected result |
|---|---|---|
| DEBUG mock gallery entry | Run `SkateTrack-watchOS` on an Apple Watch simulator | Snow Watch mock gallery appears instead of the original plain welcome shell. |
| Downhill scenario | Select Downhill | Large speed, run number, vertical drop, and counting status display correctly. |
| Lift / gondola scenario | Select Lift / Gondola | Uphill transport is clearly shown and marked as not counted toward ski distance. |
| Waiting scenario | Select Waiting | Waiting / queue state and last-run summary display correctly. |
| Low confidence scenario | Select Low Confidence | Low-confidence warning and confidence / status information display correctly. |
| Fall alert scenario | Select Fall Alert | Fall-alert card, impact value, SOS/status, and acknowledgement presentation display correctly. No real SOS flow is triggered. |
| Summary scenario | Select Summary | Today's runs, total vertical, ski distance, lift distance, and top speed display correctly. |
| Controls | Use Start / Pause / Resume / Mark / End / subscriber toggle | Controls do not crash and haptic intent text updates as expected. |
| Release fallback | Build Release watchOS target if needed | Mock provider is not injected as fake production data; neutral fallback remains available before 006b. |
| Scope boundary | Inspect source / behavior after Watch QA | No `Shared/WatchBridge/*`, WatchConnectivity, real sensors, HealthKit, or emergency-contact behavior is involved. |

Snow-Task-006a manual QA token: Watch Snow mock gallery smoke test complete.
