# SkateTrack File Structure

**Last Updated:** 2026-06-09  
**Source of Truth:** DevProcess v1.0 Principle E  
**Task:** Task-002 — Localization Infrastructure

This document records the current repository structure after Task-002. It must be updated whenever three or more files are added or changed, or when a phase is completed.

```text
SkateTrack/
├── SkateTrack.xcworkspace/                 # Xcode workspace containing the project
│   └── contents.xcworkspacedata             # Workspace file reference to SkateTrack.xcodeproj
├── SkateTrack.xcodeproj/                    # Xcode project containing iOS, watchOS, macOS targets
│   ├── project.pbxproj                      # Target, build setting, resources, and SPM package configuration
│   └── xcshareddata/xcschemes/              # Shared build schemes
├── Shared/                                  # [協作區] Shared models, protocols, localization, constants, utilities
│   ├── Constants/
│   │   └── AppConstants.swift               # [協作區] App-wide constants and deployment baselines
│   ├── Models/                              # [協作區] Placeholder for Task-003 shared models
│   ├── Protocols/                           # [協作區] Placeholder for Task-003 / Task-004 protocols
│   ├── Localization/                        # [原則 A] App-wide localization resources
│   │   ├── en.lproj/
│   │   │   └── Localizable.strings          # English base strings
│   │   └── zh-Hant.lproj/
│   │       └── Localizable.strings          # Traditional Chinese strings
│   └── Utilities/                           # [協作區] Shared formatting utilities
│       ├── UnitFormatter.swift              # Distance, temperature, and pace formatting
│       └── NumberFormatter+SkateTrack.swift # App-wide number formatter presets
├── iOS/
│   ├── App/
│   │   └── SkateTrackApp.swift              # [協作區] iOS app entry with localized placeholder shell
│   ├── Features/                            # [協作區] iOS feature modules
│   │   ├── SessionRecording/                # Placeholder for Task-011+
│   │   ├── FallDetection/                   # Placeholder for Task-010 integration
│   │   ├── HealthReminders/                 # Placeholder for Task-021
│   │   ├── TrickRecognition/                # Placeholder for later recognition tasks
│   │   ├── RouteMap/                        # Placeholder for Task-020
│   │   ├── SpotManagement/                  # Placeholder for Task-024
│   │   ├── EquipmentManager/                # Placeholder for Task-023
│   │   ├── Tutorials/                       # Placeholder for tutorial features
│   │   └── Social/                          # Placeholder for later social features
│   ├── Core/                                # [自主區] iOS performance-critical engines
│   │   ├── SensorEngine/                    # Placeholder for Task-006 through Task-010
│   │   ├── MLEngine/                        # Placeholder for later ML inference
│   │   └── DataPipeline/                    # Placeholder for sensor/session pipelines
│   └── Hooks/                               # [協作區] UI-to-Core boundary adapters
├── watchOS/
│   ├── App/
│   │   └── SkateTrackWatchApp.swift         # [協作區] watchOS app entry with localized placeholder shell
│   ├── Features/                            # [協作區] watchOS feature placeholders
│   └── Core/                                # [自主區] watchOS core placeholders
├── macOS/
│   ├── App/
│   │   └── SkateTrackMacApp.swift           # [協作區] macOS app shell entry with localized placeholder shell
│   ├── Features/                            # [協作區] macOS feature modules
│   │   ├── SessionBrowser/                  # Placeholder for macOS session browser
│   │   ├── DataVisualization/               # Placeholder for charts and analysis views
│   │   ├── VideoOverlay/                    # Placeholder for video overlay editor
│   │   ├── AIAnalysis/                      # Placeholder for AI analysis view
│   │   ├── TrainingPlan/                    # Placeholder for training plan view
│   │   └── Tutorials/                       # Placeholder for macOS tutorial browser
│   └── Core/                                # [自主區] macOS core placeholders
├── Tests/
│   ├── iOSTests/                            # Placeholder for iOS unit tests
│   ├── watchOSTests/                        # Placeholder for watchOS unit tests
│   └── macOSTests/                          # Placeholder for macOS unit tests
├── docs/                                    # [原則 E] Live project documentation
│   ├── FILE_STRUCTURE.md                    # Current file tree and file purpose map
│   ├── DEV_LOG.md                           # Append-only development log
│   └── decisions/                           # Placeholder for architecture decision records
├── tasks/                                   # Per-task prompt packs
│   └── Task-002-Localization/
│       ├── prompt.md                        # Cursor / agent prompt for Task-002
│       ├── context.md                       # Task references from Build Plan, PRD, DevProcess, UI scope
│       ├── acceptance.md                    # Task-002 acceptance checklist
│       └── files_expected.md                # Files created or modified by Task-002
├── scripts/
│   ├── set_github_remote.sh                 # Helper to attach real GitHub origin after repo creation
│   └── verify_localization_keys.py          # Local check that both language files contain identical keys
├── .swiftlint.yml                           # SwiftLint rules, including file_length 450 / 500
├── .gitignore                               # Standard Swift / Xcode ignore rules
└── README.md                                # Project overview and setup notes
```

## History

### 2026-06-09 — Task-002 Localization Infrastructure

- Added English and Traditional Chinese `Localizable.strings` files.
- Added shared unit and number formatting utilities.
- Added localized placeholder shells to iOS, watchOS, and macOS app entry points so simulator locale switching can be verified immediately.
- Added Task-002 prompt pack under `tasks/Task-002-Localization/`.
- Added a local script for localization key parity checks.

No deprecated structure entries yet.
