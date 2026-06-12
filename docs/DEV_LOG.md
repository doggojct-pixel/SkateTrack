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
- Updated `docs/FILE_STRUCTURE.md` for the new localization, utilities, script, and task files.

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
- Updated `docs/FILE_STRUCTURE.md` for the new model, protocol, script, and task files.

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
- Living documentation initialized with a full annotated `docs/FILE_STRUCTURE.md` and this Phase 0 completion entry.

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
- Rewrote `docs/FILE_STRUCTURE.md` to reflect the current repository structure, current progress, and unresolved Task-013 blockers honestly.
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
