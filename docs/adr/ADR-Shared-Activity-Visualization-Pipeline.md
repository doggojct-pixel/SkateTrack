# ADR — Shared Activity Visualization Pipeline

**Status:** Accepted / documented from already-merged Task-031-prep baseline
**Date:** 2026-07-06
**Aligned Build Plan:** `SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md`
**Aligned subtask:** `Task-031a — Develop Baseline Lock + Source-of-Truth Preflight`

## Context

Task-031-prep introduced the Shared Activity Visualization pipeline before Phase 1b Watch implementation begins. The pipeline prepares route, speed, elevation, unified visualization output, and Watch-ready compact summaries from existing session data and motion samples.

Task-031a documents this already-merged architecture so later Watch UI tasks can consume the shared display contract without reimplementing route, speed, or elevation semantics inside watchOS UI files.

## Decision

Shared decides visualization data semantics. Platforms decide rendering.

`Shared/ActivityVisualization` owns display-only route, speed, elevation, diagnostics, unified visualization, and compact summary semantics. iOS, macOS, and future watchOS renderers consume those display-ready outputs and remain responsible only for presentation.

## Baseline components

```text
Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift
Shared/ActivityVisualization/ActivityVisualizationDiagnostics.swift
Shared/ActivityVisualization/ActivityVisualizationPipeline.swift
Shared/ActivityVisualization/ActivityVisualizationQuality.swift
Shared/ActivityVisualization/Route/
Shared/ActivityVisualization/Speed/
Shared/ActivityVisualization/Elevation/
Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift
```

Core compact output types:

```text
ActivityVisualizationCompactSummary
CompactRouteDisplay
CompactSpeedSparkline
CompactElevationProfile
```

## Boundaries

Task-031a records the following boundaries:

- No Watch UI implementation.
- No Watch recording implementation.
- No WatchBridge implementation.
- No Snow production implementation.
- No route geometry mutation.
- No trusted metric mutation.
- No estimated route enablement.
- No package schema mutation.
- No Core Data mutation.
- No platform UI framework imports inside `Shared/ActivityVisualization`.

## Consequences

Future Watch UI tasks should consume compact visualization outputs where scoped by the active plan. They must not reimplement route filtering, route segmentation, speed sparkline semantics, or elevation profile semantics inside watchOS UI.

If a future task discovers missing watchOS source membership for Shared ActivityVisualization files, that is a scoped Task-031b membership issue. It must not be confused with the expected zero watchOS compact consumption before the Watch UI subtasks.
