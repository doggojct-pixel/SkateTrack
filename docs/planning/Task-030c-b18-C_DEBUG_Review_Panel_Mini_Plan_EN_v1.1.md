# Task-030c-b18-C DEBUG Review Panel Mini Plan EN v1.1

**Project:** SkateTrack  
**Branch:** `task-030c-gps-route-fidelity`  
**Task:** `Task-030c-b18-C`  
**Title:** DEBUG-Only Estimated Route Review Panel  
**Controlling baseline:** `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`  
**Must remain aligned with:** `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`  
**Previous completed milestone:** `Task-030c-b18-B` — Review-only estimated route overlay artifact  
**Revision:** v1.1  
**Status:** Implementation planning note, not yet implementation

---

## 0. v1.1 Revision Summary

This v1.1 note incorporates the five pre-implementation review points raised before b18-C implementation.

1. **Localization policy clarified:** even though the panel is DEBUG-only, all SwiftUI panel text must still use `Localizable.strings` keys in `en`, `zh-Hant`, and `ja`. This is an intentional engineering choice, not an accidental default.
2. **Hook boundary clarified:** if `iOS/Hooks/useEstimatedRouteReview.swift` is introduced, the entire file/type must be wrapped in `#if DEBUG`, not only call sites.
3. **Verifier priority clarified:** the most critical verifier checks are the full `#if DEBUG` type-boundary checks for panel/hook files. Token scanning is secondary and must not be treated as sufficient.
4. **`userVisibleDisplayAllowed` source confirmed:** b18-B already introduced this safety flag in `EstimatedRouteReviewOverlay` and `EstimatedRouteReviewOverlayRecord`; b18-C may read it but must not loosen it.
5. **Route rendering non-goal tightened:** the review panel must not render route polylines, path shapes, Canvas previews, Map overlays, or route-like geometry of any kind, even in DEBUG context.

---

## 1. Product Decision

Task-030c-b18-C may introduce a DEBUG-only review panel that displays b18-B review-only overlay records for developer inspection.

It must not make estimated routes visible to general users.  
It must not draw route geometry.  
It must not mutate production route data.  
It must not change trusted metrics.  
It must not persist display decisions or overlay data.

b18-C remains a review and inspection milestone only.

---

## 2. Controlling Documents

b18-C must be aligned with:

- `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`
- `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`
- `docs/planning/Task-030c-b16_Localization_Foundation_Plan.md`
- `docs/history/DEV_LOG.md`
- `docs/adr/ADR-INDEX.md`
- `docs/reference/FILE_STRUCTURE.md`
- `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md`

The implementation must update project documentation and verifiers consistently.

---

## 3. Allowed Scope

b18-C may add:

```text
iOS/Features/Debug/EstimatedRouteReviewPanel.swift
iOS/Hooks/useEstimatedRouteReview.swift          # optional, only if needed
Tests/iOSTests/EstimatedRouteReviewPanelTests.swift
scripts/verify_task030c_b18c_debug_review_panel.py
```

b18-C may update:

```text
SkateTrack.xcodeproj/project.pbxproj
Shared/Models/SessionData.swift
Shared/Localization/en.lproj/Localizable.strings
Shared/Localization/zh-Hant.lproj/Localizable.strings
Shared/Localization/ja.lproj/Localizable.strings
docs/adr/ADR-INDEX.md
docs/history/DEV_LOG.md
docs/planning/Task-030c-b16_Localization_Foundation_Plan.md
docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md
docs/reference/FILE_STRUCTURE.md
docs/release/KNOWN_LIMITATIONS_PRE_ADP.md
scripts/verify_task030c_b18a_product_decision_gate.py
scripts/verify_task030c_b18b_review_overlay.py
scripts/verify_task030c_post_b15_v12_alignment.py
```

Only minimal wiring/token updates should touch existing legacy files.

---

## 4. Required `#if DEBUG` Boundary

The DEBUG boundary is the highest-risk part of b18-C.

The following must be fully wrapped in `#if DEBUG` if introduced:

```text
iOS/Features/Debug/EstimatedRouteReviewPanel.swift
iOS/Hooks/useEstimatedRouteReview.swift
debug-only panel fixtures
debug-only SwiftUI previews
debug-only panel helpers
debug-only entry points
```

Correct pattern:

```swift
// [協作區] iOS/Features/Debug/EstimatedRouteReviewPanel.swift
#if DEBUG

import SwiftUI

struct EstimatedRouteReviewPanel: View {
    ...
}

#endif
```

Correct hook pattern if a hook is introduced:

```swift
// [協作區] iOS/Hooks/useEstimatedRouteReview.swift
#if DEBUG

import Foundation

struct EstimatedRouteReviewState {
    ...
}

func useEstimatedRouteReview(...) -> EstimatedRouteReviewState {
    ...
}

#endif
```

Insufficient pattern:

```swift
// Not enough
struct EstimatedRouteReviewPanel: View {
    ...
}

#if DEBUG
EstimatedRouteReviewPanel(...)
#endif
```

The type itself must not exist in release builds.

---

## 5. Verifier Priority

The verifier must treat the following as the most critical checks:

1. `EstimatedRouteReviewPanel.swift`, if present, must have the entire panel type inside a `#if DEBUG` / `#endif` region.
2. `useEstimatedRouteReview.swift`, if present, must have the entire hook/state/helper implementation inside a `#if DEBUG` / `#endif` region.
3. The first Swift declaration in these files must appear only after `#if DEBUG`.
4. The final non-empty line of these files should be `#endif` unless a file-level trailing comment convention is already used.
5. Token scanning for non-debug production feature files is required, but secondary. It must not replace full type-boundary verification.

The verifier should fail if it only finds no production references but the DEBUG panel type itself is still compiled into release.

---

## 6. Localization Policy

Even though the b18-C panel is DEBUG-only, all SwiftUI text in the panel must use localization keys.

This is an intentional engineering choice for SkateTrack consistency:

- no hard-coded SwiftUI `Text("...")` panel labels
- no hard-coded visible button labels
- no hard-coded visible section headers
- keys must be added to:
  - `Shared/Localization/en.lproj/Localizable.strings`
  - `Shared/Localization/zh-Hant.lproj/Localizable.strings`
  - `Shared/Localization/ja.lproj/Localizable.strings`

The panel may keep the number of visible strings small to limit localization overhead.

Recommended key prefix:

```text
debug.estimatedRouteReview.*
```

Example keys:

```text
debug.estimatedRouteReview.title
debug.estimatedRouteReview.subtitle
debug.estimatedRouteReview.empty
debug.estimatedRouteReview.state
debug.estimatedRouteReview.blockingReasons
debug.estimatedRouteReview.routeGeometryDisabled
debug.estimatedRouteReview.userVisibleDisplayDisabled
```

---

## 7. Existing b18-B Data Contract

b18-C must consume the existing b18-B overlay contract. It should not redesign the b18-B model unless a compile issue proves that the model is insufficient.

The following flags already exist in b18-B and may be read by the panel:

```text
reviewOnly
exportedReviewArtifactOnly
routeGeometryIncluded
normalSessionMapMutationApplied
productionRouteMutationApplied
trustedMetricsMutationApplied
estimatedRouteDisplayEnabled
persistedOverlayApplied
userVisibleDisplayAllowed
```

b18-C must keep these values safe:

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
```

b18-C may show these values as DEBUG-only review information, but must not allow toggling or overriding them.

---

## 8. Strict Non-Goals

b18-C must not:

1. Enable general-user estimated route display.
2. Connect the review panel to the normal Session Summary map.
3. Render route polylines, path shapes, Canvas route previews, Map overlays, or route-like geometry of any kind, even in DEBUG context.
4. Add route geometry to `EstimatedRouteReviewOverlay`.
5. Add persisted display decisions to Core Data.
6. Add `EstimatedRouteReviewOverlay` or `EstimatedRouteReviewPanel` to `SessionRepository`.
7. Add overlay mapping to `SessionEntityMapper`.
8. Change `.skatetrack` package schema.
9. Change trusted distance, speed, elevation, or route metrics.
10. Set `estimatedRouteActive` to true.
11. Add a release-build reachable review UI.
12. Add runtime override controls for safety thresholds or display flags.

---

## 9. UI Shape

The panel should be a simple, read-only DEBUG view.

Allowed display:

- task identifier
- overlay safety flags
- number of overlay records
- per-record session role
- per-record display decision state
- per-record blocking reason summary
- explicit “route geometry disabled” / “user visible display disabled” labels

Not allowed:

- map
- polyline
- Canvas route
- estimated route preview
- route coordinates
- production session summary map integration
- “show route” toggle
- “enable estimated route” toggle
- persistence/export controls that modify product package schema

---

## 10. Test Requirements

b18-C tests should verify:

1. The panel can render an overlay with the five real-session regression role labels.
2. The panel exposes safety flags as read-only information.
3. `userVisibleDisplayAllowed` remains false.
4. `estimatedRouteDisplayEnabled` remains false.
5. `routeGeometryIncluded` remains false.
6. `normalSessionMapMutationApplied` remains false.
7. Empty overlay data renders a localized empty state.
8. No route geometry model is required by the panel.
9. Test files stay under 500 lines.
10. Tests do not require outdoor or real-device GPS.

If direct SwiftUI view inspection is impractical, deterministic tests may validate a small DEBUG-only view model/state formatter, provided the formatter file is also fully wrapped in `#if DEBUG`.

---

## 11. Verification Requirements

`scripts/verify_task030c_b18c_debug_review_panel.py` must verify:

- b18-C files exist only in allowed locations.
- first-line `[協作區]` / `[自主區]` markers are present.
- new Swift files are under 500 lines.
- `EstimatedRouteReviewPanel.swift` is fully wrapped in `#if DEBUG`.
- `useEstimatedRouteReview.swift`, if present, is fully wrapped in `#if DEBUG`.
- `EstimatedRouteReviewPanel` type declaration is inside the DEBUG region.
- production feature files do not reference `EstimatedRouteReviewPanel` or `useEstimatedRouteReview`.
- panel code does not contain `Text("...")` hard-coded visible strings.
- required localization keys exist in en, zh-Hant, and ja.
- no `Map`, `MKMapView`, `Polyline`, `Path`, `Canvas`, or route-like geometry rendering appears in the b18-C panel files.
- no `estimatedRouteActive: true`.
- no `productionRouteMutationApplied = true`.
- no `trustedMetricsMutationApplied = true`.
- no `estimatedRouteDisplayEnabled = true`.
- no `userVisibleDisplayAllowed = true`.
- no `normalSessionMapMutationApplied = true`.
- no Core Data / SessionRepository / SessionEntityMapper / `.skatetrack` persistence additions for the panel or overlay.
- b18-A and b18-B verifiers still pass.
- v1.2 alignment verifier still passes.

---

## 12. Build and XCTest Requirements

Before commit, run:

```bash
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

Logs should be written to `/Users/doggo/Documents/App軟體區/upload/`.

---

## 13. Acceptance Criteria

b18-C is complete only if:

1. DEBUG-only review panel exists.
2. The entire review panel type is inside `#if DEBUG`.
3. Optional hook/state file, if introduced, is entirely inside `#if DEBUG`.
4. No release-build reachable panel type exists.
5. No production session summary map integration exists.
6. No route geometry rendering exists, even in DEBUG UI.
7. No route geometry is added to overlay model.
8. No trusted metrics are changed.
9. No persistence is added.
10. No `.skatetrack` schema change is introduced.
11. `estimatedRouteActive` remains false.
12. `estimatedRouteDisplayEnabled` remains false.
13. `userVisibleDisplayAllowed` remains false.
14. Localizable keys exist in en, zh-Hant, and ja for panel text.
15. New Swift files stay under 500 lines.
16. b18-C verifier passes.
17. b18-B verifier passes.
18. b18-A verifier passes.
19. v1.2 alignment verifier passes.
20. Build passes.
21. XCTest passes.

---

## 14. Expected Product Status After b18-C

After b18-C, SkateTrack still must not expose estimated route display to general users.

Expected state:

```text
estimated route review panel: DEBUG-only
route geometry display: disabled
normal session map mutation: disabled
general-user estimated route: disabled
trusted metrics mutation: disabled
persistence/schema changes: none
product decision: still debug/review only
```

b18-C should prepare developer inspection for b18-D recheck. It should not change the product decision.
