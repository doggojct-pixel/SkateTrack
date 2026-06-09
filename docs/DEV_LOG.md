# SkateTrack Development Log

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
