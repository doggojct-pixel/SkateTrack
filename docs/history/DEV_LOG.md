# SkateTrack Development Log

## Task-014 follow-up: Clean power type subtitle

- Removed the Phase 1a electric skateboard note from the Session Start power type card.
- The power type card now keeps the concise shared subtitle so human-powered and electric modes stay visually aligned.
- Removed the unused `power.electric.phase1a.note` localization key from English and Traditional Chinese strings.


This log is append-only. Do not delete or overwrite old entries.


## 2026-07-05 — Task-031-prep-ActivityViz-003-1 Shared Route Pipeline Split Alignment

### Completed
- Split `RouteDisplayPipeline` helpers into `RouteDisplayPipeline+Filtering.swift`, `RouteDisplayPipeline+Startup.swift`, `RouteDisplayPipeline+Segmentation.swift`, and `RouteDisplayPipeline+Bounds.swift` to realign ActivityViz-003 with the v1.1 build-plan file layout before ActivityViz-004.
- Kept the split behavior-preserving: existing ActivityViz-002 fixture baselines and ActivityViz-003 Shared pipeline parity tests remain the verification source of truth.
- Updated Xcode project membership so the split files are grouped under `Shared/ActivityVisualization/Route/` and compiled by iOS, macOS, and watchOS app targets.
- Updated the ActivityViz-003 verifier to validate the split file inventory, group-relative project paths, and line limits for each split file.

### Validation Notes
- This alignment stage does not modify `SessionRouteMapView.swift`, `MacRouteDisplayPipeline.swift`, renderer behavior, route appearance, stored route geometry, trusted metrics, persistence/export, package schema, location permission, or current user location display.

## 2026-07-05 — Task-031-prep-ActivityViz-003 Shared Route Pipeline Extraction

### Completed
- Added `RouteDisplayPipeline` under `Shared/ActivityVisualization/Route/` to prepare display-only route points, segments, bounds, summaries, and diagnostics from `MotionSample` source-of-truth data.
- Added parity coverage so ActivityViz-002 JSON-backed fixtures verify the Shared pipeline output against existing route semantic baselines.
- Kept iOS and macOS renderers untouched; renderer migration remains deferred to ActivityViz-004 and ActivityViz-005.

### Validation Notes
- The Shared route pipeline mirrors existing display semantics without route correction, road matching, map matching, snap-to-road, route reconstruction, trusted metrics mutation, persistence/export writes, package schema changes, location permission requests, or current user location display.
- `RouteDisplayPipeline` is display-only and does not write `displayDerived` values into `SessionData`, persistence, export, or package paths.


## 2026-07-05 — Task-031-prep-ActivityViz-002 Route Pipeline Test Fixtures

### Completed
- Added deterministic route display fixture tests before Shared route pipeline extraction.
- Added fixture baselines for clean GPS route, startup drift, low-confidence segment, sparse route, duplicate location fixes, large jump, and too few points.
- Added source verifier for ActivityViz-002 fixture scope, project membership, Shared UI-import guard, and no renderer/pipeline migration.

### Validation Notes
- ActivityViz-002 is test/fixture only. It does not change `SessionRouteMapView.swift`, `MacRouteDisplayPipeline.swift`, route appearance, stored route geometry, trusted metrics, persistence/export, or package schema.
- These baselines are intended to fail loudly if ActivityViz-003/004 changes `RouteDisplaySemantic` distribution without deliberate investigation.


## 2026-07-05 — Task-031-prep-ActivityViz-001 Shared Model Shell

### Completed
- Added `Shared/ActivityVisualization/` as the platform-neutral model-shell area for route, speed, and elevation display data.
- Added model-only route, speed, and elevation display result/configuration/diagnostics types.
- Added Xcode project membership for the new Shared model shell in iOS, macOS, and watchOS app targets.
- Preserved Task-031-prep v1.1 scope boundaries: no route correction, renderer migration, trusted metric mutation, persistence/export/package schema change, Core Data write, Watch UI, or Watch recording implementation.

### Validation Notes
- ActivityViz-001 verification must confirm Swift headers, line counts, project membership, no platform UI imports, iOS build, and macOS build before ActivityViz-002 begins.
- `displayDerived` and `displayDerivedTotalAscentMeters` are display-only model terminology and must remain absent from `SessionData` encode/export/package writer paths.


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

## 2026-06-13 — Task-030c-a Core Location Diagnostics Package Extension

### Completed
- Added optional `LocationFixDiagnostics` metadata to `MotionSample` so future `.skatetrack` exports can carry Core Location accuracy, raw location timestamp, millisecond timestamp, update interval, segment distance, coordinate-derived speed, speed source, freshness state, and route segment confidence.
- Added optional `RouteQualitySummary` support for completed sessions and portable package sessions, including `uniqueCoordinateCount`, `lowConfidenceSegmentCount`, stale-location sample count, average / max GPS update interval, and total GPS-derived distance.
- Kept `.skatetrack` `schemaVersion = 1` and added optional `formatCapabilities` values `location-diagnostics-v1` and `route-quality-summary-v1`; old packages without the new fields should remain decode-compatible.
- Bridged accepted Core Location updates through `SensorFusionEngine` diagnostics without changing `GPSProvider` high-accuracy policy yet.
- Added `scripts/verify_task030c_gps_diagnostics_package.py` to guard the diagnostics schema, package capabilities, route-quality summary, documentation alignment, and Task-030c-a scope boundaries.

### Evidence Handling
- `SkateTrack-Session-20260613-110119.skatetrack` is the real-device evidence for the route / speed fidelity mismatch: many motion samples, very few unique coordinates, and route reconstruction from sparse location fixes.
- `SkateTrack-Session-20260612-180037.skatetrack` is treated as a simulator / compatibility reference only. It must not be cited as real-device GPS evidence.

### Scope Boundary
- Task-030c-a is diagnostics and package compatibility only. It does not change `GPSProvider` desired accuracy, distance filter, background behavior, signing, capabilities, entitlements, road snapping, map matching, route replay, Snow Mode, Watch Phase 1b, StoreKit production, Google production services, CloudKit / iCloud, or WeatherKit production.
- Low-confidence route segments are recorded as data, but route rendering changes are deferred to Task-030c-d.

### Validation Notes
- Run `python3 scripts/verify_task030c_gps_diagnostics_package.py` after applying this task.
- Also run `python3 scripts/verify_shared_models.py`, `python3 scripts/verify_sensor_fusion_engine.py`, `python3 scripts/verify_skatetrack_package.py`, and platform builds because this task changes shared models and iOS runtime sample creation.
- Next real-device package export should be inspected for `locationDiagnostics`, `timestampMillisecondsSince1970`, `routeQualitySummary`, `location-diagnostics-v1`, and `route-quality-summary-v1`.

## 2026-06-13 — Task-030c-b High-Accuracy Outdoor Recording + DEBUG Simulated Route

### Completed
- Updated `GPSProvider` active ride policy to request `kCLLocationAccuracyBestForNavigation`, a 1-meter `distanceFilter`, `.fitness` activity type, and no automatic pausing while recording an active ride.
- Updated `SensorFusionEngine` so any mode whose primary, secondary, or supplemental priority plan includes GPS uses the active ride location policy instead of falling back to stationary power saving when GPS is not primary.
- Reworked the DEBUG mock session feed into a simulated outdoor route feed with skating-like coordinate movement, speed variation, small altitude changes, route accuracy diagnostics, and occasional low-confidence route fixes.
- Marked DEBUG simulated samples with `LocationSpeedSource.debugSimulated` and package capability `debug-simulated-route-v1` so simulator packages are not confused with real-device GPS evidence.
- Persisted DEBUG simulated route samples into completed mock sessions instead of saving only the latest mock sample.
- Fixed the same-stage compile-risk duplication of the `motionSamples:` argument in `SessionRecordingCoordinator.enrich`.
- Updated the DEBUG tools copy in `en`, `zh-Hant`, and `ja` so the toggle now describes simulated route diagnostics rather than speed-only demo data.
- Added `scripts/verify_task030c_high_accuracy_debug_route.py` and updated related verify gates for the Task-030c-b scope.

### Scope Boundary
- Task-030c-b changes Core Location recording policy and DEBUG-only simulator route data. It does not add road snapping, map matching, route replay, Snow Mode, Watch Phase 1b, production StoreKit, Google production services, CloudKit / iCloud, WeatherKit production, signing, capabilities, entitlements, Launch Screen, AppIcon, or bottom dock changes.
- DEBUG simulated route data is explicitly marked and remains unavailable as a production fallback.
- Real-device route / speed fidelity still requires outdoor iPhone validation after this task; simulator packages remain diagnostics / compatibility references only.

### Validation Notes
- Run `python3 scripts/verify_task030c_high_accuracy_debug_route.py` after applying this task.
- Also run `python3 scripts/verify_task030c_gps_diagnostics_package.py`, `python3 scripts/verify_gps_provider.py`, `python3 scripts/verify_sensor_fusion_engine.py`, `python3 scripts/verify_debug_tools.py`, `python3 scripts/verify_localization_keys.py`, `python3 scripts/verify_skatetrack_package.py`, and platform builds.
- In DEBUG simulator, enable the simulated route toggle before starting a session, record at least 60 seconds, and export `.skatetrack`; the package should include moving coordinates, altitude changes, `debugSimulated` speed source values, and `debug-simulated-route-v1`.

Task-030c-b verification token: High-accuracy outdoor recording policy, DEBUG simulated route, debug-simulated-route-v1, road snapping deferred.

## 2026-06-13 — Task-030c-b Live HUD Speed Trace Visibility Fix

### Completed
- Rechecked the Live HUD speed trace after real-device and simulator observations suggested the background speed line could appear missing even before the high-accuracy GPS change.
- Kept the existing `LiveSpeedTraceView` architecture but made trace collection more robust by appending samples on recording start, elapsed-time updates, speed updates, and the existing timer path.
- Added a visible waiting trace baseline so the speed hero no longer looks empty while fewer than two speed samples have accumulated.
- Increased speed trace contrast slightly while preserving the dark neon HUD style.
- Updated `scripts/verify_live_hud.py` so the gate explicitly checks the speed trace component, robust fallback trace, current full-screen HUD layout, and current file line budget.

### Scope Boundary
- This is a Task-030c-b same-stage UI reliability fix. It does not change `GPSProvider`, sensor fusion policy, DEBUG simulated route generation, road snapping, map matching, route replay, Snow Mode, Watch Phase 1b, signing, capabilities, entitlements, Launch Screen, AppIcon, or bottom dock behavior.
- It does not invent speed data. The trace only visualizes existing live speed metrics and shows a low-emphasis baseline before enough samples exist.

### Validation Notes
- Run `python3 scripts/verify_live_hud.py` in addition to the Task-030c-b verify scripts.
- In iPhone 17 Pro simulator, start a DEBUG simulated route session and confirm the speed trace is visible behind the main Live HUD speed value within the first few seconds.
- On real iPhone, confirm the speed trace is visible during outdoor recording even before route fidelity is judged.

## 2026-06-13 — Task-030c-b2 Navigation-grade Location Continuity

### Completed
- Treated the 2026-06-13 screen-off pocket motorcycle validation as a failed Task-030c-b real-device result: route samples were still sparse, distance was severely under-recorded, and large location / motion gaps appeared after the screen was locked.
- Formalized active ride recording as a navigation-style background location session for the iOS target by keeping generated Info.plist `UIBackgroundModes = location`, `NSLocationWhenInUseUsageDescription`, and `NSLocationAlwaysAndWhenInUseUsageDescription` aligned with the runtime policy.
- Kept `GPSProvider` active ride policy on `kCLLocationAccuracyBestForNavigation`, 1 m distance filter, `.fitness`, and no automatic pausing, while adding significant-location-change backup for long screen-off pocket sessions.
- Changed `GPSProvider` from dropping every fix over 35 m horizontal accuracy to accepting lower-confidence-but-valid fixes up to 250 m, so pocket / urban-canyon updates can be recorded and marked low confidence instead of silently creating multi-minute route gaps.
- Added received-at timestamps to `LocationFixDiagnostics` so future package analysis can compare Core Location raw timestamps with app receive time.
- Added continuity gap diagnostics to `RouteQualitySummary`: max motion sample interval, long location update gap count, and long motion sample gap count.
- Added `navigation-continuity-diagnostics-v1` package capability for exports carrying the new continuity diagnostics.
- Added `scripts/verify_task030c_navigation_continuity.py` and updated related GPS / diagnostics verify gates.

### Real-device Evidence Handling
- `SkateTrack-Session-20260613-155800.skatetrack` and `SkateTrack-Session-20260613-160652.skatetrack` are real-device failed validation packages for the pre-b2 state. They show that foreground high-accuracy settings alone are not sufficient for screen-off pocket recording.
- The next validation package must be produced with DEBUG simulated route disabled, iPhone screen locked, phone in pocket, and a known outdoor route long enough to test background continuity.

### Scope Boundary
- Task-030c-b2 intentionally touches iOS background location generated Info.plist settings and Core Location background runtime behavior for active ride recording.
- It does not add road snapping, map matching, route replay, Snow Mode, Watch Phase 1b, production StoreKit, Google production services, CloudKit / iCloud, WeatherKit production, Launch Screen, AppIcon, bottom dock, or Apple Developer Program production integrations.
- It still does not claim fully validated navigation-grade route reliability; real-device screen-off pocket validation must pass first.

### Validation Notes
- Run `python3 scripts/verify_task030c_navigation_continuity.py` after applying this task.
- Also run the Task-030c-b, GPS diagnostics, GPS provider, sensor fusion, debug tools, localization, package, Live HUD, and release-readiness verify scripts.
- On the real iPhone, grant precise location and Always location access when prompted or via Settings before judging screen-off recording behavior.
- Real-device validation should compare new packages against the failed 2026-06-13 screen-off packages using unique coordinate count, average / max location update gap, long location gap count, long motion sample gap count, total GPS distance, and route map continuity.

Task-030c-b2 verification token: Navigation-grade Location Continuity, screen-off pocket, background location mode, navigation-continuity-diagnostics-v1, road snapping deferred.

## 2026-06-13 — Task-030c-b3 Navigation-grade Route Recording Recovery

### Completed
- Treated the 2026-06-13 windshield / car validation packages as a failed Task-030c-b2 result: real-world distance, speed summary, chart continuity, fall-event safety, and route rendering still need recovery before commit.
- Reconciled saved `SessionSummaryMetrics` with `RouteQualitySummary.totalGPSDistanceMeters` so completed sessions no longer under-report distance when the raw route stream records more distance than the live foreground accumulator.
- Added same-session fall-event scoping and reset `FallDetectionEngine.detectedFallEvents` at the start of each monitoring session so stale or DEBUG-origin fall events cannot leak into new real sessions.
- Added a high-speed guard for fall alerts during current skateboard / inline recording so car / motorcycle validation does not keep triggering fall warnings from vibration-like motion.
- Reduced speed outlier propagation by preferring Core Location speed when available and rejecting coordinate-derived speeds above the current pre-Snow-mode plausible range.
- Reworked speed and elevation charts to be gap-aware: long gaps, stale fixes, and low-confidence fixes start a new chart segment, and the area fills were removed so charts do not draw pale triangular blocks across missing data.
- Reworked the summary route preview into segmented raw route polylines so long gaps or low-confidence segments are not drawn as one continuous precise line.
- Replaced the content-bottom return button with a persistent floating bottom return CTA using `safeAreaInset(edge: .bottom)`, keeping the large SkateTrack CTA style while allowing return from any scroll position.
- Added `route-recording-recovery-v1` to package capabilities and added `scripts/verify_task030c_route_recording_recovery.py`.

### Scope Boundary
- Task-030c-b3 is still raw Core Location route recording recovery. It does not implement road snapping, map matching, route replay, speed smoothing, Snow Mode, Watch Phase 1b, production StoreKit, Google production services, CloudKit / iCloud, WeatherKit production, Launch Screen, AppIcon, or bottom dock changes.
- The segmented route map is not a road-matched navigation route. It only avoids presenting long gaps as precise continuous road travel.
- The speed outlier cap is a current pre-Snow-mode guard for skateboard / inline validation and should be revisited when Snow Mode / skiing speeds are formally added.

### Validation Notes
- Run `python3 scripts/verify_task030c_route_recording_recovery.py` after applying this task.
- Also run the Task-030c-b2 navigation continuity, Task-030c-b simulated route, GPS diagnostics, GPS provider, sensor fusion, Live HUD, session summary, localization, package, and release-readiness verify scripts.
- Real-device validation must still be repeated with DEBUG simulated route off. Use known outdoor routes, record screen-off / pocket and windshield scenarios separately, and compare summary distance, route-quality distance, long gap counts, fall-event counts, speed outliers, chart rendering, and floating return UX.

Task-030c-b3 verification token: Navigation-grade Route Recording Recovery, route-recording-recovery-v1, gap-aware charts, floating bottom return, road snapping deferred.

## 2026-06-13 — Task-030c-b4 Raw CLLocation Stream Persistence

### Completed
- Promoted active ride route recording from throttled location-driven timer samples to explicit raw Core Location fix persistence inside `SensorFusionEngine`.
- Added `MotionSampleSource` so exported / persisted samples can distinguish timer-fusion samples, raw location-fix samples, and DEBUG simulated route samples without breaking old `.skatetrack` decode.
- Every accepted `CLLocation` now creates a dedicated `.locationFix` `MotionSample` using the raw Core Location timestamp, accuracy diagnostics, speed source, and available altitude before being appended to the session sample stream.
- Kept timer-fusion samples for IMU / barometer continuity, but route / package diagnostics can now deduplicate raw location fixes instead of relying on repeated last-coordinate timer samples.
- Updated route-quality aggregation to sort by raw route timestamp and deduplicate unique location-fix keys so raw location fixes and timer-fusion duplicates do not double-count route distance.
- Reconciled summary distance using a trusted route-distance helper that rejects long-gap / low-confidence / implausible segments instead of blindly adopting every route-quality distance across missing data.
- Marked DEBUG simulated route samples as `.debugSimulated` and added `raw-location-stream-v1` package capability.
- Fixed route map annotation titles to use localized start / finish strings instead of showing localization keys on the map.
- Added `scripts/verify_task030c_raw_location_stream.py` for the new raw stream persistence guard.

### Scope Boundary
- Task-030c-b4 is still raw Core Location persistence and honesty work. It does not add road snapping, map matching, route replay, speed smoothing, Snow Mode, Watch Phase 1b, production StoreKit, Google production services, CloudKit / iCloud, WeatherKit production, Launch Screen, AppIcon, or bottom dock changes.
- It cannot repair historical packages where raw location fixes were never saved. It only improves future recordings made after this hotfix.
- The app still does not infer the exact road taken; it records raw location fixes and marks low-confidence / long-gap data honestly.

### Validation Notes
- Run `python3 scripts/verify_task030c_raw_location_stream.py` after applying this task.
- Also run the Task-030c-b3 route recovery, Task-030c-b2 navigation continuity, Task-030c-b simulated route, GPS diagnostics, GPS provider, sensor fusion, Live HUD, session summary, localization, package, and release-readiness verify scripts.
- Real-device validation must use new recordings only. DEBUG simulated route must be off, precise + Always location should be enabled, and screen-off / pocket plus windshield scenarios should be tested separately.
- Compare new packages using raw `.locationFix` sample count, unique coordinate count, long gap counts, trusted summary distance, route-quality distance, route map continuity, chart continuity, and fall-event count.

Task-030c-b4 verification token: Raw CLLocation Stream Persistence, raw-location-stream-v1, raw location fix stream, road snapping deferred.

## 2026-06-14 — Task-030c-b5 Activity-Aware Location, Speed & Altitude Fidelity

### Completed
- Reframed Task-030c after real-device walking, windshield, motorcycle, and car validation showed that SkateTrack cannot assume a single normal skateboard speed range.
- Added activity-aware fidelity profiles for technical skateboard, standard skateboard, electric skateboard, recreational inline, speed inline, snow-reserved future use, and vehicle validation.
- Replaced fixed global speed caps with `ActivityFidelityPolicy`, allowing electric skateboard, speed inline, future snow / ski, and vehicle validation packages to preserve broader speed ranges while still rejecting impossible values.
- Added altitude source metadata so Core Location absolute altitude, barometer relative altitude, and DEBUG simulated altitude are no longer mixed silently in samples.
- Stabilized elevation gain by using trusted Core Location absolute altitude or DEBUG simulated altitude only, with vertical accuracy and per-step altitude jump guards to prevent walking sessions from showing impossible 100 m jumps or multi-kilometer climb totals.
- Updated fall alert gating to use activity-aware policy rather than a single hard-coded skateboard speed threshold, reducing vehicle / high-speed validation false positives while keeping low-speed ride fall checks available.
- Updated speed / elevation chart filtering to use activity-aware speed policy and altitude-source policy instead of a fixed 90 km/h chart cutoff or mixed altitude sources.
- Added `activity-aware-fidelity-v1` and `altitude-source-stabilization-v1` package capabilities, plus `scripts/verify_task030c_activity_aware_fidelity.py`.

### Scope Boundary
- Task-030c-b5 does not add road snapping, map matching, route replay, Snow Mode UI, Watch Phase 1b, production StoreKit, Google production services, CloudKit / iCloud, WeatherKit production, Launch Screen, AppIcon, bottom dock changes, or required Apple Intelligence / Core ML runtime.
- Core ML / Apple on-device AI remains optional future enhancement. The current implementation is deterministic and works on devices without Apple Intelligence.
- Low-speed technical S-curve tracing is recognized as a separate relative technique-trace problem; GPS route preview remains a geographic route and must not pretend to draw sub-meter surfskate carving shapes.

### Validation Notes
- Run `python3 scripts/verify_task030c_activity_aware_fidelity.py` after applying this task.
- Also run raw location stream, route recovery, navigation continuity, GPS diagnostics, GPS provider, sensor fusion, debug tools, Live HUD, session summary, localization, package, and release-readiness verify scripts.
- Real-device validation should include walking, windshield / vehicle validation, screen-off pocket, and later real skateboard / inline scenarios. Compare speed range preservation, long gap counts, summary distance, route continuity, chart stability, altitude gain sanity, and fall-event count.

Task-030c-b5 verification token: Activity-Aware Location, Speed & Altitude Fidelity, activity-aware-fidelity-v1, altitude-source-stabilization-v1, Core ML optional, road snapping deferred.


## 2026-06-14 — Task-030c-b6 Debug Tools Status Panel Polish

### Completed
- Replaced the old unlabeled grey `SessionRecordingPreviewPanel` with a polished DEBUG-only diagnostics card.
- The diagnostics card now labels session state, current speed, distance, elapsed time, GPS count, total samples, latest horizontal accuracy, latest freshness state, and latest sample source.
- Added a polished build-signature card to the Debug Tools page that displays `Task-030c-b6` so real-device testers can confirm the installed build contains the latest GPS fidelity test package.
- Added three-language localization keys for the debug diagnostics card and build-signature copy.
- Added `scripts/verify_task030c_debug_panel_polish.py` and extended `scripts/verify_debug_tools.py` to guard the new debug UI tokens.

### Scope Boundary
- Task-030c-b6 does not change GPS, background location, raw location stream persistence, activity-aware fidelity policy, altitude policy, fall detection, route rendering, speed charts, StoreKit, Google, CloudKit, WeatherKit, signing, capabilities, Launch Screen, AppIcon, bottom dock, Watch Phase 1b, or Task-031.
- `Task-030c-b6` is intentionally a tester-facing DEBUG build label, not an App Store marketing version or production release claim.

### Validation Notes
- Run `python3 scripts/verify_task030c_debug_panel_polish.py`.
- Also run `python3 scripts/verify_debug_tools.py` and `python3 scripts/verify_localization_keys.py`.
- Xcode iOS build should be verified on `iPhone 17 Pro` simulator and real-device install before continuing GPS fidelity testing.

Task-030c-b6 verification token: Debug Tools Status Panel Polish, Task-030c-b6, debug-build-signature-card, session-recording-preview-panel.

## 2026-06-14 — Task-030c-b7 Background Recording Gap Diagnostics

### Completed
- Added optional DEBUG-only `debugRecordingDiagnostics` metadata to `SessionData` so future `.skatetrack` packages can include internal diagnostics without changing the production package schema version.
- Added `RecordingDebugDiagnostics` event blocks for build identity, test context, app lifecycle, protected data lock/unlock signals, recording heartbeats, authorization snapshots, location manager snapshots, Core Location callback events, gap events, recovery events, filter decision summaries, and altitude diagnostics.
- Instrumented `SessionRecordingCoordinator` to start a per-session diagnostics collector, record session lifecycle events, capture recording heartbeat gaps, and attach the final debug diagnostics block when the session is enriched.
- Instrumented `GPSProvider` to record location manager configuration, authorization state, `didUpdateLocations`, `didFailWithError`, `didPauseLocationUpdates`, `didResumeLocationUpdates`, accepted/rejected location fix counts, and significant-location-change backup start events.
- Added a DEBUG-only recording test context picker to Debug Tools so real-device packages can be tagged as handheld screen-on, handheld auto-lock, locked pocket walk, windshield drive, or vehicle screen-off before recording.
- Updated the DEBUG build signature from `Task-030c-b6` to `Task-030c-b7` and added `debug-recording-diagnostics-v1` plus `background-gap-diagnostics-v1` package capabilities when a debug diagnostics block exists.
- Added `scripts/verify_task030c_background_gap_diagnostics.py` for the new internal diagnostics guard.

### Scope Boundary
- Task-030c-b7 is diagnostics-first. It does not perform road snapping, map matching, route replay, route reconstruction, Snow Mode work, Watch Phase 1b, production StoreKit, Google production services, CloudKit / iCloud, WeatherKit production, HealthKit production, signing, Bundle ID, entitlements, Launch Screen, AppIcon, bottom dock, or broad GPS algorithm changes.
- The new diagnostics are temporary DEBUG-only internal recording metadata. They are intended to help diagnose lock-screen / background / pocket recording gaps during Pre-ADP testing and may be removed or collapsed into cleaner developer diagnostics after the GPS fidelity branch stabilizes.
- The diagnostics block does not duplicate the full raw coordinate log beyond the existing motion samples; it records event-based state needed to distinguish iOS callback gaps, app recording-loop gaps, and SkateTrack filter decisions.

### Validation Notes
- Run `python3 scripts/verify_task030c_background_gap_diagnostics.py` after applying this task.
- Also run debug tools, localization, package, raw location stream, route recovery, activity-aware fidelity, GPS provider, sensor fusion, session summary, and release-readiness verify scripts.
- Real-device validation should repeat locked pocket walking, handheld auto-lock walking, and windshield drive scenarios with DEBUG simulated route off. Before each run, choose the matching Debug Tools recording test context so uploaded packages can be compared against app lifecycle, protected data, heartbeat, authorization, location callback, filter, and gap event diagnostics.

Task-030c-b7 verification token: Background Recording Gap Diagnostics, debug-recording-diagnostics-v1, background-gap-diagnostics-v1, DEBUG-only, protected data.


## Task-030c-b8 — Debug Recording Context Labels

- Refined DEBUG recording test context labels so real-device diagnostics can distinguish auto-lock, manual lock, pocket, windshield, electric longboard, and scooter validation scenarios.
- Added concise human-readable descriptions under the context picker; these labels are saved only in DEBUG diagnostics and do not change GPS, route, altitude, or fall-detection behavior.
- Updated the DEBUG build identity to `Task-030c-b8` for easier real-device build confirmation.
- Deferred: no background recording algorithm change, no road snapping, no production UI exposure, and no SnowPrototype changes.

## Task-030c-b9 — Ensure Background Diagnostics Export

### Completed
- Updated the internal recording diagnostics build identity to `Task-030c-b9` so real-device exports can prove which GPS fidelity build created the `.skatetrack` package.
- Added `diagnosticsStatus` to `RecordingDebugDiagnostics` so exported packages can distinguish `enabled`, `enabledButNoEventsRecorded`, and `disabledByBuildConfiguration` states.
- Changed DEBUG diagnostics finalization to export a non-nil diagnostics block even if no lifecycle, heartbeat, location callback, gap, or filter events were collected.
- Added a non-DEBUG build-configuration placeholder diagnostics block so accidental Release / non-DEBUG real-device installs can still be identified from exported packages instead of looking identical to older b5 packages.
- Added package capabilities `debug-build-identity-v1` and `diagnostics-export-status-v1` whenever a diagnostics block is present, alongside `debug-recording-diagnostics-v1` and `background-gap-diagnostics-v1`.
- Updated the Debug Tools build signature to `Task-030c-b9` and added `scripts/verify_task030c_diagnostics_export.py`.

### Scope Boundary
- Task-030c-b9 does not change GPS algorithms, Core Location background policy, restart / retry behavior, route reconstruction, altitude filtering, fall detection, SnowPrototype, Watch Phase 1b, signing, Bundle ID, entitlements, App Store capabilities, StoreKit, Google, CloudKit, WeatherKit, HealthKit, road snapping, or map matching.
- The non-DEBUG placeholder is temporary Pre-ADP internal diagnostics metadata. It is intended only to prove whether diagnostics were disabled by build configuration during GPS branch testing and should be removed or reworked before production release.

### Validation Notes
- Run `python3 scripts/verify_task030c_diagnostics_export.py` after applying this task.
- Also run background gap diagnostics, debug tools, debug recording context labels, localization, package, GPS provider, sensor fusion, raw location stream, route recovery, activity-aware fidelity, session summary, and release-readiness verify scripts.
- Real-device validation should confirm exported packages include `debugRecordingDiagnostics.buildIdentity.debugBuildTaskID == Task-030c-b9` and a meaningful `diagnosticsStatus` before using the package to diagnose lock-screen / pocket recording gaps.

Task-030c-b9 verification token: Ensure Background Diagnostics Export, Task-030c-b9, debug-build-identity-v1, diagnostics-export-status-v1, disabledByBuildConfiguration.

## Task-030c-b9-r1 — Persist Diagnostics Through Session Export

### Completed
- Updated the internal recording diagnostics build identity to `Task-030c-b9-r1` and kept the Debug Tools build signature aligned.
- Persisted `debugRecordingDiagnostics` through the Core Data save / fetch round trip by adding optional `debugRecordingDiagnosticsData` to persisted sessions and encoding / decoding `RecordingDebugDiagnostics` in `SessionEntityMapper`.
- Added an export-time fallback that injects a minimal diagnostics block with `diagnosticsStatus == "missingFromPersistedSession"` when an older persisted session is exported without recording diagnostics.
- Ensured package capabilities are evaluated against the final export session so `debug-build-identity-v1`, `debug-recording-diagnostics-v1`, `background-gap-diagnostics-v1`, and `diagnostics-export-status-v1` match the actual payload.
- Extended the existing repository round-trip test so saved / fetched sessions preserve `debugRecordingDiagnostics.buildIdentity.debugBuildTaskID == Task-030c-b9-r1`.
- Added `scripts/verify_task030c_diagnostics_persistence.py` to guard the persistence model, mapper, fallback export path, and documentation.

### Scope Boundary
- Task-030c-b9-r1 does not change GPS algorithms, Core Location background policy, restart / retry behavior, route reconstruction, startup stabilization, implied-speed filtering, altitude filtering, fall detection, SnowPrototype, Watch Phase 1b, signing, Bundle ID, entitlements, App Store capabilities, StoreKit, Google, CloudKit, WeatherKit, HealthKit, road snapping, or map matching.
- The new Core Data attribute is an optional local persistence field for temporary Pre-ADP diagnostics only. It is not a production service integration and does not change `.skatetrack` schema version.

### Validation Notes
- Run `python3 scripts/verify_task030c_diagnostics_persistence.py` and `python3 scripts/verify_task030c_diagnostics_export.py` after applying this task.
- Real-device validation should first perform a 10–20 second stationary export and confirm `debugRecordingDiagnostics.buildIdentity.debugBuildTaskID == Task-030c-b9-r1` plus a meaningful `diagnosticsStatus` before repeating long lock-screen / pocket tests.

Task-030c-b9-r1 verification token: Persist Diagnostics Through Session Export, Ensure Background Diagnostics Export, Debug Recording Context Labels, Task-030c-b9-r1, debugRecordingDiagnosticsData, debug-build-identity-v1, diagnostics-export-status-v1, missingFromPersistedSession.

## Task-030c-b10 — Effective Background Location Runtime + Gap Recovery Quality Gate

### Completed
- Updated the internal recording diagnostics build identity and Debug Tools build signature to `Task-030c-b10`.
- Added an explicit iOS app `Info.plist` with `UIBackgroundModes` declared as an array containing `location`, and wired only the SkateTrack-iOS Debug / Release configurations to that plist so the existing background-location declaration is visible in the built app bundle.
- Added `RecordingDebugBundleInfoSnapshot` and attached it to location manager diagnostics so real-device packages can show the app bundle identifier, bundle path marker, raw `UIBackgroundModes` value, resolved modes, and whether `location` was detected at runtime.
- Hardened runtime background-mode detection in `GPSProvider` by reading `Bundle.main.object(forInfoDictionaryKey:)`, `infoDictionary`, `localizedInfoDictionary`, and the built `Info.plist`, then normalizing array / string / punctuation-separated values before setting `allowsBackgroundLocationUpdates`.
- Added a DEBUG recovery event when active recording wants background updates but the runtime bundle declaration still cannot be resolved.
- Added a conservative gap-recovery quality gate so stale, low-confidence, low-accuracy, overlong-gap, or implausible implied-speed fixes can remain in diagnostics / raw samples but no longer update trusted live route anchors, summary speed, summary distance, or trusted `RouteQualitySummary.totalGPSDistanceMeters`.
- Added `scripts/verify_task030c_background_runtime_quality_gate.py` to guard the Info.plist wiring, runtime diagnostics snapshot, background enablement path, and trusted-distance quality gate.

### Scope Boundary
- Task-030c-b10 does not add new entitlements, change signing, change Bundle ID, add production services, perform road snapping, perform map matching, or fabricate route points.
- The explicit iOS `Info.plist` is limited to making the already-intended `UIBackgroundModes/location` declaration effective in the app bundle. Watch, macOS, tests, SnowPrototype, Watch Phase 1b, StoreKit, Google, CloudKit, WeatherKit, and HealthKit production integrations remain untouched.
- Gap-recovery quality gating is conservative: low-quality fixes are still exported for diagnostics, but trusted metrics avoid counting them as reliable movement.

### Validation Notes
- Run `python3 scripts/verify_task030c_background_runtime_quality_gate.py` after applying this task, followed by the existing diagnostics persistence / export / background gap / GPS / sensor fusion / summary verify scripts.
- Real-device validation should first repeat a 30–60 second `步行・鎖螢幕口袋` test and confirm `debugRecordingDiagnostics.buildIdentity.debugBuildTaskID == Task-030c-b10`, `bundleInfo.hasLocationBackgroundMode == true`, `hasBackgroundLocationModeDeclared == true`, and `allowsBackgroundLocationUpdates == true` in location manager snapshots.
- If background snapshots become true but gaps still occur, compare `locationCallbackEvents`, `gapEvents`, and trusted distance against the b9-r1 walking baseline before moving to motorcycle / electric longboard tests.

Task-030c-b10 verification token: Effective Background Location Runtime + Gap Recovery Quality Gate, Task-030c-b10, UIBackgroundModes, background runtime, gap recovery, stale / low-accuracy quality gate.

## Task-030c-b10-r2 — Startup Speed Spike + Fall Handling Guard

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b10-r2`.
- Added a startup stabilization guard so coordinate-derived GPS speed spikes during the first seconds of recording are marked as low-confidence diagnostics and do not update live trusted speed, max speed, trusted route distance, or timer-fusion samples.
- Added a startup fall handling guard so IMU impacts caused by locking the screen / putting the phone into a pocket during the first seconds of a session are suppressed from the persisted session and do not keep the SOS countdown active.
- Raw GPS fixes and raw IMU samples remain preserved for diagnostics; this task does not smooth, snap, map-match, or fabricate route geometry.

Task-030c-b10-r2 verification token: Startup Speed Spike + Fall Handling Guard, Task-030c-b10-r2, startupCoordinateDerivedSpeedSpikeKmh, startupFallHandlingSuppressionSeconds, coordinate-derived startup guard.

## Task-030c-b10-r3 — Low-Speed Metrics Gate + UI Responsiveness

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b10-r3`.
- Added a low-speed metric gate so short residential / small-area GPS jumps with poor horizontal accuracy, suspicious Core Location speed, mismatched coordinate-implied speed, or poor speed accuracy no longer inflate trusted max speed, average speed, or distance.
- Tightened live and summary metric trust so low-confidence route diagnostics are preserved as raw samples but excluded from trusted speed / distance metrics.
- Added elevation-gain stabilization that prefers barometer-relative altitude for short low-speed sessions and rejects startup / poor-vertical-accuracy Core Location altitude jumps from summary climb.
- Improved perceived responsiveness by yielding after the preparing transition before heavier sensor startup work and by moving `.skatetrack` package creation to a user-initiated detached task.
- Task-030c-b10-r3 does not perform route smoothing, road snapping, map matching, S-curve presentation, SnowPrototype work, Watch Phase 1b work, signing changes, Bundle ID changes, entitlement changes, or production service integrations.

Task-030c-b10-r3 verification token: Low-Speed Metrics Gate + UI Responsiveness, Task-030c-b10-r3, low-speed metrics gate, barometer-relative elevation, export responsiveness.


## Task-030c-b10-r4 — Strict Low-Speed Metrics + Altitude Source Isolation

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b10-r4`.
- Tightened the low-speed metrics gate so Core Location speed is not trusted by itself when horizontal accuracy, small-area segment size, speed accuracy, or coordinate-implied speed suggest a low-speed GPS artifact.
- Isolated altitude sources for short low-speed sessions: barometer-relative altitude is preferred whenever present, while Core Location absolute altitude remains raw diagnostics unless barometer data is unavailable and the fix is sufficiently stable.
- Continued to preserve raw GPS, raw altitude, and diagnostics samples while excluding untrusted low-speed / altitude artifacts from trusted max speed, distance, and elevation gain.
- Task-030c-b10-r4 does not perform route smoothing, road snapping, map matching, S-curve presentation, SnowPrototype work, Watch Phase 1b work, signing changes, Bundle ID changes, entitlement changes, or production service integrations.

Task-030c-b10-r4 verification token: Strict Low-Speed Metrics + Altitude Source Isolation, Task-030c-b10-r4, strict low-speed metrics, altitude source isolation, barometer-relative elevation, verify_task030c_strict_low_speed_altitude.py.
Task-030c-b10-r4 compatibility token: Background Location Runtime + Gap Recovery Quality Gate, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard, low-speed metrics gate, startup guard, diagnostics persistence, diagnostics export.

## Task-030c-b10-r5 — Trusted Chart Metrics + Display Source Alignment

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b10-r5`.
- Aligned Session Summary speed charts with trusted display speed rather than raw Core Location instantaneous speed, including median smoothing and display-step limiting so short one-off pulses do not dominate the chart.
- Aligned elevation charts with trusted altitude source selection. When barometer-relative altitude exists, charts normalize and display the barometer-relative series instead of raw Core Location absolute altitude startup drift.
- - Smoothed the Live HUD trace display so user-visible trace motion is calmer without altering raw samples or diagnostics.
- Task-030c-b10-r5 does not implement route geometry stabilization, small-area loop smoothing, skateboard S-curve presentation, map matching, road snapping, SnowPrototype work, Watch Phase 1b work, signing changes, Bundle ID changes, entitlement changes, or production service integrations.

Task-030c-b10-r5 verification token: Trusted Chart Metrics + Display Source Alignment, Task-030c-b10-r5, trusted chart metrics, display source alignment, verify_task030c_trusted_chart_metrics.py.
Task-030c-b10-r5 compatibility token: Strict Low-Speed Metrics + Altitude Source Isolation, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard, Background Location Runtime + Gap Recovery Quality Gate.

## Task-030c-b11 — Small-Area Route Geometry Stabilization

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b11`.
- Introduced a Summary map display-route pipeline that separates raw GPS samples from user-facing route geometry.
- Added `rawRoute`, `trustedRoute`, and `displayRoute` terminology for the GPS fidelity branch:
  - `rawRoute` remains the unmodified Core Location / motion-sample coordinate stream preserved in diagnostics and exports.
  - `trustedRoute` is the route subset whose samples pass freshness, confidence, accuracy, and gap checks.
  - `displayRoute` is the Summary map rendering path built from trusted location fixes with small-area jitter suppression and light smoothing.
- Updated `SessionRouteMapView` so the map no longer draws timer-fusion coordinate repeats directly and no longer treats low-confidence / stale route segments as normal continuous path geometry.
- Added small-area jitter suppression for low-speed movement so sub-meter / short-range GPS noise is not drawn as real movement when the phone is stationary or moving slowly in a small residential area.
- Preserved start / finish annotations on the display route while keeping raw GPS samples available in diagnostics and `.skatetrack` exports.
- Added `scripts/verify_task030c_small_area_route_geometry.py` and extended the Session Summary verifier to guard the display-route pipeline.

### Scope Boundary
- Task-030c-b11 does not create skateboard S-curve sensor-fusion presentation, does not use road snapping, does not use map matching, and does not fabricate route points.
- This task does not delete raw GPS, raw IMU, raw altitude, or diagnostics data.
- Motorcycle validation remains a background / high-speed stress test only and does not define standard skateboard display geometry.
- SnowPrototype, Watch Phase 1b, signing, Bundle ID, entitlements, StoreKit, Google, CloudKit, WeatherKit, HealthKit, and production services remain untouched.

### Validation Notes
- Run `python3 scripts/verify_task030c_small_area_route_geometry.py` after applying this task, followed by the existing Session Summary, GPS, diagnostics, and trusted metric verify scripts.
- Real-device validation should use a small residential open area /巷口繞圈 test for 1–2 minutes. The expected result is not 1m absolute positioning, but a less jittery Summary map display path that no longer draws obvious raw GPS drift or timer-fusion repeats as the primary visible route.
- If small-area display geometry is acceptable, continue to Task-030c-b12 for skateboard S-curve sensor-fusion presentation.

Task-030c-b11 verification token: Small-Area Route Geometry Stabilization, Task-030c-b11, rawRoute, trustedRoute, displayRoute, small-area jitter suppression, verify_task030c_small_area_route_geometry.py.
Task-030c-b11 compatibility token: Trusted Chart Metrics + Display Source Alignment, Strict Low-Speed Metrics + Altitude Source Isolation, Background Location Runtime + Gap Recovery Quality Gate.

## Task-030c-b11-r1 — Route Confidence Display Continuity

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b11-r1`.
- Refined the Summary map route renderer so low-confidence / uncertain route fixes are not treated as missing data or immediate route breaks.
- Added secondary display styling for uncertain route segments using reduced opacity and a dashed line style while preserving trusted segments as the primary route line.
- Kept true route discontinuities limited to actual time gaps or large coordinate jumps, so high-speed validation sessions do not visually resemble recording dropouts merely because part of the route is low-confidence for the selected activity profile.
- Raw GPS, trusted metrics, diagnostics, and `.skatetrack` exports remain unchanged. This task does not claim small-area loops are accurate and does not implement IMU reconstruction, skateboard S-curve presentation, road snapping, map matching, or fabricated route points.

Task-030c-b11-r1 verification token: Route Confidence Display Continuity, Task-030c-b11-r1, low-confidence route display, uncertain route segment, verify_task030c_route_confidence_display.py.
Task-030c-b11-r1 compatibility token: Small-Area Route Geometry Stabilization, Trusted Chart Metrics + Display Source Alignment, Strict Low-Speed Metrics + Altitude Source Isolation.

## Task-030c-b11-r2 — Activity-Aware Route Confidence + Small-Area Display Gate

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b11-r2`.
- Aligned live SensorFusion route confidence with the active activity profile, including electric skateboard / electric longboard, vehicle-validation, and future snow-proxy testing paths, instead of letting standard-skateboard thresholds mark high-speed proxy routes as low confidence.
- Passed the selected power type and resolved fidelity profile into the live sensor engine so electric and validation sessions preserve plausible route, speed, and altitude display continuity.
- Kept strict small-area low-speed filtering for human-powered walking / skateboard-like profiles while using broader activity-aware gates for electric, snow-reserved, speed, and vehicle-validation profiles.
- Updated Summary map and chart display gates so low-confidence fresh segments remain uncertain rather than missing, while stale fixes and true long gaps still break the visible route / chart.

Task-030c-b11-r2 verification token: Activity-Aware Route Confidence + Small-Area Display Gate, Task-030c-b11-r2, verify_task030c_activity_aware_route_confidence.py.
Task-030c-b11-r2 compatibility token: Route Confidence Display Continuity, Small-Area Route Geometry Stabilization, Activity-Aware Location Fidelity.



## Task-030c-b11-r3-3 — Post-Record GPS Lock Guard + Approximate Start Semantics

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b11-r3-3`.
- Separated Summary Map start marker semantics from the GPS lock route anchor: the start marker now represents an approximate recording-start candidate when GPS is still converging, while trusted route geometry begins from the first confirmed GPS-lock cluster.
- Extended startup stable-anchor guarding to electric skateboard / electric longboard sessions so post-record medium-confidence convergence fixes are kept as red warm-up context instead of becoming the green route start.
- Added approximate start marker / approximate start semantics styling using a visually distinct hollow `play.circle` marker when the recording-start fix is low confidence, outside preferred accuracy, or when GPS lock is delayed after recording starts.
- Anchored the primary map region to post-GPS-lock route coordinates when available, preventing early convergence points from pulling the Summary Map away from the trusted route.
- Preserved red low-quality / startup dashed segments, warm-up segment isolation, and route accuracy disclosure without changing raw GPS storage, trusted metrics, exports, or `.skatetrack` schema.
- Deferred `.skatetrack` package-size optimization, IMU / gyro / heading-aided dead reckoning, Wi-Fi RTT diagnostics, and barometric outlier rejection to follow-up tasks.

Task-030c-b11-r3-3 verification token: Post-Record GPS Lock Guard + Approximate Start Semantics, Task-030c-b11-r3-3, GPS lock route anchor, approximate start marker / approximate start semantics, startup convergence warm-up, session-route-accuracy-disclosure, verify_task030c_startup_anchor_semantics.py.
Task-030c-b11-r3-3 deferred package-size token: `.skatetrack` export compression / thinning remains deferred and must preserve legacy plaintext package compatibility.

## Task-030c-b11-r4-1 — Heading Availability + GPS Gap Diagnostics + Dead Reckoning Readiness

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b11-r4-1`.
- Added optional `HeadingDiagnostics`, `GPSGapDiagnostics`, and `DeadReckoningDiagnostics` metadata under `LocationFixDiagnostics` so new sessions can describe route-continuity readiness without breaking legacy plaintext `.skatetrack` compatibility.
- Classified GPS update continuity as `normalCadence`, `shortGap`, `backgroundLocationGap`, or `extendedSignalLoss` from raw Core Location timestamp spacing and timer-fusion repeats.
- Recorded conservative course-over-ground heading availability from Core Location while explicitly deferring device magnetometer heading integration to a later task.
- Added dead-reckoning readiness diagnostics that mark whether a gap has a trusted anchor and heading signal, while keeping `estimatedRouteActive` false in r4.
- This task does not reconstruct route geometry, does not fabricate estimated route points, does not change distance / speed / altitude accumulators, and does not implement road snapping, map matching, Wi-Fi RTT, barometric GPS outlier rejection, or `.skatetrack` package-size optimization.

Task-030c-b11-r4-1 verification token: Heading Availability + GPS Gap Diagnostics + Dead Reckoning Readiness, Task-030c-b11-r4-1, HeadingDiagnostics, GPSGapDiagnostics, DeadReckoningDiagnostics, verify_task030c_r4_diagnostics_foundation.py.
Task-030c-b11-r4-1 compatibility token: legacy plaintext `.skatetrack` compatibility, diagnostics-only foundation, does not reconstruct route geometry.


### Task-030c-b11-r4-1 XCTest regression stabilization
- Task-030c-b11-r4-1 keeps the r4 diagnostics-only route-continuity foundation unchanged while stabilizing XCTest coverage after the r4 schema expansion.
- It removes UI-framework imports from the core SessionRecording coordinator boundary and keeps r4 diagnostics persistence covered by repository tests.


## Task-030c-b12-A — Altitude Outlier Guard + Per-Sample Diagnostics

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b12`.
- Added optional per-sample `AltitudeDiagnostics` metadata on `MotionSample` so new `.skatetrack` payloads can preserve raw altitude, trusted altitude, vertical accuracy, altitude delta, vertical speed, trust classification, and the reason for each altitude trust decision.
- Added `AltitudeOutlierGuardConfig` and a deterministic `AltitudeOutlierGuard` that keeps CoreLocation absolute altitude, barometer-relative altitude, and DEBUG-simulated altitude anchors source-isolated.
- Integrated altitude guard evaluation into `SensorFusionEngine` for raw location-fix samples and timer-fusion barometer-relative samples without generating fake barometer values or changing horizontal route geometry.
- Updated live and final elevation-gain calculation to prefer trusted b12 altitude diagnostics when present; rejected altitude outliers do not update trusted altitude anchors and do not inflate `elevationGainMeters`.
- Updated advanced elevation chart selection to prefer trusted altitude diagnostics, preserving raw altitude for diagnostics/export while avoiding obvious 100m-class spikes in trusted display paths.
- Added XCTest coverage for legacy sample decoding, diagnostics persistence/export, 100m spike rejection, poor vertical accuracy classification, and component-level isolation where altitude rejection does not drop horizontal coordinates or distance accumulation.

Task-030c-b12 verification token: AltitudeDiagnostics, AltitudeOutlierGuardConfig, AltitudeOutlierGuard, per-sample altitude diagnostics, component-level altitude isolation, source-isolated altitude anchors, no estimated route geometry, no SnowPrototype changes.
Task-030c-b12 limitation token: improves altitude robustness and elevation-gain honesty; does not guarantee survey-grade elevation precision; barometric pressure LPF and long-term atmospheric drift correction remain deferred.

Task-030c-b12 package capability token: altitude-diagnostics-v1.

## Task-030c-b12-B — Pressure smoothing diagnostics foundation

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b12-B`.
- Added `AltitudePressureDiagnostics`, `AltitudePressureFilterConfig`, and `AltitudePressureFilter` as a diagnostics-only pressure smoothing layer for barometer-relative altitude samples.
- Recorded raw pressure, smoothed pressure, previous smoothed pressure, pressure delta, filter alpha, and spike-suppression state inside optional per-sample `AltitudeDiagnostics.pressureDiagnostics`.
- Wired `BarometerProvider.pressureKilopascalsPublisher` into `SensorFusionEngine` so timer-fusion barometer-relative samples can carry pressure smoothing diagnostics without changing altitude, speed, distance, or route geometry.
- Preserved Task-030c-b12-A component-level altitude isolation and source-isolated altitude anchors. Pressure smoothing diagnostics are not used for atmospheric drift correction and do not blend CoreLocation absolute altitude with barometer-relative altitude.
- Added XCTest coverage for pressure spike suppression and Codable round-trip persistence of pressure diagnostics.

Task-030c-b12-B verification token: AltitudePressureDiagnostics, AltitudePressureFilterConfig, AltitudePressureFilter, pressureDiagnostics, pressure spike suppression, diagnostics-only pressure smoothing, no estimated route geometry, no SnowPrototype changes.
Task-030c-b12-B limitation token: Pressure LPF diagnostics are recorded, but long-term atmospheric drift correction, pressure-to-absolute-altitude conversion, full barometer fusion, IMU dead reckoning, Wi-Fi RTT, and indoor localization remain deferred.


## Task-030c-b13-A-4 — Route Confidence Visual + Freebord Confidence Calibration

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b13-A-4`.
- Changed low-confidence route rendering from semi-transparent dashed red to solid bright-orange low-confidence route segments and solid fluorescent-pink startup/warm-up segments with the same line weight and opacity as trusted teal/green segments.
- Preserved startup warm-up as a separate dashed style so GPS warm-up remains visually distinct from low-confidence-but-present route fixes.
- Calibrated the low-speed local metric outlier gate so the suspicious CoreLocation-speed rule only runs when CoreLocation actually reports a valid speed. Coordinate-derived speed no longer substitutes into that CoreLocation-specific gate, which prevents low-speed freebord carving under tree canopy from being over-penalized when `CLLocation.speed` is unavailable.
- Kept the coordinate-derived local-jump gate intact for genuinely implausible GPS teleports; no estimated route geometry, dead reckoning, map matching, road snapping, altitude, pressure, or summary metric logic changed.

Task-030c-b13-A-4 verification token: solid bright-orange low-confidence route segments and solid fluorescent-pink startup/warm-up segments, CoreLocation speed availability, coordinate-derived local jump gate unchanged, freebord confidence calibration, no estimated route geometry, no SnowPrototype changes.


### Task-030c-b13-A-4 — Display Metrics + Altitude Anchor + Route Color Semantics

- Added display-derived summary metrics so low-confidence-but-metric-eligible route samples can contribute to displayed distance and speed without rewriting recorded `.skatetrack` data.
- Updated speed charts to fall back to persisted diagnostics speed when `sample.speedKmh` is zero but CoreLocation or coordinate-derived diagnostics are metric-eligible.
- Updated elevation charts to display stable barometer-relative profiles against the first trusted absolute CoreLocation anchor when available.
- Updated route color semantics: trusted remains teal, low-confidence/uncertain is solid bright orange, and startup/warm-up/approximate-start is solid fluorescent pink.
- No recording, SensorFusionEngine, altitude/pressure guard, schema, or SnowPrototype changes.

Task-030c-b13-A-4 verification token: display-derived metrics, absolute elevation display anchor, diagnostics speed fallback, solid bright-orange low-confidence route segments, solid fluorescent-pink startup warm-up segments.

## Task-030c-b13-B-1 — Magnetometer Heading Diagnostics Foundation

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b13-B-1`.
- Added device magnetometer heading support to `GPSProvider` by starting/stopping CoreLocation heading updates alongside active ride location updates when heading is available.
- Extended optional `HeadingDiagnostics` with device heading degrees, heading accuracy, timestamp, age, course/device heading delta, agreement, and device-heading reliability fields while preserving legacy `.skatetrack` compatibility.
- Wired device heading into `SensorFusionEngine` location-fix and timer-fusion diagnostics so future dead-reckoning readiness can distinguish CoreLocation course-over-ground from device magnetometer heading.
- Kept `DeadReckoningDiagnostics.estimatedRouteActive` false. b13-B records readiness metadata only and does not reconstruct route geometry, estimate missing coordinates, map match, road snap, or alter distance/speed/altitude/summary metrics.

Task-030c-b13-B-1 verification token: magnetometer heading diagnostics foundation, deviceHeadingDegrees, deviceHeadingAccuracyDegrees, courseDeviceHeadingDeltaDegrees, courseDeviceHeadingAgreement, startUpdatingHeading, estimatedRouteActive false, no estimated route geometry, no SnowPrototype changes.


### Task-030c-b13-B-1 — Heading Diagnostics Legacy Decode Guard
- Added a custom `HeadingDiagnostics` decoder so sessions recorded before magnetometer heading diagnostics can still be read when newer b13-B fields are absent.
- Preserved `estimatedRouteActive == false`; this remains diagnostics-only and does not alter distance, speed, altitude, route confidence, or estimated route geometry.
- Verification token: Task-030c-b13-B-1, heading diagnostics legacy decode guard, `testB13B1HeadingDiagnosticsDecodesLegacyB13BPayload`.

## Task-030c-b15-B-3 — Replay-Only Dead-Reckoning Readiness Diagnostics

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b15-B-3`.
- Added `DeadReckoningReadinessAnalyzer`, `DeadReckoningReadinessConfig`, `DeadReckoningReadinessSummary`, and per-gap `DeadReckoningReadinessGapCandidate` diagnostics as a pure replay-only analysis layer over persisted `MotionSample` data.
- Classified GPS gap candidates by pre-gap anchor availability, post-gap anchor availability, timer-fusion IMU cadence, heading availability, heading age, and heading accuracy so future b14 phases can decide whether offline interpolation is even safe to prototype.
- Preserved b13-A-4 distance/altitude behavior and b13-B-1 legacy heading diagnostics decoding. The analyzer does not write estimated route points, does not mutate `MotionSample`, and does not alter route geometry, distance, speed, altitude, confidence colors, or summary metrics.
- Added XCTest coverage for replay-eligible gap classification, missing-heading blocking, and no-mutation / no-`estimatedRouteActive` behavior.
- Added `verify_task030c_b14a_dead_reckoning_readiness.py` to guard the replay-only scope and prevent estimated route geometry, map matching, road snapping, or SnowPrototype creep.

Task-030c-b15-B-3 verification token: replay-only dead-reckoning readiness diagnostics, DeadReckoningReadinessAnalyzer, DeadReckoningReadinessConfig, eligibleForReplay, blockingReasonCounts, preserves b13-A-4 distance/altitude behavior, preserves b13-B-1 legacy heading diagnostics decoding, estimatedRouteActive remains false, no estimated route geometry, no SnowPrototype changes.


## Task-030c-b15-B-3 — Altitude Chart Source Guard

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b15-B-3`.
- Added a display-only altitude chart source guard in `SessionAdvancedChartsView`: when barometer-relative samples are available, the elevation profile now stays altitude-source aware and no longer creates visual breaks from unrelated GPS stale/gap diagnostics.
- Tightened trusted altitude display extraction so sessions with altitude diagnostics do not fall back to raw rejected samples; raw altitude fallback remains available only for legacy packages without altitude diagnostics.
- Preserved stored motion samples, route geometry, distance, speed, elevation gain summaries, b14-A replay-only readiness diagnostics, and b13-B-1 legacy heading diagnostics decoding.

Task-030c-b15-B-3 verification token: altitude chart source guard, barometer-relative altitude profile, display-only, does not rewrite stored samples, route geometry unchanged, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Altitude Chart Micro-Dip Display Guard

- Added a display-only micro-dip guard to the iOS advanced elevation chart.
- The guard is applied only after the b14-A-1 barometer-relative source guard selects the barometer profile.
- It only suppresses very short local notches where the left and right local baselines agree and the center point drops sharply below both sides.
- It does not rewrite stored samples, does not change elevation gain summaries, does not change route geometry, and does not enable dead reckoning.
- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b15-B-3`.

Task-030c-b15-B-3 verification token: altitude micro-dip display guard, display-only micro-dip guard, barometer-relative chart profile, no stored sample rewrite, no elevation summary mutation, route geometry unchanged, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Startup Route Visual Suppression

- Updated the internal diagnostics build identity and Debug Tools build signature to `Task-030c-b15-B-3`.
- Restored startup / GPS warm-up route drawing to solid fluorescent-pink route context while keeping early low-confidence or convergence geometry separated from confirmed route.
- Preserved trusted teal route and bright-orange uncertain route semantics while preventing startup context from bridging into the first trusted GPS-lock segment.
- This is display-only: it does not delete raw GPS samples, does not rewrite stored samples, does not change distance, speed, altitude, elevation gain, route geometry, exports, or diagnostics, and does not enable dead reckoning.

Task-030c-b15-B-3 verification token: startup route visual suppression, solid fluorescent-pink route context, display-only, no stored sample rewrite, route geometry unchanged, estimatedRouteActive remains false.

Task-030c-b15-B-3 display token: solid fluorescent-pink startup/warm-up context.

## Task-030c-b15-B-3 — Replay-Only Candidate Gap Interpolation Prototype
- Added `DeadReckoningCandidateInterpolationAnalyzer`, `DeadReckoningCandidateInterpolationConfig`, `DeadReckoningCandidateInterpolationSummary`, and debug-only interpolation result models on top of b14-A readiness diagnostics.
- The analyzer creates candidate points only for replay/debug diagnostics when readiness, anchor closure, IMU cadence, and heading diagnostics are conservative enough.
- Restored startup / GPS warm-up route visual semantics to solid fluorescent-pink route context with full route-line weight while preserving A-2 segment separation from trusted teal GPS-lock geometry.
- Preserved `estimatedRouteActive == false`; candidate interpolation does not mutate `MotionSample`, does not rewrite `.skatetrack`, and does not change route geometry, distance, speed, altitude, or summaries.

Task-030c-b15-B-3 verification token: replay-only candidate gap interpolation, DeadReckoningCandidateInterpolationAnalyzer, debugCandidateOnly, anchorClosureTooLarge, solid fluorescent-pink startup/warm-up route context, no production estimated route geometry, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Summary Elevation Gain Source Guard
- Fixed the Summary climb card so display-derived `elevationGainMeters` prefers trusted barometer-relative altitude whenever that stream is present, matching the advanced elevation chart source guard.
- Prevented Core Location absolute altitude jitter from contributing to the user-facing climb total in sessions that already contain trusted barometer-relative altitude.
- Preserved raw altitude diagnostics, persisted samples, route geometry, distance, speed, altitude charts, b14-B replay-only candidate interpolation, and `estimatedRouteActive == false`.
Task-030c-b15-B-3 verification token: summary elevation gain source guard, trusted barometer-relative climb, no Core Location absolute altitude jitter accumulation, no stored sample rewrite, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Total Elevation Gain Terminology
- Renamed the user-facing Summary / share-card elevation-gain metric from the shorter Traditional Chinese label `爬升` to `總爬升量` so the UI describes the cumulative positive-gain metric more explicitly.
- Updated localization consistently across supported summary locales: Traditional Chinese `總爬升量`, English `Total elevation gain`, and Japanese `総獲得標高`.
- Preserved the b14-B-1 trusted altitude-source calculation: the metric is still cumulative positive elevation gain from trusted altitude sources, not max altitude minus start altitude.
- This task is terminology-only: it does not change raw samples, `.skatetrack` schema, route geometry, distance, speed, altitude charts, summary calculation logic, replay-only candidate interpolation, or `estimatedRouteActive`.

Task-030c-b15-B-3 verification token: total elevation gain terminology, summary.metric.elevationGain, 總爬升量, Total elevation gain, 総獲得標高, no calculation change, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Simulator Recording Persistence Guard
- Added a DEBUG / iOS Simulator persistence guard so simulator live recordings no longer disappear silently when the underlying sensor stop snapshot contains no `MotionSample` entries.
- The coordinator now retains live samples observed through `handleMotionSample` and can recover them into the persisted session when the simulator stop snapshot is empty.
- If a DEBUG simulator session ends before any live sample arrives, the coordinator creates a small debug-simulated route sample set using the existing `DebugOutdoorRouteSimulator`, ensuring the session can be saved and inspected in History.
- Preserved production behavior: this fallback is gated to DEBUG iOS Simulator live sessions only and does not modify real-device recording, `.skatetrack` schema, distance/speed/elevation calculations, or production route estimation.

Task-030c-b15-B-3 verification token: simulator recording persistence guard, debugSimulatorPersistenceSessionIfNeeded, liveSessionSamples, debugSimulatorPersistenceFallback, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Debug Mock Recording Pipeline Hardening
- Moved DEBUG mock route sample delivery onto the main queue so the coordinator, Live HUD, and save path observe one deterministic sample stream.
- Appends every `debugSimulated` sample to the mock recording buffer, including simulator fallback samples that are not created by an explicitly toggled demo-speed session.
- Broadcasts a local session-save notification and reloads History when a simulator/debug session is saved, preventing a stale list from looking like persistence failed.
- Lets DEBUG simulated speed drive the Live HUD trace directly so simulator validation shows a changing curve instead of a flat line.
Task-030c-b15-B-3 verification token: debug mock recording pipeline, simulator recording persistence guard, history save notification, Live HUD trace update, no production estimated route geometry, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Simulator Save Pipeline Hardening
- Hardened `SessionEntityMapper` so optional DEBUG recording diagnostics cannot block saving a valid simulator session when the diagnostics payload contains non-conforming floating-point values.
- Added non-conforming float encode/decode support to the motion-sample store and Core Data mapper encoding helpers.
- Verified the Core Data row exists after `saveCompletedSession`; if row persistence fails, the freshly written motion sample file is cleaned up to avoid invisible orphan files.
- Made recent-history fetch resilient to individual legacy/corrupt rows so valid sessions remain visible.
Task-030c-b15-B-3 verification token: simulator save pipeline hardening, safeEncodedDebugRecordingDiagnostics, orphan sample cleanup, resilient History fetch, no production estimated route geometry, estimatedRouteActive remains false.

### Task-030c-b16-A — Localization Foundation Audit and Sensor-Fusion Plan

- Added `docs/planning/Task-030c-b16_Localization_Foundation_Plan.md` as the repo-local post-b15-B-3 localization foundation checkpoint before b16-B/C/D implementation.
- Documented existing `MotionSample`, `LocationFixDiagnostics`, altitude diagnostics, heading diagnostics, route confidence colors, simulator-only paths, real-device-only validation paths, and replay-only dead-reckoning readiness.
- Defined b16-B as diagnostics-only barometric GPS cross-validation, b16-C as passive Wi-Fi RTT / accuracy-source diagnostics, and b16-D as magnetometer heading quality consolidation.
- Reaffirmed that indoor localization is deferred to Task-031 and that camera localization, road snapping, fake GPS, RTK, UWB anchor dependency, and SnowPrototype contamination remain out of Task-030c scope.
- Advanced the DEBUG build identity to `Task-030c-b16-A` without changing SensorFusionEngine behavior, route geometry, trusted distance, speed, average speed, max speed, moving ratio, total elevation gain, raw samples, persistence schema, or production estimated route display.

Task-030c-b16-A verification token: Localization Foundation Audit and Sensor-Fusion Plan, Task-030c-b16-A, b16-B diagnostics-only, b16-C passive Wi-Fi RTT diagnostics, b16-D heading quality consolidation, indoor localization deferred to Task-031, estimatedRouteActive remains false.

### Task-030c-b16-B — Barometric GPS Outlier Cross-Validation Diagnostics

- Added diagnostics-only barometric GPS outlier cross-validation for suspicious GPS jumps.
- Added `BarometricGPSOutlierDecision` with `productionRouteDecisionApplied` hard-coded to `false` and `wouldRejectIfGateWereEnabled` as diagnostic evidence only.
- Added optional `barometricGPSOutlierDecision` to `LocationFixDiagnostics` so legacy `.skatetrack` sessions decode without the new field.
- Split the implementation into new model / guard / SensorFusionEngine extension files instead of expanding existing oversized legacy production files.
- Advanced the DEBUG build identity to `Task-030c-b16-B` without enabling estimated routes, rejecting production route fixes, mutating raw samples, or changing trusted distance, speed, average speed, max speed, moving ratio, or total elevation gain.

Task-030c-b16-B verification token: barometric GPS outlier cross-validation diagnostics, diagnostics-only, productionRouteDecisionApplied false, wouldRejectIfGateWereEnabled, estimatedRouteActive remains false.

### Task-030c-b16-C — Passive Wi-Fi RTT / Accuracy Source Diagnostics

- Added passive accuracy-source diagnostics that classify CoreLocation accuracy evidence into likely high-precision GPS or possible Wi-Fi RTT assisted categories without using explicit Wi-Fi APIs.
- Added `LocationAccuracySourceDiagnostics` with `passiveInferenceOnly` forced to true, `explicitWiFiAPIUsed` forced to false, and `wifiRTTConfirmed` forced to false during construction and decoding.
- Added `LocationAccuracySourceClassifier` to keep heuristic classification outside legacy oversized model files.
- Added optional `locationAccuracySourceDiagnostics` to `LocationFixDiagnostics` so legacy `.skatetrack` sessions decode without the new field.
- Advanced the DEBUG build identity to `Task-030c-b16-C` without changing route geometry, trusted distance, speed, average speed, max speed, moving ratio, total elevation gain, raw samples, production route acceptance, or estimated route display.

Task-030c-b16-C verification token: passive accuracy-source diagnostics, no Wi-Fi entitlement, no Wi-Fi scanning, no confirmed Wi-Fi RTT claim, estimatedRouteActive remains false.

### Task-030c-b16-D — Magnetometer Heading Quality Consolidation

- Added `HeadingReliability`, `HeadingQualityConfig`, and `HeadingQualityAssessment` as small shared diagnostics models for replay-readiness classification.
- Added `HeadingQualityClassifier` so existing `HeadingDiagnostics` can be classified without expanding legacy oversized model or sensor-fusion files.
- Added XCTest coverage for high, moderate, too-old, invalid, unavailable, and Codable round-trip heading quality boundaries.
- Advanced the DEBUG build identity to `Task-030c-b16-D` without changing route geometry, trusted distance, speed, average speed, max speed, moving ratio, total elevation gain, raw samples, production route acceptance, or estimated route display.

Task-030c-b16-D verification token: magnetometer heading quality consolidation, HeadingReliability, HeadingQualityAssessment, HeadingQualityClassifier, replay-readiness only, no production estimated route geometry, estimatedRouteActive remains false.

### Task-030c-b17 — Localization Diagnostics Review Pack

- Added `LocalizationDiagnosticsReviewPack`, `LocalizationDiagnosticsReviewSummary`, and `LocalizationDiagnosticsReviewSample` to consolidate b16-B/C/D diagnostics for replay-only review.
- Added `LocalizationDiagnosticsReviewBuilder` so session samples can be summarized without expanding oversized legacy model or sensor-fusion files.
- Added XCTest coverage for barometric outlier summary counts, passive accuracy-source counts, heading replay-readiness counts, safety flags, and empty-diagnostics behavior.
- Advanced the DEBUG build identity to `Task-030c-b17` and moved the visible DEBUG task token / badge through `Localizable.strings`.
- Kept b17 diagnostics-only and replay-review-only: no route geometry mutation, trusted metric mutation, production route rejection, Wi-Fi entitlement, Wi-Fi scan, road snapping, map matching, raw sample mutation, or production estimated route display.

Task-030c-b17 verification token: localization diagnostics review pack, diagnosticsOnly true, replayReviewOnly true, productionRouteMutationApplied false, localized DEBUG build signature, estimatedRouteActive remains false.

### Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation

- v1.2 alignment checkpoint for `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`.
- Reclassified the already-pushed `Task-030c-b17` localization diagnostics review pack as `Task-030c-b17-0` / preflight foundation because `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` defines b17 as the replay-only IMU gap interpolation engine.
- Added a v1.2 alignment verify guard so future Task-030c hotfixes must check the plan before continuing.
- Added the v1.2-named b16-C verifier alias `verify_task030c_b16c_wifi_rtt_accuracy_source_diagnostics.py` while keeping the implemented passive accuracy-source verifier name honest and non-RTT-confirming.
- Preserved the existing diagnostics-only boundary: no route geometry mutation, no trusted metrics mutation, no production estimated route display, and `estimatedRouteActive` remains false.

Task-030c-b17-0 verification token: v1.2 alignment checkpoint, b17 preflight only, next milestone is Task-030c-b17-A local tangent coordinate frame and sensor bias foundation, estimatedRouteActive remains false.


### Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation

- Added `LocalTangentPlane` and `LocalTangentMeters` for deterministic ENU conversion around a GPS anchor without storing production route geometry.
- Added `IMUBiasEstimator`, `IMUBiasEstimatorConfig`, and `IMUBiasEstimate` for low-motion accelerometer bias estimation over replay/debug samples.
- Added `GravityCompensatedMotionSample` to remove the estimated accelerometer bias and gravity axis before future b17-B replay-only integration.
- Added `IMULocalFrameBiasFoundationTests` covering Taipei-latitude ENU round trip, synthetic bias convergence, high-motion refusal, and gravity compensation.
- Advanced the DEBUG build identity to `Task-030c-b17-A` while keeping `estimatedRouteActive` false and preserving trusted metrics.

Task-030c-b17-A verification token: v1.2 b17-A local tangent coordinate frame and sensor bias foundation, no route geometry, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b17-B — Replay-Only Dead Reckoning Engine v1

- Added `DeadReckoningReplayEstimate`, `DeadReckoningReplayDiagnostics`, `DeadReckoningEstimateSource`, and `DeadReckoningConfidence` as replay-only diagnostic outputs.
- Added `DeadReckoningEngine` to generate candidate IMU replay estimates between trusted GPS anchors using b17-A `LocalTangentPlane`, `IMUBiasEstimator`, and `GravityCompensatedMotionSample`.
- Added conservative drift growth through the named `estimatedPositionDriftRateMetersPerSecond` constant so b17-D real-session closure data can later calibrate it.
- Added deterministic XCTest coverage for synthetic acceleration, constant heading velocity, missing heading confidence downgrade, policy gap blocking, anchor closure error, and drift-rate accuracy growth.
- Advanced the DEBUG build identity to `Task-030c-b17-B` while keeping `estimatedRouteActive` false and preserving trusted metrics.

Task-030c-b17-B verification token: v1.2 replay-only dead reckoning engine, DeadReckoningReplayEstimate, anchor closure error, no production route geometry, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b17-C — Anchor Closure Error and Confidence Scoring

- Added `DeadReckoningClosureDiagnostics` for b17-C replay-only closure scoring output.
- Added `DeadReckoningClosureScorer` with conservative v1.2 gates for gap duration, closure error, heading reliability, and IMU sample coverage.
- Extended b17-B replay diagnostics to attach closure diagnostics without changing production route geometry, route maps, exports, or trusted metrics.
- Added deterministic XCTest coverage for low closure eligibility, high closure blocking, missing heading blocking, low IMU coverage blocking, very long gap blocking, and replay diagnostics closure attachment.
- Advanced the DEBUG build identity to `Task-030c-b17-C` while keeping `estimatedRouteActive` false.

Task-030c-b17-C verification token: v1.2 anchor closure error and confidence scoring, DeadReckoningClosureDiagnostics, DeadReckoningClosureScorer, no user-visible route display, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b17-D — Real-Session Replay Review Pack

- Added `DeadReckoningReplayReviewPack`, `DeadReckoningReplayReviewSessionSummary`, and `DeadReckoningReplayReviewGapRecord` as shared b17-D review-pack models.
- Added `DeadReckoningReplayReviewPackBuilder` to convert real-session replay diagnostics into JSON, Markdown, and CSV artifact contents for `Task030c_b17D_ReplayReviewPack.zip`.
- Added deterministic XCTest coverage for eligible gaps, blocked gaps, artifact rendering, replay-only safety flags, and blocking-reason preservation.
- Advanced the DEBUG build identity to `Task-030c-b17-D` while keeping `estimatedRouteActive` false and preserving trusted metrics.

Task-030c-b17-D verification token: v1.2 real-session replay review pack, JSON / Markdown / CSV artifacts, gap duration, IMU coverage, heading reliability, estimated displacement, closure error, eligibility, blocking reasons, product decision checkpoint required, no user-visible route display, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b17-D-3 — Real-Session Review Runner / Export Glue

- Added an offline runner for real `.skatetrack` session exports.
- Added metrics glue to convert location-fix gaps and timer-fusion samples into b17-D review-pack fields: gap duration, IMU coverage, heading reliability, estimated displacement, anchor closure error, closure-error ratio, conservative eligibility, and blocking reasons.
- The runner writes `Task030c_b17D_ReplayReviewPack.zip` with JSON, Markdown, and CSV artifacts for real-session product-decision review.
- Preserved the b17-D safety boundary: no route map rendering, no production route mutation, no trusted metrics mutation, and no user-visible estimated route display.

Task-030c-b17-D-3 verification token: real-session runner / export glue, `.skatetrack` inputs, review-only artifacts, product decision checkpoint required, estimatedRouteActive remains false.

### Task-030c-b18-A — Product Decision Gate and In-Memory Estimated Route Display Decision

- Implements the b18-A product decision gate using `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md` as the controlling implementation baseline.
- Added `EstimatedRouteDisplayDecision` and `EstimatedRouteDisplayDecisionState` as shared, in-memory-only review decision outputs for b17-D gap records.
- Added `EstimatedRouteDisplayGate` and `EstimatedRouteDisplayGatePolicy` to classify b17-D replay review gaps into `blocked`, `reviewOnly`, `candidateButHidden`, or `eligibleForFutureProductReview` without enabling product UI.
- Keeps estimated route display decisions in memory only. No Core Data attribute, SessionRepository persistence, SessionEntityMapper mapping, or `.skatetrack` package schema change is introduced.
- Records the b18 product-decision refinement from the v1.2 plan: candidate user-visible estimated-route consideration is tightened to very short gaps, with `maximumCandidateGapDurationSeconds = 6`, while gaps up to `maximumReviewOnlyGapDurationSeconds = 30` remain review-only evidence only.
- This two-tier 6s / 30s policy is intentionally more conservative than the original v1.2 candidate threshold because the b17-D-3 real-session review pack found 0 eligible gaps for the core electric-skateboard session and large closure errors in several real sessions.
- Advanced the DEBUG build identity to `Task-030c-b18-A` while keeping `estimatedRouteActive` false.
- No general-user estimated route display is enabled. `productionRouteMutationApplied`, `trustedMetricsMutationApplied`, and `estimatedRouteDisplayEnabled` remain false.

Task-030c-b18-A verification token: in-memory product decision gate, named 6s / 30s threshold constants, no Core Data persistence, no SessionRepository persistence, no SessionEntityMapper mapping, no `.skatetrack` schema change, no trusted metric mutation, no route map display, estimatedRouteActive remains false.


### Task-030c-b18-B — Review-Only Estimated Route Overlay Artifact

- Implements the b18-B review-only overlay artifact using `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md` as the controlling implementation baseline.
- Added `EstimatedRouteReviewOverlay` and `EstimatedRouteReviewOverlayRecord` as shared review-only artifact models for b18-A display decisions.
- Added `EstimatedRouteReviewOverlayBuilder` to convert b18-A decisions into overlay records carrying session role labels, decision states, blocking reasons, and safety flags without route geometry.
- Added deterministic XCTest coverage for the five b17-D-3 real-session regression roles: electric skateboard core candidate, walking low-speed trap, sheltered surfskate high-risk case, motorcycle pressure test, and motorcycle control sample.
- Advanced the DEBUG build identity to `Task-030c-b18-B` while keeping `estimatedRouteActive` false.
- No general-user estimated route display is enabled. No Core Data, SessionRepository, SessionEntityMapper, `.skatetrack` schema, route map, or trusted metric mutation is introduced.

Task-030c-b18-B verification token: review-only overlay artifact, five real-session regression traps, no user-visible estimated route display, no route geometry, no persistence, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b18-C — DEBUG-Only Estimated Route Review Panel

- Implements the b18-C DEBUG-only review panel using `Task-030c-b18-C_DEBUG_Review_Panel_Mini_Plan_EN_v1.1.md` as the controlling implementation note while remaining aligned with `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` and the b18 v1.1 plan.
- Added `EstimatedRouteReviewPanel` as a fully `#if DEBUG`-wrapped SwiftUI review panel for b18-B overlay records.
- Added deterministic DEBUG XCTest coverage confirming the panel can be created with the five real-session regression roles while keeping all user-visible display, route-geometry, persistence, and trusted-metric safety flags disabled.
- Preserved the localization rule for DEBUG UI by adding `debug.estimatedRouteReview.*` keys to English, Traditional Chinese, and Japanese localization files.
- Advanced the DEBUG build identity to `Task-030c-b18-C` while keeping `estimatedRouteActive` false.
- No general-user estimated route display is enabled. No route polyline, path shape, map overlay, Core Data, SessionRepository, SessionEntityMapper, `.skatetrack` schema, route map, or trusted metric mutation is introduced.

Task-030c-b18-C verification token: DEBUG-only estimated route review panel, fully wrapped in `#if DEBUG`, localized panel text, no route rendering, no user-visible estimated route display, no route geometry, no persistence, no trusted metric mutation, estimatedRouteActive remains false.


### Task-030c-b18-D — Real-Session Recheck and Product Decision Update

- Implements the b18-D product decision update using `Task-030c-b18-D_Real_Session_Recheck_and_Product_Decision_Mini_Plan_EN_v1.0.md` as the controlling implementation note while remaining aligned with `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` and the b18 v1.1 plan.
- Added `EstimatedRouteProductDecisionUpdate` and `EstimatedRouteProductDecisionSessionSummary` as shared review-only product-decision records for the b18 real-session recheck.
- Added `EstimatedRouteProductDecisionUpdateBuilder` to summarize the five b17-D-3 real-session roles from b18-B overlay records and preserve the final `keepDisabled` decision.
- Added deterministic XCTest coverage confirming the electric skateboard core candidate, walking low-speed trap, sheltered surfskate high-risk case, and motorcycle pressure test do not become user-visible display candidates; motorcycle control remains limited hidden candidate evidence only.
- Advanced the DEBUG build identity to `Task-030c-b18-D` while keeping `estimatedRouteActive` false.
- No general-user estimated route display is enabled. No route geometry, Session Summary map mutation, trusted metric mutation, Core Data, SessionRepository, SessionEntityMapper, or `.skatetrack` schema change is introduced.

Task-030c-b18-D verification token: real-session recheck product decision update, `EstimatedRouteProductDecisionUpdate`, `EstimatedRouteProductDecisionUpdateBuilder`, outcome `keepDisabled`, five real-session roles, no user-visible estimated route display, no route geometry, no persistence, no trusted metric mutation, estimatedRouteActive remains false.


### Task-030c-b19 — Outdoor Localization Release Gate

- Implements the b19 outdoor localization release gate using `Task-030c-b19_Outdoor_Localization_Release_Gate_Mini_Plan_EN_v1.0.md` as the controlling implementation note while remaining aligned with `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` and the b18 v1.1 product decision plan.
- Added `OutdoorLocalizationReleaseGate`, `OutdoorLocalizationReleasePolicy`, and `OutdoorLocalizationReleaseEvidence` as shared review/release gate records for real-GPS outdoor localization quality.
- Added `OutdoorLocalizationReleaseGateBuilder` to classify deterministic outdoor localization evidence as `releaseReady`, `limitedDisclosure`, or `blocked` without enabling estimated route display.
- Added deterministic XCTest coverage for high-quality outdoor evidence, limited-disclosure evidence, low-speed trap evidence, sheltered/high-risk evidence, poor coverage, long gap, and empty evidence.
- Advanced the DEBUG build identity to `Task-030c-b19` while keeping `estimatedRouteActive` false.

Task-030c-b19 verification token: outdoor localization release gate, `OutdoorLocalizationReleaseGate`, `OutdoorLocalizationReleaseGateBuilder`, releaseReady, limitedDisclosure, blocked, realGPSOnly true, no user-visible estimated route display, no route geometry mutation, no persistence, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c Final Closure Audit — Post-b19 Documentation and Merge Readiness

- Prepared Task-030c for final closure after `2cc0550 Task-030c-b19 add outdoor localization release gate` rather than opening a new b20 milestone.
- Mapped the `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` Section 5 Final Definition of Done to the completed b13–b19 implementation chain.
- Confirmed the outdoor GPS fidelity scope is covered by the existing startup / warm-up honesty, low-confidence and warm-up route styling, small-area limitations disclosure, bad-GPS diagnostics, stable trusted metrics, freebord / low-speed calibration, and b19 outdoor localization release gate.
- Confirmed locked-screen / pocket continuity evidence is covered by GPS-gap detection, replay-only IMU estimates, anchor closure scoring, b17-D real-session review artifacts, and ineligible-gap disclosure.
- Confirmed the b18-D product decision remains `keepDisabled`; general-user estimated route display is not enabled in Task-030c closure.
- Confirmed indoor localization remains explicitly out of scope for Task-030c and is handed off to Task-031.
- Preserved all non-goals: no camera localization, no RTK dependency, no UWB consumer-flow dependency, no road snapping, no fake GPS, and no claim that small-area GPS can be perfectly reconstructed.
- Preserved trusted-metric honesty: no estimated geometry silently affects trusted distance, speed, average speed, max speed, moving ratio, or total elevation gain.
- Closure scope is docs-only. It does not add Swift files, product logic, persistence, route geometry, route rendering, trusted metric mutation, or schema changes.

Task-030c final closure verification token: Section 5 closure checklist mapped to commits, `2cc0550`, b18-D `keepDisabled`, b19 outdoor localization release gate, Task-031 indoor handoff, no user-visible estimated route display, no route geometry mutation, no trusted metric mutation, no persistence/schema mutation.

### Task-030d-A — iOS Multi-File `.skatetrack` Import Foundation

- Started Task-030d after Task-030c final closure and develop merge verification.
- Added an iOS multi-file `.skatetrack` import entry from History beside the existing selection action.
- Added a staged import coordinator that uses security-scoped access, copies selected files into temporary staging, validates each package independently, and classifies duplicates / already-imported sessions before commit.
- Added localized dark import preview UI with per-file status cards, partial success handling, user confirmation, and selected-valid-package commit.
- Preserved no silent overwrite: already-imported sessions and duplicate candidates are not auto-merged or overwritten.
- Kept the existing `.skatetrack` package schema unchanged and did not add custom UTType declarations, document associations, cloud sync, Watch / WatchBridge, Task-031, or Task-030e behavior.
- Preserved Task-030c safety boundaries: no general-user estimated route display, no route geometry mutation, no trusted metrics mutation, and no route reconstruction.

Task-030d-A verification token: iOS multi-file .skatetrack import foundation, History import button, staged validation, partial success preview, no silent overwrite, no package schema change, no route geometry mutation, no trusted metrics mutation, no Watch / Task-031 / Task-030e scope.

### Task-030e-MacViewer-002 — Browser-First IA Shell

- Aligned implementation scope with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.
- Made the macOS `Session Browser` the default browser-first destination for opening and reviewing `.skatetrack` packages.
- Moved the package open action into `MacSessionBrowserView` header / empty state flow while retaining `MacPackageImportViewModel` as the lower-level read-only package reader boundary.
- Demoted the standalone Import destination from the primary sidebar; macOS user-facing copy now uses Open Packages / Open Package language rather than implying database import.
- Preserved strict read-only behavior: no Core Data writes, no package schema changes, no merge/restore/sync, no route correction, no MapKit stage yet, and no Task-031 / Watch work.

Task-030e-MacViewer-002 verification token: browser-first Session Browser IA, Open Packages action in browser header, Import destination not primary sidebar, read-only package opening, `MacPackageBrowserHeaderView`, aligned Build Plan v1.2, no multi-package state yet, no MapKit yet, no route geometry mutation, no trusted metrics mutation, no persistence/schema mutation.

### Task-030e-MacViewer-003 — In-Memory Multi-Package Preview State

- Aligned implementation scope with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.
- Added `MacMultiPackageViewerState`, `MacMultiPackageViewerSelection`, and `MacPackageOpenBatchSummary` as the read-only in-memory state foundation for future multi-package browsing.
- Updated `MacPackageImportViewModel` to own package collection state, selected package state, selected session state, and future append / remove hooks while preserving the current single-file open behavior.
- Moved Session Browser selection ownership from view-local state into the view model boundary so later package cards and multi-file open can reuse the same model without Views owning package internals.
- Preserved browser-first behavior from Task-030e-MacViewer-002 and kept `NSOpenPanel.allowsMultipleSelection = false`; true multi-file open and package cards remain deferred to later Task-030e subtasks.
- Preserved strict read-only behavior: no Core Data writes, no package schema changes, no merge/restore/sync, no route correction, no MapKit stage yet, and no Task-031 / Watch work.

Task-030e-MacViewer-003 verification token: in-memory multi-package viewer state, `MacMultiPackageViewerState`, `MacMultiPackageViewerSelection`, `MacPackageOpenBatchSummary`, view-model owned package/session selection, single-file compatibility retained, multi-file open foundation added in Task-030e-MacViewer-004, no MapKit yet, no route geometry mutation, no trusted metrics mutation, no persistence/schema mutation.

### Task-030e-MacViewer-004 — Multi-File Open Foundation

- Aligned implementation scope with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.
- Added `MacPackageOpenCoordinator` to read multiple selected `.skatetrack` files independently through `SkateTrackPackageReader` with per-file extension validation, security-scoped access, and failure classification.
- Added `MacPackageOpenResult` / `MacPackageOpenFailure` and `MacPackageOpenResultStatusView` so partial success can be surfaced without hiding invalid package results.
- Updated `MacSessionBrowserView` to use `NSOpenPanel.allowsMultipleSelection = true` and call the view-model `openPackages(from:)` boundary from the browser.
- Updated `MacMultiPackageViewerState` with deterministic batch replacement and duplicate path de-duplication while keeping selection in memory only.
- Preserved strict read-only behavior: no custom UTType, no document association, no Core Data write, no persistent recent files/bookmarks, no merge/restore/sync, no MapKit stage yet, and no route correction.

Task-030e-MacViewer-004 verification token: Multi-File Open Foundation, `MacPackageOpenCoordinator`, `MacPackageOpenResultStatusView`, `allowsMultipleSelection = true`, independent package validation, partial success, read-only, no custom UTType, no document association, no MapKit yet, no route geometry mutation, no trusted metrics mutation, no persistence/schema mutation.

### Task-030e-MacViewer-005 — Package Cards and Batch Summary

- Aligned implementation scope with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.
- Added `MacPackageCardListView` to surface opened package cards, read-only batch summary, selected package state, package switching, and package removal from the macOS Session Browser.
- Updated `MacSessionBrowserView` to show package cards after multi-file open results and before the currently selected package session summary, resolving the Task-030e-004 limitation where multiple packages could be opened but not selected from the UI.
- Preserved Task-030e-MacViewer-004 multi-file open behavior and Task-030e-MacViewer-003 in-memory state without adding persistent recent files, bookmarks, drag-and-drop, Finder document association, or custom UTType declarations.
- Preserved strict read-only behavior: no Core Data writes, no package schema changes, no merge/restore/sync, no route correction, no MapKit stage yet, and no Task-031 / Watch work.

Task-030e-MacViewer-005 verification token: package cards and batch summary, `MacPackageCardListView`, selected package switching, package removal, read-only multi-package UI, aligned Build Plan v1.2, no MapKit yet, no route geometry mutation, no trusted metrics mutation, no persistence/schema mutation.

### Task-030e-MacViewer-006 — Selected Package Sessions List

- Aligned implementation scope with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.
- Added `MacPackageSessionListView` to show the sessions inside the currently selected opened package and switch the selected session for the read-only detail view.
- Updated `MacSessionBrowserView` so package selection from Task-030e-MacViewer-005 is followed by an explicit selected-package session list before the detail dashboard.
- Kept session selection in `MacPackageImportViewModel` / `MacMultiPackageViewerState`; the list is a read-only UI over already opened package payloads and does not write, merge, restore, sync, or persist packages.
- Preserved strict read-only behavior: no Core Data writes, no package schema changes, no merge/restore/sync, no route correction, no MapKit stage yet, and no Task-031 / Watch work.

Task-030e-MacViewer-006 verification token: selected package sessions list, `MacPackageSessionListView`, selected session switching, read-only detail update, aligned Build Plan v1.2, no MapKit yet, no route geometry mutation, no trusted metrics mutation, no persistence/schema mutation.


### Task-030e-MacViewer-007A — Read-Only MapKit Route Context

- Aligned implementation scope with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.
- Added `MacRouteMapContextView` as a read-only `MKMapView` bridge for macOS route previews, using only the existing route samples already present in opened `.skatetrack` packages.
- Updated `MacRoutePreviewView` to place the existing route preview on a MapKit context while preserving the route sample counts, unique point count, derived distance, start / finish markers, and read-only disclosure.
- Preserved strict safety boundaries: no current-location permission, no user-location display, no road matching, no snap-to-road, no route reconstruction, no route geometry mutation, no trusted metrics mutation, no package schema change, no Core Data write, no persistent recent files, and no expanded route inspection yet.

Task-030e-MacViewer-007A verification token: Read-Only MapKit Route Context, `MacRouteMapContextView`, `MKMapView`, existing route samples only, no current location, no road matching, no snap-to-road, no route geometry mutation, no trusted metrics mutation, no persistence/schema mutation, 007B deferred.

## Task-030e-MacViewer-007B — iOS Route Visual Parity + Expanded Route Inspection
- Added macOS read-only route visual parity colors using green route line, bright orange accent, and fluorescent pink glow to echo the iOS route language without representing correction, confidence, or matching state.
- Added expanded route inspection surface for larger route review, fit-to-route-bounds MapKit context, route metadata, and visual legend.
- Preserved Task-030e safety boundaries: no location permission, no user-location display, no road matching, no snapping, no route reconstruction, no route geometry mutation, no trusted metrics mutation, and no package/schema/database writes.

## 2026-07-04 — Task-030e-MacViewer-008 Selected Session Detail Layout Alignment

- Aligned the selected session detail dashboard with the Task-030e v1.2 macOS multi-package viewer plan.
- `MacSessionDetailView` now keeps metrics at the top and uses a `ViewThatFits` desktop layout so the route map remains the primary visual area while speed chart, route metadata, and privacy/read-only notes stay grouped nearby.
- Added `MacRouteInspectionWindowPresenter` so the expanded route inspector opens in a separate resizable route inspection window instead of a fixed sheet.
- `MacRouteInspectionView` keeps the same read-only MapKit route content and iOS route visual parity legend while explaining that the window can be resized and the map can be panned / zoomed normally.
- Added `scripts/verify_task030e_selected_session_detail_layout.py` and updated the 007B route visual inspection verifier for the window presenter architecture.
- No route geometry mutation, no trusted metrics mutation, no route correction, no road matching, no snap-to-road, no location permission, no user-location display, no package schema change, and no Core Data write were introduced.

## 2026-07-04 — Task-030e-MacViewer-008-1 Elevation Profile + Total Ascent Display Alignment

- Aligned the macOS selected-session detail dashboard with the iOS Summary metric set by adding the localized `summary.metric.elevationGain` total elevation gain card.
- Added `MacElevationDisplayPipeline` to produce display-only elevation profile points from existing package motion samples, preferring trusted altitude diagnostics and preserving barometer-relative/source-isolated behavior where available.
- Added `MacElevationProfileView` as a lightweight SwiftUI Path chart beside the existing macOS speed chart so the Session Browser can show both speed and elevation trends without adding Swift Charts or shared cross-platform pipeline scope yet.
- Updated `MacSessionViewerModel` to expose elevation profile points to the view layer while keeping package parsing, Core Data, route geometry, trusted metrics, and schema untouched.
- Added `scripts/verify_task030e_elevation_profile.py` for 008-1 source checks, project membership, line/header rules, docs coverage, localization key reuse, and no-mutation safety boundaries.
- No route geometry mutation, no trusted metrics mutation, no route correction, no road matching, no snap-to-road, no location permission, no user-location display, no package schema change, and no Core Data write were introduced.

Task-030e-MacViewer-008-1 verification token: Elevation Profile + Total Ascent Display Alignment, `MacElevationDisplayPipeline`, `MacElevationProfileView`, `summary.metric.elevationGain`, existing package motion samples only, display-only elevation profile, no trusted metrics mutation, no package schema change, no Core Data write, Task-031-prep shared activity visualization deferred.

## 2026-07-04 — Task-030e-MacViewer-009-1 Duplicate Attention Acknowledgement

- Added a read-only acknowledgement action for transient duplicate file path warnings in the macOS multi-package Session Browser.
- Acknowledging duplicate file path warnings clears the current visual warning state without removing packages, merging packages, choosing a winner, importing to local history, mutating schema, writing Core Data, or changing route geometry / trusted metrics.
- Reopening the same already-open package path removes the acknowledgement for that path and surfaces the duplicate attention warning again.

Task-030e-MacViewer-009-1 verification token: Duplicate Attention Acknowledgement, acknowledgeDuplicateFilePathWarnings, acknowledgedDuplicateFilePaths, mac.viewer.attention.acknowledge_duplicate_files, transient duplicate file path warning acknowledgement, no merge, no delete, no winner selection, no local history import.

## 2026-07-04 — Task-030e-MacViewer-009 Duplicate and Attention States

- Aligned the macOS multi-package viewer with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2` duplicate / attention scope.
- Added `MacPackageAttentionState` to classify exact duplicate file paths and duplicate session identifiers in the current read-only viewer session while leaving a package-identifier hook disabled until package metadata exposes a real stable package ID.
- Added `MacPackageAttentionSummaryView` so duplicate / attention warnings are visible as warnings, not destructive blockers, and read-only browsing remains available where safe.
- Updated package cards to surface attention badges and warning titles without adding merge, delete, winner selection, local-history import, persistence, or package mutation behavior.
- Added `scripts/verify_task030e_duplicate_attention.py` for 009 source checks, project membership, localization, docs, line/header rules, and no-mutation safety boundaries.
- No package merge, duplicate deletion, winner selection, local history import, route geometry mutation, trusted metrics mutation, package schema change, Core Data write, road matching, snap-to-road, route reconstruction, location permission, or user-location display was introduced.

Task-030e-MacViewer-009 verification token: Duplicate and Attention States, `MacPackageAttentionState`, `MacPackageAttentionSummaryView`, exact duplicate file path warnings, duplicate session identifier warnings, read-only browsing remains available where safe, no merge, no delete, no winner selection, no local history import, no package schema change, no Core Data write, aligned Build Plan v1.2.

## 2026-07-04 — Task-030e-MacViewer-009-1 duplicate acknowledgement button affordance hotfix

- Strengthened the macOS duplicate attention acknowledgement control so `已了解` reads as a clear button instead of a low-contrast text-like control.
- Kept acknowledgement behavior unchanged: only transient duplicate-file-path warnings are cleared, packages remain in memory, and reopening the same duplicate file path surfaces the warning again.
- Did not add merge, deletion, winner selection, local-history import, package mutation, route correction, road matching, snap-to-road, route reconstruction, Core Data writes, location permission, or user-location display.

## 2026-07-04 — Task-030e-MacViewer-010 Localization / Accessibility Pass

- Aligned the macOS multi-package Session Browser with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2` localization / accessibility scope.
- Added focused accessibility labels, hints, identifiers, and help text for package open / clear controls, duplicate attention acknowledgement, route inspection open / close controls, package card removal, session list cards, speed chart, and elevation chart.
- Added `mac.accessibility.*` localization keys in English, Traditional Chinese, and Japanese for the new accessibility copy.
- Tightened Japanese macOS viewer strings that were still generic or missing unit context, including package distance / speed / percent formats, empty-session copy, locked-viewer copy, and package-open copy.
- Treated package privacy-note text as verbatim exported package content rather than a localization key.
- Added `scripts/verify_task030e_localization_accessibility.py` for Task-030e-010 source-level checks.
- No package merge, duplicate deletion, winner selection, local-history import, route correction, road matching, snap-to-road, route reconstruction, location permission, user-location display, route geometry mutation, trusted metrics mutation, package schema change, or Core Data write was introduced.

Task-030e-MacViewer-010 verification token: Localization / Accessibility Pass, mac.accessibility.open_packages.button.label, mac.accessibility.acknowledge_duplicate_files.button.label, mac.accessibility.route_inspect_open.button.label, mac.accessibility.elevation_chart.label, accessibilityIdentifier, Text(verbatim: "• \\(note)"), no merge, no delete, no winner selection, no Core Data write.

## 2026-07-04 — Task-030e-MacViewer-011 Verifier / Test Foundation

- Aligned the macOS multi-package Session Browser with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2` verifier / test foundation scope.
- Added `scripts/verify_task030e_macos_multi_package_viewer.py` as the consolidated Task-030e source verifier covering browser-first IA, multi-file open support, in-memory multi-package state, duplicate attention acknowledgement, route MapKit boundaries, localization parity, Swift collaboration headers, line counts, documentation tokens, and no runtime-scope expansion.
- Added `scripts/run_task030e_macos_multi_package_viewer_oneclick.sh` as the source-controlled Task-030e one-click verification runner.
- The one-click runner packages verifier, build, line, diff, and status logs into `task030e_011_oneclick_*.zip`, then removes the temporary run directory and records `ONECLICK_RUN_DIR_REMOVED=YES` in the postpack log.
- The 011 verifier/test foundation remains source-level and build-log based; it does not add screenshot dependency, UI automation, package merge, duplicate deletion, winner selection, local-history import, package schema change, Core Data write, route geometry mutation, trusted metrics mutation, location permission, user-location display, Watch, WatchBridge, or Task-031 work.

Task-030e-MacViewer-011 verification token: Verifier / Test Foundation, verify_task030e_macos_multi_package_viewer.py, run_task030e_macos_multi_package_viewer_oneclick.sh, ONECLICK_RUN_DIR_REMOVED=YES, no package schema change, no Core Data write.

## 2026-07-04 — Task-030e-MacViewer-012 Documentation Sync

- Aligned the Task-030e macOS multi-package viewer documentation across the documentation index, development rules, release readiness, manual QA matrix, known limitations, ADR index, file structure, and development log.
- Documented the current macOS viewer state through Task-030e-MacViewer-011: browser-first multi-file `.skatetrack` open, in-memory package cards, selected sessions, read-only MapKit route context, route visual parity, expanded route inspection, display-only speed/elevation/total-ascent views, duplicate attention warnings, duplicate-file acknowledgement, localization/accessibility pass, and consolidated verification.
- Promoted one-click cleanup to a recurring docs rule: one-click verification packages logs into a zip, deletes the temporary run directory, and records `ONECLICK_RUN_DIR_REMOVED=YES` after packaging.
- Added `scripts/verify_task030e_documentation_sync.py` and included it in the Task-030e source-controlled one-click verification runner.
- No UI behavior, package opening behavior, package schema, Core Data write, local-history import, merge, duplicate deletion, winner selection, route geometry mutation, trusted metrics mutation, location permission, user-location display, Watch / WatchBridge, or Task-031 shared visualization pipeline work was introduced.

Task-030e-MacViewer-012 verification token: Documentation Sync, verify_task030e_documentation_sync.py, documentation index, release readiness, manual QA matrix, known limitations, ADR index, one-click cleanup rule, no route / metric / package mutation.


## 2026-07-04 — Task-030e-MacViewer-013 Manual QA Gate

- Added `docs/release/TASK030E_MANUAL_QA_GATE.md` as the source-controlled manual QA signoff checklist for the macOS multi-package viewer before final merge.
- Added `scripts/verify_task030e_manual_qa_gate.py` to verify manual-gate documentation, one-click runner inclusion, consolidated verifier inclusion, and no-scope-expansion boundaries.
- Updated release readiness, manual QA matrix, documentation index, development rules, known limitations, ADR index, file structure, consolidated verifier, and source-controlled one-click runner for the 013 gate.
- Manual QA remains operator-run and must be explicitly confirmed in the conversation before commit / push.
- No product UI behavior, package opening behavior, package schema, Core Data write, local-history import, merge, duplicate deletion, winner selection, route geometry mutation, trusted metrics mutation, location permission, user-location display, Watch / WatchBridge, or Task-031 shared visualization pipeline work was introduced.

Task-030e-MacViewer-013 verification token: Manual QA Gate, TASK030E_MANUAL_QA_GATE.md, verify_task030e_manual_qa_gate.py, operator signoff required, task030e_013_oneclick, no route / metric / package mutation.


## Task-030e-MacViewer-014 Final Merge Gate

- Added `docs/release/TASK030E_FINAL_MERGE_GATE.md` as the source-controlled final merge gate checklist for the macOS multi-package viewer branch.
- Added `scripts/verify_task030e_final_merge_gate.py` and wired it into the consolidated Task-030e verifier and one-click runner.
- Documented develop merge readiness, 014 one-click evidence, manual QA carry-forward, and final no-scope-expansion review.
- Preserved scope boundaries: no route / metric / package mutation, no package schema change, no Core Data write, no location permission, no user-location display, no Watch behavior, and no Task-031-prep implementation.

Task-030e-MacViewer-014 verification token: Task-030e-MacViewer-014 Final Merge Gate, TASK030E_FINAL_MERGE_GATE.md, verify_task030e_final_merge_gate.py, develop merge readiness.

## 2026-07-05 — Task-031-prep-ActivityViz-004 iOS Route Migration

- Migrated `SessionRouteMapView` to consume the Shared `RouteDisplayPipeline` / `RouteDisplayResult` for display-only route points and segments.
- Preserved iOS renderer responsibilities in `SessionRouteMapView`: MapKit rendering, route colors, line width, start / finish annotations, empty state, SwiftUI layout, localized disclosure text, and map region selection.
- Removed duplicated iOS route preparation helpers for filtering, timer-fusion fallback, startup warmup classification, GPS-lock clustering, small-area jitter suppression, smoothing, segmentation, location-fix keys, and distance calculation from `SessionRouteMapView`.
- Added `scripts/verify_task031_prep_004_ios_route_migration.py` for ActivityViz-004 source checks, iOS migration boundaries, renderer ownership, Shared UI-import guard, and no persistence/export/package mutation guard.
- Did not modify `MacRouteDisplayPipeline.swift`; macOS route migration remains deferred to ActivityViz-005.
- No route correction, road matching, map matching, snap-to-road, route reconstruction, stored route geometry mutation, trusted metrics mutation, persistence/export/package schema change, Core Data write/import/merge/restore, location permission request, or current user location display was introduced.

Task-031-prep-ActivityViz-004 verification token: iOS Route Migration, `SessionRouteMapView`, `RouteDisplayPipeline().makeDisplayRoute`, `RouteDisplayResult`, `RouteDisplaySemantic`, renderer remains iOS-owned, `MacRouteDisplayPipeline.swift` untouched, no persistence/export/package schema change, no route correction.

## 2026-07-05 — Task-031-prep-ActivityViz-005 macOS Route Migration

- Migrated `MacRouteDisplayPipeline` to consume the Shared `RouteDisplayPipeline` / `RouteDisplayResult` for display-only macOS route points while preserving macOS read-only package viewer behavior.
- Preserved macOS renderer ownership in `MacRoutePreviewView`, `MacRouteMapContextView`, `MacRouteInspectionView`, `MacRouteInspectionWindowPresenter`, and `MacRouteVisualStyle`: MapKit context, visual styles, preview / inspection UI, endpoint annotations, and SwiftUI layout remain macOS-owned.
- Removed duplicated macOS route preparation helpers for filtering, timer-fusion fallback, startup warmup classification, GPS-lock clustering, small-area jitter suppression, smoothing, route display point construction, and location-fix keys from `MacRouteDisplayPipeline`.
- Kept macOS display-only derived metrics, speed points, elevation gain, moving ratio, and read-only route summary derivation local to the macOS package viewer; these values are not written back to stored route geometry, trusted metrics, persistence, export, or package schema.
- Added `scripts/verify_task031_prep_005_macos_route_migration.py` for ActivityViz-005 source checks, macOS migration boundaries, iOS untouched guard, Shared UI-import guard, and no persistence/export/package mutation guard.
- Did not modify `SessionRouteMapView.swift`; iOS route migration remains untouched after ActivityViz-004.
- No route correction, road matching, map matching, snap-to-road, route reconstruction, stored route geometry mutation, trusted metrics mutation, persistence/export/package schema change, Core Data write/import/merge/restore, location permission request, or current user location display was introduced.

Task-031-prep-ActivityViz-005 verification token: macOS Route Migration, `MacRouteDisplayPipeline`, `RouteDisplayPipeline().makeDisplayRoute`, `RouteDisplayResult`, `ActivityRouteDisplayPoint`, macOS renderer remains macOS-owned, `SessionRouteMapView.swift` untouched, no persistence/export/package schema change, no route correction.

## 2026-07-05 — Task-031-prep-ActivityViz-006 Shared Speed Display Pipeline Shell

- Added `Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift` as a display-only Shared speed chart preparation shell from `MotionSample` source-of-truth speed data.
- Extended the speed display model shell with `segmentID` on `SpeedDisplayPoint` and `segmentCount` on `SpeedDisplaySummary` so later iOS/macOS chart adapters can preserve chart segmentation without moving renderer logic into Shared.
- Added `Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift` to verify speed point creation, display-only invalid/out-of-range speed dropping, gap segmentation, downsampling, and that stored sample speed metrics are not mutated.
- Added `scripts/verify_task031_prep_006_speed_pipeline.py` for ActivityViz-006 source checks, iOS/macOS speed chart untouched guards, route migration stability guards, Shared UI-import guard, and no persistence/export/package mutation guard.
- Did not modify `SpeedTimelineChartView.swift`, `SessionAdvancedChartsView.swift`, `MacSpeedSparklineView.swift`, route display pipelines, elevation display pipelines, stored speed metrics, trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, location permission request, or current user location display.

Task-031-prep-ActivityViz-006 verification token: Shared Speed Display Pipeline Shell, `SpeedDisplayPipeline`, `makeDisplaySpeed`, `SpeedDisplayPoint.segmentID`, `SpeedDisplaySummary.segmentCount`, `SpeedDisplayPipelineTests`, speed charts untouched, no persistence/export/package schema change, no speed metric mutation.


## 2026-07-05 — Task-031-prep-ActivityViz-007 iOS Speed Chart Migration

- Migrated the iOS speed timeline chart data adapter to consume the Shared `SpeedDisplayPipeline` / `SpeedDisplayResult` created in ActivityViz-006.
- Updated `SessionAdvancedChartsView` to build display-only speed results through `SpeedDisplayPipeline(configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 120)).makeDisplaySpeed(...)`, preserving the existing iOS chart point count cap while keeping SwiftUI rendering on iOS.
- Updated `SpeedTimelineChartView` to accept `SpeedDisplayResult` and map Shared `SpeedDisplayPoint` values into the existing segmented chart renderer.
- Preserved iOS renderer ownership: Swift Charts `LineMark`, chart labels, teal styling, empty state, card layout, locked preview behavior, localization keys, and accessibility identifiers remain iOS-owned.
- Did not modify `MacSpeedSparklineView.swift`; macOS speed chart migration remains deferred to ActivityViz-008.
- Did not modify Shared speed pipeline behavior, route display pipelines, elevation display pipelines, stored speed metrics, trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, location permission request, or current user location display.

Task-031-prep-ActivityViz-007 verification token: iOS Speed Chart Migration, `SpeedTimelineChartView`, `SessionAdvancedChartsView`, `SpeedDisplayPipeline(configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 120))`, `SpeedTimelineChartView(result: speedResult)`, `SpeedDisplayResult`, iOS renderer remains SwiftUI-owned, `MacSpeedSparklineView.swift` untouched, no persistence/export/package schema change, no speed metric mutation.


## 2026-07-05 — Task-031-prep-ActivityViz-008 macOS Speed Chart Migration

- Migrated the macOS speed sparkline data adapter to consume the Shared `SpeedDisplayPipeline` / `SpeedDisplayResult` created in ActivityViz-006.
- Updated `MacSessionViewerModel` to build display-only speed results through `SpeedDisplayPipeline(configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 180)).makeDisplaySpeed(...)`, preserving the existing macOS sparkline point-count cap while keeping SwiftUI rendering on macOS.
- Updated `MacSpeedSparklineView` to accept `SpeedDisplayResult` and map Shared `SpeedDisplayPoint` values into macOS-owned sparkline path segments.
- Updated `MacSessionDetailView` to pass `model.speedResult` into `MacSpeedSparklineView(result:)`.
- Preserved macOS renderer ownership: SwiftUI `Path`, cyan stroke styling, grid lines, empty state, card material, localization keys, and accessibility identifiers remain macOS-owned.
- Did not modify `SpeedTimelineChartView.swift`, `SessionAdvancedChartsView.swift`, Shared speed pipeline behavior, route display pipelines, elevation display pipelines, stored speed metrics, trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, location permission request, or current user location display.

Task-031-prep-ActivityViz-008 verification token: macOS Speed Chart Migration, `MacSpeedSparklineView`, `MacSessionViewerModel`, `MacSessionDetailView`, `SpeedDisplayPipeline(configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 180))`, `MacSpeedSparklineView(result: model.speedResult)`, `SpeedDisplayResult`, macOS renderer remains SwiftUI-owned, `SpeedTimelineChartView.swift` untouched, no persistence/export/package schema change, no speed metric mutation.

## 2026-07-05 — Task-031-prep-ActivityViz-009 Shared Elevation Display Pipeline Shell

- Added `Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift` as a display-only Shared elevation profile preparation shell from `MotionSample` source-of-truth altitude data.
- Extended the elevation display model shell with `segmentID`, selected elevation source, absolute-anchor status, segment count, and display-derived total-ascent summary fields so future iOS/macOS/watchOS renderers can consume stable visualization data without moving platform rendering into Shared.
- Added `Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift` to verify barometer-relative anchor alignment, Core Location trust filtering, gap segmentation, downsampling, and no stored sample mutation before any platform elevation chart migration.
- Added `scripts/verify_task031_prep_009_elevation_pipeline.py` for ActivityViz-009 source checks, Xcode project membership checks, iOS/macOS elevation renderer untouched guards, Shared UI-import guard, and no persistence/export/package mutation guard.
- Did not modify `ElevationProfileChartView.swift`, `SessionAdvancedChartsView.swift`, `MacElevationDisplayPipeline.swift`, `MacElevationProfileView`, route display pipelines, speed display pipelines, stored elevation/ascent metrics, trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, location permission request, current user location display, Watch UI, or Watch recording.

Task-031-prep-ActivityViz-009 verification token: Shared Elevation Display Pipeline Shell, `ElevationDisplayPipeline`, `makeDisplayElevation`, `ElevationDisplayPoint.segmentID`, `ElevationDisplaySummary.displayDerivedTotalAscentMeters`, `ElevationDisplayPipelineTests`, elevation renderers untouched, no persistence/export/package schema change, no elevation metric mutation.

## 2026-07-05 — Task-031-prep-ActivityViz-010 iOS Elevation Profile Migration

### Completed
- Migrated iOS `SessionAdvancedChartsView` elevation data preparation to consume `ElevationDisplayPipeline` with `ElevationDisplayConfiguration(maximumDisplayPointCount: 120)`.
- Preserved iOS renderer ownership by keeping `ElevationProfileChartView.swift` as the SwiftUI/Charts drawing surface that receives `SessionSummaryChartPoint` values.
- Removed duplicated iOS-only elevation source selection, absolute-anchor, micro-dip guard, smoothing, segmenting, and downsampling helpers from `SessionAdvancedChartsView`; Shared `ElevationDisplayPipeline` now owns display-only elevation semantics.
- Added `scripts/verify_task031_prep_010_ios_elevation_migration.py` to verify Shared elevation consumption, renderer untouched guard, route/speed/macOS invariants, line limits, and no persistence/export/package mutation.

### Validation Notes
- ActivityViz-010 intentionally does not modify `ElevationProfileChartView.swift`, `MacElevationDisplayPipeline.swift`, macOS elevation rendering, route display pipelines, speed display pipelines, stored elevation/ascent metrics, trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, cloud sync, location permission, current user location display, Watch UI, or Watch recording.

Task-031-prep-ActivityViz-010 verification token: iOS Elevation Profile Migration, `SessionAdvancedChartsView`, `ElevationDisplayPipeline(configuration: ElevationDisplayConfiguration(maximumDisplayPointCount: 120))`, `ElevationDisplayResult`, `chartPoints(from result: ElevationDisplayResult)`, `ElevationProfileChartView(points: elevationPoints)`, iOS renderer remains SwiftUI-owned, `ElevationProfileChartView.swift` untouched, no persistence/export/package schema change, no elevation metric mutation.

## 2026-07-05 — Task-031-prep-ActivityViz-011 macOS Elevation Profile Migration

- Migrated the macOS elevation profile data adapter to consume the Shared `ElevationDisplayPipeline` / `ElevationDisplayResult` created in ActivityViz-009.
- Demoted `MacElevationDisplayPipeline.swift` to a macOS adapter that builds `ElevationDisplayResult` with `ElevationDisplayConfiguration(maximumDisplayPointCount: 180)` and maps Shared `ElevationDisplayPoint` values into existing `MacElevationPoint` renderer data.
- Updated `MacSessionViewerModel` to keep `elevationResult`, `elevationPoints`, and display-only `displayElevationGainMeters` sourced from `ElevationDisplayResult.summary.displayDerivedTotalAscentMeters` with a stored/derived display-metric fallback.
- Updated `MacSessionDetailView` to display `model.displayElevationGainMeters` while keeping `MacElevationProfileView` and SwiftUI `Path` rendering on macOS.
- Preserved macOS renderer ownership: orange stroke styling, segmented path drawing, grid lines, empty state, material card layout, localization keys, and accessibility identifiers remain macOS-owned.
- Did not modify `SessionAdvancedChartsView.swift`, `ElevationProfileChartView.swift`, Shared elevation pipeline behavior, route display pipelines, speed display pipelines, stored elevation/ascent metrics, trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, cloud sync, location permission request, current user location display, Watch UI, or Watch recording.

Task-031-prep-ActivityViz-011 verification token: macOS Elevation Profile Migration, `MacElevationDisplayPipeline.elevationResult`, `ElevationDisplayPipeline(configuration: ElevationDisplayConfiguration(maximumDisplayPointCount: 180))`, `MacElevationProfileView(points: model.elevationPoints)`, `displayElevationGainMeters`, macOS renderer remains SwiftUI-owned, `SessionAdvancedChartsView.swift` untouched, no persistence/export/package schema change, no elevation metric mutation.

## 2026-07-05 — Task-031-prep-ActivityViz-012 Unified ActivityVisualizationPipeline Entry Point

- Added `Shared/ActivityVisualization/ActivityVisualizationPipeline.swift` as a display-only umbrella entry point that composes `RouteDisplayPipeline`, `SpeedDisplayPipeline`, and `ElevationDisplayPipeline` without rewriting their semantics.
- Added `ActivityVisualizationResult` and `ActivityVisualizationCompactSummary` so consumers that want all visualization data at once can receive route, speed, elevation, aggregate diagnostics, and a compact summary shell from one call.
- Kept iOS and macOS screen adapters on focused sub-pipelines for now; ActivityViz-012 does not force `SessionAdvancedChartsView`, `MacSessionViewerModel`, or renderer views to consume the umbrella API.
- Added `Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift` to verify umbrella output matches the focused sub-pipelines and that diagnostics / compact summary aggregation remains display-only.
- Added `scripts/verify_task031_prep_012_unified_pipeline.py` for ActivityViz-012 source checks, project membership, committed platform invariant guards, Shared UI-import guard, and no persistence/export/package mutation guard.
- Did not implement ActivityViz-013 Watch-ready compact route/speed/elevation adapters, Watch UI, Watch recording, route/speed/elevation behavior rewrites, stored/trusted metric mutation, persistence/export/package schema changes, Core Data writes/import/merge/restore, cloud sync, location permission request, or current user location display.

Task-031-prep-ActivityViz-012 verification token: Unified ActivityVisualizationPipeline Entry Point, `ActivityVisualizationPipeline.makeVisualization`, `ActivityVisualizationResult`, `ActivityVisualizationCompactSummary`, focused sub-pipelines preserved, no forced platform view migration, no persistence/export/package schema change, no trusted metric mutation.

### Task-031-prep-ActivityViz-013 Watch-ready Compact Adapter Contract

- Added `Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift` as a display-only compact contract for future watchOS summaries.
- Expanded `ActivityVisualizationCompactSummary` to carry `CompactRouteDisplay`, `CompactSpeedSparkline`, and `CompactElevationProfile` while preserving existing quality/count fields.
- Added `CompactActivityVisualizationTests.swift` to verify compact payload construction, standalone `CompactRouteDisplay` initialization without requiring a full `RouteDisplayResult`, and compact sparkline normalization/downsampling.
- Updated Xcode project membership for the compact Shared file across iOS/macOS/watchOS and the compact test file in the iOS test target.
- Focused sub-pipelines and platform renderers are preserved; no forced platform view migration.
- Not implementing ActivityViz-014 cross-platform verifier, Watch UI, Watch recording, route/speed/elevation behavior rewrites, stored/trusted metric mutation, persistence/export/package schema change, Core Data writes/import/merge/restore, cloud sync, location permission request, or current user location display.

- ActivityViz-013 verification note: no Watch UI, no Watch recording, and no current-user-location behavior are introduced.

## 2026-07-05 — Task-031-prep-ActivityViz-014 Cross-platform Visualization Verifier

- Added `scripts/verify_task031_prep_014_cross_platform_visualization.py` as the cross-platform static verifier for the Shared ActivityVisualization stack.
- The verifier checks route/speed/elevation focused pipelines, the ActivityViz-012 umbrella pipeline, and the ActivityViz-013 compact adapter contract together.
- Added guards for iOS/macOS/watchOS Shared source membership, ActivityVisualization test target membership, 500-line Swift limits, Shared UI-import boundaries, compact/displayDerived persistence/export/package safety, and platform renderer ownership.
- ActivityViz-014 intentionally does not change production visualization behavior, platform renderers, Watch UI, Watch recording, stored/trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, cloud sync, location permission, or current user location display.

Task-031-prep-ActivityViz-014 verification token: Cross-platform Visualization Verifier, `verify_task031_prep_014_cross_platform_visualization.py`, Shared ActivityVisualization source membership, iOS/macOS/watchOS membership, Shared UI-import guard, platform renderer ownership, compact/displayDerived persistence/export/package guard, no Watch UI, no Watch recording, no persistence/export/package schema change.
## 2026-07-05 — Task-031-prep-ActivityViz-015 Docs / ADR Final Sync

- Synchronized Task-031-prep documentation across `DEV_LOG.md`, `FILE_STRUCTURE.md`, `ADR-INDEX.md`, and `KNOWN_LIMITATIONS_PRE_ADP.md` for ActivityViz-001 through ActivityViz-014.
- Re-stated the Task-031-prep ownership principle: Shared decides visualization data semantics; platforms decide rendering.
- Documented the completed Shared display stack: route/speed/elevation focused pipelines, the ActivityViz-012 `ActivityVisualizationPipeline` umbrella entry point, the ActivityViz-013 compact route/speed/elevation adapter contract, and the ActivityViz-014 cross-platform visualization verifier.
- Preserved the boundary that platform views may keep focused sub-pipeline usage when cleaner; ActivityViz-012/013 do not force every iOS/macOS/watchOS consumer onto the umbrella API.
- Added ADR and limitation notes that ActivityViz display data is display-only and must not write compact/displayDerived values into persistence, export, package schema, Core Data, trusted metrics, Watch recording, location permission, or current-user-location behavior.
- ActivityViz-015 intentionally does not modify production Swift source, Xcode project membership, tests, iOS/macOS renderers, Watch UI, Watch recording, route/speed/elevation behavior, stored/trusted metrics, persistence/export/package schema, Core Data writes/import/merge/restore, cloud sync, location permission, or current user location display.

Task-031-prep-ActivityViz-015 verification token: Docs / ADR Final Sync, Shared decides visualization data semantics; platforms decide rendering, focused pipelines documented, `ActivityVisualizationPipeline`, `ActivityVisualizationCompactSummary`, `CompactRouteDisplay`, `CompactSpeedSparkline`, `CompactElevationProfile`, Cross-platform Visualization Verifier documented, ActivityViz-016 remains final parity gate, no Watch UI, no Watch recording, no persistence/export/package schema change.


## 2026-07-05 — Task-031-prep-ActivityViz-016 Final Parity Gate

- Added `scripts/verify_task031_prep_016_final_parity_gate.py` as the final Task-031-prep static parity gate for the Shared ActivityVisualization display-preparation layer.
- Confirmed the completed ActivityViz stack remains aligned: route, speed, elevation, unified `ActivityVisualizationPipeline`, `ActivityVisualizationResult`, `ActivityVisualizationCompactSummary`, `CompactRouteDisplay`, `CompactSpeedSparkline`, and `CompactElevationProfile` remain display-only contracts.
- The final parity gate composes the ActivityViz-003/004/010/011/012/013/014/015 invariant family and keeps the obsolete raw ActivityViz-009 verifier replaced by committed Shared elevation invariant checks after ActivityViz-011.
- Preserved ownership rule: Shared decides visualization data semantics; platforms decide rendering. iOS/macOS/watchOS drawing, colors, fonts, layout, MapKit/Charts/SwiftUI/AppKit usage, localization, and accessibility identifiers remain platform-owned.
- Verified no Watch UI, no Watch recording, no watchOS compact consumption, no route correction, no map matching, no snap-to-road, no route reconstruction, no current-user-location display, no location permission prompt, no trusted metric mutation, and no persistence/export/package schema change.

Task-031-prep-ActivityViz-016 verification token: Final Parity Gate, `verify_task031_prep_016_final_parity_gate.py`, ActivityViz-003 through ActivityViz-015 verifier family, Shared decides visualization data semantics; platforms decide rendering, display-only compact summaries, no Watch UI, no Watch recording, no persistence/export/package schema change, Task-031-prep closure gate.

<!-- Task-031a-001 BEGIN -->

## 2026-07-06 — Task-031a-001 Baseline Preflight

Aligned Build Plan: `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md`
Aligned subtask: `Task-031a — Develop Baseline Lock + Source-of-Truth Preflight`

Task-031a opens Phase 1b from the confirmed `develop` baseline at `b941c7c2519c8e152327b5f91e4322e87de39cd9`, with Task-031-prep merged at `99e9737fa7878cee84259ea98012aa5988f59fde` through merge commit `b941c7c`.

This documentation/verifier-only step adds:

```text
docs/process/PHASE_1B_AGENT_STATE.md
docs/adr/ADR-Shared-Activity-Visualization-Pipeline.md
scripts/verify_task031_phase1b_preflight.py
```

It also records the initial macOS XCTest policy checkpoint and Watch route mini-card checkpoint for later Task-031d closure.

Task-031a-001 intentionally does not implement Watch UI, WatchBridge runtime behavior, Watch recording, Snow production code, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement, signing changes, capabilities, or Xcode project membership changes.

<!-- Task-031a-001 END -->

<!-- TASK031B_WATCHOS_INVENTORY_DEVLOG_START -->
## Task-031b-001 WatchOS Target Inventory

Aligned Build Plan: `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md`

Aligned subtask: `Task-031b — watchOS Target / Scheme / Simulator Inventory`

Summary:

- Inventoried the existing watchOS target and scheme before implementation.
- Confirmed `SkateTrack-watchOS` is the watchOS target and scheme name.
- Recorded the no-signing build style as target build with `CODE_SIGNING_ALLOWED=NO`.
- Confirmed Shared ActivityVisualization watchOS source membership remains present.
- Confirmed watchOS compact visualization consumption remains absent before approved Watch UI subtasks.
- Recorded `Shared/WatchBridge` as absent and deferred to Task-032a audit.
- Added `scripts/verify_task031_watchos_inventory.py`.

No product Swift behavior, Watch UI, WatchBridge runtime behavior, HealthKit, signing, capabilities, bundle identifiers, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement, or Snow production work was implemented.
<!-- TASK031B_WATCHOS_INVENTORY_DEVLOG_END -->

<!-- TASK031C_MODE_GUARDRAILS_DEVLOG_START -->
## Task-031c-001 SportMode and Snow-aware Guardrails

Aligned Build Plan: `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md`

Aligned subtask: `Task-031c — SportMode and Snow-aware Architecture Guardrails`

Summary:

- Added `scripts/verify_task031_mode_guardrails.py` as the Task-031c architecture guardrail verifier.
- Confirmed `SportMode` remains skateboard / inline only in mainline Phase 1b and does not introduce a production Snow case.
- Confirmed `ActivityFidelityProfile.snowReserved` remains a reserved future profile and is not wired to a production Snow mode.
- Confirmed `SessionData`, `MotionSample`, and fidelity policy boundaries remain mode-aware without adding Snow production schema or classifier behavior.
- Classified the external `SkateTrack-SnowFeature` repo and Snow UI screenshots as SnowFeature reference-only context.
- Guarded against Snow production implementation, Trick recognition implementation, and unapproved boolean-only mode shortcuts.

Verification markers:

```text
SNOW_PRODUCTION_IMPLEMENTATION_COUNT=0
TRICK_RECOGNITION_IMPLEMENTATION_COUNT=0
BOOLEAN_ONLY_MODE_SHORTCUT_COUNT=0
SnowFeature reference-only
```

No product Swift behavior, Watch UI, WatchBridge runtime behavior, WatchConnectivity, HealthKit, SnowSegment, SnowRun, SnowDistanceBreakdown, Snow Core Data schema, Snow classifier, Snow run detector, SnowPrototype UI, Trick recognition implementation, route geometry mutation, trusted metric mutation, estimated route enablement, signing, capabilities, or Xcode project membership change was implemented.
<!-- TASK031C_MODE_GUARDRAILS_DEVLOG_END -->

<!-- TASK031D_DOCS_ALIGNMENT_DEVLOG_START -->
## Task-031d-001 Phase 1b Documentation Alignment

Aligned Build Plan: `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md`

Aligned subtask: `Task-031d — Phase 1b Documentation Alignment Commit`

Summary:

- Closed the Task-031 macOS XCTest policy checkpoint as `DOCUMENTED_UNAVAILABLE_NO_MACOS_TEST_TARGET_IN_PBXPROJ`.
- Recorded `WATCH_ROUTE_MINI_CARD_SCOPE=DEFERRED` for the current Task-031 closure.
- Recorded `WATCH_ROUTE_MINI_CARD_REVIEW_AT_TASK036C=YES`; Task-036c must remind the operator and request a refreshed decision before any compact Watch route mini-card implementation.
- Added `scripts/verify_task031_docs_alignment.py` as the Task-031d documentation alignment gate.
- Updated the Task-031a/031b/031c verifiers so the aggregate Task-031 branch can run all accumulated pre-merge gates before the final merge-to-develop.
- Confirmed the next implementation step after Task-031 closure is `NEXT_TASK=Task-032a`.

No Watch UI, WatchBridge runtime behavior, WatchConnectivity runtime behavior, HealthKit, signing, entitlements, capabilities, bundle identifiers, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement, or Snow production implementation was added.
<!-- TASK031D_DOCS_ALIGNMENT_DEVLOG_END -->

<!-- TASK032A_WATCHBRIDGE_AUDIT_DEVLOG_START -->
## 2026-07-06 — Task-032a-001 WatchBridge Source Audit + Contract Placement

- Audited the post-Task-031 `develop` baseline for WatchBridge placement readiness.
- Confirmed `Shared/WatchBridge` is absent before contract creation and no duplicate WatchBridge runtime layer exists.
- Confirmed guarded Swift source paths do not contain runtime `WatchConnectivity` / `WCSession` implementation.
- Recorded `Shared/WatchBridge/` as the future contract namespace for Task-032b.
- Recorded the planned file split: `WatchBridgeEnvelope.swift`, `WatchBridgePayloads.swift`, `WatchBridgeConnectionState.swift`, and `WatchBridgeCommandModels.swift`.
- Recorded the target-membership plan: iOS + watchOS required when contracts are added; macOS optional only for compile-only tools, previews, or tests.
- Added `docs/adr/ADR-WatchBridge-Contract-Placement.md` and `scripts/verify_task032a_watchbridge_audit.py`.

```text
VERIFY_TASK032A_WATCHBRIDGE_AUDIT_RESULT=PASSED
CONTRACT_PLACEMENT_DECIDED=YES
WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge
DUPLICATE_WATCHBRIDGE_LAYER_COUNT=0
WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO
NEXT_TASK=Task-032b
```

Task-032a intentionally does not add WatchBridge Swift models, WatchConnectivity runtime behavior, command mirroring, Watch UI, HealthKit runtime, Snow production behavior, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, or estimated route enablement.
<!-- TASK032A_WATCHBRIDGE_AUDIT_DEVLOG_END -->

## Task-032b-001 WatchBridge Contract Models

```text
TASK032B_WATCHBRIDGE_CONTRACTS_RESULT=PASSED
WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge
WATCHBRIDGE_CONTRACT_SCHEMA_VERSION=1
WATCHBRIDGE_CONTRACT_FILES=WatchBridgeEnvelope.swift|WatchBridgePayloads.swift|WatchBridgeConnectionState.swift|WatchBridgeCommandModels.swift
WATCHBRIDGE_CONTRACT_TARGET_MEMBERSHIP=IOS_AND_WATCHOS_REQUIRED_MACOS_OPTIONAL
WATCHBRIDGE_MODELS_IMPLEMENTED=YES
WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO
WATCH_UI_IMPLEMENTED=NO
NEXT_TASK=Task-032c
```

Task-032b added the first versioned, Codable-only WatchBridge contract surface under `Shared/WatchBridge/` and source-membered it for iOS/watchOS. It intentionally avoided `WatchConnectivity`, `WCSession`, command mirroring runtime behavior, Watch UI, HealthKit runtime, Snow production behavior, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, and estimated route enablement.

## Task-032c-001 Activity-aware Payload Models

- Added activity-aware WatchBridge Codable payload models for session state, metric updates, command acknowledgement, connection status, and display-only compact activity summaries.
- Extended `WatchBridgePayload` with typed activity/session/metric/display/command-result payload cases while keeping Task-032 runtime work deferred.
- Added iOS/watchOS source membership for the new `Shared/WatchBridge` payload model files.
- Verified no WatchConnectivity runtime behavior, no Watch UI, no HealthKit runtime, no Snow production implementation, no trusted metric mutation, and no route geometry mutation.

Task-032c verification token: WATCHBRIDGE_ACTIVITY_PAYLOAD_MODELS_IMPLEMENTED=YES, WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO, WATCH_UI_IMPLEMENTED=NO, TRUSTED_METRIC_MUTATION=NO, NEXT_TASK=Task-032d.

## Task-032d-001 Connection State Store + Mock Transport

- Added a simulator-safe WatchBridge connection timeline, connection state store, and mock transport under `Shared/WatchBridge/`.
- Added iOS/watchOS source membership for the new connection/mock transport files.
- Added iOS unit tests for connected, disconnected, unavailable, stale, message-received, queue, and reject transition behavior.
- Verified no real WatchConnectivity runtime behavior, no WCSession dependency, no command mirroring runtime, no Watch UI, no HealthKit runtime, no Snow production implementation, no schema/Core Data/package mutation, no trusted metric mutation, and no route geometry mutation.

Task-032d verification token: WATCHBRIDGE_CONNECTION_STATE_STORE_IMPLEMENTED=YES, WATCHBRIDGE_MOCK_TRANSPORT_IMPLEMENTED=YES, WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO, WATCH_UI_IMPLEMENTED=NO, NEXT_TASK=Task-032e.

<!-- TASK032E_WATCHBRIDGE_FOUNDATION_DEV_LOG_START -->
## Task-032e-001 WatchBridge Tests + Verifier + Docs

- Added the aggregate WatchBridge foundation verifier `scripts/verify_task032_watchbridge_foundation.py`.
- Added `docs/adr/ADR-WatchBridge-Foundation.md` to record the Task-032 foundation boundary and Task-033a runtime handoff.
- Updated process, file-structure, release limitation, and ADR index documentation for Task-032 closure.
- Confirmed the existing Task-032 foundation includes 9 `Shared/WatchBridge` Swift files and 2 iOS WatchBridge test files.
- Confirmed Task-032 remains a foundation-only layer with no real WatchConnectivity runtime, no `WCSession`, no session-control mirroring runtime, no Watch UI, no HealthKit runtime, no Snow production, no schema/Core Data/package mutation, no route geometry mutation, and no trusted metric mutation.

Task-032e verification token: TASK032_WATCHBRIDGE_FOUNDATION_COMPLETE=YES, WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO, SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO, WATCH_UI_IMPLEMENTED=NO, NEXT_TASK=Task-033a.
<!-- TASK032E_WATCHBRIDGE_FOUNDATION_DEV_LOG_END -->
## Task-033a-001C WatchConnectivity Boundary Shell

- Added `WatchBridgeConnectivityBoundary` and `WatchBridgeConnectivityAvailability` as the Task-033a boundary shell.
- Added `WatchBridgeWCSessionBoundary` to isolate WCSession usage inside a single shared boundary wrapper for iOS/watchOS.
- Added `WatchBridgeSimulatorFallbackBoundary` and iOS fallback tests.
- Preserved Task-033a boundaries:
  - WCSESSION_WRAPPED_BY_BOUNDARY=YES
  - SIMULATOR_FALLBACK_PRESENT=YES
  - DIRECT_UI_WCSESSION_USAGE_COUNT=0
  - SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO
  - WATCH_UI_IMPLEMENTED=NO
- NEXT_TASK=Task-033b

## Task-033b-001 Mirrored Session Commands

- Added mirrored session command models for start / pause / resume / stop actions.
- Added a command processor that requires iPhone-side authority validation before accepting Watch-originated commands.
- Added duplicate command protection with command-id idempotency and stale command rejection.
- Added command acknowledgement/rejection round-trip tests without paired hardware.
- Preserved guardrails: MIRRORED_SESSION_COMMAND_BOUNDARY_IMPLEMENTED=YES, IPHONE_SESSION_AUTHORITY_PRESERVED=YES, WATCH_DIRECT_SESSION_MUTATION=NO, WATCH_UI_IMPLEMENTED=NO, NEXT_TASK=Task-033c.

## Task-033c-001 Command Safety / Conflict Rules

- Added command safety rules for simultaneous iPhone-side action conflicts, out-of-order Watch commands, and disconnected/unreachable Watch command state.
- Added a safety authority wrapper that rejects unsafe Watch commands before forwarding to the iPhone-side command authority.
- Added simulator-safe conflict tests for iPhone action precedence, out-of-order rejection, disconnected Watch rejection, and reachable/in-order forwarding.
- Preserved guardrails: COMMAND_CONFLICT_RULES_IMPLEMENTED=YES, IPHONE_WATCH_CONFLICT_PRECEDENCE=IPHONE_AUTHORITY_FIRST, OUT_OF_ORDER_COMMAND_REJECTION=YES, WATCH_DIRECT_SESSION_MUTATION=NO, WATCH_UI_IMPLEMENTED=NO, NEXT_TASK=Task-033d.

<!-- TASK033D_WATCHCONNECTIVITY_VERIFIER_DOCS_DEVLOG_START -->
## Task-033d-001 WatchConnectivity Verifier + Docs

- Added the aggregate `scripts/verify_task033_watchconnectivity_boundary.py` closure verifier for Task-033.
- Confirmed the Task-033 bridge stack remains limited to a WatchConnectivity boundary wrapper, simulator fallback, mirrored command acknowledgement/rejection, duplicate and stale command protection, and command safety/conflict rules.
- Confirmed `TASK033_AGGREGATE_VERIFIER_IMPLEMENTED=YES` and `TASK033_WATCHCONNECTIVITY_BOUNDARY_COMPLETE=YES`.
- Preserved guardrails: `WATCHCONNECTIVITY_WRAPPED_BY_BOUNDARY=YES`, `DIRECT_UI_WCSESSION_USAGE_COUNT=0`, `IPHONE_SESSION_AUTHORITY_PRESERVED=YES`, `WATCH_DIRECT_SESSION_MUTATION=NO`, `WATCH_UI_IMPLEMENTED=NO`, `HEALTHKIT_PRODUCTION_IMPLEMENTED=NO`, `SNOW_PRODUCTION_IMPLEMENTATION=NO`.
- Next task handoff: `NEXT_TASK=Task-034a`.
<!-- TASK033D_WATCHCONNECTIVITY_VERIFIER_DOCS_DEVLOG_END -->
