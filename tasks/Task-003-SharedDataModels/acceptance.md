# Task-003 Acceptance Checklist

- [x] `Shared/Models/SessionData.swift` exists and is a collaboration-zone file.
- [x] `Shared/Models/SportMode.swift` exists and defines `BoardMode`, `InlineMode`, and unified `SportMode`.
- [x] `Shared/Models/PowerType.swift` exists and validates electric power as skateboard-only.
- [x] `Shared/Models/MotionSample.swift` exists and defines sensor sample value types.
- [x] `Shared/Models/TrickEvent.swift` exists.
- [x] `Shared/Models/FallEvent.swift` exists.
- [x] `Shared/Models/EquipmentProfile.swift` exists.
- [x] `Shared/Models/SpotProfile.swift` exists.
- [x] `Shared/Protocols/SensorProvider.swift` exists.
- [x] `Shared/Protocols/SyncProvider.swift` exists.
- [x] Shared model and protocol files have zone headers on line 1.
- [x] No shared model/protocol file imports UI frameworks.
- [x] No Swift source file exceeds 500 lines.
- [x] New shared files are added to iOS, watchOS, and macOS source phases in the Xcode project.
- [x] Local verification script exists: `scripts/verify_shared_models.py`.

## Manual Xcode Validation Required

Because this task changes Xcode project file membership, run all three app targets locally:

1. `SkateTrack-iOS`
2. `SkateTrack-watchOS`
3. `SkateTrack-macOS`

The expected UI is unchanged from Task-002. The important result is successful compilation.
