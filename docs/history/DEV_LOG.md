# SkateTrack Development Log

## Task-014 follow-up: Clean power type subtitle

- Removed the Phase 1a electric skateboard note from the Session Start power type card.
- The power type card now keeps the concise shared subtitle so human-powered and electric modes stay visually aligned.
- Removed the unused `power.electric.phase1a.note` localization key from English and Traditional Chinese strings.


This log is append-only. Do not delete or overwrite old entries.

## 2026-06-09 Phase 0 — Task-001 Project Scaffold Completed

### Completed
- Created the root Xcode workspace and Xcode project shell.
- Added iOS, watchOS, and macOS app entry points with empty SwiftUI shells.
- Created the DevProcess folder structure: `Shared/`, `iOS/`, `watchOS/`, `macOS/`, `Tests/`, `docs/`, and `tasks/`.
- Added `Shared/Constants/AppConstants.swift` for global deployment and naming constants.
- Added `.swiftlint.yml` with `file_length` warning at 450 lines and error at 500 lines.
- Added `README.md`, `.gitignore`, and this live documentation set.
- Initialized Git with an initial commit on `main` and created `develop` locally.

### Reason / Context
- Build Plan v1.0 defines Task-001 as the foundation for all later work.
- DevProcess v1.0 requires all files to follow the hybrid co-coding structure, 500-line limit, semantic naming, and live documentation protocol from the start.
- App entry points intentionally use `EmptyView()` so no feature or localization work leaks into Task-001.

### Known Issues / Follow-up
- GitHub remote still requires the real repository URL. Use `scripts/set_github_remote.sh` after creating the GitHub repository.
- SwiftLint SPM package is referenced in the Xcode project; Xcode may resolve packages on first open.
- Task-002 should add the actual localization resources and replace any future user-visible text with localization keys.

### 2026-06-09 — Task-001 hotfix

- Fixed malformed empty build setting in `SkateTrack.xcodeproj/project.pbxproj`.
- Changed `SWIFT_ACTIVE_COMPILATION_CONDITIONS = ;` to `SWIFT_ACTIVE_COMPILATION_CONDITIONS = "";` so Xcode can parse the project file.
- No product feature scope was added; this remains Task-001 scaffold only.

## 2026-06-09 Phase 0 — Task-002 Localization Infrastructure Completed

### Completed
- Added `Shared/Localization/en.lproj/Localizable.strings` as the English base localization file.
- Added `Shared/Localization/zh-Hant.lproj/Localizable.strings` as the Traditional Chinese localization file.
- Added matching key sets for app general strings, sport modes, subscription labels, and unit formatting support keys.
- Added `Shared/Utilities/UnitFormatter.swift` to centralize distance, temperature, and pace formatting.
- Added `Shared/Utilities/NumberFormatter+SkateTrack.swift` to centralize number formatting presets.
- Updated iOS, watchOS, and macOS app entry shells to display `app.name` and `app.tagline` through SwiftUI localization keys.
- Updated the Xcode project so localization resources and shared utility files are included in all three targets.
- Added `scripts/verify_localization_keys.py` for local localization key parity checks.
- Added the Task-002 prompt pack under `tasks/Task-002-Localization/`.
- Updated `docs/reference/FILE_STRUCTURE.md` for the new localization, utilities, script, and task files.

### Reason / Context
- Build Plan v1.0 defines Task-002 as the localization infrastructure task.
- DevProcess v1.0 Principle A requires all user-visible strings, units, and locale-specific values to pass through the localization and formatter layers.
- The localized placeholder shells exist only to verify Task-002 in the simulator; product features still begin in later tasks.

### Validation Notes
- Localization keys were checked with `python3 scripts/verify_localization_keys.py`.
- Swift source file line counts remain below the 500-line hard limit.
- Xcode simulator validation should focus on verifying the tagline changes between English and Traditional Chinese.

### Known Issues / Follow-up
- This task does not add real product screens, GPS, session recording, or data models.
- Task-003 should add shared data models without hardcoded user-visible strings.

## 2026-06-09 Phase 0 — Task-003 Shared Data Models Completed

### Completed
- Added `Shared/Models/SessionData.swift` as the root cross-platform session container.
- Added `Shared/Models/SportMode.swift` with `BoardMode`, `InlineMode`, and unified `SportMode` cases.
- Added `Shared/Models/PowerType.swift` with centralized validation that electric power only applies to skateboard modes.
- Added `Shared/Models/MotionSample.swift` with reusable `GeoCoordinate` and `ThreeAxisValue` value types.
- Added `Shared/Models/TrickEvent.swift` and `Shared/Models/FallEvent.swift` for session timeline events.
- Added `Shared/Models/EquipmentProfile.swift` and `Shared/Models/SpotProfile.swift` for gear and riding spot management foundations.
- Added `Shared/Protocols/SensorProvider.swift` and `Shared/Protocols/SyncProvider.swift` as cross-platform provider boundaries.
- Updated `SkateTrack.xcodeproj/project.pbxproj` so the new shared files are included in iOS, watchOS, and macOS targets.
- Added `scripts/verify_shared_models.py` for required-file, zone-header, line-count, and UI-import checks.
- Added the Task-003 prompt pack under `tasks/Task-003-SharedDataModels/`.
- Updated `docs/reference/FILE_STRUCTURE.md` for the new model, protocol, script, and task files.

### Reason / Context
- Build Plan v1.0 defines Task-003 as the shared data model foundation for later GPS, IMU, fall detection, sync, equipment, spot, and analytics tasks.
- DevProcess v1.0 §3.3 requires all shared models to live in `Shared/Models/` and conform to `Codable` and `Sendable`.
- The PRD requires skateboard, electric skateboard, and inline skating to share the same session-recording foundation while keeping mode-specific analysis possible.

### Validation Notes
- Required model/protocol files were checked with `python3 scripts/verify_shared_models.py`.
- `Shared/Models/*.swift` type-checks with Swift on the local generation environment.
- No `SwiftUI`, `UIKit`, `AppKit`, or `WatchKit` imports were added to `Shared/Models/` or `Shared/Protocols/`.
- Swift source file line counts remain below the 500-line hard limit.

### Known Issues / Follow-up
- This task defines data shapes and protocols only; it does not create persistence, GPS recording, sensor fusion, UI screens, or sync implementation.
- Actual JSON round-trip tests should be added once real test targets are introduced.
- Task-004 should build feature gating on top of these shared types without duplicating sport-mode or power-type logic.

## 2026-06-09 Phase 0 — Task-004 Feature Flag System Completed

### Completed
- Added `Shared/Constants/FeatureFlags.swift` with all 10 Build Plan Phase 1a gated features.
- Added `FreeFeature` so free access checks always return `true` without subscription state.
- Added `iOS/Core/Subscription/FeatureFlagEngine.swift` as the single source of truth for feature access.
- Stubbed subscription entitlement reading until Task-016 StoreKit integration.
- Added DEBUG-only subscription override support for simulator testing.
- Added `iOS/Hooks/useSubscriptionStatus.swift` as the SwiftUI-facing boundary adapter.
- Updated the iOS placeholder shell with a DEBUG-only subscription toggle.
- Added localized keys for debug subscription UI and gated feature display names.
- Added `scripts/verify_feature_flags.py` for Task-004 validation.
- Added the Task-004 prompt pack under `tasks/Task-004-FeatureFlags/`.

### Reason / Context
- Build Plan v1.0 requires feature gating before subscriber UI, paywall overlays, equipment manager, spot manager, Google Drive sync, advanced charts, or premium inline modes are built.
- DevProcess requires Views to call a clean hook boundary instead of hardcoding subscription logic.

### Validation Notes
- Run `python3 scripts/verify_feature_flags.py` to confirm all 10 gated features, zone headers, and debug override API exist.
- Run existing Task-002 and Task-003 scripts to confirm localization and shared models remain valid.
- iOS DEBUG simulator should show a small subscription toggle below the placeholder app title.

### Known Issues / Follow-up
- Real StoreKit entitlement reading remains intentionally stubbed until Task-016.
- This task does not add a paywall screen or lock-icon UI; future Views should call `hasAccess(to:)` through `useSubscriptionStatus`.

## 2026-06-09 Phase 0 — Foundation Complete (Tasks 001–005)

### Completed
- Xcode workspace with iOS, watchOS, and macOS targets.
- Localized app shell infrastructure for English and Traditional Chinese (`en` + `zh-Hant`).
- Shared data model foundation for sessions, sport modes, power types, motion samples, trick events, fall events, equipment, and spots.
- Shared provider protocols for future sensor and sync implementations.
- Feature flag system for the 10 Phase 1a gated features, including DEBUG subscription override support.
- Living documentation initialized with a full annotated `docs/reference/FILE_STRUCTURE.md` and this Phase 0 completion entry.

### Decisions Made
- Subscription model remains free download + $2.99/month subscription through StoreKit 2 in a later task.
- Free tier includes session recording, fall detection, sport mode selection, Urban/Freestyle inline mode, and limited recent history.
- Subscriber tier gates unlimited history, advanced charts, health reminders, equipment manager, spot management, Google Drive sync, premium inline modes, and session share cards.
- Locale strategy remains Traditional Chinese for `zh-Hant` / Taiwan users and English fallback for other locales.
- macOS remains a functional shell in Phase 1a and is intentionally deferred until Phase 2 feature work.
- SwiftLint configuration is retained in `.swiftlint.yml`, but the SwiftLint Xcode build plugin is not attached to targets to avoid blocking local Xcode builds.
- Current watchOS target is treated as a watch-only shell for scaffold validation; paired watch/iPhone connectivity is deferred to Phase 1b.

### Validation Notes
- Run `python3 scripts/verify_localization_keys.py` to verify localization key parity.
- Run `python3 scripts/verify_shared_models.py` to verify shared model presence, zone headers, line limits, and forbidden UI imports.
- Run `python3 scripts/verify_feature_flags.py` to verify all Phase 1a gated features and debug access paths.
- iOS, watchOS, and macOS still display placeholder localized shells; product UI begins in later tasks.

### Known Issues / Follow-up
- StoreKit integration is deferred to Task-016.
- GPS Provider begins in Task-006.
- Watch connectivity and companion flows remain deferred to Phase 1b.
- Real JSON round-trip tests should be added when formal test targets are populated.


## 2026-06-09 Phase 1a — Task-006 GPS Provider Completed

### Completed
- Added `iOS/Core/SensorEngine/GPSAuthorizationHandler.swift` to centralize CLLocation authorization requests and state checks.
- Added `iOS/Core/SensorEngine/GPSProvider.swift` to publish filtered `CLLocation` updates and km/h speed values through Combine.
- Implemented active-ride and stationary power-saving accuracy modes.
- Filtered invalid or low-quality location points where horizontal accuracy is unavailable or greater than 20 meters.
- Added location permission copy to `Localizable.strings` and localized `InfoPlist.strings` files for English and Traditional Chinese.
- Updated the iOS target generated Info.plist settings with When-In-Use and Always-and-When-In-Use location usage descriptions.
- Added `scripts/verify_gps_provider.py` and the Task-006 prompt pack.

### Reason / Context
- Build Plan v1.0 defines Task-006 as the first Sensor Engine task and requires a GPS provider before sensor fusion, fall detection, and session recording UI can be implemented.
- PRD v1.2 §5.1.1 identifies GPS as the source for route, speed, and elevation data.
- iOS UI Screen 03 will eventually consume speed and route data in the Live HUD mini-map and speed display.

### Validation Notes
- Run `python3 scripts/verify_gps_provider.py` to confirm the two provider files, permissions, localization hooks, and Xcode membership.
- Run existing Task-002 to Task-004 scripts to confirm localization, shared models, and feature flags remain valid.
- iOS should Build / Run. watchOS and macOS should still Build / Run unchanged because GPS files are iOS-only.
- In a simulator, GPS stream behavior can be validated after a future session-recording/debug UI starts the provider; this task intentionally adds provider infrastructure only.

### Known Issues / Follow-up
- This task does not start a real session, draw a route map, or display live speed UI.
- Background location mode is not enabled yet; `requestAlwaysAuthorization()` is available for later recording tasks but not exercised by the current shell UI.
- Task-007 will add the IMU provider. Task-009 will fuse GPS with motion data.


## 2026-06-09 Phase 1a — Task-007 + Task-008 Sensor Providers Completed

### Completed
- Added `iOS/Core/SensorEngine/IMUProvider.swift` to wrap `CMMotionManager` for accelerometer and gyroscope streams at 50Hz.
- Added raw `CMAccelerometerData` and `CMGyroData` Combine publishers for future sensor fusion.
- Added normalized `ThreeAxisValue` publishers so unavailable simulator sensors can stay stable at zero values without fabricating CoreMotion objects.
- Added `iOS/Core/SensorEngine/BarometerProvider.swift` to wrap `CMAltimeter` for relative altitude and pressure streams.
- Added unavailable-device guards for IMU and barometer behavior so simulators and unsupported devices do not crash.
- Added `scripts/verify_imu_provider.py` and `scripts/verify_barometer_provider.py`.
- Added Task-007 and Task-008 prompt packs.

### Reason / Context
- Build Plan v1.0 defines Tasks 007 and 008 as the next Sensor Engine providers after GPS.
- PRD v1.2 §5.1.1 identifies accelerometer, gyroscope, and barometer data as required inputs for motion tracking, elevation analysis, and fall detection.
- Task-009 will fuse GPS, IMU, and barometer data into a unified `MotionSample` stream.

### Validation Notes
- Run `python3 scripts/verify_imu_provider.py` to confirm 50Hz CoreMotion settings, publisher types, line limit, UI-import ban, and Xcode membership.
- Run `python3 scripts/verify_barometer_provider.py` to confirm CMAltimeter usage, unavailable-device guard, line limit, UI-import ban, and Xcode membership.
- Run existing Task-002 through Task-006 scripts to confirm localization, shared models, feature flags, and GPS provider remain valid.
- iOS should Build / Run. watchOS and macOS should still Build / Run unchanged because these new providers are iOS-only.

### Known Issues / Follow-up
- Raw CoreMotion object streams cannot emit fabricated `CMAccelerometerData`, `CMGyroData`, or `CMAltitudeData` objects on unsupported devices. Normalized helper streams expose safe zero / nil values for simulator stability.
- No UI starts these providers yet; Task-009 Sensor Fusion and later Session Recording tasks will consume them.

## 2026-06-09 Phase 1a — Task-009 + Task-010 Sensor Fusion and Fall Detection Completed

### Completed
- Added `iOS/Core/SensorEngine/SensorFusionEngine.swift` to merge GPS, IMU, and barometer provider streams into a unified 10Hz `MotionSample` publisher.
- Implemented `SensorProvider` conformance through `startRecording(mode:)` and `stopRecording()` while also exposing Build Plan method names `startSession(mode:)` and `stopSession()`.
- Added `iOS/Core/SensorEngine/SensorCalibrationEngine.swift` for startup bias calibration and sport-mode sensor priority planning.
- Added `iOS/Core/SensorEngine/FallDetectionEngine.swift` to monitor impact G-force, confirm post-impact stationary state, publish `FallEvent`, run a 15-second countdown, and publish SOS trigger events.
- Added DEBUG-sensitive fall-detection thresholds for simulator/development testing without touching production thresholds.
- Added `scripts/verify_sensor_fusion_engine.py` and `scripts/verify_fall_detection_engine.py`.
- Added Task-009 and Task-010 prompt packs.

### Reason / Context
- Build Plan v1.0 defines Task-009 as the core `MotionSample` fusion engine and Task-010 as the last Sensor Engine task before formal Session Recording UI work begins.
- PRD v1.2 §5.1 requires MotionSample data as the source for HUD metrics, summaries, route analysis, and fall detection.
- PRD v1.2 §5.2 requires fall detection from impact threshold plus post-impact inactivity and a user-cancellable SOS countdown.

### Validation Notes
- Run `python3 scripts/verify_sensor_fusion_engine.py` to confirm 10Hz publishing, provider integration, `SensorProvider` conformance, sport-mode priority planning, line limits, UI-import bans, and iOS target membership.
- Run `python3 scripts/verify_fall_detection_engine.py` to confirm 4g production threshold, DEBUG low threshold, 3-second stationary confirmation, 15-second countdown, `cancelFallAlert()`, `FallEvent` publishing, and iOS target membership.
- Run existing Task-002 through Task-008 scripts to confirm localization, shared models, feature flags, GPS, IMU, and barometer providers remain valid.
- iOS should Build / Run. watchOS and macOS should still Build / Run unchanged because these new engines are iOS-only.

### Known Issues / Follow-up
- No production UI starts the engines yet; Task-011 and later Session Recording tasks will connect UI flows to these providers.
- Simulator sensor behavior is limited. DEBUG fall thresholds exist for development validation, while real 4g behavior must be tested on hardware.
- SOS delivery is intentionally represented as a published event only; actual emergency-contact messaging and user-facing alert UI are later tasks.

## 2026-06-09 Phase 1a — Task-011 Session Recording Coordinator Completed

### Completed
- Added `iOS/Core/SessionRecording/SessionStateMachine.swift` with strict lifecycle transitions from idle through saving.
- Added `iOS/Core/SessionRecording/SessionMetricsAccumulator.swift` for live distance, speed, elevation, tilt, and moving-ratio accumulation.
- Added `iOS/Core/SessionRecording/SessionRecordingCoordinator.swift` as the sole session entry point wiring `SensorFusionEngine` and `FallDetectionEngine`.
- Added `iOS/Hooks/useSessionRecording.swift` exposing `SessionRecordingState`, `SessionRecordingActions`, and a DEBUG mock-data preview panel.
- Extended `Shared/Models/SessionData.swift` and added `SessionSummaryMetrics.swift` for completed-session summary output.
- Added `Tests/iOSTests/SessionRecordingCoordinatorTests.swift` with six unit tests and the `SkateTrack-iOSTests` target/scheme configuration.
- Added session localization keys, `scripts/verify_session_recording_coordinator.py`, and Task-011 prompt pack.

### Reason / Context
- Build Plan Task 011-020 pack defines Task-011 as the session lifecycle layer required before Session Start UI (Task-012) and Live HUD (Task-013).
- PRD v1.2 §5.1 and §5.5 require a managed recording lifecycle with live metrics and completed `SessionData` output.
- DevProcess principle B/C requires Views to use hooks instead of calling sensor engines directly.

### Validation Notes
- Run `python3 scripts/verify_session_recording_coordinator.py` to confirm coordinator files, localization keys, line limits, and Xcode membership.
- Run `xcodebuild test -scheme SkateTrack-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SkateTrack-iOSTests`.
- Run existing Task-002 through Task-010 scripts to confirm prior infrastructure remains valid.
- iOS should Build / Run. watchOS and macOS should still Build / Run unchanged.

### Known Issues / Follow-up
- No production Session Start or Live HUD screens yet; Task-012 and Task-013 will consume `useSessionRecording`.
- Fall alert UI and SOS dispatch remain deferred to Task-014.
- Session persistence is deferred to Task-015; completed `SessionData` is returned in memory only.


## 2026-06-09 Phase 1a — Task-012 Session Start Flow Completed

### Completed
- Added `iOS/App/RootNavigationView.swift` and replaced the placeholder iOS shell with the first real Session Start Flow.
- Added `SessionStartView`, category picker, skateboard mode selector, inline mode selector, power type toggle, reusable mode cards, and start CTA components.
- Connected the UI to `useSessionRecording` for start-session actions and to `useSubscriptionStatus` for inline subscription gates.
- Added all eight mode cards while keeping Inline Fitness / Speed, Aggressive, and Slalom locked for free users.
- Added Task-012 localization keys, `scripts/verify_session_start_flow.py`, and Task-012 prompt pack.

### Reason / Context
- Build Plan Task 012 requires iOS Screen 01, Screen 02, and Screen 12 to become the first visible user-facing UI after the sensor and session lifecycle foundation.
- Task-011 established `SessionRecordingCoordinator` and `useSessionRecording`; Task-012 is the first View layer consuming that boundary.
- Feature gates remain stub-compatible until Task-016 StoreKit and Paywall implementation.

### Validation Notes
- Run `python3 scripts/verify_session_start_flow.py` to confirm UI files, gated inline modes, localization keys, and iOS project membership.
- Run existing Task-002 through Task-011 scripts to confirm localization, shared models, feature flags, sensor providers, engines, and session lifecycle remain valid.
- iOS should Build / Run and show the Session Start UI. watchOS and macOS should still Build / Run unchanged.

### Known Issues / Follow-up
- Task-012 intentionally does not include Live HUD; after starting a session it only updates session state. Task-013 will add the in-session HUD.
- Paywall routing is a stub prompt until Task-016.
- Real sensor availability still depends on device capabilities; DEBUG uses the mock coordinator for simulator-friendly start flow testing.

## 2026-06-09 — Task-012 Hotfix: Align Session Start UI with iOS mockup

- Reworked the iOS Session Start Flow from a white system-card layout to the uploaded SkateTrack dark visual system.
- Replaced system backgrounds with navy / card / accent tokens matching the iOS UI v3 mockup.
- Kept Task-012 scope unchanged: sport category selection, mode selection, power type toggle, subscription gating, and start action only.
- Did not add pause, stop, swipe-to-end, Live HUD, Fall Alert, persistence, or history features; those remain scheduled for later tasks.
- Pinned the Start Session CTA to the bottom safe area so the entry action is discoverable without scrolling to the very bottom.

## 2026-06-10 Phase 1a — Task-013 Live HUD + Slide-to-End Completed

### Completed
- Added `LiveHUDView.swift` as the dark full-screen iOS riding HUD following iOS UI mockup Screen 03 / 03b.
- Added reusable HUD components: `LiveSpeedDisplayView`, `LiveHUDMetricCardView`, `TiltIndicatorView`, `MiniRouteMapView`, `SlideToEndSessionControl`, and `InlineLiveMetricsView`.
- Routed active session states from `RootNavigationView` to `LiveHUDView` while preserving Task-012 Session Start UI for idle / failed states.
- Extended `SessionRecordingState` with `recentRouteCoordinates` so the HUD can render recent route context without directly accessing sensor engines.
- Added localized HUD keys and `scripts/verify_live_hud.py`.

### Reason / Context
- Build Plan Task-013 requires iOS Screen 03 / 03b Live HUD, a dark outdoor-friendly riding interface, and a slide-to-end control to avoid accidental session termination.
- Task-011 already provides session lifecycle actions; Task-013 consumes those actions without directly stopping sensors.
- Task-014 will replace the SOS stub with Fall Alert / SOS flow.

### Validation Notes
- Run `python3 scripts/verify_live_hud.py` to confirm HUD files, localized keys, slide threshold, route state, and iOS project membership.
- Run existing Task-002 through Task-012 scripts to confirm prior functionality remains valid.
- iOS should Build / Run and switch from Session Start to Live HUD after pressing Start Session.
- watchOS and macOS should still Build / Run unchanged.

### Known Issues / Follow-up
- Heart-rate, trick count, inline cadence, and inline rhythm are placeholders until their dedicated engine / HealthKit tasks exist.
- SOS button is a stub until Task-014.
- Mini route is driven by recent coordinates collected in memory only; persistence and full route replay are later tasks.


## 2026-06-10 — Task-013 UI/Icon Hotfix

- Reworked iOS Session Start and Live HUD root layout to use the whole phone canvas instead of nested mid-screen cards.
- Replaced inline skating glyph usage with a custom lightweight inline-skate glyph so it no longer reads as a wheelchair.
- Added unified AppIcon asset catalogs for iOS, watchOS, and macOS from the provided SkateTrack icon artwork.

## 2026-06-10 — Task-013 Final UI/Icon Hotfix

- Rebuilt the iOS Session Start and Live HUD layouts as true edge-to-edge screens instead of nested mid-screen panels.
- Moved the primary Start Session and Live HUD controls into bottom safe-area docks so controls no longer sit at the old working-area lower edge.
- Reworked the Live HUD to remove the fixed-height map/HUD container that clipped the speed hero and lower controls.
- Refined the custom inline-skate glyph so the skater and wheels lean together and no longer resemble a wheelchair.
- Regenerated iOS, watchOS, and macOS app icon assets from the approved SkateTrack artwork and added a macOS `.icns` fallback.
- Updated generated Info.plist app icon keys so all three app targets explicitly point to `AppIcon`.

## 2026-06-10 — Task-013 Status Review / File Structure Documentation Update

### Reviewed Current State
- Inspected the repository from `SkateTrack_Current_For_UI_Diagnosis.zip` after Tasks 001–013 and the Task-013 UI/icon hotfix attempts.
- Confirmed the project contains iOS Session Start UI, iOS Live HUD UI, session recording coordinator, iOS tests, sensor providers, sensor fusion, fall detection foundation, localization, generated AppIcon assets, and macOS `.icns` fallback.
- Confirmed source-pattern verification scripts can pass for Session Start, Live HUD, localization, app icons, and session recording.

### Correction / Important Finding
- Passing verification scripts are not sufficient for Task-013 visual acceptance. Current screenshots show the iOS Session Start and Live HUD still do not meet the intended full-screen mockup alignment.
- Current screenshots also show the bottom Start / Slide-to-End controls can still be clipped.
- The custom inline-skating glyph regressed visually and should not be treated as accepted.
- AppIcon asset folders exist for iOS, watchOS, and macOS, but runtime app icon display is still unresolved on the user's machine.

### Documentation Change
- Rewrote `docs/reference/FILE_STRUCTURE.md` to reflect the current repository structure, current progress, and unresolved Task-013 blockers honestly.
- Reclassified Task-013 as functionally implemented but visually not accepted yet.
- Added an explicit gate: Task-014 should not begin until Task-013 visual layout, inline icon, and runtime AppIcon issues are resolved.

### Next Recommended Action
- Perform a focused Task-013 repair pass using the current full project source, not incremental speculative hotfixes.
- Strengthen the UI/icon verification scripts so they do not pass purely on source-pattern checks when visual acceptance is failing.


## 2026-06-10 — Task-014a Fall Alert Overlay + SOS Event Skeleton

### Completed
- Added `SOSTriggerEvent` as the shared SOS event model for manual HUD SOS, immediate fall SOS, and countdown-expired SOS paths.
- Added `SOSEventDispatcher` as the Phase 1a SOS abstraction layer. It records and publishes events without pretending iOS can silently auto-send SMS.
- Added `useFallDetection` to expose active fall alert state, countdown seconds, latest SOS event, cancel, immediate SOS, and manual SOS actions to SwiftUI.
- Added `FallDetectionAlertView` and `FallDetectionOverlayPresenter` for the high-priority dark SkateTrack fall alert overlay.
- Moved `LiveSpeedTraceView` out of `LiveHUDView` so the Live HUD remains below the 500-line file guideline while adding Task-014a overlay wiring.
- Wired Live HUD SOS button to the Task-014a manual SOS event path.
- Extended `SessionRecordingCoordinator` with fall countdown publishing and SOS event dispatch bridging.
- Added localized Fall Alert / SOS strings and `scripts/verify_fall_alert_ui.py`.

### Scope Boundary
- Emergency contact CRUD, contact settings UI, Contacts framework integration, and real message/phone handoff remain Task-014b.
- No Launch Screen, safe-area, bottom dock, AppIcon, watchOS UI, macOS UI, or SwiftLint plugin wiring was changed.

### Validation Notes
- Run `python3 scripts/verify_fall_alert_ui.py` to confirm Task-014a files, project membership, localization, and key source tokens.
- Run `python3 scripts/verify_fall_detection_engine.py`, `python3 scripts/verify_session_recording_coordinator.py`, `python3 scripts/verify_localization_keys.py`, and the AppIcon verification scripts to confirm previous task baselines.

### Task-014a Debug Verify
- Added a DEBUG-only Live HUD simulate fall trigger for safe Fall Alert overlay QA on simulator and physical iPhone.
- The trigger does not lower real FallDetectionEngine thresholds and is not visible in Release builds.



## 2026-06-11 — Task-014b Emergency Contacts Settings + SOS Contact Flow

### Completed
- Added `EmergencyContact` and `EmergencyContactRelationship` shared models for local SOS contact metadata.
- Added `EmergencyContactStore`, a Phase 1a local storage layer backed by `UserDefaults`.
- Added `EmergencyContactsSettingsView` so users can add, view, and delete emergency contacts without importing the system address book.
- Updated `SOSEventDispatcher` to read usable contacts from `EmergencyContactStore`, attach them to `SOSTriggerEvent`, and mark SOS events as `contactSetupRequired` when no contacts exist.
- Updated Fall Alert UI and Live HUD to expose contact readiness, open the contact settings sheet, and show visible SOS status feedback after manual / fall-triggered SOS.
- Added localization keys and `scripts/verify_emergency_contacts.py`.

### Validation Notes
- Run `python3 scripts/verify_emergency_contacts.py` in addition to the existing Task-014a and session/fall verification scripts.
- Manual Xcode validation should confirm the emergency contacts sheet opens from Live HUD, contact add/delete works, Fall Alert shows contact status, and SOS status feedback appears after SOS actions.

### Scope Boundary
- No Contacts framework permission, no real automatic SMS/iMessage dispatch, and no Task-015 persistence were added.


## 2026-06-11 — Task-014 Follow-up: Centralized Debug Tools + Real-Speed Runtime Default

### Completed
- Added a DEBUG-only `iOS/Features/Debug` module as the centralized entry for development tools.
- Moved Fall Alert simulation out of the Live HUD top bar into `DebugToolsPanelView`.
- Moved subscription override testing into the same Debug Tools panel instead of leaving it as a separate Start Session section.
- Changed the normal app runtime to use `useSessionRecording()` so real device Debug runs use live GPS / sensor data by default.
- Kept mock speed samples available only as an explicit Debug Tools Demo Speed Session option for UI demos and previews.
- Added `scripts/verify_debug_tools.py` to guard against reintroducing mock speed into the app entry point.

### Scope Boundary
- No GPSProvider or SensorFusionEngine algorithm changes were made.
- No Task-014b SOS / emergency contacts production flow changes were made.
- No Launch Screen, AppIcon, bottom dock, watchOS, macOS, or SwiftLint plugin changes were made.
## Task-014 follow-up: Portrait + Conservative Tilt/Fall Surfacing

- Locked iOS generated Info.plist orientation settings to portrait/full-screen for the current riding UI.
- Reframed the Live HUD tilt card as an uncalibrated phone-posture status instead of rendering raw phone angle as skateboard lean.
- Added a SessionRecordingCoordinator surfacing gate so automatic fall alerts require an armed session window and ride motion before showing the SOS overlay.



## 2026-06-11 — Task-015a Local Persistence Foundation

### Completed
- Added a Task-015a persistence foundation under `Shared/Persistence`.
- Added `PersistenceController` with a Core Data stack and Task-015a model entities for sessions, fall events, equipment, and spots.
- Added `SessionRepositoryProtocol` and `SessionRepository` for local completed-session save, recent fetch, single-session fetch, motion-sample load, delete, and export bundle operations.
- Added `SessionEntityMapper` so Core Data `NSManagedObject` values do not leak into UI, hooks, or session recording coordinator code.
- Added `MotionSampleFileStore` so high-frequency `MotionSample` arrays are stored as session files instead of being written row-by-row into Core Data.
- Added `FallEventRepository` as a narrow read boundary for session-linked fall events.
- Added iOS unit coverage in `SessionRepositoryTests` for save / fetch / load / export / delete using an isolated temporary store.
- Added `scripts/verify_session_repository.py` to guard Task-015a file presence, project membership, model fields, and repository APIs.

### Scope Boundary
- Session recording is not yet auto-saving through the repository. That integration remains Task-015b.
- No History UI, Summary UI, route map, equipment UI, spot UI, Google Drive sync, or CloudKit sync was added.
- No GPSProvider, IMUProvider, SensorFusionEngine, FallDetectionEngine, Debug Tools, SOS, Launch Screen, AppIcon, bottom dock, watchOS UI, or macOS UI changes were made.

### Validation Notes
- Run `python3 scripts/verify_session_repository.py` to verify Task-015a persistence source structure and Xcode project membership.
- Run the iOS unit-test target in Xcode to execute `SessionRepositoryTests`.
- Continue running existing session, localization, sensor, fall alert, and debug tools verification scripts after applying this task.

## 2026-06-11 — Task-015b Session Recording Persistence Integration

### Completed
- Connected `SessionRecordingCoordinator.requestEndSession()` to `SessionRepositoryProtocol.saveCompletedSession(_:)`.
- Completed sessions are now saved through the local repository before `completedSessionPublisher` emits.
- Added repository error surfacing so local save failures publish localized repository error keys instead of crashing or being mislabeled as state-transition errors.
- Confirmed `discardCurrentSession()` does not save discarded sessions.
- Moved DEBUG-only mock speed feed helpers into `SessionRecordingCoordinator+DebugMock.swift` to keep the core coordinator under the file-size guideline while preserving Demo Speed Session behavior.
- Added iOS unit coverage for save-before-publish, discard-without-save, and persistence failure behavior.
- Added `scripts/verify_session_persistence_integration.py` for Task-015b source-structure and integration checks.

### Scope Boundary
- No History UI, Session Summary UI, map UI, equipment mileage, spot management, Google Drive sync, or CloudKit sync was added.
- No GPSProvider, IMUProvider, SensorFusionEngine, FallDetectionEngine algorithm, Debug Tools UI, SOS / Emergency Contacts, Launch Screen, AppIcon, bottom dock, watchOS UI, or macOS UI changes were made.

### Validation Notes
- Run `python3 scripts/verify_session_persistence_integration.py` with the existing repository, session coordinator, localization, sensor, debug tools, fall alert, and emergency contacts verification scripts.
- Run the iOS unit-test target in Xcode to execute the expanded `SessionRecordingCoordinatorTests` and existing `SessionRepositoryTests`.


## 2026-06-11 — Task-015 Documentation Refresh

### Completed
- Updated the living file-structure documentation after Task-015b was validated in Xcode.
- Marked Task-015b Session Recording Persistence Integration as complete rather than hotfix-pending.
- Refreshed the repository inventory, validation command list, current known follow-ups, and next-step guidance to match the persistence-enabled baseline.
- Confirmed Task-015a / Task-015b documentation now records both the local persistence foundation and session-end auto-save integration.

### Scope Boundary
- No product source, persistence logic, session recording behavior, UI, sensor, safety, icon, watchOS, or macOS code was changed by this documentation refresh.
- This entry only documents the already-tested Task-015b state before committing the documentation update.


## 2026-06-11 — Task-016a Subscription Entitlement Simulation Architecture

### Completed
- Added ADR-0001 to document the subscription entitlement strategy before real Apple Developer Program / App Store Connect setup exists.
- Split Task-016 into a safer entitlement architecture phase first, rather than implementing production StoreKit monetization immediately.
- Added a replaceable `SubscriptionEntitlementProviding` boundary, local/free simulation provider, DEBUG-only entitlement override provider, and `SubscriptionEntitlementStore`.
- Moved subscription state into reusable entitlement snapshots so `FeatureFlagEngine` can consume local simulation now and a future `AppStoreSubscriptionProvider` later.
- Added `PurchaseProductCatalog` to centralize future StoreKit product IDs and avoid scattering identifiers through Views.
- Updated `useSubscriptionStatus` so SwiftUI can observe entitlement state, entitlement source, and status message keys without directly reading DEBUG flags.
- Updated DEBUG subscription tooling copy to show whether access comes from local simulation or DEBUG override.
- Added `scripts/verify_subscription_entitlement_simulation.py` to guard Task-016a file presence, Xcode membership, localization keys, debug boundaries, product ID centralization, and documentation requirements.
- Updated `scripts/verify_debug_tools.py` so it recognizes the existing `SessionRecordingCoordinator+DebugMock.swift` split instead of expecting DEBUG mock helpers only inside the core coordinator file.

### Decision / Context
- The project does not currently have an Apple Developer Program account, so Task-016a intentionally does not implement production App Store Connect products or real StoreKit purchase flow.
- Current development should use DEBUG/local simulation only through the entitlement provider boundary.
- Future monetization should add an `AppStoreSubscriptionProvider` behind the same provider boundary instead of rewriting Paywall UI, locked-feature UI, or `FeatureFlagEngine` access rules.

### Scope Boundary
- No real App Store Connect subscription setup, sandbox tester workflow, production purchase, receipt/transaction validation, Paywall UI, History UI, unlimited-history enforcement, charts, equipment, spot, sync, GPS, IMU, Sensor Fusion, Fall Detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS changes were added.

### Validation Notes
- Run `python3 scripts/verify_subscription_entitlement_simulation.py` together with existing localization, feature flag, debug tools, and persistence verification scripts.
- Xcode should still Build / Test the existing iOS target and iOS unit tests after applying this task.

## 2026-06-11 — Task-016a Compile Fix: Subscription source membership

### Completed
- Fixed the Xcode project source membership for the Task-016a subscription entitlement Swift files.
- Added the missing `PBXFileReference` records for the new subscription files so `FeatureFlagEngine.swift` can resolve `SubscriptionEntitlementSnapshot`, `SubscriptionEntitlementStore`, and DEBUG entitlement provider types during iOS builds.
- Strengthened `scripts/verify_subscription_entitlement_simulation.py` so future verification checks `PBXFileReference`, `PBXBuildFile`, `PBXSourcesBuildPhase`, and dangling `fileRef` consistency instead of only matching filenames.

### Scope Boundary
- No subscription business logic, Paywall UI, StoreKit purchase flow, sensor engine, persistence logic, Launch Screen, AppIcon, watchOS, or macOS behavior was changed.


## 2026-06-11 — Task-016b Paywall UI + Locked Feature Flow

### Completed
- Added the first SkateTrack Pro Paywall UI under `iOS/Features/Subscription` using the existing dark / neon outdoor-readable visual language.
- Added reusable subscription UI components: `SubscriptionPaywallView`, `SubscriberBenefitsListView`, `RestorePurchaseButton`, and `LockedFeatureOverlayView`.
- Connected locked Inline Fitness / Speed, Aggressive, and Slalom mode taps to open the Paywall instead of only showing an inline upgrade prompt.
- Updated the locked bottom CTA path so trying to start a locked inline mode opens the Paywall.
- Kept all entitlement changes routed through `useSubscriptionStatus` and `FeatureFlagEngine`; Views still do not hardcode subscriber state.
- Added DEBUG-only Paywall simulation controls for success, cancelled, and failed purchase states. Success grants subscriber access through the existing DEBUG entitlement override path.
- Added restore-purchase UI that refreshes the local entitlement snapshot only; real `AppStore.sync()` remains deferred to the future StoreKit task.
- Added subscription Paywall localization keys and `scripts/verify_subscription_paywall.py`.

### Decision / Context
- Task-016b intentionally does not process real payments because the project does not currently have an Apple Developer Program / App Store Connect subscription setup.
- Paywall UI is now reusable and should be wired to a future `AppStoreSubscriptionProvider` / StoreKit 2 purchase implementation in Task-016c rather than rewritten.
- The Paywall can be validated now through DEBUG/local entitlement simulation while keeping production monetization clearly deferred.

### Scope Boundary
- No real StoreKit 2 purchase, App Store Connect product, sandbox tester flow, transaction validation, receipt validation, History UI, unlimited-history enforcement, charts, equipment, spot management, sync, GPS, IMU, Sensor Fusion, Fall Detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_subscription_paywall.py` with the existing subscription entitlement, localization, feature flag, debug tools, persistence, and session-start verification scripts.
- Manual validation should confirm locked inline modes open the Paywall, DEBUG success unlocks premium inline modes, DEBUG cancelled / failed states do not grant access, restore refreshes local entitlement only, and normal Session Start / Live HUD flows remain unchanged.

## 2026-06-11 — Task-017a Session History Foundation + Free Limit

### Completed
- Added the first iOS Session History screen with local repository loading, loading / empty / error / content states, pull-to-refresh, sport filters, month grouping, weekly distance summary, and saved-session cards.
- Added `useSessionHistory` as the SwiftUI-facing boundary for Task-015 `SessionRepositoryProtocol`, including free-plan gating calculations and subscriber-aware grouping.
- Connected a lightweight Ride / History root switch in `RootNavigationView` without replacing the existing Session Start / Live HUD flow or adding a full tab system.
- Implemented the free 5-session History limit: free users can access the latest five sessions, older cards render as locked Pro history and open the Task-016b Paywall.
- Kept unlimited-history access behind `GatedFeature.unlimitedHistory`, `useSubscriptionStatus`, and the existing Task-016 entitlement provider architecture.
- Added a Task-018 placeholder sheet for accessible session taps so History can confirm session selection without implementing Summary, route map, or charts in Task-017a.
- Added `scripts/verify_session_history.py` to guard History file presence, Xcode project membership, localization keys, free-limit tokens, Paywall routing, and documentation updates.
- Expanded ADR-0001 so all future paid-feature tasks continue using DEBUG/local entitlement simulation until real App Store Connect monetization is intentionally implemented.

### Scope Boundary
- No real StoreKit purchase, App Store Connect product setup, sandbox tester flow, `AppStore.sync()`, transaction validation, production subscription claim, Session Summary, route map, charts, swipe delete, calendar view, export, GPS, IMU, Sensor Fusion, Fall Detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_session_history.py` together with localization, subscription entitlement simulation, subscription Paywall, feature flag, debug tools, and persistence verification scripts.
- Xcode should Build / Run / Test the iOS target after applying this task. Manual validation should confirm free users see older sessions locked and DEBUG subscriber simulation unlocks the full History list.



## 2026-06-11 — Task-017a UI Alignment Hotfix

### Completed
- Moved the Ride / History switch out of the Ride screen global overlay path so it no longer overlaps the Session Start header.
- Kept the History screen switch in the lightweight top overlay but reduced the header top spacing so the switch and title feel visually connected.

### Scope Boundary
- No History repository logic, free-limit gating, Paywall behavior, subscription entitlement behavior, session recording, Live HUD, sensor, Launch Screen, AppIcon, watchOS, or macOS code was changed.


## 2026-06-11 — Task-017a UI Alignment Follow-up 2

### Completed
- Fine-tuned the Task-017a root Ride / History switch placement after simulator review.
- Moved the History switch and debug control slightly upward to reduce excess top spacing.
- Lowered the Ride page header so the SkateTrack title no longer visually collides with the Dynamic Island.

### Scope Boundary
- No History repository, free-limit gating, Paywall, subscription entitlement, Session Start behavior, Live HUD, project membership, watchOS, macOS, Launch Screen, AppIcon, or bottom dock logic was changed.


## 2026-06-11 — Task-017a UI Alignment Follow-up: History top spacing

### Completed
- Tightened the History screen top rhythm by moving the Ride / History switch and DEBUG tools button upward together.
- Pulled the History header content upward to preserve the spacing relationship after the top controls were raised.

### Scope Boundary
- No Ride screen spacing, History data loading, free-limit gating, Paywall behavior, subscription entitlement logic, project settings, sensor engines, or persistence behavior was changed.


## 2026-06-11 — Task-017b History Navigation + Summary Handoff

### Completed
- Extracted the History selected-session placeholder into `SessionSummaryHandoffView` so Task-018 can replace one dedicated handoff screen with the real Summary UI.
- Kept unlocked History card taps routed to the Summary handoff and locked old-session taps routed to the Task-016b Paywall.
- Added a compact session identity and metric preview to the handoff screen without implementing route maps, charts, export, or detailed analytics.
- Updated History localization keys and `scripts/verify_session_history.py` so the verification script covers the Task-017b handoff file, project membership, and localization.
- Preserved the project-wide paid-feature rule from ADR-0001: free-limit and Paywall behavior still consume `useSubscriptionStatus` / `FeatureFlagEngine` and DEBUG/local entitlement simulation only.

### Scope Boundary
- No real StoreKit purchase, App Store Connect setup, sandbox tester flow, `AppStore.sync()`, transaction validation, production subscription claim, real Session Summary, route map, charts, export, delete, calendar view, GPS, IMU, Sensor Fusion, Fall Detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_session_history.py` together with localization, subscription Paywall, entitlement simulation, feature flag, debug tools, and persistence verification scripts.
- Manual validation should confirm unlocked History cards open the Summary handoff, locked cards still open Paywall, and DEBUG subscriber simulation still unlocks full History.


## 2026-06-11 — Task-018a Session Summary Foundation + Core Metrics

### Completed
- Replaced the Task-017b Summary handoff sheet with the first real `SessionSummaryView` foundation.
- Added `useSessionSummary` as the SwiftUI-facing boundary for loading a selected session through `SessionRepositoryProtocol` without exposing Core Data to Views.
- Added `SessionSummaryMetricsGridView` for core local metrics: distance, duration, max speed, average speed, elevation gain, moving ratio, falls, and tricks.
- Added `SessionSummaryPlaceholderSectionView` for route, chart, and health/calorie placeholders so Task-018b / Task-018c can extend the screen without rewriting History routing.
- Kept History unlocked-card taps routed into the new Summary foundation and locked old-session taps routed to the existing Paywall.
- Added `scripts/verify_session_summary.py` and updated History verification to recognize the real Summary handoff target.
- Updated localization and living documentation for the Task-018a Summary foundation.

### Paid Feature / Monetization Boundary
- Task-018a does not add paid chart gating yet. Future advanced charts in Task-018c must continue the project-wide Task-016 entitlement-provider strategy: `FeatureFlagEngine` / `useSubscriptionStatus`, DEBUG/local simulation during development, and future `AppStoreSubscriptionProvider` for production monetization.

### Scope Boundary
- No MapKit route map, Swift Charts, advanced chart gating, real StoreKit purchase, App Store Connect setup, sandbox tester flow, `AppStore.sync()`, transaction validation, production subscription claim, export, delete, calendar view, GPS, IMU, Sensor Fusion, Fall Detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_session_summary.py` together with session history, localization, subscription Paywall, entitlement simulation, feature flag, debug tools, and persistence verification scripts.
- Manual validation should confirm unlocked History cards open the real Summary foundation, locked cards still open Paywall, and Summary shows only core metrics plus route/chart/health placeholders.

## 2026-06-11 — Task-018b Route Map + Safety / Share Stub

### Completed
- Added `SessionRouteMapView` with a MapKit route preview, local GPS polyline rendering, and start / finish annotations when at least two valid GPS samples exist.
- Preserved a graceful no-route state for sessions without enough valid GPS coordinates.
- Added `SessionSummarySafetyStatusView` to summarize local fall-event count, peak impact, and user-confirmed fall count without changing the fall-detection engine.
- Added `SessionSummaryShareStubView` as a visible Summary share entry point while keeping real share-card generation, image export, and system share-sheet flow deferred.
- Updated `SessionSummaryView` so the Task-018a route placeholder is replaced by the Task-018b route map / empty route state, while advanced charts and health data remain placeholders.
- Updated Session Summary localization keys and `scripts/verify_session_summary.py` so verification now checks MapKit route rendering, safety recap, share stub, project membership, and documentation updates.
- Updated living documentation for the Task-018b Summary route-map phase.

### Paid Feature / Monetization Boundary
- Task-018b does not introduce subscriber-only advanced chart access or production monetization.
- Future Task-018c advanced charts must continue using the project-wide Task-016 entitlement-provider strategy: `FeatureFlagEngine` / `useSubscriptionStatus`, DEBUG/local entitlement simulation during development, and future `AppStoreSubscriptionProvider` only when production monetization is intentionally implemented.

### Scope Boundary
- No Swift Charts, advanced chart gating, real StoreKit purchase, App Store Connect setup, sandbox tester flow, `AppStore.sync()`, transaction validation, production subscription claim, real share-card export, delete, calendar view, GPS, IMU, Sensor Fusion, Fall Detection algorithm, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_session_summary.py` together with session history, localization, subscription Paywall, entitlement simulation, feature flag, debug tools, and persistence verification scripts.
- Manual validation should confirm unlocked History cards open Summary, route sessions show a route map with start / finish markers, no-route sessions show the empty route state, safety status reflects fall-event data, and the share button only shows the deferred share-card notice.


## 2026-06-11 — Task-018c Advanced Charts + Subscription Gating

### Completed
- Added subscriber-gated advanced chart rendering to the existing `SessionSummaryView` instead of creating a second Summary screen.
- Added `SessionAdvancedChartsView` to centralize Task-018c chart access, chart-point generation, and lightweight downsampling for large motion-sample sets.
- Added `SpeedTimelineChartView` and `ElevationProfileChartView` using Swift Charts for subscriber-visible speed and altitude analysis.
- Added `AdvancedChartsLockedView` so free users see a Pro preview and are routed to the existing Task-016b Paywall through `GatedFeature.advancedCharts`.
- Added `HeartRateZonePlaceholderView` to keep heart-rate zones visible as a future-ready placeholder without fabricating health data.
- Updated `SessionHistoryView` / `SessionSummaryView` handoff so Summary receives the existing `SubscriptionStatusViewModel` and does not create a separate paid-access path.
- Updated Summary localization keys and `scripts/verify_session_summary.py` so verification now covers Swift Charts, downsampling, paid gating, Paywall routing, project membership, localization, and documentation.
- Updated living documentation for the Task-018c advanced chart phase.

### Paid Feature / Monetization Boundary
- Task-018c implements subscriber-only advanced chart access but still does not implement production StoreKit purchase, App Store Connect products, sandbox tester flow, transaction validation, or `AppStore.sync()`.
- Advanced chart access is routed through `GatedFeature.advancedCharts`, `useSubscriptionStatus`, and the existing Task-016 entitlement provider architecture.
- DEBUG/local entitlement simulation remains the development path; production monetization remains deferred to a future `AppStoreSubscriptionProvider` task.

### Scope Boundary
- No real StoreKit purchase, App Store Connect setup, sandbox tester flow, `AppStore.sync()`, transaction validation, production subscription claim, real HealthKit / watchOS heart-rate data, real share-card export, delete, calendar view, GPS, IMU, Sensor Fusion, Fall Detection algorithm, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_session_summary.py` together with session history, localization, subscription Paywall, entitlement simulation, feature flag, debug tools, and persistence verification scripts.
- Manual validation should confirm free users see locked advanced chart previews that open the Paywall, DEBUG subscriber simulation unlocks speed and elevation charts, heart-rate zones remain a no-fake-data placeholder, and route/safety/share Summary sections still work.


## 2026-06-11 — Task-019a Health Reminder Rules + Settings Foundation

### Completed
- Added the Task-019a health reminder settings foundation without introducing live-session scheduling, system notifications, or real weather data.
- Added `HealthReminderRule` and `HealthReminderSettingsStore` under `iOS/Core/HealthReminders` to define hydration, rest, cooldown stretch, heat-risk, and UV-risk reminder preferences.
- Added `useHealthReminders` as the SwiftUI-facing boundary so Views do not directly manipulate reminder storage or subscription entitlement state.
- Added `HealthReminderSettingsView` and a compact `HealthReminderSettingsEntryCardView` using the existing SkateTrack dark / neon visual language.
- Connected the health reminder entry card to the Ride start screen while keeping Start Session, Live HUD, History, Summary, and Paywall flows unchanged.
- Free users can preview the health reminder settings and are routed to the existing Task-016b Paywall; subscriber / DEBUG-local entitlement simulation users can save reminder settings locally.
- Added `scripts/verify_health_reminders.py` to guard file presence, project membership, localization, paid-feature boundaries, deferred notification/weather scope, and documentation updates.
- Updated living documentation and ADR-0001 to record that Task-019 health reminder paid functionality continues the project-wide DEBUG/local entitlement simulation strategy.

### Paid Feature / Monetization Boundary
- Health reminders are gated through `GatedFeature.healthReminders`, `useSubscriptionStatus`, and the existing Task-016 entitlement provider architecture.
- Task-019a does not introduce production StoreKit purchase, App Store Connect products, sandbox tester flow, transaction validation, `AppStore.sync()`, real WeatherKit, or real notification scheduling.
- DEBUG/local entitlement simulation remains the development path; production monetization remains deferred to a future `AppStoreSubscriptionProvider` task.

### Scope Boundary
- No live-session reminder banner, UserNotifications scheduling, WeatherKit, real weather provider, high-temperature live alert, UV live alert, Watch haptic, GPS, IMU, Sensor Fusion, Fall Detection algorithm, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_health_reminders.py` together with localization, subscription entitlement simulation, subscription Paywall, feature flag, debug tools, and existing session summary/history verification scripts.
- Manual validation should confirm free users can preview health reminders but cannot save settings, Paywall routing works, DEBUG subscriber simulation unlocks editable settings, and Ride / History / Summary flows remain unchanged.

## 2026-06-11 — Task-019b Health Reminder Scheduler + In-App Reminder Banner

### Completed
- Added `HealthReminderEvent` and `HealthReminderScheduler` to convert saved health-reminder rules into in-app reminder events during active sessions.
- Connected `useHealthReminders` to session state so hydration and rest reminders are generated from active recording time while paused sessions do not accumulate new reminder events.
- Added a cooldown-stretch reminder event for the session ending / saving path.
- Added `HealthReminderBannerView` and integrated it into the Live HUD as an in-app banner that can be dismissed for the current event.
- Passed subscription state into `LiveHUDView` so health reminders continue to use the Task-016 `FeatureFlagEngine` / `useSubscriptionStatus` boundary and DEBUG/local entitlement simulation.
- Updated health reminder localization and verification coverage.

### Scope Boundary
- No UserNotifications scheduling, notification permission request, WeatherKit, real weather provider, high-temperature / UV live risk monitoring, Watch haptic feedback, StoreKit purchase flow, App Store Connect setup, AppStore.sync, transaction validation, sensor-engine algorithm, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_health_reminders.py` together with localization, subscription, debug tools, session recording, persistence, history, and summary verification scripts.
- Manual validation should confirm Live HUD in-app health reminder banners appear only when health reminders are enabled under subscriber / DEBUG simulated subscriber access.

## 2026-06-11 — Task-019b UI/UX Hotfix: Live HUD Debug Button and Minute-Level Reminder Intervals

### Completed
- Moved the DEBUG tools entry out of the Live HUD floating overlay path and into the Live HUD top control row so health reminder banners remain tappable.
- Kept the DEBUG tools entry visible only through the existing DEBUG-only root wiring; no Release behavior or subscription logic was changed.
- Changed health reminder interval steppers from 5-minute increments to 1-minute increments while preserving the existing valid range.

### Scope Boundary
- No health reminder scheduler logic, UserNotifications integration, WeatherKit, WeatherProvider, StoreKit purchase flow, sensor engine, fall detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

## 2026-06-11 — Task-019b UI/UX Hotfix: One-Minute Reminder Minimum

### Completed
- Updated health reminder interval validation so minute-based reminders can be set as low as 1 minute instead of being clamped to 5 minutes.
- Updated the health reminder settings steppers so hydration, rest, and cooldown stretch intervals use a 1-minute minimum with 1-minute adjustment steps.
- Kept existing upper bounds and did not change heat or UV threshold controls.

### Scope Boundary
- No scheduler timing logic, UserNotifications integration, WeatherKit, WeatherProvider, StoreKit purchase flow, Live HUD layout, sensor engine, fall detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

## 2026-06-11 — Task-019b Follow-up: Post-session Stretch Reminder Handoff

### Completed
- Moved the cooldown stretch reminder behavior out of the Live HUD ending/saving-only path and into a post-session handoff owned by the root navigation layer.
- After a session returns to the Ride start screen, the app now waits for the configured cooldown stretch interval and then shows the in-app stretch reminder on the Ride screen.
- Reused the existing `HealthReminderBannerView` and `GatedFeature.healthReminders` subscription boundary; free users still do not receive Pro health reminder events.
- Updated health reminder verification coverage for the post-session stretch reminder handoff.

### Scope Boundary
- No UserNotifications scheduling, notification permission request, background notification, WeatherKit, WeatherProvider, StoreKit purchase flow, sensor engine, fall detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

## 2026-06-11 — Task-019b UI/UX Follow-up: Post-session Stretch Overlay

### Completed
- Changed the post-session cooldown stretch reminder from an inline Ride-screen content card into a root-level overlay so it appears above the current Ride screen position instead of being embedded under the health reminder entry card.
- Kept the reminder explicitly dismissible through the existing `HealthReminderBannerView` close action.
- Preserved the Task-019b post-session delay, `GatedFeature.healthReminders` subscription boundary, and DEBUG/local entitlement simulation behavior.
- Updated health reminder verification coverage so the overlay handoff is owned by `RootNavigationView` rather than `SessionStartView` content flow.

### Scope Boundary
- No UserNotifications scheduling, background notification, WeatherKit, WeatherProvider, StoreKit purchase flow, health reminder settings range, Live HUD drinking/rest banner behavior, sensor engine, fall detection, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.


## 2026-06-11 — Task-019c Weather Risk Provider + Weather Suitability Card

### Completed
- Added a Task-019c weather-risk foundation without introducing real WeatherKit, network weather APIs, location permission requests, system notifications, or background updates.
- Added `WeatherRiskSnapshot`, `WeatherSuitabilityLevel`, `WeatherRiskFactor`, and `WeatherSuitabilityReport` models under `iOS/Core/HealthReminders`.
- Added `WeatherProviding` as a replaceable provider boundary and `MockWeatherProvider` as the development-time source of local mock weather data.
- Added `WeatherRiskMonitor` to evaluate heat, UV, and rain risk against the existing local health reminder thresholds.
- Added `useWeatherRisk` as the SwiftUI-facing boundary for weather suitability state and Pro detailed-risk access.
- Added `WeatherSuitabilityCardView` to the Ride start screen using the existing dark / neon SkateTrack visual language.
- Free users can see the basic mock weather summary, while detailed heat / UV / rain guidance remains gated behind `GatedFeature.healthReminders` through `useSubscriptionStatus` and the existing Task-016 entitlement-provider strategy.
- Added `scripts/verify_weather_risk.py` and updated living documentation for Task-019c.

### Paid Feature / Monetization Boundary
- Task-019c continues the project-wide paid feature rule: detailed weather-risk guidance is gated through `GatedFeature.healthReminders`, `useSubscriptionStatus`, and DEBUG/local entitlement simulation during development.
- No production StoreKit purchase, App Store Connect product, sandbox tester flow, transaction validation, `AppStore.sync()`, WeatherKit entitlement, real network weather API, or location-based weather flow was introduced.

### Scope Boundary
- No UserNotifications scheduling, background notification, real WeatherKit provider, network weather API, location permission request, Watch haptic, GPS, IMU, Sensor Fusion, Fall Detection algorithm, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_weather_risk.py` together with health reminders, localization, subscription entitlement simulation, subscription Paywall, feature flag, debug tools, and existing session summary/history verification scripts.
- Manual validation should confirm the Ride page shows the weather suitability card, free users see only basic mock weather summary plus a Pro detailed-risk preview, DEBUG subscriber simulation unlocks detailed heat / UV / rain guidance, and no real weather permission or system notification prompt appears.

## 2026-06-11 — Task-020a Equipment Manager Foundation + CRUD UI

### Completed
- Added the first Equipment Manager slice for iOS Screen 07 without connecting runtime session mileage accumulation yet.
- Expanded `EquipmentProfile` with equipment type, bearing mileage, maintenance date, optional photo identifier, and skateboard / inline setup fields while preserving the existing sport-mode and power-type validation rules.
- Extended the local `PersistedEquipment` Core Data model and programmatic persistence model with optional Task-020a gear fields for lightweight migration safety.
- Added `EquipmentRepository` for local equipment CRUD and wheel / bearing mileage reset actions.
- Added `WearReminderEngine` to calculate semantic OK / CHECK / REPLACE wear states from wheel and bearing mileage; Views render engine results and do not own wear formulas.
- Added `useEquipmentManager` as the SwiftUI-facing boundary for equipment state, CRUD actions, demo gear, and `.equipmentManager` subscription gating.
- Added `EquipmentListView`, `EquipmentCardView`, `EquipmentDetailView`, and `EditEquipmentView` using the existing dark / neon SkateTrack visual language and the UI Screen 07 equipment-card structure.
- Added the Gear entry to the root iOS navigation switch so free users can see sample gear cards and subscribers / DEBUG simulated subscribers can manage local gear profiles.
- Added `scripts/verify_equipment_manager.py` and updated localization for English and Traditional Chinese.

### Paid Feature / Monetization Boundary
- Task-020a gates equipment management through `GatedFeature.equipmentManager`, `useSubscriptionStatus`, and the existing Task-016 `FeatureFlagEngine` / DEBUG-local entitlement simulation architecture.
- Free users can view the Gear screen and sample cards, but creating, editing, deleting, and resetting real local gear profiles requires subscriber access.
- No production StoreKit purchase, App Store Connect product, sandbox tester flow, transaction validation, `AppStore.sync()`, or real App Store entitlement provider was added.

### Scope Boundary
- Task-020a does not connect SessionStart gear selection, SessionRepository equipment references, SessionRecordingCoordinator completion hooks, or automatic mileage accumulation; those remain Task-020b.
- No photo picker, Photos permission, cloud sync, Google Drive sync, UserNotifications, WeatherKit, GPS, IMU, Sensor Fusion, Fall Detection algorithm, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_equipment_manager.py` together with localization, subscription entitlement simulation, subscription Paywall, feature flag, health reminders, weather risk, debug tools, and existing session summary/history verification scripts.
- Manual validation should confirm the Gear screen appears in the root switch, free users see sample gear cards plus the Pro upgrade prompt, DEBUG subscriber simulation unlocks add/edit/delete/reset actions, wheel and bearing reset buttons update local gear mileage, and Ride / History / Live HUD flows remain unchanged.

## 2026-06-11 — Task-020a UI/UX Follow-up: Equipment Detail Header + Inline Skate Symbol

### Completed
- Reworked the equipment detail screen to use an in-content custom header below the root primary switch, preventing the back / title / edit controls from overlapping the root Ride / History / Gear tabs.
- Hid the default NavigationStack bar on equipment details and kept the root navigation switch visible for consistency with the existing top-level navigation style.
- Attempted to move the inline-skate icon toward the active platform symbol set, but follow-up validation showed `inline.skate` is unavailable in the current Xcode / iOS symbol set.
- Tightened equipment manager verification around the detail-header layout contract and duplicate post-session stretch overlay declarations; the later follow-up rejects the invalid `inline.skate` dependency explicitly.

### Scope Boundary
- No EquipmentRepository CRUD behavior, Core Data schema, SessionStart equipment selection, automatic session mileage accumulation, photo picker, Photos permission, StoreKit, sensor engine, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.



## 2026-06-11 — Task-020a UI/UX Follow-up 2: Detail Overlay Isolation + Safe Inline Skate Glyph

### Completed
- Fixed the remaining equipment-detail overlap by letting `EquipmentListView` report when a detail path is active and letting `RootNavigationView` hide the root primary switch and DEBUG floating button during equipment detail presentation.
- Preserved the equipment detail custom header as the only visible detail-level navigation control, so the back button no longer competes with the top-level Ride / History / Gear switch.
- Removed the invalid `inline.skate` SF Symbol dependency after Xcode confirmed the symbol is not available in the active system symbol set.
- Reintroduced a local `InlineSkateGlyphView` for inline-skate equipment cards, backed by safe SwiftUI drawing and the stable `figure.walk` SF Symbol fallback.
- Updated equipment manager verification to reject `inline.skate`, confirm root/detail handoff state, and confirm the safe inline-skate glyph path.

### Scope Boundary
- No EquipmentRepository CRUD behavior, Core Data schema, SessionStart equipment selection, automatic session mileage accumulation, photo picker, Photos permission, StoreKit, sensor engine, Launch Screen, AppIcon, bottom dock, watchOS, or macOS behavior was changed.

#### Task-020a UI/UX follow-up compile fix — Inline skate glyph scoped type
- Fixed an `Invalid redeclaration of InlineSkateGlyphView` build error by renaming the equipment-card local inline-skate glyph to `EquipmentCardInlineSkateGlyphView`.
- Kept the custom inline-skate glyph approach because `inline.skate` is not available in the current Xcode / SF Symbols set.
- Fixed `verify_equipment_manager.py` string quoting so the verifier can run successfully after the glyph fallback check.


## 2026-06-11 — Task-020b Session Equipment Selection + Auto Mileage Tracking

### Completed
- Added `SessionEquipmentPickerView` to the Ride start screen as a compact in-flow card, avoiding navigation overlays or top-control stacking risk.
- Connected the Ride start flow to subscriber-gated real equipment only; free users see a Pro equipment-tracking prompt and do not select sample gear for runtime sessions.
- Extended `useSessionRecording` and `SessionRecordingCoordinator.startSession` to carry an optional selected equipment ID into the active session lifecycle.
- Ensured finalized `SessionData` now receives the selected `equipmentID` during coordinator enrichment before `SessionRepository.saveCompletedSession(_:)` persists the session.
- Added `EquipmentMileageTracker` and repository mileage accumulation so saved sessions add distance to total gear mileage, wheel mileage, and bearing mileage.
- Applied equipment mileage only after `saveCompletedSession` succeeds; discard, failed save, missing equipment, zero distance, and no-equipment sessions do not update gear mileage.
- Added process-level duplicate protection in `EquipmentMileageTracker` so the same completed session ID is not applied twice during one app run.
- Added `scripts/verify_equipment_mileage_tracking.py` and updated equipment / session-recording verification coverage.

### Paid Feature / Monetization Boundary
- Task-020b follows the existing Task-016 strategy: equipment selection and automatic mileage tracking are gated through `GatedFeature.equipmentManager`, `useSubscriptionStatus`, and DEBUG/local entitlement simulation.
- No production StoreKit purchase, App Store Connect product, sandbox tester flow, transaction validation, `AppStore.sync()`, or real App Store entitlement provider was introduced.

### Scope Boundary
- Task-020b does not add History or Summary equipment-name display, archived gear-name snapshots, gear photos, photo-library permissions, cloud sync, Google Drive sync, maintenance calendar scheduling, Watch, or macOS behavior.
- No GPS, IMU, Sensor Fusion, Fall Detection algorithm, Launch Screen, AppIcon, bottom dock, WeatherKit, UserNotifications, or background task behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_equipment_mileage_tracking.py` together with equipment manager, session recording coordinator, localization, subscription entitlement simulation, subscription Paywall, feature flag, health reminders, weather risk, debug tools, and existing history/summary verification scripts.
- Manual validation should confirm Pro / DEBUG subscribers can select compatible gear on the Ride start screen, sessions without selected gear still start normally, saved sessions with selected gear increase total / wheel / bearing mileage, discard does not increase gear mileage, and free users cannot select sample gear for runtime mileage tracking.

#### Task-020b follow-up — Equipment mode / power compatibility filter
- Tightened the Ride start equipment picker so selectable gear must match the current `SportMode` and `PowerType`, not only the broad skateboard / inline equipment family.
- Skateboard sessions now require matching board mode and matching human / electric power type before a gear profile can be selected.
- Inline sessions now require matching inline mode and human-powered gear; electric power remains invalid for inline equipment.
- Changing board mode, inline mode, power type, subscription access, or available gear clears an incompatible selected gear ID before a session starts.
- Kept the picker as an in-flow Ride card to avoid root-tab, detail-navigation, or floating overlay overlap risk.

## 2026-06-12 — Task-020c Equipment Attribution in History / Summary + Archived Reference

### Completed
- Added `EquipmentSessionSnapshot` so completed sessions can keep an archived equipment snapshot independent of the mutable Equipment Manager store.
- Extended `SessionData`, `SessionRecordingCoordinator`, and `useSessionRecording` to carry the selected equipment snapshot from the Ride start screen into the completed session payload.
- Persisted the snapshot as optional `equipmentSnapshotData` on `PersistedSession` and updated both the programmatic Core Data model and `.xcdatamodel` file for lightweight migration.
- Updated `SessionEntityMapper` to encode / decode the archived equipment snapshot alongside `equipmentID`.
- Added a compact equipment snapshot row to History cards without changing the History list hierarchy or adding overlay UI.
- Added `SessionEquipmentAttributionView` to Session Summary as a standalone card after the identity card, using the same dark / neon card language as the existing UI plan.
- Added `scripts/verify_equipment_attribution.py` and expanded History / Summary verification coverage for the archived equipment snapshot path.

### Scope Boundary
- Task-020c does not add gear photos, photo-library permission, Summary-to-Gear deep links, maintenance calendar scheduling, report export, cloud sync, production StoreKit, App Store Connect products, Watch, or macOS behavior.
- No GPS, IMU, Sensor Fusion, Fall Detection algorithm, Launch Screen, AppIcon, bottom dock, WeatherKit, UserNotifications, or background task behavior was changed.

### Validation Notes
- Run `python3 scripts/verify_equipment_attribution.py` together with equipment mileage, equipment manager, session history, session summary, localization, feature flag, and subscription simulation verification scripts.
- Manual validation should confirm a saved session with selected equipment shows the archived gear line in History and the Used Equipment card in Summary, and that those UI elements still render even if the original gear is later deleted.

## 2026-06-12 — Task-021a Spot Management Foundation + SessionStart Split

### Completed
- Split `SessionStartView.swift` by moving shared Session Start support types, colors, and the custom inline-skate glyph into `SessionStartSupportTypes.swift` without changing Session Start behavior or visuals.
- Expanded `SpotProfile` for Task-021a local-first management with radius, activity family, safety rating, crowd level, favorite status, and created / updated timestamps.
- Added `SpotVisit` as a shared future association model for Task-021b route / summary linking, without wiring runtime visit detection yet.
- Extended the local Core Data `PersistedSpot` schema for the new Spot fields while keeping migration-friendly optional storage for newly added columns.
- Added `SpotRepository` for local Spot CRUD, favorite toggling, and nearby distance filtering behind a Core Data boundary.
- Added `useSpots` as the SwiftUI-facing Spot state boundary, including the free 3-favorite limit and Paywall intent through `GatedFeature.spotManagement`.
- Added iOS Spot Management UI: Spot list, local MapKit marker foundation, Spot detail, Spot editor, Spot cards, and favorite-limit banner.
- Added a root-level `場地 / Spots` entry while making the root primary switch horizontally scrollable to avoid top-tab crowding.
- Added Task-021a localization keys and `scripts/verify_spots.py`.
- Added ADR-0002 for developer-account-dependent services and appended Task-021a confirmation to ADR-0001.

### Scope Boundary
- Task-021a does not connect WeatherKit, Google services, public spot databases, location permission requests, cloud sync, route-to-spot detection, SessionStart spot selection, Summary spot attribution, social sharing, App Store Connect, production StoreKit, signing, capabilities, Launch Screen, AppIcon, watchOS, or macOS UI.
- MapKit is used only to render coordinates that users manually save in local Spot records.
- Spot favorite gating continues to use `FeatureFlagEngine`, `useSubscriptionStatus`, and DEBUG/local entitlement simulation; no production monetization behavior was added.

### Validation Notes
- Run `python3 scripts/verify_spots.py` to verify Task-021a files, Spot model fields, repository boundary, UI boundaries, localization keys, project membership, docs, and SessionStart split.
- Continue running localization, feature-flag, subscription entitlement, Paywall, weather-risk, equipment, and session-recording verification scripts after applying this task.


## 2026-06-12 — Task-021b Spot Association + Visit Tracking Foundation

### Completed
- Added `SpotSessionSnapshot` so completed sessions can preserve the selected local Spot name, activity family, coordinate, and radius at ride time.
- Extended `SessionData`, `SessionEntityMapper`, the programmatic Core Data model, and the `.xcdatamodel` with optional `spotSnapshotData`.
- Added a lightweight `PersistedSpotVisit` entity and expanded `SpotRepository` with visit fetch / idempotent record APIs.
- Added `SpotVisitTracker` as the session-completion boundary that updates Spot visit count and last-visited date only after `SessionRepository.saveCompletedSession(_:)` succeeds.
- Split post-save mileage / Spot visit side effects into `SessionRecordingCoordinator+CompletionEffects.swift` so the main coordinator stays under the 450-line warning threshold.
- Extended `SessionRecordingCoordinator` and `useSessionRecording` so Session Start can carry `spotID` and `SpotSessionSnapshot` through final persistence.
- Added `SessionSpotPickerView` as an in-flow local Spot picker on Session Start without location permission, public spot discovery, or WeatherKit integration.
- Updated History cards and Session Summary with snapshot-based Spot attribution.
- Updated Spot detail with last-visited display.
- Added Task-021b localization keys, iOS unit-test coverage for selected Spot snapshot persistence, and `scripts/verify_spot_session_association.py`.

### Scope Boundary
- No route-to-spot auto detection, geofencing, nearby public spot database, WeatherKit rideability, Google services, cloud sync, background location, signing, capabilities, production StoreKit, watchOS UI, or macOS UI was added.
- `SpotVisitTracker` updates visits after successful session persistence only; failed save and discarded sessions do not update Spot visit counts.
- Session Summary uses archived `SpotSessionSnapshot` data rather than live mutable Spot lookup, matching the Task-020c equipment snapshot pattern.

### Validation Notes
- Run `python3 scripts/verify_spot_session_association.py` together with Task-021a Spot, Session Start, localization, equipment attribution, weather, and subscription verification scripts.
- Run the iOS build / test target in Xcode to validate the new Session Start picker, session finalization, History spot line, Summary spot attribution, and Core Data lightweight migration on the simulator.

## 2026-06-12 — Task-021b Follow-up: History Bulk Delete + MapKit Warning Cleanup

### Completed
- Added History multi-select cleanup mode so users can select and delete multiple local session records from the History page before committing Task-021b.
- Added `SessionHistoryBulkActionBarView` for a compact dark / neon bulk-action toolbar, keeping selection and delete controls out of the main History list code.
- Extended `SessionHistoryViewModel` with visible-session selection helpers and local batch deletion through `SessionRepositoryProtocol.deleteSession(id:)`.
- Updated `SessionHistoryCardView` and `SessionHistoryListView` to support selection badges without changing the normal tap-to-summary / locked-card Paywall behavior.
- Updated `SessionRepository.deleteSession(id:)` so deleting a saved session also deletes linked local Spot visit records and refreshes the mutable Spot visit summary.
- Updated `SpotRepository.deleteSpot(id:)` to clean up local visit rows when a Spot is deleted.
- Reworked `SpotMapView` to use iOS 17 `Map(position:)` and `Annotation` APIs, removing the deprecated `coordinateRegion` / `MapAnnotation` warnings from Task-021a/021b.
- Added localization keys and verification coverage for History bulk delete and MapKit deprecation guards.

### Scope Boundary
- No cloud deletion, server sync, Google Drive, WeatherKit, route-to-spot auto detection, production StoreKit, signing, capabilities, watchOS UI, or macOS UI was added.
- Deletion is local-device only and intentionally destructive after user confirmation.
- Locked older free-tier History cards remain deletable in selection mode so users can clean up local data without upgrading.

### Validation Notes
- Run `python3 scripts/verify_session_history.py`, `python3 scripts/verify_spots.py`, and `python3 scripts/verify_spot_session_association.py` after applying this follow-up.
- Manual validation should confirm selection mode, select-all-visible, clear selection, destructive delete confirmation, locked-card deletion, History refresh, Spot visit summary refresh, and absence of SpotMapView deprecation warnings.


## 2026-06-12 — Task-022 Weather Provider Upgrade + Local Rideability Integration

### Completed
- Upgraded the Task-019c weather boundary with `WeatherQueryContext` so ride-start and spot-preview UI can request context-aware mock weather without reading current location or calling a network service.
- Added `DisabledWeatherProvider` as the explicit fallback for developer-account-dependent live weather services that are not enabled yet.
- Added `WeatherRideabilityReport` and `WeatherRideabilityEngine` to combine mock weather risk with local Spot surface, crowd, and safety factors.
- Updated `MockWeatherProvider` to produce stable local mock snapshots from ride-start / spot-preview context while remaining fully offline.
- Updated `useWeatherRisk` to expose both the original weather suitability report and the new local rideability report.
- Split the Session Start weather section into `SessionStartWeatherSectionView` so `SessionStartView.swift` stays comfortably under the file-length warning threshold.
- Added reusable weather UI rows and status chips to keep `WeatherSuitabilityCardView` readable.
- Added Spot rideability UI on Spot detail, plus lightweight rideability chips in Spot cards and map markers.
- Added Task-022 localization keys and `scripts/verify_weather_rideability.py`; updated the existing weather verification script for the upgraded provider boundary.

### Scope Boundary
- Task-022 does not implement WeatherKit, external weather APIs, API keys, URLSession networking, current-location permission, background weather refresh, signing, capabilities, production StoreKit, App Store Connect, Google services, watchOS UI, or macOS UI.
- Rideability output is a local simulation built from mock weather and local Spot metadata; it must be presented as guidance, not as a production live-weather safety guarantee.
- Detailed weather / spot-factor guidance remains gated through `GatedFeature.healthReminders`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation.

### Validation Notes
- Run `python3 scripts/verify_weather_rideability.py` together with `verify_weather_risk.py`, localization, subscription, Spot, and Session Start verification scripts.
- Manual validation should confirm ride-start weather context changes when a local Spot is selected, Spot detail shows the local rideability card, free users see locked detailed factors, DEBUG/local subscriber simulation unlocks detailed factors, and no location or WeatherKit permission prompt appears.

## 2026-06-12 — Task-022d Documentation Alignment: GPS-Denied Indoor Recording Strategy

### Completed
- Added ADR-0003 to document the GPS-denied indoor recording strategy before future indoor tracking work begins.
- Recorded the decision that Task-023 through Task-030 must not add production indoor speed, IMU-only route drawing, ARKit normal ride recording, UWB venue tracking, or fake indoor route / speed data.
- Defined the earliest safe follow-up as a post-Task-030 Recording Data Quality + Indoor Fallback Foundation task.
- Split future indoor-related work into safer phases: Phase 1b data quality and honest fallback, Phase 2 dataset / offline experimentation, Phase 3 ARKit coach / video analysis, and future B2B UWB venue mode.
- Documented product safety copy principles for GPS-unavailable sessions so SkateTrack presents low-confidence or unavailable data honestly.

### Scope Boundary
- Documentation only. No Swift source, Xcode project, Core Data schema, localization, sensors, Session Recording runtime, UI, signing, capabilities, WeatherKit, ARKit, UWB, or external service integration was changed.
- This documentation alignment is intentionally left uncommitted until the first Task-023 stage is ready, so it can be committed together with that stage as requested.

### Validation Notes
- Review `docs/adr/ADR-INDEX.md` before starting any task that mentions indoor mode, no-GPS speed, IMU-only odometry, ARKit tracking, or UWB venue analytics.
- Future implementation tasks should treat ADR-0003 as a guardrail against introducing misleading indoor speed or route data.

## 2026-06-12 — Task-023a Session Share Card Preview Foundation

### Completed
- Replaced the Task-018b Summary share stub with a real local share-card preview foundation while keeping export and the system share sheet deferred to Task-023b.
- Added `SessionShareCardData` as a shared Codable / Sendable model for share-card preview data.
- Added `useSessionShareCard` as the SwiftUI-facing formatter boundary so Summary Views do not directly format share-card metrics, route status, safety status, Spot attribution, or equipment attribution.
- Added dark SkateTrack neon share-card preview UI with reusable metric, locked, and action components.
- Gated full share-card preview access through `GatedFeature.sessionShareCard`, `useSubscriptionStatus`, and the existing Task-016b Paywall route.
- Free users now see a locked share-card preview and can open the existing Paywall; Pro / DEBUG-local subscriber simulation shows the full card preview.
- Added Task-023a localization keys, `scripts/verify_session_share_card.py`, and updated `scripts/verify_session_summary.py` for the new share-card foundation.

### Scope Boundary
- No PNG rendering, `ImageRenderer`, `UIActivityViewController`, temporary file export, AirDrop package, Photos write, Google Drive, iCloud / CloudKit, external API, Core Data schema, signing, capabilities, production StoreKit, watchOS UI, or macOS UI was added.
- Task-023a is preview and gating foundation only. Task-023b should add local image / text export and the system share-sheet wrapper behind this foundation.
- Task-022d ADR-0003 remains part of the same pending commit and continues to guard against adding misleading indoor speed or route data during Task-023 work.

### Validation Notes
- Run `python3 scripts/verify_session_share_card.py`, `python3 scripts/verify_session_summary.py`, and `python3 scripts/verify_localization_keys.py` after applying this task.
- Manual validation should confirm locked preview for free users, Paywall routing for `sessionShareCard`, full preview in DEBUG/local subscriber simulation, Summary still loads route / safety / equipment / Spot attribution, and no export or system share sheet appears in Task-023a.


## 2026-06-12 — Task-023b Session Share Card Quick Export + Share Sheet Integration

### Completed
- Added `iOS/Core/SessionSharing` as the local share export boundary for Task-023b payloads and temporary file writing / cleanup.
- Added `SessionShareExportPayload` and `SessionShareExportService` to create a PNG / TXT / JSON quick-export set inside `FileManager.default.temporaryDirectory` without writing to Photos or cloud storage.
- Added `SessionShareCardRenderer` so the Task-023a SwiftUI share-card preview can be rendered into a PNG only inside the dedicated renderer boundary.
- Added `SessionShareExportViewModel` to keep render, export, share-sheet state, errors, and cleanup out of `SessionSummaryView` and `SessionSummaryShareStubView`.
- Added `SessionShareSheetView` as the only `UIActivityViewController` wrapper for the generated local file URLs.
- Updated `SessionShareCardActionView` so Pro / DEBUG-local subscriber simulation can prepare the export and open the iOS system share sheet.
- Updated localization keys, `scripts/verify_session_share_export.py`, `scripts/verify_session_share_card.py`, and `scripts/verify_session_summary.py` for the quick-export flow.

### Scope Boundary
- Task-023b does not write to Photos, request Photo Library permission, create an AirDrop-specific package, integrate Google Drive, iCloud / CloudKit, external APIs, production StoreKit, signing, capabilities, watchOS UI, or macOS UI.
- Share-card export remains gated through `GatedFeature.sessionShareCard`, `useSubscriptionStatus`, and DEBUG/local entitlement simulation.
- Task-027 remains responsible for a fuller AirDrop / export package format; Task-023b is only Summary quick export.

### Validation Notes
- Run `python3 scripts/verify_session_share_export.py`, `python3 scripts/verify_session_share_card.py`, `python3 scripts/verify_session_summary.py`, and `python3 scripts/verify_localization_keys.py` after applying this task.
- Manual validation should confirm free users cannot export, Pro / DEBUG-local subscriber simulation can open the share sheet with PNG / TXT / JSON items, cancelling the sheet does not crash, and no Photos permission prompt appears.

## 2026-06-12 — Task-023c Save Share Card to Photos + Export Scope ADR

### Completed
- Added `SessionSharePhotoLibrarySaver` as the only Photos framework bridge for saving generated share-card PNG data to the user's photo library through add-only authorization.
- Added `SessionSharePhotoSaveState` and updated `SessionShareExportViewModel` so Photos save state, permission denial, success, and failure messages stay out of the Summary view tree.
- Updated `SessionShareCardActionView` with a separate "Save to Photos" action while preserving the existing Task-023b quick-export share-sheet flow.
- Added `NSPhotoLibraryAddUsageDescription` to the iOS generated Info.plist build settings and localized InfoPlist copy in English and Traditional Chinese.
- Added ADR-0004 to document the export-target strategy: Task-023c saves share-card images to Photos, while AirDrop-specific packages and full portable archives remain Task-027 / Task-028 work.
- Added `scripts/verify_session_share_photos.py` and updated share export / share card verification for the Photos boundary.

### Scope Boundary
- Task-023c does not request full Photo Library read access, read the user's photo library, use `UIImageWriteToSavedPhotosAlbum`, create an AirDrop-specific package, define the final portable archive format, integrate Google Drive / iCloud / CloudKit, modify Core Data, or change signing / capabilities / entitlements.
- Save-to-Photos remains gated behind the same `GatedFeature.sessionShareCard`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation path as Task-023a / Task-023b.
- Task-027 remains responsible for AirDrop / Export Package / portable archive format design.

### Validation Notes
- Run `python3 scripts/verify_session_share_photos.py` together with the existing Task-023b share export, share card, Summary, and localization verification scripts.
- Manual validation should confirm Pro / DEBUG-local subscriber simulation can save the generated share-card PNG to Photos, denied Photos add permission shows a clear localized message, free users remain on the locked preview / Paywall route, and no full photo-library read permission is requested.

## 2026-06-12 — Task-024a Achievements Foundation + Local Progress UI

### Completed
- Added shared `Achievement` and `WeeklyChallenge` models for local milestone and weekly-goal data.
- Added `iOS/Core/Achievements` with `AchievementCatalog`, `AchievementEngine`, `AchievementUnlockStore`, and `WeeklyChallengeEngine` so rule evaluation and local unlock persistence stay out of SwiftUI Views.
- Added `useAchievements` as the SwiftUI-facing boundary that reads local Session, Equipment, and Spot repositories, evaluates progress, and persists unlocked achievement records through UserDefaults.
- Added the iOS Achievements screen with dark SkateTrack visual styling, local progress stats, weekly challenge cards, achievement cards, and Pro-locked advanced challenge previews.
- Added `GatedFeature.advancedChallenges` so advanced challenge access follows `FeatureFlagEngine`, `useSubscriptionStatus`, and DEBUG/local entitlement simulation.
- Added root navigation access to the Achievements screen without changing Session Start, History, Equipment, Spot, or Summary flows.
- Added localization keys and `scripts/verify_achievements.py`; updated the feature flag verification script for the new gated feature.

### Scope Boundary
- Task-024a is local-first and does not add Game Center, remote leaderboards, friends, server verification, push notifications, calendar integration, cloud sync, Google services, production StoreKit, App Store Connect, signing, capabilities, watchOS UI, or macOS UI.
- Achievement unlock state is intentionally stored in UserDefaults as local JSON; Core Data schema is not changed in this phase.
- The task does not modify GPS, IMU, SensorFusion, FallDetection, Launch Screen, AppIcon, bottom dock, WeatherKit, or the share/export pipeline.

### Validation Notes
- Run `python3 scripts/verify_achievements.py`, `python3 scripts/verify_feature_flags.py`, and `python3 scripts/verify_localization_keys.py` after applying this task.
- Manual validation should confirm the new Achievements tab opens, local stats load from saved sessions, basic achievements show progress, advanced challenges open the existing Paywall for free users, and DEBUG/local subscriber simulation unlocks advanced challenge progress.

## 2026-06-12 — Task-024b Weekly Challenge Polish + Achievement Dashboard Links

### Completed
- Added `WeeklyChallengeCompletionRecord` and `WeeklyChallengeCompletionStore` so completed weekly challenge periods can be preserved locally with UserDefaults-backed JSON rather than Core Data migration.
- Extended the weekly challenge engine with local week identifiers, completion-record merging, a safe weekly no-fall challenge, and an advanced gear-tracking weekly challenge.
- Extended the achievement catalog with safe local goals for gear setup, active weeks, and no-fall session flow while avoiding trick-count, indoor, ARKit, or UWB achievements.
- Added `useAchievementDashboard` and `SessionStartAchievementDashboardCardView` so the Ride page can surface a lightweight weekly challenge / unlocked-achievement dashboard without reading repositories in `SessionStartView`.
- Added related-stat links on the Achievements screen for History, Gear, and Spots, with navigation delegated back to `RootNavigationView`.
- Added `WeeklyChallengePeriodBadgeView` to display local weekly challenge periods and completion state without growing `WeeklyChallengeCardView`.
- Added ADR-0005 to record the local-first achievements / challenges scope and the Task-024 deferred items.
- Updated localization keys and `scripts/verify_achievements.py` for the Task-024b dashboard, completion store, related links, and deferred-scope documentation.

### Scope Boundary / Deferred Items
- Task-024b does not add global leaderboards, friends, social challenges, remote challenge configuration, server verification, Game Center, push notifications, calendar integration, cloud sync, cross-device challenge state, Google / iCloud / CloudKit, production StoreKit, signing, capabilities, watchOS UI, or macOS UI.
- Trick-count achievements remain deferred until a reliable trick engine exists.
- Indoor, ARKit, and UWB achievements remain deferred according to ADR-0003 and ADR-0005.
- Punitive daily streak mechanics are intentionally deferred to avoid pressure-based retention and rest-day penalties; the current implementation uses weekly progress and active-week style goals instead.

### Validation Notes
- Run `python3 scripts/verify_achievements.py`, `python3 scripts/verify_feature_flags.py`, and `python3 scripts/verify_localization_keys.py` after applying this task.
- Manual validation should confirm the Ride page dashboard opens Achievements, related-stat links navigate to History / Gear / Spots, weekly challenge period badges render correctly, completed weekly challenges remain marked complete during the same local week, and advanced challenge progress remains behind the existing Paywall for free users.

## 2026-06-12 — Task-024b Follow-up: Session Start Floating Root Navigation

### Completed
- Added a sticky floating root navigation component for the Ride / Session Start page.
- The root navigation pills still appear below the SkateTrack title at the top of the Ride page.
- When the Ride page scrolls down, the same navigation control now floats below the Dynamic Island / safe area while the title and dashboard content scroll away.
- Preserved the existing root navigation behavior for History, Equipment, Spots, and Achievements pages.
- Refreshed the SessionShareExportViewModel concurrency-safe initializer guard in the delivered fix package so stale local files cannot reintroduce the Task-023b main-actor default-argument compile error.

### Scope Boundary
- No Start Session behavior, recording lifecycle, achievement rules, repository logic, sensor engines, AppIcon, Launch Screen, bottom dock, watchOS, macOS, signing, capabilities, or entitlements were changed.

## 2026-06-12 — Task-024b Follow-up: Split Session Start Header / Metrics

### Completed
- Split the Session Start page header and preview metric strip into `SessionStartHeaderMetricsView.swift`.
- Reduced `SessionStartView.swift` from the sticky-navigation follow-up's 450-line edge case to a safer sub-400-line file so Task-022 / Session Start verification remains comfortably below the guardrail.
- Updated `scripts/verify_session_start_flow.py` to require the new split header / metrics component and guard against regressing the Session Start file-size boundary.

### Scope Boundary
- No Session Start behavior, start-session parameters, recording lifecycle, achievement / challenge rules, repositories, sensor engines, platform targets, signing, capabilities, entitlements, AppIcon, Launch Screen, or bottom dock were changed.
- This is a same-stage Task-024b compile / verification hygiene fix and should be committed together with the Task-024b main package and sticky-navigation follow-up.


## 2026-06-12 — Task-024b Follow-up: Sticky Navigation Trigger + Compile Sources Cleanup

### Completed
- Refined the Ride-page sticky root navigation trigger to use the measured navigation-row position instead of relying only on scroll offset, so the pill navigation floats below the Dynamic Island / safe area as soon as the in-content row reaches the pinned position.
- Kept the top-of-page layout unchanged: SkateTrack title, root navigation pills, greeting / ready state, and content cards remain in the normal scroll flow until the user scrolls down.
- Cleaned the iOS target Compile Sources phase so `WeeklyChallengeCompletionRecord.swift` is included exactly once, removing the Xcode duplicate-build-file warning.
- Updated verification scripts to guard against regressing the measured sticky-navigation trigger or reintroducing duplicate Compile Sources membership.

### Scope Boundary
- No achievement / weekly-challenge rules, session recording behavior, repositories, sensor engines, platform targets, signing, capabilities, entitlements, AppIcon, Launch Screen, or bottom dock were changed.
- This is a same-stage Task-024b UI / project-warning correction and should be committed together with the Task-024b main package and previous follow-up fixes.

## 2026-06-12 — Task-024b Follow-up: Dynamic Island Sticky Navigation Offset

### Completed
- Corrected the Ride-page floating root navigation vertical offset so the sticky pill row uses a minimum Dynamic Island-safe top inset even when SwiftUI reports a zero safe-area inset inside the full-screen Session Start layout.
- Kept the top-of-page layout unchanged while ensuring the floating navigation pins below the Dynamic Island / status area after scrolling instead of being covered by the camera island, time, Wi-Fi, or battery indicators.
- Updated `scripts/verify_session_start_flow.py` to guard the minimum sticky navigation top inset constants.

### Scope Boundary
- No Start Session behavior, recording lifecycle, achievement / challenge rules, repositories, sensor engines, platform targets, signing, capabilities, entitlements, AppIcon, Launch Screen, or bottom dock were changed.
- This is a same-stage Task-024b UI positioning fix and should be committed together with the Task-024b main package and prior follow-up fixes.

## 2026-06-12 — Task-025a Account Provider Foundation（Google Sign-In Deferred）

### Completed
- Added `AuthSession` shared account state models for signed-out, local simulation signed-in, and Google-unavailable states without storing OAuth token or external-service secrets.
- Added `AuthProvider` and `GoogleSignInProviding` boundaries so future account providers can be swapped behind a protocol instead of being called directly from Views.
- Added `LocalAccountProvider` for DEBUG-only local account simulation. Release builds stay signed out and do not expose a fake sign-in path.
- Added `DisabledGoogleAuthProvider` to represent the current blocked Google Sign-In state without importing Google SDKs, launching OAuth, adding client IDs, or configuring URL schemes.
- Added `AuthTokenStore` as a placeholder token-storage boundary that only records non-sensitive provider metadata and always reports no production token in Task-025a.
- Added `useAccount` / `AccountViewModel` as the SwiftUI-facing account state adapter for future Account settings UI.
- Added localized account / Google-deferred / DEBUG simulation strings in English and Traditional Chinese.
- Added `scripts/verify_account_provider.py` to verify required files, project membership, localization keys, provider-boundary tokens, documentation, and the absence of production Google configuration.
- Updated `docs/reference/FILE_STRUCTURE.md` and ADR-0002 for the Task-025a account-provider boundary.

### Scope Boundary
- Task-025a does not add `AccountSettingsView`, root navigation entry, or visible Settings UI. That UI foundation remains Task-025b so provider architecture and navigation polish do not land in one oversized change.
- Task-025a does not add Google Sign-In production, Google OAuth client ID, reversed client ID URL scheme, `GoogleService-Info.plist`, Google SDK package dependency, token refresh, real Google profile loading, Drive scope authorization, Google Drive sync, server verification, cloud backend, signing changes, capabilities, entitlements, production StoreKit, watchOS UI, or macOS UI.
- The local account path is explicitly DEBUG-only simulation and must not be described as a real external login provider.
- The token store is a placeholder boundary only; it intentionally does not save access tokens, refresh tokens, ID tokens, or secrets.

### Deferred from Task-025a
- `AccountSettingsView`, account status card, and root Settings / Account navigation entry move to Task-025b.
- Real `GoogleSignInProvider`, OAuth client ID, reversed client ID URL scheme, Google SDK dependency, `GoogleService-Info.plist`, real user profile, token refresh, token revocation, and server-side verification remain blocked until Google Cloud credentials and privacy review are ready.
- Drive scope authorization and Google Drive sync are not part of Task-025 and should start no earlier than Task-026 behind a separate backup / sync provider boundary.
- Production token persistence / Keychain policy should be completed only with the real provider integration task, after credentials, minimum scopes, logout / revocation behavior, and privacy copy are finalized.

### Validation Notes
- Run `python3 scripts/verify_account_provider.py` after applying this task.
- Run existing localization and shared-model verification scripts to ensure account strings and shared models remain aligned.
- Xcode validation should confirm the iOS target compiles with the new account provider files and that no Google OAuth prompt, URL-scheme setup, signing change, or capability change appears.

## 2026-06-12 — Task-025b Account Settings UI Foundation

### Completed
- Added a visible Account settings screen under `iOS/Features/Settings/AccountSettingsView.swift` using the Task-025a `useAccount` boundary rather than direct Google SDK, token storage, or Drive APIs.
- Added a localized `帳號` / Account root navigation entry in `RootNavigationView` without changing the bottom dock, Launch Screen, AppIcon, watchOS UI, or macOS UI.
- The Account screen now shows local-first account status, provider state, profile placeholder / local simulation profile details, Google unavailable state, and a clear Drive-sync deferred note.
- DEBUG builds can use local-only account simulation sign-in / sign-out from the Account screen; Release builds do not expose local fake sign-in controls.
- The Google status action only reports the disabled / unconfigured state through `DisabledGoogleAuthProvider`; it does not start OAuth, open Safari, request credentials, or load any Google SDK.
- Added Task-025b localization keys and extended `scripts/verify_account_provider.py` to verify the Account UI, root navigation membership, disabled-provider guardrails, localization, docs, and project membership.
- Updated `docs/reference/FILE_STRUCTURE.md` and ADR-0002 so the visible UI is documented separately from production Google Sign-In and Google Drive sync.

### Scope Boundary
- Task-025b does not add real Google OAuth sign-in, Google SDK package dependency, OAuth client ID, reversed client ID URL scheme, `GoogleService-Info.plist`, production profile loading, token refresh, token revocation, server verification, Drive scope authorization, Google Drive sync, cloud backup, production token persistence, or Keychain policy finalization.
- Task-025b does not change signing, capabilities, provisioning, Bundle ID, entitlements, production StoreKit, WeatherKit, CloudKit, watchOS UI, macOS UI, Launch Screen, AppIcon, bottom dock, GPSProvider, IMUProvider, SensorFusionEngine, or FallDetectionEngine.
- The UI is intentionally local-first and honest about unavailable Google functionality. It must not be described as production Google Sign-In readiness.

### Deferred from Task-025b
- Real `GoogleSignInProvider`, Google OAuth client ID, reversed client ID URL scheme, Google SDK dependency, `GoogleService-Info.plist`, real profile loading, token refresh / revocation, server verification, and production token persistence / Keychain policy remain future blocked work after credentials and privacy copy are ready.
- Google Drive scope authorization and Google Drive sync remain Task-026 or later work and must use a separate backup / sync provider boundary.
- Cloud backup, portable account migration, production account deletion, and cross-device account recovery remain future account / sync tasks.

### Validation Notes
- Run `python3 scripts/verify_account_provider.py`, `python3 scripts/verify_localization_keys.py`, `python3 scripts/verify_shared_models.py`, and `python3 scripts/verify_subscription_entitlement_simulation.py` after applying this task.
- Manual validation should confirm the `帳號` navigation entry opens the Account screen, DEBUG local simulation sign-in / sign-out works without external login, Google shows a disabled / unconfigured state, no OAuth or Safari flow appears, and no signing / capabilities changes are introduced.

## 2026-06-12 — Task-025c Root Navigation Sticky Polish + Debug Entry Placement

### Completed
- Reworked the Ride-page root navigation so the visible `滑行` / `歷史紀錄` / `我的裝備` / `場地` / `成就` / `帳號` pill row follows the original in-page position and then pins below the Dynamic Island / safe area, instead of appearing as a separate threshold-only overlay.
- Kept the in-page root navigation row as an invisible layout / measurement anchor so the title-first layout spacing stays stable while only one visible navigation row is presented to the user.
- Added a subtle sticky background fade as the navigation row approaches its pinned position, preserving legibility when content scrolls underneath the pinned controls.
- Moved the DEBUG-only `DEV`開發者工具入口 from the upper-right overlay to a bottom-right floating position, with extra Ride-page bottom clearance to reduce overlap with the start-session dock.
- Added `scripts/verify_root_navigation_polish.py` to guard the continuous sticky-navigation implementation, bottom-right DEBUG placement, documentation notes, and production Google Sign-In boundaries.

### Scope Boundary
- Task-025c does not change Account provider behavior, Google Sign-In production, Google SDK dependencies, OAuth client IDs, reversed client ID URL schemes, `GoogleService-Info.plist`, Google Drive sync, StoreKit production, signing, capabilities, entitlements, provisioning, Bundle ID, Launch Screen, AppIcon, bottom dock implementation, watchOS UI, macOS UI, GPSProvider, IMUProvider, SensorFusionEngine, or FallDetectionEngine.
- Task-025c does not refactor the independent scroll layouts of `歷史紀錄`, `我的裝備`, `場地`, `成就`, or `帳號`.

### Deferred from Task-025c
- Applying the same natural title-under-navigation-to-sticky transition to non-Ride root screens remains Task-025d or later, after each screen's ScrollView structure is reviewed independently.
- A shared frosted-glass / material root navigation system for all root screens remains future UI polish work and should not be mixed with this same-stage fix.

### Validation Notes
- Run `python3 scripts/verify_root_navigation_polish.py` plus existing Task-025 verification scripts after applying this task.
- Manual validation should confirm the Ride-page pill row appears to be the same row naturally sliding into a pinned position, the `DEV`開發者工具入口 sits at the lower-right, and no top navigation pill is blocked.

## 2026-06-12 — Task-026a Backup Package Export Foundation + Disabled Drive Status

### Completed
- Added shared backup package models with `BackupPackageManifest.schemaVersion` fixed as `Int = 1` and `packageType = backup` so future restore / export readers can distinguish local backups from portable sharing packages.
- Added `BackupPackagePayload` sections for sessions, equipment, spots, achievements, and weekly challenge completions.
- Added `CloudBackupProvider`, `LocalBackupProvider`, and `DisabledDriveProvider` so backup / sync work follows the same provider-boundary pattern as Weather and Account tasks.
- Added `BackupPackageEncoder` to independently encode each domain-model store and record store-specific fetch / encoding issues without importing Core Data or encoding `NSManagedObject` directly.
- Added `useBackupSync` as the SwiftUI-facing hook. Views use this hook rather than direct provider, Core Data, Google SDK, Drive API, or token APIs.
- Added `BackupSyncSettingsView` to the Account screen. It supports user-initiated local backup package creation and system share sheet export, while clearly showing Google Drive as not configured.
- Added localized English and Traditional Chinese strings for 「備份與同步」 local backup, Drive disabled state, restore-deferred state, errors, and conflict-policy labels.
- Added `scripts/verify_backup_sync.py` to verify provider boundaries, localization keys, docs, project membership, and the absence of production Google Drive / OAuth configuration.
- Added `docs/process/DEVELOPMENT_RULES.md` as the Task-026～030 technical-risk reference and added ADR-0006 for backup provider / package strategy.
- Updated `docs/reference/FILE_STRUCTURE.md`, ADR-0002, and ADR-0004 for Task-026a scope and deferred work.

### Scope Boundary
- Task-026a does not implement production Google Drive API, OAuth client ID, reversed client ID URL scheme, Google SDK dependency, `GoogleService-Info.plist`, Drive scope authorization, remote upload, remote download, background sync, cross-device merge, server verification, production token refresh / revocation, or production Keychain token policy.
- Task-026a does not implement restore preview, destructive restore, automatic overwrite, `remoteWins`, `mergeByDate`, CloudKit, iCloud sync, AirDrop `.skatetrack` package, macOS import viewer, StoreKit production, signing, capabilities, entitlements, provisioning, Bundle ID, Launch Screen, AppIcon, bottom dock, watchOS UI, macOS UI, GPSProvider, IMUProvider, SensorFusionEngine, or FallDetectionEngine changes.
- Local backup export is user-initiated and uses a temporary local JSON package plus the iOS system share sheet. It must not be described as cloud sync.

### Deferred from Task-026a
- Task-026b should implement local restore preview, validation, and explicit conflict-policy confirmation before any local data can be overwritten.
- Real Google Drive provider integration remains blocked until Google Sign-In production, OAuth credentials, Drive API scopes, privacy copy, token lifecycle, logout / revocation behavior, and server verification strategy are ready.
- Task-027 should define the portable `.skatetrack` export / AirDrop package separately from the Task-026a backup package.
- Task-028 should consume the future export package from a macOS viewer without reusing iOS navigation or hardcoding sandbox paths.
- Task-029 and Task-030 should consult `docs/process/DEVELOPMENT_RULES.md` for localization, accessibility, privacy, mock-provider, and release-readiness checks.

### Validation Notes
- Run `python3 scripts/verify_backup_sync.py` after applying this task.
- Also run localization, shared-model, account-provider, and subscription entitlement simulation verification scripts.
- Xcode validation should confirm the iOS target compiles, the Account screen shows 「備份與同步」, the local backup share sheet opens, and no Google OAuth / Drive permission / signing prompt appears.

## 2026-06-12 Task-026b — Local Restore Preview + Conflict Policy Simulation

### Completed

- Added `BackupRestorePreview` shared preview models for non-destructive restore inspection.
- Added `BackupPackageDecoder` to validate local backup files with `schemaVersion == 1` and `packageType = backup` before previewing contents.
- Extended `CloudBackupProvider` with a restore-preview boundary while keeping Views behind `useBackupSync`.
- Added `BackupRestorePreviewView` to the Account → Backup UI so users can choose a local `.skatetrack-backup.json` file and inspect section counts / validation issues.
- Added `.fileImporter`-based local file selection using JSON / data types only; no custom UTType, capabilities, or entitlements were added.
- Displayed conflict-policy simulation: `localWins` is the only safe policy represented in Task-026b, while `remoteWins` and `mergeByDate` remain deferred.
- Added `verify_backup_restore_preview.py` and updated documentation / localization for restore preview.

### Safety Notes

- Task-026b is intentionally non-destructive. It never writes sessions, equipment, spots, achievement unlocks, or weekly challenge completion records back to Core Data or UserDefaults.
- The preview decodes each store independently so one corrupted section can be shown as a validation issue without crashing the whole screen.
- Google Drive restore, Drive download, OAuth, Drive scopes, production token lifecycle, and server verification remain blocked by the same external-service constraints recorded in ADR-0002 and ADR-0006.

### Deferred from Task-026b

- Real restore execution, local overwrite, local database replacement, and UserDefaults replacement.
- `remoteWins` implementation and any UX that replaces local data with backup data.
- `mergeByDate` implementation and cross-device conflict resolution.
- Google Drive download / restore, background sync, Drive provider integration, OAuth / Drive scopes, and server verification.
- AirDrop `.skatetrack` package import / export and macOS package viewer remain Task-027 / Task-028.

## 2026-06-12 — Task-026c-blocked + Task-027a Portable `.skatetrack` Export Package Foundation

### Completed

- Documented Task-026c as intentionally blocked rather than skipped. Google Drive production integration remains gated by Google OAuth credentials, Drive scope decisions, token lifecycle, privacy copy, and signing / URL-scheme review.
- Added `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` to track pre-Apple-Developer-Program and external-credential limitations through Task-030 readiness.
- Added `SkateTrackPackageManifest` and `SkateTrackPackagePayload` to define a portable `packageType = export` package separate from Task-026 backup packages.
- Added platform-neutral `Shared/Export/SkateTrackPackageWriter.swift` and `Shared/Export/SkateTrackPackageReader.swift`. These helpers accept caller-provided URLs and do not hardcode iOS temporary paths, macOS sandbox paths, or platform import UI.
- Added `SkateTrackPackageExportProvider` and `SkateTrackPackageExportViewModel` so iOS Session Summary can create a single-session `.skatetrack` file through a hook/provider boundary.
- Added `SessionPackageExportActionView` to the unlocked Session Summary share section, using the existing iOS system share sheet bridge to share the `.skatetrack` file.
- Added `scripts/verify_skatetrack_package.py` and ADR-0007 to guard package schema, provider boundaries, localization, docs, no account/achievement data leakage, and no custom UTType / signing changes.

### Scope Boundary

- Task-027a exports a single session package only. It does not implement batch export, raw-motion-sample toggles, privacy trimming UI, import / restore, merge behavior, incoming file handling, or macOS viewer UI.
- Task-027a does not declare a custom UTType, add document association, edit Info.plist exported type declarations, or change signing, capabilities, entitlements, provisioning, or Bundle ID.
- Task-027a does not add Google Drive upload / download, Google OAuth / Drive scopes, Google SDK dependencies, external-service secrets, CloudKit / iCloud sync, production StoreKit, watchOS UI, Launch Screen, AppIcon, bottom dock, GPSProvider, IMUProvider, SensorFusionEngine, or FallDetectionEngine changes.

### Deferred from Task-027a

- macOS Import Stub, package preview UI, `NSOpenPanel`, drag-and-drop import, and full macOS viewer move to Task-027b / Task-028.
- Custom UTType declaration and document association remain deferred until signing impact and incoming-file UX are reviewed.
- Batch Session export, package privacy options, import into local data stores, package merge, and cross-device transfer remain future tasks.
- Task-026c production Google Drive provider remains blocked and must be implemented behind `CloudBackupProvider` only after credentials, scopes, privacy copy, token lifecycle, and signing review are ready.

### Validation Notes

- Run `python3 scripts/verify_skatetrack_package.py` after applying this task.
- Also run localization, shared-model, backup, account, and subscription entitlement verification scripts to ensure Task-027a does not regress earlier provider boundaries.
- Manual validation should confirm the Session Summary share section shows a `SkateTrack 檔案` export action for unlocked share-card access, opens the iOS system share sheet, and produces a `.skatetrack` file without Google, OAuth, or signing prompts.


## Task-027-preflight — Real-device GPS background recording diagnostics

- Paused Task-027b macOS import work after iPhone 13 Pro real-device testing showed a session could preserve an initial map point but lose route / speed after the screen was turned off.
- Confirmed the likely root cause was incomplete locked-screen / background location support rather than Google Drive, backup, export, or mock-speed work.
- Added generated Info.plist `UIBackgroundModes = location` for the iOS app target so Core Location can deliver active ride updates while the screen is off.
- Updated `GPSProvider` to enable `allowsBackgroundLocationUpdates` and the background location indicator only when the bundle declares the location background mode.
- Updated `GPSProvider` to disable automatic location pausing during active ride recording, request an Always authorization upgrade after When In Use permission is available, accept outdoor fixes up to 35 m accuracy, and derive speed from consecutive GPS fixes when `CLLocation.speed` is unavailable.
- Updated `SensorFusionEngine` to emit location-driven motion samples from GPS callbacks so background location delivery can still preserve route data if the normal 10 Hz timer is throttled.
- Added live sample counters to `LiveSessionMetrics`, `SessionMetricsAccumulator`, and `useSessionRecording` so debugging can distinguish zero speed from missing GPS-backed samples.
- Added a real-device recording notice to the Session Start screen explaining that locked-screen recording now depends on Always / Precise Location permission and that the app should not be force-quit during a session.
- Added `scripts/verify_gps_background_recording.py`.
- Added ADR-0008 to document the real-device background GPS strategy.

### Deferred from Task-027-preflight

- Full battery profiling and power policy tuning remain deferred.
- A dedicated runtime diagnostics screen for precise location, accepted / rejected GPS fix counts, last GPS sample age, and route confidence remains deferred.
- App Store privacy review copy for production release readiness remains deferred.
- Recovery after force quit or system termination remains deferred.
- Indoor / GPS-denied odometry, IMU-only route drawing, ARKit route tracking, UWB venue tracking, fake route generation, and fake speed generation remain explicitly out of scope.

## 2026-06-12 — Task-027b macOS Import Stub + Package Preview

### Completed
- Replaced the Task-002 macOS placeholder with `MacRootView`, an independent `NavigationSplitView` shell that does not reuse iOS `RootNavigationView` or bottom-dock navigation.
- Added `MacImportView` using macOS `NSOpenPanel` to let the user choose a `.skatetrack` file for read-only preview.
- Reused `Shared/Export/SkateTrackPackageReader.swift` and the Task-027a portable package schema so macOS validates `schemaVersion = 1` and `packageType = export` instead of inventing a second reader.
- Added `MacPackageImportViewModel` with security-scoped file access, extension validation, package error mapping, and no database writes.
- Added `MacPackagePreviewView` to display manifest details, session count, motion sample count, route sample count, duration, distance, speeds, moving ratio, export time, and privacy notes.
- Added `MacLockedFeatureCardView` so incomplete macOS features use one consistent locked / coming-soon pattern before the Task-029 accessibility pass.
- Added localized English and Traditional Chinese copy for macOS import, preview, locked cards, and validation errors.
- Added `scripts/verify_macos_package_preview.py` to verify macOS shell independence, NSOpenPanel usage, package-reader reuse, localization, docs, project membership, and no custom UTType / document association / production cloud-service changes.
- Updated `docs/reference/FILE_STRUCTURE.md` and ADR-0007 to distinguish Task-027b read-only package preview from Task-028 full macOS viewer work.

### Scope Boundary
- Task-027b does not import package data into local storage, restore backups, merge sessions, persist imported files, create a session database, generate charts, draw maps, export PDF / CSV reports, or implement drag-and-drop import.
- Task-027b does not declare `UTExportedTypeDeclarations`, `CFBundleDocumentTypes`, custom `.skatetrack` UTType metadata, incoming document association, open-in-place handling, iCloud documents, CloudKit, Google Drive sync, OAuth, Google SDKs, production StoreKit, or paid unlock logic.
- Task-027b does not change signing, provisioning, Bundle ID, entitlements, App Groups, iCloud containers, Launch Screen, AppIcon, bottom dock, iOS runtime, watchOS runtime, GPSProvider, IMUProvider, SensorFusionEngine, or FallDetectionEngine.
- The macOS import flow is intentionally user-initiated and read-only. It must be described as a package preview stub, not as completed cross-device sync or completed macOS analytics.

### Deferred from Task-027b
- Task-028 should build the full macOS shell / Phase 1a viewer on top of this import preview, including a more complete session viewer, route / chart placeholders or initial views, session browser structure, and Focus Mode direction from the PRD.
- Drag-and-drop import, persistent security-scoped bookmarks, document association, custom UTType registration, Finder open-with behavior, batch import, package merge, local database import, report export, and AI / video analysis remain later macOS work.
- Google Drive upload / download and cloud sync remain blocked under Task-026c until OAuth credentials, minimum Drive scopes, privacy copy, token lifecycle, and signing review are ready.
- iPhone 13 Pro outdoor locked-screen GPS validation remains a Task-030 release-readiness gate, even though simulator GPS package-export data is now usable for Task-027b development.

### Validation Notes
- Run `python3 scripts/verify_macos_package_preview.py` after applying this task.
- Also run `python3 scripts/verify_skatetrack_package.py`, `python3 scripts/verify_localization_keys.py`, and existing macOS AppIcon verification.
- Xcode validation should include a macOS build and a manual check that selecting an iOS-exported `.skatetrack` file shows manifest and session preview without adding document associations or changing signing / capabilities.

## 2026-06-12 — Task-027b Mac UI Stability Hotfix

### Completed
- Stabilized the macOS Task-027b shell after manual testing showed the `NavigationSplitView` sidebar could jump, hide other destinations, or become difficult to scroll after selecting locked / coming-soon destinations.
- Replaced the sidebar `List(selection:)` implementation with a fixed custom sidebar inside the existing `NavigationSplitView`, keeping the macOS navigation architecture while avoiding selection-driven sidebar scroll collapse.
- Made the sidebar selection non-optional and kept `NavigationSplitViewVisibility = .all` so selecting `Session Browser`, `Analytics`, `Video Overlay`, or `Cloud Sync` only changes the detail pane and does not rebuild or collapse the sidebar.
- Added explicit titlebar-safe top spacing to the sidebar and import detail content so macOS traffic-light window controls remain visually above the content area.
- Kept Task-027b read-only: no package import into storage, no document association, no custom UTType, no Google Drive / CloudKit / StoreKit production behavior, and no signing / capability changes.

### Validation Notes
- Re-run `python3 scripts/verify_macos_package_preview.py` after applying this hotfix.
- Manual validation should click every sidebar destination repeatedly, confirm all sidebar rows remain visible and scrollable, confirm the macOS traffic-light controls are not visually covered, and then re-open a `.skatetrack` package preview.

## 2026-06-12 — Task-028a macOS Read-only Session Viewer Foundation

### Completed
- Promoted the macOS sidebar `Session Browser` destination from a locked placeholder to a read-only viewer for the currently opened `.skatetrack` package.
- Moved the package preview state to `MacRootView` via a shared `MacPackageImportViewModel`, so `MacImportView` and `MacSessionBrowserView` read the same validated package without writing any local storage.
- Added `MacSessionBrowserView` with a package-scoped session list and selected-session detail pane.
- Added `MacSessionDetailView` to show session title, mode, power type, package file, duration, distance, max speed, average speed, moving ratio, motion sample count, route sample count, exported time, route summary, and privacy boundary.
- Added `MacSessionViewerModel` to derive read-only metrics from package motion samples when older exports have route / speed samples but empty summary metrics.
- Added `MacSpeedSparklineView`, a lightweight SwiftUI `Path` speed preview that avoids introducing Swift Charts before Task-028b.
- Updated `MacPackagePreviewView` so package preview can also use viewer-derived metrics and now points users to the sidebar Session Browser instead of saying the viewer is fully locked.
- Added localized English and Traditional Chinese copy for the macOS Session Browser, derived-metric notice, route summary, speed preview, empty states, and read-only privacy boundary.
- Added `scripts/verify_macos_session_viewer.py` and updated `scripts/verify_macos_package_preview.py` for the shared preview state and Task-028a viewer boundary.
- Updated ADR-0007, `docs/reference/FILE_STRUCTURE.md`, and `docs/process/DEVELOPMENT_RULES.md` to record the Task-028a split from future Task-028b visualization work.

### Scope Boundary
- Task-028a remains a read-only package viewer. It does not import package data into Core Data, merge sessions, restore backups, persist security-scoped bookmarks, sync cloud state, or modify the selected `.skatetrack` package.
- Task-028a does not introduce MapKit route rendering, Swift Charts, heat maps, session comparison, calendar / filter views, CSV / PDF export, drag-and-drop import, Finder open-with behavior, custom UTType registration, document association, Focus Mode, video overlay editing, or AI analysis.
- Task-028a does not change signing, provisioning, Bundle ID, entitlements, iCloud containers, Google Drive, CloudKit, StoreKit production, iOS runtime, GPSProvider, SensorFusionEngine, FallDetectionEngine, Launch Screen, AppIcon, bottom dock, or watchOS runtime.

### Deferred from Task-028a
- Task-028b should decide whether to add MapKit route visualization, Swift Charts / richer charts, or continue with lightweight SwiftUI visualizations after a macOS build and UX check.
- Session filtering, multi-session comparison, persistent imports, report export, drag-and-drop import, document association, custom UTType, Finder open-with behavior, Focus Mode, AI analysis, and video overlay remain later macOS tasks.
- iPhone 13 Pro outdoor locked-screen GPS validation remains a Task-030 release-readiness gate.

### Validation Notes
- Run `python3 scripts/verify_macos_session_viewer.py` after applying this task.
- Also re-run `python3 scripts/verify_macos_package_preview.py`, `python3 scripts/verify_skatetrack_package.py`, `python3 scripts/verify_localization_keys.py`, `python3 scripts/verify_macos_appiconset.py`, and `python3 scripts/verify_shared_models.py`.
- Xcode validation should include a macOS build and an iOS build to confirm shared model and project membership changes did not regress either platform.

## 2026-06-12 — Task-028a macOS Session Viewer Layout Polish

### Completed
- Refined the Task-028a macOS read-only Session Viewer after manual testing showed the first viewer layout was functionally correct but too iOS-like for a desktop viewer.
- Narrowed the middle Session list column so it behaves like a true browser list instead of a second primary content pane.
- Converted the right-side Session detail into a more compact macOS dashboard with a shorter header, denser metrics grid, smaller cards, and a shorter speed sparkline.
- Grouped route summary and privacy boundary into compact responsive sections so the user can see more of the Session at the top of the window before Task-028b adds route / chart visualization.

### Scope Boundary
- This layout polish is presentation-only. It does not change package schema, package decoding, derived metrics, storage, import behavior, route calculation, MapKit, Charts, custom UTType, document association, signing, capabilities, Google Drive, CloudKit, StoreKit production, iOS runtime, GPS, FallDetection, or watchOS behavior.

### Validation Notes
- Run `python3 scripts/verify_macos_session_viewer.py`, `python3 scripts/verify_macos_package_preview.py`, and `python3 scripts/verify_localization_keys.py` after applying this polish.
- Manual validation should confirm the Session Browser reads as a compact macOS dashboard rather than a large mobile-style card stack.

## 2026-06-12 — Task-028a macOS Session Viewer Layout Restructure

### Completed
- Restructured the macOS Session Browser from the earlier three-column prototype into a right-side stacked layout: the left sidebar remains the function-area navigation, while the main viewer uses a compact package-session summary above the detailed Session dashboard.
- Removed the separate middle `Package Sessions` column for the normal single-session package flow so the empty list area no longer consumes desktop space.
- Added a compact `MacCurrentPackageSessionSummaryView` at the top of `MacSessionBrowserView` for the currently opened package session, with a horizontal selector only when a future package contains multiple sessions.
- Kept `MacSessionDetailView` focused on the bottom dashboard area: metrics, speed preview, route summary, and privacy boundary.
- Preserved Task-028a read-only boundaries: no database import, no package rewrite, no MapKit / Charts, no document association, no custom UTType, and no signing / capability changes.

### Validation Notes
- Re-run `python3 scripts/verify_macos_session_viewer.py` after applying this layout restructure.
- Manual validation should confirm the top package-session summary does not truncate important file / session information, the bottom dashboard uses the primary vertical space, and the left sidebar remains stable.

## 2026-06-12 — Task-028b macOS Route / Chart Visualization Foundation

### Completed
- Extended the Task-028a read-only macOS Session Viewer with a lightweight route / chart visualization foundation while preserving the right-side stacked dashboard layout learned from the Task-028a layout review.
- Added `MacRoutePreviewView`, a normalized SwiftUI `Path` route preview that draws the package route shape from GPS samples without using system map frameworks, road matching, heat maps, or route editing.
- Added viewer-side route points and route quality classification in `MacSessionViewerModel`, including route sample count, effective route point count, derived distance, and unavailable / limited / usable route states.
- Upgraded the speed preview copy to a speed chart foundation and increased its chart height so route and speed visualization remain legible in the macOS dashboard.
- Updated `MacSessionDetailView` so the lower dashboard shows metrics first, then route preview and speed chart, followed by route data and privacy / read-only boundary.
- Added `scripts/verify_macos_route_chart_viewer.py` and updated `scripts/verify_macos_session_viewer.py` to guard against MapKit / Charts / document-association / persistence regressions.
- Verified the uploaded successful simulator package (`SkateTrack-Session-20260612-180037.skatetrack`) contains non-zero distance, speed, GPS samples, and drawable route data suitable for Task-028b development.

### Scope Boundary
- Task-028b remains a read-only package viewer. It does not import sessions into Core Data, merge packages, restore backups, rewrite `.skatetrack` files, persist security-scoped bookmarks, add Finder open-with behavior, declare custom UTType, or add document association.
- Task-028b intentionally avoids system map rendering frameworks and full chart frameworks in this phase. Road matching, heat maps, map overlays, multi-session comparison, report export, and route editing remain deferred.
- No signing, provisioning, Bundle ID, entitlements, iCloud containers, Google Drive, CloudKit, StoreKit production, iOS runtime, GPSProvider, SensorFusionEngine, FallDetectionEngine, Launch Screen, AppIcon, bottom dock, or watchOS runtime changes are included.

### Validation Notes
- Run `python3 scripts/verify_macos_route_chart_viewer.py` after applying this task.
- Also re-run `python3 scripts/verify_macos_session_viewer.py`, `python3 scripts/verify_macos_package_preview.py`, `python3 scripts/verify_skatetrack_package.py`, `python3 scripts/verify_localization_keys.py`, `python3 scripts/verify_shared_models.py`, and `python3 scripts/verify_macos_appiconset.py`.
- Manual validation should open both an older low-data package and a successful simulator package with non-zero distance. The low-data package should show a useful empty / unavailable route state, while the successful package should show a route shape and speed chart without compressing dashboard text.

## 2026-06-12 — Task-029a Japanese Localization + Privacy Copy Gate

### Completed
- Added Japanese as the third active localization language with `Shared/Localization/ja.lproj/Localizable.strings` and `Shared/Localization/ja.lproj/InfoPlist.strings`.
- Added Japanese permission copy for When In Use location, Always / background location, motion sensors, and add-only Photos saving.
- Updated the Xcode project localization variant groups so `ja` is included in `knownRegions` and both `Localizable.strings` / `InfoPlist.strings` have Japanese variants.
- Expanded `scripts/verify_localization_keys.py` to verify English, Traditional Chinese, and Japanese key parity, placeholder parity, `.strings` syntax, InfoPlist key parity, and project membership.
- Added `scripts/verify_task029_localization_privacy.py` as the Task-029a quality gate for Japanese localization, critical privacy / deferred-service copy, InfoPlist permission copy, docs alignment, and no document / cloud capability drift.
- Added ADR-0009 to document the localization and privacy-copy strategy.
- Documented that localization resource files are not governed by the Swift 500-line guideline; they are governed by key parity, placeholder parity, syntax validity, and privacy-copy correctness instead.
- Added the deferred localization roadmap: `pt-BR` Brazilian Portuguese and `es` Spanish remain deferred until after Japanese QA and native-review workflow are stable.

### Scope Boundary
- Task-029a does not add new product features, account providers, Google OAuth, Google Drive sync, CloudKit / iCloud, StoreKit production, Finder document association, custom UTType, report export, MapKit, Charts, iOS runtime changes, GPS changes, FallDetection changes, watchOS changes, signing changes, provisioning changes, or new entitlements.
- Japanese localization is an initial product pass and still requires native review before App Store release.

### Validation Notes
- Run `python3 scripts/verify_localization_keys.py` and `python3 scripts/verify_task029_localization_privacy.py` after applying this task.
- Also run the existing platform verification scripts and at least one iOS + macOS build because localization membership touches the Xcode project file.

## 2026-06-12 — Task-029b Accessibility / Privacy / UX Quality Gate

### Completed
- Added a Task-029b quality gate for accessibility labels, privacy-copy guardrails, and macOS layout guardrails after Japanese localization and macOS route / speed visualization were completed.
- Replaced remaining hard-coded accessibility copy for the iOS DEBUG tools entry and Live HUD emergency contacts entry with localized keys.
- Added a localized Live HUD status accessibility label so VoiceOver receives a clearer status summary entry point during active sessions.
- Added macOS accessibility labels / hints for the current package-session summary, read-only session detail dashboard, route preview, and speed chart.
- Added route preview accessibility value copy that summarizes route sample count, unique route points, and derived distance without implying MapKit, road matching, or heat map support.
- Added `scripts/verify_task029b_accessibility_privacy_gate.py` to protect Task-029b accessibility, privacy, read-only package boundaries, macOS layout guardrails, and no document / cloud capability drift.
- Added ADR-0010 to document the accessibility, privacy, and UX quality gate strategy before Task-030 release readiness.

### Scope Boundary
- Task-029b does not add new product features, MapKit, Charts, Google Drive, Google OAuth, CloudKit / iCloud, StoreKit production, document association, custom UTType, report export, persistent import, backup restore execution, merge behavior, GPS algorithm changes, FallDetection changes, Launch Screen changes, AppIcon changes, bottom dock changes, watchOS runtime changes, signing changes, provisioning changes, or new entitlements.
- The macOS viewer remains a read-only package viewer. Route and speed visualization remain lightweight SwiftUI Path-based previews.

### Deferred from Task-029b
- Full VoiceOver walkthrough on a physical iPhone and macOS device.
- Dynamic Type / large-text visual QA across all iOS and macOS screens.
- Native Japanese accessibility-copy review.
- `pt-BR` Brazilian Portuguese and `es` Spanish localization remain deferred roadmap items.
- MapKit, road matching, heat maps, Swift Charts, multi-session comparison, report export, and package library remain later tasks.

### Validation Notes
- Run `python3 scripts/verify_task029b_accessibility_privacy_gate.py` after applying this task.
- Also run `python3 scripts/verify_localization_keys.py`, `python3 scripts/verify_task029_localization_privacy.py`, `python3 scripts/verify_macos_session_viewer.py`, `python3 scripts/verify_macos_route_chart_viewer.py`, `python3 scripts/verify_skatetrack_package.py`, and platform builds.
- Manual validation should use English, Traditional Chinese, and Japanese app language settings and confirm that long Japanese labels do not overlap, truncate critical meaning, or cover macOS window controls.


## 2026-06-13 — Task-030a Pre-ADP Release Readiness Audit + Verify Gate

### Completed
- Added `docs/release/RELEASE_READINESS_PRE_ADP.md` as the Task-030a source of truth for Pre-ADP release posture, verify scripts, build commands, source-control hygiene, service boundaries, GPS / safety gates, and macOS viewer gates.
- Added `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` to consolidate iOS, macOS, localization, accessibility, privacy, background GPS, Fall Detection, and service-boundary manual QA.
- Added `scripts/verify_task030_release_readiness.py` to guard release-readiness documentation, known limitations, local Xcode scheme hygiene, service-boundary terms, and absence of custom UTType / document association / entitlement drift.
- Added ADR-0011 to define the Pre-ADP release-readiness strategy and keep Task-030 focused on quality gates rather than feature expansion.
- Expanded `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` with CloudKit / iCloud, real-device background GPS validation, Fall Detection diagnostics / safe test mode, native Japanese review, and deferred `pt-BR` / `es` localization roadmap items.

### Scope Boundary
- Task-030a is documentation and verification only. It does not add runtime UI, product features, provider integrations, production credentials, signing changes, provisioning changes, entitlements, custom `.skatetrack` UTType, Finder open-with behavior, document association, CloudKit, StoreKit production, Google OAuth / Drive, WeatherKit production, TestFlight upload, GPS algorithm changes, FallDetection algorithm changes, Launch Screen changes, AppIcon changes, bottom dock changes, watchOS changes, or macOS viewer feature expansion.

### Release-blocking Notes
- iPhone 13 Pro or equivalent outdoor real-device background GPS test remains required before public release claims. Simulator success is not enough for background-location release validation.
- Fall Detection must not be validated by unsafe human hard-fall testing; future diagnostics / safe controlled protocol is required before stronger safety claims.
- Japanese localization remains first-pass and needs native review before public App Store release.

### Validation Notes
- Run `python3 scripts/verify_task030_release_readiness.py` after applying this task.
- Also run the existing Task-029 localization / privacy / accessibility gates, macOS viewer gates, package gates, backup gates, account provider gate, GPS gate, shared model gate, and iOS / macOS platform builds.
- Confirm `.xcscheme` files do not include local App Language, App Region, or Location Scenario state before commit.

## 2026-06-13 — Task-030b Documentation Consolidation + Deferred Feature Handoff Package

### Completed
- Added `docs/DOCUMENTATION_INDEX.md` as the documentation entry point and reading order for future human / ChatGPT / Cursor handoffs.
- Added `docs/process/DEVELOPMENT_RULES.md` to consolidate recurring development workflow, hotfix, commit, localization, macOS layout, documentation, and scope-control rules.
- Rewrote `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` as the consolidated Pre-ADP deferred-feature and unlock-condition source of truth.
- Added `docs/adr/ADR-INDEX.md` to preserve historical ADR decisions after removing the old per-topic ADR files from active docs.
- Updated `docs/release/RELEASE_READINESS_PRE_ADP.md`, `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md`, `docs/reference/FILE_STRUCTURE.md`, and `scripts/verify_task030_release_readiness.py` for the consolidated documentation structure.
- Consolidated and retired the former root-level `docs/DEVELOPMENT_RULES.md` as an active root document after moving it to `docs/process/DEVELOPMENT_RULES.md`.

### Scope Boundary
- Task-030b is documentation and verification only. It does not modify iOS runtime, macOS runtime, Swift source, localization resources, project signing, capabilities, entitlements, custom UTType, document association, StoreKit production, Google OAuth / Drive, CloudKit / iCloud, WeatherKit production, GPS algorithms, FallDetection algorithms, Launch Screen, AppIcon, bottom dock, or watchOS.

### Removal / Consolidation Notes
- Old ADR files `ADR-0001` through `ADR-0011` are consolidated into `docs/adr/ADR-INDEX.md`, `docs/process/DEVELOPMENT_RULES.md`, and `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`.
- The previous Task 026–030 technical-risk notes are consolidated into the active development rules, known limitations, release readiness, and manual QA documents.
- `docs/history/DEV_LOG.md` remains the chronological history source, not the primary rules source.

### Validation Notes
- Run `python3 scripts/verify_task030_release_readiness.py` after applying this task and deleting the consolidated old ADR / technical-risk files.
- Confirm `git status --short` does not contain unzipped hotfix folders, `.xcscheme` local QA state, simulator exports, or sample `.skatetrack` files.

## 2026-06-13 — Task-030b Verify Script Consolidation Fix

### Completed
- Updated legacy verify scripts that still referenced retired per-topic ADR files and previous Task 026–030 technical-risk notes after Task-030b documentation consolidation.
- Redirected active verification checks to consolidated documentation sources: `docs/process/DEVELOPMENT_RULES.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`, `docs/release/RELEASE_READINESS_PRE_ADP.md`, `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md`, and `docs/adr/ADR-INDEX.md`.
- Strengthened `scripts/verify_task030_release_readiness.py` so future documentation consolidation regressions fail when verify scripts still reference retired documentation paths.

### Reason / Context
- Task-030b intentionally removed the old ADR single files and the stage-specific technical-risk note.
- Several older verify scripts still expected those retired files, causing the consolidated documentation check to pass while feature-specific verification scripts failed.

### Validation Notes
- Run `python3 scripts/verify_task030_release_readiness.py` first.
- Then run the standard localization, privacy, macOS viewer, package, backup, account, GPS, and shared-model verify scripts.

### Known Issues / Follow-up
- This fix does not restore retired ADR files; it keeps the consolidated documentation model active.
- Very old feature-specific scripts may still check historical feature tokens, but they must not require retired documentation paths.

## 2026-06-13 — Task-030b Documentation Directory Cleanup + Retired Path Fix

### Completed
- Organized active docs into human-readable subdirectories: `docs/process`, `docs/release`, `docs/adr`, `docs/reference`, and `docs/history`.
- Kept `docs/DOCUMENTATION_INDEX.md` as the root entry point while moving process, release, ADR, reference, and history files out of the crowded docs root.
- Updated verify scripts to read the new subdirectory paths instead of root-level docs or retired `docs/decisions` paths.
- Updated the release-readiness gate so old root-level docs, old per-topic ADR files, and previous Task 026–030 technical-risk notes cannot reappear as active source-of-truth files.

### Scope Boundary
- This cleanup is documentation and verification only. It does not modify iOS runtime, macOS runtime, Swift source, localization resources, project signing, capabilities, entitlements, custom UTType, document association, StoreKit production, Google OAuth / Drive, CloudKit / iCloud, WeatherKit production, GPS algorithms, FallDetection algorithms, Launch Screen, AppIcon, bottom dock, or watchOS.

### Validation Notes
- Run `python3 scripts/verify_task030_release_readiness.py` first.
- Then run the standard localization, privacy, macOS viewer, package, backup, account, GPS, and shared-model verify scripts.
- `docs/history/DEV_LOG.md` may contain historical mentions of old paths, but active docs and scripts must not depend on retired paths.
## 2026-06-14 — Snow-Task-001 Sport Mode Integration Foundation + Preflight

### Completed
- Added production `SnowDiscipline` and integrated `SportMode.snow(SnowDiscipline)` into the existing sport-mode model instead of creating a `SnowPrototype*` namespace.
- Added explicit `.snow` handling to sport-related switches in session start, live HUD, session history, session summary, sensor calibration priority planning, equipment compatibility boundaries, weather mock context, and equipment wear thresholds.
- Added minimal production Session Start snow discipline selection and localized `en` / `zh-Hant` / `ja` strings for Snow Sports, Snowboard, Skiing, mode descriptions, tags, and history filtering.
- Added `docs/process/PHASE_1C_SNOW_AGENT_STATE.md` as the Phase 1c production agent state record and `scripts/verify_snow_sport_enum.py` as the Snow sport integration gate.

### Scope Boundary
- Snow-Task-001 does not add SnowSegment / SnowRun persistence, Core Data migration, SnowSegmentClassifier, RunBoundaryDetector, Snow Live HUD, package compatibility, HealthKit export, WatchBridge wiring, signing changes, entitlements, or production service integrations.
- Existing skateboard and inline behavior remains additive-only; electric power remains skateboard-only.

### Validation Notes
- Run `python3 scripts/verify_snow_sport_enum.py`, `python3 scripts/verify_localization_keys.py`, and `python3 scripts/verify_shared_models.py` after applying this task.
- Snow-Task-001 verification token: production snow sport enum integrated.


## 2026-06-14 — Snow-Task-001a Debug-gated Snow Mode Entry

### Completed
- Kept production `SportMode.snow(SnowDiscipline)` and `SnowDiscipline` available for Snow-Task-002+ while hiding the normal user-facing Snow category from Release builds.
- Added `SessionStartSportCategory.userFacingCases` so DEBUG builds can still exercise Snow / Snowboard / Skiing from Session Start, while Release builds show only the currently supported public sport categories.
- Added a Debug Tools note clarifying that the Snow entry is DEBUG-only until Snow-Task-002 through Snow-Task-009 complete the production data path.
- Added `scripts/verify_snow_task_001a_debug_gate.py` to guard against accidentally exposing the Snow entry publicly before the production schema, classifier, detector, package, and fixture tasks are complete.

### Scope Boundary
- Snow-Task-001a does not remove or wrap `SportMode.snow` in `#if DEBUG`; the production enum remains available for follow-up data-model work.
- No `SnowPrototype*` namespace, WatchBridge wiring, Core Data migration, package compatibility, classifier, or RunBoundaryDetector work was added in this gate.

### Validation Notes
- Run `python3 scripts/verify_snow_sport_enum.py`, `python3 scripts/verify_snow_task_001a_debug_gate.py`, `python3 scripts/verify_localization_keys.py`, and `python3 scripts/verify_shared_models.py`.
- Snow-Task-001a verification token: snow mode public entry debug-gated.
Snow-Task-001b verification token: snow mode entry controlled by debug toggle.


## 2026-06-14 — Snow-Task-002 Snow Session Data Layer

### Completed
- Added production Snow Mode value types: `SnowSegmentType`, `SnowSegment`, `SnowRun`, `SnowDistanceBreakdown`, `SnowVerticalMetrics`, and `SnowSessionState`.
- Added additive Core Data entities `PersistedSnowRun` and `PersistedSnowSegment` through the existing programmatic model in `PersistenceController.makeManagedObjectModel()`.
- Updated the `.xcdatamodeld` schema reference and model version identifier to `Phase1cSnowTask002` while preserving automatic lightweight migration options.
- Added `SnowSessionRepository` and `SnowSessionEntityMapper` for repository-backed CRUD and aggregate Snow session state.
- Added `useSnowSession.swift` as the iOS data boundary for later Snow-Task-005 UI integration.
- Added `SnowSessionRepositoryTests.swift` and `scripts/verify_snow_schema.py` to verify repository persistence and schema registration.

### Scope Boundary
- Snow-Task-002 does not add `SnowSegmentClassifier`, `RunBoundaryDetector`, Snow UI, `.skatetrack` snow package compatibility, fixture generation, HealthKit export, WatchBridge wiring, signing, entitlements, or production service integrations.
- Snow Mode continues to avoid `SnowPrototype*` namespaces and `Shared/WatchBridge/*` changes.

### Validation Notes
- Run `python3 scripts/verify_snow_schema.py`, `python3 scripts/verify_snow_sport_enum.py`, `python3 scripts/verify_snow_task_001a_debug_gate.py`, `python3 scripts/verify_snow_task_001b_debug_toggle.py`, `python3 scripts/verify_localization_keys.py`, and `python3 scripts/verify_shared_models.py`.
- Snow-Task-002 verification token: production snow schema and repository boundary integrated.

## 2026-06-15 — Snow-Task-003 Snow Segment Classifier Foundation

### Completed
- Added `SnowClassifierConfig.productionV0` with centralized v0 thresholds for altitude smoothing, trend windows, hysteresis, downhill, ascent, stopped, walking, gondola, motion-energy, and derived-heading checks.
- Added `SnowSegmentClassification` and `SnowSegmentClassifier` as a rule-based classifier over existing `MotionSample` windows.
- Added fixture-driven tests covering clean downhill, lift ascent, gondola ascent, surface lift ascent, stopped, walking, noisy downhill altitude, ambiguous gondola-like descent, and missing-altitude movement.
- Added `scripts/verify_snow_classifier.py` to verify classifier registration, fixture coverage, no `SnowPrototype*`, no `Shared/WatchBridge/*`, no `.skatetrack` samples, and no `MotionSample` schema expansion.

### Scope Boundary
- Snow-Task-003 does not implement the run-boundary state machine, Snow UI, package compatibility, WatchBridge wiring, or `.skatetrack` fixtures.
- Snow-Task-003 does not modify `MotionSample` or Snow-Task-002 value types.

### Validation Notes
- Run `python3 scripts/verify_snow_classifier.py`, `python3 scripts/verify_snow_schema.py`, `python3 scripts/verify_snow_sport_enum.py`, `python3 scripts/verify_localization_keys.py`, and `python3 scripts/verify_shared_models.py`.
- Run `xcodebuild -project SkateTrack.xcodeproj -scheme SkateTrack-iOSTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` to capture fixture result lines beginning with `SnowClassifierFixtureResult`.
- Snow-Task-003 verification token: production snow segment classifier foundation integrated.

## Snow-Task-004 — RunBoundaryDetector foundation

- Added the production `RunBoundaryDetector` streaming state machine for Snow run boundaries.
- Added `RunBoundaryState`, `RunBoundaryConfig`, `RunBoundarySnapshot`, and `RunBoundaryEvent` as production model-layer boundaries.
- Added high-confidence lift/gondola/surface-lift fast-path run ending using `hardTransportEndConfidenceThreshold` and `hardTransportConfirmationSeconds`.
- Added fixture tests for run start confirmation, short-stop resume, long-stop run end, high-confidence lift fast-path, pending-end cancellation, low-confidence unknown, and v0 altitude-endpoint limitations.
- Kept `RunBoundaryDetector` pure and persistence-free; it does not call `SnowSessionRepository` directly.
- Deferred Snow Live HUD, UI wiring, real WatchBridge wiring, and `.skatetrack` package compatibility to later Snow tasks.

Snow-Task-004 verification token: RunBoundaryDetector state machine added without classifier/schema/WatchBridge scope creep.

## 2026-06-16 — Snow-Task-005 iPhone Snow UI Production Wiring

### Completed
- Added the production iPhone Snow live data boundary for Snow Mode recording without creating a `SnowPrototype*` namespace.
- Added `SnowLiveSessionConfig`, `SnowLiveSessionState`, `SnowClassificationWindowBuffer`, `SnowLiveSessionCoordinator`, `SnowLiveHUDState`, and `SnowLiveHUDStateMapper`.
- Defined the iPhone `lowConfidence` HUD policy through `SnowLiveSessionConfig.productionV0.lowConfidenceThreshold`, sourced from `SnowClassifierConfig.productionV0.mediumConfidenceThreshold`, so Snow UI code does not hardcode confidence literals.
- Wired `SessionRecordingCoordinator` to start, pause, resume, finish, reset, and feed MotionSample windows into the Snow live coordinator only for `.snow(...)` sessions.
- Exposed live Snow state through `useSessionRecording` / `useSnowLiveSession` while keeping `useSnowSession` repository-backed for persisted history.
- Added four-state iPhone `SnowHUDView` UI: downhill, lift / gondola, waiting, and low confidence.
- Added repository-backed Snow summary surfaces: `SnowDaySummaryView`, `SnowSegmentTimelineView`, and `SnowDistanceInspectorView`.
- Added localized Snow HUD / summary / timeline / inspector keys for `en`, `zh-Hant`, and `ja`.
- Added `scripts/verify_snow_iphone_ui.py` as the Snow-Task-005 verification gate.
- Added `scripts/create_snow_task005_review_pack.sh` to generate the Snow-Task-005 Claude review pack after final local verification.

### Scope Boundary
- Snow-Task-005 does not modify `RunBoundaryDetector`, `SnowSegmentClassifier`, `SnowClassifierConfig`, `MotionSample`, or Snow-Task-002 value types.
- Snow-Task-005 does not touch `Shared/WatchBridge/*`, does not implement watchOS UI, does not implement WatchBridge real-data wiring, and does not add `.skatetrack` sample files.
- Snow-Task-005 uses `/Users/doggo/Documents/App軟體區/SkateTrack-SnowPrototype` only as read-only visual / copy reference; no production `SnowPrototype*` namespace is introduced.

### Deferred Items
- Manual correction persistence is deferred because editing `SnowSegment.manualOverride` requires a separate UX and persistence task.
- Real WatchBridge snow data wiring and any Watch low-confidence payload are deferred to Snow-Task-006b after mainline Task-040.
- True altitude confidence scoring is deferred because `MotionSample` v0 still lacks vertical accuracy, GPS altitude, and altitude source metadata.
- Live provisional timeline before `runEnded` is deferred because `RunBoundaryDetector` v0 finalizes segments at run-boundary events.

### Validation Notes
- Run `python3 scripts/verify_snow_iphone_ui.py`, `python3 scripts/verify_snow_run_boundary.py`, `python3 scripts/verify_snow_classifier.py`, `python3 scripts/verify_snow_schema.py`, and `python3 scripts/verify_snow_sport_enum.py`.
- Run targeted iOS XCTest for `SnowLiveSessionConfigTests`, `SnowLiveHUDStateMapperTests`, and `SessionRecordingCoordinatorTests`.
- Run `xcodebuild build -project SkateTrack.xcodeproj -scheme SkateTrack-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
- Manual smoke testing confirmed Snow toggle, Snow session HUD routing, Snow summary empty / zero state, and non-Snow HUD preservation.

Snow-Task-005 verification token: production iPhone Snow UI wired to live Snow boundary without classifier/schema/WatchBridge scope creep.

## 2026-06-17 — Snow-Task-006a Mock-backed Watch Snow UI

### Completed
- Added the production-safe Watch Snow data contract `WatchSnowSessionSnapshot` as the Watch UI equivalent of the Addendum's prototype session field contract, without introducing a `SnowPrototype*` production namespace.
- Added the watchOS Snow data-source boundary: `WatchSnowSessionDataSource`, `WatchSnowMockScenario`, and the DEBUG-only `WatchSnowMockSessionProvider`.
- Added `WatchSnowHapticIntent`, `WatchSnowHapticIntentObserver`, and `WatchSnowHapticEngine` so mock scenario transitions can expose haptic intent without WatchBridge / WatchConnectivity dependencies.
- Added mock-backed Watch Snow UI surfaces: root, mock gallery, live speed, carousel, lift / gondola, waiting, low-confidence, fall-alert, summary, controls, metric chip, style, formatter, and Release-safe unavailable view.
- Routed `SkateTrackWatchApp` to `WatchSnowRootView`; DEBUG builds show the mock gallery, while Release builds keep a neutral unavailable fallback until real Watch integration exists.
- Added localized `snow.watch.*` keys for English, Traditional Chinese, and Japanese.
- Added `scripts/verify_snow_watch_ui.py` as the Snow-Task-006a verification gate.
- Added `scripts/create_snow_task006_review_pack.sh` to generate the Snow-Task-006a Claude review pack after final local verification.

### Scope Boundary
- Snow-Task-006a does not touch `Shared/WatchBridge/*`, does not import WatchConnectivity, does not reference `WCSession`, and does not implement `WatchSessionCoordinator` or real iPhone-to-Watch Snow metrics.
- Snow-Task-006a does not modify `SessionRecordingCoordinator`, `useSessionRecording`, `useSnowLiveSession`, `SnowLiveSessionCoordinator`, `MotionSample`, `RunBoundaryDetector`, `SnowSegmentClassifier`, or Snow-Task-002 value types.
- Snow-Task-006a uses SnowPrototype source only as read-only UI / scenario reference; production files use `WatchSnow*` names instead of `SnowPrototype*` names.
- Snow-Task-006a does not add `.skatetrack` sample files, HealthKit integration, emergency contact integration, signing changes, entitlements, or production complication timeline data.

### Deferred Items
- Snow-Task-006b real WatchBridge / WatchConnectivity wiring remains deferred until mainline Task-040 is complete and `feature/snow-mode` is rebased or merged onto post-Task-040 `develop`.
- The future 006b adapter should map real WatchBridge Snow payloads into `WatchSnowSessionSnapshot` while keeping Watch views unchanged.
- Mock scenario switching, subscriber toggling, and fall-alert screens are DEBUG / preview QA surfaces only; they are not production sensor or safety integrations.

### Validation Notes
- Run `python3 scripts/verify_snow_watch_ui.py`, `python3 scripts/verify_snow_iphone_ui.py`, `python3 scripts/verify_snow_run_boundary.py`, `python3 scripts/verify_snow_classifier.py`, `python3 scripts/verify_snow_schema.py`, and `python3 scripts/verify_snow_sport_enum.py`.
- Run `xcodebuild build -project SkateTrack.xcodeproj -scheme SkateTrack-watchOS -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)'`.
- Run `xcodebuild build -project SkateTrack.xcodeproj -scheme SkateTrack-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
- Manual watchOS smoke testing confirmed the DEBUG Snow mock gallery, downhill, lift / gondola, waiting, low confidence, fall alert, summary, controls, and haptic intent text flows.

Snow-Task-006a verification token: mock-backed Watch Snow UI complete without WatchBridge real-data wiring.

## 2026-06-17 Phase 1c — Snow-Task-007 macOS Snow Viewer Completed

### Completed

- Added a production-safe macOS Snow analysis boundary for read-only post-session review.
- Added `MacSnowSessionAnalysis` as a pure struct presentation model and kept live / repository / mock concerns outside the value type.
- Added `MacSnowAnalysisViewModel`, `MacSnowAnalysisAvailability`, `MacSnowAnalysisSource`, `MacSnowSessionAnalysisMapper`, and `MacSnowRouteFilter` for macOS Snow viewer data flow.
- Added a DEBUG-only `MacSnowMockAnalysisProvider` for local macOS Snow viewer QA before Snow-Task-008 package payload support.
- Added macOS Snow viewer surfaces: session browser, dashboard, route + elevation overview, segment timeline, segment inspector, distance inspector, vertical drop chart, and package-pending / unavailable states.
- Added DEBUG-only MacRootView integration for Snow Analysis Preview so the UI can be exercised without modifying production package schema.
- Aligned the Snow viewer body toward `SkateTrack_SnowMode_UI_v1.1.1_Pack` visual direction: deep snow-night panels, ice cyan route/downhill emphasis, amber lift/transport emphasis, and explicit low-confidence indicators.
- Added `scripts/verify_snow_macos_viewer.py` and `scripts/create_snow_task007_review_pack.sh`.

### Reason / Context

Snow-Task-007 implements the macOS Snow viewer surface required by the Phase 1c BuildPlan while preserving the task boundary with Snow-Task-008. Official `.skatetrack` Snow package manifest / payload / reader / writer compatibility remains deferred to Snow-Task-008.

Claude's Snow-Task-007 guidance confirmed that Release builds should distinguish between repository-backed Snow sessions and imported packages without official Snow fields: repository-backed Snow sessions may show the full viewer, while imported `.skatetrack` packages missing Snow payload must show `packageSchemaPending` instead of inferred or fabricated analysis.

### Validation Notes

- Run `python3 scripts/verify_snow_macos_viewer.py` to verify macOS Snow viewer files, struct-based analysis model, DEBUG mock gating, localization, project membership, and package-schema guardrails.
- Run cumulative Snow verify scripts before commit.
- Build macOS, iOS, and watchOS targets because the task touches the Xcode project and shared localization.
- Manual QA should open the DEBUG Snow Analysis Preview from the macOS sidebar and confirm the SnowMode visual direction, route/elevation readability, segment timeline, inspector, and distance inspector.

### Known Issues / Follow-up

- Snow-Task-007 does not add official `.skatetrack` Snow package payload support; this remains Snow-Task-008.
- Snow-Task-007 does not persist manual segment corrections.
- Snow-Task-007 uses lightweight SwiftUI route/elevation visualization; full MapKit fitting remains later work.
- v0 elevation is limited because `SnowSegment.startAltitudeMeters` and `endAltitudeMeters` may be nil.
- Future macOS main-shell integration may require outer layout adjustments when the app moves toward `SkateTrack_macOS_UI_v2`.

Snow-Task-007 verification token: read-only macOS Snow viewer complete without package schema scope creep.

## Snow-Task-008a — Snow Package Compatibility and macOS Imported Package Viewer

### Completed
- Added official optional Snow payload support to `.skatetrack` package sessions through `SkateTrackPackageSnowPayload`.
- Bumped the package manifest schema to version 2 while preserving schema 1 decode compatibility.
- Added optional package `capabilities` with Snow capability keys for payload-aware exports.
- Updated iOS package export to include Snow payload only when real `SnowSessionState` is available from the repository.
- Preserved `snowPayload == nil` for non-Snow sessions and Snow sessions without official repository Snow state.
- Wired imported Snow packages into the macOS Snow viewer through `MacSnowSessionAnalysisMapper.makeAvailabilityFromPackage(...)` and `.importedPackage` source.
- Added package compatibility verification, tests, and a review-pack script that writes artifacts outside the repo under `/Users/doggo/Documents/App軟體區/upload/`.

### Deferred
- Backup `snowSessions` compatibility and Snow Health export provider boundary remain deferred to Snow-Task-008b.


### Snow-Task-008b backup compatibility and Health provider boundary

- Added backup schema version 2 with schema 1 / 2 decode support.
- Added optional `snowSessions: [SnowBackupSession]?` to backup payloads.
- Preserved legacy backup semantics: missing `snowSessions` decodes successfully as a legacy backup.
- Encodes new Snow-aware backups with an empty `snowSessions` array by default.
- Added restore preview Snow session counts without changing restore execution behavior.
- Added iOS-only Snow Health export provider boundary under `iOS/Core/Health/`.
- `DisabledSnowHealthExporter` is the production default and returns unavailable without touching HealthKit.
- `MockSnowHealthExporter` is DEBUG-only for local provider wiring tests.
- Added `scripts/verify_snow_backup_compatibility.py` and `scripts/create_snow_task008b_review_pack.sh`.
- Verified package compatibility, backup compatibility, cumulative Snow guardrails, iOS tests, and iOS / macOS / watchOS builds.

Snow-Task-008b intentionally does not add production HealthKit export, WatchBridge wiring, classifier changes, run-boundary changes, or Snow value-model changes.

### Snow-Task-009 QA fixtures and regression matrix

Snow-Task-009 adds a QA / regression safety layer for Phase 1c Snow Mode after Snow-Task-008b.

Implemented boundaries:

- Added deterministic JSON-only Snow QA fixtures under `Tests/Fixtures/Snow/`.
- Added `scripts/generate_snow_qa_fixtures.py` so committed fixtures can be regenerated deterministically.
- Added `SnowQAFixtureRegressionTests` for package v2 Snow payload, package v2 without Snow payload, backup v1 legacy decode, backup v2 empty / populated Snow sessions, lift exclusion semantics, low-confidence safety, and Health boundary regression.
- Added `scripts/verify_snow_regression.py` as the Task 009 verification gate.
- Updated the manual QA matrix with Traditional Chinese checklist items covering iPhone, watchOS, macOS viewer, package import/export, backup compatibility, and Health boundary behavior.
- Added `scripts/create_snow_task009_review_pack.sh`, writing `SnowTask009_ReviewPack.zip` to `/Users/doggo/Documents/App軟體區/upload/`.

Snow-Task-009 intentionally does not change runtime classifier behavior, run-boundary behavior, package schema version, backup schema version, WatchBridge / WatchConnectivity wiring, or real HealthKit export.
