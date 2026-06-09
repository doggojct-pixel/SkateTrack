# Task-003 Files Expected

## New Files

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
scripts/verify_shared_models.py
tasks/Task-003-SharedDataModels/context.md
tasks/Task-003-SharedDataModels/acceptance.md
tasks/Task-003-SharedDataModels/files_expected.md
tasks/Task-003-SharedDataModels/prompt.md
```

## Modified Files

```text
SkateTrack.xcodeproj/project.pbxproj
docs/FILE_STRUCTURE.md
docs/DEV_LOG.md
```

## Intentionally Unchanged

```text
iOS/App/SkateTrackApp.swift
watchOS/App/SkateTrackWatchApp.swift
macOS/App/SkateTrackMacApp.swift
Shared/Localization/en.lproj/Localizable.strings
Shared/Localization/zh-Hant.lproj/Localizable.strings
```

Task-003 is a data-layer task. The visible simulator screen should remain the Task-002 localized placeholder.
