# ADR — WatchBridge Contract Placement

Status: Accepted for Task-032a planning / no product behavior implementation

Aligned Build Plan: `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md`

Aligned subtask: `Task-032a — WatchBridge Source Audit + Contract Placement`

## Context

Task-032a audits the current repository before WatchBridge models are added. The source pack confirms the current `develop` baseline is `891d460f8e221c50729201880102d554b01127ad`, `Shared/WatchBridge` is absent, no runtime `WatchConnectivity` layer exists in guarded source paths, and watchOS currently has one Swift app entry file. Task-032a is intentionally docs/source-audit/verifier only.

## Decision

```text
CONTRACT_PLACEMENT_DECIDED=YES
WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge
WATCHBRIDGE_CONTRACT_CREATION_TASK=Task-032b
WATCHBRIDGE_RUNTIME_CREATION_TASK=Task-033a
DUPLICATE_WATCHBRIDGE_LAYER_COUNT=0
WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO
WATCH_UI_IMPLEMENTED=NO
```

Future WatchBridge contract files should live under `Shared/WatchBridge/`. Task-032a does not create those Swift model files; it records the placement decision so Task-032b can add the smallest versioned envelope and tests without rediscovering the namespace.

## Planned file split

Task-032b and later Task-032 slices should use a small, typed split rather than a single large bridge file:

```text
Shared/WatchBridge/WatchBridgeEnvelope.swift
Shared/WatchBridge/WatchBridgePayloads.swift
Shared/WatchBridge/WatchBridgeConnectionState.swift
Shared/WatchBridge/WatchBridgeCommandModels.swift
```

The split is a plan, not a Task-032a implementation. If Task-032b finds a smaller split is enough, it may add fewer files while keeping the namespace and constraints.

## Target membership plan

```text
WATCHBRIDGE_TARGET_MEMBERSHIP_PLAN=IOS_AND_WATCHOS_REQUIRED_MACOS_OPTIONAL_FOR_COMPILE_ONLY_TOOLS
```

The core iPhone ↔ Watch contracts must be source-membered for iOS and watchOS when they are added. macOS membership is optional and should only be added if compile-only tooling, previews, or tests require it. Any new Shared Swift files must pass the standard collaboration/autonomous header rule and the 500-line hard limit.

## Boundaries

Task-032a does not implement:

```text
WatchBridge models
WatchConnectivity runtime behavior
WCSession usage
command mirroring
Watch UI
HealthKit runtime
Snow production behavior
schema/Core Data/package mutation
route geometry mutation
trusted metric mutation
estimated route enablement
```

Task-032b owns the envelope/schema-version implementation. Task-032c owns activity-aware payload models. Task-032d owns simulator-safe connection state and mock transport. Task-033a owns the first real WatchConnectivity boundary shell.
