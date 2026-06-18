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

## 11. Phase 1c Snow Mode macOS viewer smoke test

Snow-Task-007 provides a read-only macOS Snow viewer. The DEBUG preview exists for local UI validation before Snow-Task-008 package payload support.

| Flow | Steps | Expected result |
|---|---|---|
| DEBUG Snow preview entry | Run `SkateTrack-macOS` in DEBUG | Sidebar shows the Snow Analysis Preview entry. |
| Open Snow viewer | Select Snow Analysis Preview | Snow viewer opens with mock resort-day data and does not crash. |
| SnowMode visual direction | Inspect the viewer body | Viewer uses SnowMode visual language: deep snow-night panels, ice cyan downhill / route emphasis, amber lift emphasis, and low-confidence indicators. |
| Dashboard | Review the dashboard cards | Runs, ski distance, lift distance, route distance, vertical drop, top speed, duration, and average run duration are visible. |
| Route + Elevation | Inspect route and elevation panels | Lightweight route / elevation visualization is readable and limited altitude data is clearly indicated when needed. |
| Segment timeline | Select downhill, lift, and unknown rows | Timeline selection updates inspector content; downhill is counted and lift / unknown are excluded as appropriate. |
| Segment inspector | Inspect selected segment details | Segment type, distance, duration, confidence, altitude delta, and manual-correction placeholder display read-only information. |
| Distance inspector | Review the distance breakdown | Ski distance, lift distance, route distance, and unknown / excluded distance remain distinct. |
| Package pending state | Use package-pending mock state or future imported package without Snow payload | UI shows package schema pending instead of fabricated official Snow analysis. |
| Scope boundary | Inspect behavior and source after QA | No package schema / reader / writer, iOS, watchOS, WatchBridge, HealthKit, WeatherKit, CloudKit, or persistence changes are introduced. |

Snow-Task-007 manual QA token: macOS Snow viewer smoke test complete.

## Snow-Task-008a Manual QA Addendum

| Flow | Steps | Expected result |
|---|---|---|
| Old package import | Import a schema 1 `.skatetrack` package with no Snow fields | Package decodes and previews normally; no Snow crash. |
| Non-Snow export | Export a skateboard / inline session | Package has no `snowPayload`; existing preview behavior remains unchanged. |
| Snow export with state | Export a Snow session after repository-backed Snow state exists | Package declares Snow capability keys and includes official `snowPayload`. |
| Snow export without state | Export a Snow session with no repository Snow state | Package remains valid but `snowPayload` is nil; no empty placeholder analysis is fabricated. |
| macOS imported Snow package | Import a schema 2 Snow package with valid `snowPayload` | macOS shows Snow analysis through `MacSnowRootView` with source `.importedPackage`. |
| macOS imported pending package | Import a Snow package without `snowPayload` | macOS shows the existing `packageSchemaPending` state. |


## Snow-Task-008b Backup / Health Boundary QA

Run after applying Snow-Task-008b:

```bash
python3 scripts/verify_snow_backup_compatibility.py
python3 scripts/verify_snow_package_compatibility.py
python3 scripts/verify_snow_macos_viewer.py
python3 scripts/verify_snow_watch_ui.py
python3 scripts/verify_snow_iphone_ui.py
python3 scripts/verify_snow_run_boundary.py
python3 scripts/verify_snow_classifier.py
python3 scripts/verify_snow_schema.py
python3 scripts/verify_snow_sport_enum.py
```

Manual QA checklist:

- 備份 schema 1 舊檔可解碼，不因缺少 `snowSessions` 失敗。
- 新備份 schema 2 會輸出 `snowSessions: []`，代表 Snow-aware backup 但目前 0 筆 Snow session。
- 還原預覽可顯示 / 計入 Snow session count，不影響既有 session / gear / subscription counts。
- Health provider boundary 保持 iOS-only，production default 為 unavailable。
- DEBUG mock Health exporter 僅測試 wiring，不寫入系統健康資料。
- Shared 不含 `import HealthKit`。
- watchOS / macOS / iOS build 均成功。

## Snow-Task-009 QA / Regression Manual Test Matrix

Snow-Task-009 adds deterministic QA fixtures, regression tests, and manual QA coverage for the Snow Mode work completed through Snow-Task-008b. This section is intentionally written as a manual checklist; it does not introduce new runtime behavior.

### iPhone Snow Mode

- [ ] 在 DEBUG 模式確認 Snow entry 仍由 debug toggle 控制，不應在非預期狀態自行出現。
- [ ] 開啟 Snow entry 後，確認 Snow live HUD 的 idle / recording / low confidence / summary 狀態都能顯示，且不 crash。
- [ ] 使用 fixture 概念檢查低信心資料情境：低 confidence session 應能安全顯示，不應讓 summary 或 timeline 中斷。
- [ ] 確認 skiing / snowboarding 相關文案在繁中、英文、日文模式下沒有明顯錯譯或截斷。

### watchOS Snow UI

- [ ] 在 DEBUG / mock-backed 狀態確認 Watch Snow UI 可載入。
- [ ] 確認 006b WatchBridge production integration 仍是 deferred，Task 009 不應要求 WatchConnectivity。
- [ ] 確認 watchOS build 不需要 HealthKit、package schema 或 backup schema 額外變更。

### macOS Snow viewer

- [ ] 匯入含 Snow payload 的 schema v2 package 時，應直接進入 Snow viewer / `MacSnowRootView` 顯示 Snow 分析。
- [ ] 匯入沒有 Snow payload 的 Snow session package 時，應顯示 pending / unavailable 狀態，不應 crash。
- [ ] 匯入 legacy schema v1 package 時，應安全處理沒有 Snow payload 的情境。

### Package export / import

- [ ] 非 Snow session 不應輸出 Snow payload。
- [ ] Snow session 若 repository 沒有 Snow state，不應輸出空 placeholder payload。
- [ ] Snow session 若有 Snow state，package schema v2 應包含 Snow capabilities 與 `snow-payload-1.0`。
- [ ] JSON fixtures 中的 package v2 with / without Snow payload 情境都應能 decode。

### Backup compatibility

- [ ] Backup schema v1 沒有 `snowSessions` 時仍可 decode。
- [ ] Backup schema v2 的 `snowSessions: []` 應被視為合法 snow-aware empty state。
- [ ] Backup schema v2 若有 `SnowBackupSession`，基本 round-trip / preview count 不應失敗。

### Health boundary

- [ ] Production default exporter 應回傳 unavailable，不應跳出 HealthKit 權限要求。
- [ ] DEBUG mock exporter 只作為本機測試 boundary，不代表正式 HealthKit export 已完成。
- [ ] Task 009 不應加入 `import HealthKit`、`HKWorkout`、`HKQuantitySample` 或 `HKHealthStore`。

### Regression smoke check

- [ ] `python3 scripts/verify_snow_regression.py` PASS。
- [ ] `SnowQAFixtureRegressionTests` 在 iPhone 17 Pro simulator 上 PASS。
- [ ] macOS / iOS / watchOS builds PASS。
- [ ] `SnowTask009_ReviewPack.zip` 產生在 `/Users/doggo/Documents/App軟體區/upload/`。
