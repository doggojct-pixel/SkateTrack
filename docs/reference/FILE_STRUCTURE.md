# SkateTrack File Structure

**Last Updated:** 2026-06-13
**Source of Truth:** DevProcess v1.0 Principle E — Living Documentation Protocol
**Current Baseline:** Source-controlled repository after Task-030b Documentation Consolidation + Deferred Feature Handoff Package.
**Current Development Gate:** Task-030b consolidates fragmented docs and ADRs into `docs/DOCUMENTATION_INDEX.md`, `docs/process/DEVELOPMENT_RULES.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`, `docs/release/RELEASE_READINESS_PRE_ADP.md`, `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md`, and `docs/adr/ADR-INDEX.md`. It adds no runtime feature, production credential, signing change, entitlement, custom UTType, document association, or cloud / StoreKit / Google production integration.

This document records the current SkateTrack repository structure and development status. It focuses on source-controlled files and intentionally excludes `.git/`, `xcuserdata/`, `DerivedData/`, `.build/`, simulator output, and other generated local artifacts.


## Active Documentation Structure After Task-030b

| File | Status | Purpose |
|---|---|---|
| `docs/DOCUMENTATION_INDEX.md` | Active | Documentation entry point and reading order. |
| `docs/process/DEVELOPMENT_RULES.md` | Active | Consolidated development workflow, hotfix, commit, localization, macOS layout, and scope-control rules. |
| `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` | Active | Consolidated blocked / deferred Pre-ADP feature list with unlock conditions and no-overclaim rules. |
| `docs/release/RELEASE_READINESS_PRE_ADP.md` | Active | Pre-ADP release-readiness gate. |
| `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` | Active | Manual QA matrix for iOS, macOS, languages, accessibility, privacy, GPS, and safety. |
| `docs/adr/ADR-INDEX.md` | Active | Historical ADR summary and mapping after consolidation. |
| `docs/history/DEV_LOG.md` | Historical / active log | Chronological history; not the primary rules source. |
| `docs/reference/FILE_STRUCTURE.md` | Active | Repository structure and progress snapshot. |

Task-030b removes the old per-topic ADR single files and the previous Task 026–030 technical-risk notes from active source control after their content is consolidated into the organized docs subdirectories.

## Current Progress Snapshot

| Area | Status | Notes |
|---|---:|---|
| Task-001 Project Scaffold | Complete | Workspace, Xcode project, platform app targets, baseline docs, Git-ready repository structure. |
| Task-002 Localization Infrastructure | Complete | English and Traditional Chinese localization resources plus shared formatting utilities. |
| Task-003 Shared Data Models | Complete | Cross-platform models for sport modes, sessions, motion samples, falls, tricks, equipment, and spots. |
| Task-004 Feature Flags | Complete | Subscription-gated feature definitions and DEBUG subscription override engine. |
| Task-005 Living Documentation | Complete / Active | `docs/reference/FILE_STRUCTURE.md` and `docs/history/DEV_LOG.md` remain living documents. |
| Task-006 GPS Provider | Complete | iOS-only GPS provider and authorization wrapper. |
| Task-007 IMU Provider | Complete | iOS-only accelerometer and gyroscope provider. |
| Task-008 Barometer Provider | Complete | iOS-only altitude / pressure provider. |
| Task-009 Sensor Fusion Engine | Complete | 10Hz fused `MotionSample` pipeline. |
| Task-010 Fall Detection Engine | Complete | Impact / stationary confirmation / SOS event foundation. |
| Task-011 Session Recording Coordinator | Complete | Session state machine, metrics accumulator, coordinator, hook, and iOS unit tests. |
| Task-012 Session Start Flow | Functionally complete | Start flow, sport category selection, mode selection, power selection, and gating are implemented. Visual alignment remains tied to Task-013 UI cleanup. |
| Task-013 Live HUD + Slide-to-End | Functionally complete after hotfixes | Live HUD, pause/resume, slide-to-end, speed trace, icon cleanup, and inline placeholders exist. Remaining visual polish should be handled as focused UI refinements. |
| Task-014a Fall Alert Overlay + SOS Event Skeleton | Complete | Fall alert overlay, countdown bridge, cancel / immediate SOS / countdown SOS actions, SOS event model, dispatcher skeleton, and DEBUG simulate-fall support exist. |
| Task-014b Emergency Contacts Settings + SOS Contact Flow | Complete | Local emergency contact settings, contact-aware SOS event payloads, and visible SOS status feedback are implemented. |
| Debug Tools Follow-up | Complete | DEBUG tools are centralized under `iOS/Features/Debug`; mock speed is explicit Demo Mode only and normal runtime uses real sensor data. |
| Task-015a Local Persistence Foundation | Complete | Core Data stack, session repository, motion sample file store, fall-event read repository, export/delete API, and repository unit tests are prepared. |
| Task-015b Session Persistence Integration | Complete | Session end now saves through SessionRepository before completed-session publish; discard does not save; repository errors surface as localized keys. |
| Task-016a Subscription Entitlement Simulation Architecture | Complete | Replaceable entitlement provider architecture, local/free simulation, DEBUG-only override provider, product catalog constants, ADR-0001, and verification script are implemented. Production App Store Connect subscription remains deferred. |
| Task-016b Paywall UI + Locked Feature Flow | Complete | Reusable Paywall, subscriber benefits list, restore button, locked-feature overlay, locked inline-mode Paywall routing, DEBUG purchase state simulation, localization, and verification script are implemented. |
| Task-017a Session History Foundation + Free Limit | Complete | Local Session History screen, filters, month grouping, weekly distance summary, free 5-session limit, locked older cards, Paywall routing, and DEBUG/local entitlement strategy documentation are implemented. |
| Task-017b History Navigation + Summary Handoff | Complete | Unlocked History cards now open a dedicated Summary handoff path; locked cards continue to open Paywall. |
| Task-018a Session Summary Foundation + Core Metrics | Complete | Unlocked History cards now open the real Summary foundation with repository-loaded core metrics plus route/chart/health placeholders. |
| Task-018b Route Map + Safety / Share Stub | Complete | Summary now renders a MapKit route preview when valid GPS samples exist, preserves no-route empty states, summarizes local fall-event safety status, and exposes a deferred share stub. |
| Task-018c Advanced Charts + Subscription Gating | Complete | Summary now renders subscriber-gated speed and elevation Swift Charts, keeps free users on a locked Pro preview routed through the existing Paywall, and preserves the no-fake-data heart-rate placeholder. Production monetization remains deferred. |
| Task-019a Health Reminder Rules + Settings Foundation | Complete | Health reminder rules, local settings store, SwiftUI hook, settings sheet, Ride entry card, Pro locked preview, DEBUG/local entitlement editing, localization, docs, and verification script are implemented. |
| Task-019b Health Reminder Scheduler + In-App Reminder Banner | Complete | Live HUD now surfaces subscriber-gated in-app hydration, rest, and cooldown-stretch reminder banners from active Session time; system notification scheduling remains deferred. |
| Task-019c Weather Risk Provider + Weather Suitability Card | Complete | Mock weather provider, weather suitability report, heat / UV / rain risk evaluation, Ride-page weather suitability card, free basic summary, Pro detailed guidance, localization, docs, and verification script are implemented. Real WeatherKit remains deferred. |
| Task-021a Spot Management Foundation | Complete | Local Spot model extension, SpotVisit future model, Core Data spot schema extension, SpotRepository, useSpots, Spot list / map / detail / editor, free 3-favorite limit, root Spots entry, ADR-0002, docs, and verify script are implemented. |
| Task-021b Spot Association + Visit Tracking Foundation | Complete | Session Start can select a local Spot; completed sessions persist `SpotSessionSnapshot`; successful saves update local Spot visits; History and Summary display archived Spot attribution. Follow-up adds multi-select local History deletion and cleans Spot MapKit deprecation warnings. No route auto-detection, WeatherKit, public database, or cloud sync. |
| Task-022 Weather Provider Upgrade + Local Rideability Integration | Complete | Weather query context, disabled provider, mock/local rideability engine, Ride Start weather context, Spot detail rideability card, lightweight Spot rideability chips, localization, docs, and verification are implemented without WeatherKit or external APIs. |
| Task-022d GPS-Denied Indoor Recording Strategy | Documentation prepared / pending Task-023-stage commit | ADR-0003 records that Task-023 through Task-030 must not add production indoor speed, IMU-only route drawing, ARKit normal ride recording, UWB venue tracking, or fake route / speed data. Earliest safe work is a post-Task-030 Recording Data Quality + Indoor Fallback Foundation task. |
| Task-023a Session Share Card Preview Foundation | Complete | Summary has a real local share-card preview foundation, shared data model, SwiftUI hook, Pro locked preview, Paywall route, localization, docs, and verification. |
| Task-023b Session Share Card Quick Export + Share Sheet | Complete | Pro / DEBUG subscriber simulation can render a share-card PNG, lightweight text, and JSON to temporary storage, open the iOS system share sheet, and clean up exported temp files. No Photos write, AirDrop-specific package, Google Drive, cloud sync, or signing / capabilities changes. |
| Task-023c Save Share Card to Photos + Export Scope ADR | Complete | Pro / DEBUG subscriber simulation can save the generated share-card PNG to Photos through add-only permission; ADR-0004 defers AirDrop-specific packages and portable archives to Task-027 / Task-028. No full photo-library read access, Google Drive, cloud sync, or signing / capabilities changes. |
| Task-024a Achievements Foundation + Local Progress UI | Complete | Local achievement models, weekly challenge models, catalog, engines, UserDefaults unlock store, SwiftUI hook, root Achievements screen, Pro-gated advanced challenge previews, localization, docs, and verification are implemented. No Game Center, remote leaderboard, server verification, cloud sync, production StoreKit, signing, or capabilities. |
| Task-024b Weekly Challenge Polish + Achievement Dashboard Links | Complete | Local weekly challenge completion records, Ride-page achievement dashboard, History / Gear / Spot related links, weekly period badges, extra safe local achievement / challenge definitions, ADR-0005 deferred-scope documentation, and verification updates are implemented. No Game Center, social challenge, remote config, server verification, push notification, cloud sync, or capability changes. |
| Task-025a Account Provider Foundation | Complete | Account state model, AuthProvider / GoogleSignInProviding boundary, DEBUG-only LocalAccountProvider, DisabledGoogleAuthProvider, AuthTokenStore placeholder, useAccount hook, localization, ADR-0002 deferred documentation, and verification are implemented. No Account UI, Google OAuth client ID, URL scheme, Google SDK, Drive scopes, production token storage, signing, capabilities, or entitlements. |
| Task-025b Account Settings UI Foundation | Complete | Visible Account settings screen, root `帳號` navigation entry, local-first account status, Google-unavailable placeholder, DEBUG local simulation controls, localization, docs, and verification updates are implemented. No real Google OAuth, Google SDK, URL scheme, client ID, GoogleService plist, Drive scopes, token refresh / revocation, server verification, production token persistence, signing, capabilities, or entitlements. |
| App Icon Integration | Assets present, runtime verification unresolved | iOS/watchOS/macOS AppIcon asset folders and macOS `.icns` exist, but runtime app icon display has not yet matched the intended result on the user's machine. |

## Current Known Issues / Follow-up

| Issue | Impact | Likely Area |
|---|---|---|
| Runtime app icon display still needs final manual confirmation on the user's machine. | Asset catalogs and scripts may pass while simulator / device cache behavior still needs visual verification. | Asset catalog membership, generated Info.plist icon keys, Xcode / simulator cache. |
| Live HUD tilt is intentionally conservative and uncalibrated in Phase 1a. | The app should not claim precise skateboard lean until a real calibration flow and fixed phone placement assumptions exist. | `TiltIndicatorView.swift`, future calibration UX, future sensor interpretation layer. |
| Indoor / no-GPS speed may remain `0.0 km/h`. | This is expected when real-speed runtime is active and GPS speed is unavailable. ADR-0003 now requires honest low-confidence / unavailable states before any future indoor odometry work. | `GPSProvider.swift`, `SensorFusionEngine.swift`, `docs/adr/ADR-INDEX.md`, future Recording Data Quality task. |
| HealthKit / watchOS heart-rate data and deeper analysis are not built yet. | Task-023c adds local share-card quick export and Save to Photos, but heart-rate zones remain a no-fake-data placeholder. | `iOS/Features/SessionSummary`, future HealthKit / watchOS data providers. |
| UserNotifications scheduling and real weather data are not built yet. | Task-022 now provides mock / disabled provider boundaries and local rideability guidance, but notification permission flow, background/system notifications, real WeatherKit / live weather providers, and background weather updates remain deferred. | `iOS/Core/HealthReminders`, `iOS/Features/HealthReminders`, future WeatherKit / notification tasks. |
| Route-to-spot auto detection, real WeatherKit, and cloud sync remain future tasks. | Task-022 supports local mock rideability for manually saved Spots, but it does not infer Spots from GPS routes, fetch live weather, or query public places. | `iOS/Core/Spots`, `iOS/Features/Spots`, `iOS/Core/HealthReminders`, future live-weather / sync tasks. |
| Production Google Sign-In and Google Drive sync are deferred. | Task-025b shows an honest local-first Account screen and Google-unavailable state only. It must not be treated as production Google login readiness. | `iOS/Core/Account`, `iOS/Features/Settings/AccountSettingsView.swift`, `docs/adr/ADR-INDEX.md`, future Task-026 or later provider integration. |
| Real StoreKit monetization is deferred. | The app should not claim production subscription readiness until Apple Developer Program, App Store Connect products, sandbox testing, and production StoreKit provider are completed. | `iOS/Core/Subscription`, `iOS/Hooks/useSubscriptionStatus.swift`, future `AppStoreSubscriptionProvider`, `docs/adr/ADR-INDEX.md`. |


## Zone Legend

| Label | Meaning |
|---|---|
| `[協作區]` | Human-readable UI, app entry, hooks, orchestration, shared constants, shared models, shared utilities. |
| `[協作區 — 邊界適配層]` | Boundary layer exposing a clean View-facing API while delegating implementation details. |
| `[自主區]` | Implementation-heavy, sensor, engine, lifecycle, or performance-sensitive code. |
| `[原則 A]` | Localization and locale-sensitive resources. |
| `[原則 E]` | Living documentation and architecture recordkeeping. |
| `[工程設定]` | Xcode, build, repository, asset catalog, or tooling configuration. |
| `[任務文件]` | Task prompt pack and acceptance documentation for agent development. |
| `[佔位]` | Placeholder directory preserved for planned work. |

## Repository Inventory

| Area | Current Contents | Count / Notes |
|---|---|---:|
| Swift source files | App entries, shared models/utilities, persistence, iOS engines, iOS UI, hooks, watchOS/macOS shells, and tests | ~95 Swift files |
| Verification scripts | Python scripts for localization, models, feature flags, sensors, session recording, HUD, start flow, debug tools, safety, icons, persistence, subscription entitlement simulation, Paywall validation, Session History, Session Summary, Health Reminder validation, Weather Risk validation, and Session Share Card validation | 25 scripts |
| Task prompt packs | Task-002 through Task-013 task documentation folders | 11 task folders |
| App-icon images | Generated iOS/watchOS/macOS PNG icon assets plus macOS `.icns` | 103 image/icon files in current baseline |
| Tests | iOS session recording coordinator and session repository tests | 2 active iOS test files |
| Living docs | `docs/reference/FILE_STRUCTURE.md`, `docs/history/DEV_LOG.md`, `docs/adr/ADR-INDEX.md`, and release / process docs under subdirectories | Active |

## Annotated Repository Tree

```text
SkateTrack/
├── .gitignore                                      # [工程設定] Ignored files for Xcode, SwiftPM, build output, logs, env files, `.DS_Store`, and local planning files.
├── .swiftlint.yml                                  # [工程設定] SwiftLint configuration; file length warning/error thresholds support DevProcess limits.
├── README.md                                       # [協作區] Project overview and setup notes.
├── SkateTrack.xcworkspace/                         # [工程設定] Root Xcode workspace.
│   └── contents.xcworkspacedata                    # [工程設定] Workspace reference to `SkateTrack.xcodeproj`.
├── SkateTrack.xcodeproj/                           # [工程設定] Xcode project for iOS, watchOS, macOS, and iOS tests.
│   ├── project.pbxproj                             # [工程設定] Target definitions, source membership, resources, build settings, and icon-related settings.
│   ├── project.xcworkspace/                        # [工程設定] Xcode-generated project workspace metadata.
│   └── xcshareddata/xcschemes/                     # [工程設定] Shared build/test schemes.
│       ├── SkateTrack-iOS.xcscheme                 # [工程設定] iOS app scheme.
│       ├── SkateTrack-watchOS.xcscheme             # [工程設定] watchOS app scheme.
│       ├── SkateTrack-macOS.xcscheme               # [工程設定] macOS app scheme.
│       └── SkateTrack-iOSTests.xcscheme            # [工程設定] iOS unit-test scheme, when present in the local Xcode metadata.
├── Shared/                                         # [協作區] Cross-platform source shared by all app targets.
│   ├── Constants/
│   │   ├── AppConstants.swift                      # [協作區] App identity, bundle prefix, and deployment baseline constants.
│   │   └── FeatureFlags.swift                      # [協作區] Free and subscription-gated feature definitions.
│   ├── Localization/                               # [原則 A] Localized user-facing strings and Info.plist permission strings.
│   │   ├── en.lproj/
│   │   │   ├── Localizable.strings                 # [原則 A] English app, mode, session, HUD, subscription, and permission strings.
│   │   │   └── InfoPlist.strings                   # [原則 A] English Info.plist permission copy.
│   │   └── zh-Hant.lproj/
│   │       ├── Localizable.strings                 # [原則 A] Traditional Chinese string parity with English keys.
│   │       └── InfoPlist.strings                   # [原則 A] Traditional Chinese Info.plist permission copy.
│   ├── Models/                                     # [協作區] Codable + Sendable domain models.
│   │   ├── EquipmentProfile.swift                  # [協作區] Equipment identity, type, power, wheel / bearing mileage, maintenance metadata, and notes.
│   │   ├── EmergencyContact.swift                  # [協作區] Local emergency contact model used by SOS contact flow.
│   │   ├── FallEvent.swift                         # [協作區] Fall timeline event and SOS-related fall metadata.
│   │   ├── MotionSample.swift                      # [協作區] GPS, speed, acceleration, gyro, altitude, and accuracy sample model.
│   │   ├── PowerType.swift                         # [協作區] Human-powered / electric power classification.
│   │   ├── SessionData.swift                       # [協作區] Root session container for samples, tricks, falls, equipment, and summary metrics.
│   │   ├── SessionSummaryMetrics.swift             # [協作區] Completed-session summary and live metric snapshot structs.
│   │   ├── SessionShareCardData.swift              # [協作區] Task-023a/023b share-card data model used by preview and local export.
│   │   ├── Achievement.swift                       # [協作區] Task-024a local achievement definition, progress, category, and unlock record models.
│   │   ├── WeeklyChallenge.swift                   # [協作區] Task-024a/024b weekly challenge definition, progress, period, and completion-state models.
│   │   ├── WeeklyChallengeCompletionRecord.swift   # [協作區] Task-024b local weekly challenge completion record model.
│   │   ├── AuthSession.swift                         # [協作區] Task-025a account session, provider kind, and local / disabled auth state models; no OAuth token.
│   │   ├── SportMode.swift                         # [協作區] Skateboard and inline skating mode enums plus unified `SportMode`.
│   │   ├── SOSTriggerEvent.swift                   # [協作區] SOS event source, dispatch status, contact payload, and message preview.
│   │   ├── SpotProfile.swift                       # [協作區] Saved riding spot profile and coordinates.
│   │   └── TrickEvent.swift                        # [協作區] Trick timeline event with confidence and landing information.
│   ├── Persistence/                                # [協作區 — 邊界適配層] Task-015a local persistence foundation.
│   │   ├── FallEventRepository.swift               # [協作區 — 邊界適配層] Session-linked fall-event query boundary.
│   │   ├── MotionSampleFileStore.swift             # [自主區] Stores high-frequency MotionSample arrays as compact JSON files.
│   │   ├── PersistenceController.swift             # [自主區] Core Data stack and programmatic Task-015a model.
│   │   ├── RepositoryError.swift                   # [協作區] Localized repository error keys.
│   │   ├── SessionEntityMapper.swift               # [自主區] NSManagedObject / domain-model mapping.
│   │   ├── SessionRepository.swift                 # [協作區 — 邊界適配層] Completed-session save / fetch / delete / export API.
│   │   └── SkateTrackDataModel.xcdatamodeld/       # [工程設定] Core Data schema reference for Task-015a entities.
│   ├── Protocols/
│   │   ├── SensorProvider.swift                    # [協作區] Cross-platform sensor recording contract.
│   │   └── SyncProvider.swift                      # [協作區] Future cloud-sync contract.
│   └── Utilities/
│       ├── NumberFormatter+SkateTrack.swift        # [協作區] Shared number formatter presets.
│       └── UnitFormatter.swift                     # [協作區] Locale-sensitive unit formatting helpers.
├── iOS/                                            # iOS app source tree.
│   ├── App/                                        # [協作區] iOS app entry, root routing, and assets.
│   │   ├── Assets.xcassets/                        # [工程設定] iOS asset catalog.
│   │   │   ├── Contents.json                       # [工程設定] Asset catalog descriptor.
│   │   │   └── AppIcon.appiconset/                 # [工程設定] Generated iOS AppIcon PNG set and `Contents.json`.
│   │   ├── RootNavigationView.swift                # [協作區] Routes idle/failed states to Session Start, History, Gear, Spots, Achievements, Account, and active states to Live HUD.
│   │   └── SkateTrackApp.swift                     # [協作區] iOS app entry and shared state-owner wiring.
│   ├── Core/                                       # [自主區] iOS implementation engines.
│   │   ├── Account/                                # [自主區] Task-025a account provider boundary and local / disabled auth providers.
│   │   │   ├── AuthProvider.swift                      # [自主區] AuthProvider and GoogleSignInProviding protocols plus localized error boundary.
│   │   │   ├── LocalAccountProvider.swift              # [自主區] DEBUG-only local account simulation; release builds do not fake sign-in.
│   │   │   ├── DisabledGoogleAuthProvider.swift        # [自主區] Google Sign-In unavailable provider; no Google SDK, client ID, OAuth flow, or URL scheme.
│   │   │   └── AuthTokenStore.swift                    # [自主區] Placeholder token-storage boundary; stores no production access / refresh / ID token.
│   │   ├── DataPipeline/                           # [佔位] Future persistence and data-processing pipeline.
│   │   ├── MLEngine/                               # [佔位] Future trick recognition and ML inference engines.
│   │   ├── SensorEngine/                           # [自主區] iOS sensor providers and fusion/fall engines.
│   │   │   ├── BarometerProvider.swift             # [自主區] CMAltimeter relative altitude / pressure provider.
│   │   │   ├── FallDetectionEngine.swift           # [自主區] Impact detection, stationary confirmation, countdown, and SOS event publishing.
│   │   │   ├── GPSAuthorizationHandler.swift       # [自主區] CLLocation authorization wrapper.
│   │   │   ├── GPSProvider.swift                   # [自主區] CLLocation and km/h speed provider; Task-030c-b2 active ride uses BestForNavigation / 1 m / fitness / no auto pause plus background-location continuity and significant-change backup.
│   │   │   ├── IMUProvider.swift                   # [自主區] 50Hz accelerometer and gyro provider.
│   │   │   ├── SensorCalibrationEngine.swift       # [自主區] Startup bias calibration and mode sensor priority planning.
│   │   │   └── SensorFusionEngine.swift            # [自主區] 10Hz fused `MotionSample` engine.
│   │   ├── Safety/                                 # [自主區] iOS safety event dispatch and fall/SOS bridge.
│   │   │   ├── EmergencyContactStore.swift         # [自主區] Local UserDefaults-backed emergency contact store for Phase 1a.
│   │   │   ├── SOSEventDispatcher.swift            # [自主區] Phase 1a contact-aware SOS event dispatcher; records events without pretending to auto-send SMS.
│   │   │   └── SessionRecordingCoordinator+FallSafety.swift # [自主區] Fall alert cancel / manual SOS / immediate SOS actions.
│   │   ├── HealthReminders/                        # [自主區] Health reminder rules, settings store, scheduler, in-app events, and mock weather-risk foundation.
│   │   │   ├── HealthReminderRule.swift            # [自主區] Reminder kinds and persisted settings model.
│   │   │   ├── HealthReminderSettingsStore.swift   # [自主區] UserDefaults-backed local reminder settings store.
│   │   │   ├── HealthReminderEvent.swift           # [自主區] In-app reminder event payload for Live HUD banners.
│   │   │   ├── HealthReminderScheduler.swift       # [自主區] Converts active session time into hydration/rest/stretch reminders.
│   │   │   ├── WeatherRiskSnapshot.swift           # [自主區] Mock weather snapshot, risk level, and suitability report models.
│   │   │   ├── WeatherProvider.swift               # [自主區] Replaceable weather provider protocol; no WeatherKit / network implementation yet.
│   │   │   ├── MockWeatherProvider.swift           # [自主區] Local mock weather provider for Task-019c development.
│   │   │   └── WeatherRiskMonitor.swift            # [自主區] Evaluates heat, UV, and rain risk against local reminder thresholds.
│   │   ├── EquipmentManager/                       # [自主區] Equipment CRUD, wear-status formulas, and save-success mileage tracking.
│   │   │   ├── EquipmentRepository.swift           # [自主區] Local PersistedEquipment CRUD, delete, wheel / bearing reset, and mileage accumulation actions.
│   │   │   ├── EquipmentMileageTracker.swift       # [自主區] Applies completed-session distance to selected gear only after successful SessionRepository save.
│   │   │   └── WearReminderEngine.swift            # [自主區] Central OK / CHECK / REPLACE wear status rules for wheels and bearings.
│   │   ├── Spots/                                  # [自主區] Local Spot CRUD, visit persistence, and session-association boundaries.
│   │   │   ├── SpotRepository.swift                # [自主區] Local Spot CRUD, favorite toggling, nearby distance query, and visit record APIs.
│   │   │   └── SpotVisitTracker.swift              # [自主區] Applies completed-session visits to selected Spots only after session save succeeds.
│   │   ├── SessionSharing/                         # [自主區] Task-023b / 023c local share export and Photos save boundary.
│   │   ├── Achievements/                           # [自主區] Task-024a/024b local achievement and weekly challenge engines.
│   │   │   ├── AchievementCatalog.swift            # [自主區] Central local achievement definitions.
│   │   │   ├── AchievementEngine.swift             # [自主區] Evaluates achievement progress from local repository-derived stats.
│   │   │   ├── AchievementUnlockStore.swift        # [自主區] UserDefaults-backed local unlock records; no Core Data migration.
│   │   │   ├── WeeklyChallengeEngine.swift         # [自主區] Local weekly challenge progress / period / completion engine.
│   │   │   └── WeeklyChallengeCompletionStore.swift # [自主區] UserDefaults-backed weekly challenge completion records.
│   │   │   ├── SessionShareExportPayload.swift     # [協作區] Describes generated PNG / TXT / JSON temporary export files.
│   │   │   ├── SessionShareExportService.swift     # [自主區] Writes share-card export files to temporary storage and cleans them up.
│   │   │   └── SessionSharePhotoLibrarySaver.swift # [自主區] Add-only Photo Library authorization and PNG save bridge.
│   │   ├── SessionRecording/                       # [自主區] Recording lifecycle and metrics accumulation.
│   │   │   ├── SessionMetricsAccumulator.swift     # [自主區] Distance, speed, elevation, tilt, and moving ratio accumulator.
│   │   │   ├── SessionRecordingCoordinator.swift   # [自主區] Sole session lifecycle coordinator.
│   │   │   ├── SessionRecordingCoordinator+CompletionEffects.swift # [自主區] Post-save equipment mileage and Spot visit side effects.
│   │   │   ├── SessionRecordingCoordinator+DebugMock.swift # [自主區] DEBUG-only simulated outdoor route sample feed.
│   │   │   └── SessionStateMachine.swift           # [自主區] Strict session-state transition rules.
│   │   └── Subscription/
│   │       └── FeatureFlagEngine.swift             # [自主區] Feature access and DEBUG subscription override logic.
│   ├── Features/                                   # [協作區] iOS feature modules.
│   │   ├── Achievements/                           # [協作區] Task-024a/024b Achievements screen and reusable achievement/challenge cards.
│   │   │   ├── AchievementListView.swift           # [協作區] Root Achievements screen with stats, weekly challenges, related links, basic achievements, and Pro advanced previews.
│   │   │   ├── AchievementCardView.swift           # [協作區] Single achievement progress / lock card.
│   │   │   ├── AchievementProgressRingView.swift   # [協作區] Reusable circular progress indicator.
│   │   │   ├── WeeklyChallengeCardView.swift       # [協作區] Weekly challenge progress / advanced lock card.
│   │   │   ├── WeeklyChallengePeriodBadgeView.swift # [協作區] Local week period / completion badge for challenge cards.
│   │   │   └── AchievementRelatedStatsLinksView.swift # [協作區] History / Gear / Spots related-stat navigation links.
│   │   ├── Settings/                              # [協作區] Task-025b account settings and local-first account status UI.
│   │   │   └── AccountSettingsView.swift          # [協作區] Visible Account screen using useAccount, Google-unavailable placeholder, and DEBUG local simulation controls.
│   │   ├── Debug/                               # [協作區] DEBUG-only unified development tools.
│   │   │   ├── DebugFeatureFlag.swift           # [協作區] Central DEBUG tool feature definitions.
│   │   │   ├── DebugMockSessionFactory.swift    # [協作區] Explicit demo speed / mock session helper; not used by normal app runtime.
│   │   │   ├── DebugRuntimeOptions.swift        # [協作區] Shared DEBUG runtime presentation state.
│   │   │   ├── DebugToolAction.swift            # [協作區] Central DEBUG tool action identifiers.
│   │   │   └── DebugToolsPanelView.swift        # [協作區] Unified Debug Tools panel for fall simulation, demo speed, subscription override, and test data reset.
│   │   ├── EquipmentManager/                       # [協作區] Equipment Manager list, cards, detail, edit form, and SessionStart picker UI.
│   │   │   ├── EquipmentListView.swift             # [協作區] Screen 07 My Gear screen, free sample cards, Pro gating, and CRUD entry points.
│   │   │   ├── EquipmentCardView.swift             # [協作區] Gear card with mileage stats, skateboard SF Symbol, safe custom inline-skate glyph, wheel / bearing progress, and OK / CHECK / REPLACE badge.
│   │   │   ├── EquipmentDetailView.swift           # [協作區] Gear maintenance details, custom non-overlapping detail header, wheel / bearing reset actions, edit and delete confirmation.
│   │   │   ├── EditEquipmentView.swift             # [協作區] Add / edit gear form for skateboard and inline gear setup.
│   │   │   └── SessionEquipmentPickerView.swift    # [協作區] Ride-page compact gear picker for current session; no detail navigation overlay.
│   │   ├── FallDetection/                          # [協作區] Fall alert / SOS overlay UI.
│   │   │   ├── EmergencyContactsSettingsView.swift # [協作區] Dark contact settings sheet for local emergency contacts.
│   │   │   ├── FallDetectionAlertView.swift        # [協作區] Dark neon fall alert card, countdown, contact status, cancel and SOS buttons.
│   │   │   └── FallDetectionOverlayPresenter.swift # [協作區] High-priority overlay and SOS status presenter for Live HUD.
│   │   ├── HealthReminders/                        # [協作區] Pro-gated health reminder settings, in-app banner UI, and weather suitability card.
│   │   │   ├── HealthReminderSettingsView.swift    # [協作區] Dark Pro-gated settings sheet plus Ride entry card for health reminders.
│   │   │   ├── HealthReminderBannerView.swift      # [協作區] Live HUD in-app hydration/rest/stretch reminder banner.
│   │   │   ├── WeatherSuitabilityCardView.swift    # [協作區] Ride-page mock / disabled weather rideability card with free summary and Pro detailed guidance.
│   │   │   ├── WeatherRiskFactorRowView.swift      # [協作區] Reusable risk / rideability factor row for weather and Spot details.
│   │   │   └── WeatherRideabilityStatusChipView.swift # [協作區] Reusable local rideability status chip.
│   │   ├── RouteMap/                               # [佔位] Future full route map and replay UI.
│   │   ├── SessionRecording/                       # [協作區] Session Start and Live HUD UI components.
│   │   │   ├── BoardModeSelectorView.swift         # [協作區] Skateboard mode selector.
│   │   │   ├── InlineLiveMetricsView.swift         # [協作區] Inline-specific live metric placeholders.
│   │   │   ├── InlineModeSelectorView.swift        # [協作區] Inline mode selector and gated mode handling.
│   │   │   ├── LiveHUDMetricCardView.swift         # [協作區] Reusable metric card for HUD values.
│   │   │   ├── LiveHUDView.swift                   # [協作區] Active riding HUD; currently under visual-alignment review.
│   │   │   ├── LiveSpeedDisplayView.swift          # [協作區] Large speed / max-speed display component.
│   │   │   ├── LiveSpeedTraceView.swift            # [協作區] Time × speed background trace for the Live HUD speed hero.
│   │   │   ├── MiniRouteMapView.swift              # [協作區] Lightweight route preview from recent coordinates.
│   │   │   ├── ModeSelectionCardView.swift         # [協作區] Reusable sport/mode card; contains current custom icon work.
│   │   │   ├── PowerTypeToggleView.swift           # [協作區] Human/electric skateboard power-type toggle.
│   │   │   ├── SessionSpotPickerView.swift         # [協作區] In-flow local Spot selector for Session Start; no location permission or public discovery.
│   │   │   ├── SessionStartSupportTypes.swift      # [協作區] Session Start colors, category enum, and inline glyph split out from SessionStartView.
│   │   │   ├── SessionStartStickyRootNavigationView.swift # [協作區] Continuous Ride-page root navigation overlay that follows the in-page anchor and pins below the Dynamic Island / safe area.
│   │   │   ├── SessionStartHeaderMetricsView.swift # [協作區] Split Session Start title/header, hidden root navigation anchor, and preview metric strip, keeping SessionStartView under the file-size guardrail.
│   │   │   ├── SessionStartView.swift              # [協作區] Session Start flow with equipment, local Spot selection, and measured sticky root-navigation positioning.
│   │   │   ├── SlideToEndSessionControl.swift      # [協作區] Slide-to-end control with accidental-stop protection.
│   │   │   ├── SportCategoryPickerView.swift       # [協作區] Skateboard / inline category picker; contains current inline glyph work.
│   │   │   ├── StartSessionCTAView.swift           # [協作區] Start-session call-to-action button.
│   │   │   └── TiltIndicatorView.swift             # [協作區] Conservative phone-posture card; does not claim calibrated board tilt in Phase 1a.
│   │   ├── Subscription/                           # [協作區] Task-016b Paywall and locked feature UI.
│   │   │   ├── SubscriptionPaywallView.swift       # [協作區] Dark neon Paywall using DEBUG/local entitlement simulation; no real payment processing.
│   │   │   ├── SubscriberBenefitsListView.swift    # [協作區] Reusable subscriber benefit rows.
│   │   │   ├── RestorePurchaseButton.swift         # [協作區] Restore UI that refreshes local entitlement until real StoreKit restore is added.
│   │   │   └── LockedFeatureOverlayView.swift      # [協作區] Locked-feature prompt used by Session Start before opening Paywall.
│   │   ├── SessionHistory/                         # [協作區] Task-017a local History UI plus Task-017b selected-session handoff routing.
│   │   │   ├── SessionHistoryView.swift            # [協作區] Main History screen with summary, filters, repository state, Paywall routing, and local bulk delete coordination.
│   │   │   ├── SessionHistoryListView.swift        # [協作區] Month-grouped saved-session list with optional selection-mode routing.
│   │   │   ├── SessionHistoryCardView.swift        # [協作區] Saved-session card with locked old-session and selection-badge states.
│   │   │   ├── SessionHistoryFilterBar.swift       # [協作區] All / Skate / Inline / Electric filter bar.
│   │   │   ├── SessionHistoryBulkActionBarView.swift # [協作區] Multi-select local deletion toolbar for History cleanup.
│   │   │   ├── SessionSummaryHandoffView.swift     # [協作區] Legacy Task-017b handoff placeholder retained for reference; Task-018a now opens `SessionSummaryView`.
│   │   │   └── HistoryLimitPaywallBanner.swift     # [協作區] Free 5-session limit upgrade banner.
│   │   ├── SessionSummary/                         # [協作區] Summary foundation, route map, safety recap, share-card preview, and subscriber-gated advanced charts.
│   │   │   ├── SessionSummaryView.swift            # [協作區] Real Summary foundation opened from unlocked History cards.
│   │   │   ├── SessionSummaryMetricsGridView.swift # [協作區] Core metrics grid for distance, speed, duration, elevation, falls, and tricks.
│   │   │   ├── SessionSummaryPlaceholderSectionView.swift # [協作區] Legacy reusable placeholder card retained for future Summary sections.
│   │   │   ├── SessionRouteMapView.swift           # [協作區] MapKit route preview, start / finish markers, and no-route empty state.
│   │   │   ├── SessionSpotAttributionView.swift    # [協作區] Archived Spot snapshot attribution card for Summary.
│   │   │   ├── SessionSummarySafetyStatusView.swift # [協作區] Local fall-event and safety recap for Summary.
│   │   │   ├── SessionSummaryShareStubView.swift   # [協作區] Share-card section wrapper for preview, locked state, and export action.
│   │   │   ├── SessionShareCardPreviewView.swift   # [協作區] Dark neon local share-card preview reused by Task-023b PNG renderer.
│   │   │   ├── SessionShareCardMetricView.swift    # [協作區] Reusable metric tile inside the share-card preview.
│   │   │   ├── SessionShareCardLockedView.swift    # [協作區] Free-user locked share-card preview routed through existing Paywall.
│   │   │   ├── SessionShareCardActionView.swift    # [協作區] Pro quick-export and Save to Photos actions.
│   │   │   ├── SessionShareCardRenderer.swift      # [協作區 — 邊界適配層] Renders the SwiftUI share card preview to PNG through ImageRenderer.
│   │   │   ├── SessionShareExportViewModel.swift   # [協作區 — 邊界適配層] Coordinates render, export payload, Photos save state, errors, and cleanup.
│   │   │   ├── SessionSharePhotoSaveState.swift    # [協作區] Local save-to-Photos UI state and localized message mapping.
│   │   │   ├── SessionShareSheetView.swift         # [協作區 — 系統橋接層] UIActivityViewController wrapper for local export URLs.
│   │   │   ├── SessionAdvancedChartsView.swift     # [協作區] Subscriber-gated advanced chart section, downsampling, and Paywall routing.
│   │   │   ├── SpeedTimelineChartView.swift        # [協作區] Swift Charts speed timeline for Pro / DEBUG subscriber state.
│   │   │   ├── ElevationProfileChartView.swift     # [協作區] Swift Charts elevation profile for Pro / DEBUG subscriber state.
│   │   │   ├── AdvancedChartsLockedView.swift      # [協作區] Free-user Pro preview and Paywall entry for advanced charts.
│   │   │   └── HeartRateZonePlaceholderView.swift  # [協作區] No-fake-data heart-rate zone placeholder for future wearable / HealthKit work.
│   │   ├── Social/                                 # [佔位] Future sharing and community features.
│   │   ├── Spots/                                  # [協作區] Local Spot list, map, detail, editor, and favorite-limit UI.
│   │   │   ├── SpotListView.swift                  # [協作區] Local Spot list / map mode shell and CRUD routing.
│   │   │   ├── SpotCardView.swift                  # [協作區] Low-density dark Spot summary card.
│   │   │   ├── SpotMapView.swift                   # [協作區] iOS 17 MapKit marker foundation for manually saved coordinates only.
│   │   │   ├── SpotDetailView.swift                # [協作區] Local Spot detail, visit stats, edit, delete, and favorite UI.
│   │   │   ├── SpotEditorView.swift                # [協作區] Add / edit form with optional manual coordinates; no location permission.
│   │   │   └── SpotFavoriteLimitBanner.swift       # [協作區] Free favorite limit / local privacy banner.
│   │   ├── TrickRecognition/                       # [佔位] Future trick UI and ML results.
│   │   └── Tutorials/                              # [佔位] Future tutorials and onboarding.
│   └── Hooks/                                      # [協作區 — 邊界適配層] SwiftUI-facing adapters.
│       ├── useSessionRecording.swift              # [協作區 — 邊界適配層] Observable session state/actions; DEBUG demo speed mode is explicit, not app-runtime default.
│       ├── useFallDetection.swift                 # [協作區 — 邊界適配層] Observable fall alert state, countdown, cancel and SOS actions.
│       ├── useHealthReminders.swift               # [協作區 — 邊界適配層] Observable health reminder settings and Pro access boundary.
│       ├── useWeatherRisk.swift                   # [協作區 — 邊界適配層] Observable mock weather suitability report and detailed Pro risk access.
│       ├── useEquipmentManager.swift              # [協作區 — 邊界適配層] Observable equipment CRUD state, demo gear, and `.equipmentManager` Pro access boundary.
│       ├── useSpots.swift                         # [協作區 — 邊界適配層] Observable local Spot CRUD state and `.spotManagement` favorite-limit Paywall boundary.
│       ├── useSessionShareCard.swift              # [協作區 — 邊界適配層] Formats Summary content into share-card preview / export data.
│       ├── useAccount.swift                       # [協作區 — 邊界適配層] Task-025a/025b account state adapter for local simulation, disabled Google status, and Account settings UI.
│       └── useSubscriptionStatus.swift            # [協作區 — 邊界適配層] Observable subscription/debug override state.
├── watchOS/                                        # watchOS app source tree.
│   ├── App/
│   │   ├── Assets.xcassets/                        # [工程設定] watchOS asset catalog.
│   │   │   └── AppIcon.appiconset/                 # [工程設定] Generated watchOS AppIcon PNG set and `Contents.json`.
│   │   └── SkateTrackWatchApp.swift               # [協作區] watchOS app shell.
│   ├── Core/                                      # [佔位] Future watchOS sensor / sync implementation.
│   └── Features/                                  # [佔位] Future watch session companion features.
├── macOS/                                         # macOS app source tree.
│   ├── App/
│   │   ├── Assets.xcassets/                        # [工程設定] macOS asset catalog.
│   │   │   └── AppIcon.appiconset/                 # [工程設定] Generated macOS AppIcon PNG set and `Contents.json`.
│   │   ├── SkateTrack.icns                         # [工程設定] macOS icon fallback generated from approved artwork.
│   │   └── SkateTrackMacApp.swift                  # [協作區] macOS app shell.
│   ├── Core/                                      # [佔位] Future macOS data/analysis implementation.
│   └── Features/                                  # [佔位] Future desktop features.
│       ├── AIAnalysis/                            # [佔位] Future AI analysis UI.
│       ├── DataVisualization/                     # [佔位] Future charts and analytics.
│       ├── SessionBrowser/                        # [佔位] Future session history browser.
│       ├── TrainingPlan/                          # [佔位] Future training plans.
│       ├── Tutorials/                             # [佔位] Future tutorials.
│       └── VideoOverlay/                          # [佔位] Future video overlay analysis.
├── Tests/                                         # Test source tree.
│   ├── iOSTests/
│   │   ├── SessionRecordingCoordinatorTests.swift  # [工程設定] iOS unit tests for state transitions, session coordinator behavior, and Task-015b persistence integration.
│   │   └── SessionRepositoryTests.swift            # [工程設定] Task-015a persistence save / fetch / export / delete tests.
│   ├── watchOSTests/                              # [佔位] Future watchOS tests.
│   └── macOSTests/                                # [佔位] Future macOS tests.
├── scripts/                                       # [工程設定] Repository verification scripts.
│   ├── set_github_remote.sh                       # [工程設定] GitHub remote helper.
│   ├── verify_app_icons.py                        # [工程設定] Checks icon asset folders and selected project icon settings; does not prove runtime Dock/simulator display.
│   ├── verify_barometer_provider.py               # [工程設定] Task-008 verification.
│   ├── verify_fall_detection_engine.py            # [工程設定] Task-010 verification.
│   ├── verify_fall_alert_ui.py                    # [工程設定] Task-014a Fall Alert overlay / SOS skeleton verification.
│   ├── verify_feature_flags.py                    # [工程設定] Task-004 verification.
│   ├── verify_debug_tools.py                      # [工程設定] DEBUG tools centralization and real-speed runtime default verification.
│   ├── verify_gps_provider.py                     # [工程設定] Task-006 verification.
│   ├── verify_imu_provider.py                     # [工程設定] Task-007 verification.
│   ├── verify_live_hud.py                         # [工程設定] Task-013 source-pattern verification; not a visual-layout test.
│   ├── verify_localization_keys.py                # [工程設定] Task-002 localization key parity check.
│   ├── verify_portrait_fall_tilt_rework.py        # [工程設定] Portrait lock, conservative tilt display, and fall-alert surfacing gate verification.
│   ├── verify_sensor_fusion_engine.py             # [工程設定] Task-009 verification.
│   ├── verify_session_recording_coordinator.py    # [工程設定] Task-011 verification.
│   ├── verify_session_repository.py               # [工程設定] Task-015 persistence foundation verification.
│   ├── verify_session_persistence_integration.py   # [工程設定] Task-015b recording-to-repository integration verification.
│   ├── verify_subscription_entitlement_simulation.py # [工程設定] Task-016a subscription entitlement provider architecture verification.
│   ├── verify_subscription_paywall.py              # [工程設定] Task-016b Paywall / locked feature flow verification.
│   ├── verify_session_history.py                   # [工程設定] Task-017a Session History / free-limit, handoff, and local bulk-delete verification.
│   ├── verify_session_summary.py                   # [工程設定] Task-018a/018b/018c Session Summary, route map, safety, share-stub, and advanced-chart gating verification.
│   ├── verify_session_start_flow.py               # [工程設定] Task-012 source-pattern verification; not a visual-layout test.
│   └── verify_shared_models.py                    # [工程設定] Task-003 verification.
├── docs/                                          # [原則 E] Living documentation.
│   ├── FILE_STRUCTURE.md                          # [原則 E] This source tree and status document.
│   ├── DEV_LOG.md                                 # [原則 E] Chronological development log and correction notes.
│   └── decisions/                                 # [原則 E] Architecture decision records.
│       ├── ADR-0001-subscription-entitlement-strategy.md # [原則 E] Decision to use replaceable entitlement providers before real App Store monetization.
│       ├── ADR-0002-developer-account-dependent-services.md # [原則 E] Provider-boundary policy for Apple / Google / external services.
│       └── ADR-0003-gps-denied-indoor-recording-strategy.md # [原則 E] Deferred indoor recording strategy and no-fake-indoor-data guardrail.
└── tasks/                                         # [任務文件] Task prompt packs and acceptance documentation.
    ├── Task-002-Localization/                     # [任務文件] Task-002 prompt pack.
    ├── Task-003-SharedDataModels/                 # [任務文件] Task-003 prompt pack.
    ├── Task-004-FeatureFlags/                     # [任務文件] Task-004 prompt pack.
    ├── Task-006-GPSProvider/                      # [任務文件] Task-006 prompt pack.
    ├── Task-007-IMUProvider/                      # [任務文件] Task-007 prompt pack.
    ├── Task-008-BarometerProvider/                # [任務文件] Task-008 prompt pack.
    ├── Task-009-SensorFusionEngine/               # [任務文件] Task-009 prompt pack.
    ├── Task-010-FallDetectionEngine/              # [任務文件] Task-010 prompt pack.
    ├── Task-011-SessionRecordingCoordinator/      # [任務文件] Task-011 prompt pack.
    ├── Task-012-SessionStartFlow/                 # [任務文件] Task-012 prompt pack.
    └── Task-013-LiveHUD/                          # [任務文件] Task-013 Live HUD scope and validation notes.
```

## Current Validation Commands

```bash
cd "/Users/doggo/Documents/App軟體區/SkateTrack"

python3 scripts/verify_localization_keys.py
python3 scripts/verify_shared_models.py
python3 scripts/verify_feature_flags.py
python3 scripts/verify_gps_provider.py
python3 scripts/verify_imu_provider.py
python3 scripts/verify_barometer_provider.py
python3 scripts/verify_sensor_fusion_engine.py
python3 scripts/verify_fall_detection_engine.py
python3 scripts/verify_session_recording_coordinator.py
python3 scripts/verify_session_start_flow.py
python3 scripts/verify_live_hud.py
python3 scripts/verify_debug_tools.py
python3 scripts/verify_fall_alert_ui.py
python3 scripts/verify_emergency_contacts.py
python3 scripts/verify_portrait_fall_tilt_rework.py
python3 scripts/verify_session_repository.py
python3 scripts/verify_session_persistence_integration.py
python3 scripts/verify_subscription_entitlement_simulation.py
python3 scripts/verify_subscription_paywall.py
python3 scripts/verify_session_history.py
python3 scripts/verify_session_summary.py
python3 scripts/verify_health_reminders.py
python3 scripts/verify_weather_risk.py
python3 scripts/verify_weather_rideability.py
python3 scripts/verify_account_provider.py
python3 scripts/verify_root_navigation_polish.py
python3 scripts/verify_equipment_manager.py
python3 scripts/verify_equipment_mileage_tracking.py
python3 scripts/verify_app_icons.py
```

Important: the UI-related scripts currently verify file existence, localization keys, and source-pattern contracts. They do **not** prove rendered iPhone layout or runtime app-icon cache behavior. Manual Xcode / simulator / device validation remains required for visual acceptance.


## Recommended Next Step

1. Continue with Task-026 backup / sync provider planning only after Task-025b is verified and committed; keep Google Drive sync behind a separate provider boundary.
2. Keep future paid features on the Task-016 entitlement-provider strategy and defer production App Store monetization until `AppStoreSubscriptionProvider` is intentionally implemented.
3. Future live WeatherKit / external-weather work should replace `MockWeatherProvider` or `DisabledWeatherProvider` behind `WeatherProviding` only after developer-account / privacy / capability review.
4. Future HealthKit / watchOS heart-rate work should replace the Task-018c no-fake-data placeholder with real wearable data only.
5. History / Summary UI should keep reading from the repository layer added in Task-015a / Task-015b; Views should not import or manipulate `NSManagedObject` directly.

## Task-016b Subscription UI Note

Task-016b adds the `iOS/Features/Subscription` module for Paywall and locked-feature UI. This module is UI-only in Task-016b and must continue to consume `useSubscriptionStatus` rather than directly reading DEBUG flags or StoreKit state.

## Task-020b Compatibility Follow-up

- `Shared/Models/EquipmentProfile.swift` now owns the mode / power compatibility rule used by the Ride start equipment picker.
- `iOS/Features/EquipmentManager/SessionEquipmentPickerView.swift` filters gear by exact session sport mode and power type while remaining an in-flow card with no navigation overlay.
- `iOS/Features/SessionRecording/SessionStartView.swift` passes the selected power type into the picker and clears incompatible gear when mode or power changes.
- `scripts/verify_equipment_mileage_tracking.py` verifies exact mode / power compatibility filtering for Task-020b.

## Task-020c Equipment Attribution in History / Summary + Archived Reference

### Added
- `Shared/Models/EquipmentSessionSnapshot.swift` — archived equipment snapshot saved with completed sessions.
- `iOS/Features/SessionSummary/SessionEquipmentAttributionView.swift` — Summary card showing the gear used for a ride.
- `scripts/verify_equipment_attribution.py` — verifies archived equipment snapshot persistence and History / Summary attribution UI.

### Updated
- `Shared/Models/SessionData.swift` — added optional `equipmentSnapshot` beside `equipmentID`.
- `Shared/Persistence/PersistenceController.swift` — added optional `equipmentSnapshotData` to the programmatic `PersistedSession` entity.
- `Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents` — added optional binary `equipmentSnapshotData` for lightweight migration.
- `Shared/Persistence/SessionEntityMapper.swift` — encodes / decodes `EquipmentSessionSnapshot` for completed sessions.
- `iOS/Core/SessionRecording/SessionRecordingCoordinator.swift` — carries selected equipment snapshot through session finalization.
- `iOS/Hooks/useSessionRecording.swift` — exposes the equipment snapshot argument through the SwiftUI action boundary.
- `iOS/Features/SessionRecording/SessionStartView.swift` — creates the archived snapshot from the selected compatible gear before starting a session.
- `iOS/Features/SessionHistory/SessionHistoryCardView.swift` — renders a compact archived gear line in History cards.
- `iOS/Features/SessionSummary/SessionSummaryView.swift` — inserts the Summary equipment attribution card after the identity card.
- `Shared/Localization/en.lproj/Localizable.strings` and `Shared/Localization/zh-Hant.lproj/Localizable.strings` — added History / Summary equipment attribution strings.
- `SkateTrack.xcodeproj/project.pbxproj` — added source membership for `EquipmentSessionSnapshot.swift` and `SessionEquipmentAttributionView.swift`.
- `scripts/verify_session_history.py` and `scripts/verify_session_summary.py` — expanded verification tokens for equipment attribution.
- `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, and `docs/adr/ADR-INDEX.md` — synchronized Task-020c architecture and paid-feature boundaries.


## Task-021a Spot Management Foundation Addendum

### New / Updated Source Areas

```text
Shared/Models/SpotProfile.swift                  # [協作區] Extended local Spot profile with radius, activity family, safety, crowd, favorite, and timestamps.
Shared/Models/SpotVisit.swift                    # [協作區] Local Spot ↔ Session visit record model used by Task-021b.
iOS/Core/Spots/SpotRepository.swift              # [自主區] Local Spot CRUD, favorite toggling, and nearby distance query boundary.
iOS/Hooks/useSpots.swift                         # [協作區 — 邊界適配層] SwiftUI Spot state boundary and favorite-limit Paywall intent.
iOS/Features/Spots/SpotListView.swift            # [協作區] Local Spot list / map mode shell and CRUD routing.
iOS/Features/Spots/SpotCardView.swift            # [協作區] Low-density dark Spot summary card.
iOS/Features/Spots/SpotMapView.swift             # [協作區] MapKit marker foundation for manually saved coordinates only.
iOS/Features/Spots/SpotDetailView.swift          # [協作區] Local Spot detail, edit, delete, and favorite UI.
iOS/Features/Spots/SpotEditorView.swift          # [協作區] Add / edit form with optional manual coordinates; no location permission.
iOS/Features/Spots/SpotFavoriteLimitBanner.swift # [協作區] Free favorite limit / local privacy banner.
iOS/Features/SessionRecording/SessionStartSupportTypes.swift # [協作區] Session Start colors, category enum, and inline glyph split out from SessionStartView.
scripts/verify_spots.py                          # [工程設定] Task-021a verification script.
docs/adr/ADR-INDEX.md # [原則 E] Provider-boundary policy for Apple / Google / external services.
```

### Deferred After Task-021a

- SessionStart spot selection, SpotVisit persistence updates, and Summary spot linking were completed in Task-021b.
- Route-to-spot auto detection remains deferred to a future dedicated task.
- Spot rideability and weather risk chips remain Task-022 and must use the existing weather provider boundary.
- Public spot discovery, Google / cloud sync, WeatherKit, production StoreKit, signing, capabilities, watchOS, and macOS UI are not part of Task-021a.


## Task-021b Spot Association + Visit Tracking Addendum

### New / Updated Source Areas

```text
Shared/Models/SpotSessionSnapshot.swift           # [協作區] Archived selected-Spot metadata stored with completed sessions.
Shared/Models/SessionData.swift                   # [協作區] Adds optional `spotSnapshot` beside existing `spotID`.
Shared/Persistence/SessionEntityMapper.swift      # [自主區] Encodes / decodes `SpotSessionSnapshot` into `spotSnapshotData`.
Shared/Persistence/PersistenceController.swift    # [自主區] Adds `spotSnapshotData` and `PersistedSpotVisit` to the programmatic Core Data model.
iOS/Core/Spots/SpotRepository.swift               # [自主區] Adds idempotent local Spot visit recording and visit fetch API.
iOS/Core/SessionRecording/SessionRecordingCoordinator+CompletionEffects.swift # [自主區] Keeps post-save side effects out of the main coordinator file.
iOS/Core/Spots/SpotVisitTracker.swift             # [自主區] Applies Spot visit count / last-visited updates only after successful session save.
iOS/Features/SessionRecording/SessionSpotPickerView.swift # [協作區] Session Start local Spot picker with no location permission or external discovery.
iOS/Features/SessionHistory/SessionHistoryCardView.swift # [協作區] Shows archived Spot attribution and selection badges on History cards.
iOS/Features/SessionHistory/SessionHistoryBulkActionBarView.swift # [協作區] Multi-select local deletion toolbar for History cleanup.
iOS/Features/SessionSummary/SessionSpotAttributionView.swift # [協作區] Shows archived Spot attribution in Summary.
scripts/verify_spot_session_association.py        # [工程設定] Task-021b verification script.
```

### Deferred After Task-021b

- Route-to-Spot auto detection remains deferred; Task-021b only uses manual local Spot selection.
- Weather rideability remains Task-022 and must use the existing Weather provider boundary.
- Public Spot discovery, Google / cloud sync, WeatherKit, production StoreKit, signing, capabilities, watchOS, and macOS UI remain out of scope.

### Task-021b Follow-up Notes

- History now supports local multi-select deletion from the History page, including locked older free-tier sessions, after a destructive confirmation dialog.
- Deleting sessions remains local-only and removes linked motion samples through `SessionRepository.deleteSession(id:)`.
- Linked `PersistedSpotVisit` rows are also removed and Spot visit summary fields are refreshed, so deleted sessions do not leave stale visit counts.
- `SpotMapView` now uses iOS 17 `Map(position:)` and `Annotation` to avoid deprecated MapKit APIs.


## Task-022 Weather Provider Upgrade + Local Rideability Addendum

### New / Updated Source Areas

```text
iOS/Core/HealthReminders/WeatherQueryContext.swift        # [自主區] Ride Start / Spot Preview weather context without current-location permission.
iOS/Core/HealthReminders/DisabledWeatherProvider.swift    # [自主區] Explicit fallback when live weather services are not enabled.
iOS/Core/HealthReminders/WeatherRideabilityReport.swift   # [自主區] Local rideability report and factor model.
iOS/Core/HealthReminders/WeatherRideabilityEngine.swift   # [自主區] Combines mock weather, surface, crowd, and safety factors.
iOS/Core/HealthReminders/WeatherProvider.swift            # [自主區] Upgraded provider boundary accepting `WeatherQueryContext`.
iOS/Core/HealthReminders/MockWeatherProvider.swift        # [自主區] Offline context-aware mock provider; no network or WeatherKit.
iOS/Hooks/useWeatherRisk.swift                            # [協作區 — 邊界適配層] Exposes weather and local rideability reports to SwiftUI.
iOS/Features/SessionRecording/SessionStartWeatherSectionView.swift # [協作區] Keeps ride-start weather context sync out of SessionStartView.
iOS/Features/HealthReminders/WeatherSuitabilityCardView.swift # [協作區] Ride Start mock / disabled weather and rideability card.
iOS/Features/HealthReminders/WeatherRiskFactorRowView.swift # [協作區] Reusable factor row for weather and Spot rideability details.
iOS/Features/HealthReminders/WeatherRideabilityStatusChipView.swift # [協作區] Reusable rideability status chip.
iOS/Features/Spots/SpotRideabilityCardView.swift          # [協作區] Spot Detail local rideability card with Pro-gated factors.
iOS/Features/Spots/SpotCardView.swift                     # [協作區] Adds lightweight local rideability chip to Spot cards.
iOS/Features/Spots/SpotMapView.swift                      # [協作區] Adds lightweight local rideability chip to Spot map markers / strips.
scripts/verify_weather_rideability.py                     # [工程設定] Task-022 verification script.
```

### Deferred After Task-022

- Real WeatherKit, external weather APIs, API keys, URLSession networking, current-location weather lookup, background weather refresh, and live-weather caching remain deferred.
- Route-to-Spot auto detection, public Spot discovery, Google / cloud sync, production StoreKit, signing, capabilities, watchOS, and macOS UI remain out of scope.
- Future live-weather integration must replace providers behind `WeatherProviding` and update privacy / capability documentation in a separate integration task.


## Task-022d GPS-Denied Indoor Recording Strategy Addendum

### New / Updated Documentation Areas

```text
docs/adr/ADR-INDEX.md # [原則 E] GPS-denied indoor recording strategy, deferred roadmap, and production guardrails.
docs/history/DEV_LOG.md                                                 # [原則 E] Appends Task-022d documentation-only alignment notes.
docs/reference/FILE_STRUCTURE.md                                          # [原則 E] Records ADR-0003 and the Task-023–030 no-indoor-odometry guardrail.
```

### Deferred After Task-022d

- Task-023 through Task-030 must not add production indoor speed, IMU-only route drawing, Core ML indoor velocity in normal runtime, ARKit normal ride tracking, UWB venue tracking, or fake route / speed data.
- The earliest safe entry point is a post-Task-030 Recording Data Quality + Indoor Fallback Foundation task. That task should expose GPS quality, speed source, route confidence, and no-route fallback states before any indoor odometry experiment.
- Phase 2 may explore dataset export and offline Core ML / inertial odometry experiments, but not as default production runtime.
- Phase 3 may explore ARKit coach / video analysis as a separate camera-based workflow, not as pocket-based Session Recording.
- Future UWB work belongs to a hardware-supported venue / B2B mode and must not affect the consumer app-only roadmap until explicitly planned.

### Commit Note

Task-022d is documentation-only and intentionally prepared for a later combined commit with the first Task-023 stage. No Swift source, Xcode project, Core Data schema, localization, signing, capabilities, permissions, or runtime behavior should change in this documentation-only patch.


## Task-023a Session Share Card Preview Foundation Addendum

### Added / Updated Files

```text
Shared/Models/SessionShareCardData.swift                       # [協作區] Codable / Sendable share-card preview data model.
iOS/Hooks/useSessionShareCard.swift                            # [協作區 — 邊界適配層] Formats Summary content into share-card display data.
iOS/Features/SessionSummary/SessionShareCardPreviewView.swift  # [協作區] Local dark neon share-card preview reused by PNG renderer.
iOS/Features/SessionSummary/SessionShareCardMetricView.swift   # [協作區] Share-card metric tile.
iOS/Features/SessionSummary/SessionShareCardLockedView.swift   # [協作區] Locked Pro preview and Paywall routing.
iOS/Features/SessionSummary/SessionShareCardActionView.swift   # [協作區] Pro quick-export action.
iOS/Features/SessionSummary/SessionShareCardRenderer.swift     # [協作區 — 邊界適配層] SwiftUI preview to PNG renderer.
iOS/Features/SessionSummary/SessionShareExportViewModel.swift  # [協作區 — 邊界適配層] Export state, Photos save state, and cleanup coordinator.
iOS/Features/SessionSummary/SessionSharePhotoSaveState.swift   # [協作區] Save-to-Photos UI state and localized message mapping.
iOS/Features/SessionSummary/SessionShareSheetView.swift        # [協作區 — 系統橋接層] System share sheet wrapper.
iOS/Core/SessionSharing/SessionShareExportPayload.swift        # [協作區] Temporary export file payload.
iOS/Core/SessionSharing/SessionShareExportService.swift        # [自主區] Local temp-file export and cleanup service.
iOS/Core/SessionSharing/SessionSharePhotoLibrarySaver.swift    # [自主區] Add-only Photo Library authorization and PNG save bridge.
iOS/Features/SessionSummary/SessionSummaryShareStubView.swift  # [協作區] Reworked as share-card section wrapper.
scripts/verify_session_share_card.py                           # [工程設定] Task-023b-compatible share-card verification script.
scripts/verify_session_share_export.py                         # [工程設定] Task-023c-compatible export / share-sheet boundary verification script.
scripts/verify_session_share_photos.py                         # [工程設定] Task-023c Photos save boundary and permission verification script.
scripts/verify_achievements.py                                  # [工程設定] Task-024b local achievement / weekly challenge verification script.
scripts/verify_session_summary.py                              # [工程設定] Updated Summary verification for share-card export foundation.
scripts/verify_root_navigation_polish.py                       # [工程設定] Task-025c sticky root navigation and DEBUG entry placement verification script.
```

### Task-023b Quick Export Addendum

```text
Task-023b renders the local share-card preview to PNG, writes PNG / TXT / JSON files into temporary storage, opens the iOS system share sheet, and cleans up the generated temporary folder when sharing is dismissed.
```

Task-023b remains local-first and account-safe. It introduces no Photos permission, Google Drive, iCloud / CloudKit, AirDrop-specific package, production StoreKit, signing, capabilities, or external services. Full portable export packages remain deferred to Task-027.

### Task-023c Photos Save Addendum

Task-023c adds a separate Save to Photos action for the generated share-card PNG. It uses add-only Photo Library permission, localized InfoPlist copy, and a dedicated Photos bridge so Summary Views do not directly access `PHPhotoLibrary`.

Task-023c intentionally does not request full photo-library read access, use `UIImageWriteToSavedPhotosAlbum`, create an AirDrop-specific package, define the portable archive format, integrate cloud sync, or change signing / capabilities. ADR-0004 records that AirDrop-specific packages and portable archives remain Task-027 / Task-028 work.


### Task-024a Achievements Addendum

Task-024a adds a local-first Achievements root screen. Achievement progress is computed from saved Session, Equipment, and Spot repository data through `useAchievements`; Views do not directly access Core Data or repositories. Local unlock records are stored as JSON in UserDefaults through `AchievementUnlockStore`, intentionally avoiding a Core Data migration in this phase.

Advanced achievements and advanced weekly challenge previews are gated by `GatedFeature.advancedChallenges`, `useSubscriptionStatus`, `FeatureFlagEngine`, and DEBUG/local entitlement simulation. Task-024a does not add Game Center, remote leaderboards, server verification, cloud sync, production StoreKit, signing, capabilities, push notifications, watchOS UI, or macOS UI.


### Task-024b Achievements / Weekly Challenge Polish Addendum

Task-024b completes the local Task-024 scope by adding weekly challenge completion records, a Ride-page achievement dashboard card, related History / Gear / Spot stat links, weekly period badges, and additional safe local goals. Unlock and weekly completion state remains local JSON in UserDefaults; Core Data schema is intentionally unchanged.

Deferred Task-024 items are now documented in ADR-0005: global leaderboards, social challenges, remote challenge configuration, server verification, Game Center, push notifications, calendar integration, cloud / cross-device challenge sync, trick-count achievements, indoor / ARKit / UWB achievements, and punitive daily streak mechanics remain future work and must be handled as explicit later tasks.

## Task-024b Follow-up — Session Start Floating Root Navigation

- Added `SessionStartStickyRootNavigationView.swift` so the Ride page root navigation behaves like a floating sticky control after scrolling while preserving the normal title-first layout at the top.
- Added `SessionStartHeaderMetricsView.swift` to split the Ride-page title/header and preview metrics out of `SessionStartView.swift`, restoring a comfortable file-size margin after the sticky-navigation follow-up.
- This follow-up does not change session recording behavior, achievement calculation, repositories, sensor engines, platform targets, signing, capabilities, or entitlements.


### Task-024b Follow-up — Sticky Navigation Trigger + Compile Sources Cleanup

- Updated `SessionStartStickyRootNavigationView.swift` and `SessionStartHeaderMetricsView.swift` so the Ride-page root navigation exposes its measured scroll position and pins below the Dynamic Island / safe area when the in-content navigation row reaches the sticky threshold.
- Updated `SessionStartView.swift` to use the measured navigation-row position while preserving the existing full-screen dark Session Start layout and start-session behavior.
- Cleaned `SkateTrack.xcodeproj/project.pbxproj` so `WeeklyChallengeCompletionRecord.swift` appears only once in the iOS target Compile Sources list.
- Updated `scripts/verify_session_start_flow.py` and `scripts/verify_achievements.py` to guard the sticky-navigation measurement and duplicate Compile Sources warning.

### Task-024b Follow-up — Dynamic Island Sticky Navigation Offset

- Updated `SessionStartView.swift` to pass a Dynamic Island-safe sticky top inset into `SessionStartStickyRootNavigationView` while preserving the normal top-of-page title-first layout.
- Updated `SessionStartStickyRootNavigationView.swift` with explicit minimum sticky navigation top-inset constants so the floating root navigation pins below the camera island / status area instead of under it.
- Updated `scripts/verify_session_start_flow.py` to verify the sticky navigation safe-positioning constants.


### Task-025a Account Provider Foundation Addendum

Task-025a adds a local-first account architecture without enabling production Google Sign-In. The new `AuthSession` model, `AuthProvider` / `GoogleSignInProviding` protocols, `LocalAccountProvider`, `DisabledGoogleAuthProvider`, `AuthTokenStore`, and `useAccount` hook create the provider boundary required before Task-025b UI and Task-026 backup / sync work.

Deferred from Task-025a: visible `AccountSettingsView`, account status card, root Settings / Account navigation entry, real `GoogleSignInProvider`, OAuth client ID, reversed client ID URL scheme, Google SDK package dependency, `GoogleService-Info.plist`, real profile loading, token refresh / revocation, Drive scope authorization, Google Drive sync, server verification, production token persistence / Keychain policy, signing changes, capabilities, entitlements, production StoreKit, watchOS UI, and macOS UI.

`AuthTokenStore` is intentionally a placeholder boundary only. It records no access token, refresh token, ID token, client secret, or external-service credential. Future production token storage must be designed with the real provider integration task after credentials, minimum scopes, logout / revocation behavior, and privacy copy are finalized.

### Task-025b Account Settings UI Foundation Addendum

Task-025b adds the visible Account settings foundation on top of the Task-025a provider boundary. `RootNavigationView` now exposes a localized `帳號` / Account root entry, and `AccountSettingsView` displays local-first status, the disabled Google provider state, a Drive-sync deferred note, and DEBUG-only local simulation sign-in / sign-out controls. The screen talks only to `useAccount` and does not import Google SDKs or touch token storage directly.

Deferred from Task-025b: real Google OAuth sign-in, Google SDK package dependency, OAuth client ID, reversed client ID URL scheme, `GoogleService-Info.plist`, production profile loading, token refresh / revocation, production token persistence / Keychain policy, server verification, Drive scope authorization, Google Drive sync, cloud backup, signing changes, capabilities, entitlements, production StoreKit, watchOS UI, and macOS UI. Google Drive work remains Task-026 or later and must use a separate backup / sync provider boundary.

### Task-025c Root Navigation Sticky Polish + Debug Entry Placement Addendum

Task-025c refines the Ride-page root navigation so the visible pill row behaves like one continuous control: the in-page row is now a hidden layout / measurement anchor, while the visible row follows that measured position and naturally pins below the Dynamic Island / safe area. This replaces the previous threshold-only overlay appearance that could feel like a second row popping in after scrolling.

Task-025c also moves the DEBUG-only `DEV`開發者工具入口 from the upper-right overlay position to a bottom-right safe-area floating position, so it no longer competes with the top root navigation pills (`滑行`, `歷史紀錄`, `我的裝備`, `場地`, `成就`, `帳號`). The Ride page uses additional bottom padding to reduce overlap with the bottom start-session dock.

`verify_root_navigation_polish.py` verifies the continuous sticky-navigation anchor / overlay relationship, bottom-right DEBUG entry placement, documentation notes, and the absence of production Google Sign-In configuration in the changed Swift sources.

Deferred from Task-025c: applying the same title-under-navigation-to-sticky transition to `歷史紀錄`, `我的裝備`, `場地`, `成就`, and `帳號` remains Task-025d or later, because those screens have separate scrolling structures and should not be refactored inside this Ride-page polish fix. A full frosted-glass material system for all root navigation states is also deferred until the shared root-screen layout is intentionally standardized.

## Task-026a Backup Package Export Foundation + Disabled Drive Status

```text
Shared/Models/BackupPackageManifest.swift          # [協作區] Backup manifest, schemaVersion = 1, packageType = backup, store counts and issues.
Shared/Models/BackupPackagePayload.swift           # [協作區] Backup payload envelope with independently encoded JSON sections.
iOS/Core/Sync/CloudBackupProvider.swift            # [協作區] Backup / Drive provider boundary and conflict policy enum.
iOS/Core/Sync/BackupPackageEncoder.swift           # [自主區] Encodes domain-model stores independently; no Core Data / NSManagedObject access.
iOS/Core/Sync/LocalBackupProvider.swift            # [自主區] User-initiated local `.skatetrack-backup.json` package writer.
iOS/Core/Sync/DisabledDriveProvider.swift          # [協作區] Honest disabled Google Drive provider until OAuth / Drive scopes are ready.
iOS/Hooks/useBackupSync.swift                      # [協作區 — 邊界適配層] SwiftUI-facing backup sync ViewModel / hook.
iOS/Features/Settings/BackupSyncSettingsView.swift # [協作區] Account screen backup UI with local export and Drive disabled state.
scripts/verify_backup_sync.py                      # Verifies Task-026a files, boundary rules, localization, docs, and no production Google config.
docs/process/DEVELOPMENT_RULES.md             # Technical-risk reference for Task-026 through Task-030.
docs/adr/ADR-INDEX.md # Backup provider / package architecture decision.
```

### Deferred from Task-026a

- Restore preview, validation, conflict resolution, and local overwrite behavior are Task-026b.
- Production Google Drive provider, OAuth credentials, Drive scopes, remote upload / download, background sync, cross-device merge, and server verification remain blocked.
- AirDrop `.skatetrack` package and macOS import viewer remain Task-027 / Task-028.

## Task-026b Local Restore Preview + Conflict Policy Simulation

```text
Shared/Models/BackupRestorePreview.swift              # [協作區] Non-destructive restore-preview summary, store statuses, and validation issues.
iOS/Core/Sync/BackupPackageDecoder.swift              # [自主區] Validates schemaVersion/packageType and decodes backup sections independently for preview.
iOS/Features/Settings/BackupRestorePreviewView.swift  # [協作區] Account backup UI section for file selection, preview counts, and conflict-policy simulation.
scripts/verify_backup_restore_preview.py              # Verifies Task-026b restore-preview boundaries, docs, localization, and no destructive writes.
```

### Deferred from Task-026b

- No restore writer or local overwrite service was added.
- No Core Data / UserDefaults mutation is performed from restore preview.
- `remoteWins`, `mergeByDate`, Google Drive download / restore, AirDrop package import, and macOS viewer work remain deferred to later tasks.

## Task-026c-blocked + Task-027a Portable `.skatetrack` Export Package Foundation

```text
Shared/Models/SkateTrackPackageManifest.swift       # [協作區] Portable export manifest, schemaVersion = 1, packageType = export.
Shared/Models/SkateTrackPackagePayload.swift        # [協作區] Single-session portable package payload; excludes account, token, achievements, and weekly challenge state.
Shared/Export/SkateTrackPackageWriter.swift         # [自主區] Writes caller-provided .skatetrack URL; does not choose iOS/macOS paths.
Shared/Export/SkateTrackPackageReader.swift         # [自主區] Reads and validates portable export packages without importing into local storage.
iOS/Core/Export/SkateTrackPackageExportProvider.swift # [協作區 — 邊界適配層] iOS temp-file package export provider for Session Summary.
iOS/Hooks/useSkateTrackPackageExport.swift          # [協作區 — 邊界適配層] SwiftUI-facing .skatetrack export ViewModel / hook.
iOS/Features/SessionSummary/SessionPackageExportActionView.swift # [協作區] Session Summary action for sharing a .skatetrack file.
scripts/verify_skatetrack_package.py                # Verifies package schema, provider boundaries, docs, localization, and no custom UTType / signing changes.
docs/release/KNOWN_LIMITATIONS_PRE_ADP.md                   # Tracks StoreKit, Google Sign-In, Task-026c Drive sync, UTType, WeatherKit, and TestFlight blocked items.
docs/adr/ADR-INDEX.md # Portable package strategy decision.
```

### Task-026c-blocked status

Task-026c is recorded as blocked, not skipped. The current production state remains `DisabledDriveProvider`, local backup export, and non-destructive restore preview. Real Google Drive integration requires Google OAuth credentials, Drive scope authorization, token lifecycle, privacy copy, and signing / URL-scheme review.

### Deferred from Task-027a

- macOS Import Stub / package preview UI is deferred to Task-027b or Task-028.
- Custom UTType declaration, document association, and inbound file handling are deferred until signing impact is reviewed.
- Batch export, import / restore into local storage, package merge, Drive upload / download, OAuth / Drive scope work, and cloud sync remain future tasks.


## Task-027-preflight Real-device GPS Background Recording Notes

- `iOS/Core/SensorEngine/GPSProvider.swift` now enables background location updates only when `UIBackgroundModes = location` is declared, disables automatic pausing during active ride recording, requests an Always authorization upgrade when appropriate, derives GPS speed from consecutive fixes when Core Location speed is unavailable, and uses a 35 m accepted accuracy threshold for real outdoor pocket tests.
- `iOS/Core/SensorEngine/SensorFusionEngine.swift` now emits location-driven motion samples from GPS callbacks so route data can be preserved when normal timers are throttled during locked-screen recording.
- `Shared/Models/SessionSummaryMetrics.swift`, `iOS/Core/SessionRecording/SessionMetricsAccumulator.swift`, and `iOS/Hooks/useSessionRecording.swift` expose motion / GPS sample counts for diagnostics.
- `iOS/Features/SessionRecording/SessionStartView.swift` includes a real-device recording notice.
- `scripts/verify_gps_background_recording.py` statically verifies background mode, Core Location flags, location-driven samples, diagnostic counters, localization copy, and ADR-0008.
- `docs/adr/ADR-INDEX.md` records the strategy and deferred follow-ups.

## Task-027b macOS Import Stub + Package Preview

```text
macOS/App/MacRootView.swift                                  # [協作區] Independent macOS NavigationSplitView shell; does not reuse iOS RootNavigationView.
macOS/Features/Import/MacImportView.swift                    # [協作區] NSOpenPanel-based .skatetrack file chooser and read-only preview host.
macOS/Features/Import/MacPackageImportViewModel.swift        # [協作區] macOS package import preview state, security-scoped read, extension validation, and package error mapping.
macOS/Features/Import/MacPackagePreviewView.swift            # [協作區] Manifest + session summary preview for packageType = export packages.
macOS/Features/Shared/MacLockedFeatureCardView.swift         # [協作區] Shared macOS locked / coming-soon card for Task-028+ incomplete features.
scripts/verify_macos_package_preview.py                      # Verifies Task-027b macOS import stub, package reader reuse, localization, docs, and no custom UTType / capability drift.
```

### Task-027b deferred items

- Full macOS session viewer, route maps, charts, session browser, Focus Mode, report export, drag-and-drop import, persistent security-scoped bookmarks, local database import, package merge, document association, custom UTType, Google Drive sync, and AI / video analysis remain later tasks.
- Task-027b only validates and previews `.skatetrack` packages produced by Task-027a. It does not mutate local storage and does not claim cross-device cloud sync is complete.

### Task-027b Mac UI stability hotfix

```text
macOS/App/MacRootView.swift                                  # [協作區] Stabilized custom sidebar inside NavigationSplitView; keeps selection non-optional and titlebar-safe.
macOS/Features/Import/MacImportView.swift                    # [協作區] Import detail content gains titlebar-safe top spacing while remaining read-only.
scripts/verify_macos_package_preview.py                      # Adds stability checks for custom sidebar, non-optional selection, and titlebar-safe layout.
```

- This hotfix does not add new files, custom UTType declarations, document association, signing changes, or persistent import behavior.
- `.skatetrack` preview values continue to reflect the metrics stored inside the selected export package. Older simulator exports made before the GPS distance accumulator fix may validly show route samples but `0.00 km` distance.

## Task-028a macOS Read-only Session Viewer Foundation

```text
macOS/Features/SessionBrowser/MacSessionBrowserView.swift    # [協作區] Read-only package-scoped macOS Session Browser with session list and detail host.
macOS/Features/SessionBrowser/MacSessionDetailView.swift     # [協作區] Read-only session detail cards, derived metrics, route summary, and privacy boundary.
macOS/Features/SessionBrowser/MacSessionViewerModel.swift    # [協作區] Converts package sessions into viewer models and derives display metrics from motion samples when needed.
macOS/Features/SessionBrowser/MacSpeedSparklineView.swift    # [協作區] Lightweight SwiftUI Path speed preview; keeps full Charts / MapKit visualization deferred.
macOS/App/MacRootView.swift                                  # [協作區] Owns shared MacPackageImportViewModel so Import and Session Browser use the same package preview state.
macOS/Features/Import/MacImportView.swift                    # [協作區] Uses an injected MacPackageImportViewModel instead of owning a separate StateObject.
macOS/Features/Import/MacPackagePreviewView.swift            # [協作區] Package preview can show viewer-derived metrics and points users to Session Browser.
scripts/verify_macos_session_viewer.py                       # Verifies Task-028a viewer files, shared preview state, read-only boundaries, localization, docs, and project membership.
scripts/verify_macos_package_preview.py                      # Updated so Task-027b package preview verification stays compatible with Task-028a shared state.
```

### Task-028a deferred items

- Route maps, heat maps, Swift Charts, richer graph interactions, report export, persistent imports, drag-and-drop import, document association, custom UTType, Finder open-with behavior, Focus Mode, AI analysis, and video overlay remain future macOS work.
- The viewer reads `.skatetrack` package contents only. It does not mutate local storage, merge records, restore backup packages, upload to cloud, or claim Google Drive / iCloud sync is complete.

### Task-028a layout polish update

- `macOS/Features/SessionBrowser/MacSessionBrowserView.swift` — tightened the Session list into a compact browser column for the read-only package viewer.
- `macOS/Features/SessionBrowser/MacSessionDetailView.swift` — refined the Session detail into a compact macOS dashboard with denser metrics and grouped route / privacy sections.
- `macOS/Features/SessionBrowser/MacSpeedSparklineView.swift` — reduced the lightweight SwiftUI speed preview height for desktop information density.
- `scripts/verify_macos_session_viewer.py` — now checks the compact layout guardrails in addition to the read-only package boundaries.


### Task-028a layout restructure update

- `macOS/Features/SessionBrowser/MacSessionBrowserView.swift` now owns the right-side stacked layout for the macOS read-only Session Viewer: top compact package-session summary, bottom detailed dashboard.
- `macOS/Features/SessionBrowser/MacSessionDetailView.swift` now focuses on detail sections only and no longer duplicates a large package/session hero header.
- `scripts/verify_macos_session_viewer.py` checks that Task-028a keeps the right-side stacked layout and does not regress to a separate middle session-list column.

## Task-028b macOS Route / Chart Visualization Foundation

```text
macOS/Features/SessionBrowser/MacRoutePreviewView.swift      # [協作區] Lightweight SwiftUI Path route shape preview from package GPS samples; no system map framework or road matching.
macOS/Features/SessionBrowser/MacSessionViewerModel.swift    # [協作區] Adds route points, route quality, unique route point count, and read-only route derivation for visualization.
macOS/Features/SessionBrowser/MacSessionDetailView.swift     # [協作區] Places route preview and speed chart in the main dashboard after compact metrics.
macOS/Features/SessionBrowser/MacSpeedSparklineView.swift    # [協作區] Speed chart foundation using SwiftUI Path; keeps full chart framework deferred.
scripts/verify_macos_route_chart_viewer.py                   # Verifies Task-028b route / chart visualization, read-only boundary, localization, docs, and no document / capability drift.
scripts/verify_macos_session_viewer.py                       # Updated to include Task-028b route preview membership and compact visualization guardrails.
```

### Task-028b deferred items

- System map rendering, road matching, heat maps, route overlays, route editing, full chart framework adoption, multi-session comparison, report export, persistent imports, drag-and-drop import, custom UTType, document association, Finder open-with behavior, Google Drive / iCloud / CloudKit sync, and StoreKit production behavior remain future tasks.
- Task-028b remains read-only and package-backed. It does not mutate package contents, write Core Data, merge sessions, or restore backups.

## Task-029a Japanese Localization + Privacy Copy Gate

```text
Shared/Localization/ja.lproj/Localizable.strings              # Japanese first-pass app localization; key set must match en / zh-Hant.
Shared/Localization/ja.lproj/InfoPlist.strings                # Japanese system permission copy for location, background location, motion, and Photos.
scripts/verify_localization_keys.py                           # Updated to validate en / zh-Hant / ja key parity, placeholder parity, syntax, InfoPlist parity, and project membership.
scripts/verify_task029_localization_privacy.py                 # Task-029a gate for Japanese localization, critical privacy copy, deferred localization roadmap, and no capability/document drift.
docs/adr/ADR-INDEX.md # Records the localization strategy, 500-line exception for resource files, and deferred pt-BR / es roadmap.
```

### Task-029a localization file-size note

`Localizable.strings` and `InfoPlist.strings` are resource files, not Swift implementation files. They are intentionally allowed to exceed the usual Swift 500-line readability guideline. Localization quality is enforced through key parity, placeholder parity, syntax checks, and privacy-copy checks rather than line count.

### Task-029a deferred localization roadmap

- `pt-BR` Brazilian Portuguese — deferred localization roadmap item.
- `es` Spanish — deferred localization roadmap item.
- Native Japanese review before public release remains a Task-030 release-readiness checkpoint.

### Task-029b Accessibility / Privacy / UX Quality Gate

```text
iOS/App/RootNavigationView.swift                              # [協作區] DEBUG tools entry uses localized accessibility copy.
iOS/Features/SessionRecording/LiveHUDView.swift               # [協作區] Live HUD status, emergency contacts, and debug tools accessibility labels are localized.
macOS/Features/SessionBrowser/MacSessionBrowserView.swift     # [協作區] Current package-session summary gains accessibility label / hint while preserving stacked macOS layout.
macOS/Features/SessionBrowser/MacSessionDetailView.swift      # [協作區] Read-only dashboard sections and metric cards gain VoiceOver grouping guardrails.
macOS/Features/SessionBrowser/MacRoutePreviewView.swift       # [協作區] Lightweight route preview gains localized accessibility label, hint, and route sample summary.
macOS/Features/SessionBrowser/MacSpeedSparklineView.swift     # [協作區] Lightweight speed chart gains localized accessibility label, value, and hint.
Shared/Localization/en.lproj/Localizable.strings              # Adds Task-029b accessibility / quality-gate keys.
Shared/Localization/zh-Hant.lproj/Localizable.strings         # Adds Task-029b accessibility / quality-gate keys.
Shared/Localization/ja.lproj/Localizable.strings              # Adds Task-029b accessibility / quality-gate keys.
scripts/verify_task029b_accessibility_privacy_gate.py         # Task-029b quality gate for accessibility, privacy copy, macOS layout, and no capability drift.
docs/adr/ADR-INDEX.md # Records Task-029b accessibility / privacy / UX guardrails.
```

- This task does not change project membership, signing, capabilities, document association, custom UTType, Google Drive, CloudKit, StoreKit production, MapKit, Charts, or package persistence behavior.
- Localization resource files remain governed by key parity, placeholder parity, syntax validity, and privacy-copy correctness rather than the Swift 500-line guideline.


## Task-030a Pre-ADP Release Readiness Audit + Verify Gate

Task-030a adds the release-readiness documentation and verification layer used before Task-030b handoff:

```
docs/release/RELEASE_READINESS_PRE_ADP.md              # Pre-ADP release posture, build commands, source-control gate, service-boundary gate, GPS / safety gate, macOS viewer gate.
docs/release/MANUAL_QA_MATRIX_PRE_ADP.md               # Manual QA matrix for iOS, macOS, localization, accessibility, privacy, GPS, and service-boundary checks.
docs/adr/ADR-INDEX.md  # Release-readiness strategy before Apple Developer Program enrollment.
scripts/verify_task030_release_readiness.py     # Task-030a quality gate for docs, scheme hygiene, service boundaries, known limitations, and project-setting drift.
```

Task-030a intentionally does not add runtime features. StoreKit production, Google OAuth / Drive, CloudKit / iCloud, WeatherKit, TestFlight, custom `.skatetrack` UTType, document association, Finder open-with, MapKit route rendering, Swift Charts, package library, persistent import, and production signing / capability work remain deferred until the relevant unlock prerequisites are met.

Task-030a verification token: pre-ADP release readiness gate.


## Task-030b Documentation Consolidation

Task-030b consolidates fragmented ADR and stage-specific documentation into active source-of-truth docs.

## Task-030b Verify Script Consolidation Fix

Task-030b documentation consolidation removed old per-topic ADR files and the stage-specific `docs/process/DEVELOPMENT_RULES.md` file. The following verify scripts were updated to reference consolidated documentation instead of retired document paths:

```text
scripts/verify_task030_release_readiness.py
scripts/verify_task029_localization_privacy.py
scripts/verify_task029b_accessibility_privacy_gate.py
scripts/verify_macos_session_viewer.py
scripts/verify_macos_route_chart_viewer.py
scripts/verify_macos_package_preview.py
scripts/verify_skatetrack_package.py
scripts/verify_backup_sync.py
scripts/verify_backup_restore_preview.py
scripts/verify_account_provider.py
scripts/verify_gps_background_recording.py
scripts/verify_spot_session_association.py
scripts/verify_achievements.py
scripts/verify_session_history.py
scripts/verify_health_reminders.py
scripts/verify_weather_rideability.py
scripts/verify_session_share_export.py
scripts/verify_equipment_attribution.py
scripts/verify_weather_risk.py
scripts/verify_subscription_entitlement_simulation.py
scripts/verify_equipment_mileage_tracking.py
scripts/verify_equipment_manager.py
scripts/verify_session_share_card.py
scripts/verify_spots.py
scripts/verify_session_share_photos.py
```

The old ADR single files remain retired. `docs/adr/ADR-INDEX.md` is the active historical decision index.

## Task-030c-a Core Location Diagnostics Package Extension

```text
Shared/Models/MotionSample.swift                         # [協作區] Adds optional Core Location diagnostics, received-at timestamps, speed source, freshness state, route segment confidence, millisecond timestamps, continuity gap counters, and RouteQualitySummary.
Shared/Models/SessionData.swift                          # [協作區] Adds optional routeQualitySummary while preserving old .skatetrack decode compatibility.
Shared/Models/SkateTrackPackageManifest.swift            # [協作區] Adds optional formatCapabilities for diagnostics-capable package exports without changing schemaVersion = 1.
Shared/Models/SkateTrackPackagePayload.swift             # [協作區] Adds optional per-package-session routeQualitySummary generated from exported motion samples.
iOS/Core/SensorEngine/SensorFusionEngine.swift           # [自主區] Attaches accepted Core Location diagnostics to 10Hz MotionSample exports without changing high-accuracy policy yet.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # [自主區] Enriches completed sessions with RouteQualitySummary.
iOS/Core/Export/SkateTrackPackageExportProvider.swift    # [協作區 — 邊界適配層] Marks exported .skatetrack packages with location-diagnostics-v1, route-quality-summary-v1, navigation-continuity-diagnostics-v1, and DEBUG-only debug-simulated-route-v1 capabilities when applicable.
scripts/verify_task030c_gps_diagnostics_package.py       # Verifies Task-030c-a diagnostics schema, package capabilities, docs alignment, and no road snapping / production-service / signing drift.
```

## Task-030c-b High-Accuracy Outdoor Recording + DEBUG Simulated Route

```text
Shared/Models/MotionSample.swift                         # [協作區] Adds LocationSpeedSource.debugSimulated for explicitly marked simulator route diagnostics.
iOS/Core/SensorEngine/GPSProvider.swift                  # [自主區] Active ride recording requests kCLLocationAccuracyBestForNavigation, 1 m distance filtering, .fitness activity type, and no automatic pausing.
iOS/Core/SensorEngine/SensorFusionEngine.swift           # [自主區] Uses active ride GPS policy whenever primary, secondary, or supplemental route-tracking channels include GPS.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # [自主區] Stores DEBUG simulated route samples in completed mock sessions and fixes duplicate motionSamples argument risk.
iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift # [自主區] Generates DEBUG-only skating-like simulated route, speed, altitude, accuracy, and low-confidence samples.
iOS/Core/Export/SkateTrackPackageExportProvider.swift    # [協作區 — 邊界適配層] Adds debug-simulated-route-v1 capability only for DEBUG simulated route packages.
Shared/Localization/en.lproj/Localizable.strings         # [協作區] DEBUG simulated route copy.
Shared/Localization/zh-Hant.lproj/Localizable.strings    # [協作區] DEBUG simulated route copy.
Shared/Localization/ja.lproj/Localizable.strings         # [協作區] DEBUG simulated route copy.
scripts/verify_task030c_high_accuracy_debug_route.py     # Verifies Task-030c-b high-accuracy policy, DEBUG simulated route, localization, docs, and scope boundaries.
```

### Task-030c-a data interpretation rule

- `SkateTrack-Session-20260613-110119.skatetrack` is the real-device baseline for Task-030c route / speed fidelity work.
- `SkateTrack-Session-20260612-180037.skatetrack` is a simulator / compatibility reference only and must not be used as real-device GPS evidence.
- Task-030c-a records Core Location diagnostics; Task-030c-b remains responsible for high-accuracy outdoor recording policy changes.

### Task-030c-b Live HUD Speed Trace Visibility Fix

```text
iOS/Features/SessionRecording/LiveHUDView.swift          # [協作區] Appends Live HUD speed trace samples from timer, elapsed-time, speed-change, and recording-start paths.
iOS/Features/SessionRecording/LiveSpeedTraceView.swift   # [協作區] Keeps the Live HUD background speed trace visible with a waiting baseline before two samples accumulate.
scripts/verify_live_hud.py                               # Verifies current Live HUD speed trace wiring, fallback baseline, current full-screen layout, and source membership.
```

Task-030c-b speed trace fix does not change GPS policy, DEBUG route generation, road snapping, map matching, signing, capabilities, entitlements, Launch Screen, AppIcon, bottom dock, watchOS, or production services.


## Task-030c-b2 Navigation-grade Location Continuity

```text
SkateTrack.xcodeproj/project.pbxproj                    # [工程設定] Enables generated iOS Info.plist background location mode for screen-off active ride recording.
Shared/Models/MotionSample.swift                         # [協作區] Adds receivedAtTimestamp diagnostics plus motion/location long-gap counters in RouteQualitySummary.
iOS/Core/SensorEngine/GPSProvider.swift                  # [自主區] Keeps active ride background location updates enabled, requests Always upgrade when possible, uses significant-change backup, and accepts lower-confidence-but-valid pocket fixes for diagnostics instead of dropping them at 35 m.
iOS/Core/SensorEngine/SensorFusionEngine.swift           # [自主區] Records received-at timestamps and publishes location-driven samples when Core Location wakes the app while timers may be throttled.
iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift # [自主區] Keeps DEBUG simulated route diagnostics aligned with received-at timestamps.
iOS/Core/Export/SkateTrackPackageExportProvider.swift    # [協作區 — 邊界適配層] Adds navigation-continuity-diagnostics-v1 package capability.
scripts/verify_task030c_navigation_continuity.py         # Verifies Task-030c-b2 background-location Info.plist settings, navigation continuity safeguards, diagnostics, docs, and no road snapping / production-service drift.
```

Task-030c-b2 intentionally touches iOS generated Info.plist background location settings for the iOS target only. It still does not add road snapping, map matching, route replay, Snow Mode, watchOS, StoreKit, Google production services, CloudKit / iCloud, WeatherKit production, Launch Screen, AppIcon, bottom dock, or Apple Developer Program production integrations. Real-device screen-off pocket validation remains required before claiming navigation-grade route reliability.

## Task-030c-b3 Route Recording Recovery Additions

- `iOS/Core/SessionRecording/SessionRecordingCoordinator.swift` — reconciles saved summary distance with route quality distance, scopes fall events to the active session window, and guards fall alerts during implausibly high-speed validation runs.
- `iOS/Core/SensorEngine/FallDetectionEngine.swift` — resets detected fall events at the start of each monitoring session so stale fall events do not leak into later sessions.
- `iOS/Core/SensorEngine/SensorFusionEngine.swift` — prefers Core Location speed when available and rejects implausible coordinate-derived speed outliers for current pre-Snow-mode route recovery.
- `iOS/Core/SensorEngine/GPSProvider.swift` — applies the same coordinate-derived speed outlier guard before publishing fallback speed.
- `iOS/Features/SessionSummary/SessionAdvancedChartsView.swift` — assigns chart segment identifiers when long gaps, stale fixes, or low-confidence fixes appear.
- `iOS/Features/SessionSummary/SpeedTimelineChartView.swift` — renders speed as segmented lines without area fills so missing data does not appear as pale filled blocks.
- `iOS/Features/SessionSummary/ElevationProfileChartView.swift` — renders elevation as segmented lines without area fills so missing data does not appear as pale filled blocks.
- `iOS/Features/SessionSummary/SessionRouteMapView.swift` — splits route map polylines across long gaps or low-confidence location diagnostics instead of drawing one continuous precise route.
- `iOS/Features/SessionSummary/SessionSummaryView.swift` — uses a persistent floating bottom return CTA via `safeAreaInset(edge: .bottom)`.
- `scripts/verify_task030c_route_recording_recovery.py` — verifies Task-030c-b3 route recovery, chart gap-awareness, floating return, fall reset, and scope boundaries.

Task-030c-b3 verification token: Navigation-grade Route Recording Recovery, route-recording-recovery-v1, gap-aware charts, floating bottom return, road snapping deferred.

## Task-030c-b4 Raw CLLocation Stream Persistence

```text
Shared/Models/MotionSample.swift                         # Adds MotionSampleSource and raw location-fix deduplication helpers for route-quality summaries.
iOS/Core/SensorEngine/SensorFusionEngine.swift           # Persists every accepted CLLocation as a dedicated .locationFix MotionSample using raw CLLocation timestamps.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # Reconciles summary distance with trusted raw route segments instead of blindly counting long-gap jumps.
iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift # Marks DEBUG simulated route samples as .debugSimulated.
iOS/Core/Export/SkateTrackPackageExportProvider.swift    # Adds raw-location-stream-v1 export capability.
iOS/Features/SessionSummary/SessionRouteMapView.swift    # Localizes start / finish map annotations.
scripts/verify_task030c_raw_location_stream.py           # Verifies raw CLLocation stream persistence boundaries.
```

### Task-030c-b5 Activity-Aware Location, Speed & Altitude Fidelity

- `Shared/Models/MotionSample.swift` — Adds `ActivityFidelityProfile`, `ActivityFidelityPolicy`, and `AltitudeSampleSource` so route, speed, altitude, and fall policies no longer rely on one skateboard-only speed range.
- `Shared/Models/SessionData.swift` — Carries an optional `fidelityProfile` in session packages while keeping old `.skatetrack` decode compatible.
- `iOS/Core/SensorEngine/SensorFusionEngine.swift` — Tags location-fix altitude as Core Location absolute altitude, timer-fusion altitude as barometer relative altitude, and applies activity-aware route-confidence thresholds.
- `iOS/Core/SensorEngine/GPSProvider.swift` — Keeps high-speed coordinate-derived speed support within a broad global plausibility ceiling instead of the former skateboard-only cap.
- `iOS/Core/SessionRecording/SessionMetricsAccumulator.swift` — Prevents mixed absolute / relative altitude from inflating elevation gain.
- `iOS/Core/SessionRecording/SessionRecordingCoordinator.swift` — Reconciles summary distance, speed, fall alert gating, and elevation gain through activity-aware policy.
- `iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift` — Marks DEBUG simulated altitude with `AltitudeSampleSource.debugSimulated`.
- `iOS/Features/SessionSummary/SessionAdvancedChartsView.swift` — Filters speed / elevation charts through activity-aware speed and altitude-source policies.
- `scripts/verify_task030c_activity_aware_fidelity.py` — Guards against regression to fixed 45 / 90 km/h assumptions and mixed altitude-source rendering.

Task-030c-b5 verification token: Activity-Aware Location, Speed & Altitude Fidelity, activity-aware-fidelity-v1, altitude-source-stabilization-v1, Core ML optional, road snapping deferred.


## Task-030c-b6 Debug Tools Status Panel Polish

- `iOS/Hooks/useSessionRecording.swift` — Polishes the DEBUG-only `SessionRecordingPreviewPanel` into a labeled diagnostics card with state, speed, distance, elapsed time, GPS count, sample count, latest accuracy, freshness, and sample-source chip.
- `iOS/Features/Debug/DebugToolsPanelView.swift` — Adds the polished `Task-030c-b6` build-signature card at the bottom of Debug Tools so real-device testers can confirm the installed build.
- `Shared/Localization/en.lproj/Localizable.strings` — Adds English Debug status panel and build-signature strings.
- `Shared/Localization/zh-Hant.lproj/Localizable.strings` — Adds Traditional Chinese Debug status panel and build-signature strings.
- `Shared/Localization/ja.lproj/Localizable.strings` — Adds Japanese Debug status panel and build-signature strings.
- `scripts/verify_task030c_debug_panel_polish.py` — Guards the b6 diagnostics card, build-signature card, and localization keys.
- `scripts/verify_debug_tools.py` — Extends the existing debug tools gate with b6 debug panel polish tokens.

Task-030c-b6 verification token: Debug Tools Status Panel Polish, Task-030c-b6, debug-build-signature-card, session-recording-preview-panel.

### Task-030c-b7 Background Recording Gap Diagnostics

```text
Shared/Models/SessionData.swift                         # [協作區] Adds optional DEBUG-only `debugRecordingDiagnostics` payload models for event-based background / lock-screen gap analysis.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # [自主區] Starts / finishes DEBUG recording diagnostics, records app lifecycle / protected data events, and attaches diagnostics to saved sessions.
iOS/Core/SensorEngine/GPSProvider.swift                 # [自主區] Records Core Location callback, authorization, location manager config, filter decision, pause / resume, and significant-change backup diagnostics.
iOS/Core/Export/SkateTrackPackageExportProvider.swift   # [協作區] Adds debug package capabilities when an exported session includes recording diagnostics.
iOS/Hooks/useSessionRecording.swift                     # [邊界適配層] Exposes DEBUG recording test context selection to Debug Tools before a session starts.
iOS/Features/Debug/DebugFeatureFlag.swift               # [協作區] Adds Debug Tools card metadata for recording test context tagging.
iOS/Features/Debug/DebugToolsPanelView.swift            # [協作區] Adds a polished DEBUG-only recording test context picker and updates the build signature to Task-030c-b7.
scripts/verify_task030c_background_gap_diagnostics.py   # Verifies DEBUG-only background recording gap diagnostics scope and docs.
```

Task-030c-b7 verification token: Background Recording Gap Diagnostics, debug-recording-diagnostics-v1, background-gap-diagnostics-v1, DEBUG-only, protected data.


### Task-030c-b8 debug recording context labels

- `Shared/Models/SessionData.swift` — adds DEBUG recording context cases for electric longboard locked-pocket and scooter locked-pocket validation.
- `iOS/Features/Debug/DebugToolsPanelView.swift` — shows concise selected-context descriptions and updates the debug build signature to `Task-030c-b8`.
- `Shared/Localization/*/Localizable.strings` — localizes the refined debug recording context labels and descriptions.
- `scripts/verify_task030c_debug_recording_context_labels.py` — verifies the b8 label polish without touching GPS runtime behavior.

### Task-030c-b9 diagnostics export guard

```text
Shared/Models/SessionData.swift                         # Adds Task-030c-b9 diagnostics build identity and diagnosticsStatus for export verification.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # Ensures DEBUG diagnostics exports are non-nil and adds a non-DEBUG disabled-by-build-configuration placeholder.
iOS/Core/Export/SkateTrackPackageExportProvider.swift   # Emits debug-build-identity-v1 and diagnostics-export-status-v1 when diagnostics metadata is present.
iOS/Features/Debug/DebugToolsPanelView.swift            # Shows Task-030c-b9 as the tester-visible Debug Tools build signature.
scripts/verify_task030c_diagnostics_export.py           # Verifies the b9 diagnostics export contract.
```

Task-030c-b9 verification token: Ensure Background Diagnostics Export, Task-030c-b9, diagnostics export, debug-build-identity-v1, diagnostics-export-status-v1.

### Task-030c-b9-r1 diagnostics persistence guard

```text
Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b9-r1.
Shared/Persistence/PersistenceController.swift          # Adds optional local `debugRecordingDiagnosticsData` Core Data attribute for persisted sessions.
Shared/Persistence/SessionEntityMapper.swift            # Encodes / decodes `debugRecordingDiagnosticsData` during SessionData save / fetch round trips.
Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents # Mirrors optional `debugRecordingDiagnosticsData` in the model file.
iOS/Core/Export/SkateTrackPackageExportProvider.swift   # Applies a `missingFromPersistedSession` diagnostics fallback before package capabilities are computed.
iOS/Features/Debug/DebugToolsPanelView.swift            # Shows Task-030c-b9-r1 as the tester-visible Debug Tools build signature.
Tests/iOSTests/SessionRepositoryTests.swift             # Asserts Core Data save / fetch preserves diagnostics build identity and status.
scripts/verify_task030c_diagnostics_persistence.py      # Verifies the b9-r1 diagnostics persistence and export fallback guard.
```

Task-030c-b9-r1 verification token: Persist Diagnostics Through Session Export, Task-030c-b9-r1, debugRecordingDiagnosticsData, missingFromPersistedSession, diagnostics export.

### Task-030c-b10 background runtime and quality gate guard

```text
iOS/App/Info.plist                                      # Explicit iOS app plist with UIBackgroundModes/location as an array for effective runtime bundle declaration.
SkateTrack.xcodeproj/project.pbxproj                   # Wires only SkateTrack-iOS Debug / Release to iOS/App/Info.plist while preserving existing background-mode build-setting token.
Shared/Models/SessionData.swift                        # Updates diagnostics build identity to Task-030c-b10 and adds RecordingDebugBundleInfoSnapshot.
Shared/Models/MotionSample.swift                       # Adds trusted route segment policy helpers and prevents low-quality diagnostic segments from inflating trusted GPS distance.
iOS/Core/SensorEngine/GPSProvider.swift                # Resolves runtime UIBackgroundModes from the built bundle and records bundle info in location manager diagnostics.
iOS/Core/SensorEngine/SensorFusionEngine.swift         # Keeps raw location diagnostics while preventing stale / low-confidence fixes from replacing trusted live route anchors.
iOS/Core/SessionRecording/SessionMetricsAccumulator.swift # Prevents stale / low-confidence gap-recovery samples from updating trusted summary speed and distance.
iOS/Features/Debug/DebugToolsPanelView.swift           # Shows Task-030c-b10 as the tester-visible Debug Tools build signature.
scripts/verify_task030c_background_runtime_quality_gate.py # Verifies b10 background runtime wiring and gap-recovery quality gate tokens.
```

Task-030c-b10 verification token: Effective Background Location Runtime + Gap Recovery Quality Gate, Task-030c-b10, iOS/App/Info.plist, background runtime, gap recovery.

### Task-030c-b10-r2 startup guard

```text
Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b10-r2.
iOS/Core/SensorEngine/SensorFusionEngine.swift           # Suppresses startup coordinate-derived speed spikes from trusted live route state.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # Suppresses startup handling fall events from alert/countdown and persisted fallEvents.
iOS/Features/Debug/DebugToolsPanelView.swift            # Shows Task-030c-b10-r2 in Debug Tools.
scripts/verify_task030c_startup_guard.py                # Verifies startup speed and fall handling guard tokens.
```

Task-030c-b10-r2 verification token: Startup Speed Spike + Fall Handling Guard, Task-030c-b10-r2, startup guard, coordinate-derived speed, fall handling.

### Task-030c-b10-r3 low-speed metrics and UI responsiveness guard

```text
Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b10-r3.
Shared/Models/MotionSample.swift                        # Adds ActivityFidelityPolicy.acceptsLowSpeedMetricSample for conservative trusted metric filtering.
iOS/Core/SensorEngine/SensorFusionEngine.swift          # Marks startup / low-speed local GPS jumps as low-confidence before live speed propagation.
iOS/Core/SessionRecording/SessionMetricsAccumulator.swift # Excludes low-confidence low-speed samples from live metrics and uses source-separated altitude gates.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # Reconciles saved metrics using trusted speed / distance / elevation helpers and yields before heavy startup work.
iOS/Hooks/useSkateTrackPackageExport.swift              # Creates package exports off the main actor with a user-initiated detached task.
iOS/Hooks/useSessionSummary.swift                       # Marks SessionSummaryContent as Sendable for export task handoff.
scripts/verify_task030c_low_speed_metrics_ui.py         # Verifies b10-r3 low-speed metric and UI responsiveness guardrails.
```

Task-030c-b10-r3 verification token: Low-Speed Metrics Gate + UI Responsiveness, Task-030c-b10-r3, verify_task030c_low_speed_metrics_ui.py, low-speed metrics, UI responsiveness.


### Task-030c-b10-r4 strict low-speed metrics and altitude source isolation

Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b10-r4.
Shared/Models/MotionSample.swift                        # Tightens low-speed metric acceptance thresholds for small-area / low-speed GPS artifacts.
iOS/Core/SensorEngine/SensorFusionEngine.swift           # Applies stricter live-route speed trust and standard skateboard low-speed policy.
iOS/Core/SessionRecording/SessionMetricsAccumulator.swift # Isolates barometer-relative elevation from Core Location absolute altitude drift.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # Reconciles final summary metrics using strict low-speed and altitude-source gates.
scripts/verify_task030c_strict_low_speed_altitude.py     # Verifies b10-r4 strict low-speed metrics and altitude source isolation.

Task-030c-b10-r4 verification token: Strict Low-Speed Metrics + Altitude Source Isolation, Task-030c-b10-r4, verify_task030c_strict_low_speed_altitude.py, strict low-speed metrics, altitude source isolation.
Task-030c-b10-r4 compatibility token: Background Location Runtime + Gap Recovery Quality Gate, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard, verify_task030c_low_speed_metrics_ui.py, verify_task030c_startup_guard.py.

### Task-030c-b10-r5 trusted chart metrics and display source alignment

Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b10-r5.
iOS/Features/Debug/DebugToolsPanelView.swift            # Shows the Task-030c-b10-r5 Debug build signature.
iOS/Features/SessionSummary/SessionAdvancedChartsView.swift # Builds trusted / smoothed speed and elevation chart point series.
iOS/Features/SessionRecording/LiveHUDView.swift         # Smooths the Live HUD trace display without changing raw samples.
scripts/verify_task030c_trusted_chart_metrics.py        # Verifies trusted chart metrics and display source alignment.

Task-030c-b10-r5 verification token: Trusted Chart Metrics + Display Source Alignment, Task-030c-b10-r5, verify_task030c_trusted_chart_metrics.py, trusted chart metrics, display source alignment.
Task-030c-b10-r5 compatibility token: Strict Low-Speed Metrics + Altitude Source Isolation, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard.

### Task-030c-b11 small-area route geometry stabilization

```text
Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b11.
iOS/Features/Debug/DebugToolsPanelView.swift            # Shows the Task-030c-b11 Debug build signature.
iOS/Features/SessionSummary/SessionRouteMapView.swift   # Separates rawRoute / trustedRoute / displayRoute and renders a stabilized Summary map route.
scripts/verify_task030c_small_area_route_geometry.py     # Verifies the b11 small-area display-route guardrails.
scripts/verify_session_summary.py                       # Guards the updated SessionRouteMapView display route pipeline.
```

Task-030c-b11 verification token: Small-Area Route Geometry Stabilization, Task-030c-b11, verify_task030c_small_area_route_geometry.py, rawRoute, trustedRoute, displayRoute.
Task-030c-b11 compatibility token: Trusted Chart Metrics + Display Source Alignment, Strict Low-Speed Metrics + Altitude Source Isolation, Low-Speed Metrics Gate + UI Responsiveness.

### Task-030c-b11-r1 route confidence display continuity

```text
Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b11-r1.
iOS/Features/Debug/DebugToolsPanelView.swift            # Shows the Task-030c-b11-r1 Debug build signature.
iOS/Features/SessionSummary/SessionRouteMapView.swift   # Displays low-confidence route segments as uncertain secondary lines instead of route disappearance.
scripts/verify_task030c_route_confidence_display.py      # Verifies b11-r1 route confidence display continuity guardrails.
```

Task-030c-b11-r1 verification token: Route Confidence Display Continuity, Task-030c-b11-r1, verify_task030c_route_confidence_display.py, low-confidence route display, uncertain route segment.

### Task-030c-b11-r2 activity-aware route confidence and small-area display gate

Shared/Models/MotionSample.swift                         # Adds activity-aware display-route and speed-display policy helpers.
Shared/Protocols/SensorProvider.swift                    # Passes power type and fidelity profile into live recording.
iOS/Core/SensorEngine/SensorFusionEngine.swift           # Uses active fidelity profile for live route confidence, speed, and route acceptance.
iOS/Core/SessionRecording/SessionRecordingCoordinator.swift # Resolves electric / vehicle-validation debug contexts before starting the sensor engine.
iOS/Core/SessionRecording/SessionMetricsAccumulator.swift # Applies active fidelity policy to live trusted metrics.
iOS/Features/SessionSummary/SessionRouteMapView.swift    # Uses session fidelity policy for displayRoute filtering and high-speed proxy continuity.
iOS/Features/SessionSummary/SessionAdvancedChartsView.swift # Keeps fresh uncertain chart segments continuous and uses activity-aware speed corroboration.
scripts/verify_task030c_activity_aware_route_confidence.py # Guards the b11-r2 confidence alignment.

Task-030c-b11-r2 verification token: Activity-Aware Route Confidence + Small-Area Display Gate, Task-030c-b11-r2, verify_task030c_activity_aware_route_confidence.py.


Task-030c-b11-r2 compatibility token: Strict Low-Speed Metrics + Altitude Source Isolation.


### Task-030c-b11-r3-3 post-record GPS lock guard and approximate start semantics

Shared/Models/SessionData.swift                         # Updates diagnostics build identity to Task-030c-b11-r3-3.
iOS/Features/Debug/DebugToolsPanelView.swift            # Shows the Task-030c-b11-r3-3 Debug build signature.
iOS/Features/SessionSummary/SessionRouteMapView.swift   # Separates approximate recording-start marker from GPS lock route anchor and uses post-lock route coordinates for primary region.
scripts/verify_task030c_startup_gps_warmup.py           # Guards startup warm-up display and disclosure behavior.
scripts/verify_task030c_startup_anchor_semantics.py     # Guards approximate start marker, GPS lock route anchor, and region anchoring semantics.

Task-030c-b11-r3-3 verification token: Post-Record GPS Lock Guard + Approximate Start Semantics, Task-030c-b11-r3-3, GPS lock route anchor, approximate start marker, startup convergence warm-up, session-route-accuracy-disclosure.
