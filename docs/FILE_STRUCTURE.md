# SkateTrack File Structure

**Last Updated:** 2026-06-10  
**Source of Truth:** DevProcess v1.0 Principle E — Living Documentation Protocol  
**Current Baseline:** Source-controlled repository after Tasks 001–013, inspected from `SkateTrack_Current_For_UI_Diagnosis.zip`  
**Current Development Gate:** Do **not** proceed to Task-014 until the Task-013 iOS visual alignment and app-icon runtime wiring issues are resolved.

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
| Task-013 Live HUD + Slide-to-End | Functionally implemented, visually not accepted yet | Live HUD, pause/resume, slide-to-end, and inline placeholders exist. Current screenshots show fullscreen/layout clipping problems and inline glyph regression, so UI acceptance is still blocked. |
| App Icon Integration | Assets present, runtime verification unresolved | iOS/watchOS/macOS AppIcon asset folders and macOS `.icns` exist, but runtime app icon display has not yet matched the intended result on the user's machine. |

## Current Known Issues Blocking Task-014

| Issue | Impact | Likely Area |
|---|---|---|
| iOS Session Start and Live HUD still do not visually occupy the intended full phone canvas. | UI does not match uploaded full-screen mockups. | `SessionStartView.swift`, `LiveHUDView.swift`, root layout, safe-area / bottom-control architecture. |
| Start Session / Slide-to-End controls can be clipped near the bottom. | Manual testing cannot confidently validate Task-013 controls. | Bottom dock, `ScrollView`, container height, safe-area padding. |
| Custom inline-skating glyph regressed visually. | Inline mode icon is not acceptable and should be redrawn from a stable vector/asset approach. | `SportCategoryPickerView.swift`, `InlineModeSelectorView.swift`, `ModeSelectionCardView.swift`, related glyph component. |
| App icon assets are present but runtime app icon is not applied correctly. | iOS/watchOS/macOS app icon is not reliably visible in the actual running app / Dock / simulator. | Asset catalog membership, target build settings, generated Info.plist icon keys, Xcode cache. |
| Verification scripts passed despite visual failure. | Current scripts verify source patterns, not actual rendered layout or target runtime icon result. | `scripts/verify_live_hud.py`, `verify_session_start_flow.py`, `verify_app_icons.py`. |

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
| Swift source files | App entries, shared models/utilities, iOS engines, iOS UI, hooks, watchOS/macOS shells, tests | 47 Swift files |
| Verification scripts | Python scripts for localization, models, feature flags, sensors, session recording, HUD, start flow, app icons | 12 scripts |
| Task prompt packs | Task-002 through Task-013 task documentation folders | 11 task folders |
| App-icon images | Generated iOS/watchOS/macOS PNG icon assets plus macOS `.icns` | 103 image/icon files in current baseline |
| Tests | iOS session recording coordinator tests | 1 active iOS test file |
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
│   │   ├── FallEvent.swift                         # [協作區] Fall timeline event and SOS-related fall metadata.
│   │   ├── MotionSample.swift                      # [協作區] GPS, speed, acceleration, gyro, altitude, and accuracy sample model.
│   │   ├── PowerType.swift                         # [協作區] Human-powered / electric power classification.
│   │   ├── SessionData.swift                       # [協作區] Root session container for samples, tricks, falls, equipment, and summary metrics.
│   │   ├── SessionSummaryMetrics.swift             # [協作區] Completed-session summary and live metric snapshot structs.
│   │   ├── SportMode.swift                         # [協作區] Skateboard and inline skating mode enums plus unified `SportMode`.
│   │   ├── SpotProfile.swift                       # [協作區] Saved riding spot profile and coordinates.
│   │   └── TrickEvent.swift                        # [協作區] Trick timeline event with confidence and landing information.
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
│   │   ├── SessionRecording/                       # [自主區] Recording lifecycle and metrics accumulation.
│   │   │   ├── SessionMetricsAccumulator.swift     # [自主區] Distance, speed, elevation, tilt, and moving ratio accumulator.
│   │   │   ├── SessionRecordingCoordinator.swift   # [自主區] Sole session lifecycle coordinator.
│   │   │   └── SessionStateMachine.swift           # [自主區] Strict session-state transition rules.
│   │   └── Subscription/
│   │       └── FeatureFlagEngine.swift             # [自主區] Feature access and DEBUG subscription override logic.
│   ├── Features/                                   # [協作區] iOS feature modules.
│   │   ├── EquipmentManager/                       # [佔位] Future equipment management UI.
│   │   ├── FallDetection/                          # [佔位] Future fall alert / SOS UI, scheduled for Task-014.
│   │   ├── HealthReminders/                        # [佔位] Future rest, hydration, heat, and safety reminders.
│   │   ├── RouteMap/                               # [佔位] Future full route map and replay UI.
│   │   ├── SessionRecording/                       # [協作區] Session Start and Live HUD UI components.
│   │   │   ├── BoardModeSelectorView.swift         # [協作區] Skateboard mode selector.
│   │   │   ├── InlineLiveMetricsView.swift         # [協作區] Inline-specific live metric placeholders.
│   │   │   ├── InlineModeSelectorView.swift        # [協作區] Inline mode selector and gated mode handling.
│   │   │   ├── LiveHUDMetricCardView.swift         # [協作區] Reusable metric card for HUD values.
│   │   │   ├── LiveHUDView.swift                   # [協作區] Active riding HUD; currently under visual-alignment review.
│   │   │   ├── LiveSpeedDisplayView.swift          # [協作區] Large speed / max-speed display component.
│   │   │   ├── MiniRouteMapView.swift              # [協作區] Lightweight route preview from recent coordinates.
│   │   │   ├── ModeSelectionCardView.swift         # [協作區] Reusable sport/mode card; contains current custom icon work.
│   │   │   ├── PowerTypeToggleView.swift           # [協作區] Human/electric skateboard power-type toggle.
│   │   │   ├── SessionStartView.swift              # [協作區] Session Start flow; currently under visual-alignment review.
│   │   │   ├── SlideToEndSessionControl.swift      # [協作區] Slide-to-end control with accidental-stop protection.
│   │   │   ├── SportCategoryPickerView.swift       # [協作區] Skateboard / inline category picker; contains current inline glyph work.
│   │   │   ├── StartSessionCTAView.swift           # [協作區] Start-session call-to-action button.
│   │   │   └── TiltIndicatorView.swift             # [協作區] Tilt visualization for Live HUD.
│   │   ├── Social/                                 # [佔位] Future sharing and community features.
│   │   ├── SpotManagement/                         # [佔位] Future spot database and user spot management.
│   │   ├── TrickRecognition/                       # [佔位] Future trick UI and ML results.
│   │   └── Tutorials/                              # [佔位] Future tutorials and onboarding.
│   └── Hooks/                                      # [協作區 — 邊界適配層] SwiftUI-facing adapters.
│       ├── useSessionRecording.swift              # [協作區 — 邊界適配層] Observable session state/actions and mock preview support.
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
│   │   └── SessionRecordingCoordinatorTests.swift  # [工程設定] Six iOS unit tests for state transitions and session coordinator behavior.
│   ├── watchOSTests/                              # [佔位] Future watchOS tests.
│   └── macOSTests/                                # [佔位] Future macOS tests.
├── scripts/                                       # [工程設定] Repository verification scripts.
│   ├── set_github_remote.sh                       # [工程設定] GitHub remote helper.
│   ├── verify_app_icons.py                        # [工程設定] Checks icon asset folders and selected project icon settings; does not prove runtime Dock/simulator display.
│   ├── verify_barometer_provider.py               # [工程設定] Task-008 verification.
│   ├── verify_fall_detection_engine.py            # [工程設定] Task-010 verification.
│   ├── verify_feature_flags.py                    # [工程設定] Task-004 verification.
│   ├── verify_gps_provider.py                     # [工程設定] Task-006 verification.
│   ├── verify_imu_provider.py                     # [工程設定] Task-007 verification.
│   ├── verify_live_hud.py                         # [工程設定] Task-013 source-pattern verification; not a visual-layout test.
│   ├── verify_localization_keys.py                # [工程設定] Task-002 localization key parity check.
│   ├── verify_sensor_fusion_engine.py             # [工程設定] Task-009 verification.
│   ├── verify_session_recording_coordinator.py    # [工程設定] Task-011 verification.
│   ├── verify_session_start_flow.py               # [工程設定] Task-012 source-pattern verification; not a visual-layout test.
│   └── verify_shared_models.py                    # [工程設定] Task-003 verification.
├── docs/                                          # [原則 E] Living documentation.
│   ├── FILE_STRUCTURE.md                          # [原則 E] This source tree and status document.
│   ├── DEV_LOG.md                                 # [原則 E] Chronological development log and correction notes.
│   └── decisions/                                 # [原則 E] Placeholder for future architecture decision records.
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
python3 scripts/verify_app_icons.py
```

Important: the UI-related scripts currently verify file existence, localization keys, and source-pattern contracts. They do **not** prove that rendered iPhone layout is visually full-screen, and they do **not** prove that runtime Dock/simulator app icons are actually applied. Manual Xcode / simulator validation remains required for Task-013 UI acceptance.

## Recommended Next Step

Before Task-014, run a focused Task-013 repair pass with the following scope only:

1. Diagnose the actual SwiftUI container that still constrains Session Start / Live HUD layout.
2. Replace the custom inline glyph with a stable, previewable vector asset or a clearly isolated `InlineSkateGlyph` component.
3. Verify iOS/watchOS/macOS AppIcon target wiring directly against `project.pbxproj`, asset-catalog membership, and runtime cache behavior.
4. Strengthen the verification scripts so they no longer pass while the visual acceptance criteria fail.

Task-014 Fall Alert / SOS UI should remain blocked until the Task-013 visual and icon issues are accepted.
