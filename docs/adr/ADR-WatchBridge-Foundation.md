# ADR — WatchBridge Foundation Boundary

**Status:** Accepted for Phase 1b Task-032e
**Scope:** Task-032 WatchBridge foundation closure
**Aligned Build Plan:** `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md`

## Decision

Task-032 closes the WatchBridge foundation as a shared contract, simulator-safe state, mock transport, tests, and verification layer only.

```text
TASK032_WATCHBRIDGE_FOUNDATION_COMPLETE=YES
WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge
WATCHBRIDGE_CONTRACT_SCHEMA_VERSION=1
WATCHBRIDGE_SWIFT_FILE_COUNT=9
WATCHBRIDGE_TEST_SWIFT_COUNT=2
WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO
WCSESSION_DEPENDENCY_IMPLEMENTED=NO
SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO
WATCH_UI_IMPLEMENTED=NO
HEALTHKIT_RUNTIME_IMPLEMENTED=NO
SNOW_PRODUCTION_IMPLEMENTATION=NO
SCHEMA_OR_CORE_DATA_MUTATION=NO
ROUTE_GEOMETRY_MUTATION=NO
TRUSTED_METRIC_MUTATION=NO
NEXT_TASK=Task-033a
```

## Foundation contents

Task-032 owns:

- Codable WatchBridge envelope, payload, command, activity, metric, and connection state contracts.
- Display-only compact activity payload carriage.
- Simulator-safe connection timeline, connection state store, and mock transport.
- iOS unit tests for connection state and mock transport behavior.
- Aggregate verifier `scripts/verify_task032_watchbridge_foundation.py`.

## Boundary

Task-032 does not implement real WatchConnectivity runtime behavior, `WCSession`, session-control mirroring runtime, Watch UI, HealthKit runtime, Snow production behavior, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, or estimated route enablement.

Task-033a owns the first real WatchConnectivity runtime boundary shell. That future task must treat the Task-032 contracts as input and must not retroactively mix runtime behavior into the foundation closure.
