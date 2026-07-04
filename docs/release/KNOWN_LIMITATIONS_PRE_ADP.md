# Known Limitations Before Apple Developer Program / External Credentials

**Status:** Active source of truth — Task-030b consolidation
**Last Updated:** 2026-06-13
**Scope:** Features intentionally blocked until Apple Developer Program enrollment, App Store Connect setup, Google Cloud credentials, production provider configuration, or additional release validation is available.

This file replaces scattered pre-ADP limitation notes from older ADRs. Each item states current status, why it is blocked, the current safe substitute, the unlock condition, the suggested future task, and what must not be claimed.

## L-001 StoreKit Production Subscription

- **Current status:** Local / DEBUG entitlement simulation only.
- **Blocked by:** Apple Developer Program, App Store Connect subscription products, production transaction testing, receipt / transaction validation policy, and App Store metadata.
- **Current substitute:** Replaceable entitlement-provider boundary and local simulation established in Task-016.
- **Unlock condition:** Apple Developer Program is active, App Store Connect products exist, and a production StoreKit provider can be added behind the existing entitlement boundary.
- **Future task:** Production StoreKit provider + App Store subscription QA.
- **Do not claim:** Do not claim production subscriptions, real App Store purchases, production restore purchases, or App Store receipt validation.

## L-002 Google Sign-In Production

- **Current status:** Disabled Google provider plus DEBUG-only local account simulation.
- **Blocked by:** Google Cloud project, OAuth client ID, reversed client ID URL scheme, token lifecycle, logout / revocation behavior, and privacy copy review.
- **Current substitute:** `AuthProvider` / `GoogleSignInProviding` boundary, `DisabledGoogleAuthProvider`, DEBUG `LocalAccountProvider`.
- **Unlock condition:** Production OAuth credentials and URL scheme are available and reviewed.
- **Future task:** Production Google auth provider behind the existing account-provider boundary.
- **Do not claim:** Do not claim real Google login, Google identity verification, or production token storage.

## L-003 Google Drive Sync / Task-026c-blocked

- **Current status:** Blocked; local backup export and non-destructive restore preview only.
- **Blocked by:** Google Sign-In production, Drive API scopes, production token lifecycle, remote conflict policy, and minimum-scope privacy copy.
- **Current substitute:** `DisabledDriveProvider`, local backup package export, restore preview without overwrite.
- **Unlock condition:** Google OAuth and Drive scopes are ready, token storage is reviewed, and conflict policy is designed.
- **Future task:** Real Drive provider behind `CloudBackupProvider`.
- **Do not claim:** Do not claim cloud sync, Google Drive backup, automatic restore, remote merge, or multi-device sync.

## L-004 CloudKit / iCloud Sync

- **Current status:** Not implemented.
- **Blocked by:** Apple Developer Program, CloudKit / iCloud capabilities, CloudKit container, data model sync policy, conflict strategy, and device-to-device QA.
- **Current substitute:** Local data, local backup package, portable `.skatetrack` export.
- **Unlock condition:** Apple Developer Program is active and a CloudKit provider plan is approved.
- **Future task:** Cloud sync provider boundary and CloudKit implementation after local package semantics are stable.
- **Do not claim:** Do not claim Apple cloud sync, iCloud backup, or cross-device automatic sync.

## L-005 WeatherKit Live Data

- **Current status:** Weather work remains mock / disabled / local rideability only.
- **Blocked by:** Apple Developer Program, WeatherKit capability, live provider QA, privacy copy, and fallback behavior.
- **Current substitute:** Mock / local rideability guidance.
- **Unlock condition:** WeatherKit entitlement and live provider design are available.
- **Future task:** WeatherKit provider behind the existing weather boundary.
- **Do not claim:** Do not claim live weather, live UV, live rain, or production WeatherKit forecasts.

## L-006 TestFlight / App Store Submission

- **Current status:** Local simulator / development-device build only.
- **Blocked by:** Apple Developer Program, App Store Connect app record, signing setup, provisioning, TestFlight metadata, privacy labels, screenshots, and review copy.
- **Current substitute:** Pre-ADP local release-readiness gate.
- **Unlock condition:** Apple Developer Program is active and release assets / metadata are prepared.
- **Future task:** TestFlight pipeline and App Store Connect readiness.
- **Do not claim:** Do not claim upload readiness, TestFlight availability, App Store readiness, or review readiness.

## L-007 Custom `.skatetrack` UTType / Finder Open-With / Document Association

- **Current status:** Not implemented; `.skatetrack` is shared / opened as a normal file URL.
- **Blocked by:** Apple Developer Program, signing review, product decision on inbound file handling, Finder open-with behavior, and document association QA.
- **Current substitute:** iOS export share sheet and macOS NSOpenPanel read-only package viewer.
- **Unlock condition:** Incoming-file UX and signing / capability impact are reviewed.
- **Future task:** Custom UTType + document association after package viewer and import semantics are mature.
- **Do not claim:** Do not claim Finder open-with, custom UTType registration, automatic file opening, or document association.

## L-008 Real-device Background GPS Release Validation

- **Current status:** Task-030c-b2 adds navigation-style background location continuity code for active ride recording, including iOS background location mode, `allowsBackgroundLocationUpdates`, Always-location upgrade when possible, significant-change backup, lower-confidence fix retention, and `navigation-continuity-diagnostics-v1` package diagnostics. Release-grade real-device validation remains open.
- **Blocked by:** Outdoor iPhone validation with screen off, phone in pocket, precise location enabled, Always location access granted, real device power management, and location scheduling behavior.
- **Current substitute:** Simulator route testing, DEBUG simulated route packages, and manual real-device checklist. The 2026-06-13 pre-b2 screen-off packages are treated as failed validation evidence, not as acceptable release evidence.
- **Unlock condition:** Run outdoor validation on iPhone: start in foreground, confirm DEBUG simulated route is off, grant precise + Always location access, lock screen, pocket carry, move at least 1 km or 3–5 minutes, then confirm route continuity, unique coordinate count, location update intervals, long gap counters, speed metrics, summary distance, and package export consistency.
- **Future task:** Repeat real-device GPS validation after Task-030c-b2; if long gaps persist, add a targeted background location lifecycle / permission UX task before Task-031.
- **Do not claim:** Do not claim fully validated lock-screen background tracking, navigation-grade route accuracy, road snapping, map matching, or precise real-road replay until real-device validation passes.

## L-009 Fall Detection Diagnostics / Safe Test Mode

- **Current status:** Fall Detection engine and UI foundation exist; real-world safety validation is not complete.
- **Blocked by:** Safe controlled test plan, diagnostics UI, non-human hardware / fixture validation, and safety-copy review.
- **Current substitute:** Existing engine thresholds and fall alert UI foundation.
- **Unlock condition:** Add DEBUG diagnostics / safe test mode showing recent G-force, gyro, candidate impact, stationary confirmation, and alert state; validate with safe controlled tests.
- **Future task:** Fall Detection diagnostics and safe validation protocol.
- **Do not claim:** Do not claim fully validated real-world crash detection; do not ask the user to test by hard-falling with their body.

## L-010 Native Japanese Review

- **Current status:** Japanese is implemented as first-pass product localization.
- **Blocked by:** Native Japanese product-copy, privacy-copy, accessibility-copy, and App Store metadata review.
- **Current substitute:** `ja` key parity, placeholder parity, and first-pass copy QA.
- **Unlock condition:** Native Japanese review is complete and issues are fixed.
- **Future task:** Japanese localization review pass.
- **Do not claim:** Do not claim final Japanese-market copy readiness before native review.

## L-011 Deferred Localization Roadmap

- **Current status:** Active languages are `en`, `zh-Hant`, and `ja`.
- **Blocked by:** Localization QA capacity, native review, and product-market prioritization.
- **Current substitute:** Three-language support.
- **Unlock condition:** Task scope explicitly approves another language and native / QA review is planned.
- **Future task:** Add `pt-BR` Brazilian Portuguese first, then `es` Spanish.
- **Do not claim:** Do not claim Brazilian Portuguese or Spanish support in the current build.

Task-030b verification token: consolidated pre-ADP limitations.

## L-012 Route Replay / Track Post-Processing Engine

- **Current status:** Deferred. Task-030c-a adds Core Location diagnostics and route-quality summary metadata only; it does not implement replay, smoothing, map matching, or skiing-specific analysis.
- **Blocked by:** Real-device high-accuracy outdoor recording validation, enough raw location diagnostics, route confidence rendering, and a separate post-processing design for smoothing / interpolation.
- **Current substitute:** `.skatetrack` packages can carry optional `locationDiagnostics`, millisecond timestamps, and `routeQualitySummary` with `location-diagnostics-v1` and `route-quality-summary-v1` capabilities. Task-030c-b also provides a DEBUG-only simulated route package marker (`debug-simulated-route-v1`) for simulator diagnostics.
- **Unlock condition:** Task-030c-b/c/d validate high-accuracy recording, speed freshness, and low-confidence route rendering on real devices.
- **Future task:** Route Replay & Track Post-Processing Engine after raw Core Location quality is stable; future Snow Mode / Skiing Mode must reuse generic route confidence logic rather than skateboard-only assumptions.
- **Do not claim:** Do not claim road snapping, map matching, navigation-grade route accuracy, precise real-road replay, or ski-app-grade replay before the post-processing engine exists and has real-device validation.

Task-030c-b verification token: simulator / compatibility reference, route-quality-summary-v1, High-accuracy outdoor recording policy, DEBUG simulated route, debug-simulated-route-v1, road snapping deferred.

Task-030c-b2 verification token: Navigation-grade Location Continuity, screen-off pocket, background location mode, navigation-continuity-diagnostics-v1, road snapping deferred.

## L-013 Route Recording Recovery / Raw Route Honesty

- **Current status:** Task-030c-b3 recovers several real-device validation failures by reconciling summary distance with route-quality distance, scoping fall events to the active session, rejecting current pre-Snow-mode coordinate-derived speed outliers, rendering speed / elevation charts as gap-aware segmented lines, splitting raw route preview polylines across long or low-confidence gaps, and keeping the summary return CTA floating at the bottom.
- **Blocked by:** Additional real-device validation with DEBUG simulated route off, screen-off / pocket and windshield scenarios, known route distance comparison, and inspection of `.skatetrack` route-quality diagnostics.
- **Current substitute:** Raw Core Location route preview with explicit gap handling. The app does not infer the exact road taken.
- **Unlock condition:** Real-device packages show summary distance close to route-quality distance, no stale fall-event carryover, no chart fill artifacts across long gaps, fewer long recording gaps, and user-acceptable raw route continuity.
- **Future task:** If road-aligned rendering is required, open a separate road snapping / map matching task after evaluating privacy, network dependency, off-road skating spots, and future snow / ski routes.
- **Do not claim:** Do not claim road snapping, map matching, navigation-grade road alignment, exact real-road replay, or ski-app-grade replay.

Task-030c-b3 verification token: Navigation-grade Route Recording Recovery, route-recording-recovery-v1, gap-aware charts, floating bottom return, road snapping deferred.

## L-014 Raw CLLocation Stream Persistence Validation

- **Current status:** Task-030c-b4 persists each accepted Core Location fix as a dedicated raw location-fix sample with `raw-location-stream-v1` package capability. This is intended to improve future screen-off / pocket / windshield recordings by reducing reliance on timer-fusion samples.
- **Blocked by:** New real-device outdoor validation after applying Task-030c-b4, including screen-off pocket and windshield scenarios with DEBUG simulated route off, precise location enabled, and Always location authorization when available.
- **Current substitute:** Gap-aware route / chart rendering and diagnostics expose missing data honestly. Historical packages cannot be repaired if raw location fixes were not saved at recording time.
- **Unlock condition:** New `.skatetrack` packages show increased `.locationFix` sample count, increased unique coordinate count, reduced long location gaps, summary distance closer to known route distance, no stale fall-event carryover, and acceptable raw route continuity.
- **Future task:** If exact road alignment is still required after raw stream persistence is validated, open a separate map matching / road snapping task with privacy, network, off-road skating, and future snow-route implications reviewed.
- **Do not claim:** Do not claim road snapping, map matching, exact navigation-grade road alignment, historical route repair, or ski-app-grade replay.

Task-030c-b4 verification token: Raw CLLocation Stream Persistence, raw-location-stream-v1, raw location fix stream, road snapping deferred.

## L-015 Activity-Aware Fidelity / Optional ML Enhancement

- **Current status:** Task-030c-b5 introduces deterministic activity-aware speed, route-confidence, fall-alert, chart, and altitude-source policies. It supports broader speed ranges for electric skateboard, speed inline, future snow / ski, and vehicle validation without requiring Apple Intelligence.
- **Blocked by:** Additional real-device validation across walking, technical skateboard, electric skateboard, inline, screen-off pocket, windshield, and future snow-mode scenarios. Optional Core ML / Apple on-device AI confidence classification is not implemented yet.
- **Current substitute:** Deterministic `ActivityFidelityPolicy`, raw Core Location stream persistence, gap-aware rendering, altitude-source separation, and package diagnostics.
- **Unlock condition:** Real-device packages show acceptable route continuity, no major long gaps, sane speed ranges for each activity profile, no impossible elevation jumps, and no inappropriate fall alerts during vehicle / high-speed validation.
- **Future task:** Optional Core ML confidence engine for location / speed / altitude quality classification, plus a separate relative technique-trace engine for low-speed surfskate S-turn analysis.
- **Do not claim:** Do not claim Apple Intelligence dependency, AI route reconstruction, sub-meter carving traces, road snapping, map matching, exact ski-app-grade replay, or complete Snow Mode support.

Task-030c-b5 verification token: Activity-Aware Location, Speed & Altitude Fidelity, activity-aware-fidelity-v1, altitude-source-stabilization-v1, Core ML optional, road snapping deferred.


## L-028 Debug Build Signature Is Not Production Versioning

- **Current status:** Task-030c-b6 adds a polished DEBUG-only build-signature card that displays `Task-030c-b6` inside Debug Tools.
- **Blocked by:** This is a temporary tester-facing task marker used during the GPS fidelity branch; production release versioning still requires the normal app version / build number process.
- **Current substitute:** DEBUG-only build signature in the Debug Tools panel plus Git commit history and hotfix documentation.
- **Unlock condition:** When SkateTrack reaches a release-ready workflow, use formal app version and build numbers instead of task IDs as tester-facing version identifiers.
- **Future task:** Formal internal build metadata and release-channel labeling after Pre-ADP GPS fidelity stabilization.
- **Do not claim:** Do not claim `Task-030c-b6` is an App Store version, TestFlight build number, production release, or public marketing version.

Task-030c-b6 verification token: Debug Tools Status Panel Polish, Task-030c-b6, debug-build-signature-card, session-recording-preview-panel.

## L-029 Temporary DEBUG Recording Gap Diagnostics

- **Current status:** Task-030c-b7 adds temporary DEBUG-only `debugRecordingDiagnostics` metadata to future `.skatetrack` packages so lock-screen, background, pocket, and windshield recording gaps can be diagnosed from uploaded files.
- **Blocked by:** Additional real-device validation is required to determine whether long gaps are caused by missing Core Location callbacks, app lifecycle / protected data transitions, recording heartbeat pauses, authorization / precise-location changes, or SkateTrack filter decisions.
- **Current substitute:** Event-based diagnostics record app lifecycle events, protected data lock/unlock signals, recording heartbeats, location manager snapshots, authorization snapshots, Core Location callback events, gap events, filter decisions, altitude diagnostics, and a DEBUG recording test context label.
- **Unlock condition:** Repeated screen-off pocket, handheld auto-lock, and windshield packages show a clear root cause and the production recording pipeline is fixed and validated.
- **Future task:** Remove or collapse the temporary diagnostics block after GPS fidelity stabilization, or convert a small subset into a stable developer diagnostics format if still useful.
- **Do not claim:** Do not claim background GPS continuity is fixed merely because diagnostics exist. Do not present `debugRecordingDiagnostics` as a production user-visible feature.

Task-030c-b7 verification token: Background Recording Gap Diagnostics, debug-recording-diagnostics-v1, background-gap-diagnostics-v1, DEBUG-only, protected data.


### Task-030c-b8 — DEBUG-only context labels

The additional electric longboard and scooter recording context labels are temporary DEBUG-only diagnostics aids. They are not production activity modes, do not enable official electric longboard mode, and do not change location, route, altitude, or speed filtering behavior.

### Task-030c-b9 — Diagnostics export verification

- **Current status:** Task-030c-b9 ensures exported `.skatetrack` packages can prove whether background recording diagnostics were enabled, empty, or disabled by build configuration through `debugRecordingDiagnostics.diagnosticsStatus` and the `Task-030c-b9` build identity.
- **Blocked by:** New real-device validation is still required. This task does not fix lock-screen / pocket GPS gaps; it only ensures the next package contains the information needed to diagnose them.
- **Current substitute:** Temporary internal diagnostics metadata in exported DEBUG / Pre-ADP packages, including `debug-build-identity-v1`, `debug-recording-diagnostics-v1`, `background-gap-diagnostics-v1`, and `diagnostics-export-status-v1` capabilities.
- **Future task:** After GPS fidelity stabilizes, remove the non-DEBUG placeholder and either remove the temporary diagnostics block or convert a small subset into a cleaner developer diagnostics format.
- **Do not claim:** Do not claim background GPS continuity is fixed, do not treat `Task-030c-b9` as a production app version, and do not present diagnostics metadata as a user-visible product feature.

Task-030c-b9 verification token: Ensure Background Diagnostics Export, Task-030c-b9, diagnostics export, debug-build-identity-v1, diagnostics-export-status-v1.

### Task-030c-b9-r1 — Diagnostics persistence round trip

- **Current status:** Task-030c-b9-r1 persists `debugRecordingDiagnostics` through the local Core Data save / fetch round trip using optional `debugRecordingDiagnosticsData`, then exports either the recorded diagnostics block or a `missingFromPersistedSession` fallback for older sessions.
- **Blocked by:** Real-device validation is still required to determine the cause of lock-screen / pocket GPS recording gaps. This task only makes diagnostics reliably exportable.
- **Current substitute:** Temporary internal package metadata and local persistence fields: `debug-build-identity-v1`, `debug-recording-diagnostics-v1`, `background-gap-diagnostics-v1`, `diagnostics-export-status-v1`, and `debugRecordingDiagnostics.diagnosticsStatus`.
- **Future task:** After GPS fidelity stabilizes, remove or collapse temporary diagnostics persistence, or retain only a small developer diagnostics subset.
- **Do not claim:** Do not claim background GPS continuity is fixed, do not treat `Task-030c-b9-r1` as a production app version, and do not expose temporary diagnostics as normal user-facing product telemetry.

Task-030c-b9-r1 verification token: Persist Diagnostics Through Session Export, Task-030c-b9-r1, missingFromPersistedSession, diagnostics export.

### Task-030c-b10 — Background runtime and gap-recovery quality gate

- **Current status:** Task-030c-b10 makes the intended `UIBackgroundModes/location` declaration explicit in the iOS app bundle, records bundle-info snapshots in temporary diagnostics, and adds conservative filtering so stale / low-accuracy gap-recovery fixes do not inflate trusted route distance or speed.
- **Blocked by:** Real-device validation is still required. A successful b10 package should show `bundleInfo.hasLocationBackgroundMode == true`, `hasBackgroundLocationModeDeclared == true`, and `allowsBackgroundLocationUpdates == true` before longer lock-screen tests are considered meaningful.
- **Current substitute:** Temporary internal diagnostics in `.skatetrack` packages continue to be used for Pre-ADP validation only.
- **Future task:** If b10 confirms effective background runtime but route quality still degrades, follow-up work should focus on startup warm-up, first reliable fix gates, implied-speed sanity checks, and profile-aware quality thresholds.
- **Do not claim:** Do not claim lock-screen / pocket recording is fully fixed until repeated walking, electric longboard, and vehicle-validation tests show stable callbacks and trusted route metrics.

Task-030c-b10 verification token: Effective Background Location Runtime + Gap Recovery Quality Gate, Task-030c-b10, background location runtime, stale / low-accuracy gap recovery, trusted metrics.

### Task-030c-b10-r2 — Startup speed spike and fall handling guard

- **Current status:** Task-030c-b10-r2 prevents startup coordinate-derived GPS jumps from inflating trusted speed / distance, and suppresses early lock-screen / pocket handling impacts from persisting as fall alerts. Raw samples remain available for diagnostics.
- **Still limited:** Small-area route geometry, walking-loop smoothing, and display-route stabilization are deferred to a later route-geometry task. This task does not perform map matching, road snapping, or fabricate a cleaner route.
- **Do not claim:** Do not claim small-area loops are visually corrected, do not claim all GPS drift is solved, and do not treat suppressed startup handling impacts as production-grade fall-classification telemetry.

Task-030c-b10-r2 verification token: Startup Speed Spike + Fall Handling Guard, Task-030c-b10-r2, startup coordinate-derived speed, fall handling, raw diagnostics preserved.

### Task-030c-b10-r3 — Low-speed metrics and UI responsiveness

- **Current status:** Task-030c-b10-r3 adds conservative trusted-metric gates for low-speed / small-area GPS jumps, rejects unstable Core Location altitude from elevation gain, prefers barometer-relative altitude when available, and moves package export work away from the main actor.
- **Known limitation:** This task does not make small-area loops or skateboard S-curves visually smooth. Raw GPS may still look noisy in residential or building-adjacent areas until the dedicated route geometry stabilization work is implemented.
- **Do not claim:** Do not claim S-curve route presentation, route smoothing, map matching, or road snapping is complete.

Task-030c-b10-r3 verification token: Low-Speed Metrics Gate + UI Responsiveness, Task-030c-b10-r3, low-speed metrics, elevation gain gate, UI responsiveness.


### Task-030c-b10-r4 — Strict low-speed metrics and altitude source isolation

- **Current status:** Task-030c-b10-r4 tightens low-speed metrics so suspicious Core Location speed, small-area GPS jumps, and mixed altitude sources are preserved in raw diagnostics but excluded from trusted max speed, trusted distance, and elevation gain when confidence is insufficient.
- **Pre-ADP limitation:** This is still a trusted-metric gate, not route geometry smoothing. Small-area route display, route geometry stabilization, and skateboard S-curve presentation remain deferred.
- **Do not claim:** Do not claim GPS geometry is fully stabilized, do not claim S-curve presentation is complete, and do not claim map matching / road snapping is used.

Task-030c-b10-r4 verification token: Strict Low-Speed Metrics + Altitude Source Isolation, Task-030c-b10-r4, strict low-speed metrics, altitude source isolation, barometer-relative elevation.
Task-030c-b10-r4 compatibility token: Background Location Runtime + Gap Recovery Quality Gate, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard, low-speed metrics, Startup speed spike.

### Task-030c-b10-r5 — Trusted chart metrics and display source alignment

- **Current status:** Task-030c-b10-r5 aligns user-facing charts with trusted display metrics so raw Core Location speed pulses and raw absolute-altitude startup drift do not dominate the Summary UI.
- **Raw data policy:** Raw speed, raw altitude, GPS fixes, and diagnostics remain preserved in `.skatetrack` exports. The UI may display a trusted / smoothed series for readability while diagnostics retain the underlying signal.
- **Still deferred:** Small-area route geometry stabilization, route smoothing, skateboard S-curve presentation, map matching, road snapping, and motorcycle route display continuity remain out of scope.

Task-030c-b10-r5 verification token: Trusted Chart Metrics + Display Source Alignment, Task-030c-b10-r5, trusted chart metrics, display source alignment.
Task-030c-b10-r5 compatibility token: Strict Low-Speed Metrics + Altitude Source Isolation, Low-Speed Metrics Gate + UI Responsiveness, Startup Speed Spike + Fall Handling Guard.

### Task-030c-b11 — Small-area route geometry stabilization

- **Current status:** Task-030c-b11 separates raw route samples from the Summary map display route. The app now uses trusted location fixes, small-area jitter suppression, and light display smoothing for the user-facing route preview while preserving raw GPS / IMU samples in diagnostics and exports.
- **Pre-ADP limitation:** This does not guarantee 1m absolute positioning. iPhone Core Location may still drift in residential streets, near buildings, or when the phone is in a pocket. The display route is a conservative visualization layer, not a replacement for raw data.
- **Still deferred:** Skateboard S-curve sensor-fusion presentation, IMU-assisted carving shape reconstruction, map matching, road snapping, and high-precision metric calibration remain deferred.
- **Do not claim:** Do not claim S-curve rendering is complete, do not claim road snapping / map matching is used, and do not claim raw GPS is deleted or overwritten.

Task-030c-b11 verification token: Small-area route geometry, Small-Area Route Geometry Stabilization, Task-030c-b11, rawRoute, trustedRoute, displayRoute.
Task-030c-b11 compatibility token: Trusted Chart Metrics + Display Source Alignment, Strict Low-Speed Metrics + Altitude Source Isolation.

### Task-030c-b11-r1 — Route confidence display continuity

- **Current status:** Task-030c-b11-r1 keeps low-confidence / uncertain route samples visible as secondary Summary map segments instead of treating them as route disappearance. This makes motorcycle / high-speed validation routes less misleading while preserving confidence separation for skateboard-mode summaries.
- **Pre-ADP limitation:** This is a display-continuity refinement, not high-precision positioning. Do not claim small-area loops are accurate, do not claim 1m absolute positioning, and do not claim raw GPS drift has been solved.
- **Still deferred:** IMU-assisted route reconstruction, skateboard S-curve presentation, high-precision metric calibration, map matching, road snapping, and any fabricated route geometry remain out of scope.

Task-030c-b11-r1 verification token: Route Confidence Display Continuity, Task-030c-b11-r1, low-confidence route display, uncertain route segment.

### Task-030c-b11-r2 — Activity-aware route confidence and small-area display gate

- **Current status:** Task-030c-b11-r2 aligns live route confidence and Summary display gates with the active fidelity profile so electric longboard and vehicle-validation / future snow-proxy sessions do not appear as missing route, speed, or elevation simply because standard-skateboard thresholds were too strict.
- **Still limited:** Small-area walking route geometry remains limited by GPS signal-to-noise ratio. Poor-accuracy fixes are filtered or shown as uncertain; the app does not promise 1m-level route reconstruction from GPS alone.
- **Still deferred:** IMU dead reckoning, magnetometer heading, Wi-Fi RTT diagnostics, barometric GPS outlier rejection, skateboard S-curve presentation, road snapping, and map matching remain out of scope.

Task-030c-b11-r2 verification token: Activity-Aware Route Confidence + Small-Area Display Gate, Task-030c-b11-r2, electric longboard route confidence, vehicle-validation display continuity.


Task-030c-b11-r2 compatibility token: strict low-speed metrics, altitude source isolation.


### Task-030c-b11-r3-3 — Post-record GPS lock guard and approximate start semantics

- **Current status:** Task-030c-b11-r3-3 keeps startup GPS warm-up fixes visible as uncertain route context, separates the approximate start marker from the GPS lock route anchor, and prevents medium-confidence convergence fixes from becoming the green route start.
- **Display note:** Red startup / low-quality route segments are isolated from trusted segments, and an approximate start uses a visually distinct marker when GPS lock is delayed after recording starts.
- **Region note:** Summary Map region selection prefers post-GPS-lock route coordinates when available so early convergence points do not pull the map away from the trusted route.
- **Accuracy note:** Small-area route geometry remains approximate when GPS horizontal accuracy is near the route scale. The Summary Map exposes a route accuracy disclosure instead of implying 1m-level precision.
- **Deferred:** `.skatetrack` package-size reduction, IMU / gyro / heading-aided dead reckoning, Wi-Fi RTT diagnostics, and barometric outlier rejection are not part of b11-r3.

Task-030c-b11-r3-3 verification token: Post-Record GPS Lock Guard + Approximate Start Semantics, Task-030c-b11-r3-3, GPS warming up, GPS lock route anchor, approximate start marker, startup convergence warm-up, route accuracy disclosure.

### Task-030c-b11-r4-1 — Heading availability and GPS gap diagnostics foundation

- **Current status:** Task-030c-b11-r4-1 records optional heading availability, GPS gap classification, and dead-reckoning readiness metadata for future route-continuity work.
- **Accuracy note:** This task does not make GPS 1m-accurate and does not correct absolute location drift. Locked-screen pocket sessions remain limited by normal iPhone GPS accuracy, sky visibility, multipath, and background delivery timing.
- **Route note:** r4 keeps estimated route reconstruction disabled. IMU-aided route interpolation remains deferred, and any future estimated segment must be visibly disclosed as estimated rather than trusted raw GPS.
- **Still deferred:** Device magnetometer heading provider, barometric GPS outlier rejection, Wi-Fi RTT diagnostics, IMU-aided route interpolation, road snapping / map matching, and `.skatetrack` package compression remain out of scope.

Task-030c-b11-r4-1 verification token: Heading Availability + GPS Gap Diagnostics + Dead Reckoning Readiness, Task-030c-b11-r4-1, does not make GPS 1m-accurate, IMU-aided route interpolation remains deferred.


### Task-030c-b11-r4-1 XCTest regression stabilization
- Task-030c-b11-r4-1 keeps the r4 diagnostics-only route-continuity foundation unchanged while stabilizing XCTest coverage after the r4 schema expansion.
- It removes UI-framework imports from the core SessionRecording coordinator boundary and keeps r4 diagnostics persistence covered by repository tests.


### Task-030c-b12-A — Altitude outlier guard and barometric diagnostics foundation

- **Current status:** Task-030c-b12-A records optional per-sample altitude trust diagnostics and protects trusted elevation gain from obvious CoreLocation altitude spikes.
- **What improved:** A 100m-class altitude jump can be classified as a rejected altitude outlier; rejected altitude samples preserve raw altitude for diagnostics/export but do not update trusted altitude anchors or inflate `elevationGainMeters`.
- **Scope boundary:** b12-A isolates altitude trust from horizontal route geometry. It does not reconstruct routes, estimate missing positions, perform dead reckoning, road snap, use DEM elevation lookup, or change SnowPrototype.
- **Remaining limitation:** Altitude remains consumer-device telemetry. b12-A improves robustness and honesty but does not guarantee survey-grade elevation precision. Pressure LPF, pocket-wind pressure suppression, and long-term atmospheric drift correction remain deferred to later tasks.

Task-030c-b12 verification token: AltitudeDiagnostics, AltitudeOutlierGuard, does not make altitude survey-grade, pressure LPF deferred, atmospheric drift correction deferred.

Task-030c-b12 package capability token: altitude-diagnostics-v1.

### Task-030c-b12-B — Pressure smoothing diagnostics foundation

- **Current status:** Task-030c-b12-B records optional pressure smoothing diagnostics for barometer-relative altitude samples. This helps explain raw pressure, smoothed pressure, and pressure spike suppression decisions during future analysis.
- **Altitude precision limitation:** b12-B does not guarantee survey-grade elevation precision and does not convert pressure into absolute altitude.
- **Deferred:** Pressure LPF is diagnostics-only in b12-B. Long-term atmospheric drift correction, full barometer-assisted fusion, pressure-to-altitude calibration, IMU dead reckoning, Wi-Fi RTT, indoor localization, and Snow-specific vertical dynamics remain deferred.
- **Safety boundary:** Pressure smoothing diagnostics must not alter horizontal route geometry, trusted distance, trusted speed, or estimated route behavior.

Task-030c-b12-B verification token: AltitudePressureDiagnostics, AltitudePressureFilter, Pressure LPF diagnostics, does not guarantee survey-grade elevation precision, no estimated route geometry.


### Task-030c-b13-A-4 — Route Confidence Visual + Freebord Confidence Calibration

- **Current status:** Task-030c-b13-A-4 improves how low-confidence route segments are displayed and reduces false low-confidence classifications for low-speed freebord riding when CoreLocation does not provide a valid speed scalar.
- Low-confidence route segments now use a solid fluorescent-pink style instead of a semi-transparent dashed red style. This makes uncertain but present GPS geometry look visually integrated with trusted route geometry.
- The freebord calibration is intentionally narrow: the suspicious CoreLocation-speed outlier gate only runs when CoreLocation actually reports a valid speed. The coordinate-derived local-jump gate remains active for implausible GPS jumps.
- This task does not add IMU dead reckoning, road snapping, map matching, GPS gap interpolation, indoor localization, or any estimated route geometry.
- A small amount of low-confidence route data remains expected under tree canopy, poor horizontal accuracy, stale fixes, or genuine GPS jumps.

Task-030c-b13-A-4 verification token: solid bright-orange low-confidence route segments and solid fluorescent-pink startup/warm-up segments, freebord confidence calibration, does not add IMU dead reckoning, no estimated route geometry, startup warm-up rendered as solid fluorescent pink.


### Task-030c-b13-A-4 — Display Metrics + Altitude Anchor + Route Color Semantics

- **Current status:** History/Summary display now derives corrected distance, speed, and elevation presentation from persisted motion samples and diagnostics when available. This improves existing records without rewriting raw `.skatetrack` data.
- **Color semantics:** trusted route remains teal, low-confidence/uncertain route is solid bright orange, and startup/warm-up/approximate-start route is solid fluorescent pink.
- **Altitude display:** barometer-relative profiles can be displayed against the first trusted absolute CoreLocation anchor when available; records without a trusted anchor still fall back to relative elevation presentation.
- **Still deferred:** this does not add IMU dead reckoning, route completion, road snapping, map matching, Wi-Fi RTT, or SnowPrototype changes.

Task-030c-b13-A-4 verification token: display-derived metrics, absolute elevation display anchor, diagnostics speed fallback, solid bright-orange low-confidence route segments, solid fluorescent-pink startup warm-up segments.

### Task-030c-b13-B-1 — Magnetometer Heading Diagnostics Foundation

- **Current status:** Task-030c-b13-B-1 records device magnetometer heading availability and reliability metadata for future route-continuity work.
- **What improved:** Diagnostics can now distinguish CoreLocation course-over-ground from device magnetometer heading, including heading accuracy, signal age, and course/device agreement.
- **Still deferred:** b13-B does not add IMU dead reckoning, estimated route geometry, road snapping, map matching, indoor localization, Wi-Fi RTT, or route completion.
- **Reliability limitation:** magnetometer heading can be disturbed by nearby metal, magnetic accessories, vehicles, or calibration state. It should be used as readiness metadata until a later dead-reckoning phase adds cross-sensor filtering.

Task-030c-b13-B-1 verification token: magnetometer heading diagnostics foundation, device heading reliability, course/device agreement, no estimated route geometry, no distance/speed/altitude recalculation.


Task-030c-b13-B-1 note: magnetometer heading diagnostics remain diagnostics-only; legacy sessions should continue to decode even when newer heading fields are absent.

### Task-030c-b15-B-3 — Replay-Only Dead-Reckoning Readiness Diagnostics

- **Current status:** Task-030c-b15-B-3 can classify persisted GPS gap candidates for future replay / interpolation readiness using trusted anchors, timer-fusion IMU cadence, and heading diagnostics.
- **Safety boundary:** dead reckoning remains disabled. The task does not write estimated route points, does not fill GPS gaps, and does not alter route geometry, distance, speed, altitude, confidence colors, or summary metrics.
- **Why this remains limited:** IMU dead reckoning can drift quickly, magnetometer heading can be disturbed, and small-area GPS geometry may still have signal-to-noise limits. b14-A only decides whether a gap is eligible for future replay analysis.
- **Still deferred:** production estimated route geometry, runtime gap filling, map matching, road snapping, camera-aided localization, Wi-Fi RTT, indoor localization, and SnowPrototype work remain deferred until explicitly approved.

Task-030c-b15-B-3 verification token: replay-only dead-reckoning readiness diagnostics, no estimated route geometry, dead reckoning remains disabled, preserves b13-B-1 legacy decode compatibility.


### Task-030c-b15-B-3 — Altitude Chart Source Guard

- **Current status:** The elevation chart display is now altitude-source aware. Trusted barometer-relative altitude profiles remain visually continuous across unrelated GPS stale/gap diagnostics.
- **Boundary:** This is a display-only guard. It does not change elevation gain summaries, does not rewrite stored motion samples, does not alter route geometry, and does not enable dead reckoning.
- **Remaining limitation:** CoreLocation absolute altitude can still be noisy in diagnostics; it is retained for analysis but should not be treated as authoritative when trusted barometer-relative altitude is available.

Task-030c-b15-B-3 verification token: altitude chart source guard, does not change elevation gain summaries, does not enable dead reckoning, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Altitude Chart Micro-Dip Display Guard

- **Current status:** The advanced elevation chart now has a conservative display-only micro-dip guard for very short barometer notches after the b14-A-1 source guard selects the barometer-relative profile.
- **Important limitation:** This does not change recorded altitude samples, elevation gain summaries, route geometry, or exported diagnostics. Long or real elevation trends remain visible.
- **Still deferred:** Recording-time altitude correction, production dead reckoning, and startup route visual suppression remain separate tasks.

Task-030c-b15-B-3 verification token: altitude micro-dip display guard, does not change elevation gain summaries, does not enable dead reckoning, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Startup Route Visual Suppression

- **Current status:** Startup / GPS warm-up route geometry is displayed only as solid fluorescent-pink route context and remains visually separated from trusted teal route segments.
- **Display-only:** This does not change distance, speed, altitude, elevation gain, route geometry, raw samples, exported diagnostics, or `.skatetrack` schema.
- **Still deferred:** Real route reconstruction, IMU interpolation, road snapping, map matching, and production dead reckoning remain disabled.

Task-030c-b15-B-3 verification token: startup route visual suppression, solid fluorescent-pink route context, does not change distance, speed, altitude, or route geometry, does not enable dead reckoning, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Replay-Only Candidate Gap Interpolation Prototype
- **Current status:** b14-B can create debug-only candidate interpolation points for eligible GPS gaps using conservative readiness diagnostics, trusted anchors, IMU cadence, and heading diagnostics.
- **Display note:** Startup / warm-up route context uses solid fluorescent pink with full route-line weight again, while remaining segmented away from trusted teal GPS-lock geometry.
- **Still deferred:** Production route estimation, official map correction, distance / speed / altitude metric mutation, and any `estimatedRouteActive == true` behavior remain deferred.

Task-030c-b15-B-3 verification token: replay-only candidate gap interpolation, debug-only candidate points, anchor closure blocking, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Summary Elevation Gain Source Guard
- **Current status:** The Summary climb card now uses the trusted barometer-relative altitude stream when available, so flat walking / sheltered skate sessions no longer show large climb totals caused by Core Location absolute altitude jitter.
- **Still deferred:** Recording-time altitude correction, production dead reckoning, and route geometry interpolation remain separate tasks.
Task-030c-b15-B-3 verification token: summary elevation gain source guard, trusted barometer-relative climb, does not change distance, speed, route geometry, or stored samples, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Total Elevation Gain Terminology
- **Current status:** The Summary and share-card elevation metric now uses explicit cumulative-gain wording: `總爬升量`, `Total elevation gain`, and `総獲得標高`.
- **Meaning unchanged:** The number still represents trusted cumulative positive elevation gain. It is not max altitude minus start altitude.
- **Boundary:** This is terminology-only and does not change raw samples, schema, route geometry, distance, speed, altitude charts, the b14-B-1 trusted climb calculation, or replay-only candidate interpolation.

Task-030c-b15-B-3 verification token: total elevation gain terminology, summary.metric.elevationGain, localization-only, no calculation change, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Simulator Recording Persistence Guard
- **Current status:** DEBUG iOS Simulator recording can now persist a session even when the sensor engine stop snapshot is empty. The coordinator first recovers live samples it observed during recording, and only in Simulator DEBUG can it fall back to a small debug-simulated sample set.
- **Boundary:** This does not affect real-device recording, does not change route/distance/speed/total elevation gain calculations, does not modify `.skatetrack` schema, and does not enable production dead reckoning.
- **Still deferred:** Production IMU-aided localization, real dead-reckoning route geometry, road snapping, map matching, and indoor localization remain future tasks.

Task-030c-b15-B-3 verification token: simulator recording persistence guard, debug-only simulator fallback, no production estimated route geometry, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Debug Mock Recording Pipeline Hardening
- **Current status:** Simulator/debug recordings use a more deterministic mock sample path for development validation when CoreMotion / CoreLocation simulator services are incomplete.
- **Boundary:** This remains DEBUG/simulator-only support. It does not change real-device recording, `.skatetrack` schema, distance, speed, total elevation gain, or production route geometry.
Task-030c-b15-B-3 verification token: simulator recording persistence guard, debug mock recording pipeline, no calculation change, estimatedRouteActive remains false.

### Task-030c-b15-B-3 — Simulator Save Pipeline Hardening
- **Current status:** DEBUG simulator recordings use a hardened save path that tolerates optional diagnostics encoding issues, verifies the Core Data session row after save, and avoids orphaned motion sample files.
- **Boundary:** This is still simulator/debug persistence hardening only. It does not change real-device recording behavior, schemas, distance/speed/total elevation gain semantics, or production route estimation.
Task-030c-b15-B-3 verification token: simulator save pipeline hardening, safe diagnostics encoding, resilient History fetch, no calculation change, estimatedRouteActive remains false.

### Task-030c-b16-A — Localization Foundation Audit and Sensor-Fusion Plan

- **Current status:** Task-030c-b16-A documents the post-b15-B-3 localization foundation before adding b16-B/C/D sensor-source diagnostics. It does not change recording behavior, route geometry, trusted metrics, raw samples, persistence schema, or production estimated route display.
- **Still limited:** Small-area GPS geometry cannot be perfectly reconstructed from GPS alone when route radius is comparable to horizontal accuracy. Future IMU work must remain replay-only until the b17-D real-session review pack and product decision checkpoint.
- **Deferred to later Task-030c stages:** b16-B barometric GPS cross-validation remains diagnostics-only, b16-C Wi-Fi RTT / accuracy-source classification remains passive and inferred, and b16-D heading quality remains replay-readiness metadata.
- **Deferred outside Task-030c:** indoor localization, indoor mode detector, indoor session-start anchors, and indoor accuracy disclosure are moved to Task-031.
- **Do not claim:** Do not claim production dead reckoning, estimated route activation, road snapping, fake GPS, camera localization, RTK GPS, UWB anchor dependency, or SnowPrototype integration.

Task-030c-b16-A verification token: Localization Foundation Audit and Sensor-Fusion Plan, indoor mode detector deferred to Task-031, no camera localization, no road snapping, no fake GPS, no RTK GPS dependency, no UWB anchor dependency, estimatedRouteActive remains false.

### Task-030c-b16-B — Barometric GPS Outlier Cross-Validation Diagnostics

- **Current status:** b16-B records diagnostics-only evidence when a suspicious GPS jump conflicts with barometer-relative altitude evidence. It does not reject or rewrite production route fixes.
- **User-facing impact:** no user-facing behavior change yet; the diagnostics prepare later replay review and release-gate decisions.
- **Metric safety:** trusted distance, speed, average speed, max speed, moving ratio, and total elevation gain continue to ignore estimated positions and are not changed by b16-B.
- **Estimated route safety:** `estimatedRouteActive` remains false.

Task-030c-b16-B verification token: diagnostics-only barometric GPS cross-validation, no production route rejection, productionRouteDecisionApplied false, wouldRejectIfGateWereEnabled, estimatedRouteActive remains false.

### Task-030c-b16-C — Passive Wi-Fi RTT / Accuracy Source Diagnostics

- **Current status:** Task-030c-b16-C classifies CoreLocation accuracy evidence passively. It can infer that a fix looks like likely high-precision GPS or possible Wi-Fi RTT assisted positioning, but it does not confirm Wi-Fi RTT.
- **No explicit Wi-Fi dependency:** This milestone does not add Wi-Fi scanning, Wi-Fi entitlement, explicit Wi-Fi APIs, managed RTT APIs, or router / access-point assumptions.
- **No route behavior change:** The diagnostic does not change route geometry, trusted distance, speed, average speed, max speed, moving ratio, total elevation gain, production route acceptance, or estimated route display.
- **Legacy decode:** Sessions without `locationAccuracySourceDiagnostics` continue to decode with a nil optional diagnostic.

Task-030c-b16-C verification token: passive Wi-Fi RTT / accuracy-source diagnostics, does not confirm Wi-Fi RTT, no Wi-Fi scanning, no Wi-Fi entitlement, estimatedRouteActive remains false.

### Task-030c-b16-D — Magnetometer Heading Quality Consolidation

- **Current status:** Task-030c-b16-D classifies existing course / device-magnetometer heading evidence into replay-readiness reliability levels.
- **Diagnostics-only boundary:** The heading quality assessment can inform future replay-only IMU interpolation, but it does not generate production estimated route geometry or alter route samples.
- **Legacy oversized files:** New heading quality logic is split into small files instead of expanding existing oversized production files.

Task-030c-b16-D verification token: magnetometer heading quality consolidation, HeadingReliability, replay-readiness only, no production estimated route geometry, estimatedRouteActive remains false.

### Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation

- **Current status:** Task-030c-b17-0 summarizes b16-B/C/D diagnostics into a replay-only review pack foundation for future analysis.

- **v1.2 alignment:** This is not the full `Task-030c-b17` Replay-Only IMU Gap Interpolation Engine from `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`. The next required milestone remains `Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation`. It can count suspicious barometric GPS outlier evidence, passive accuracy-source inference, and heading replay-readiness, but it does not correct or rewrite the route.
- **Production boundary:** No production route mutation is enabled. The review pack is diagnostics-only and replay-review-only; `productionRouteMutationApplied` remains false and `estimatedRouteActive` remains false.
- **Localization boundary:** The visible DEBUG build signature uses localized keys instead of hard-coded visible strings.

Task-030c-b17-0 verification token: localization diagnostics review pack foundation, replay-review-only, no route mutation, localized DEBUG build signature, estimatedRouteActive remains false.

### Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation

- **Current status:** Task-030c-b17-A adds the mathematical IMU replay foundation requested by `Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2`: local tangent coordinate conversion, low-motion accelerometer bias estimation, and gravity-compensated motion samples.
- **Boundary:** No route geometry is generated. No replay estimate is integrated into the route map. No trusted metrics are changed. No CoreLocation manager side effects are introduced.
- **Next milestone:** Task-030c-b17-B must add the replay-only dead-reckoning engine before closure scoring or real-session review packs can be produced.

Task-030c-b17-A verification token: local tangent coordinate frame, sensor bias foundation, no production route geometry, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b17-B — Replay-Only Dead Reckoning Engine v1

- **Current status:** Task-030c-b17-B can generate replay-only IMU candidate estimates between trusted GPS anchors for debugging and analysis.
- **Production boundary:** The generated `DeadReckoningReplayEstimate` values are diagnostics, not production route geometry. They do not change route map rendering, trusted distance, speed, average speed, max speed, total elevation gain, or exported trusted metrics.
- **Drift disclosure:** The first drift model uses the conservative named `estimatedPositionDriftRateMetersPerSecond = 0.5` constant. This must be recalibrated only after b17-D real-session closure-error measurements exist.
- **Next milestone:** Task-030c-b17-C must add anchor closure error and confidence scoring before any real-session review pack or display model work.

Task-030c-b17-B verification token: replay-only dead reckoning engine, no production route geometry, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b17-C — Anchor Closure Error and Confidence Scoring

- **Current status:** Task-030c-b17-C scores replay-only IMU estimates with closure error, closure-error ratio, heading reliability, IMU coverage, conservative eligibility, and blocking reasons.
- **Production boundary:** No user-visible estimated route is enabled by this milestone. The closure score does not change route map rendering, trusted distance, speed, average speed, max speed, total elevation gain, or exported trusted metrics.
- **Data dependency:** These thresholds remain conservative until b17-D real-session replay review packs provide closure-error evidence from walking, electric longboard, motorcycle proxy, and known GPS-gap sessions.
- **Next milestone:** Task-030c-b17-D must produce the real-session replay review pack before any b18 display or production eligibility gate work begins.

Task-030c-b17-C verification token: anchor closure error and confidence scoring, no user-visible route display, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b17-D — Real-Session Replay Review Pack

- **Current status:** Task-030c-b17-D can turn real-session replay diagnostics into review-pack artifacts for `Task030c_b17D_ReplayReviewPack.zip`, including JSON, Markdown, and CSV outputs.
- **Evidence captured:** Each gap record includes gap duration, IMU coverage, heading reliability, estimated displacement, anchor closure error, closure-error ratio, conservative eligibility, replay blocking reason, and blocking reasons.
- **Production boundary:** The review pack remains replay-review-only. No user-visible estimated route is enabled, no route map rendering changes are made, and no trusted metrics are mutated. `estimatedRouteActive` remains false.
- **Decision boundary:** The b17-D review pack is evidence for the required non-code product decision checkpoint. b18 display model work and any production eligibility gate must remain blocked until that decision checkpoint is complete.

Task-030c-b17-D verification token: real-session replay review pack, no user-visible route display, no trusted metric mutation, product decision checkpoint required, estimatedRouteActive remains false.

### Task-030c-b17-D-3 — Real-Session Review Runner / Export Glue

- **Current status:** Task-030c-b17-D-3 can generate `Task030c_b17D_ReplayReviewPack.zip` from real `.skatetrack` exports for review-only product-decision evidence.
- **Safety boundary:** It does not enable user-visible estimated route display, does not mutate production route geometry, does not modify route maps, and does not change trusted distance, speed, or elevation metrics.
- **Review limitation:** The runner is an offline diagnostic tool. Its output helps decide whether b18 should display any estimated route segment, but it is not itself a production route correction feature.

Task-030c-b17-D-3 verification token: real-session review runner, `.skatetrack` inputs, no user-visible estimated route display, no trusted metric mutation, product decision checkpoint required, estimatedRouteActive remains false.

### Task-030c-b18-A — Product Decision Gate and In-Memory Estimated Route Display Decision

- **Current status:** Task-030c-b18-A can classify b17-D replay review gap records into in-memory display decision states for product review.
- **Product boundary:** This is not general-user estimated route display. All b18-A decisions are hidden/review-only and are not persisted.
- **Persistence boundary:** No Core Data attribute, `SessionRepository` persistence, `SessionEntityMapper` mapping, or `.skatetrack` package schema change is introduced for estimated route display decisions.
- **Safety boundary:** `productionRouteMutationApplied`, `trustedMetricsMutationApplied`, `estimatedRouteDisplayEnabled`, and `estimatedRouteActive` remain false.
- **Threshold boundary:** Candidate consideration is tightened to `maximumCandidateGapDurationSeconds = 6`; gaps up to `maximumReviewOnlyGapDurationSeconds = 30` are review-only or future product-review evidence, not product display.

Task-030c-b18-A verification token: in-memory display gate, no user-visible estimated route display, no trusted metric mutation, no persistence, product decision checkpoint required, estimatedRouteActive remains false.


### Task-030c-b18-B — Review-Only Estimated Route Overlay Artifact

- **Current status:** Task-030c-b18-B can convert b18-A in-memory display decisions into review-only overlay artifact records for product-decision inspection.
- **Product boundary:** The overlay artifact is not a normal route overlay and is not visible to general users. It is review evidence only.
- **Persistence boundary:** No Core Data attribute, `SessionRepository` persistence, `SessionEntityMapper` mapping, or `.skatetrack` schema change is introduced for estimated route review overlays.
- **Safety boundary:** `productionRouteMutationApplied`, `trustedMetricsMutationApplied`, `estimatedRouteDisplayEnabled`, `userVisibleDisplayAllowed`, and `estimatedRouteActive` remain false.
- **Regression boundary:** The electric skateboard core candidate, walking low-speed trap, sheltered surfskate high-risk case, and motorcycle pressure test must not be promoted to product display; motorcycle-control candidates remain hidden review evidence only.

Task-030c-b18-B verification token: review-only overlay artifact, five real-session regression traps, no user-visible estimated route display, no route geometry, no persistence, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c-b18-C — DEBUG-Only Estimated Route Review Panel

- **Current status:** Task-030c-b18-C can show b18-B review-only overlay records in a DEBUG-only panel for developer inspection.
- **Product limitation:** The panel is not general-user UI and is not reachable in release builds.
- **Route limitation:** The panel does not render route polylines, path shapes, Canvas previews, map overlays, or route-like geometry of any kind.
- **Safety boundary:** `productionRouteMutationApplied`, `trustedMetricsMutationApplied`, `estimatedRouteDisplayEnabled`, `userVisibleDisplayAllowed`, and `estimatedRouteActive` remain false.
- **Persistence boundary:** No Core Data, SessionRepository, SessionEntityMapper, or `.skatetrack` schema persistence is added.

Task-030c-b18-C verification token: DEBUG-only review panel, full `#if DEBUG` boundary, localized panel strings, no user-visible estimated route display, no route rendering, no persistence, no trusted metric mutation, estimatedRouteActive remains false.


### Task-030c-b18-D — Real-Session Recheck and Product Decision Update

- **Current status:** Task-030c-b18-D records the b18 real-session recheck decision using the existing five-session evidence baseline. General-user estimated route display remains disabled.
- **Evidence boundary:** New real-world sessions are optional for this milestone. The five b17-D-3 roles remain sufficient to complete the b18-D review artifact.
- **Product limitation:** The decision outcome is `keepDisabled`; DEBUG/review-only inspection remains allowed, but product display remains blocked.
- **Route limitation:** No route polylines, route coordinates, path shapes, Canvas previews, map overlays, or route-like geometry are introduced.
- **Safety boundary:** `productionRouteMutationApplied`, `trustedMetricsMutationApplied`, `estimatedRouteDisplayEnabled`, `userVisibleDisplayAllowed`, `generalUserEstimatedRouteDisplayAllowed`, and `estimatedRouteActive` remain false.
- **Persistence boundary:** No Core Data, SessionRepository, SessionEntityMapper, or `.skatetrack` schema persistence is added.

Task-030c-b18-D verification token: real-session recheck product decision update, outcome keepDisabled, no user-visible estimated route display, no route rendering, no persistence, no trusted metric mutation, estimatedRouteActive remains false.


### Task-030c-b19 — Outdoor Localization Release Gate

- **Current status:** Task-030c-b19 adds a conservative outdoor localization release gate for real-GPS release-quality classification.
- **Product limitation:** The release gate can classify evidence as `releaseReady`, `limitedDisclosure`, or `blocked`, but it does not enable estimated route display or route reconstruction.
- **Safety boundary:** `generalUserEstimatedRouteDisplayAllowed`, `estimatedRouteDisplayEnabled`, `estimatedRouteActive`, `routeGeometryMutationApplied`, `trustedMetricsMutationApplied`, and `persistenceSchemaMutationApplied` remain false.
- **Persistence boundary:** b19 introduces no Core Data, `SessionRepository`, `SessionEntityMapper`, export payload, or `.skatetrack` schema change.

Task-030c-b19 verification token: outdoor localization release gate, releaseReady, limitedDisclosure, blocked, realGPSOnly true, no user-visible estimated route display, no route rendering, no persistence, no trusted metric mutation, estimatedRouteActive remains false.

### Task-030c Final Closure Audit — Post-b19 Outdoor Localization Baseline

- **Current status:** Task-030c is ready for final closure after `2cc0550 Task-030c-b19 add outdoor localization release gate`, pending the dedicated docs-only closure commit and merge back to `develop`.
- **Section 5 coverage:** The Task-030c v1.2 Final Definition of Done is covered by the completed b13–b19 chain: honest startup / warm-up visuals, distinct low-confidence route styling, conservative bad-GPS diagnostics, stable trusted metrics, replay-only IMU gap estimates, closure-error scoring, real-session review artifacts, conservative b18-D product decision, and b19 outdoor localization release gate.
- **Estimated route product decision:** The final b18-D decision remains `keepDisabled`. General-user estimated route display is not enabled by Task-030c closure. DEBUG/review-only inspection artifacts may remain, but they must not be represented as normal product route correction.
- **Outdoor release gate:** b19 classifies real-GPS outdoor localization evidence as `releaseReady`, `limitedDisclosure`, or `blocked`. This is a release-quality classification over real localization evidence, not estimated-route reconstruction.
- **Still limited:** Small-area GPS loops, sheltered environments, startup warm-up, low-speed localization traps, and long GPS gaps must still be disclosed or blocked when evidence quality requires it. Task-030c does not claim perfect reconstruction of small-area routes.
- **Indoor scope:** Indoor localization remains outside Task-030c and is tracked under Task-031. Task-030c only provides passive accuracy-source diagnostics, heading quality diagnostics, and honesty scaffolding that Task-031 can reuse.
- **Persistence boundary:** Task-030c final closure adds no Core Data schema, `SessionRepository`, `SessionEntityMapper`, export payload, or `.skatetrack` schema persistence for estimated route decisions, review overlays, product decisions, or b19 release gates.
- **Safety boundary:** `generalUserEstimatedRouteDisplayAllowed`, `estimatedRouteDisplayEnabled`, `estimatedRouteActive`, `routeGeometryMutationApplied`, `trustedMetricsMutationApplied`, and persistence/schema mutation remain false.
- **Do not claim:** Do not claim production estimated route display, route reconstruction, map matching, road snapping, fake GPS, camera localization, RTK, UWB consumer-flow dependency, indoor estimated route geometry, or trusted metrics derived from estimated geometry.

Task-030c final closure verification token: Section 5 closure checklist mapped to commits, `2cc0550`, b18-D outcome `keepDisabled`, b19 outdoor localization release gate, Task-031 indoor handoff, no user-visible estimated route display, no route geometry mutation, no trusted metric mutation, no persistence/schema mutation.

### Task-030d-A iOS `.skatetrack` Import Limitations

- **Current status:** iOS can select multiple `.skatetrack` files, stage them temporarily, validate each package independently, preview per-file status, and import selected valid packages after confirmation.
- **No silent overwrite:** Existing session IDs are classified as already imported and are skipped. Duplicate candidates are surfaced for review rather than merged or overwritten.
- **No silent merge:** Multiple packages are never merged automatically. Duplicate package/session candidates stay blocked in the first import foundation.
- **Schema boundary:** Task-030d-A does not change `.skatetrack` package schema, manifest format, checksum behavior, Core Data schema, signing, entitlements, or document associations.
- **Safety boundary:** Import stores exported session payloads as-is; it does not reconstruct route geometry, mutate trusted metrics, enable estimated-route display, road-snap, map-match, or fabricate GPS samples.
- **Still limited:** Package checksum validation is not added because the current portable `.skatetrack` payload has no checksum field. Conflict-resolution UI beyond conservative duplicate blocking remains future work.
- **Out of scope:** Production sync/cloud import, Watch / WatchBridge, Task-031 indoor localization, and Task-030e macOS multi-package viewer remain separate tasks.

Task-030d-A limitation token: iOS multi-file .skatetrack import, no silent overwrite, no silent merge, no route geometry mutation, no trusted metrics mutation, no package schema change.

### Task-030e-MacViewer-002 — Browser-First macOS Viewer IA Limitation

- **Current status:** The macOS app now treats Session Browser as the primary `.skatetrack` review surface and opens packages from within that browser flow.
- **Still deferred:** Multi-package in-memory state, true multi-file open, package cards, MapKit route context, iOS route visual parity, expanded route inspection, drag-and-drop, persistent recent files, bookmarks, database import, merge, restore, and cloud sync remain later Task-030e subtasks.
- **Safety boundary:** This step is read-only. It does not mutate package schema, route geometry, trusted metrics, Core Data, or local session storage.

Task-030e-MacViewer-002 limitation token: browser-first macOS Session Browser shell, Open Packages copy, Import destination demoted, no multi-package state yet, no MapKit yet, no import/merge/restore/sync, aligned `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.

### Task-030e-MacViewer-003 — Multi-Package State Foundation Limitation

- **Current status:** macOS now has an in-memory multi-package viewer state foundation aligned with `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.
- **User-visible behavior:** The visible file picker still opens one `.skatetrack` package at a time in this subtask. Multi-package cards, true multi-file open, partial-success package cards, and expanded map inspection remain later Task-030e subtasks.
- **Read-only guarantee:** The state layer is memory-only and performs no database import, merge, restore, cloud sync, package schema mutation, route geometry mutation, trusted metrics mutation, or route correction.

Task-030e-MacViewer-003 limitation token: in-memory package collection state, selected package/session state, single-file compatibility retained, multi-file open foundation implemented, no MapKit yet, no import/merge/restore/sync, aligned `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.

### Task-030e-MacViewer-004 — Multi-File Open Foundation Limitation

- **Current status:** macOS Session Browser can select multiple `.skatetrack` files through `NSOpenPanel.allowsMultipleSelection = true` and read valid packages independently in memory.
- **Implemented boundary:** `MacPackageOpenCoordinator` validates extensions, uses security-scoped access per URL, reads packages through `SkateTrackPackageReader`, and records per-file failures so partial success is preserved.
- **Still deferred:** package cards, rich batch summary UI, persistent recent files/bookmarks, drag-and-drop, Finder open-with, custom UTType/document association, MapKit route context, expanded route inspection, database import/merge/restore/sync, and cloud sync.
- **Do not claim:** Do not claim Finder document handling, persistent library import, package merge, restore, automatic sync, route correction, map matching, or route geometry mutation.

Task-030e-MacViewer-004 limitation token: multi-file open foundation, `MacPackageOpenCoordinator`, partial success, read-only, no custom UTType, no document association, package cards deferred, MapKit deferred, no import/merge/restore/sync, aligned `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.

### Task-030e-MacViewer-005 — Package Cards and Batch Summary Limitation

- **Current status:** macOS Session Browser now shows opened package cards and a batch summary so users can switch between packages opened in Task-030e-MacViewer-004.
- **Implemented boundary:** Package cards select an in-memory package preview and can remove a package from the current viewer state. This is a read-only browsing affordance, not a database import or persistent library.
- **Still deferred:** selected package session list refinement, persistent recent files/bookmarks, drag-and-drop, Finder open-with, custom UTType/document association, MapKit route context, iOS route visual parity, expanded route inspection, database import/merge/restore/sync, and cloud sync.
- **Do not claim:** Do not claim persistent package library management, Finder document handling, automatic package merge, restore, route correction, map matching, route geometry mutation, or trusted metrics mutation.

Task-030e-MacViewer-005 limitation token: package cards and batch summary, `MacPackageCardListView`, package switching, package removal, read-only in-memory UI, selected package session list deferred, MapKit deferred, no import/merge/restore/sync, aligned `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.

### Task-030e-MacViewer-006 — Selected Package Sessions List Limitation

- **Current status:** macOS Session Browser now shows an explicit session list for the currently selected opened package so users can switch the selected session before reading the detail dashboard.
- **Implemented boundary:** Session rows update only the in-memory selected session state. They do not import packages into local storage, persist bookmarks, merge packages, restore backups, sync cloud data, or modify package payloads.
- **Still deferred:** MapKit route context, iOS route visual parity, expanded route inspection, persistent recent files/bookmarks, drag-and-drop, Finder open-with, custom UTType/document association, database import/merge/restore/sync, and cloud sync.
- **Do not claim:** Do not claim persistent package library management, automatic package merge, restore, route correction, map matching, route geometry mutation, or trusted metrics mutation.

Task-030e-MacViewer-006 limitation token: selected package sessions list, `MacPackageSessionListView`, selected session switching, read-only in-memory UI, MapKit deferred, route inspection deferred, no import/merge/restore/sync, aligned `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.


### Task-030e-MacViewer-007A — Read-Only MapKit Route Context Limitation

- **Current status:** macOS Session Browser route preview now uses a read-only MapKit context for existing `.skatetrack` route samples.
- **Implemented boundary:** `MacRouteMapContextView` uses opened package route samples to draw the visible route on `MKMapView`; it does not request current location, show user location, road-match, snap-to-road, reconstruct route geometry, edit samples, or mutate trusted metrics.
- **Still deferred:** iOS route visual parity, expanded route inspection, route-detail sheet/window, drag-and-drop, Finder open-with, custom UTType/document association, persistent recent files/bookmarks, database import/merge/restore/sync, and cloud sync.
- **Do not claim:** Do not claim route correction, map matching, road snapping, route reconstruction, current-location tracking, persistent package library management, trusted metric mutation, or production route editing.

Task-030e-MacViewer-007A limitation token: read-only MapKit route context, `MacRouteMapContextView`, existing route samples only, no current location, no road matching, no snap-to-road, no route geometry mutation, no trusted metrics mutation, no import/merge/restore/sync, aligned `SkateTrack_BuildPlan_Task-030e_MacOS_MultiPackage_Viewer_EN_v1.2`.

## Task-030e-MacViewer-007B route inspection boundaries
- macOS expanded route inspection is read-only and displays existing `.skatetrack` route samples only.
- iOS-style route colors are visual continuity cues only; they do not indicate route correction, confidence scoring, road matching, snapping, or reconstructed geometry.
- The viewer still does not write to Core Data, mutate packages, request location permission, show current user location, or change trusted metrics.

### Task-030e-MacViewer-012 — Documentation Sync and Current macOS Viewer Boundary

- **Current status:** Documentation now reflects the Task-030e macOS multi-package viewer state through verifier / documentation sync. The viewer supports browser-first multi-file open, in-memory package cards, selected package sessions, read-only MapKit route context, iOS route visual parity, expanded route inspection, display-only speed/elevation/total-ascent views, duplicate attention warnings, duplicate-file acknowledgement, localization/accessibility polish, and consolidated verification.
- **Read-only boundary:** This remains a read-only `.skatetrack` review surface. It does not import packages into local history, merge packages, delete duplicates, choose a winner, restore data, or persist a package library.
- **Route boundary:** Route display uses existing package route samples. It does not request location permission, show user location, perform road matching, snap to road, reconstruct route geometry, mutate trusted metrics, or rewrite package data.
- **Platform boundary:** Finder open-with, custom UTType/document association, drag-and-drop, persistent recent files/bookmarks, Watch / WatchBridge, cloud sync, and Task-031 shared visualization pipeline work remain deferred.
- **Verification boundary:** `scripts/run_task030e_macos_multi_package_viewer_oneclick.sh` is the source-controlled Task-030e one-click runner. It must zip logs, delete the temporary run directory, and record `ONECLICK_RUN_DIR_REMOVED=YES` after packaging.

Task-030e-MacViewer-012 limitation token: Documentation Sync, current macOS multi-package viewer boundary, read-only package review, ONECLICK_RUN_DIR_REMOVED=YES, no import, no merge, no route mutation, no Core Data write.
