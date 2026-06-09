# Task-003 Agent Prompt — Shared Data Models

You are implementing SkateTrack Build Plan Task-003.

Use Build Plan v1.0 as the source of truth and DevProcess v1.0 as the engineering rule set.

Create shared cross-platform data models and protocols only. Do not implement UI, storage, sensor collection, sync engines, or feature gates.

Required files:

```text
Shared/Models/SessionData.swift
Shared/Models/SportMode.swift
Shared/Models/PowerType.swift
Shared/Models/MotionSample.swift
Shared/Models/TrickEvent.swift
Shared/Models/FallEvent.swift
Shared/Models/EquipmentProfile.swift
Shared/Models/SpotProfile.swift
Shared/Protocols/SensorProvider.swift
Shared/Protocols/SyncProvider.swift
```

Rules:

1. Every file starts with a collaboration-zone header.
2. Models conform to `Codable` and `Sendable`.
3. Stored entity models conform to `Identifiable` with `UUID` ids.
4. `SportMode` is a unified enum: `.skateboard(BoardMode)` and `.inline(InlineMode)`.
5. `PowerType.electric` is only valid for skateboard sport modes.
6. Do not import `SwiftUI`, `UIKit`, `AppKit`, or `WatchKit` in shared models or protocols.
7. Add the new shared files to all three Xcode targets: iOS, watchOS, and macOS.
8. Update `docs/FILE_STRUCTURE.md` and `docs/DEV_LOG.md`.
9. Keep every Swift file under 500 lines.

Validation commands:

```bash
python3 scripts/verify_shared_models.py
python3 scripts/verify_localization_keys.py
```

Manual validation:

Build the iOS, watchOS, and macOS targets in Xcode. The visible UI should remain the Task-002 localized placeholder.
