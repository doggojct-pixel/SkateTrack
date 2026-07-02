# Task-030c-b16-A — Localization Foundation Audit and Sensor-Fusion Plan

**Project:** SkateTrack iOS / macOS / watchOS  
**Branch:** `task-030c-gps-route-fidelity`  
**Baseline commit:** `b3ab7a0 Task-030c-b15-B stabilize simulator recording persistence`  
**Build identity:** `Task-030c-b16-A`  
**Milestone type:** repo-local planning / audit / verification guard  
**Production behavior change:** none  
**Production route geometry change:** none  
**Trusted metric change:** none  
**Estimated route activation:** forbidden; `estimatedRouteActive` remains false

---

## 1. Objective

`Task-030c-b16-A` is a repo-local planning checkpoint before implementing the sensor-source diagnostics milestones in `Task-030c-b16-B`, `Task-030c-b16-C`, and `Task-030c-b16-D`.

This milestone reconciles the current post-`Task-030c-b15-B-3` codebase with the uploaded localization roadmap and small-area localization analysis. It exists to prevent duplicated work, accidental production dead reckoning, over-claiming Wi-Fi RTT evidence, or silently mutating trusted route / metric behavior.

`Task-030c-b16-A` is documentation and verification only, except for the DEBUG build identity token advancing to `Task-030c-b16-A`.

---

## 2. Confirmed baseline after b15-B-3

The confirmed local baseline already includes:

```text
b3ab7a0 Task-030c-b15-B stabilize simulator recording persistence
0ac958c Task-030c-b15 rename total elevation gain metric
e757463 Task-030c-b14 stabilize replay diagnostics and summary altitude metrics
6783afb Task-030c-b13-B-1 preserve legacy heading diagnostics decoding
00f3ea0 Task-030c-b13-B add magnetometer heading diagnostics
c2f5617 Task-030c-b13-A-4 stabilize display metrics and altitude anchoring
bfcf751 Task-030c-b13-A calibrate freebord confidence and route visuals
d167192 Task-030c-b12-B add pressure smoothing diagnostics
bcc83c4 Task-030c-b12 add altitude outlier guard diagnostics
ec41572 Task-030c-b11-r4-1 add diagnostics foundation and stabilize tests
a96e48b Task-030c-b11-r3 stabilize startup GPS route anchors
a7f26fa Task-030c-b10 stabilize GPS diagnostics and trusted metrics
09905c0 Task-030c-a add GPS diagnostics package metadata
```

Current confirmed behavior:

- Simulator recording can persist sessions and show them in History.
- DEBUG simulated route / speed can drive the Live HUD speed trace.
- The History / save pipeline is resilient to legacy or corrupt rows and non-conforming float diagnostics.
- `Task-030c-b15-B-3` restored development velocity for future localization work.
- `estimatedRouteActive` remains false.
- The user-facing elevation-gain label is now explicit cumulative-gain wording:
  - `zh-Hant`: `總爬升量`
  - `en`: `Total elevation gain`
  - `ja`: `総獲得標高`

---

## 3. Hard scope boundaries

The following are non-goals for b16-A and must remain non-goals through b16-B/C/D unless a later product checkpoint explicitly changes them:

- No external hardware requirement.
- No road snapping.
- No fake GPS.
- No SnowPrototype contamination.
- No camera localization for core SkateTrack recording.
- No camera-based visual localization.
- No RTK GPS dependency.
- No UWB anchor dependency for the consumer app path.
- No mutation of raw samples to hide sensor uncertainty.
- No estimated positions for trusted distance.
- No estimated positions for max speed.
- No estimated positions for average speed.
- No estimated positions for moving ratio.
- No estimated positions for total elevation gain.
- No production dead reckoning.
- No production estimated route display before the b17-D review pack and product decision checkpoint.

The controlling invariant remains:

```text
estimatedRouteActive remains false
```

---

## 4. What already exists in the codebase

### 4.1 Existing `MotionSample` foundation

`MotionSample` already supports the data required for later replay-only localization analysis:

```swift
id
timestamp
timestampMillisecondsSince1970
gpsCoordinate
speedKmh
accelerometerG
gyroscopeRadPS
altitudeMeters
altitudeSource
altitudeDiagnostics
locationDiagnostics
sampleSource
```

Implications:

- `accelerometerG` and `gyroscopeRadPS` are already available for future IMU replay-only gap interpolation.
- `altitudeMeters`, `altitudeSource`, and `altitudeDiagnostics` are already available for barometer-vs-GPS altitude analysis.
- `locationDiagnostics` is the correct optional extension point for new per-location diagnostic models.
- `sampleSource` can distinguish `timerFusion`, `locationFix`, and `debugSimulated` samples.

### 4.2 Existing `LocationFixDiagnostics` foundation

`LocationFixDiagnostics` already contains:

```swift
horizontalAccuracyMeters
verticalAccuracyMeters
speedAccuracyMetersPerSecond
courseAccuracyDegrees
rawLocationTimestamp
rawLocationTimestampMillisecondsSince1970
receivedAtTimestamp
receivedAtTimestampMillisecondsSince1970
gpsUpdateIntervalSeconds
gpsSegmentDistanceMeters
coordinateDerivedSpeedKmh
speedSource
freshnessState
routeSegmentConfidence
headingDiagnostics
gpsGapDiagnostics
deadReckoningDiagnostics
```

Implications:

- b16-B can add an optional `BarometricGPSOutlierDecision`-style diagnostic field without changing trusted route behavior.
- b16-C can add an optional passive `LocationAccuracySourceClass` diagnostic without using explicit Wi-Fi APIs.
- b16-D can add optional heading reliability classification without breaking legacy `.skatetrack` decode.
- All future diagnostic additions must remain optional and legacy-safe.

### 4.3 Existing altitude diagnostics foundation

Task-030c-b12 and b12-B already introduced:

- `AltitudeDiagnostics`
- `AltitudeOutlierGuardConfig`
- `AltitudeOutlierGuard`
- `AltitudePressureDiagnostics`
- `AltitudePressureFilterConfig`
- `AltitudePressureFilter`
- source-isolated CoreLocation absolute altitude and barometer-relative altitude handling
- trusted altitude source preference for summary climb and chart display

Important distinction for b16-B:

b16-B is not another total-elevation-gain fix. It is a horizontal route-quality diagnostic that asks whether suspicious GPS horizontal movement conflicts with barometer-relative altitude evidence.

### 4.4 Existing heading diagnostics foundation

`HeadingDiagnostics` already contains:

```swift
source
headingAvailable
courseOverGroundDegrees
courseAccuracyDegrees
coreLocationSpeedKmh
courseReliableForRouteContinuity
deviceHeadingDeferred
deviceHeadingDegrees
deviceHeadingAccuracyDegrees
deviceHeadingTimestamp
deviceHeadingTimestampMillisecondsSince1970
deviceHeadingAgeSeconds
deviceHeadingReliableForRouteContinuity
courseDeviceHeadingDeltaDegrees
courseDeviceHeadingAgreement
```

`HeadingDiagnosticsSource` already contains:

```swift
coreLocationCourse
deviceMagnetometer
courseAndDeviceMagnetometer
unavailable
```

Implications:

- b16-D should consolidate heading quality instead of rebuilding heading capture.
- Heading quality should become an explicit replay-readiness gate.
- Heading quality must remain diagnostics-only in b16-D.
- b16-D must not produce production estimated route geometry.

### 4.5 Existing dead-reckoning diagnostics and replay-only prototype

The branch already contains replay-only readiness and candidate interpolation scaffolding:

```swift
DeadReckoningDiagnostics
DeadReckoningReadinessConfig
DeadReckoningReadinessGapCandidate
DeadReckoningReadinessSummary
DeadReckoningReadinessAnalyzer
DeadReckoningCandidateInterpolationAnalyzer
DeadReckoningCandidateInterpolationResult
DeadReckoningCandidateInterpolationSummary
```

Implications:

- b17 should build on the existing replay-only path.
- b16-D should feed cleaner heading reliability into b17 readiness.
- Existing candidate interpolation is not production route geometry.
- Existing candidate interpolation must not affect distance, speed, total elevation gain, route geometry, persisted samples, or exports.

### 4.6 Existing route confidence and visual semantics

Current route visual semantics:

| Segment type | Meaning | Current style |
|---|---|---|
| Trusted GPS route | high / medium-confidence GPS route | teal / green, solid |
| Low-confidence GPS route | degraded but honest GPS context | bright orange, solid |
| Startup warm-up GPS route | approximate warm-up context, not trusted GPS-lock geometry | fluorescent pink, solid |
| Estimated IMU route | not enabled yet | to be defined in b18-A only if approved |

Older references to red dashed low-confidence styling are superseded by the b13-A route palette.

### 4.7 Existing simulator-only development paths

After b15-B-3, the following paths exist only to support development and simulator verification:

- DEBUG simulated route provider.
- DEBUG simulated speed driving the Live HUD trace.
- Simulator recording persistence recovery.
- Simulator DEBUG fallback session creation when real simulator sensor services are incomplete.
- Debug Tools build identity display.
- Simulator-specific persistence safeguards for coordinate-less timerFusion samples.

These paths must not be treated as real-device localization evidence.

### 4.8 Real-device-only validation paths

The following cannot be fully validated by simulator:

- Real CoreLocation GPS accuracy and freshness.
- Real CoreLocation course-over-ground and course accuracy.
- Real CLHeading / magnetometer accuracy, age, and disturbance behavior.
- Real CMAltimeter relative altitude stability in pocket / outdoor movement.
- Real lock-screen / pocket / background location update gaps.
- Real possible Wi-Fi-assisted CoreLocation accuracy behavior.
- Real SLC wakeup or degraded-GPS behavior.

---

## 5. Sensor-fusion milestone plan

### 5.1 b16-B — Barometric GPS Outlier Cross-Validation Diagnostics

Objective:

Add diagnostics that compare suspicious GPS jumps against barometer-relative altitude evidence.

Expected direction:

```text
iOS/Core/SensorEngine/BarometricGPSOutlierGuard.swift
Shared/Models/MotionSample.swift
Shared/Models/SessionData.swift
RecordingDebugDiagnosticsCollector or related diagnostics flow
scripts/verify_task030c_b16b_barometric_gps_outlier_guard.py
```

Suggested optional model:

```swift
enum GPSOutlierDiagnosticReason: String, Codable, Sendable, Equatable {
    case barometricAltitudeConflict
    case impliedSpeedTooHigh
    case staleLocationAfterGap
    case poorHorizontalAccuracy
    case insufficientBarometricEvidence
}

struct BarometricGPSOutlierDecision: Codable, Sendable, Equatable {
    let timestamp: Date
    let candidateHorizontalJumpMeters: Double
    let candidateGPSAltitudeDeltaMeters: Double?
    let barometerAltitudeDeltaMeters: Double?
    let discrepancyMeters: Double?
    let productionRouteDecisionApplied: Bool
    let wouldRejectIfGateWereEnabled: Bool
    let diagnosticReason: GPSOutlierDiagnosticReason?
}
```

Safety rule:

- `productionRouteDecisionApplied` must always be false in b16-B.
- `wouldRejectIfGateWereEnabled` may become true only as diagnostics.
- b16-B must not reject a production route fix.
- b16-B must not rewrite route geometry.
- b16-B must not rewrite raw samples.
- b16-B must not change trusted distance, speed, average speed, max speed, moving ratio, or total elevation gain.
- b16-B must not enable estimated route.

### 5.2 b16-C — Passive Wi-Fi RTT / Accuracy Source Diagnostics

Objective:

Make likely accuracy source visible in diagnostics without adding Wi-Fi entitlements or explicit Wi-Fi APIs.

Expected direction:

```text
iOS/Core/SensorEngine/LocationAccuracySourceClassifier.swift
Shared/Models/MotionSample.swift
Shared/Models/SessionData.swift
scripts/verify_task030c_b16c_wifi_rtt_accuracy_source_diagnostics.py
```

Suggested optional enum:

```swift
enum LocationAccuracySourceClass: String, Codable, Sendable, Equatable {
    case highPrecisionGPSOrWiFiRTT
    case goodGPSOrWiFiRTT
    case typicalGPS
    case degradedGPS
    case cellOrCachedPosition
    case unknown
}
```

Initial passive heuristic:

```text
horizontalAccuracy < 3m       likely high-precision GPS or Wi-Fi RTT
3m...8m                       good GPS or Wi-Fi RTT
8m...20m                      typical GPS
20m...50m                     degraded GPS
> 50m                         cell, cached, or poor indoor fallback
missing                       unknown
```

Safety rule:

- No explicit Wi-Fi API usage.
- No Wi-Fi entitlement.
- No claim of confirmed Wi-Fi RTT.
- Use language such as `likely`, `possible`, or `inferred`.
- Do not use language such as `confirmed`, `active Wi-Fi RTT`, or `managed RTT`.
- No route mutation.
- No trusted metric mutation.
- No estimated route activation.

### 5.3 b16-D — Magnetometer Heading Quality Consolidation

Objective:

Turn existing heading diagnostics into a formal reliability classification for future replay-only IMU interpolation.

Expected direction:

```text
iOS/Core/SensorEngine/HeadingQualityClassifier.swift
Shared/Models/MotionSample.swift
scripts/verify_task030c_b16d_heading_quality_gate.py
```

Suggested optional enum:

```swift
enum HeadingReliability: String, Codable, Sendable, Equatable {
    case high
    case moderate
    case poor
    case invalid
    case unavailable
}
```

Initial thresholds:

```text
unavailable     no heading sample
invalid         heading accuracy < 0
high            0...5 degrees
moderate        >5...20 degrees
poor            >20 degrees
tooOld          age exceeds configured threshold
```

Safety rule:

- b16-D may affect replay-readiness diagnostics only.
- b16-D must not produce production estimated route geometry.
- b16-D must not display estimated route to normal users.
- b16-D must not rewrite GPS samples.
- b16-D must not rewrite route geometry.
- b16-D must not change trusted distance, speed, average speed, max speed, moving ratio, or total elevation gain.

---

## 6. b17 / b18 / b19 boundary

### 6.1 b17 — Replay-only IMU gap interpolation engine

b17 may build a replay-only interpolation engine using:

- local tangent coordinate frame
- IMU cadence
- accelerometer / gyroscope samples
- heading reliability from b16-D
- trusted pre-gap and post-gap GPS anchors
- anchor-closure error diagnostics

b17 must remain replay-only and must not change production route geometry.

### 6.2 Product decision checkpoint after b17-D

After `Task-030c-b17-D` produces a real-session replay review pack, a product decision checkpoint is required before any general-user estimated route display.

The checkpoint must decide whether estimated route visualization is acceptable, and under what UI disclosure and metric isolation rules.

### 6.3 b18 — Estimated route display and production safety gate

b18 may only proceed after the product decision checkpoint.

Even if b18 displays estimated route geometry, estimated positions must remain excluded from:

- trusted distance
- max speed
- average speed
- moving ratio
- total elevation gain

### 6.4 b19 — Outdoor Localization Release Gate

b19 should validate outdoor localization behavior after b16/b17/b18 decisions. It should not become indoor localization.

---

## 7. Task-031 indoor localization boundary

Indoor localization is moved out of Task-030c and should become `Task-031`.

Task-031 may later own:

- indoor mode detector
- indoor session-start anchor
- indoor accuracy disclosure badges
- indoor dead-reckoning policy
- magnetometer calibration monitor
- Wi-Fi RTT contribution diagnostics for indoor-specific interpretation
- optional future venue / anchor strategies

Task-030c may preserve diagnostic scaffolding that Task-031 can reuse, but Task-030c must not become a full indoor localization implementation.

---

## 8. Why camera localization remains rejected

Camera localization is not suitable for the core SkateTrack recording path because:

- the primary recording scenario is phone-in-pocket
- the camera is physically blocked in pocket recording
- skate surfaces often have low visual feature density
- continuous camera + CV has high battery and thermal cost
- pre-capture requirements are not compatible with spontaneous skate sessions
- lighting and occlusion are unreliable

Therefore, Task-030c must not add camera-based visual localization.

---

## 9. Why GPS-only small-area geometry remains limited

Small-area raw GPS geometry cannot be perfectly reconstructed from GPS alone when the route radius is comparable to horizontal accuracy.

When the signal-to-noise ratio is below roughly 2x, smoothing can make the route look nicer but cannot reliably recover the true path. SkateTrack should be honest about uncertainty rather than hiding it through fake GPS, road snapping, or raw sample mutation.

The safe medium-term path is IMU replay analysis plus explicit uncertainty disclosure, not pretending that GPS alone can recover sub-meter carving or small-loop geometry.

---

## 10. b16-A implementation deliverables

`Task-030c-b16-A` implementation should include:

```text
docs/planning/Task-030c-b16_Localization_Foundation_Plan.md
docs/adr/ADR-INDEX.md
docs/history/DEV_LOG.md
docs/reference/FILE_STRUCTURE.md
docs/release/KNOWN_LIMITATIONS_PRE_ADP.md
scripts/verify_task030c_b16a_localization_foundation_plan.py
Shared/Models/SessionData.swift
iOS/Features/Debug/DebugToolsPanelView.swift
```

Allowed Swift edits:

- update DEBUG build identity to `Task-030c-b16-A`
- update Debug Tools visible build signature to `Task-030c-b16-A`

Forbidden Swift edits in b16-A:

- no SensorFusionEngine behavior change
- no GPSProvider behavior change
- no BarometerProvider behavior change
- no IMUProvider behavior change
- no SessionRecordingCoordinator behavior change
- no SessionMetricsAccumulator behavior change
- no MotionSample schema change
- no persistence schema change
- no route map behavior change
- no trusted metric behavior change

---

## 11. b16-A verification

The b16-A verify script must check:

- the repo-local plan exists
- the plan references b16-A/B/C/D
- the plan references barometric GPS cross-validation
- the plan references Wi-Fi RTT diagnostics
- the plan references magnetometer heading quality
- the plan references IMU replay-only gap interpolation
- the plan states indoor mode detector is deferred to Task-031
- the plan rejects camera localization
- the plan rejects road snapping
- the plan rejects fake GPS
- the plan rejects RTK GPS dependency
- the plan rejects UWB anchor dependency
- the plan rejects SnowPrototype contamination
- the plan states `estimatedRouteActive` remains false
- ADR / dev log / file-structure / known-limitations entries exist
- DEBUG build identity is `Task-030c-b16-A`
- `SensorFusionEngine.swift` still contains `estimatedRouteActive: false`
- no production estimated-route activation is introduced

Recommended command:

```bash
python3 scripts/verify_task030c_b16a_localization_foundation_plan.py
```

---

## 12. Acceptance criteria

`Task-030c-b16-A` is accepted only if:

- Documentation clearly reconciles the post-b15-B-3 codebase with the uploaded roadmap and small-area analysis.
- b16-B/C/D implementation boundaries are explicit.
- Indoor localization is deferred to Task-031.
- Small-area GPS limitations are stated honestly.
- Camera localization, road snapping, fake GPS, RTK, UWB anchor dependency, and SnowPrototype contamination are rejected.
- `estimatedRouteActive` remains false.
- No production route geometry changes.
- No trusted metric changes.
- No raw sample mutation.
- No production estimated route display.
- Existing simulator recording persistence and localization terminology guards still pass.

## b16-B implementation note

`Task-030c-b16-B` implements the planned barometric GPS outlier cross-validation as diagnostics-only. `productionRouteDecisionApplied` remains false, `wouldRejectIfGateWereEnabled` is diagnostic evidence only, and `estimatedRouteActive` remains false. The implementation is intentionally split into new files so the existing over-800-line production files do not absorb the new logic.

