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

## Task-030c-b14-B-1 — Replay-Only Dead-Reckoning Readiness Diagnostics

Decision: Task-030c-b14-B-1 adds only replay-only readiness classification for future IMU-aided route continuity. It analyzes persisted samples for gap duration, trusted anchors, timer-fusion cadence, heading availability, heading age, and heading accuracy, but it does not create estimated coordinates or mutate production route data.

Rationale: b13-B-1 provides magnetometer/device heading diagnostics, but real dead reckoning remains risky without replay evidence. The next safe step is to measure whether sessions are eligible for future interpolation while keeping route geometry, distance, speed, altitude, and summary metrics unchanged.

Task-030c-b14-B-1 verification token: replay-only readiness, DeadReckoningReadinessAnalyzer, estimatedRouteActive remains false, preserves b13-A-4 display/altitude behavior, preserves b13-B-1 legacy decode compatibility.


## Task-030c-b14-B-1 — Altitude Chart Source Guard

Decision: Task-030c-b14-B-1 is a display-only altitude source guard. When a session has trusted barometer-relative altitude, the elevation chart should use that altitude stream continuously and should not split the profile merely because GPS location diagnostics report stale fixes or background gaps. Raw altitude fallback remains only for legacy packages without altitude diagnostics.

Boundary: route geometry remains unchanged, stored samples are not rewritten, summary metrics are not recalculated, and dead reckoning remains disabled.

Task-030c-b14-B-1 verification token: display-only altitude source guard, barometer-relative profile continuity, route geometry remains unchanged, estimatedRouteActive remains false.

## Task-030c-b14-B-1 — Altitude Chart Micro-Dip Display Guard

Decision: Task-030c-b14-B-1 adds a display-only guard for very short barometer notches in the advanced elevation chart. The guard is intentionally conservative: it only adjusts chart points when nearby left and right baselines agree, the center point is a sharp local dip, and the local span is short.

Non-goals: no stored sample rewrite, no elevation gain recalculation, no route geometry mutation, no recording-pipeline altitude change, no dead reckoning enablement, no road snapping, no map matching.

Task-030c-b14-B-1 verification token: display-only guard for very short barometer notches, route geometry remains unchanged, estimatedRouteActive remains false.

## Task-030c-b14-B-1 — Startup Route Visual Suppression

Decision: Task-030c-b14-B-1 applies visual-only suppression to startup / GPS warm-up route segments. Startup geometry remains available as solid fluorescent-pink route context with route accuracy disclosure, full route-line weight, and clear separation from the first trusted GPS-lock segment. Raw samples and diagnostics remain immutable. Distance, speed, altitude, route geometry, and exported diagnostics are unchanged.

Task-030c-b14-B-1 verification token: visual-only suppression, startup route visual suppression, solid fluorescent-pink route context, route geometry remains unchanged, estimatedRouteActive remains false.

## Task-030c-b14-B-1 — Replay-Only Candidate Gap Interpolation Prototype
Decision: Task-030c-b14-B-1 may generate candidate interpolation points only as replay/debug diagnostics. Candidate points are derived from existing readiness candidates and trusted pre/post GPS anchors, but they are not production route geometry and must never affect distance, speed, altitude, summaries, exports, or persisted motion samples.

Task-030c-b14-B-1 verification token: replay-only candidate gap interpolation, debug-only candidate points, anchor closure blocking, solid fluorescent-pink startup/warm-up route context, estimatedRouteActive remains false.

## Task-030c-b14-B-1 — Summary Elevation Gain Source Guard
- Decision: Task-030c-b14-B-1 aligns the Summary climb card with the trusted altitude-source policy already used by the advanced elevation chart. When trusted barometer-relative altitude exists, Core Location absolute altitude remains available for diagnostics/export but must not inflate user-facing `elevationGainMeters`.
- The display layer can return a zero-meter climb when trusted altitude samples are flat instead of falling back to an older persisted climb value merely because the recomputed display gain is zero.
Task-030c-b14-B-1 verification token: summary elevation gain source guard, trusted barometer-relative climb, Core Location absolute altitude diagnostics only, route geometry remains unchanged, estimatedRouteActive remains false.
