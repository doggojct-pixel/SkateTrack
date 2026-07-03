# Task-030c-b18 Product Decision Checkpoint and Safety-Gated Display Plan

**Document version:** v1.1  
**Language:** English  
**Repository branch:** `task-030c-gps-route-fidelity`  
**Current baseline:** after `859f860 Task-030c-b17-D-3 add real session review runner`  
**Controlling plan:** `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`  
**Previous required milestone:** Task-030c-b17-D / b17-D-3 real-session replay review pack  
**Current implementation baseline:** Task-030c-b18-C, following completed b18-B review-only overlay artifact  

---

## 0. v1.1 Revision Summary

This v1.1 plan keeps the v1.0 product direction unchanged, but adds four mandatory pre-implementation clarifications:

1. `EstimatedRouteDisplayDecision` and `EstimatedRouteDisplayGate` must be **in-memory only** in b18. They must not be persisted to Core Data, `SessionRepository`, `SessionEntityMapper`, or `.skatetrack` package schema.
2. Any b18 debug review UI, including `EstimatedRouteReviewPanel`, must have the **entire type and helpers wrapped in `#if DEBUG`**, not only the entry point.
3. b18-D must be completable with the existing five-session b17-D-3 review pack. Additional outdoor electric skateboard sessions are useful but optional and must not become an open-ended blocker.
4. Safety thresholds must be implemented as **named policy constants/config values**, not scattered inline literals. Debug builds may display thresholds for review, but production builds must not expose runtime override controls.

These clarifications are now part of the b18 acceptance criteria and verifier requirements.

---

## 1. Executive Product Decision

Task-030c-b18 may proceed, but it must **not** immediately enable general user-visible estimated route display.

The b17-D real-session evidence shows that the replay pipeline can generate review artifacts and conservative eligibility decisions, but the most important electric skateboard real session still produced **0 eligible gaps**. Therefore, b18 should be scoped as:

```text
Safety-gated display decision model, review-only overlay artifacts, and DEBUG-only inspection UI.
```

It must not become:

```text
General-user estimated route correction.
Production route geometry mutation.
Trusted distance/speed/elevation metric mutation.
Core Data persistence of estimated route display decisions.
```

The correct product posture is: **build the safety gate first, keep display hidden or debug/review-only, and require additional real-session evidence before any general user-visible route interpolation.**

---

## 2. Alignment with `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`

The v1.2 sequence requires b18 only after b17-D real-session review evidence exists:

```text
Task-030c-b16 — Sensor-source diagnostics and cross-validation foundation
Task-030c-b17 — Replay-only IMU gap interpolation engine
Task-030c-b18 — Estimated route display and production safety gate
[PRODUCT DECISION CHECKPOINT]
Task-030c-b19 — Task-030c outdoor localization release gate
```

b17-D and b17-D-3 have produced the review-pack mechanism and real-session review evidence. However, the product decision checkpoint outcome is conservative:

```text
b18 may implement safety-gated display decisions, review-only artifacts, and DEBUG-only review visualization.
b18 must not enable general user-visible estimated route display by default.
```

This preserves the v1.2 intent: estimated route display work is allowed only after the product decision checkpoint, and even then only within explicitly documented safety gates. v1.1 also prevents b18 from expanding into persistence, production UI, or route mutation.

---

## 3. Evidence Summary from b17-D Real Sessions

Five real sessions were reviewed with the b17-D-3 runner:

| Session | Role | Gap count | Eligible gaps | Key result |
|---|---|---:|---:|---|
| `20260701-204949` | Electric skateboard core candidate | 33 | 0 | Main target case is not yet safe enough for display. |
| `20260701-204705` | Walking low-speed trap | 22 | 0 | Correctly blocked; low-speed spiderweb route should not be displayed. |
| `20260701-192842` | Surfskate sheltered high risk | 7 | 0 | Correctly blocked; sheltered GPS reflection risk is high. |
| `20260629-131547` | Motorcycle pressure test | 14 | 0 | Correctly blocked; high-speed / long-gap case is unsafe. |
| `20260629-132410` | Motorcycle control | 13 | 1 | One short gap eligible; proves runner is not blindly blocking all cases. |

### Product interpretation

The b17-D evidence does not justify a general estimated route display feature. It does justify a b18 safety-gated display foundation that can show evidence internally and prevent unsafe segments from reaching product UI.

The most important point is that `20260701-204949`, the electric skateboard core case, still has **0 eligible gaps**. Therefore, b18 must remain conservative.

---

## 4. b18 Goals

Task-030c-b18 should implement a narrow safety-gated display foundation with the following goals:

1. Define an estimated-route display decision model that can represent `blocked`, `reviewOnly`, `candidateButHidden`, and `eligibleForFutureProductReview` states.
2. Keep any estimated route visualization hidden behind debug/review-only boundaries.
3. Make the product safety gate explicit and testable.
4. Prevent route geometry mutation unless a future milestone explicitly approves it.
5. Prevent trusted metric mutation in all b18 work.
6. Keep b18 display decisions in-memory only.
7. Use b17-D review records as evidence, not as automatic production approval.
8. Prepare a clean handoff to a later product-facing decision after more real-session data exists.

---

## 5. b18 Non-Goals

Task-030c-b18 must **not** implement:

- general user-visible estimated route display,
- automatic route correction,
- production route geometry replacement,
- route map rendering changes for normal users,
- trusted distance mutation,
- trusted speed mutation,
- average speed / max speed mutation,
- total elevation gain mutation,
- Core Data persistence for estimated route display decisions,
- new Core Data optional attributes for b18 display decisions,
- `SessionEntityMapper` or `SessionRepository` persistence changes for b18 display decisions,
- `.skatetrack` package schema changes for b18 display decisions,
- road snapping,
- map matching,
- indoor localization,
- Wi-Fi scanning or explicit Wi-Fi RTT APIs,
- hidden changes to `.skatetrack` production metrics.

If any of these become necessary, they must be moved to a later explicitly approved milestone after a product decision checkpoint.

---

## 6. Mandatory Pre-Implementation Decisions

### 6.1 In-memory only display decision model

`EstimatedRouteDisplayDecision` and `EstimatedRouteDisplayGate` are in-memory review-only models in b18.

They must not be persisted to:

```text
Core Data
SessionRepository
SessionEntityMapper
.skatetrack package schema
SessionData summary metrics
MotionSample production route fields
```

This means b18-A must not introduce:

```text
lightweight migration
new optional Core Data attributes
new persisted display-decision payload
session package schema additions
repository round-trip requirements
```

Rationale: b18 is a debug/review safety gate milestone, not a durable product feature. Recomputing display decisions from review-pack evidence is safer and avoids repeating historical persistence/round-trip risks.

---

### 6.2 Full `#if DEBUG` wrapping for debug UI

If b18-C introduces `EstimatedRouteReviewPanel.swift`, the entire panel type and any debug-only helper types must be wrapped in `#if DEBUG`.

Correct pattern:

```swift
#if DEBUG
struct EstimatedRouteReviewPanel: View {
    // DEBUG-only review UI.
}
#endif
```

Insufficient pattern:

```swift
#if DEBUG
EstimatedRouteReviewPanel(...)
#endif
```

The implementation must ensure that the type itself, previews, debug hooks, and entry points are all debug-only. This prevents release builds from containing a hidden debug panel type that could later be accidentally connected.

---

### 6.3 b18-D must not depend on new sessions

b18-D must be completable with the existing five-session b17-D-3 review pack.

Additional outdoor electric skateboard sessions may improve evidence quality, but they are optional. They must not block b18-D completion.

If no new sessions are available, the expected b18-D conclusion is:

```text
Maintain debug/review-only display foundation.
Do not enable general user-visible estimated route display.
Continue requiring more outdoor electric skateboard evidence before product visibility.
```

---

### 6.4 Named policy constants for safety thresholds

All safety thresholds must be declared as named constants in a single gate policy namespace or configuration type.

They must not be scattered as inline literals across:

```text
decision logic
review overlay builder
Swift tests
Python verifier scripts
debug panel code
```

Recommended Swift shape:

```swift
enum EstimatedRouteDisplayGatePolicy {
    static let maximumCandidateGapDurationSeconds: TimeInterval = 6
    static let maximumReviewOnlyGapDurationSeconds: TimeInterval = 30
    static let minimumCandidateIMUSampleCoverageRatio: Double = 0.90
    static let maximumCandidateClosureErrorMeters: Double = 5
    static let maximumCandidateClosureErrorRatio: Double = 0.25
}
```

Debug builds may display threshold values for review, but production builds must not expose runtime override controls. Any threshold change after b18-D recheck must be source-controlled, reviewed, and documented.

---

## 7. Proposed b18 Implementation Split

### b18-A — Product Decision Checkpoint Record and In-Memory Display Gate Model

**Purpose:** Convert the b17-D product decision into explicit source-controlled documentation and in-memory model scaffolding.

**Possible outputs:**

```text
Shared/Models/EstimatedRouteDisplayDecision.swift
Shared/Models/EstimatedRouteDisplayGate.swift
Tests/iOSTests/EstimatedRouteDisplayGateTests.swift
scripts/verify_task030c_b18a_product_decision_gate.py
```

**Allowed behavior:**

- Build a pure in-memory decision model.
- Accept b17-D review fields as input.
- Return conservative display states.
- Keep default production display disabled.
- Use named policy constants for threshold values.

**Forbidden behavior:**

- No map drawing.
- No route mutation.
- No trusted metric mutation.
- No Core Data persistence.
- No `SessionRepository` changes.
- No `SessionEntityMapper` changes.
- No `.skatetrack` schema changes.
- No runtime production override for thresholds.

**Acceptance note:** b18-A is not complete unless verifiers explicitly reject Core Data / repository / package-schema persistence additions related to estimated route display decisions.

---

### b18-B — Review-Only Display Artifact

**Purpose:** Create a non-production visualization/export contract so estimated-route candidates can be inspected without changing the user route.

**Possible outputs:**

```text
Shared/Models/EstimatedRouteReviewOverlay.swift
iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift
Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift
scripts/verify_task030c_b18b_review_overlay.py
```

**Allowed behavior:**

- Build review-only overlay records.
- Show why a gap is blocked or candidate.
- Keep output separated from normal route geometry.
- Optionally emit JSON/Markdown/CSV review artifacts.
- Preserve in-memory or exported review-only boundaries.

**Forbidden behavior:**

- No normal session-summary map rendering change.
- No general user route overlay.
- No metric mutation.
- No persisted route replacement.
- No automatic promotion from review overlay to product route.


**b18-B implementation note:** Task-030c-b18-B turns the b18-A in-memory decision gate into a review-only overlay artifact contract. The artifact carries session role labels, decision states, blocking reasons, and safety flags so the five real-session regression traps can be inspected without adding route geometry, changing the normal session-summary map, or persisting display decisions. The overlay is review evidence only; it must never be promoted into general-user estimated route display in b18-B.

**b18-C implementation note:** Task-030c-b18-C turns the b18-B review-only overlay artifact into a DEBUG-only review panel. The panel is fully wrapped in `#if DEBUG`, uses localized `debug.estimatedRouteReview.*` keys, and displays only textual review information. It must not render route polylines, path shapes, Canvas previews, map overlays, or route-like geometry, and it must not be reachable from release builds or general-user UI.

---

### b18-C — Safety-Gated DEBUG-Only Inspection UI / Developer Hook

**Purpose:** Allow internal inspection of candidate/blocked gaps without exposing them as a real product feature.

**Possible outputs:**

```text
iOS/Features/Debug/EstimatedRouteReviewPanel.swift
iOS/Hooks/useEstimatedRouteReview.swift
Tests/iOSTests/EstimatedRouteReviewPanelTests.swift
scripts/verify_task030c_b18c_debug_review_ui.py
```

**Allowed behavior:**

- DEBUG-only visibility.
- Entire UI type and helper types wrapped in `#if DEBUG`.
- Clearly label output as review evidence.
- Display blocking reasons in plain language.
- Make it impossible to confuse review overlay with trusted route.

**Forbidden behavior:**

- No production route map integration.
- No public UI affordance.
- No release-build debug panel type.
- No implicit feature flag enabling general display.
- No release-build entry point to estimated route review UI.

---

### b18-D — Real-Session Recheck and Product Decision Update

**Purpose:** Re-run the b17-D / b18 review flow on real sessions and decide whether the thresholds are too conservative, too permissive, or correctly conservative.

**Required baseline inputs:**

- `20260701-204949` electric skateboard core candidate.
- `20260701-204705` walking low-speed trap.
- `20260701-192842` sheltered surfskate high-risk case.
- `20260629-131547` motorcycle pressure test.
- `20260629-132410` motorcycle control sample.

**Optional inputs:**

- Additional outdoor electric skateboard sessions if available.

**Important rule:** optional additional sessions must not block b18-D completion.

**Output:**

A product-decision note that states whether b19 can begin, whether b18 must remain debug-only, or whether more data is needed. If no additional sessions are available, b18-D can still complete with a conservative debug-only conclusion.

---

## 8. Proposed Display Decision States

b18 must not use a simple boolean such as `showEstimatedRoute`. It should use an explicit state model.

```text
blocked
reviewOnly
candidateButHidden
eligibleForFutureProductReview
```

### `blocked`

Use when any hard safety condition fails.

Examples:

- gap too long,
- closure error too large,
- closure error ratio too high,
- heading unavailable or insufficient,
- IMU sample coverage insufficient,
- sheltered/high-risk environment note,
- low-speed walking spiderweb behavior,
- replay engine limit exceeded.

### `reviewOnly`

Use when the data is interesting but not safe for display.

Examples:

- electric skateboard core sample with visually plausible route but high closure error,
- short gap with moderate heading reliability,
- short displacement but uncertain IMU coverage.

### `candidateButHidden`

Use when a segment passes strict numeric gates but still must not be shown to normal users because b18 remains debug/review-only.

### `eligibleForFutureProductReview`

Use only for a segment that passes all gates and is suitable for later product-decision review. This still does not mean it is visible to general users in b18.

---

## 9. Conservative Eligibility Gates for b18

The initial b18 safety gate should be stricter than b17-D review eligibility. Recommended starting gates:

| Gate | Initial b18 policy |
|---|---|
| Gap duration | Candidate prefer `<= 6 s`; gaps up to `<= 30 s` may be review-only, never automatic product display. |
| IMU coverage | Require `>= 0.90` for candidate. |
| Heading reliability | Require `high` for candidate; `moderate` can only be review-only. |
| Closure error | Require very low absolute closure error, initially `<= 5 m` for candidate. |
| Closure error ratio | Require `<= 0.25` for candidate. |
| Replay blocking reasons | Any blocking reason forces `blocked`. |
| Environment risk | Sheltered/covered sessions default to blocked or review-only, not candidate. |
| Activity risk | Walking low-speed trap sessions default to blocked unless future logic proves stability. |
| Product visibility | All candidates remain hidden/debug-only in b18. |

### Threshold source and calibration note

These thresholds are conservative seed values derived from two sources:

1. the v1.2 plan’s requirement that b18 must be safety-gated and product-decision-bound, and
2. the b17-D real-session evidence, especially the fact that the electric skateboard core candidate had 33 gaps and 0 eligible gaps, with closure evidence far beyond a safe display threshold.

They are not final product-calibrated thresholds. They must be implemented as named policy constants so b18-D can re-evaluate them without scattering magic numbers across the codebase.

---

## 10. Real-Session Specific b18 Policy

### 10.1 Electric skateboard `20260701-204949`

**Current result:** 33 gaps, 0 eligible gaps.

**b18 policy:**

```text
Do not show estimated route to normal users.
Allow debug/review overlay only if clearly labeled and not connected to trusted route geometry.
```

This is the key target scenario, but the current closure evidence is not safe enough.

---

### 10.2 Walking `20260701-204705`

**Current result:** 22 gaps, 0 eligible gaps.

**b18 policy:**

```text
Keep blocked.
Use as a regression trap to prevent low-speed GPS spiderweb routes from becoming display-eligible.
```

This session should be part of every b18 safety-gate regression suite.

---

### 10.3 Sheltered surfskate `20260701-192842`

**Current result:** 7 gaps, 0 eligible gaps.

**b18 policy:**

```text
Keep blocked or review-only.
Do not use sheltered/covered environment data as proof that outdoor estimated-route display is safe.
```

---

### 10.4 Motorcycle pressure test `20260629-131547`

**Current result:** 14 gaps, 0 eligible gaps.

**b18 policy:**

```text
Keep blocked.
Use as a high-speed / long-gap safety regression case.
```

---

### 10.5 Motorcycle control `20260629-132410`

**Current result:** 13 gaps, 1 eligible gap.

**b18 policy:**

```text
Use as a sanity check that the gate does not blindly block everything.
Do not use this single eligible gap to justify general product display.
```

---

## 11. Proposed Data Model Contract

A b18 display decision should preserve enough evidence for review:

```text
sessionIdentifier
gapIndex
gapDurationSeconds
imuSampleCoverageRatio
headingReliability
estimatedDisplacementMeters
anchorDistanceMeters
anchorClosureErrorMeters
closureErrorRatio
b17DEligibleForUserVisibleEstimatedRoute
b18DisplayDecision
b18DisplayBlockedReasons
productionRouteMutationApplied
trustedMetricsMutationApplied
estimatedRouteDisplayEnabled
productDecisionCheckpointRequired
```

Hard-coded safety defaults:

```text
productionRouteMutationApplied = false
trustedMetricsMutationApplied = false
estimatedRouteDisplayEnabled = false
productDecisionCheckpointRequired = true
```

### In-memory model rule

This data model contract is for in-memory decisions and review artifacts only in b18. It must not become a Core Data schema, persisted session field, or package schema addition in b18.

---

## 12. UI / UX Principles for b18 Debug Review

If a debug/review UI is implemented, it must use unambiguous language:

- “Estimated route review candidate”
- “Blocked from display”
- “Replay-only evidence”
- “Not included in trusted distance/speed/elevation”
- “Not shown to normal users”

It must avoid language such as:

- “Corrected route”
- “Fixed route”
- “Trusted route”
- “Recovered GPS route”
- “Production route”

The UI should make the blocked reason visible, because the product value of b18 is not only showing possible candidates; it is also proving that unsafe segments remain blocked.

### DEBUG-only rule

Any UI type introduced for this purpose must be fully excluded from release builds with `#if DEBUG`. The verifier must check the whole type boundary, not only entry-point visibility.

---

## 13. Verification Plan

b18 must add new verifiers and preserve all prior gates.

### Required new verifiers

```text
scripts/verify_task030c_b18a_product_decision_gate.py
scripts/verify_task030c_b18b_review_overlay.py
scripts/verify_task030c_b18c_debug_review_ui.py
scripts/verify_task030c_b18d_product_decision_recheck.py
```

### b18-A verifier requirements

The b18-A verifier must confirm:

- `EstimatedRouteDisplayDecision` exists and uses enum-like explicit states, not a simple `showEstimatedRoute` boolean.
- `EstimatedRouteDisplayGate` is in-memory only.
- No b18 display decision fields are added to Core Data.
- No b18 display decision fields are added to `SessionRepository` persistence.
- No b18 display decision fields are added to `SessionEntityMapper`.
- No `.skatetrack` package schema changes are added for display decisions.
- Thresholds are defined as named policy constants, not inline literals.
- Hard safety defaults remain false/true as required.

### b18-B verifier requirements

The b18-B verifier must confirm:

- `EstimatedRouteReviewOverlay` exists and is explicitly review-only.
- `EstimatedRouteReviewOverlayBuilder` consumes b18-A decisions without producing route geometry.
- The five real-session regression roles are represented in deterministic XCTest coverage.
- Walking, sheltered surfskate, and motorcycle pressure cases remain blocked.
- The electric skateboard core candidate is not promoted to general product display.
- Any motorcycle-control candidate remains `candidateButHidden` or review evidence only, never user-visible.
- No Core Data, repository, mapper, `.skatetrack` schema, route map, or trusted metric mutation is introduced.

### b18-C verifier requirements

The b18-C verifier must confirm:

- `EstimatedRouteReviewPanel` is fully wrapped in `#if DEBUG`.
- Any debug-only helper type or hook is fully debug-gated.
- No release-build entry point exposes estimated route review UI.
- Debug review copy does not use production wording such as “corrected route” or “trusted route.”

### b18-D verifier requirements

The b18-D verifier must confirm:

- b18-D can complete using the existing five-session review pack.
- Additional sessions are optional, not required.
- Walking, sheltered surfskate, and motorcycle pressure cases remain blocked.
- The electric skateboard core candidate is not promoted to general product display without new evidence.
- If no new sessions are available, the conclusion remains debug/review-only.

### Required regression verifiers

```text
scripts/verify_task030c_b17d_real_session_runner.py
scripts/verify_task030c_b17d_replay_review_pack.py
scripts/verify_task030c_post_b15_v12_alignment.py
scripts/verify_task030c_b17c_dead_reckoning_closure_scoring.py
scripts/verify_task030c_b17b_replay_dead_reckoning_engine.py
scripts/verify_task030c_b17a_imu_local_frame_bias_foundation.py
scripts/verify_task030c_b17_diagnostics_review_pack.py
scripts/verify_task030c_b16d_heading_quality_gate.py
scripts/verify_task030c_b16c_location_accuracy_source_diagnostics.py
scripts/verify_task030c_b16b_barometric_gps_outlier_diagnostics.py
scripts/verify_task030c_b16a_localization_foundation_plan.py
```

### Xcode checks

- `xcodebuild clean build` for `SkateTrack-iOS`
- `xcodebuild test` for `SkateTrack-iOS`
- simulator: `iPhone 17 Pro`

---

## 14. Acceptance Criteria

b18 can be considered complete only if all of the following are true:

1. A product decision checkpoint is documented in source-controlled docs.
2. b18 display decision logic is explicit and testable.
3. b18 display decisions remain in-memory only.
4. No Core Data persistence, `SessionRepository` persistence, `SessionEntityMapper`, or `.skatetrack` schema change is introduced for b18 display decisions.
5. Normal user-visible estimated route display remains disabled.
6. `estimatedRouteActive` remains false unless a later explicitly approved milestone changes it.
7. `productionRouteMutationApplied` remains false.
8. `trustedMetricsMutationApplied` remains false.
9. `estimatedRouteDisplayEnabled` remains false.
10. Safety thresholds are named constants/config values, not scattered inline literals.
11. Production builds expose no runtime threshold override controls.
12. Any b18 debug review panel type is fully wrapped in `#if DEBUG`.
13. The walking low-speed trap session remains blocked.
14. The sheltered surfskate high-risk session remains blocked or review-only.
15. The motorcycle pressure test remains blocked.
16. The electric skateboard core candidate is not promoted to product display without new evidence.
17. b18-D can complete even if no additional sessions are available.
18. All b16/b17 regression verifiers continue to pass.
19. Build and XCTest pass.
20. New Swift files comply with collaboration/autonomous marker and file-size rules.
21. `FILE_STRUCTURE.md`, `DEV_LOG.md`, `ADR-INDEX.md`, and `KNOWN_LIMITATIONS_PRE_ADP.md` are updated.

---

## 15. Manual Review Checklist

Before any future product-facing display approval, reviewers must answer:

1. Is this a true outdoor electric skateboard case, not walking, motorcycle, or sheltered GPS reflection?
2. Is the gap short enough to trust?
3. Is IMU coverage high enough?
4. Is heading reliability high enough?
5. Is closure error low enough in meters?
6. Is closure error ratio low enough compared with estimated movement?
7. Are there no blocking reasons?
8. Does the estimated path connect cleanly between anchors?
9. Would a user be misled if this segment were displayed?
10. Are trusted distance/speed/elevation still untouched?
11. Was the decision produced in-memory rather than persisted as product route state?
12. Is any review UI debug-only and excluded from release builds?

If any answer is unsafe or uncertain, the segment must remain blocked or review-only.

---

## 16. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| A visually plausible route has bad closure error. | Keep numeric closure gates authoritative over visual appearance. |
| Walking low-speed noise becomes display-eligible. | Keep walking trap sessions in regression tests. |
| Sheltered GPS reflections appear as real movement. | Default sheltered/covered sessions to blocked or review-only. |
| High-speed gaps produce huge displacement errors. | Keep motorcycle pressure tests blocked. |
| Debug overlay is confused with trusted route. | Use explicit copy, separate models, hard false safety flags, and DEBUG-only wrapping. |
| Future hotfix accidentally enables production display. | Static verifiers must reject `estimatedRouteDisplayEnabled = true`, `productionRouteMutationApplied = true`, and trusted metric mutation unless a later approved milestone changes the policy. |
| b18 repeats a Core Data round-trip / migration issue. | Keep b18-A display decisions in-memory only; reject Core Data, repository, mapper, and package-schema changes. |
| b18-D becomes blocked by lack of new real sessions. | Require b18-D to complete with the existing five-session evidence; additional sessions are optional only. |
| Threshold values become magic numbers. | Define named policy constants and verifier checks against scattered inline gate literals. |
| Debug panel exists in release builds but is not reachable. | Reject this; the entire debug panel type and helpers must be wrapped in `#if DEBUG`. |

---

## 17. Recommended b18 Decision

Proceed with b18 only under this scope:

```text
Task-030c-b18-A: Product decision checkpoint record and in-memory safety gate model.
Task-030c-b18-B: Review-only estimated route overlay artifact.
Task-030c-b18-C: DEBUG-only estimated route review panel.
Task-030c-b18-C: DEBUG-only inspection UI or export hook.
Task-030c-b18-D: Real-session recheck and updated product decision note.
```

Do not implement general user-visible estimated route display in b18.

Do not implement Core Data persistence, repository persistence, package schema changes, production route mutation, trusted metric mutation, or release-build debug UI in b18.

---

## 18. Final Statement

The b17-D real-session evidence is valuable precisely because it advises caution. b18 should not attempt to make the route look better yet. It should make the safety decision visible, testable, in-memory, and hard to bypass. Only after additional real outdoor electric skateboard sessions demonstrate consistently low closure error and stable heading/IMU evidence should a later milestone consider product-facing estimated route display.

v1.1 is therefore the required implementation baseline for b18-A and supersedes v1.0 for execution planning.
