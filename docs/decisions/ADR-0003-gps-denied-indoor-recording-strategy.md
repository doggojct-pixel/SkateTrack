# ADR-0003 — GPS-Denied Indoor Recording Strategy

**Date:** 2026-06-12  
**Status:** Accepted  
**Related Task:** Task-022d Documentation Alignment — GPS-Denied Indoor Recording Strategy  
**Decision Owner:** SkateTrack project development workflow

## Context

SkateTrack records riding sessions for skateboard and inline skating. Outdoor sessions can use GPS as the primary source for route, distance, and speed. Indoor skateparks, covered bowls, ramps, parking structures, and metal-roof venues often degrade or block GPS. In those environments, location samples may be missing, inaccurate, delayed, or jump across the map.

The project already has iOS sensor providers, `SensorFusionEngine`, `SessionRecordingCoordinator`, local persistence, Session History, Session Summary, Spot Management, and mock/local rideability. It also has an explicit product constraint: do not put DEBUG mock speed into normal runtime, do not pretend unavailable services are live, and do not present phone posture or raw IMU data as precise board movement.

Several future technologies could improve indoor tracking, including IMU-based inertial odometry, Core ML velocity estimation, ARKit visual-inertial odometry, and UWB venue anchors. These technologies are useful long-term directions, but they have different product shapes, hardware assumptions, privacy implications, calibration requirements, and reliability risks.

## Decision

SkateTrack will **not** implement production indoor speed or indoor route tracking during Task-023 through Task-030. GPS-denied indoor recording is a deferred capability. The current roadmap must continue toward the local-first release baseline instead of introducing unproven indoor odometry into normal runtime.

The earliest safe entry point is a future task after Task-030, recommended as:

> Task-031 — Recording Data Quality + Indoor Fallback Foundation

That first indoor-related task should not attempt to generate precise indoor speed or indoor routes. It should instead make recording data quality visible and honest:

- Show GPS quality, such as good, weak, unavailable, or indoor/low-confidence.
- Show speed source, such as GPS, unavailable, or low-confidence.
- Show route confidence in Live HUD / Summary where appropriate.
- Avoid drawing fake routes when location data is missing or unreliable.
- Avoid claiming precise indoor speed when only IMU data is available.
- Preserve sensor samples for future analysis without turning experimental estimates into product truth.
- Add an `IndoorOdometryProvider` boundary only as a future-facing interface, not as a production estimator.

## Product Safety Rule

When GPS is unavailable or unreliable, SkateTrack must degrade honestly:

- Do not fabricate route lines.
- Do not estimate user-facing distance from raw IMU integration in production.
- Do not label IMU-only output as accurate speed.
- Do not present phone absolute tilt as skateboard or inline-skate lean.
- Do not show indoor trajectory as precise unless a future task proves the data source and UX are production-ready.
- Do not hide low-confidence data behind polished charts that imply accuracy.

User-facing copy should prefer terms like reference, estimate, limited, low confidence, GPS unavailable, or route unavailable. It should not imply guaranteed safety, certified precision, or live venue-grade tracking.

## Deferred Technical Directions

### Phase 1b — Data Quality and Indoor Fallback

Goal: make existing recordings more trustworthy by exposing data confidence.

Recommended work:

- `LocationQuality` / `GPSQuality` model.
- `SpeedSource` model.
- `RouteConfidence` model.
- Live HUD GPS-quality indicator.
- Summary route-confidence note.
- No-route fallback for GPS-denied sessions.
- Optional indoor-session label that clearly states route and speed limitations.

Non-goal: precise indoor trajectory.

### Phase 2 — Dataset and Offline Experimentation

Goal: collect and export data that could support future analysis.

Recommended work:

- Export outdoor paired GPS + IMU samples for training / offline analysis.
- Add sensor-quality metadata to export packages.
- Add developer-only / offline experimentation boundaries.
- Evaluate Core ML or other inertial odometry approaches outside production runtime.

Non-goal: enabling IMU-only speed or indoor routes for all users.

### Phase 3 — ARKit Coach / Video Analysis Mode

Goal: support a separate coaching workflow where a phone is intentionally positioned to observe the rider.

ARKit visual-inertial odometry should be treated as a video / coach feature, not as a normal pocket-based session recorder. It may require:

- A phone on a tripod, held by a coach, or otherwise pointed at the skatepark.
- Camera permission and clear privacy copy.
- Good lighting and visible environmental features.
- A separate UI mode for video overlays, trick timing, height estimates, and trajectory visualization.

Non-goal: using ARKit for normal pocket / backpack / watch-only recording.

### Future / B2B — UWB Venue Mode

Goal: explore professional venue analytics only if the product later supports installed hardware.

UWB venue tracking should be treated as a hardware-supported B2B / venue feature. It may require:

- Installed anchors.
- Calibration workflow.
- Accessory compatibility review.
- Nearby Interaction lifecycle handling.
- Venue privacy / operations policy.

Non-goal: app-only consumer indoor tracking.

## Consequences

### Benefits

- Avoids shipping misleading indoor speed or route data.
- Preserves product trust for safety-adjacent riding analytics.
- Keeps Task-023 through Task-030 focused on local release readiness.
- Provides a clear future path without polluting current `GPSProvider`, `SensorFusionEngine`, or `SessionRecordingCoordinator` behavior.
- Keeps experimental odometry behind future provider boundaries rather than leaking it into Views.

### Trade-offs

- Indoor sessions may remain limited in Phase 1a.
- Users in indoor skateparks may see unavailable or low-confidence route / speed states.
- More advanced indoor analytics will require later tasks, more validation, and possibly additional permissions or hardware.

## Explicit Non-goals for Task-023 through Task-030

- No IMU-only production speed.
- No IMU-integrated route drawing.
- No Core ML indoor velocity model in normal runtime.
- No ARKit tracking inside the normal ride recorder.
- No UWB / Nearby Interaction venue tracking.
- No changes to GPSProvider, IMUProvider, SensorFusionEngine, or FallDetectionEngine algorithms for indoor positioning.
- No fake data to make indoor sessions look complete.
- No new permissions, capabilities, signing changes, or hardware assumptions.

## Interaction with Existing ADRs

This ADR complements ADR-0001 and ADR-0002:

- Subscription-gated future indoor features must still use `FeatureFlagEngine`, `useSubscriptionStatus`, and the existing entitlement provider strategy.
- Any ARKit, UWB, external service, or hardware-backed future integration must follow provider-boundary, disabled-provider, privacy-copy, and capability-review rules before it reaches production.
- Current mock or development-only behavior must never be presented as a completed production tracking capability.
