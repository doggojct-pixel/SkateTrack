# Task-030c-b19 Outdoor Localization Release Gate Mini Plan EN v1.0

**Project:** SkateTrack  
**Branch:** `task-030c-gps-route-fidelity`  
**Task:** `Task-030c-b19`  
**Title:** Outdoor Localization Release Gate  
**Controlling baseline:** `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`  
**Must remain aligned with:** `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`  
**Previous completed milestone:** `Task-030c-b18-D` — Real-session recheck and product decision update  
**Revision:** v1.0  
**Status:** Implementation planning note, not yet implementation

---

## 1. Current Baseline Before b19

Task-030c-b18 has been completed and pushed through b18-D.

Completed commits:

```text
93ae35e Task-030c-b18-A add product decision display gate
db8f42b Task-030c-b18-B add review-only estimated route overlay
8d39e18 Task-030c-b18-C add DEBUG estimated route review panel
9d7db70 Task-030c-b18-D add product decision update
```

Current branch state before b19:

```text
branch: task-030c-gps-route-fidelity
branch synced with origin after b18-D
latest completed commit: 9d7db70 Task-030c-b18-D add product decision update
git status: clean
```

Current b18 product decision:

```text
outcome = keepDisabled
generalUserEstimatedRouteDisplayAllowed = false
estimatedRouteDisplayEnabled = false
estimatedRouteActive = false
routeGeometryIncluded = false
normalSessionMapMutationApplied = false
productionRouteMutationApplied = false
trustedMetricsMutationApplied = false
persistence/schema mutation = none
```

b19 must treat this as a hard baseline. It must not reopen estimated route display, route reconstruction, production route mutation, or trusted metric mutation.

---

## 2. b19 Purpose

Task-030c-b19 should introduce an **Outdoor Localization Release Gate**.

The purpose is to determine whether a recorded outdoor session is safe enough to be treated as release-quality localization data for normal product presentation.

This is not an estimated route display milestone.  
This is not a dead-reckoning route reconstruction milestone.  
This is not a map polyline replacement milestone.

b19 should answer:

```text
Can this session's real GPS/localization data be presented as normal outdoor localization output without additional correction or estimated-route display?
```

The gate should provide:

- a deterministic release-gate model;
- a conservative decision builder;
- tests that cover good / blocked / warning cases;
- a static verifier that prevents unsafe display paths;
- documentation that explains the release decision.

---

## 3. Product-Level Meaning

b19 should separate three product states:

```text
releaseReady
  The session's actual GPS/localization evidence is good enough for normal product presentation.

limitedDisclosure
  The session can still be shown, but the app / docs should disclose that GPS quality, gaps, startup warm-up, or low-speed localization may limit route confidence.

blocked
  The session should not be represented as release-quality outdoor localization evidence.
```

Important: `limitedDisclosure` is not estimated-route display.  
It only means the real recorded data may be shown with conservative disclosure.

---

## 4. Allowed Scope

b19 may add a small, deterministic release-gate model and builder.

Possible new files:

```text
Shared/Models/OutdoorLocalizationReleaseGate.swift
iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift
Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift
scripts/verify_task030c_b19_outdoor_localization_release_gate.py
docs/planning/Task-030c-b19_Outdoor_Localization_Release_Gate_Mini_Plan_EN_v1.0.md
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
scripts/verify_task030c_b18d_product_decision_update.py
scripts/verify_task030c_post_b15_v12_alignment.py
scripts/verify_task030c_debug_panel_polish.py
```

b19 should avoid adding new logic to existing oversized legacy Swift files.

---

## 5. Proposed b19 Data Contract

Suggested model:

```swift
// [協作區] Shared/Models/OutdoorLocalizationReleaseGate.swift

enum OutdoorLocalizationReleaseDecision: String, Codable, Sendable, Equatable, CaseIterable {
    case releaseReady
    case limitedDisclosure
    case blocked
}

enum OutdoorLocalizationReleaseBlockingReason: String, Codable, Sendable, Equatable, CaseIterable {
    case insufficientTrustedGPSCoverage
    case excessiveStartupWarmupDrift
    case excessiveGPSGapDuration
    case excessiveHorizontalAccuracy
    case lowSpeedLocalizationTrap
    case headingQualityInsufficient
    case altitudeQualityInsufficient
    case estimatedRouteDisplayDisabledByProductDecision
}

struct OutdoorLocalizationReleaseGate: Codable, Sendable, Equatable {
    let taskIdentifier: String
    let decision: OutdoorLocalizationReleaseDecision
    let blockingReasons: [OutdoorLocalizationReleaseBlockingReason]
    let disclosureReasons: [String]

    let reviewedOutdoorSessionCount: Int
    let minimumTrustedGPSCoverageRatio: Double
    let maximumAllowedStartupWarmupSeconds: Double
    let maximumAllowedGPSGapSeconds: Double
    let maximumAllowedHorizontalAccuracyMeters: Double

    let realGPSOnly: Bool
    let generalUserEstimatedRouteDisplayAllowed: Bool
    let estimatedRouteDisplayEnabled: Bool
    let estimatedRouteActive: Bool
    let routeGeometryMutationApplied: Bool
    let trustedMetricsMutationApplied: Bool
    let persistenceSchemaMutationApplied: Bool
}
```

Required safety defaults:

```text
taskIdentifier = Task-030c-b19
realGPSOnly = true
generalUserEstimatedRouteDisplayAllowed = false
estimatedRouteDisplayEnabled = false
estimatedRouteActive = false
routeGeometryMutationApplied = false
trustedMetricsMutationApplied = false
persistenceSchemaMutationApplied = false
```

---

## 6. Proposed Policy Constants

b19 thresholds should be conservative and named. They must not be inline magic numbers.

Initial suggested gate constants:

```text
minimumTrustedGPSCoverageRatio = 0.80
maximumAllowedStartupWarmupSeconds = 30.0
maximumAllowedGPSGapSeconds = 10.0
maximumAllowedHorizontalAccuracyMeters = 25.0
maximumLimitedDisclosureHorizontalAccuracyMeters = 65.0
maximumLowSpeedTrapDurationSeconds = 20.0
minimumHeadingReliabilityForReleaseReady = moderate
altitudeQualityRequiredForElevationClaims = true
```

These constants should be treated as release-gate thresholds, not route-correction thresholds.

b19 may classify release gate status as:

```text
releaseReady:
  sufficient trusted GPS coverage
  acceptable startup warm-up
  short or no GPS gaps
  acceptable horizontal accuracy
  no low-speed trap
  no estimated-route dependency

limitedDisclosure:
  actual GPS data can be shown, but quality limitations must be disclosed
  no estimated-route display is enabled

blocked:
  session must not be used as release-quality localization evidence
  estimated route display remains disabled
```

---

## 7. Existing Evidence to Preserve

b19 should preserve the current understanding from b17-D and b18-D:

```text
electricSkateboardCoreCandidate:
  not enough to enable estimated-route display
  may be useful as outdoor localization review evidence, but must pass real-GPS release thresholds independently

walkingLowSpeedTrap:
  must remain a release-gate warning/block candidate for low-speed localization trap conditions

surfskateShelteredHighRisk:
  should remain a high-risk/sheltered-environment caution case

motorcyclePressureTest:
  should remain blocked as release-quality localization evidence due to extreme gap/closure-error behavior

motorcycleControl:
  may be useful as a control case but must not alone justify estimated-route display
```

b19 can use deterministic fixtures derived from these roles, but it should not require new outdoor sessions to complete.

New real-world sessions can be used later to validate the gate, but b19 implementation must not depend on them.

---

## 8. Strict Non-Goals

b19 must not:

1. Enable general-user estimated route display.
2. Set `estimatedRouteActive` to true.
3. Add route polylines, route coordinates, path shapes, Canvas route previews, Map overlays, or route-like geometry.
4. Replace normal Session Summary route geometry.
5. Mutate production route geometry.
6. Mutate trusted distance, speed, elevation, or route metrics.
7. Add Core Data persistence for b19 decisions.
8. Add b19 decisions to `SessionRepository`.
9. Add b19 decisions to `SessionEntityMapper`.
10. Change `.skatetrack` schema.
11. Add user-facing UI unless explicitly approved in a later task.
12. Add runtime override controls to bypass the release gate.
13. Add new oversized Swift files.
14. Add new logic to existing oversized legacy files unless the change is minimal and unavoidable.

---

## 9. Test Requirements

b19 tests should verify:

1. A high-quality outdoor real-GPS fixture can be `releaseReady`.
2. A fixture with moderate quality but safe real GPS can be `limitedDisclosure`.
3. A fixture with insufficient trusted GPS coverage is `blocked`.
4. A fixture with excessive startup warm-up drift is `blocked` or `limitedDisclosure`.
5. A fixture with excessive GPS gap duration is `blocked`.
6. A fixture with poor horizontal accuracy is `blocked` or `limitedDisclosure`.
7. A low-speed localization trap fixture is not `releaseReady`.
8. A sheltered/high-risk fixture is not blindly marked `releaseReady`.
9. b18-D product decision is preserved:
   - `generalUserEstimatedRouteDisplayAllowed == false`
   - `estimatedRouteDisplayEnabled == false`
   - `estimatedRouteActive == false`
10. No release decision requires estimated route display.
11. No route geometry mutation is applied.
12. No trusted metrics mutation is applied.
13. No persistence/schema mutation is applied.
14. New test files remain under 500 lines.

---

## 10. Verifier Requirements

`scripts/verify_task030c_b19_outdoor_localization_release_gate.py` must verify:

- b19 files exist in allowed locations.
- first-line `[協作區]` / `[自主區]` markers are present.
- new Swift files are under 500 lines.
- `OutdoorLocalizationReleaseGate` model exists.
- `OutdoorLocalizationReleaseDecision` has `releaseReady`, `limitedDisclosure`, and `blocked`.
- release gate policy constants are named.
- b18-D safety decision is preserved.
- no `estimatedRouteActive: true`.
- no `generalUserEstimatedRouteDisplayAllowed = true`.
- no `estimatedRouteDisplayEnabled = true`.
- no `routeGeometryMutationApplied = true`.
- no `trustedMetricsMutationApplied = true`.
- no `persistenceSchemaMutationApplied = true`.
- no route rendering tokens in b19 files:
  - `Map(`
  - `MKMapView`
  - `Polyline`
  - `MKPolyline`
  - `Canvas(`
  - `Path(`
- no Core Data / SessionRepository / SessionEntityMapper / `.skatetrack` schema additions.
- b18-D verifier still passes.
- b18-C verifier still passes.
- b18-B verifier still passes.
- b18-A verifier still passes.
- v1.2 alignment verifier still passes.

---

## 11. Documentation Requirements

b19 must update:

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
Task-030c-b19 adds an outdoor localization release gate.
b19 does not enable estimated route display.
b19 does not change trusted metrics.
b19 does not mutate route geometry.
b19 does not change persistence or package schema.
b19 preserves the b18-D decision: general-user estimated route display remains disabled.
```

---

## 12. Build and XCTest Requirements

Before commit, run:

```bash
python3 scripts/verify_task030c_b19_outdoor_localization_release_gate.py
python3 scripts/verify_task030c_b18d_product_decision_update.py
python3 scripts/verify_task030c_b18c_debug_review_panel.py
python3 scripts/verify_task030c_b18b_review_overlay.py
python3 scripts/verify_task030c_b18a_product_decision_gate.py
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

b19 is complete only if:

1. Outdoor localization release gate model exists.
2. Release decision has `releaseReady`, `limitedDisclosure`, and `blocked`.
3. Release gate policy constants are named.
4. High-quality real-GPS fixture can pass as `releaseReady`.
5. Poor quality / high-risk fixtures are not release-ready.
6. Low-speed localization trap is not release-ready.
7. b18-D product decision remains unchanged.
8. General-user estimated route display remains disabled.
9. `estimatedRouteActive` remains false.
10. No route geometry is rendered or mutated.
11. Trusted metrics are not mutated.
12. Persistence/schema remains unchanged.
13. New Swift files remain under 500 lines.
14. Existing oversized legacy files are not expanded with new logic.
15. b19 verifier passes.
16. b18-D verifier passes.
17. b18-C verifier passes.
18. b18-B verifier passes.
19. b18-A verifier passes.
20. v1.2 alignment verifier passes.
21. Build passes.
22. XCTest passes.
23. Documentation is updated consistently.

---

## 14. Expected Product Status After b19

After b19, the expected state is:

```text
Outdoor localization release gate: available
General-user estimated route display: disabled
estimatedRouteActive: false
Route reconstruction: disabled
Route geometry mutation: disabled
Trusted metrics mutation: disabled
Persistence/schema changes: none
```

b19 should improve product safety by making outdoor localization quality auditable and gateable. It should not make estimated routes visible.
