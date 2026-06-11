# SkateTrack File Structure

**Last Updated:** 2026-06-11
**Source of Truth:** DevProcess v1.0 Principle E — Living Documentation Protocol
**Current Baseline:** Source-controlled repository after Task-018b Route Map + Safety / Share Stub
**Current Development Gate:** Task-018b is complete as the Summary route-map, safety recap, and share-entry stub layer. Advanced charts, real share-card export, and production App Store Connect monetization remain deferred.

This document records the current SkateTrack repository structure and development status. It focuses on source-controlled files and intentionally excludes `.git/`, `xcuserdata/`, `DerivedData/`, `.build/`, simulator output, and other generated local artifacts.

## Current Progress Snapshot

| Area | Status | Notes |
|---|---:|---|
| Task-001 Project Scaffold | Complete | Workspace, Xcode project, platform app targets, baseline docs, Git-ready repository structure. |
| Task-002 Localization Infrastructure | Complete | English and Traditional Chinese localization resources plus shared formatting utilities. |
| Task-003 Shared Data Models | Complete | Cross-platform models for sport modes, sessions, motion samples, falls, tricks, equipment, and spots. |
| Task-004 Feature Flags | Complete | Subscription-gated feature definitions and DEBUG subscription override engine. |
| Task-005 Living Documentation | Complete / Active | `docs/FILE_STRUCTURE.md` and `docs/DEV_LOG.md` remain living documents. |
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
| Task-018b Route Map + Safety / Share Stub | Complete | Summary now renders a MapKit route preview when valid GPS samples exist, preserves no-route empty states, summarizes local fall-event safety status, and exposes a deferred share stub. Advanced charts and production monetization remain deferred. |
| App Icon Integration | Assets present, runtime verification unresolved | iOS/watchOS/macOS AppIcon asset folders and macOS `.icns` exist, but runtime app icon display has not yet matched the intended result on the user's machine. |

## Current Known Issues / Follow-up

| Issue | Impact | Likely Area |
|---|---|---|
| Runtime app icon display still needs final manual confirmation on the user's machine. | Asset catalogs and scripts may pass while simulator / device cache behavior still needs visual verification. | Asset catalog membership, generated Info.plist icon keys, Xcode / simulator cache. |
| Live HUD tilt is intentionally conservative and uncalibrated in Phase 1a. | The app should not claim precise skateboard lean until a real calibration flow and fixed phone placement assumptions exist. | `TiltIndicatorView.swift`, future calibration UX, future sensor interpretation layer. |
| Indoor / no-GPS speed may remain `0.0 km/h`. | This is expected when real-speed runtime is active and GPS speed is unavailable; future work may expose speed-source status. | `GPSProvider.swift`, `SensorFusionEngine.swift`, future HUD speed-source UI. |
| Advanced charts, real share-card export, and detailed analysis are not built yet. | Task-018b provides the Summary route map, safety recap, and share-entry stub only; Swift Charts, subscriber-only chart gating, export, and deeper analysis remain future Task-018 phases. | `iOS/Features/SessionSummary`, future Swift Charts components, `SessionRepositoryProtocol`, `FeatureFlagEngine`. |
| Equipment mileage, spot linkage, and cloud sync remain future tasks. | Core Data entities exist as foundations, but product flows are not connected. | Future equipment, spot, Google Drive / CloudKit tasks. |
| Real StoreKit monetization is deferred. | The app should not claim production subscription readiness until Apple Developer Program, App Store Connect products, sandbox testing, and production StoreKit provider are completed. | `iOS/Core/Subscription`, `iOS/Hooks/useSubscriptionStatus.swift`, future `AppStoreSubscriptionProvider`, `docs/decisions/ADR-0001-subscription-entitlement-strategy.md`. |


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
| Swift source files | App entries, shared models/utilities, persistence, iOS engines, iOS UI, hooks, watchOS/macOS shells, and tests | ~79 Swift files |
| Verification scripts | Python scripts for localization, models, feature flags, sensors, session recording, HUD, start flow, debug tools, safety, icons, persistence, subscription entitlement simulation, Paywall validation, and Session History validation | 21 scripts |
| Task prompt packs | Task-002 through Task-013 task documentation folders | 11 task folders |
| App-icon images | Generated iOS/watchOS/macOS PNG icon assets plus macOS `.icns` | 103 image/icon files in current baseline |
| Tests | iOS session recording coordinator and session repository tests | 2 active iOS test files |
| Living docs | `docs/FILE_STRUCTURE.md`, `docs/DEV_LOG.md` | Active |

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
│   │   ├── EquipmentProfile.swift                  # [協作區] Equipment identity, power type, mileage, wheel data, and notes.
│   │   ├── EmergencyContact.swift                  # [協作區] Local emergency contact model used by SOS contact flow.
│   │   ├── FallEvent.swift                         # [協作區] Fall timeline event and SOS-related fall metadata.
│   │   ├── MotionSample.swift                      # [協作區] GPS, speed, acceleration, gyro, altitude, and accuracy sample model.
│   │   ├── PowerType.swift                         # [協作區] Human-powered / electric power classification.
│   │   ├── SessionData.swift                       # [協作區] Root session container for samples, tricks, falls, equipment, and summary metrics.
│   │   ├── SessionSummaryMetrics.swift             # [協作區] Completed-session summary and live metric snapshot structs.
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
│   │   ├── RootNavigationView.swift                # [協作區] Routes idle/failed states to Session Start and active states to Live HUD.
│   │   └── SkateTrackApp.swift                     # [協作區] iOS app entry and shared state-owner wiring.
│   ├── Core/                                       # [自主區] iOS implementation engines.
│   │   ├── DataPipeline/                           # [佔位] Future persistence and data-processing pipeline.
│   │   ├── MLEngine/                               # [佔位] Future trick recognition and ML inference engines.
│   │   ├── SensorEngine/                           # [自主區] iOS sensor providers and fusion/fall engines.
│   │   │   ├── BarometerProvider.swift             # [自主區] CMAltimeter relative altitude / pressure provider.
│   │   │   ├── FallDetectionEngine.swift           # [自主區] Impact detection, stationary confirmation, countdown, and SOS event publishing.
│   │   │   ├── GPSAuthorizationHandler.swift       # [自主區] CLLocation authorization wrapper.
│   │   │   ├── GPSProvider.swift                   # [自主區] Filtered CLLocation and km/h speed provider.
│   │   │   ├── IMUProvider.swift                   # [自主區] 50Hz accelerometer and gyro provider.
│   │   │   ├── SensorCalibrationEngine.swift       # [自主區] Startup bias calibration and mode sensor priority planning.
│   │   │   └── SensorFusionEngine.swift            # [自主區] 10Hz fused `MotionSample` engine.
│   │   ├── Safety/                                 # [自主區] iOS safety event dispatch and fall/SOS bridge.
│   │   │   ├── EmergencyContactStore.swift         # [自主區] Local UserDefaults-backed emergency contact store for Phase 1a.
│   │   │   ├── SOSEventDispatcher.swift            # [自主區] Phase 1a contact-aware SOS event dispatcher; records events without pretending to auto-send SMS.
│   │   │   └── SessionRecordingCoordinator+FallSafety.swift # [自主區] Fall alert cancel / manual SOS / immediate SOS actions.
│   │   ├── SessionRecording/                       # [自主區] Recording lifecycle and metrics accumulation.
│   │   │   ├── SessionMetricsAccumulator.swift     # [自主區] Distance, speed, elevation, tilt, and moving ratio accumulator.
│   │   │   ├── SessionRecordingCoordinator.swift   # [自主區] Sole session lifecycle coordinator.
│   │   │   ├── SessionRecordingCoordinator+DebugMock.swift # [自主區] DEBUG-only demo speed sample feed.
│   │   │   └── SessionStateMachine.swift           # [自主區] Strict session-state transition rules.
│   │   └── Subscription/
│   │       └── FeatureFlagEngine.swift             # [自主區] Feature access and DEBUG subscription override logic.
│   ├── Features/                                   # [協作區] iOS feature modules.
│   │   ├── Debug/                               # [協作區] DEBUG-only unified development tools.
│   │   │   ├── DebugFeatureFlag.swift           # [協作區] Central DEBUG tool feature definitions.
│   │   │   ├── DebugMockSessionFactory.swift    # [協作區] Explicit demo speed / mock session helper; not used by normal app runtime.
│   │   │   ├── DebugRuntimeOptions.swift        # [協作區] Shared DEBUG runtime presentation state.
│   │   │   ├── DebugToolAction.swift            # [協作區] Central DEBUG tool action identifiers.
│   │   │   └── DebugToolsPanelView.swift        # [協作區] Unified Debug Tools panel for fall simulation, demo speed, subscription override, and test data reset.
│   │   ├── EquipmentManager/                       # [佔位] Future equipment management UI.
│   │   ├── FallDetection/                          # [協作區] Fall alert / SOS overlay UI.
│   │   │   ├── EmergencyContactsSettingsView.swift # [協作區] Dark contact settings sheet for local emergency contacts.
│   │   │   ├── FallDetectionAlertView.swift        # [協作區] Dark neon fall alert card, countdown, contact status, cancel and SOS buttons.
│   │   │   └── FallDetectionOverlayPresenter.swift # [協作區] High-priority overlay and SOS status presenter for Live HUD.
│   │   ├── HealthReminders/                        # [佔位] Future rest, hydration, heat, and safety reminders.
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
│   │   │   ├── SessionStartView.swift              # [協作區] Session Start flow; currently under visual-alignment review.
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
│   │   │   ├── SessionHistoryView.swift            # [協作區] Main History screen with summary, filters, repository state, and Paywall routing.
│   │   │   ├── SessionHistoryListView.swift        # [協作區] Month-grouped saved-session list.
│   │   │   ├── SessionHistoryCardView.swift        # [協作區] Saved-session card with locked old-session state.
│   │   │   ├── SessionHistoryFilterBar.swift       # [協作區] All / Skate / Inline / Electric filter bar.
│   │   │   ├── SessionSummaryHandoffView.swift     # [協作區] Legacy Task-017b handoff placeholder retained for reference; Task-018a now opens `SessionSummaryView`.
│   │   │   └── HistoryLimitPaywallBanner.swift     # [協作區] Free 5-session limit upgrade banner.
│   │   ├── SessionSummary/                         # [協作區] Task-018a/018b Summary foundation, route map, safety recap, and share stub.
│   │   │   ├── SessionSummaryView.swift            # [協作區] Real Summary foundation opened from unlocked History cards.
│   │   │   ├── SessionSummaryMetricsGridView.swift # [協作區] Core metrics grid for distance, speed, duration, elevation, falls, and tricks.
│   │   │   ├── SessionSummaryPlaceholderSectionView.swift # [協作區] Chart / health placeholders for later Task-018 phases.
│   │   │   ├── SessionRouteMapView.swift           # [協作區] MapKit route preview, start / finish markers, and no-route empty state.
│   │   │   ├── SessionSummarySafetyStatusView.swift # [協作區] Local fall-event and safety recap for Summary.
│   │   │   └── SessionSummaryShareStubView.swift   # [協作區] Deferred share-card entry point; no real export yet.
│   │   ├── Social/                                 # [佔位] Future sharing and community features.
│   │   ├── SpotManagement/                         # [佔位] Future spot database and user spot management.
│   │   ├── TrickRecognition/                       # [佔位] Future trick UI and ML results.
│   │   └── Tutorials/                              # [佔位] Future tutorials and onboarding.
│   └── Hooks/                                      # [協作區 — 邊界適配層] SwiftUI-facing adapters.
│       ├── useSessionRecording.swift              # [協作區 — 邊界適配層] Observable session state/actions; DEBUG demo speed mode is explicit, not app-runtime default.
│       ├── useFallDetection.swift                 # [協作區 — 邊界適配層] Observable fall alert state, countdown, cancel and SOS actions.
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
│   ├── verify_session_history.py                   # [工程設定] Task-017a Session History / free-limit plus Task-017b/018a handoff verification.
│   ├── verify_session_summary.py                   # [工程設定] Task-018a/018b Session Summary, route map, safety, and share-stub verification.
│   ├── verify_session_start_flow.py               # [工程設定] Task-012 source-pattern verification; not a visual-layout test.
│   └── verify_shared_models.py                    # [工程設定] Task-003 verification.
├── docs/                                          # [原則 E] Living documentation.
│   ├── FILE_STRUCTURE.md                          # [原則 E] This source tree and status document.
│   ├── DEV_LOG.md                                 # [原則 E] Chronological development log and correction notes.
│   └── decisions/                                 # [原則 E] Architecture decision records.
│       └── ADR-0001-subscription-entitlement-strategy.md # [原則 E] Decision to use replaceable entitlement providers before real App Store monetization.
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
python3 scripts/verify_app_icons.py
```

Important: the UI-related scripts currently verify file existence, localization keys, and source-pattern contracts. They do **not** prove rendered iPhone layout or runtime app-icon cache behavior. Manual Xcode / simulator / device validation remains required for visual acceptance.


## Recommended Next Step

1. Continue with Task-018c advanced chart work on top of `SessionSummaryView`, not by recreating a second Summary screen.
2. Keep Task-018c advanced chart gating separate from Task-018b route/safety work and route subscriber-only chart access through `FeatureFlagEngine` / `useSubscriptionStatus`.
3. Keep Task-016c real StoreKit work separate from Paywall / Summary UI. The future StoreKit provider should replace the entitlement provider behind `FeatureFlagEngine` instead of rewriting Paywall / locked-feature UI.
4. History / Summary UI should keep reading from the repository layer added in Task-015a / Task-015b; Views should not import or manipulate `NSManagedObject` directly.

## Task-016b Subscription UI Note

Task-016b adds the `iOS/Features/Subscription` module for Paywall and locked-feature UI. This module is UI-only in Task-016b and must continue to consume `useSubscriptionStatus` rather than directly reading DEBUG flags or StoreKit state.
