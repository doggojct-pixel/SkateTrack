# SkateTrack ADR Index

**Status:** Active index — Task-030b consolidation
**Last Updated:** 2026-06-13
**Purpose:** Preserve the historical meaning of old ADRs while moving daily rules and Pre-ADP limitations into consolidated documents.

Task-030b removes the old ADR single files from the active docs tree to reduce fragmentation. Their decisions remain summarized here. Use this index to understand where a decision now lives.

## Active documentation after consolidation

| Active file | Owns |
|---|---|
| `docs/process/DEVELOPMENT_RULES.md` | Recurring development workflow, scope-control, localization, macOS layout, hotfix, commit, and verification rules. |
| `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` | Blocked features, external-service constraints, unlock conditions, and no-overclaim rules. |
| `docs/release/RELEASE_READINESS_PRE_ADP.md` | Pre-ADP release-readiness gate. |
| `docs/release/MANUAL_QA_MATRIX_PRE_ADP.md` | Manual QA matrix and release-blocking checks. |
| `docs/DOCUMENTATION_INDEX.md` | Reading order and documentation source-of-truth map. |

## Historical ADR mapping

| Old ADR | Historical decision | Current status | Consolidated into |
|---|---|---|---|
| ADR-0001 Subscription Entitlement Strategy | Paid features use replaceable entitlement providers and DEBUG / local simulation before production StoreKit. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-001 |
| ADR-0002 Developer Account Dependent Services | Google, Drive, WeatherKit, StoreKit, and other external-account services must remain disabled / provider-boundary only before credentials. | Consolidated | `KNOWN_LIMITATIONS_PRE_ADP.md`, `DEVELOPMENT_RULES.md` |
| ADR-0003 GPS-Denied Indoor Recording Strategy | Do not fake indoor speed / route; indoor fallback and ARKit / UWB are deferred. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-008 |
| ADR-0004 Export Targets and Package Strategy | Share-card export, backup package, and portable `.skatetrack` package are separate export types. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-007 |
| ADR-0005 Achievements and Challenges Scope Strategy | Achievements and weekly challenges are local-first; social / remote / Game Center style features are deferred. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` |
| ADR-0006 Backup Provider and Package Strategy | Local backup package and restore preview exist; Drive sync and destructive restore remain blocked. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-003 |
| ADR-0007 Portable `.skatetrack` Package Strategy | `.skatetrack` is a portable local package; macOS viewer is read-only; custom UTType / document association deferred. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-007 |
| ADR-0008 Real-device Background GPS Recording | Background GPS recording is implemented but requires real-device release validation. | Consolidated | `KNOWN_LIMITATIONS_PRE_ADP.md` L-008, `MANUAL_QA_MATRIX_PRE_ADP.md` |
| ADR-0009 Localization and Privacy Copy Strategy | Active languages are English, Traditional Chinese, and Japanese; localization key / placeholder parity is required. | Consolidated | `DEVELOPMENT_RULES.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` L-010 / L-011 |
| ADR-0010 Accessibility, Privacy Copy, and UX Quality Gate | Accessibility and privacy-copy checks are required before release-readiness closure. | Consolidated | `DEVELOPMENT_RULES.md`, `RELEASE_READINESS_PRE_ADP.md`, `MANUAL_QA_MATRIX_PRE_ADP.md` |
| ADR-0011 Pre-ADP Release Readiness Strategy | Task-030 is a Pre-ADP quality gate, not a production-service unlock task. | Consolidated | `RELEASE_READINESS_PRE_ADP.md`, `KNOWN_LIMITATIONS_PRE_ADP.md` |

## Future ADR rule

New ADR files should be rare. Add a new ADR only when a decision is too specific or too consequential to fit into:

- `DEVELOPMENT_RULES.md`
- `KNOWN_LIMITATIONS_PRE_ADP.md`
- `RELEASE_READINESS_PRE_ADP.md`
- `MANUAL_QA_MATRIX_PRE_ADP.md`

If a new ADR is added later, update this index with:

- ADR number and title.
- Decision summary.
- Current status.
- Owning active documentation file.
- Future reopen condition.

Task-030b verification token: ADR index consolidated.

## Task-030c decision note — Core Location Diagnostics Package Strategy

| Decision | Summary | Status | Owning active docs |
|---|---|---|---|
| Task-030c-a Core Location diagnostics package extension | Keep `.skatetrack` `schemaVersion = 1`, add optional diagnostics fields and optional package `formatCapabilities` (`location-diagnostics-v1`, `route-quality-summary-v1`), and treat Core Location fixes as accuracy / freshness / confidence-bearing data instead of assuming every coordinate is GPS-grade. | Active | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` |
| Real-device evidence handling | `20260613-110119` is the real-device route / speed fidelity baseline. `20260612-180037` is a simulator / compatibility reference and must not support real-device GPS claims. | Active | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md` |
| Deferred route inference | Road snapping, map matching, route replay, smoothing, and Snow Mode route semantics are deferred until raw location diagnostics and high-accuracy recording policy are validated. | Deferred | `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` |
| Task-030c-b High-accuracy outdoor recording policy | Active ride recording should request `kCLLocationAccuracyBestForNavigation`, 1-meter distance filtering, `.fitness` activity type, no automatic pausing, and active GPS policy whenever the mode priority plan includes GPS in primary, secondary, or supplemental channels. | Active | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` |
| Task-030c-b DEBUG simulated route | Simulator route diagnostics may generate DEBUG-only skating-like location, speed, altitude, and accuracy samples, but they must be marked with `debugSimulated` / `debug-simulated-route-v1` and must never be treated as real-device evidence or production fallback. | Active | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, `docs/process/DEVELOPMENT_RULES.md` |
| Task-030c-b2 Navigation-grade Location Continuity | Screen-off pocket recording requires iOS background location mode, `allowsBackgroundLocationUpdates`, Always-location upgrade when available, significant-change backup, and lower-confidence fix retention with diagnostics instead of silently dropping every fix above 35 m. | Active / real-device validation required | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` |

Task-030c-b verification token: Core Location diagnostics, route-quality-summary-v1, High-accuracy outdoor recording policy, DEBUG simulated route, debug-simulated-route-v1, road snapping deferred.

Task-030c-b2 verification token: Navigation-grade Location Continuity, screen-off pocket, background location mode, navigation-continuity-diagnostics-v1, road snapping deferred.

| Task-030c-b3 Route recording recovery | Route distance, charts, fall events, and summary navigation must be recovered from real-device validation failures before Task-030c-b can be committed. Summary distance may reconcile against route-quality distance, charts must be gap-aware, fall events must be scoped to the active session, and route previews must split long / low-confidence gaps instead of rendering them as precise continuous lines. | Active / real-device validation required | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` |

Task-030c-b3 verification token: Navigation-grade Route Recording Recovery, route-recording-recovery-v1, gap-aware charts, floating bottom return, road snapping deferred.

| Task-030c-b4 Raw CLLocation stream persistence | Navigation-style recording must persist every accepted Core Location fix as its own raw location-fix sample rather than relying only on timer-fusion samples that may repeat the last coordinate or be throttled in background conditions. Timer-fusion samples remain for IMU continuity; route aggregation deduplicates raw fixes and rejects long-gap / low-confidence segments for trusted summary distance. | Active / real-device validation required | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` |

Task-030c-b4 verification token: Raw CLLocation Stream Persistence, raw-location-stream-v1, raw location fix stream, road snapping deferred.

| ADR-0016 | Activity-Aware Location, Speed & Altitude Fidelity | Accepted | Task-030c-b5 replaces single skateboard-only speed / altitude assumptions with deterministic activity profiles: technical skateboard, standard skateboard, electric skateboard, inline recreation, inline speed, snow-reserved future use, and vehicle validation. Core ML / Apple on-device AI may later plug into the confidence boundary, but current recording must work without Apple Intelligence. |

Task-030c-b5 verification token: Activity-Aware Location, Speed & Altitude Fidelity, activity-aware-fidelity-v1, altitude-source-stabilization-v1, Core ML optional, road snapping deferred.


| Task-030c-b6 Debug Tools Status Panel Polish | Debug Tools must provide tester-readable diagnostics and a visible task-build signature without changing GPS / fidelity runtime behavior. The build signature uses `Task-030c-b6` only as a DEBUG test marker, not as production versioning. | Active / UI polish | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md` |

Task-030c-b6 verification token: Debug Tools Status Panel Polish, Task-030c-b6, debug-build-signature-card, session-recording-preview-panel.

| Task-030c-b7 Background Recording Gap Diagnostics | While GPS fidelity remains blocked by real-device screen-off / pocket testing, SkateTrack will temporarily write DEBUG-only event-based diagnostics into exported `.skatetrack` packages. These diagnostics must help distinguish app lifecycle / protected data transitions, Core Location callback gaps, recording heartbeat gaps, authorization changes, location manager configuration, filter decisions, and altitude confidence without changing production package schema or exposing a normal user UI. | Active / temporary diagnostics | `docs/history/DEV_LOG.md`, `docs/reference/FILE_STRUCTURE.md`, `docs/release/KNOWN_LIMITATIONS_PRE_ADP.md` |

Task-030c-b7 verification token: Background Recording Gap Diagnostics, debug-recording-diagnostics-v1, background-gap-diagnostics-v1, DEBUG-only, protected data.


- Task-030c-b8: DEBUG recording context labels remain DEBUG-only diagnostics metadata. They may describe real-world test scenarios, but they must not alter Core Location configuration, production recording behavior, package schema semantics, or SnowPrototype isolation.

- Task-030c-b9: GPS branch diagnostics export must prove whether a real-device `.skatetrack` file was created by the current diagnostics build. Exported debug diagnostics may report `enabled`, `enabledButNoEventsRecorded`, or `disabledByBuildConfiguration`, and package capabilities include `debug-build-identity-v1` plus `diagnostics-export-status-v1` when the optional diagnostics block is present. This remains a temporary Pre-ADP diagnostics mechanism and must not be treated as production telemetry.

- Task-030c-b9-r1: Background diagnostics export must survive the local Core Data save / fetch round trip before `.skatetrack` export. Persisted sessions now carry optional `debugRecordingDiagnosticsData`; exports fall back to `missingFromPersistedSession` for older records that lack runtime diagnostics. This is a temporary Pre-ADP diagnostics mechanism, not production telemetry or a GPS algorithm change.

Task-030c-b9-r1 verification token: Persist Diagnostics Through Session Export, Task-030c-b9-r1, Core Data, debugRecordingDiagnosticsData, missingFromPersistedSession.

- Task-030c-b10: The GPS branch must distinguish effective iOS app-bundle background-location runtime enablement from project-file intent. SkateTrack-iOS now uses an explicit `iOS/App/Info.plist` with `UIBackgroundModes/location`, records bundle-info diagnostics in exported packages, and applies conservative gap-recovery quality gates so stale / low-accuracy fixes are preserved as diagnostics but not counted as trusted movement.

Task-030c-b10 verification token: Effective Background Location Runtime + Gap Recovery Quality Gate, Task-030c-b10, UIBackgroundModes, gap-recovery, trusted metrics.

- Task-030c-b10-r2: GPS fidelity startup stabilization must suppress coordinate-derived speed spikes and lock-screen / pocket handling fall false alerts during the first seconds of recording without deleting raw GPS or raw IMU samples. Startup guard fixes must not perform route smoothing, road snapping, map matching, or fabricate geometry.

Task-030c-b10-r2 verification token: Startup Speed Spike + Fall Handling Guard, Task-030c-b10-r2, startup guard, coordinate-derived speed, fall handling.

- Task-030c-b10-r3: GPS fidelity metric reliability must separate raw sensor retention from trusted summary metrics. Low-speed residential / small-area GPS jumps, poor-accuracy Core Location speeds, and startup altitude drift are kept in raw diagnostics but excluded from max speed, trusted distance, and elevation gain. Export and startup paths should avoid visible UI stalls before later route geometry stabilization work begins.

Task-030c-b10-r3 verification token: Low-Speed Metrics Gate + UI Responsiveness, Task-030c-b10-r3, low-speed metrics gate, barometer-relative elevation, export responsiveness.


- Task-030c-b10-r4: Trusted metrics must not treat Core Location speed or absolute altitude as authoritative during low-speed residential tests. Strict low-speed metrics reject small-area GPS artifacts when accuracy / segment shape is not reliable, and altitude source isolation prefers barometer-relative gain whenever available before falling back to Core Location altitude.

Task-030c-b10-r4 verification token: Strict Low-Speed Metrics + Altitude Source Isolation, Task-030c-b10-r4, strict low-speed metrics, altitude source isolation, barometer-relative elevation.
Task-030c-b10-r4 compatibility token: Background Location Runtime + Gap Recovery Quality Gate, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard, low-speed metrics gate, startup guard.

- Task-030c-b10-r5: Summary charts must align with trusted metric sources instead of drawing raw Core Location instantaneous speed or raw Core Location absolute altitude directly. Raw values remain preserved in diagnostics and export payloads, but user-facing speed and elevation charts use trusted display series, smoothing, and barometer-relative altitude where available.

Task-030c-b10-r5 verification token: Trusted Chart Metrics + Display Source Alignment, Task-030c-b10-r5, trusted chart metrics, display source alignment.
Task-030c-b10-r5 compatibility token: Strict Low-Speed Metrics + Altitude Source Isolation, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard.

- Task-030c-b11: Session Summary route rendering must separate `rawRoute`, `trustedRoute`, and `displayRoute`. Raw GPS and IMU samples remain preserved in diagnostics and export payloads, while the user-facing Summary map uses trusted location fixes, small-area jitter suppression, and light display smoothing so low-speed residential loops do not show timer-fusion repeats or obvious GPS drift as the primary route geometry.

Task-030c-b11 verification token: Small-Area Route Geometry Stabilization, Task-030c-b11, rawRoute, trustedRoute, displayRoute, small-area jitter suppression.
Task-030c-b11 compatibility token: Trusted Chart Metrics + Display Source Alignment, Strict Low-Speed Metrics + Altitude Source Isolation, Low-Speed Metrics Gate + UI Responsiveness.

## Task-030c-b11-r1 — Route confidence display continuity

- Low-confidence route fixes are not equivalent to missing data. The Summary map should display them as uncertain secondary route segments rather than cutting the visible route whenever a segment is downgraded by the current activity profile.
- True route breaks remain reserved for actual temporal gaps or large coordinate jumps. Raw GPS and diagnostics stay preserved, while the display route communicates confidence without fabricating higher precision.
- This decision does not claim small-area loops are accurate and does not introduce IMU reconstruction, skateboard S-curve presentation, road snapping, or map matching.

Task-030c-b11-r1 verification token: Route Confidence Display Continuity, Task-030c-b11-r1, uncertain route segment, low-confidence display continuity.

## Task-030c-b11-r2 — Activity-aware route confidence display gates

- Task-030c-b11-r2 requires live route confidence, Summary map display gates, and Summary chart continuity to use the resolved activity fidelity profile. Electric longboard, vehicle-validation, and future snow-proxy sessions must not be judged by standard-skateboard speed and segment-distance limits, while walking / small-area sessions keep conservative display filtering for poor-accuracy fixes.

Task-030c-b11-r2 verification token: Activity-Aware Route Confidence + Small-Area Display Gate, Task-030c-b11-r2, activity-aware route confidence, small-area display gate.


Task-030c-b11-r2 compatibility token: altitude source isolation, Strict Low-Speed Metrics + Altitude Source Isolation.


## Task-030c-b11-r3-3 — Post-record GPS lock guard and approximate start semantics

- Task-030c-b11-r3-3: Summary route rendering must separate approximate recording-start markers from the GPS lock route anchor. The start marker may be approximate when GPS is still converging, while trusted green route geometry must wait for a confirmed GPS-lock cluster.
- Task-030c-b11-r3-3: Electric skateboard / electric longboard startup rendering must keep medium-confidence post-record convergence fixes as red warm-up context until GPS lock is confirmed, avoiding a misleading green route start.
- Task-030c-b11-r3-3: Primary Summary Map region should prefer post-GPS-lock route coordinates when available; early convergence points should not pull the region away from the trusted route.
- Task-030c-b11-r3-3: Summary Map may disclose route accuracy limits for startup warm-up or small-area sessions; this is preferred over over-smoothing or fabricating 1m-level route geometry.

Task-030c-b11-r3-3 verification token: Post-Record GPS Lock Guard + Approximate Start Semantics, Task-030c-b11-r3-3, GPS lock route anchor, approximate start marker, startup convergence warm-up, GPS warming up, session-route-accuracy-disclosure.

## Task-030c-b11-r4-1 — Diagnostics-only route continuity foundation

- Task-030c-b11-r4-1 is a diagnostics-only foundation for future sensor-fusion route continuity. It may record heading availability, GPS gap diagnostics, and dead-reckoning readiness, but it must not generate estimated route geometry or mutate trusted distance / speed / altitude metrics.
- GPS gap diagnostics should be based on raw Core Location timestamp spacing and timer-fusion repeat context, not on the 10Hz timer cadence alone.
- Heading diagnostics in r4 use conservative Core Location course-over-ground availability only. Device magnetometer heading remains deferred until a separate heading-provider task.
- Optional fields under `LocationFixDiagnostics` preserve legacy plaintext `.skatetrack` compatibility.

Task-030c-b11-r4-1 verification token: diagnostics-only foundation, GPS gap diagnostics, HeadingDiagnostics, GPSGapDiagnostics, DeadReckoningDiagnostics, Task-030c-b11-r4-1.


### Task-030c-b11-r4-1 XCTest regression stabilization
- Task-030c-b11-r4-1 keeps the r4 diagnostics-only route-continuity foundation unchanged while stabilizing XCTest coverage after the r4 schema expansion.
- It removes UI-framework imports from the core SessionRecording coordinator boundary and keeps r4 diagnostics persistence covered by repository tests.


## Task-030c-b12-A — Altitude outlier guard and per-sample diagnostics

- Task-030c-b12-A treats altitude as an independently trusted telemetry component. A rejected altitude value must not delete or invalidate the full `MotionSample`; horizontal coordinates, distance logic, and route rendering remain isolated from altitude trust decisions.
- `MotionSample.altitudeDiagnostics` is optional for legacy `.skatetrack` compatibility and records raw altitude, trusted altitude, trust classification, rejection reason, vertical accuracy, altitude delta, vertical speed, and whether the trusted altitude anchor was updated.
- `AltitudeOutlierGuard` keeps CoreLocation absolute altitude and barometer-relative altitude anchors source-isolated. b12-A does not blend these sources, does not create fake barometer values, and does not implement pressure LPF or long-term atmospheric drift correction.
- Live and final elevation-gain logic may consume trusted altitude diagnostics when present. Rejected outliers and low-confidence altitude samples must not inflate `elevationGainMeters`.

Task-030c-b12 verification token: component-level altitude isolation, source-isolated altitude anchors, AltitudeDiagnostics, AltitudeOutlierGuardConfig, AltitudeOutlierGuard, no estimated route geometry.

Task-030c-b12 package capability token: altitude-diagnostics-v1.

## Task-030c-b12-B — Pressure smoothing diagnostics foundation

- Task-030c-b12-B extends the b12-A altitude trust model with diagnostics-only pressure smoothing metadata for barometer-relative samples.
- `AltitudePressureFilter` uses a deterministic low-pass filter and raw-step clamp to disclose pocket-pressure / Venturi-like spikes without mutating route geometry, trusted distance, trusted speed, or trusted altitude policy.
- Pressure diagnostics are nested under optional `AltitudeDiagnostics.pressureDiagnostics`, preserving legacy `.skatetrack` compatibility and b12-A component-level altitude isolation.
- CoreLocation absolute altitude and barometer-relative altitude remain source-isolated. b12-B does not perform atmospheric drift correction, pressure-to-absolute-altitude conversion, blended altitude, IMU dead reckoning, Wi-Fi RTT, or indoor localization.

Task-030c-b12-B verification token: AltitudePressureDiagnostics, AltitudePressureFilterConfig, AltitudePressureFilter, pressureDiagnostics, diagnostics-only pressure smoothing, horizontal coordinates, distance logic, and route rendering remain isolated.


## Task-030c-b13-A-4 — Route Confidence Visual + Freebord Confidence Calibration

- Low-confidence route fixes should remain visible, but they should no longer look like broken or missing route data. b13-A renders uncertain route segments as solid fluorescent-pink geometry with the same visual weight as trusted teal/green route segments.
- Startup warm-up remains visually separate and dashed because it represents approximate GPS lock semantics, not merely lower confidence after GPS is present.
- The suspicious CoreLocation-speed outlier gate is semantically tied to CoreLocation reporting a valid speed. Coordinate-derived speed must not substitute into the suspicious CoreLocation-speed gate, because that causes false low-confidence classifications for low-speed freebord riding under tree canopy when `CLLocation.speed` is unavailable.
- The coordinate-derived local-jump gate remains unchanged and continues to reject genuinely implausible GPS jumps.

Task-030c-b13-A-4 verification token: solid bright-orange low-confidence route style with solid fluorescent-pink startup/warm-up styling, coordinate-derived speed must not substitute into the suspicious CoreLocation-speed gate, freebord confidence calibration, startup warm-up rendered as solid fluorescent pink, no estimated route geometry.


## Task-030c-b13-A-4 — Display Metrics + Altitude Anchor + Route Color Semantics

Decision: keep recorded samples immutable and correct History/Summary presentation through a display-derived metrics layer. Low-confidence route confidence is no longer treated as the same thing as metric ineligibility; fresh/recent samples with usable horizontal accuracy can contribute to displayed distance and speed. Barometer-relative altitude remains the stable profile source, but charts display it against a trusted absolute CoreLocation anchor when available. Route visual semantics are now teal = trusted, bright orange = low confidence/uncertain, fluorescent pink = startup/warm-up/approximate start.

Task-030c-b13-A-4 verification token: display-derived metrics, absolute elevation display anchor, diagnostics speed fallback, solid bright-orange low-confidence route segments, solid fluorescent-pink startup warm-up segments.

## Task-030c-b13-B-1 — Magnetometer Heading Diagnostics Foundation

Decision: collect device magnetometer heading as diagnostics-only route-continuity metadata. CoreLocation course-over-ground remains useful when movement speed is sufficient, while device heading can describe absolute heading availability during GPS gaps or low-speed movement. The two heading signals are recorded separately with accuracy, age, and agreement metadata.

Boundary: b13-B must not generate estimated route geometry, must keep `estimatedRouteActive` false, and must not change distance, speed, altitude, display-derived metrics, route color semantics, or SnowPrototype.

Task-030c-b13-B-1 verification token: device magnetometer heading diagnostics, course/device heading agreement, diagnostics-only heading readiness, no dead reckoning route reconstruction.

## Task-030c-b15-B-3 — Replay-Only Dead-Reckoning Readiness Diagnostics

Decision: Task-030c-b15-B-3 adds only replay-only readiness classification for future IMU-aided route continuity. It analyzes persisted samples for gap duration, trusted anchors, timer-fusion cadence, heading availability, heading age, and heading accuracy, but it does not create estimated coordinates or mutate production route data.

Rationale: b13-B-1 provides magnetometer/device heading diagnostics, but real dead reckoning remains risky without replay evidence. The next safe step is to measure whether sessions are eligible for future interpolation while keeping route geometry, distance, speed, altitude, and summary metrics unchanged.

Task-030c-b15-B-3 verification token: replay-only readiness, DeadReckoningReadinessAnalyzer, estimatedRouteActive remains false, preserves b13-A-4 display/altitude behavior, preserves b13-B-1 legacy decode compatibility.


## Task-030c-b15-B-3 — Altitude Chart Source Guard

Decision: Task-030c-b15-B-3 is a display-only altitude source guard. When a session has trusted barometer-relative altitude, the elevation chart should use that altitude stream continuously and should not split the profile merely because GPS location diagnostics report stale fixes or background gaps. Raw altitude fallback remains only for legacy packages without altitude diagnostics.

Boundary: route geometry remains unchanged, stored samples are not rewritten, summary metrics are not recalculated, and dead reckoning remains disabled.

Task-030c-b15-B-3 verification token: display-only altitude source guard, barometer-relative profile continuity, route geometry remains unchanged, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Altitude Chart Micro-Dip Display Guard

Decision: Task-030c-b15-B-3 adds a display-only guard for very short barometer notches in the advanced elevation chart. The guard is intentionally conservative: it only adjusts chart points when nearby left and right baselines agree, the center point is a sharp local dip, and the local span is short.

Non-goals: no stored sample rewrite, no elevation gain recalculation, no route geometry mutation, no recording-pipeline altitude change, no dead reckoning enablement, no road snapping, no map matching.

Task-030c-b15-B-3 verification token: display-only guard for very short barometer notches, route geometry remains unchanged, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Startup Route Visual Suppression

Decision: Task-030c-b15-B-3 applies visual-only suppression to startup / GPS warm-up route segments. Startup geometry remains available as solid fluorescent-pink route context with route accuracy disclosure, full route-line weight, and clear separation from the first trusted GPS-lock segment. Raw samples and diagnostics remain immutable. Distance, speed, altitude, route geometry, and exported diagnostics are unchanged.

Task-030c-b15-B-3 verification token: visual-only suppression, startup route visual suppression, solid fluorescent-pink route context, route geometry remains unchanged, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Replay-Only Candidate Gap Interpolation Prototype
Decision: Task-030c-b15-B-3 may generate candidate interpolation points only as replay/debug diagnostics. Candidate points are derived from existing readiness candidates and trusted pre/post GPS anchors, but they are not production route geometry and must never affect distance, speed, altitude, summaries, exports, or persisted motion samples.

Task-030c-b15-B-3 verification token: replay-only candidate gap interpolation, debug-only candidate points, anchor closure blocking, solid fluorescent-pink startup/warm-up route context, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Summary Elevation Gain Source Guard
- Decision: Task-030c-b15-B-3 aligns the Summary climb card with the trusted altitude-source policy already used by the advanced elevation chart. When trusted barometer-relative altitude exists, Core Location absolute altitude remains available for diagnostics/export but must not inflate user-facing `elevationGainMeters`.
- The display layer can return a zero-meter climb when trusted altitude samples are flat instead of falling back to an older persisted climb value merely because the recomputed display gain is zero.
Task-030c-b15-B-3 verification token: summary elevation gain source guard, trusted barometer-relative climb, Core Location absolute altitude diagnostics only, route geometry remains unchanged, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Total Elevation Gain Terminology
- Decision: the Summary and share-card elevation-gain metric should use explicit cumulative-gain terminology. The Traditional Chinese label changes from `爬升` to `總爬升量`; English changes to `Total elevation gain`; Japanese changes to `総獲得標高`.
- Rationale: after b14-B-1 fixed the trusted altitude-source display calculation, the shorter Traditional Chinese term could be misread as current climb or net elevation difference. The new label makes the cumulative positive-gain semantics clearer without changing the numeric definition.
- Boundary: terminology-only. No stored sample rewrite, no schema change, no route geometry mutation, no distance/speed/altitude-chart change, no summary calculation change, no production dead reckoning.

Task-030c-b15-B-3 verification token: total elevation gain terminology, localized summary.metric.elevationGain labels, cumulative positive elevation gain semantics, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Simulator Recording Persistence Guard
- Decision: DEBUG iOS Simulator recordings should be persistable for development even when CoreLocation / IMU provider behavior differs from a real device and the sensor stop snapshot is empty.
- The coordinator may recover coordinator-observed live samples into the saved session on Simulator. If no samples were observed before stop, a small DEBUG-only `DebugOutdoorRouteSimulator` fallback sample set may be persisted so the developer can verify the save/history flow.
- Boundary: this is not production dead reckoning, not route reconstruction, not map matching, and not a `.skatetrack` schema change. Real-device recording remains governed by the normal sensor pipeline.

Task-030c-b15-B-3 verification token: simulator recording persistence guard, coordinator-observed sample recovery, debug simulator fallback, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Debug Mock Recording Pipeline Hardening
- Decision: simulator/debug recording must not depend on incomplete CoreMotion runtime preferences. DEBUG mock samples are delivered on the main queue, appended to the same coordinator buffer observed by the Live HUD, and session history reloads after saves.
- Boundary: simulator/debug-only pipeline hardening; no production route estimation, no schema change, no metric calculation change, and `estimatedRouteActive` remains false.
Task-030c-b15-B-3 verification token: debug mock recording pipeline, main-queue mock samples, history save notification, Live HUD trace, estimatedRouteActive remains false.

## Task-030c-b15-B-3 — Simulator Save Pipeline Hardening
- Decision: simulator/debug recording persistence must tolerate optional diagnostics encoding failures and legacy/corrupt History rows. Motion sample files and Core Data rows must be saved as one verified operation; if the Core Data row fails, the just-written sample file is cleaned up instead of becoming an invisible orphan.
- The History fetch path is resilient to individual legacy/corrupt rows so one bad row or missing sample file cannot make the whole History screen look empty after a simulator save.
Task-030c-b15-B-3 verification token: simulator save pipeline hardening, safeEncodedDebugRecordingDiagnostics, non-conforming float encoding, orphan sample cleanup, resilient History fetch, estimatedRouteActive remains false.

## Task-030c-b16-A — Localization Foundation Audit

Decision: Task-030c-b16-A is a repo-local planning and audit checkpoint before adding new sensor-source diagnostics. It documents the post-b15-B-3 localization foundation, confirms that existing altitude diagnostics, heading diagnostics, route-confidence display semantics, simulator recording persistence, and replay-only dead-reckoning readiness already exist, and defines the b16-B/C/D implementation boundaries.

Boundary: b16-A does not change production route geometry, trusted distance, speed, average speed, max speed, moving ratio, total elevation gain, raw sample persistence, or `.skatetrack` schema. The only Swift-side change allowed in this milestone is the DEBUG build identity advancing to `Task-030c-b16-A`.

Future sequence: b16-B is diagnostics-only barometric GPS cross-validation, b16-C is passive Wi-Fi RTT / accuracy-source diagnostics without explicit Wi-Fi APIs, and b16-D is magnetometer heading quality consolidation for future replay readiness. b17 remains replay-only. b18 estimated route display requires a product decision checkpoint after b17-D real-session replay review. Task-031 owns indoor localization.

Task-030c-b16-A verification token: Localization Foundation Audit, Task-030c-b16-A, barometric GPS cross-validation, passive Wi-Fi RTT diagnostics, magnetometer heading quality, IMU replay-only gap interpolation, indoor localization deferred to Task-031, estimatedRouteActive remains false.

## Task-030c-b16-B — Barometric GPS Outlier Cross-Validation Diagnostics

Decision: Task-030c-b16-B adds diagnostics-only cross-validation between suspicious GPS jumps and barometer-relative altitude evidence. The decision model records whether a candidate GPS fix would be rejected if a future production gate were enabled, but production route acceptance is not changed in this milestone.

Boundary: `productionRouteDecisionApplied` must remain `false`; `wouldRejectIfGateWereEnabled` is diagnostic evidence only. b16-B must not mutate raw samples, route geometry, trusted distance, speed, average speed, max speed, moving ratio, total elevation gain, persistence schema semantics beyond optional Codable diagnostics, or production estimated route display. `estimatedRouteActive` remains false.

Implementation: The shared model lives in `Shared/Models/BarometricGPSOutlierDiagnostics.swift`; iOS evaluation lives in `iOS/Core/SensorEngine/BarometricGPSOutlierGuard.swift` and `SensorFusionEngine+BarometricGPSOutlierDiagnostics.swift`; the existing `LocationFixDiagnostics` model stores the optional `barometricGPSOutlierDecision` so legacy sessions decode without the field.

Task-030c-b16-B verification token: barometric GPS outlier cross-validation diagnostics, `productionRouteDecisionApplied: false`, `wouldRejectIfGateWereEnabled`, optional legacy decode, no production route rejection, estimatedRouteActive remains false.

## Task-030c-b16-C — Passive Wi-Fi RTT / Accuracy Source Diagnostics

Decision: Task-030c-b16-C adds passive accuracy-source diagnostics derived only from CoreLocation-provided accuracy, freshness, and route-confidence evidence. The diagnostic can classify a fix as likely high-precision GPS or possible Wi-Fi RTT assisted, but it remains an inference and does not confirm Wi-Fi RTT.

Boundary: `passiveInferenceOnly` is always true, `explicitWiFiAPIUsed false`, and `wifiRTTConfirmed false`. This milestone does not add Wi-Fi scanning, Wi-Fi entitlement, explicit Wi-Fi APIs, road snapping, map matching, route geometry mutation, trusted metric mutation, production route rejection, or estimated route display. `estimatedRouteActive` remains false.

Implementation: The shared diagnostic model lives in `Shared/Models/LocationAccuracySourceDiagnostics.swift`; iOS classification lives in `iOS/Core/SensorEngine/LocationAccuracySourceClassifier.swift`; `LocationFixDiagnostics` stores optional `locationAccuracySourceDiagnostics` so legacy sessions decode without the new field.

Task-030c-b16-C verification token: passive Wi-Fi RTT / accuracy source diagnostics, passiveInferenceOnly, explicitWiFiAPIUsed false, wifiRTTConfirmed false, no Wi-Fi entitlement, no Wi-Fi scanning, estimatedRouteActive remains false.

## Task-030c-b16-D — Magnetometer Heading Quality Consolidation

Decision: Task-030c-b16-D consolidates existing course and device-magnetometer heading diagnostics into a formal heading reliability assessment for future replay-only IMU interpolation. The classifier consumes already-persisted `HeadingDiagnostics` and does not introduce a new production route decision.

Boundary: b16-D is replay-readiness diagnostics only. It must not create production estimated route geometry, enable estimated route display, rewrite GPS samples, rewrite route geometry, or change trusted distance, speed, average speed, max speed, moving ratio, or total elevation gain. `estimatedRouteActive` remains false.

Implementation: The shared model lives in `Shared/Models/HeadingQualityDiagnostics.swift`; the iOS-only classifier lives in `iOS/Core/SensorEngine/HeadingQualityClassifier.swift`. The implementation intentionally avoids adding new logic to oversized legacy files beyond DEBUG build identity updates.

Task-030c-b16-D verification token: magnetometer heading quality consolidation, HeadingReliability, HeadingQualityAssessment, HeadingQualityClassifier, replay-readiness only, no production estimated route geometry, estimatedRouteActive remains false.

## Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation

Decision: Task-030c-b17-0 preserves the already-pushed localization diagnostics review pack as a preflight/foundation checkpoint before the true v1.2 b17-A replay-only IMU work begins. It consolidates the b16-A/B/C/D diagnostics into a replay-only review pack model and builder. The pack summarizes barometric GPS outlier evidence, passive accuracy-source inference, heading reliability, and safety flags so later review workflows can compare real sessions without enabling production route correction.

Boundary: b17 is diagnostics-only and replay-review-only. It must not mutate route geometry, raw samples, trusted distance, speed, average speed, max speed, moving ratio, total elevation gain, production route acceptance, Wi-Fi entitlements, Wi-Fi scanning, road snapping, map matching, or production estimated route display. `estimatedRouteActive` remains false.

Implementation: The shared pack model lives in `Shared/Models/LocalizationDiagnosticsReviewPack.swift`; the iOS builder lives in `iOS/Core/SensorEngine/LocalizationDiagnosticsReviewBuilder.swift`. The implementation intentionally avoids adding new logic to oversized legacy files and replaces the DEBUG visible build signature with localized keys.


Boundary update: `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` defines b17 as the Replay-Only IMU Gap Interpolation Engine. The pushed `bea5077` diagnostics review pack is therefore treated as `Task-030c-b17-0` / preflight, not as b17-A/B/C/D completion. The next code milestone must be `Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation`.

Task-030c-b17-0 verification token: v1.2 alignment, localization diagnostics review pack foundation, LocalizationDiagnosticsReviewPack, LocalizationDiagnosticsReviewBuilder, diagnosticsOnly true, replayReviewOnly true, productionRouteMutationApplied false, estimatedRouteActive remains false.

## Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation

Decision: Task-030c-b17-A begins the true v1.2 replay-only IMU gap interpolation engine by adding the pure mathematical foundation for local ENU coordinates, low-motion accelerometer bias estimation, and gravity-compensated motion samples. This milestone intentionally does not produce route geometry or estimated route display.

Boundary: The implementation follows `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` b17-A only. It does not implement b17-B dead-reckoning estimates, b17-C closure scoring, b17-D real-session review packs, b18 display models, production route mutation, trusted metric mutation, CoreLocation manager side effects, road snapping, or map matching.

Implementation: The iOS-only foundation lives in `iOS/Core/SensorEngine/LocalTangentPlane.swift`, `iOS/Core/SensorEngine/IMUBiasEstimator.swift`, and `iOS/Core/SensorEngine/GravityCompensatedMotionSample.swift`, with deterministic XCTest coverage in `Tests/iOSTests/IMULocalFrameBiasFoundationTests.swift`.

Task-030c-b17-A verification token: local tangent coordinate frame, sensor bias foundation, GravityCompensatedMotionSample, no production route geometry, no trusted metric mutation, estimatedRouteActive remains false.

## Task-030c-b17-B — Replay-Only Dead Reckoning Engine v1

Decision: Task-030c-b17-B implements the v1.2 replay-only dead-reckoning engine after b17-A established the local tangent coordinate frame and sensor-bias foundation. The engine consumes trusted pre-gap and post-gap GPS anchors plus persisted timerFusion IMU samples to produce `DeadReckoningReplayEstimate` diagnostics for analysis only.

Boundary: This milestone follows `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` b17-B only. No production route geometry is emitted, no route map rendering changes, and no trusted metrics are mutated. `estimatedRouteActive` remains false. The named `estimatedPositionDriftRateMetersPerSecond` constant stays at the conservative initial value of `0.5` until b17-D real-session closure data can calibrate it.

Implementation: Shared replay output models live in `Shared/Models/DeadReckoningReplayDiagnostics.swift`. The iOS-only engine lives in `iOS/Core/SensorEngine/DeadReckoningEngine.swift`, using `LocalTangentPlane`, `IMUBiasEstimator`, and `GravityCompensatedMotionSample`. Deterministic synthetic coverage lives in `Tests/iOSTests/DeadReckoningEngineReplayTests.swift`.

Task-030c-b17-B verification token: Replay-Only Dead Reckoning Engine v1, DeadReckoningReplayEstimate, DeadReckoningEngine, estimatedPositionDriftRateMetersPerSecond, anchor closure error, no production route geometry, no trusted metric mutation, estimatedRouteActive remains false.

## Task-030c-b17-C — Anchor Closure Error and Confidence Scoring

Decision: Task-030c-b17-C converts raw b17-B replay-only IMU candidate estimates into explicit closure diagnostics and conservative confidence evidence. It adds a shared `DeadReckoningClosureDiagnostics` model and an iOS-only `DeadReckoningClosureScorer` so every replay estimate set can report gap duration, estimated distance, closure error, closure-error ratio, heading reliability, IMU coverage, user-visible eligibility, and blocking reasons.

Boundary: This milestone follows `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` b17-C only. No user-visible route display is enabled, no production route geometry is emitted, no route map rendering changes are made, and no trusted metrics are mutated. `estimatedRouteActive` remains false. The scoring output is evidence for b17-D real-session review and a possible later product decision, not production behavior.

Implementation: Shared closure output lives in `Shared/Models/DeadReckoningClosureDiagnostics.swift`. The scorer lives in `iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift`, and b17-B `DeadReckoningEngine` attaches closure diagnostics to successful replay diagnostics. Deterministic XCTest coverage lives in `Tests/iOSTests/DeadReckoningClosureScoringTests.swift`.

Task-030c-b17-C verification token: Anchor Closure Error and Confidence Scoring, DeadReckoningClosureDiagnostics, DeadReckoningClosureScorer, closureErrorRatio, imuSampleCoverageRatio, eligibleForUserVisibleEstimatedRoute, no user-visible route display, no trusted metric mutation, estimatedRouteActive remains false.

## Task-030c-b17-D — Real-Session Replay Review Pack

Decision: Task-030c-b17-D turns the b17-A/B/C replay-only IMU foundation into a real-session replay review pack format. The pack records per-session and per-gap evidence for gap duration, IMU coverage, heading reliability, estimated displacement, anchor closure error, closure-error ratio, conservative user-visible eligibility, and blocking reasons.

Boundary: This milestone follows `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` b17-D only. It does not implement b18 display models, product UI, production estimated route rendering, route map changes, route geometry mutation, trusted metrics mutation, road snapping, or map matching. `estimatedRouteActive` remains false. The generated `Task030c_b17D_ReplayReviewPack.zip` artifacts are evidence for the required non-code product decision checkpoint before b18 display or production eligibility gate work.

Implementation: Shared review-pack output lives in `Shared/Models/DeadReckoningReplayReviewPack.swift`. The iOS-only builder lives in `iOS/Core/SensorEngine/DeadReckoningReplayReviewPackBuilder.swift`, converting real-session replay diagnostics into JSON, Markdown, and CSV artifacts. Deterministic XCTest coverage lives in `Tests/iOSTests/DeadReckoningReplayReviewPackTests.swift`.

Task-030c-b17-D verification token: Real-Session Replay Review Pack, `Task030c_b17D_ReplayReviewPack.zip`, JSON / Markdown / CSV artifacts, gap duration, IMU coverage, heading reliability, estimated displacement, closure error, eligibility, blocking reasons, product decision checkpoint required, no user-visible route display, no trusted metric mutation, estimatedRouteActive remains false.

## Task-030c-b17-D-3 — Real-Session Review Runner / Export Glue

Decision: Task-030c-b17-D-3 adds offline runner/export glue that reads real `.skatetrack` session exports and writes `Task030c_b17D_ReplayReviewPack.zip` review artifacts. The runner produces JSON, Markdown, and CSV outputs containing per-session and per-gap evidence for gap duration, IMU coverage, heading reliability, estimated displacement, anchor closure error, closure-error ratio, eligibility, and blocking reasons.

Boundary: This milestone remains b17-D review-only infrastructure. It does not implement b18 display models, route map rendering changes, production estimated route rendering, route geometry mutation, trusted metrics mutation, road snapping, map matching, or CoreLocation manager behavior. `estimatedRouteActive` remains false, and the generated artifacts are evidence for the required product decision checkpoint before b18.

Implementation: The command entry point lives in `scripts/generate_task030c_b17d_real_session_review_pack.py`, with metrics/glue helpers in `scripts/task030c_b17d_real_session_metrics.py`. Safety verification lives in `scripts/verify_task030c_b17d_real_session_runner.py`.

Task-030c-b17-D-3 verification token: Real-Session Review Runner / Export Glue, `.skatetrack` inputs, `Task030c_b17D_ReplayReviewPack.zip`, JSON / Markdown / CSV artifacts, no user-visible route display, no trusted metric mutation, estimatedRouteActive remains false.

## Task-030c-b18-A — Product Decision Gate and In-Memory Estimated Route Display Decision

Decision: Task-030c-b18-A implements the first b18 milestone from `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`. The milestone adds an in-memory-only estimated route display decision model and safety gate for b17-D replay review gap records. It does not persist display decisions, mutate production route geometry, mutate trusted metrics, enable map rendering, or expose general-user estimated route display.

Boundary: This milestone follows `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` while recording the b18 product-decision refinement from the v1.1 plan. The candidate gate is intentionally tightened to `maximumCandidateGapDurationSeconds = 6`, while gaps up to `maximumReviewOnlyGapDurationSeconds = 30` remain review-only or future product-review evidence. The 6s / 30s split is more conservative than the original v1.2 candidate threshold because b17-D-3 real-session review found 0 eligible gaps for the core electric-skateboard session and large closure errors in several real sessions.

Implementation: Shared in-memory decision output lives in `Shared/Models/EstimatedRouteDisplayDecision.swift`. The iOS-only gate lives in `iOS/Core/SensorEngine/EstimatedRouteDisplayGate.swift`, with named safety constants in `EstimatedRouteDisplayGatePolicy`. Deterministic XCTest coverage lives in `Tests/iOSTests/EstimatedRouteDisplayGateTests.swift`. The b18 v1.1 plan is stored in `docs/planning/Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`.

Task-030c-b18-A verification token: Product Decision Gate, In-Memory Estimated Route Display Decision, `EstimatedRouteDisplayDecision`, `EstimatedRouteDisplayGate`, `EstimatedRouteDisplayGatePolicy`, `maximumCandidateGapDurationSeconds = 6`, `maximumReviewOnlyGapDurationSeconds = 30`, no Core Data persistence, no SessionRepository persistence, no SessionEntityMapper mapping, no `.skatetrack` schema change, no general-user estimated route display, no trusted metric mutation, estimatedRouteActive remains false.


## Task-030c-b18-B — Review-Only Estimated Route Overlay Artifact

Decision: Task-030c-b18-B implements the second b18 milestone from `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md`. The milestone turns b18-A in-memory display decisions into a review-only overlay artifact contract for product-decision inspection.

Boundary: The overlay artifact is not route geometry and is not a product route. It carries review labels, decision states, blocking reasons, and safety flags only. It does not render normal session-summary maps, expose general-user estimated route display, mutate production route geometry, mutate trusted metrics, persist overlay state, update Core Data, update `SessionRepository`, update `SessionEntityMapper`, or change the `.skatetrack` schema. `estimatedRouteActive` remains false.

Implementation: Shared overlay output lives in `Shared/Models/EstimatedRouteReviewOverlay.swift`. The iOS-only builder lives in `iOS/Core/SensorEngine/EstimatedRouteReviewOverlayBuilder.swift`. Deterministic XCTest coverage for the five real-session regression roles lives in `Tests/iOSTests/EstimatedRouteReviewOverlayTests.swift`.

Task-030c-b18-B verification token: Review-Only Estimated Route Overlay Artifact, `EstimatedRouteReviewOverlay`, `EstimatedRouteReviewOverlayBuilder`, five real-session regression traps, no user-visible estimated route display, no route geometry, no persistence, no trusted metric mutation, estimatedRouteActive remains false.

## Task-030c-b18-C — DEBUG-Only Estimated Route Review Panel

Decision: Task-030c-b18-C implements the third b18 milestone from `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md` and the `Task-030c-b18-C_DEBUG_Review_Panel_Mini_Plan_EN_v1.1.md` implementation note. The milestone adds a DEBUG-only review panel for inspecting b18-B review overlay records without enabling product UI.

Boundary: The entire `EstimatedRouteReviewPanel` type is wrapped in `#if DEBUG`. The milestone does not render route polylines, path shapes, Canvas previews, map overlays, or route-like geometry. It does not mutate production route geometry, trusted metrics, persistence, SessionRepository, SessionEntityMapper, `.skatetrack` schema, or normal Session Summary map behavior.

Implementation: The DEBUG panel lives in `iOS/Features/Debug/EstimatedRouteReviewPanel.swift`. Deterministic DEBUG XCTest coverage lives in `Tests/iOSTests/EstimatedRouteReviewPanelTests.swift`. Panel text uses `debug.estimatedRouteReview.*` Localizable keys in English, Traditional Chinese, and Japanese.

Task-030c-b18-C verification token: DEBUG-Only Estimated Route Review Panel, `EstimatedRouteReviewPanel`, full `#if DEBUG` type boundary, localized DEBUG panel strings, no route rendering, no user-visible estimated route display, no persistence, no trusted metric mutation, estimatedRouteActive remains false.


## Task-030c-b18-D — Real-Session Recheck and Product Decision Update

Decision: Task-030c-b18-D completes the b18 product decision update from `Task-030c-b18_Product_Decision_Checkpoint_and_Safety_Gated_Display_Plan_EN_v1.1.md` and `Task-030c-b18-D_Real_Session_Recheck_and_Product_Decision_Mini_Plan_EN_v1.0.md`. General-user estimated route display remains disabled.

Boundary: The milestone records a review-only product decision update. It does not render route geometry, mutate production route data, change trusted metrics, persist decisions, update SessionRepository, update SessionEntityMapper, change `.skatetrack` schema, or alter normal Session Summary map behavior.

Implementation: Shared product-decision output lives in `Shared/Models/EstimatedRouteProductDecisionUpdate.swift`. The iOS-only builder lives in `iOS/Core/SensorEngine/EstimatedRouteProductDecisionUpdateBuilder.swift`. Deterministic XCTest coverage lives in `Tests/iOSTests/EstimatedRouteProductDecisionUpdateTests.swift`.

Task-030c-b18-D verification token: Real-Session Recheck and Product Decision Update, `EstimatedRouteProductDecisionUpdate`, `EstimatedRouteProductDecisionUpdateBuilder`, outcome `keepDisabled`, five real-session roles, no user-visible estimated route display, no route geometry, no persistence, no trusted metric mutation, estimatedRouteActive remains false.


## Task-030c-b19 — Outdoor Localization Release Gate

Decision: Task-030c-b19 adds a conservative outdoor localization release gate while preserving the b18-D product decision. General-user estimated route display remains disabled, `estimatedRouteActive` remains false, and the gate evaluates only real GPS/localization quality for release-quality presentation.

Boundary: b19 does not render route geometry, add route polylines, mutate the normal Session Summary map, mutate trusted metrics, persist release-gate decisions, update SessionRepository, update SessionEntityMapper, or change the `.skatetrack` schema. `OutdoorLocalizationReleaseGate` is a review/release decision artifact only.

Implementation: Shared release-gate output lives in `Shared/Models/OutdoorLocalizationReleaseGate.swift`. The iOS builder lives in `iOS/Core/SensorEngine/OutdoorLocalizationReleaseGateBuilder.swift`. Deterministic XCTest coverage lives in `Tests/iOSTests/OutdoorLocalizationReleaseGateTests.swift`.

Task-030c-b19 verification token: Outdoor Localization Release Gate, `OutdoorLocalizationReleaseGate`, `OutdoorLocalizationReleaseGateBuilder`, decisions `releaseReady`, `limitedDisclosure`, `blocked`, realGPSOnly true, no user-visible estimated route display, no route geometry mutation, no persistence, no trusted metric mutation, estimatedRouteActive remains false.

## Task-030c Final Closure Audit — Section 5 DoD Mapping

Decision: Task-030c may close at b19 with a docs-only final closure audit rather than opening a new b20 milestone. The active branch has completed the v1.2 sequence through `2cc0550 Task-030c-b19 add outdoor localization release gate`, and the remaining closure work is documentation, audit traceability, and merge hygiene only.

Boundary: This closure audit is not a feature milestone. It must not add Swift production logic, estimated route display, route reconstruction, route map rendering, route geometry mutation, trusted metric mutation, Core Data persistence, `SessionRepository` persistence, `SessionEntityMapper` mapping, `.skatetrack` schema changes, road snapping, fake GPS, camera localization, RTK, UWB consumer-flow dependency, or indoor estimated route geometry.

Section 5 mapping:

| v1.2 DoD area | Closure evidence |
|---|---|
| Outdoor GPS fidelity | b13–b16 and b19 preserve visual honesty, low-confidence / warm-up distinction, bad-GPS diagnostics, small-area disclosure, stable trusted metrics, and outdoor release classification. |
| Locked-screen / pocket continuity | b17-A/B/C/D and b17-D-3 provide replay-only IMU estimates, closure-error scoring, real-session review artifacts, and ineligible-gap disclosure. |
| Estimated route display condition | b18-A/B/C/D implements in-memory gates, review-only artifacts, DEBUG-only inspection, and final `keepDisabled`; general-user display is not enabled. |
| Indoor localization | Indoor product work is explicitly deferred to Task-031; Task-030c only contributes passive accuracy-source and heading-quality scaffolding. |
| Honesty and non-goals | Camera localization, RTK, UWB consumer dependency, road snapping, fake GPS, and perfect small-area reconstruction remain rejected. |
| Engineering quality | b19 final verification passed verify/build/XCTest/status; docs are updated; Task-031 handoff remains the next scope. |

Commit trace:

```text
0cfe8e1 Task-030c-b16-A add localization foundation plan
c3a57dd Task-030c-b16-B add barometric GPS outlier diagnostics
505a1eb Task-030c-b16-C add passive accuracy source diagnostics
87aabef Task-030c-b16-D add heading quality diagnostics
1a5f264 Task-030c-b17-0 align localization diagnostics review foundation
d7412ff Task-030c-b17-A add IMU local frame and bias foundation
6596231 Task-030c-b17-B add replay-only dead reckoning engine
b8037ba Task-030c-b17-C add dead reckoning closure scoring
5dea284 Task-030c-b17-D add replay review pack
859f860 Task-030c-b17-D-3 add real session review runner
93ae35e Task-030c-b18-A add product decision display gate
db8f42b Task-030c-b18-B add review-only estimated route overlay
8d39e18 Task-030c-b18-C add DEBUG estimated route review panel
9d7db70 Task-030c-b18-D add product decision update
2cc0550 Task-030c-b19 add outdoor localization release gate
```

Task-030c final closure verification token: docs-only closure audit, Section 5 DoD mapping, commit trace through `2cc0550`, b18-D `keepDisabled`, Task-031 indoor handoff, no user-visible estimated route display, no route geometry mutation, no trusted metric mutation, no persistence/schema mutation.

## Task-030e macOS multi-package viewer documentation sync

Decision: Task-030e-MacViewer-012 makes the macOS multi-package viewer documentation consistent across the documentation index, development rules, release readiness, manual QA matrix, known limitations, file structure, and development log. The Task-030e viewer is documented as a read-only `.skatetrack` review surface through verifier / docs sync, not as an import, merge, restore, sync, or route-correction feature.

Boundary: The documentation sync does not add Swift UI behavior, package schema fields, Core Data writes, local-history import, route geometry mutation, trusted metric mutation, location permission, user-location display, Watch / WatchBridge work, or Task-031 shared visualization pipeline work. The one-click runner is documented as responsible for deleting its temporary output directory after zip packaging and recording `ONECLICK_RUN_DIR_REMOVED=YES`.

Task-030e-MacViewer-012 ADR token: Documentation Sync, read-only macOS multi-package viewer, one-click cleanup rule, no import / merge / route mutation.


## Task-030e macOS multi-package viewer manual QA gate

Decision: Task-030e-MacViewer-013 makes manual QA an explicit source-controlled gate before the final merge gate. The gate records required automated evidence, operator-run package scenarios, route/duplicate/localization/accessibility checks, one-click cleanup confirmation, and no-scope-expansion checks.

Boundary: The manual QA gate does not add product UI behavior, package import, package merge, duplicate deletion, winner selection, local-history import, route correction, road matching, snap-to-road, route reconstruction, location permission, user-location display, route geometry mutation, trusted metric mutation, package schema mutation, Core Data writes, Watch / WatchBridge work, or Task-031 shared visualization pipeline work.

Task-030e-MacViewer-013 ADR token: Manual QA Gate, operator signoff required, task030e_013_oneclick, read-only no-import boundary, no route / metric / schema mutation.


## Task-030e macOS multi-package viewer final merge gate

Decision: Task-030e-MacViewer-014 is a final merge-readiness gate for the macOS multi-package viewer branch. It records develop merge readiness, manual QA carry-forward, automated one-click evidence, and final no-scope-expansion review before merging `task-030e-macos-multi-package-viewer` back to `develop`.

Boundary: This milestone is docs/tooling/merge-readiness only. It must not add product UI, local-history import, package merge, duplicate deletion, winner selection, route correction, road matching, snap-to-road, route reconstruction, route geometry mutation, trusted metrics mutation, package schema change, Core Data write, location permission, user-location display, Watch / WatchBridge behavior, or Task-031 implementation.

Task-030e-MacViewer-014 verification token: Task-030e macOS multi-package viewer final merge gate, develop merge readiness, final no-scope-expansion review, no schema / Core Data mutation.
## Task-031-prep shared activity visualization ownership

Decision: Task-031-prep establishes `Shared/ActivityVisualization` as a display-only preparation layer for route, speed, elevation, unified visualization results, and compact visualization summaries. Shared decides visualization data semantics; platforms decide rendering.

Boundary: The Shared visualization stack may filter, segment, downsample, summarize, and expose diagnostics for display, but it must not mutate source route geometry, trusted metrics, stored session values, Core Data, `.skatetrack` package schema, export payloads, Watch recording, location permission, current-user-location behavior, cloud sync, import, merge, or restore flows.

Implementation: ActivityViz-001 through ActivityViz-014 add the route/speed/elevation focused pipelines, `ActivityVisualizationPipeline`, `ActivityVisualizationResult`, `ActivityVisualizationCompactSummary`, `CompactRouteDisplay`, `CompactSpeedSparkline`, `CompactElevationProfile`, deterministic ActivityVisualization tests, and `verify_task031_prep_014_cross_platform_visualization.py`. Platform renderers remain in iOS/macOS/watchOS surfaces and may keep focused sub-pipeline adapters where that is cleaner than forcing umbrella API adoption.

Task-031-prep-ActivityViz-015 ADR token: Shared decides visualization data semantics; platforms decide rendering, display-only ActivityVisualization, focused pipelines, unified pipeline, compact adapter contract, cross-platform verifier, no Watch UI, no Watch recording, no persistence/export/package schema mutation, ActivityViz-016 final parity gate remains.


## Task-031-prep final parity gate and closure decision

- **Decision:** Task-031-prep closes with a Shared display-only activity visualization preparation layer and a final parity gate.
- **Ownership rule:** Shared decides visualization data semantics; platforms decide rendering.
- **Shared contracts covered:** `RouteDisplayPipeline`, `SpeedDisplayPipeline`, `ElevationDisplayPipeline`, `ActivityVisualizationPipeline`, `ActivityVisualizationResult`, `ActivityVisualizationCompactSummary`, `CompactRouteDisplay`, `CompactSpeedSparkline`, and `CompactElevationProfile`.
- **Verification rule:** `verify_task031_prep_016_final_parity_gate.py` is the final static closure verifier and must remain aligned with the ActivityViz-003 through ActivityViz-015 verifier family.
- **Boundary:** Final parity does not implement Watch UI, Watch recording, compact watchOS consumption, route correction, map matching, snap-to-road, route reconstruction, current-user-location display, location permission prompts, trusted metric mutation, Core Data writes/import/merge/restore, cloud sync, or persistence/export/package schema mutation.

Task-031-prep-ActivityViz-016 ADR token: final parity gate and closure decision, Shared decides visualization data semantics; platforms decide rendering, verify_task031_prep_016_final_parity_gate.py, ActivityVisualizationResult, ActivityVisualizationCompactSummary, CompactRouteDisplay, CompactSpeedSparkline, CompactElevationProfile, no Watch UI, no Watch recording, no persistence/export/package schema mutation.

<!-- Task-031a-001 BEGIN -->

## Task-031a ADR Addendum — Shared Activity Visualization Pipeline

| ADR | Status | Summary |
|---|---|---|
| `docs/adr/ADR-Shared-Activity-Visualization-Pipeline.md` | Accepted / documented from merged baseline | Records that Shared decides route/speed/elevation/compact visualization semantics while platforms decide rendering. No Watch UI, WatchBridge implementation, Watch recording, route geometry mutation, trusted metric mutation, package schema mutation, Core Data mutation, or Snow production implementation is introduced by Task-031a. |

<!-- Task-031a-001 END -->
