# MotionSample Extension Design

Version: EN v1.0
Branch: `feature/snow-mode`
Base commit at preparation time: `b975c43 Finalize Snow Mode Phase 1c handoff and completion checks`
Document status: Future architecture design proposal
Scope: Documentation only. This file does not authorize implementation on `feature/snow-mode` before the mainline GPS / MotionSample architecture is ready.

## 1. Purpose

SnowSegmentClassifier v0 intentionally avoids extending `MotionSample`. That decision kept Snow Mode Phase 1c safe because `MotionSample` is shared across sport modes and persistence / export boundaries. Future Snow classifier versions will need GPS accuracy, course, and altitude-source metadata. This document defines a future additive extension plan so that a later MotionSample v1 task can be implemented without starting from a blank design.

This document is intentionally not an implementation task. Do not modify Swift code, Core Data, GPSProvider, SensorFusionEngine, package schema, backup schema, or classifier behavior as part of this document-only preparation.

## 2. Current MotionSample baseline after Snow-Task-010

As of Snow-Task-010, `Shared/Models/MotionSample.swift` contains the following shape:

```swift
struct GeoCoordinate: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double
}

struct ThreeAxisValue: Codable, Sendable, Equatable {
    let x: Double
    let y: Double
    let z: Double
}

struct MotionSample: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let gpsCoordinate: GeoCoordinate?
    let speedKmh: Double
    let accelerometerG: ThreeAxisValue
    let gyroscopeRadPS: ThreeAxisValue
    let altitudeMeters: Double?
}
```

Current important limitation:

```text
altitudeMeters is present, but it does not identify whether the altitude came from barometer relative altitude, GPS absolute altitude, or a fused source.
```

## 3. Proposed future optional fields

All future additions must be optional to preserve Codable compatibility with existing samples and package / backup payloads.

```swift
// GPS accuracy metadata from CLLocation.
var horizontalAccuracyMeters: Double?   // CLLocation.horizontalAccuracy
var verticalAccuracyMeters: Double?     // CLLocation.verticalAccuracy

// GPS course / heading metadata from CLLocation.
var courseDegreesTrue: Double?          // CLLocation.course, nil if CLLocation.course < 0
var courseAccuracyDegrees: Double?      // CLLocation.courseAccuracy, nil if unavailable or invalid

// GPS absolute altitude metadata from CLLocation.
var gpsAltitudeMeters: Double?          // CLLocation.altitude
var gpsAltitudeAccuracyMeters: Double?  // CLLocation.verticalAccuracy, kept explicit for altitude context

// Altitude source disambiguation.
var altitudeSource: MotionSampleAltitudeSource?

enum MotionSampleAltitudeSource: String, Codable, Sendable, Equatable {
    case barometer   // CMBarometerData.relativeAltitude / current v0 behavior
    case gps         // CLLocation.altitude absolute altitude
    case fused       // barometer + GPS cross-validated / future behavior
}
```

## 4. Backward compatibility rules

The implementation task must preserve all existing data.

```text
- Every new field must be optional.
- Codable decode must use decodeIfPresent or equivalent default-nil behavior.
- Old MotionSample JSON without the new fields must decode successfully.
- Existing .skatetrack packages containing old MotionSample payloads must decode successfully.
- Existing backup payloads containing old MotionSample payloads must decode successfully.
- The .skatetrack package manifest schema version must not be bumped solely for these optional fields.
- The backup package manifest schema version must not be bumped solely for these optional fields.
```

Persistence rule:

```text
If MotionSample is persisted in Core Data, adding optional attributes still requires the programmatic Core Data model version identifier to change. This should be treated as a lightweight migration because all new attributes are optional.
```

Do not implement this migration from the Snow pre-Task-040 documentation task. It belongs to a future MotionSample v1 implementation task.

## 5. How SnowSegmentClassifier v1 would use the fields

### `horizontalAccuracyMeters`

Expected classifier v1 usage:

```text
- If horizontalAccuracyMeters > 50m, reduce classification confidence.
- If horizontalAccuracyMeters > 100m, classify as unknown unless another high-confidence sensor source overrides it.
- If horizontalAccuracyMeters is nil, keep v0 fallback behavior.
```

Current v0 limitation:

```text
SnowSegmentClassifier cannot reject low-quality GPS points directly because MotionSample lacks GPS accuracy metadata.
```

### `verticalAccuracyMeters` / `gpsAltitudeAccuracyMeters`

Expected classifier v1 usage:

```text
- Use vertical accuracy to decide whether GPS altitude is reliable enough for cross-validation.
- If vertical accuracy is poor, prefer barometer relative altitude for vertical-rate estimates.
- If vertical accuracy is good and barometer diverges significantly, mark confidence lower or use fused altitude logic.
```

### `courseDegreesTrue` / `courseAccuracyDegrees`

Expected classifier v1 usage:

```text
- Use CLLocation.course instead of deriving bearing only from consecutive GPS coordinates when available.
- Calculate heading standard deviation over a window to separate stable lift / gondola movement from carving downhill movement.
- Ignore course when CLLocation.course is invalid or courseAccuracyDegrees is poor.
```

### `gpsAltitudeMeters`

Expected classifier v1 usage:

```text
- Cross-check GPS absolute altitude against barometer relative altitude trends.
- If GPS altitude and barometer altitude diverge beyond a configured tolerance, lower confidence.
- Use GPS altitude as context, not as a replacement for barometer vertical-rate estimation unless validated.
```

### `altitudeSource`

Expected classifier v1 usage:

```text
- Understand whether altitudeMeters came from barometer, GPS, or a fused estimate.
- Avoid treating GPS altitude noise as barometer-quality vertical rate.
- Enable future metrics and debug diagnostics to explain altitude quality.
```

## 6. Impact on GPSProvider and SensorFusionEngine

Future implementation should keep responsibilities separated.

### GPSProvider

Expected responsibilities:

```text
- Populate horizontalAccuracyMeters from CLLocation.horizontalAccuracy when valid.
- Populate verticalAccuracyMeters from CLLocation.verticalAccuracy when valid.
- Populate courseDegreesTrue from CLLocation.course only when course >= 0.
- Populate courseAccuracyDegrees only when available and valid.
- Populate gpsAltitudeMeters from CLLocation.altitude when valid.
- Populate gpsAltitudeAccuracyMeters from CLLocation.verticalAccuracy when valid.
- Never synthesize fake accuracy or course values.
```

### SensorFusionEngine

Expected responsibilities:

```text
- Forward new fields without changing their meaning.
- Keep sensor-fusion decisions separate from classifier decisions.
- Do not silently replace barometer altitude with GPS altitude.
- Preserve nil when source data is unavailable.
```

### Snow classifier

Expected responsibilities:

```text
- Interpret the new metadata for classification confidence.
- Own classifier-specific thresholds.
- Explain any new confidence-reduction logic in tests and documentation.
```

## 7. Scope and exclusions

This design covers future work in:

```text
- MotionSample value type extension.
- Optional Codable compatibility.
- Programmatic Core Data lightweight migration if MotionSample is persisted.
- GPSProvider population of new optional fields.
- SensorFusionEngine forwarding of new fields.
- SnowSegmentClassifier v1 use of accuracy / course / altitude source metadata.
```

This design does not authorize:

```text
- Changes to skateboard or inline classifier behavior.
- Changes to package manifest schema version.
- Changes to backup manifest schema version.
- Changes to WatchBridge / MetricUpdateMessage.
- Production HealthKit integration.
- Resort map / weather / piste integration.
- Any implementation before the mainline GPS / MotionSample architecture is ready.
```

## 8. Recommended future implementation structure

When this design is approved, implement it as a dedicated future task, not as a side effect of Snow-Task-006b.

Recommended task name:

```text
MotionSample-v1
```

or, if kept within the Snow roadmap:

```text
Snow-Task-003b MotionSample accuracy metadata foundation
```

Recommended stages:

```text
Stage A — MotionSample value type extension + Codable compatibility + GPSProvider population.
          No classifier behavior changes.

Stage B — Core Data lightweight migration if the new fields must persist.
          Verify old stores and package / backup decode paths.

Stage C — SensorFusionEngine forwarding.
          Preserve source metadata and nil semantics.

Stage D — SnowSegmentClassifier v1 confidence usage.
          Add tests for low accuracy, course stability, and GPS / barometer divergence.

Stage E — QA fixtures updated with both old-style samples and new metadata-rich samples.
          Confirm old samples still decode and classify safely.
```

## 9. Future acceptance criteria

A future implementation is complete only if:

```text
□ Old MotionSample JSON decodes.
□ Existing package and backup compatibility tests pass.
□ Programmatic Core Data model migration is additive and optional.
□ GPSProvider maps CLLocation fields only when valid.
□ SensorFusionEngine forwards fields without inventing values.
□ SnowSegmentClassifier v1 handles both old and new samples.
□ Existing skateboard / inline behavior is unchanged.
□ iOS, macOS, and watchOS builds pass.
```

## 10. Recommended future commit name

```text
Add MotionSample accuracy metadata foundation
```

Do not use this commit name for this planning document. This document-only preparation should be committed as:

```text
Add Snow pre-Task-040 preparation documents
```
