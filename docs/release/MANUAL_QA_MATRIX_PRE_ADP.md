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
