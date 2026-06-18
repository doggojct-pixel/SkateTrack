# Snow-Task-006b Wiring Plan

Version: EN v1.0  
Branch: `feature/snow-mode`  
Base commit at preparation time: `b975c43 Finalize Snow Mode Phase 1c handoff and completion checks`  
Document status: Pre-Task-040 implementation specification  
Scope: Documentation only. This file does not authorize Swift implementation before mainline Watch Integration reaches its final shape.

## 1. Purpose

Snow-Task-006a intentionally delivered a mock-backed, production-safe Watch Snow UI data boundary. It did **not** connect the Watch Snow UI to real iPhone Snow session data. That real-data integration is Snow-Task-006b and remains deferred until mainline `develop` reaches Task-040 or later, where the shared WatchBridge / WatchConnectivity transport is expected to be finalized.

This document pre-defines the implementation contract for Snow-Task-006b so that, after mainline Task-040 is merged into `feature/snow-mode`, the work can proceed as an adapter-focused task instead of a new design discussion.

## 2. Absolute prerequisites checklist

Before starting Snow-Task-006b implementation, confirm all of the following:

```text
□ The active working branch is feature/snow-mode.
□ Mainline develop has reached Task-040 or later.
□ The Task-040 WatchBridge / WatchConnectivity implementation has been merged into feature/snow-mode.
□ The merged branch builds for iOS and watchOS before any Snow-Task-006b changes.
□ Shared/WatchBridge/WatchMessageTypes.swift exists, or the Task-040 equivalent file is clearly identified.
□ MetricUpdateMessage, or the Task-040 equivalent metric payload type, is finalized enough to extend safely.
□ WatchSessionCoordinator.swift, or the Task-040 equivalent transport coordinator, is finalized enough to publish / receive metric messages.
□ Shared/Models/WatchSnowSessionSnapshot.swift still exists and retains the Snow-Task-006a field contract.
□ verify_snow_watch_ui.py still passes immediately after the merge.
□ All cumulative Snow verify scripts still pass immediately after the merge.
```

Do not start 006b if these prerequisites are not true. Do not use Snow-Task-006b to redesign WatchBridge itself.

## 3. Existing Snow-Task-006a data contract

`WatchSnowSessionSnapshot` is the stable Watch Snow UI data contract created by Snow-Task-006a. It currently contains the following fields:

```swift
struct WatchSnowSessionSnapshot: Codable, Equatable, Sendable {
    var currentSpeedKmh: Double
    var maxSpeedThisRunKmh: Double

    var snowRunNumber: Int?
    var snowVerticalDropMeters: Double?
    var snowTotalVerticalMeters: Double?
    var snowSlopeAngleDegrees: Double?
    var snowSegmentType: String?
    var snowSchemaVersion: String?

    var totalRunsToday: Int
    var totalSkiDistanceMeters: Double
    var totalLiftDistanceMeters: Double
    var averageRunDurationSeconds: Double?

    var lastRunVerticalDropMeters: Double?
    var lastRunTopSpeedKmh: Double?
    var lastRunDurationSeconds: Double?

    var heartRateBpm: Int?
    var fallAlertActive: Bool
    var fallAlertPeakGForce: Double?
    var isSubscriber: Bool
}
```

Snow-Task-006b must preserve this contract. It must map real WatchBridge data into this snapshot. It must not require changes to the Watch Snow view files.

## 4. Intended mapping from iPhone Snow session state to WatchSnowSessionSnapshot

The following mapping describes the intended adapter behavior. Field names on the WatchBridge message side are proposed names only. If Task-040 uses different names, reconcile the naming inside the 006b adapter, not by changing Watch Snow view files.

| `WatchSnowSessionSnapshot` field | Intended WatchBridge source | iPhone-side source / derivation | Notes |
|---|---|---|---|
| `currentSpeedKmh` | Existing `MetricUpdateMessage.currentSpeedKmh`, or equivalent | Live recording metric from `SessionRecordingCoordinator` / active metric publisher | Existing non-Snow metric. |
| `maxSpeedThisRunKmh` | `MetricUpdateMessage.snowMaxSpeedThisRunKmh` | Current active `SnowRun` / run-boundary accumulator | Optional in transport, default to 0 if absent. |
| `snowRunNumber` | `MetricUpdateMessage.snowRunNumber` | `RunBoundarySnapshot.currentRunNumber` or derived from active run index | Optional. Nil for old messages. |
| `snowVerticalDropMeters` | `MetricUpdateMessage.snowVerticalDropMeters` | `RunBoundarySnapshot.currentRunVerticalDropMeters` | Current run drop, not total session drop. |
| `snowTotalVerticalMeters` | `MetricUpdateMessage.snowTotalVerticalMeters` | `SnowSessionState.verticalMetrics.totalVerticalDropMeters` | Session-level accumulated downhill vertical. |
| `snowSlopeAngleDegrees` | `MetricUpdateMessage.snowSlopeAngleDegrees` | Nil in v0 unless a reliable slope estimator exists | Do not fake slope angle from noisy altitude data. |
| `snowSegmentType` | `MetricUpdateMessage.snowSegmentType` | `RunBoundarySnapshot.currentSegmentType.rawValue` or latest classifier segment type | Raw string for transport stability. |
| `snowSchemaVersion` | `MetricUpdateMessage.snowSchemaVersion` | Fixed value `"1.1"` | Version negotiation field. |
| `totalRunsToday` | `MetricUpdateMessage.snowRunCount` | `SnowSessionState.runs.count` | If transport lacks this field, adapter may derive locally from received state if available. |
| `totalSkiDistanceMeters` | `MetricUpdateMessage.snowTotalSkiDistanceMeters` | `SnowSessionState.distanceBreakdown.skiDistanceMeters` | Must exclude lift / gondola distance. |
| `totalLiftDistanceMeters` | `MetricUpdateMessage.snowTotalLiftDistanceMeters` | `SnowSessionState.distanceBreakdown.liftDistanceMeters` | Includes lift-like ascent distance only. |
| `averageRunDurationSeconds` | `MetricUpdateMessage.snowAverageRunDurationSeconds` | Average duration across completed `SnowRun` entries | Nil if no completed runs. |
| `lastRunVerticalDropMeters` | `MetricUpdateMessage.snowLastRunVerticalDropMeters` | Most recent completed run vertical drop | Nil until at least one run completes. |
| `lastRunTopSpeedKmh` | `MetricUpdateMessage.snowLastRunTopSpeedKmh` | Most recent completed run top speed | Nil until at least one run completes. |
| `lastRunDurationSeconds` | `MetricUpdateMessage.snowLastRunDurationSeconds` | Most recent completed run duration | Nil until at least one run completes. |
| `heartRateBpm` | Existing or future heart-rate metric | Nil before real Health / Watch sensor integration is authorized | 006b must not implement HealthKit production export. |
| `fallAlertActive` | Existing fall-alert metric or false default | Existing fall-detection boundary if available | Default false for old messages. |
| `fallAlertPeakGForce` | Existing fall-alert peak-G metric | Existing fall-detection boundary if available | Nil when absent. |
| `isSubscriber` | Existing entitlement metric | Existing subscription / entitlement boundary if available | Preserve current entitlement strategy. |

### Version string normalization note

The intended Snow watch payload version is the simple string:

```swift
"1.1"
```

No whitespace-padded, localized, or display-formatted value should be used for transport version negotiation.

## 5. New file to create in Snow-Task-006b

```text
watchOS/Core/Snow/WatchBridgeSnowSessionProvider.swift
```

Required responsibilities:

```text
- Conform to WatchSnowSessionDataSource.
- Subscribe to the real Task-040 WatchSessionCoordinator / message stream.
- Map MetricUpdateMessage, or its Task-040 equivalent, into WatchSnowSessionSnapshot.
- Handle messages with no Snow extension fields gracefully.
- Treat snowSchemaVersion == nil as an old-version / non-Snow message.
- Populate base metrics where possible and leave Snow-only fields nil or zero-safe.
- Forward user intents such as markManeuver(), startRun(), endRun(), pause(), and resume() through the real WatchBridge command channel when Task-040 provides one.
- Avoid changing Watch Snow UI views.
```

Expected behavior for old messages:

```swift
// Pseudocode only
if message.snowSchemaVersion == nil {
    return WatchSnowSessionSnapshot(
        currentSpeedKmh: message.currentSpeedKmh,
        maxSpeedThisRunKmh: 0,
        snowRunNumber: nil,
        snowVerticalDropMeters: nil,
        snowTotalVerticalMeters: nil,
        snowSlopeAngleDegrees: nil,
        snowSegmentType: nil,
        snowSchemaVersion: nil,
        totalRunsToday: 0,
        totalSkiDistanceMeters: 0,
        totalLiftDistanceMeters: 0,
        averageRunDurationSeconds: nil,
        lastRunVerticalDropMeters: nil,
        lastRunTopSpeedKmh: nil,
        lastRunDurationSeconds: nil,
        heartRateBpm: message.heartRateBpm,
        fallAlertActive: message.fallAlertActive ?? false,
        fallAlertPeakGForce: message.fallAlertPeakGForce,
        isSubscriber: message.isSubscriber ?? false
    )
}
```

## 6. Existing files expected to change in Snow-Task-006b

The exact files may differ after Task-040. Use the real Task-040 file names if they differ.

```text
Shared/WatchBridge/WatchMessageTypes.swift
```

Expected changes:

```text
- Extend MetricUpdateMessage with optional Snow fields.
- Add snowSchemaVersion: String? = nil.
- Keep every Snow extension field optional: Int?, Double?, String?, Bool?.
- Do not make old message JSON fail to decode.
```

```text
Shared/WatchBridge/WatchSessionCoordinator.swift
```

Expected changes:

```text
- When active sport is .snow(_), publish Snow extension fields in MetricUpdateMessage.
- Populate values from SnowLiveSessionCoordinator / RunBoundarySnapshot / SnowSessionState.
- Preserve existing skateboard and inline publishing behavior unchanged.
```

```text
watchOS/App/SkateTrackWatchApp.swift
```

Expected changes:

```text
- In Release builds, inject WatchBridgeSnowSessionProvider once the real WatchBridge is available.
- In DEBUG builds, preserve MockSnowSessionProvider for local preview / simulator testing.
- Keep WatchSnowUnavailableView as the safe fallback when no provider can be constructed.
```

```text
scripts/verify_snow_watch_ui.py
```

Expected changes:

```text
- Require WatchBridgeSnowSessionProvider.swift.
- Require conformance to WatchSnowSessionDataSource.
- Require MetricUpdateMessage snowSchemaVersion support or the Task-040 equivalent.
- Require MockSnowSessionProvider remains DEBUG-gated.
- Reject HealthKit imports in watchOS/Core/Snow.
- Reject SnowPrototype* namespace usage.
```

## 7. Backward compatibility rules

Snow-Task-006b must be safe across mixed iPhone / Watch versions.

```text
- All new Snow fields in the WatchBridge message must be optional.
- New Watch app receiving old iPhone messages without Snow fields must not crash.
- Old Watch app receiving new iPhone messages with Snow fields must ignore unknown fields safely.
- JSON / Codable decode of old MetricUpdateMessage payloads must continue to work.
- snowSchemaVersion == nil means old message or non-Snow message, not error.
- No existing Watch Snow view should assume non-nil Snow fields.
```

Required unit tests after implementation:

```text
- Old MetricUpdateMessage JSON without Snow fields decodes successfully.
- Mapping old message -> WatchSnowSessionSnapshot leaves snowRunNumber nil.
- Mapping Snow message with schema version 1.1 populates Snow fields.
- DEBUG MockSnowSessionProvider still works.
- Release provider construction does not require DEBUG mock types.
```

## 8. Scope boundaries

Snow-Task-006b is adapter / transport wiring only.

Must not change:

```text
- WatchSnow*.swift view files, unless only unavoidable compiler fixes are needed.
- SnowSegmentClassifier.swift.
- SnowClassifierConfig.swift.
- RunBoundaryDetector.swift.
- RunBoundaryConfig.swift.
- SnowRun.swift / SnowSegment.swift / SnowSessionState.swift.
- Package or backup schema files.
- HealthKit export boundary.
- MotionSample schema.
- macOS Snow viewer.
```

Must not add:

```text
- Production HealthKit code.
- New SnowPrototype* namespace.
- New .skatetrack fixtures.
- New package or backup schema version.
```

## 9. Completion criteria

Snow-Task-006b is complete only if:

```text
□ WatchBridgeSnowSessionProvider conforms to WatchSnowSessionDataSource.
□ Watch Snow UI receives real iPhone Snow metrics on a paired device or paired simulator when available.
□ Lift / gondola / run state propagates from iPhone SnowLiveSessionCoordinator into Watch Snow presentation state.
□ Old MetricUpdateMessage payloads without Snow fields do not crash the Watch app.
□ MockSnowSessionProvider remains present and DEBUG-gated.
□ verify_snow_watch_ui.py is updated and passing.
□ All cumulative Snow verify scripts pass.
□ iOS, watchOS, and macOS builds succeed.
□ No Watch Snow view files are redesigned.
□ No classifier, run-boundary, package, backup, or HealthKit production scope creep is introduced.
```

## 10. Recommended commit name

```text
Wire Snow WatchBridge session provider
```

Do not use this commit name for this planning document. This document-only preparation should be committed separately before Task-040 as:

```text
Add Snow pre-Task-040 preparation documents
```
