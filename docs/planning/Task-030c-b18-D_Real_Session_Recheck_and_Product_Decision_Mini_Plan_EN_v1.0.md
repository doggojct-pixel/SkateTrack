# Task-030c-b18-D Real-Session Recheck and Product Decision Update Mini Plan EN v1.0

**Project:** SkateTrack  
**Branch:** `task-030c-gps-route-fidelity`  
**Task:** `Task-030c-b18-D`  
**Title:** Real-Session Recheck and Product Decision Update  
**Controlling baseline:** `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`  
**Must remain aligned with:** `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`  
**Previous completed milestone:** `Task-030c-b18-C` — DEBUG-only estimated route review panel  
**Revision:** v1.0  
**Status:** Implementation planning note, not yet implementation

---

## 1. Completed b18-A through b18-C Production Record

This section records the completed b18 implementation history before b18-D begins. It is intentionally placed first so the b18-D implementation remains anchored to the actual production state, not only the abstract plan.

### 1.1 Task-030c-b18-A — Product Decision Gate and In-Memory Estimated Route Display Decision

**Commit:** `93ae35e Task-030c-b18-A add product decision display gate`  
**Status:** Completed and pushed before b18-B.  
**Purpose:** Establish the product-decision gate model for estimated route display without enabling any user-visible display.

b18-A added:

```text
Shared/Models/EstimatedRouteDisplayDecision.swift
iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift
Tests/iOSTests/EstimatedRouteDisplayGateTests.swift
scripts/verify_task030c_b18a_product_decision_gate.py
```

Key implementation details:

- Added `EstimatedRouteDisplayDecisionState` with explicit states:
  - `blocked`
  - `reviewOnly`
  - `candidateButHidden`
  - `eligibleForFutureProductReview`
- Added `EstimatedRouteDisplayDecision` as an in-memory-only decision output.
- Added `EstimatedRouteDisplayGate` and `EstimatedRouteDisplayGatePolicy`.
- Added named policy constants:
  - `maximumCandidateGapDurationSeconds = 6`
  - `maximumReviewOnlyGapDurationSeconds = 30`
  - `maximumCandidateClosureErrorMeters = 8`
  - `maximumCandidateClosureErrorRatio = 0.25`
  - `minimumCandidateIMUSampleCoverageRatio = 0.80`
- Recorded the b18 threshold refinement:
  - very short gaps may become hidden candidates only;
  - gaps up to 30 seconds remain review-only or future product-review evidence;
  - this is intentionally more conservative than the earlier v1.2 candidate threshold because b17-D / b17-D-3 real-session review showed poor eligibility on core sessions.

Safety flags established by b18-A:

```text
inMemoryOnly = true
productionRouteMutationApplied = false
trustedMetricsMutationApplied = false
estimatedRouteDisplayEnabled = false
persistedDecisionApplied = false
userVisibleDisplayAllowed = false
estimatedRouteActive remains false
```

b18-A explicitly did not:

- enable general-user estimated route display;
- mutate production route geometry;
- mutate trusted metrics;
- write display decisions to Core Data;
- update `SessionRepository`;
- update `SessionEntityMapper`;
- change `.skatetrack` package schema;
- connect anything to the normal Session Summary map.

### 1.2 Task-030c-b18-B — Review-Only Estimated Route Overlay Artifact

**Commit:** `db8f42b Task-030c-b18-B add review-only estimated route overlay`  
**Status:** Completed and pushed before b18-C.  
**Purpose:** Convert b18-A in-memory decisions into a review-only overlay artifact contract without adding route geometry or UI.

b18-B added:

```text
Shared/Models/EstimatedRouteReviewOverlay.swift
iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift
Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift
scripts/verify_task030c_b18b_review_overlay.py
```

Key implementation details:

- Added `EstimatedRouteReviewOverlayRecord`.
- Added `EstimatedRouteReviewOverlay`.
- Added `EstimatedRouteReviewOverlayBuilder`.
- Added deterministic test coverage for the five real-session regression roles.
- Added review-only records carrying session role label, decision state, blocking reasons, gap duration, safety flags, and review disposition.
- Kept the artifact textual / metadata-only.
- Did not add route coordinates or route geometry.

Five real-session regression roles preserved for b18-D:

```text
motorcyclePressureTest
motorcycleControl
surfskateShelteredHighRisk
walkingLowSpeedTrap
electricSkateboardCoreCandidate
```

Safety flags preserved by b18-B:

```text
reviewOnly = true
exportedReviewArtifactOnly = true
routeGeometryIncluded = false
normalSessionMapMutationApplied = false
productionRouteMutationApplied = false
trustedMetricsMutationApplied = false
estimatedRouteDisplayEnabled = false
persistedOverlayApplied = false
userVisibleDisplayAllowed = false
estimatedRouteActive remains false
```

b18-B explicitly did not:

- create UI;
- draw maps;
- add route polylines;
- add route-like geometry;
- connect to the normal Session Summary map;
- change trusted metrics;
- persist overlay records;
- add overlay records to Core Data, `SessionRepository`, `SessionEntityMapper`, or `.skatetrack`.

### 1.3 Task-030c-b18-C — DEBUG-Only Estimated Route Review Panel

**Commit:** `8d39e18 Task-030c-b18-C add DEBUG estimated route review panel`  
**Status:** Completed and pushed; branch synced with origin.  
**Purpose:** Add a DEBUG-only review panel for developer inspection of b18-B overlay records while keeping release/product display fully disabled.

b18-C added:

```text
iOS/Features/Debug/EstimatedRouteReviewPanel.swift
Tests/iOSTests/EstimatedRouteReviewPanelTests.swift
scripts/verify_task030c_b18c_debug_review_panel.py
docs/planning/Task-030c-b18-C_DEBUG_Review_Panel_Mini_Plan_EN_v1.1.md
```

Key implementation details:

- Added `EstimatedRouteReviewPanel` as a SwiftUI DEBUG-only review panel.
- Wrapped the entire `EstimatedRouteReviewPanel` type in `#if DEBUG`.
- Did not introduce `useEstimatedRouteReview.swift`; therefore no hook release-boundary risk was introduced.
- Added deterministic DEBUG XCTest coverage for panel construction, empty overlay state, safety flag visibility, disabled user-visible display, and disabled route geometry.
- Preserved the project localization rule for DEBUG UI:
  - all visible panel text uses `debug.estimatedRouteReview.*` keys;
  - keys exist in English, Traditional Chinese, and Japanese.
- Added verifier checks for full `#if DEBUG` type boundary, no production/release references, no route rendering tokens, no hard-coded SwiftUI `Text("...")` literals, no persistence/schema changes, and no safety flag loosening.

b18-C verified that these checks are empty / safe:

```text
release/prod forbidden panel token check: empty
panel route rendering forbidden token check: empty
hardcoded SwiftUI Text literal check: empty
estimatedRouteActive guard: false
```

b18-C safety boundary:

```text
EstimatedRouteReviewPanel exists only in DEBUG context
routeGeometryIncluded remains false
normalSessionMapMutationApplied remains false
productionRouteMutationApplied remains false
trustedMetricsMutationApplied remains false
estimatedRouteDisplayEnabled remains false
persistedOverlayApplied remains false
userVisibleDisplayAllowed remains false
estimatedRouteActive remains false
```

b18-C explicitly did not:

- make the review panel reachable in release builds;
- connect to general-user UI;
- connect to the normal Session Summary map;
- render `Map`, `MKMapView`, `Polyline`, `MKPolyline`, `Canvas`, `Path`, or route-like geometry;
- add route coordinates;
- change trusted metrics;
- persist review panel data;
- alter Core Data, `SessionRepository`, `SessionEntityMapper`, or `.skatetrack` schema.

### 1.4 Current b18 Baseline Before b18-D

Current completed b18 baseline:

```text
Task-030c-b18-A: completed and pushed
Task-030c-b18-B: completed and pushed
Task-030c-b18-C: completed and pushed
Latest completed commit: 8d39e18 Task-030c-b18-C add DEBUG estimated route review panel
Branch: task-030c-gps-route-fidelity
Branch state: synced with origin after b18-C
```

Current product state before b18-D:

```text
general-user estimated route display: disabled
DEBUG-only review panel: available
route geometry display: disabled
normal Session Summary map mutation: disabled
production route mutation: disabled
trusted metrics mutation: disabled
Core Data / SessionRepository / SessionEntityMapper / .skatetrack schema changes: none
estimatedRouteActive: false
```

Current file-size state:

- New b18-C Swift files are below 500 lines.
- Existing >500-line Swift files remain legacy oversized files.
- b18-D must not add new oversized Swift files and must avoid adding new logic to legacy oversized files.

---

## 2. b18-D Objective

Task-030c-b18-D should complete the b18 cycle by rechecking the estimated-route product decision against real-session evidence and recording an explicit product decision update.

The goal is not to make estimated routes visible.  
The goal is to make the final b18 decision auditable.

b18-D should answer:

```text
Given b18-A gate decisions, b18-B review overlay artifacts, and b18-C DEBUG inspection capability,
is SkateTrack ready to enable any general-user estimated route display?
```

Expected answer based on current evidence:

```text
No. General-user estimated route display should remain disabled.
```

b18-D should preserve that decision in code-level review artifacts, tests, scripts, and documents.

---

## 3. Real-Session Evidence Baseline

b18-D may complete with the existing five real sessions. New real-world sessions are optional, not required.

Existing five-session review baseline:

```text
SkateTrack-Session-20260629-131547 | motorcyclePressureTest
SkateTrack-Session-20260629-132410 | motorcycleControl
SkateTrack-Session-20260701-192842 | surfskateShelteredHighRisk
SkateTrack-Session-20260701-204705 | walkingLowSpeedTrap
SkateTrack-Session-20260701-204949 | electricSkateboardCoreCandidate
```

Known b17-D / b17-D-3 evidence summary:

```text
motorcyclePressureTest:
  Gaps 14
  Replay OK 12
  Blocked 2
  Eligible 0
  Longest gap 49.001s
  Max closure error 8222.858m

motorcycleControl:
  Gaps 13
  Replay OK 11
  Blocked 2
  Eligible 1
  Longest gap 6.0s
  Max closure error 138.939m

surfskateShelteredHighRisk:
  Gaps 7
  Replay OK 5
  Blocked 2
  Eligible 0
  Longest gap 9.0s
  Max closure error 61.007m

walkingLowSpeedTrap:
  Gaps 22
  Replay OK 20
  Blocked 2
  Eligible 0
  Longest gap 10.498s
  Max closure error 529.588m

electricSkateboardCoreCandidate:
  Gaps 33
  Replay OK 32
  Blocked 1
  Eligible 0
  Longest gap 41.513s
  Max closure error 309.834m
```

Product interpretation from this evidence:

- The core electric-skateboard candidate still has 0 eligible gaps and a long gap above product-safe candidate duration.
- The walking low-speed trap remains blocked.
- The sheltered surfskate session remains blocked.
- The motorcycle pressure test shows extreme closure error and remains blocked.
- The motorcycle control session proves the gate is not blindly blocking everything, but a single short candidate-like gap is not enough to enable general-user display.

---

## 4. Allowed Scope

b18-D may add or modify review-only decision artifacts and verifiers.

Possible new files:

```text
Shared/Models/EstimatedRouteProductDecisionUpdate.swift
iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift
Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift
scripts/verify_task030c_b18d_product_decision_update.py
```

Possible document updates:

```text
docs/adr/ADR-INDEX.md
docs/history/DEV_LOG.md
docs/planning/Task-030c-b16_Localization_Foundation_Plan.md
docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md
docs/reference/FILE_STRUCTURE.md
docs/release/KNOWN_LIMITATIONS_PRE_ADP.md
```

Possible script updates:

```text
scripts/verify_task030c_b18a_product_decision_gate.py
scripts/verify_task030c_b18b_review_overlay.py
scripts/verify_task030c_b18c_debug_review_panel.py
scripts/verify_task030c_post_b15_v12_alignment.py
```

b18-D should avoid adding new logic to existing oversized legacy files.

---

## 5. Proposed b18-D Data Contract

A compact product-decision update model may be added.

Example shape:

```swift
// [協作區] Shared/Models/EstimatedRouteProductDecisionUpdate.swift

enum EstimatedRouteProductDecisionOutcome: String, Codable, Sendable, Equatable {
    case keepDisabled
    case continueReviewOnly
    case candidateForFutureControlledExperiment
}

struct EstimatedRouteProductDecisionUpdate: Codable, Sendable, Equatable {
    let taskIdentifier: String
    let outcome: EstimatedRouteProductDecisionOutcome
    let productDecisionCheckpointRequired: Bool
    let reviewedSessionCount: Int
    let blockingSessionRoles: [String]
    let candidateSessionRoles: [String]
    let summaryReasons: [String]

    let generalUserEstimatedRouteDisplayAllowed: Bool
    let debugReviewOnly: Bool
    let routeGeometryIncluded: Bool
    let normalSessionMapMutationApplied: Bool
    let productionRouteMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let estimatedRouteDisplayEnabled: Bool
    let persistedDecisionApplied: Bool
    let userVisibleDisplayAllowed: Bool
}
```

Required default safety values:

```text
taskIdentifier = Task-030c-b18-D
outcome = keepDisabled
productDecisionCheckpointRequired = true
generalUserEstimatedRouteDisplayAllowed = false
debugReviewOnly = true
routeGeometryIncluded = false
normalSessionMapMutationApplied = false
productionRouteMutationApplied = false
trustedMetricsMutationApplied = false
estimatedRouteDisplayEnabled = false
persistedDecisionApplied = false
userVisibleDisplayAllowed = false
estimatedRouteActive remains false
```

The model should be review metadata only. It must not contain route coordinates or route geometry.

---

## 6. Proposed Builder Scope

If introduced, `EstimatedRouteProductDecisionUpdateBuilder` should consume b18-B overlay records and produce a product-decision update.

It should:

- count reviewed session roles;
- identify blocked / review-only / hidden candidate roles;
- preserve the five real-session role labels;
- produce a final decision of `keepDisabled`;
- include reasons why general-user estimated route display remains unsafe;
- keep all safety flags false.

It should not:

- read Core Data;
- write Core Data;
- read or write `SessionRepository`;
- mutate `SessionData`;
- mutate `MotionSample`;
- mutate route geometry;
- use map rendering;
- use UI;
- require real-device GPS;
- require new sessions.

---

## 7. Required b18-D Product Decision

b18-D should explicitly record this decision:

```text
General-user estimated route display remains disabled after b18-D.
```

Recommended decision reasons:

```text
1. The core electric-skateboard session still has 0 eligible gaps and a 41.513s longest gap.
2. Walking and sheltered-surfskate sessions remain high-risk blocked cases.
3. Motorcycle pressure testing shows large closure error and long gap risk.
4. The motorcycle control session has limited candidate evidence but not enough to enable product display.
5. Estimated route review remains useful for DEBUG/product analysis but not safe for user-facing route reconstruction.
```

The resulting product state should remain:

```text
DEBUG-only review allowed
general-user display disabled
route geometry disabled
normal Session Summary map mutation disabled
trusted metrics mutation disabled
persistence/schema mutation disabled
estimatedRouteActive false
```

---

## 8. Strict Non-Goals

b18-D must not:

1. Enable general-user estimated route display.
2. Add route polylines, route coordinates, path shapes, Canvas route previews, Map overlays, or route-like geometry.
3. Add route geometry to any b18 model.
4. Connect estimated route artifacts to the normal Session Summary map.
5. Add runtime overrides to enable estimated route display.
6. Change trusted distance, speed, altitude, elevation, or route metrics.
7. Modify production route geometry.
8. Persist b18 decisions into Core Data.
9. Add b18 decisions to `SessionRepository`.
10. Add b18 decisions to `SessionEntityMapper`.
11. Change `.skatetrack` package schema.
12. Set `estimatedRouteActive` to true.
13. Require new outdoor sessions for completion.
14. Add new oversized Swift files.
15. Add new logic to existing oversized legacy files unless there is no viable alternative and the change is minimal.

---

## 9. Test Requirements

b18-D tests should verify:

1. The five session roles are represented in the product-decision update.
2. `electricSkateboardCoreCandidate` keeps general-user display disabled.
3. `walkingLowSpeedTrap` remains blocked / unsafe.
4. `surfskateShelteredHighRisk` remains blocked / unsafe.
5. `motorcyclePressureTest` remains blocked / unsafe.
6. `motorcycleControl` may be recognized as limited candidate evidence, but does not enable general-user display.
7. Final outcome is `keepDisabled`.
8. `productDecisionCheckpointRequired` remains true.
9. All safety mutation flags remain false.
10. No route geometry is included.
11. No persistence flag is enabled.
12. `userVisibleDisplayAllowed` remains false.
13. `estimatedRouteDisplayEnabled` remains false.
14. Tests do not require new real-device sessions.
15. Tests do not require map rendering.
16. New test files remain under 500 lines.

---

## 10. Verifier Requirements

`scripts/verify_task030c_b18d_product_decision_update.py` must verify:

- b18-D files exist in allowed locations.
- first-line `[協作區]` / `[自主區]` markers are present.
- new Swift files are under 500 lines.
- product decision update model exists.
- final decision keeps general-user estimated route display disabled.
- five real-session role labels are present in tests or fixtures.
- `electricSkateboardCoreCandidate` is explicitly protected from user-visible display.
- `walkingLowSpeedTrap`, `surfskateShelteredHighRisk`, and `motorcyclePressureTest` remain blocked / unsafe.
- `motorcycleControl` does not enable general-user display.
- no `estimatedRouteActive: true`.
- no `productionRouteMutationApplied = true`.
- no `trustedMetricsMutationApplied = true`.
- no `estimatedRouteDisplayEnabled = true`.
- no `userVisibleDisplayAllowed = true`.
- no `normalSessionMapMutationApplied = true`.
- no `routeGeometryIncluded = true`.
- no `generalUserEstimatedRouteDisplayAllowed = true`.
- no `Map`, `MKMapView`, `Polyline`, `MKPolyline`, `Canvas`, `Path`, or route-like geometry rendering appears in b18-D files.
- no Core Data / SessionRepository / SessionEntityMapper / `.skatetrack` persistence additions.
- b18-C verifier still passes.
- b18-B verifier still passes.
- b18-A verifier still passes.
- v1.2 alignment verifier still passes.

---

## 11. Documentation Requirements

b18-D must update:

```text
docs/adr/ADR-INDEX.md
docs/history/DEV_LOG.md
docs/planning/Task-030c-b16_Localization_Foundation_Plan.md
docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md
docs/reference/FILE_STRUCTURE.md
docs/release/KNOWN_LIMITATIONS_PRE_ADP.md
```

Documentation must explicitly state:

```text
Task-030c-b18-D completes the b18 product decision update.
General-user estimated route display remains disabled.
The current product state remains DEBUG/review-only.
No route geometry, trusted metric mutation, persistence, or schema changes are introduced.
New real-world sessions are optional, not required, for b18-D completion.
```

---

## 12. Build and XCTest Requirements

Before commit, run the full b18-D verification chain:

```bash
python3 scripts/verify_task030c_b18d_product_decision_update.py
python3 scripts/verify_task030c_b18c_debug_review_panel.py
python3 scripts/verify_task030c_b18b_review_overlay.py
python3 scripts/verify_task030c_b18a_product_decision_gate.py
python3 scripts/verify_task030c_b17d_real_session_runner.py
python3 scripts/verify_task030c_b17d_replay_review_pack.py
python3 scripts/verify_task030c_post_b15_v12_alignment.py
```

Then run:

```bash
xcodebuild \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  clean build
```

And:

```bash
xcodebuild \
  -project SkateTrack.xcodeproj \
  -scheme SkateTrack-iOS \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  test
```

All logs should be written to:

```text
/Users/doggo/Documents/App軟體區/upload/
```

---

## 13. Acceptance Criteria

b18-D is complete only if:

1. b18-D product-decision update model exists.
2. Product decision outcome is `keepDisabled`.
3. Existing five-session evidence is represented.
4. New sessions are not required.
5. General-user estimated route display remains disabled.
6. DEBUG-only review remains allowed.
7. Route geometry remains disabled.
8. Normal Session Summary map mutation remains disabled.
9. Production route mutation remains disabled.
10. Trusted metrics mutation remains disabled.
11. Persistence remains disabled.
12. `.skatetrack` schema remains unchanged.
13. `estimatedRouteActive` remains false.
14. `userVisibleDisplayAllowed` remains false.
15. `estimatedRouteDisplayEnabled` remains false.
16. No map / polyline / Canvas / Path route rendering is introduced.
17. New Swift files remain under 500 lines.
18. Existing oversized legacy files are not expanded with new logic.
19. b18-D verifier passes.
20. b18-C verifier passes.
21. b18-B verifier passes.
22. b18-A verifier passes.
23. v1.2 alignment verifier passes.
24. Build passes.
25. XCTest passes.
26. Documentation is updated consistently.

---

## 14. Expected Product Status After b18-D

After b18-D, the b18 cycle should end with this state:

```text
Product decision: keep disabled
General-user estimated route display: disabled
DEBUG-only review panel: available
Review-only product decision artifact: available
Route geometry display: disabled
Normal Session Summary map mutation: disabled
Production route mutation: disabled
Trusted metrics mutation: disabled
Persistence/schema changes: none
estimatedRouteActive: false
```

b18-D should prepare the project for the next higher-level release decision gate, not for immediate user-facing estimated route display.

---

## 15. Implementation Reminder for the Next Hotfix

Before implementing b18-D:

- use the latest after-push b18-C source as the base;
- re-check `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`;
- keep `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` aligned;
- keep all new Swift files below 500 lines;
- use `[協作區]` / `[自主區]` first-line markers;
- avoid adding logic to oversized legacy files;
- update `FILE_STRUCTURE.md` if new files are added;
- keep verify/build/XCTest/status commands directly in the chat;
- write all generated logs/status/source packs to `/Users/doggo/Documents/App軟體區/upload/`.
