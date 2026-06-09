# Task-003 Context — Shared Data Models

## Primary Source
- Build Plan v1.0: Task-003 — Shared Data Models

## Supporting Sources
- DevProcess v1.0 §3.3 Shared Data Models
- DevProcess v1.0 §3.4 Protocol Definitions
- PRD v1.2 sections on sport modes, power type, session recording, fall detection, equipment management, spot management, sync, and macOS analysis
- UI files are not directly implemented in this task because Task-003 is data-layer only

## Scope Decision
Task-003 defines foundational types only. It must not add UI, persistence, GPS recording, sensor fusion, subscription gating, CloudKit, Google Drive, or analytics implementation.

## Important Constraints
- Build Plan is the task source of truth.
- DevProcess is used as the implementation-quality rule set.
- Every file in `Shared/Models/` and `Shared/Protocols/` is a collaboration-zone file.
- Models use `Codable` and `Sendable`.
- Data containers that represent stored entities use `Identifiable` with `UUID` ids.
- No `SwiftUI`, `UIKit`, `AppKit`, or `WatchKit` imports are allowed in shared model/protocol files.
- `PowerType.electric` is valid only for `.skateboard(_)` sport modes.
