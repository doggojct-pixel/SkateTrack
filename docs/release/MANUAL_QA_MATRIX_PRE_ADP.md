# SkateTrack Manual QA Matrix — Pre-ADP

**Status:** Task-030e macOS package-viewer QA matrix and manual gate sync
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


### Task-030e-MacViewer-013 manual QA gate

Before Task-030e final merge, run the dedicated gate in `docs/release/TASK030E_MANUAL_QA_GATE.md`.

Additional 013-specific requirements:

- Attach the 013 apply log and 013 one-click zip to the review conversation.
- Confirm the one-click postpack log records `ONECLICK_RUN_DIR_REMOVED=YES`.
- Confirm the temporary one-click run directory was removed after zip packaging.
- Explicitly state in the conversation whether manual QA passed.
- Treat any manual failure as a blocker even if automated verification is green.
- Keep the gate read-only: no import, no merge, no duplicate deletion, no winner selection, no local-history import, no route geometry mutation, no trusted metrics mutation, no package schema change, no Core Data write, no location permission, and no user-location blue dot.

Task-030e-MacViewer-013 manual QA token: operator signoff required, task030e_013_oneclick, read-only no-import boundary, ONECLICK_RUN_DIR_REMOVED=YES.

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


## Task-030e-MacViewer-014 final merge gate

The Task-030e final merge gate is documented in `docs/release/TASK030E_FINAL_MERGE_GATE.md`. The Task-030e-MacViewer-013 manual QA gate remains a merge blocker: a green 014 one-click run does not override failed or missing operator signoff.

Final merge QA evidence must include `task030e_014_oneclick`, `ONECLICK_RUN_DIR_REMOVED=YES`, clean diff/status review, develop merge readiness, and confirmation that the macOS package viewer remains read-only with no import / merge / route mutation, no schema / Core Data mutation, no location permission, and no user-location display.

Task-030e-MacViewer-014 verification token: Task-030e-MacViewer-014 final merge gate, TASK030E_FINAL_MERGE_GATE.md, manual QA gate remains a merge blocker, task030e_014_oneclick.

<!-- TASK038D_HAPTICS_SAFETY_MANUAL_QA_START -->
## Task-038d Haptics/Safety Manual QA Gate

Task-038d is docs/verifier-only closure preparation, but final Task-038 closure still requires an aggregate operator QA pass because Task-038b and Task-038c introduced visible watchOS shell UI and user-facing safety copy.

Manual QA status:

```text
MANUAL_QA_HAPTICS_SAFETY=PENDING_OPERATOR_CONFIRMATION
```

Required aggregate checklist:

- 在 watchOS simulator 開啟 live session face。
- 確認 Task-038b Health Reminder shell 與 Task-038c Fall Safety shell 位置合理，沒有擠壓或遮住 metric carousel、live controls、session status。
- 確認 haptic intent 仍只是 mock/disabled intent 狀態，沒有 WatchKit 實體震動播放。
- 確認健康提醒文案只描述一般提醒，不宣稱醫療監測、診斷、治療、預防、臨床準確或 HealthKit 身體資料讀取。
- 確認 fall safety 文案只描述 presentation shell / limitation，不承諾跌倒偵測、SOS、自動通知、急救、救援或緊急服務。
- 點選 false alarm / dismiss 類按鈕，確認 shell 可回到安全狀態，且不觸發 emergency/SOS/HealthKit/sensor 行為。
- 確認沒有跳 HealthKit 權限請求，沒有讀取心率或身體資料。
- 確認速度、路線、海拔、metric carousel、session controls 行為沒有改變。
- 確認 VoiceOver/accessibility label 不含 emergency/medical/detection promise。
- 確認 Snow 功能沒有出現或改變。
- 完成後回報 MANUAL_QA_HAPTICS_SAFETY=PASSED 或明確列出失敗項目。

Task-038d manual QA token: aggregate haptics/safety manual QA pending, no production HealthKit, no WatchKit haptic playback, no emergency/SOS automation, no fall detection implementation.
<!-- TASK038D_HAPTICS_SAFETY_MANUAL_QA_END -->

<!-- TASK039A_COMPLICATION_MANUAL_QA_START -->
## Task-039a Complication Shell Manual QA Gate

Task-039a changes the visible watchOS live session face by adding a disabled Watch face complication placeholder shell. Manual QA is required before commit/push.

Manual QA status:

```text
MANUAL_QA_TASK039A_COMPLICATION=PENDING_OPERATOR_CONFIRMATION
```

Required checklist:

- 在 watchOS simulator 開啟 live session face。
- 確認新增的 Watch face / 錶面 shell 卡片位置合理，沒有擠壓或遮住速度、紀錄狀態、Health Reminder shell、Fall Safety shell、metric carousel 或 live controls。
- 確認卡片呈現 unavailable / 未開放狀態，不宣稱可新增到錶面、不宣稱 TestFlight / App Store / production distribution readiness。
- 確認 speed / time / distance 只是 placeholder slot，沒有提供錶面 timeline 或真正 complication 更新。
- 確認沒有新增 WidgetKit / ClockKit 權限提示、extension 行為或能力要求。
- 檢查 English、Traditional Chinese、Japanese 文案沒有缺 key、重疊或過長遮擋。
- 使用 VoiceOver / Accessibility Inspector spot check，確認 accessibility label 也只描述 placeholder shell。
- 確認 Snow、StoreKit、HealthKit、route / speed / elevation runtime 行為沒有改變。
- 完成後回報 MANUAL_QA_TASK039A_COMPLICATION=PASSED 或明確列出失敗項目。

Task-039a manual QA token: complication shell pending, no WidgetKit extension, no ClockKit data source, no production complication distribution claim.
<!-- TASK039A_COMPLICATION_MANUAL_QA_END -->

<!-- TASK039B_QUICK_START_MANUAL_QA_START -->
## Task-039b Quick Start Shell Manual QA Gate

Task-039b changes the visible watchOS live session face by adding a disabled/provider-aware quick-start placeholder shell. Manual QA is required before commit/push.

Manual QA status:

```text
MANUAL_QA_TASK039B_QUICK_START=PENDING_OPERATOR_CONFIRMATION
```

Required checklist:

- 在 watchOS simulator 開啟 live session face。
- 確認新增的 Quick Start / 快速開始 shell 卡片位置合理，沒有擠壓或遮住 speed、session status、complication shell、Health Reminder shell、Fall Safety shell、metric carousel 或 live controls。
- 確認卡片呈現 provider unavailable 或 iPhone authority 狀態，不宣稱 Watch 可以直接開始 session。
- 確認 last mode / outdoor / ready check 都只是 placeholder option，沒有送出開始紀錄、prepare session、StoreKit、HealthKit、Snow、route/speed/elevation 或 package/schema 行為。
- 檢查 English、Traditional Chinese、Japanese 文案沒有缺 key、重疊或過長遮擋。
- 使用 VoiceOver / Accessibility Inspector spot check，確認 accessibility label 也只描述 placeholder shell 與 iPhone start authority。
- 確認既有 complication shell、health reminder shell、fall safety shell、metric carousel 與 live controls 行為沒有改變。
- 完成後回報 MANUAL_QA_TASK039B_QUICK_START=PASSED 或明確列出失敗項目。

Task-039b manual QA token: quick-start shell pending, iPhone authority preserved, provider-aware disabled, no Watch direct session start.
<!-- TASK039B_QUICK_START_MANUAL_QA_END -->

<!-- TASK040A_SIMULATOR_QA_MATRIX_START -->
## Task-040a Phase 1b Simulator QA Matrix

Task-040a is a docs/verifier-only closure matrix for Phase 1b. It does not change UI, navigation, runtime behavior, localization files loaded by the app, schema, package format, Xcode project membership, StoreKit, HealthKit, WidgetKit, ClockKit, Snow, route geometry, trusted metrics, or Watch direct session start. Manual QA for this documentation change is not required, but the matrix records which product checks are simulator-verifiable, local Mac-verifiable, or real paired iPhone/Watch required.

Manual QA status for this change:

```text
MANUAL_QA_TASK040A_SIMULATOR_QA_MATRIX=NOT_REQUIRED_DOCS_VERIFIER_ONLY
```

| BuildPlan QA item | Classification | Evidence source / status |
|---|---|---|
| iPhone session start/pause/resume/stop | simulator-verifiable | Covered by existing session-flow and iOS smoke verifier family; Task-040a records the smoke item as `IOS_SMOKE_QA=PASSED` without changing session runtime. |
| Watch connection states | simulator-verifiable | Covered by WatchBridge connection-state mocks and Watch UI fallback verifier family; no production WatchConnectivity behavior is added. |
| Watch mirrored controls | simulator-verifiable | Covered by Watch core UI and mirrored-control verifiers; iPhone authority remains preserved. |
| Watch sample unavailable/available states | simulator-verifiable | Covered by Watch sample compatibility, provider, metric carousel, and fallback-state verifiers. |
| Watch UI empty/stale/disconnected states | simulator-verifiable | Covered by `scripts/verify_task036_watch_core_ui.py` and fallback-state source checks. |
| Shared ActivityVisualization compact output sanity | simulator-verifiable | Covered by `scripts/verify_task031_prep_016_final_parity_gate.py` and ActivityVisualization parity verifier family. |
| iOS/macOS route/speed/elevation parity smoke | local Mac-verifiable | Covered by the ActivityVisualization parity gate and macOS viewer display-only route/speed/elevation verifier family. |
| macOS multi-package viewer smoke from Task-030e | local Mac-verifiable | Covered by `scripts/verify_task030e_macos_multi_package_viewer.py`; viewer remains read-only and in-memory. |
| Task-030d import smoke where package compatibility changed | simulator-verifiable | Covered by `scripts/verify_task030d_ios_multifile_import.py`; no new package compatibility change is made by Task-040a. |
| No estimated route unlock | simulator-verifiable | `estimatedRouteActive` and general-user estimated route display remain disabled; Task-040a adds no route display runtime. |
| No trusted metric mutation | simulator-verifiable | No route, speed, elevation, package, persistence, or trusted metric source path changes are allowed. |
| No package schema break | simulator-verifiable | Task-040a makes no schema/package/runtime changes and relies on existing package compatibility verifiers. |
| Three-language localization parity | simulator-verifiable | Covered by `scripts/verify_localization_keys.py`; no localization runtime file changes are made. |
| Real paired iPhone/Watch end-to-end behavior | real paired iPhone/Watch required | Documented as a Phase 2 / post-ADP limitation; simulator-only Pre-ADP QA is accepted for Task-040a closure. |

Task-040a closure markers:

```text
VERIFY_TASK040A_QA_MATRIX_RESULT=PASSED
IOS_SMOKE_QA=PASSED
WATCH_SMOKE_QA=PASSED
MACOS_VIEWER_SMOKE_QA=PASSED
SHARED_ACTIVITYVIZ_PARITY_QA=PASSED
REAL_PAIRED_DEVICE_QA_ITEMS_DOCUMENTED=YES
SIMULATOR_ONLY_PRE_ADP_QA_ACCEPTED=YES
PHASE2_REAL_DEVICE_QA_LIMITATION_DOCUMENTED=YES
FAILURE_COUNT=0
```

Task-040a manual QA token: simulator QA matrix documented, real paired iPhone/Watch required, Phase 2 / post-ADP limitation, no estimated route unlock, no trusted metric mutation, no package schema break.
<!-- TASK040A_SIMULATOR_QA_MATRIX_END -->
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

## Snow-Task-010 Phase 1c Final Manual QA Gate

本區是 Snow Mode Phase 1c 完成前的最終人工檢查清單。這不是新功能測試，而是確認 001～009 的成果可以交給 Claude / human reviewer 做 feature-branch review。

### Final branch readiness

- [ ] 確認目前分支是 `feature/snow-mode`。
- [ ] 確認 Snow-Task-009 commit 已存在：`0d4f3a8 Add Snow QA fixtures and regression matrix`。
- [ ] 確認 `python3 scripts/verify_snow_phase1c_completion.py` PASS。
- [ ] 確認 Snow-Task-001～009 cumulative verify scripts 全部 PASS。
- [ ] 確認 `SnowTask010_ReviewPack.zip` 產生於 `/Users/doggo/Documents/App軟體區/upload/`。

### Runtime scope guardrails

- [ ] 確認 010 沒有新增 runtime Snow feature behavior。
- [ ] 確認 package schema 仍為 v2，且支援 schema 1 / 2 decode。
- [ ] 確認 backup schema 仍為 v2，且支援 schema 1 / 2 decode。
- [ ] 確認沒有新增 `.skatetrack` binary fixture。
- [ ] 確認沒有 `SnowPrototype*` 或 `MacSnowPrototype*` production/test Swift symbol。

### Deferred production integrations

- [ ] 確認 WatchBridge / WatchConnectivity production Snow wiring 仍標記 deferred。
- [ ] 確認 HealthKit production export 仍標記 deferred。
- [ ] 確認 Snow-Task-006b 仍標記為 mainline Task-040+ 後再處理。
- [ ] 確認 Snow Mode 尚未被宣告為 App Store production release-ready。

### Build and test smoke

- [ ] `SnowQAFixtureRegressionTests` 在 iPhone 17 Pro simulator 上 PASS。
- [ ] `SkateTrackPackageSnowCompatibilityTests` 在 iPhone 17 Pro simulator 上 PASS。
- [ ] macOS build PASS。
- [ ] iOS build PASS。
- [ ] watchOS build PASS。

Snow-Task-010 verification token: final manual QA gate exists for Phase 1c handoff.

## Snow-Integration-A005 Historical Manual QA Boundary

At the A005 checkpoint, manual QA and A006 through A009 were pending. That historical state was superseded by A006R1, A007, A008R1/A008R2R1, and the completed A009/A009R1 documentation closure. Commit/push and final merge remain pending.

## 12. Snow-Integration-A008 Reviewed Manual QA Closure

The operator completed the reviewed A008R2R1 matrix. No new manual QA is required for A009 or A009R1 because A009 changed documentation only and A009R1 changes only verifier/documentation state without user-visible product behavior.

| QA item | Reviewed result | Accepted evidence boundary |
|---|---|---|
| QA-01 | PASS | iPhone Snow DEBUG gate hides/shows correctly; non-Snow navigation remains normal. |
| QA-02 | PASS | Waiting, Downhill, Lift/Gondola, and Low Confidence deterministic HUD scenarios display and switch correctly; lift distance is excluded from ski distance. |
| QA-03 | PASS | Snow summary, run/segment selection, inspector updates, session switching, and empty state work without stale selection or crash. |
| QA-04 | PASS | Snow and non-Snow package round trips were visually confirmed; numeric values were not separately retained. |
| QA-05 | PASS | Normal `SkateTrack-watchOS` scheme launches the Task-040 mainline root without the Snow scenario selector. |
| QA-06 | PASS | Local ignored `SkateTrack-watchOS-SnowQA` scheme launches the DEBUG Snow mock gallery; returning to the normal scheme restores the Task-040 root. |
| QA-07 | DOCUMENTED_LIMITATION_SIMULATOR_ONLY_NO_PAIRED_WATCH_DESTINATION | No paired destination was available. Automated runtime/adapter tests and separate simulator launches passed; a real paired round trip is not claimed. |
| QA-08 | PASS | macOS Snow Analysis Preview and Session Browser open Snow packages read-only. |
| QA-09 | PASS | Backup v1, v2 Snow, and v2 empty preview/decode work; no restore, HealthKit permission, or production write occurred. |
| QA-10 | PASS | Representative en, zh-Hant, and ja Snow screens showed no raw keys or material clipping/layout issue. |
| QA-11 | PASS | Representative skateboard/inline session behavior remained normal without Snow classification or HUD contamination. |
| QA-12 | PASS | No medical monitoring/diagnosis, automatic emergency service, rescue guarantee, or resort/professional-grade accuracy claim appeared. |

The operator explicitly waived retained screenshots after completing the required interactive and visual checks. This waiver must not be rewritten as screenshot evidence being present, and no screenshot path, filename, hash, or manifest entry is claimed.

```text
QA-01=PASS
QA-02=PASS
QA-03=PASS
QA-04=PASS
QA-05=PASS
QA-06=PASS
QA-07=DOCUMENTED_LIMITATION_SIMULATOR_ONLY_NO_PAIRED_WATCH_DESTINATION
QA-08=PASS
QA-09=PASS
QA-10=PASS
QA-11=PASS
QA-12=PASS
MANUAL_QA_SNOW_INTEGRATION=PASSED
SCREENSHOT_EVIDENCE_PROVIDED=NO
SCREENSHOT_EVIDENCE_WAIVED_BY_OPERATOR=YES
OPERATOR_VISUAL_CONFIRMATION=YES
A009_MANUAL_QA_REQUIRED=NO
A009_MANUAL_QA_SKIP_REASON=DOCUMENTATION_ONLY_NO_PRODUCT_BEHAVIOR_CHANGE
SNOW_INT_A009_RESULT=PASSED
SNOW_INT_A009R1_RESULT=PASSED_REMEDIATION
A009R1_MANUAL_QA_REQUIRED=NO
A009R1_MANUAL_QA_SKIP_REASON=VERIFIER_AND_DOCUMENTATION_ONLY_NO_USER_VISIBLE_BEHAVIOR_CHANGE
```

## 13. Snow-Integration-A010R5 focused no-altitude route QA

Use a fresh iOS simulator Snow recording that follows the same approximately 59-second no-altitude path. Hash all shared schemes before and after QA; never add `-SnowMockGallery` to the shared watchOS scheme. Retain the four exact screenshots listed below.

The pre-QA automated gate is green: all 11 current verifiers, iOS/watchOS/macOS no-signing builds, localization/format locks, and 309/309 complete iOS tests passed with zero failures or skips.

| QA ID | Operator action | Required result |
|---|---|---|
| QA-R5-01 | End the fresh no-altitude Snow recording and open the normal session summary. | Summary distance is nonzero. |
| QA-R5-02 | Open Snow Distance Inspector for the same session. | Route distance is nonzero. |
| QA-R5-03 | Compare the two route values. | Summary and Inspector match when rounded to 0.01 km. |
| QA-R5-04 | Inspect ski distance. | Ski distance remains 0 because classification is unknown. |
| QA-R5-05 | Inspect lift distance. | Lift distance remains 0 because no lift exists. |
| QA-R5-06 | Inspect summary/package speed values. | No 43 km/h HUD fixture value is persisted as trusted speed. |
| QA-R5-07 | Export, import, and reopen the Snow package. | Route/unknown distance survives under existing schema 2. |
| QA-R5-08 | Review import/export feedback. | No schema or compatibility warning appears. |
| QA-R5-09 | Record a short skateboard or inline session. | Existing non-Snow GPS behavior remains unchanged. |
| QA-R5-10 | Compare shared-scheme hashes. | All shared schemes are unchanged. |

Required screenshots:

```text
A010R5_QA_summary_nonzero_route.png
A010R5_QA_distance_inspector_nonzero_route.png
A010R5_QA_package_roundtrip.png
A010R5_QA_non_snow_gps.png
```

```text
MANUAL_QA_A010R5_FOCUSED=PENDING
A010R5_AUTOMATED_GATES=PASSED
IOS_XCTEST_TOTAL_COUNT=309
SUMMARY_AND_INSPECTOR_ROUTE_ROUNDED_001KM_MATCH=PENDING
UNKNOWN_DISTANCE_NONZERO_FOR_NO_ALTITUDE_ROUTE=PENDING
SKI_DISTANCE_REMAINS_ZERO_FOR_UNKNOWN=PENDING
PACKAGE_ROUNDTRIP_PRESERVES_FALLBACK=PENDING
NON_SNOW_SESSION_GPS_BEHAVIOR_UNCHANGED=PENDING
```

## 14. Snow-Integration-A010R5R2 focused presentation/localization QA

Use a fresh iOS simulator session; do not reuse A010R5 screenshots. Record a new approximately 60-second no-altitude Snow session, end it, and inspect the same session in the general Summary, unknown Timeline row, and Distance Inspector. Localization changes must not be written into shared schemes.

The pre-QA automated gate is green: 12/12 CURRENT_REQUIRED verifiers, focused 11/11 tests, affected 35/35 regressions, iOS/watchOS/macOS no-signing builds, and 314/314 complete iOS tests passed with zero failures or unexpected skips.

| QA ID | Operator action | Required result |
|---|---|---|
| QA-R2-01 | Compare the visible route string in Summary, unknown Timeline row, and Inspector route. | All three localized strings are identical (for example `0.6 km`); never `0.6 km` versus `1 km`. |
| QA-R2-02 | Inspect Distance Inspector breakdown. | Route and unknown distances are positive; ski and lift distances remain zero. |
| QA-R2-03 | Use zh-Hant and inspect the classified Snow card. | Title is `滑降資訊`; unknown-only heading/detail appear; four classified zero metric tiles do not appear; full route remains accessible. |
| QA-R2-04 | Switch to English without shared-scheme arguments. | Title is `Downhill information`, heading is `No classified downhill data yet`, with no raw key or clipping. |
| QA-R2-05 | Switch to Japanese without shared-scheme arguments. | Title is `滑降情報`, heading is `分類済みの滑降データはまだありません`, with no raw key or clipping. |
| QA-R2-06 | Select the unknown Timeline segment. | Inspector updates and retains the same route/unknown mapping. |
| QA-R2-07 | Optionally switch Debug HUD scenarios. | No transition persistence was added; Timeline remains live-classifier/persisted-data-backed. |
| QA-R2-08 | Recompute shared-scheme hashes. | No `-SnowMockGallery`, localization argument, or other shared-scheme mutation exists. |

Required screenshots:

```text
A010R5R2_QA_zhHant_summary_timeline_inspector_match.png
A010R5R2_QA_zhHant_downhill_info_unknown_status.png
A010R5R2_QA_en_downhill_info_unknown_status.png
A010R5R2_QA_ja_downhill_info_unknown_status.png
```

```text
MANUAL_QA_A010R5R2_FOCUSED=PASSED
A010R5R2_AUTOMATED_GATES=PASSED
IOS_XCTEST_TOTAL_COUNT=314
SUMMARY_TIMELINE_INSPECTOR_VISIBLE_DISTANCE_STRING_MATCH=YES
ZH_HANT_DOWNHILL_INFORMATION_COPY=PASSED
EN_DOWNHILL_INFORMATION_COPY=PASSED
JA_DOWNHILL_INFORMATION_COPY=PASSED
UNKNOWN_ONLY_STATUS_CARD=PASSED
SKI_DISTANCE_REMAINS_ZERO_FOR_UNKNOWN=YES
LIFT_DISTANCE_REMAINS_ZERO_FOR_UNKNOWN=YES
A010R5R3_STARTED=NO
A010R5R4_STARTED=NO
```

## 15. Snow-Integration-A010R5R2R2 current closure (2026-07-19)

The final A010R5R2 evidence records QA-R2-01 through QA-R2-08 as passed, ten readable screenshots, exact `0.89 公里` Summary/Timeline/Inspector parity, zero ski/lift distance for unknown-only movement, exact three-language copy, and unchanged shared schemes. R2R2 reuses this approved evidence and does not repeat manual QA.

```text
A010R5_RESULT=BLOCKED_HISTORICAL
A010R5R1_RESULT=PASSED_HISTORICAL
A010R5R2R1_RESULT=BLOCKED_HISTORICAL
SNOW_INT_A010R5R2_RESULT=PASSED
MANUAL_QA_A010R5R2_FOCUSED=PASSED
A010R5R2_AUTOMATED_GATES=PASSED
CURRENT_REQUIRED_VERIFIERS=12_OF_12_PASSED
IOS_XCTEST_TOTAL_COUNT=314
SUMMARY_TIMELINE_INSPECTOR_VISIBLE_DISTANCE_STRING_MATCH=YES
ZH_HANT_DOWNHILL_INFORMATION_COPY=PASSED
EN_DOWNHILL_INFORMATION_COPY=PASSED
JA_DOWNHILL_INFORMATION_COPY=PASSED
UNKNOWN_ONLY_STATUS_CARD=PASSED
PACKAGE_SCHEMA_VERSION_CHANGED=NO
CORE_DATA_MODEL_CHANGED=NO
A010R5R3_STARTED=NO
A010R5R4_STARTED=NO
A010R6_STARTED=NO
A010R6_AUTHORIZED=NO_UNTIL_A010R5R2R2_INDEPENDENT_REVIEW
COMMIT_CREATED=NO
PUSH_CREATED=NO
MERGE_CONTINUE_PERFORMED=NO
```
