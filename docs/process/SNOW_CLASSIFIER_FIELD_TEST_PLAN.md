# Snow Classifier Field Test Plan

Version: EN v1.0
Branch: `feature/snow-mode`
Base commit at preparation time: `b975c43 Finalize Snow Mode Phase 1c handoff and completion checks`
Document status: Real-world validation plan
Scope: Documentation only. This file does not change classifier thresholds or runtime behavior.

## 1. Purpose

SnowSegmentClassifier v0 and RunBoundaryDetector v0 are deterministic, rule-based foundations validated with synthetic fixtures and unit tests. They have not yet been tuned against real ski / snowboard field data. This plan defines the field sessions to collect, the observations to record, and the safe tuning process for a future threshold-adjustment task.

Do not change `SnowClassifierConfig.productionV0`, `RunBoundaryConfig.productionV0`, classifier logic, or run-boundary logic as part of this document-only preparation.

## 2. Minimum field scenarios to collect

Collect separate sessions when possible. Short, clearly labeled sessions are more useful than one long mixed session.

### Scenario A — Pure downhill run

```text
Duration: 2–5 minutes.
Goal: Validate downhillRun classification and run-boundary start / end timing.
Device: iPhone in chest pocket or arm band; screen locked; Snow Mode recording active.
Notes to record: slope type, approximate start / stop time, whether carving or straight-line riding.
Expected classifier output: mostly downhillRun with limited flatTraverse / unknown interruptions.
```

### Scenario B — Chair lift ascent

```text
Duration: Full lift ride from base to top.
Goal: Validate liftAscent classification and lift-distance exclusion.
Device: iPhone in chest pocket or jacket pocket; screen locked.
Notes to record: time boarding lift, time unloading, whether lift stopped mid-ride.
Expected classifier output: liftAscent, not downhillRun.
```

### Scenario C — Gondola / enclosed lift ascent

```text
Duration: Full gondola ride if available.
Goal: Validate stable-heading / low-IMU lift behavior and prevent false downhillRun.
Device: iPhone in pocket; avoid hand-held movement if possible.
Notes to record: gondola start / end, crowd movement, cable bends if known.
Expected classifier output: liftAscent or transport-like segment, not downhillRun.
```

### Scenario D — Queue / waiting at lift base

```text
Duration: 2–3 minutes stationary or slow shuffling.
Goal: Validate stopped / walking / unknown boundaries.
Device: Normal carry position.
Notes to record: standing still vs shuffling forward.
Expected classifier output: stopped or walking; never downhillRun.
```

### Scenario E — Walking in ski boots / snowboard boots

```text
Duration: 1–2 minutes.
Goal: Confirm walking is not classified as downhillRun.
Device: Normal carry position.
Notes to record: flat area vs mild slope.
Expected classifier output: walking or flatTraverse depending on speed / slope, not downhillRun.
```

### Scenario F — Low GPS signal area

```text
Duration: 1–3 minutes under trees, near buildings, or constrained terrain if available.
Goal: Confirm low-quality data does not force incorrect classification.
Device: Normal carry position.
Notes to record: visible sky condition and any map drift.
Expected classifier output: unknown or low-confidence state when data quality is poor.
```

## 3. Recommended capture protocol

For each field test session:

```text
1. Start a new Snow Mode recording for only one scenario when possible.
2. Record the scenario name in external notes immediately before or after capture.
3. Keep the iPhone in a realistic carry position, preferably chest pocket or arm band.
4. Lock the screen to verify background recording behavior.
5. Avoid running another foreground navigation / GPS app unless intentionally testing interference.
6. End recording immediately after the scenario to reduce labeling ambiguity.
7. Export the session as a .skatetrack package.
8. Open the package in the macOS Snow viewer.
9. Record what the viewer classifies each segment as.
10. Mark any obvious mismatch with approximate time range.
```

## 4. Data to preserve for analysis

For each field test, keep:

```text
- Exported .skatetrack package.
- Session start / end time.
- Scenario label.
- Carry position.
- Screen state: locked / unlocked.
- Weather / temperature if relevant.
- Terrain description.
- Notes about stops, lift delays, walking, gondola bends, or GPS-obstructed zones.
- Screenshots of macOS Snow viewer segment list and route / elevation panel.
- Any raw MotionSample JSON export if available in future tooling.
```

Do not commit real `.skatetrack` packages into the source repo. Store them in `/Users/doggo/Documents/App軟體區/upload/` or an external field-test archive.

## 5. Parameters most likely to need tuning

The exact current values should be confirmed in source before tuning. The categories below are the important ones to inspect.

### `SnowClassifierConfig.productionV0`

```text
minDownhillSpeedKmh
  If beginner slopes or slow snowboard turns are classified as stopped, this threshold may be too high.

verticalRateForDescentThreshold
  If barometer noise produces false descent / ascent, tune this threshold after comparing multiple real sessions.

hysteresisSeconds
  If short pauses or transitions cause rapid classification flips, increase hysteresis.

lift / gondola IMU-energy thresholds
  If gondola vibration is higher than synthetic assumptions, low IMU-energy thresholds may need adjustment.

heading stability / heading standard deviation thresholds
  If gondola cable bends or lift paths produce more heading variation than expected, tune with real samples.
```

### `RunBoundaryConfig.productionV0`

```text
pendingEndTimeoutSeconds
  If users commonly stop for photos or regrouping and the run ends too early, test 45–60 seconds.

startSkiingConfirmationSeconds
  If runs start on a flat traverse before descending, the detector may need a longer or more tolerant confirmation rule.

minimumRunDurationSeconds / minimumRunDistanceMeters
  If short real runs are rejected, adjust only after comparing several sessions.
```

## 6. Tuning process

After field data is collected, tune in a dedicated future task.

```text
1. Group field sessions by scenario.
2. Identify false positives first, especially lift/gondola classified as downhillRun.
3. Identify false negatives second, especially real downhill classified as stopped or unknown.
4. Propose one threshold change at a time.
5. Update SnowClassifierConfig.productionV0 or RunBoundaryConfig.productionV0 in a small patch.
6. Run SnowSegmentClassifierTests and RunBoundaryDetectorTests.
7. Run SnowQAFixtureRegressionTests.
8. Run cumulative Snow verify scripts.
9. Build iOS, macOS, and watchOS.
10. Update fixtures only if the real-world change intentionally changes expected behavior.
11. Document the field data reason for each threshold adjustment.
```

Do not tune from a single noisy field session unless the problem is severe and obvious.

## 7. Success criteria after real-world tuning

Target outcomes:

```text
- Chair lift and gondola ascents are not classified as downhillRun.
- Genuine downhill runs are mostly downhillRun with limited false liftAscent time.
- Lift queue waiting is classified as stopped or walking, not downhillRun.
- Walking in boots is not classified as downhillRun.
- Low GPS signal areas degrade to unknown / low-confidence instead of being forced into an incorrect confident class.
- Run boundaries do not end early during normal short stops.
- Short real runs are not discarded if they are valid ski / snowboard runs.
```

Quantitative starter targets:

```text
- 0 known lift / gondola sessions misclassified as downhillRun for more than a short transition window.
- Less than 5% of a clean downhill run classified as liftAscent.
- Queue / waiting sessions classified as stopped or walking for the majority of duration.
- Low-GPS sessions show low-confidence or unknown behavior rather than confident wrong classification.
```

## 8. Known limitations before MotionSample v1

Until the MotionSample extension is implemented, classifier tuning is limited by available fields.

```text
- No horizontalAccuracyMeters in MotionSample.
- No verticalAccuracyMeters in MotionSample.
- No CLLocation.course / courseAccuracy in MotionSample.
- No gpsAltitudeMeters distinct from barometer-relative altitude.
- No altitudeSource to distinguish barometer / GPS / fused altitude.
```

Therefore, v0 tuning should be conservative. Do not overfit thresholds to one resort, one device position, or one day of sensor noise.

## 9. Suggested future commit name for tuning

```text
Tune Snow classifier thresholds from field data
```

Do not use this commit name for this planning document. This document-only preparation should be committed as:

```text
Add Snow pre-Task-040 preparation documents
```
