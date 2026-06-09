# SkateTrack File Structure

**Last Updated:** 2026-06-09  
**Source of Truth:** DevProcess v1.0 Principle E — Living Documentation Protocol  
**Task:** Task-005 — FILE_STRUCTURE.md + DEV_LOG.md Init  
**Scope:** Source-controlled repository structure after Tasks 001–005.

This document records the current SkateTrack repository layout after Phase 0 foundation work. It must be updated whenever three or more files are added or changed, or when a phase is completed.

Ignored/transient files are intentionally not listed here, including `.git/`, `.DS_Store`, `xcuserdata/`, `DerivedData/`, `.build/`, and generated `Package.resolved` files.

## Zone Legend

| Label | Meaning |
|---|---|
| `[協作區]` | Human-readable UI, app entry, hooks, orchestration, shared constants, shared models, shared utilities. |
| `[協作區 — 邊界適配層]` | Boundary layer that exposes clean API to Views while delegating implementation details. |
| `[自主區]` | Implementation-heavy or performance-sensitive engine code owned by AI-assisted logic. |
| `[原則 A]` | Localization and locale-sensitive resources. |
| `[原則 E]` | Living documentation and architecture recordkeeping. |
| `[工程設定]` | Xcode, build, repository, or tooling configuration. |
| `[任務文件]` | Task prompt pack and acceptance documentation for agent development. |
| `[佔位]` | Placeholder directory preserved for planned work. |

## Annotated Repository Tree

```text
SkateTrack/
├── .gitignore                                      # [工程設定] Ignored files for Xcode, SwiftPM, build output, logs, env files, and macOS metadata.
├── .swiftlint.yml                                  # [工程設定] SwiftLint configuration; file length warning at 450 lines and error at 500 lines.
├── README.md                                       # [協作區] Project overview, setup notes, and current development status.
├── SkateTrack.xcworkspace/                         # [工程設定] Root Xcode workspace used to open the project.
│   └── contents.xcworkspacedata                    # [工程設定] Workspace reference to `SkateTrack.xcodeproj`.
├── SkateTrack.xcodeproj/                           # [工程設定] Xcode project containing iOS, watchOS, and macOS targets.
│   ├── project.pbxproj                             # [工程設定] Target definitions, source membership, resources, build settings, and watchOS shell settings.
│   ├── project.xcworkspace/                        # [工程設定] Xcode-generated project workspace metadata.
│   │   └── contents.xcworkspacedata                # [工程設定] Internal project workspace descriptor.
│   └── xcshareddata/
│       └── xcschemes/
│           ├── SkateTrack-iOS.xcscheme             # [工程設定] Shared iOS build/run scheme.
│           ├── SkateTrack-watchOS.xcscheme         # [工程設定] Shared watchOS build/run scheme.
│           └── SkateTrack-macOS.xcscheme           # [工程設定] Shared macOS build/run scheme.
├── Shared/                                         # [協作區] Cross-platform code shared by iOS, watchOS, and macOS targets.
│   ├── Constants/                                  # [協作區] Global constants and shared feature identifiers.
│   │   ├── .gitkeep                                # [佔位] Keeps the constants directory committed when empty in early scaffolding.
│   │   ├── AppConstants.swift                      # [協作區] App-wide names, bundle identifier prefix, and deployment baselines.
│   │   └── FeatureFlags.swift                      # [協作區] Phase 1a gated feature enum and free feature enum.
│   ├── Localization/                               # [原則 A] App-wide localization resources.
│   │   ├── .gitkeep                                # [佔位] Keeps the localization root directory committed.
│   │   ├── en.lproj/
│   │   │   └── Localizable.strings                 # [原則 A] English base strings for app shell, sport modes, units, debug subscription UI, and gated feature names.
│   │   └── zh-Hant.lproj/
│   │       └── Localizable.strings                 # [原則 A] Traditional Chinese strings matching the English key set.
│   ├── Models/                                     # [協作區] Cross-platform Codable + Sendable domain models.
│   │   ├── .gitkeep                                # [佔位] Keeps the models directory committed.
│   │   ├── EquipmentProfile.swift                  # [協作區] Equipment identity, sport mode, power type, mileage, wheel details, and notes.
│   │   ├── FallEvent.swift                         # [協作區] Fall timeline event with impact G-force, location, recovery duration, sport mode, and confirmation status.
│   │   ├── MotionSample.swift                      # [協作區] GPS, speed, accelerometer, gyroscope, altitude, and accuracy sample types.
│   │   ├── PowerType.swift                         # [協作區] Human-powered / electric power type plus skateboard-only electric validation.
│   │   ├── SessionData.swift                       # [協作區] Root session container for sport mode, power, samples, tricks, falls, equipment, and spot links.
│   │   ├── SportMode.swift                         # [協作區] BoardMode, InlineMode, and unified SportMode enum for skateboard and inline skating.
│   │   ├── SpotProfile.swift                       # [協作區] Saved riding spot with coordinates, surface rating, photos, visit data, and preferred modes.
│   │   └── TrickEvent.swift                        # [協作區] Trick timeline event with type, confidence, air height, and landing quality.
│   ├── Protocols/                                  # [協作區] Cross-platform provider boundaries.
│   │   ├── .gitkeep                                # [佔位] Keeps the protocols directory committed.
│   │   ├── SensorProvider.swift                    # [協作區] Motion sample stream plus start / stop recording contract.
│   │   └── SyncProvider.swift                      # [協作區] Upload, fetch, and delete session sync contract.
│   └── Utilities/                                  # [協作區] Shared formatting and locale-sensitive helpers.
│       ├── NumberFormatter+SkateTrack.swift        # [協作區] App-wide number formatter presets.
│       └── UnitFormatter.swift                     # [協作區] Distance, temperature, and pace formatting through Foundation formatter APIs.
├── iOS/                                            # iOS app source tree.
│   ├── App/                                        # [協作區] iOS app entry and root shell.
│   │   ├── .gitkeep                                # [佔位] Keeps the iOS app directory committed.
│   │   └── SkateTrackApp.swift                     # [協作區] iOS app entry with localized placeholder shell and DEBUG subscription toggle.
│   ├── Core/                                       # [自主區] iOS implementation engines and data processing internals.
│   │   ├── DataPipeline/                           # [自主區] Placeholder for session/sensor data pipeline tasks.
│   │   │   └── .gitkeep                            # [佔位] Keeps the data pipeline directory committed.
│   │   ├── MLEngine/                               # [自主區] Placeholder for future Core ML inference engines.
│   │   │   └── .gitkeep                            # [佔位] Keeps the ML engine directory committed.
│   │   ├── SensorEngine/                           # [自主區] Placeholder for GPS, IMU, barometer, fusion, and fall detection tasks.
│   │   │   └── .gitkeep                            # [佔位] Keeps the sensor engine directory committed.
│   │   └── Subscription/                           # [自主區] Subscription and access-control internals.
│   │       └── FeatureFlagEngine.swift             # [自主區] Single source of truth for subscription access checks with DEBUG override support.
│   ├── Features/                                   # [協作區] iOS feature modules; real UI screens are implemented in later tasks.
│   │   ├── EquipmentManager/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for equipment management UI and logic.
│   │   ├── FallDetection/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for fall detection user-facing flow.
│   │   ├── HealthReminders/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for hydration, rest, stretch, and heat reminder UI.
│   │   ├── RouteMap/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for route map and mini-map UI.
│   │   ├── SessionRecording/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for GPS session recording UI.
│   │   ├── Social/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for session share cards and social export.
│   │   ├── SpotManagement/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for saved spot and weather suitability UI.
│   │   ├── TrickRecognition/
│   │   │   └── .gitkeep                            # [佔位] Placeholder for trick recognition UI and later ML integration.
│   │   └── Tutorials/
│   │       └── .gitkeep                            # [佔位] Placeholder for tutorial browsing and bookmarks.
│   └── Hooks/                                      # [協作區] UI-to-Core boundary adapters.
│       ├── .gitkeep                                # [佔位] Keeps the hooks directory committed.
│       └── useSubscriptionStatus.swift             # [協作區 — 邊界適配層] SwiftUI-facing subscription state and access-check adapter.
├── watchOS/                                        # watchOS app source tree.
│   ├── App/                                        # [協作區] watchOS app entry and root shell.
│   │   ├── .gitkeep                                # [佔位] Keeps the watchOS app directory committed.
│   │   └── SkateTrackWatchApp.swift                # [協作區] watchOS app entry with localized placeholder shell.
│   ├── Core/                                       # [自主區] Placeholder for future watch sensor and connectivity internals.
│   │   └── .gitkeep                                # [佔位] Keeps the watchOS core directory committed.
│   └── Features/                                   # [協作區] Placeholder for future watchOS screens and controls.
│       └── .gitkeep                                # [佔位] Keeps the watchOS features directory committed.
├── macOS/                                          # macOS app source tree.
│   ├── App/                                        # [協作區] macOS app entry and root shell.
│   │   ├── .gitkeep                                # [佔位] Keeps the macOS app directory committed.
│   │   └── SkateTrackMacApp.swift                  # [協作區] macOS app entry with localized placeholder shell.
│   ├── Core/                                       # [自主區] Placeholder for future macOS processing internals.
│   │   └── .gitkeep                                # [佔位] Keeps the macOS core directory committed.
│   └── Features/                                   # [協作區] macOS feature placeholders for Phase 2+.
│       ├── AIAnalysis/
│       │   └── .gitkeep                            # [佔位] Placeholder for AI analysis workspace.
│       ├── DataVisualization/
│       │   └── .gitkeep                            # [佔位] Placeholder for charts and ride analytics.
│       ├── SessionBrowser/
│       │   └── .gitkeep                            # [佔位] Placeholder for macOS session browser.
│       ├── TrainingPlan/
│       │   └── .gitkeep                            # [佔位] Placeholder for training plan UI.
│       ├── Tutorials/
│       │   └── .gitkeep                            # [佔位] Placeholder for macOS tutorial browsing.
│       └── VideoOverlay/
│           └── .gitkeep                            # [佔位] Placeholder for Phase 2 video overlay editor.
├── Tests/                                          # Test target placeholders.
│   ├── iOSTests/
│   │   └── .gitkeep                                # [佔位] Placeholder for future iOS tests.
│   ├── watchOSTests/
│   │   └── .gitkeep                                # [佔位] Placeholder for future watchOS tests.
│   └── macOSTests/
│       └── .gitkeep                                # [佔位] Placeholder for future macOS tests.
├── docs/                                           # [原則 E] Living documentation and architecture decisions.
│   ├── DEV_LOG.md                                  # [原則 E] Append-only development history and decision log.
│   ├── FILE_STRUCTURE.md                           # [原則 E] Annotated source-controlled repository tree.
│   └── decisions/
│       └── .gitkeep                                # [佔位] Placeholder for future ADR files.
├── scripts/                                        # [工程設定] Local verification and helper scripts.
│   ├── .gitkeep                                    # [佔位] Keeps the scripts directory committed.
│   ├── set_github_remote.sh                        # [工程設定] Helper to set GitHub origin remote after repo creation.
│   ├── verify_feature_flags.py                     # [工程設定] Validates Task-004 gated feature enum, engine, hook, and localization keys.
│   ├── verify_localization_keys.py                 # [工程設定] Validates English and Traditional Chinese localization key parity.
│   └── verify_shared_models.py                     # [工程設定] Validates Task-003 required shared files, zone headers, line counts, and forbidden UI imports.
└── tasks/                                          # [任務文件] Cursor / agent task prompt packs and acceptance checklists.
    ├── .gitkeep                                    # [佔位] Keeps the tasks directory committed.
    ├── Task-002-Localization/
    │   ├── acceptance.md                           # [任務文件] Task-002 acceptance checklist.
    │   ├── context.md                              # [任務文件] Task-002 context and source references.
    │   ├── files_expected.md                       # [任務文件] Task-002 expected file list.
    │   └── prompt.md                               # [任務文件] Task-002 agent prompt.
    ├── Task-003-SharedDataModels/
    │   ├── acceptance.md                           # [任務文件] Task-003 acceptance checklist.
    │   ├── context.md                              # [任務文件] Task-003 context and source references.
    │   ├── files_expected.md                       # [任務文件] Task-003 expected file list.
    │   └── prompt.md                               # [任務文件] Task-003 agent prompt.
    └── Task-004-FeatureFlags/
        ├── acceptance.md                           # [任務文件] Task-004 acceptance checklist.
        ├── context.md                              # [任務文件] Task-004 context and source references.
        ├── files_expected.md                       # [任務文件] Task-004 expected file list.
        └── prompt.md                               # [任務文件] Task-004 agent prompt.
```

## Current Phase 0 Status

- Task-001 scaffold is complete.
- Task-002 localization infrastructure is complete.
- Task-003 shared data models are complete.
- Task-004 feature flag system is complete.
- Task-005 living documentation initialization is complete with this file and `docs/DEV_LOG.md`.

## History

### 2026-06-09 — Task-005 Living Documentation Initialization

- Rewrote this document as the full annotated source-controlled tree after Tasks 001–004.
- Added one-line purpose annotations and zone labels for every listed file.
- Confirmed ignored/transient files are excluded from the living source tree.

### 2026-06-09 — Task-004 Feature Flag System

- Added `Shared/Constants/FeatureFlags.swift`, `iOS/Core/Subscription/FeatureFlagEngine.swift`, `iOS/Hooks/useSubscriptionStatus.swift`, Task-004 localization keys, and `scripts/verify_feature_flags.py`.
- iOS app shell includes a DEBUG-only subscription toggle used only for simulator validation.

### 2026-06-09 — Task-003 Shared Data Models

- Added shared domain models, provider protocols, and `scripts/verify_shared_models.py`.
- Updated the Xcode project so shared files compile on iOS, watchOS, and macOS.

### 2026-06-09 — Task-002 Localization Infrastructure

- Added English and Traditional Chinese localization files plus shared unit and number formatting utilities.
- Added localized placeholder shells to iOS, watchOS, and macOS app entries.

### 2026-06-09 — Task-001 Project Scaffold

- Created the Xcode workspace, Xcode project, platform app entries, baseline folder structure, SwiftLint config, README, and initial docs.

No deprecated structure entries yet.
