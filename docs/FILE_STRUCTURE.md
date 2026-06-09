# SkateTrack File Structure

**Last Updated:** 2026-06-09  
**Source of Truth:** DevProcess v1.0 Principle E  
**Task:** Task-001 — Project Scaffold + Git Setup

This document records the current repository structure after Task-001. It must be updated whenever three or more files are added or changed, or when a phase is completed.

```text
SkateTrack/
├── SkateTrack.xcworkspace/                 # Xcode workspace containing the project
│   └── contents.xcworkspacedata             # Workspace file reference to SkateTrack.xcodeproj
├── SkateTrack.xcodeproj/                    # Xcode project containing iOS, watchOS, macOS targets
│   ├── project.pbxproj                      # Target, build setting, and SPM package configuration
│   └── xcshareddata/xcschemes/              # Shared build schemes
├── Shared/                                  # [協作區] Shared models, protocols, localization, constants
│   ├── Constants/
│   │   └── AppConstants.swift               # [協作區] App-wide constants and deployment baselines
│   ├── Models/                              # [協作區] Placeholder for Task-003 shared models
│   ├── Protocols/                           # [協作區] Placeholder for Task-003 / Task-004 protocols
│   └── Localization/                        # [原則 A] Placeholder for Task-002 localization files
├── iOS/
│   ├── App/
│   │   └── SkateTrackApp.swift              # [協作區] iOS app entry shell
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
│   │   └── SkateTrackWatchApp.swift         # [協作區] watchOS app entry shell
│   ├── Features/                            # [協作區] watchOS feature placeholders
│   └── Core/                                # [自主區] watchOS core placeholders
├── macOS/
│   ├── App/
│   │   └── SkateTrackMacApp.swift           # [協作區] macOS app shell entry
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
├── tasks/                                   # Placeholder for future per-task prompt packs
├── scripts/
│   └── set_github_remote.sh                 # Helper to attach real GitHub origin after repo creation
├── .swiftlint.yml                           # SwiftLint rules, including file_length 450 / 500
├── .gitignore                               # Standard Swift / Xcode ignore rules
└── README.md                                # Project overview and setup notes
```

## History

No deprecated structure entries yet.
