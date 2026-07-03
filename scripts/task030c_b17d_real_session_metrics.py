#!/usr/bin/env python3
"""Task-030c-b17-D real-session replay review metrics."""

from __future__ import annotations

import math
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

GRAVITY_METERS_PER_SECOND_SQUARED = 9.80665
EARTH_RADIUS_METERS = 6_378_137.0
B17B_ENGINE_MAXIMUM_GAP_SECONDS = 30.0
OUTDOOR_USER_VISIBLE_MAXIMUM_GAP_SECONDS = 60.0
MINIMUM_IMU_COVERAGE_RATIO = 0.7


def analyze_skatetrack_file(session_file: Path, context: dict[str, str], minimum_gap_seconds: float) -> dict[str, Any]:
    import json
    package = json.loads(session_file.read_text(encoding="utf-8"))
    all_gap_records: list[dict[str, Any]] = []
    raw_ids: list[str] = []
    sample_count = location_fix_count = timer_fusion_count = 0
    for exported in package.get("sessions", []):
        session = exported.get("session", {})
        samples = sorted(exported.get("motionSamples") or session.get("motionSamples") or [], key=timestamp_seconds)
        raw_id = str(session.get("id") or exported.get("id") or session_file.stem)
        raw_ids.append(raw_id)
        sample_count += len(samples)
        location_fix_count += sum(1 for sample in samples if sample.get("sampleSource") == "locationFix")
        timer_fusion_count += sum(1 for sample in samples if sample.get("sampleSource") == "timerFusion")
        all_gap_records.extend(make_gap_records(session_file.stem, raw_id, samples, context, minimum_gap_seconds))
    return {
        "summary": make_session_summary(session_file.stem, raw_ids, session_file.name, context, sample_count, location_fix_count, timer_fusion_count, all_gap_records),
        "gapRecords": all_gap_records,
    }


def make_gap_records(session_identifier: str, raw_id: str, samples: list[dict[str, Any]], context: dict[str, str], minimum_gap_seconds: float) -> list[dict[str, Any]]:
    location_fixes = [sample for sample in samples if is_location_fix(sample)]
    records: list[dict[str, Any]] = []
    for pre_anchor, post_anchor in zip(location_fixes, location_fixes[1:]):
        gap_duration = timestamp_seconds(post_anchor) - timestamp_seconds(pre_anchor)
        if gap_duration < minimum_gap_seconds:
            continue
        gap_samples = [
            sample for sample in samples
            if sample.get("sampleSource") == "timerFusion" and timestamp_seconds(pre_anchor) < timestamp_seconds(sample) < timestamp_seconds(post_anchor)
        ]
        records.append(make_gap_record(session_identifier, raw_id, len(records), pre_anchor, post_anchor, gap_samples, context))
    return records


def make_gap_record(session_identifier: str, raw_id: str, gap_index: int, pre_anchor: dict[str, Any], post_anchor: dict[str, Any], gap_samples: list[dict[str, Any]], context: dict[str, str]) -> dict[str, Any]:
    gap_duration = max(0.0, timestamp_seconds(post_anchor) - timestamp_seconds(pre_anchor))
    pre_coordinate = pre_anchor.get("gpsCoordinate") or {}
    post_coordinate = post_anchor.get("gpsCoordinate") or {}
    heading = selected_heading_degrees(pre_anchor, gap_samples) or bearing_degrees(pre_coordinate, post_coordinate)
    heading_reliability = heading_reliability_value(pre_anchor, gap_samples)
    estimate = integrate_gap(pre_anchor, post_anchor, gap_samples, heading)
    estimated_distance = estimate["estimatedDisplacementMeters"]
    closure_error = estimate["anchorClosureErrorMeters"]
    imu_coverage = min(1.0, len(gap_samples) / max(1.0, math.floor(gap_duration))) if gap_duration > 0 else 0.0
    replay_reason = replay_blocking_reason_value(gap_duration, gap_samples, pre_anchor, post_anchor)
    blocking = blocking_reasons_for(gap_duration, estimated_distance, closure_error, heading_reliability, imu_coverage, replay_reason)
    return {
        "sessionIdentifier": session_identifier,
        "rawSessionIdentifier": raw_id,
        "reviewRole": context.get("reviewRole", "unspecified"),
        "operatorNote": context.get("operatorNote", ""),
        "gapIndex": gap_index,
        "gapStartTimestamp": timestamp_string(pre_anchor),
        "gapEndTimestamp": timestamp_string(post_anchor),
        "gapDurationSeconds": rounded(gap_duration),
        "replayBlockingReason": replay_reason,
        "estimateCount": len(gap_samples),
        "estimatedDisplacementMeters": rounded(estimated_distance),
        "anchorDistanceMeters": rounded(distance_meters(pre_coordinate, post_coordinate)),
        "anchorClosureErrorMeters": rounded(closure_error),
        "closureErrorRatio": rounded(closure_error / max(estimated_distance, 1.0)),
        "headingReliability": heading_reliability,
        "imuSampleCoverageRatio": rounded(imu_coverage),
        "eligibleForUserVisibleEstimatedRoute": replay_reason == "noBlockingReason" and not blocking,
        "blockingReasons": blocking,
        "productionRouteMutationApplied": False,
        "trustedMetricsMutationApplied": False,
        "estimatedRouteDisplayEnabled": False,
    }


def make_session_summary(session_identifier: str, raw_ids: list[str], file_name: str, context: dict[str, str], sample_count: int, location_fix_count: int, timer_fusion_count: int, records: list[dict[str, Any]]) -> dict[str, Any]:
    blocked = [record for record in records if record["replayBlockingReason"] != "noBlockingReason"]
    eligible = [record for record in records if record["eligibleForUserVisibleEstimatedRoute"]]
    closure_errors = [record["anchorClosureErrorMeters"] for record in records]
    return {
        "sessionIdentifier": session_identifier,
        "rawSessionIdentifiers": raw_ids,
        "sourceFileName": file_name,
        "reviewRole": context.get("reviewRole", "unspecified"),
        "operatorNote": context.get("operatorNote", ""),
        "sampleCount": sample_count,
        "locationFixSampleCount": location_fix_count,
        "timerFusionSampleCount": timer_fusion_count,
        "totalGapCount": len(records),
        "replaySucceededGapCount": len(records) - len(blocked),
        "blockedGapCount": len(blocked),
        "userVisibleEligibleGapCount": len(eligible),
        "reviewRecommendedGapCount": sum(1 for record in records if not record["eligibleForUserVisibleEstimatedRoute"] or record["blockingReasons"]),
        "maximumClosureErrorMeters": rounded(max(closure_errors)) if closure_errors else None,
        "longestGapSeconds": rounded(max((record["gapDurationSeconds"] for record in records), default=0.0)),
        "productDecisionCheckpointRequired": True,
        "b18DisplayWorkBlockedUntilProductDecision": True,
    }


def replay_blocking_reason_value(gap_duration: float, gap_samples: list[dict[str, Any]], pre_anchor: dict[str, Any], post_anchor: dict[str, Any]) -> str:
    if not pre_anchor.get("gpsCoordinate"):
        return "missingPreGapAnchor"
    if not post_anchor.get("gpsCoordinate"):
        return "missingPostGapAnchor"
    if gap_duration > B17B_ENGINE_MAXIMUM_GAP_SECONDS:
        return "gapTooLong"
    if len(gap_samples) < 2:
        return "insufficientIMUSamples"
    return "noBlockingReason"


def blocking_reasons_for(gap_duration: float, estimated_distance: float, closure_error: float, heading_reliability: str, imu_coverage: float, replay_reason: str) -> list[str]:
    reasons: list[str] = [] if replay_reason == "noBlockingReason" else [replay_reason]
    if gap_duration > OUTDOOR_USER_VISIBLE_MAXIMUM_GAP_SECONDS:
        reasons.append("gapDurationExceededOutdoorLimit")
    elif gap_duration > B17B_ENGINE_MAXIMUM_GAP_SECONDS:
        reasons.append("replayGapExceedsB17BEngineLimit")
        if closure_error > max(5.0, 0.1 * estimated_distance):
            reasons.append("longGapRequiresVeryLowClosureError")
    if closure_error > max(15.0, 0.5 * estimated_distance):
        reasons.append("closureErrorExceededBlockingThreshold")
    elif closure_error > max(8.0, 0.25 * estimated_distance):
        reasons.append("closureErrorExceededEligibilityThreshold")
    if heading_reliability not in {"high", "moderate"}:
        reasons.append("headingReliabilityInsufficient")
    if imu_coverage < MINIMUM_IMU_COVERAGE_RATIO:
        reasons.append("imuSampleCoverageInsufficient")
    return deduplicate(reasons)


def integrate_gap(pre_anchor: dict[str, Any], post_anchor: dict[str, Any], gap_samples: list[dict[str, Any]], heading_degrees: float) -> dict[str, float]:
    post_local = local_meters(pre_anchor.get("gpsCoordinate") or {}, post_anchor.get("gpsCoordinate") or {})
    velocity = initial_velocity(pre_anchor.get("speedKmh", 0.0), heading_degrees)
    bias = accelerometer_bias(gap_samples)
    east = north = previous_east = previous_north = path_distance = 0.0
    previous_timestamp = timestamp_seconds(pre_anchor)
    for sample in gap_samples:
        delta_seconds = max(0.0, timestamp_seconds(sample) - previous_timestamp)
        previous_timestamp = timestamp_seconds(sample)
        acceleration = compensated_acceleration(sample, bias)
        velocity["east"] += acceleration["east"] * delta_seconds
        velocity["north"] += acceleration["north"] * delta_seconds
        east += velocity["east"] * delta_seconds
        north += velocity["north"] * delta_seconds
        path_distance += math.hypot(east - previous_east, north - previous_north)
        previous_east, previous_north = east, north
    return {"estimatedDisplacementMeters": path_distance, "anchorClosureErrorMeters": math.hypot(post_local["east"] - east, post_local["north"] - north)}


def selected_heading_degrees(pre_anchor: dict[str, Any], gap_samples: list[dict[str, Any]]) -> float | None:
    for sample in [pre_anchor] + gap_samples:
        diagnostics = ((sample.get("locationDiagnostics") or {}).get("headingDiagnostics")) or {}
        if diagnostics.get("deviceHeadingReliableForRouteContinuity") and diagnostics.get("deviceHeadingDegrees") is not None:
            return float(diagnostics["deviceHeadingDegrees"])
        if diagnostics.get("courseReliableForRouteContinuity") and diagnostics.get("courseOverGroundDegrees") is not None:
            return float(diagnostics["courseOverGroundDegrees"])
    return None


def heading_reliability_value(pre_anchor: dict[str, Any], gap_samples: list[dict[str, Any]]) -> str:
    for sample in [pre_anchor] + gap_samples:
        diagnostics = ((sample.get("locationDiagnostics") or {}).get("headingDiagnostics")) or {}
        available = diagnostics.get("headingAvailable") is True
        reliable = diagnostics.get("deviceHeadingReliableForRouteContinuity") or diagnostics.get("courseReliableForRouteContinuity")
        accuracy = diagnostics.get("deviceHeadingAccuracyDegrees") or diagnostics.get("courseAccuracyDegrees")
        if available and reliable:
            if accuracy is None or float(accuracy) <= 20:
                return "high"
            if float(accuracy) <= 35:
                return "moderate"
            if float(accuracy) <= 60:
                return "poor"
            return "invalid"
    return "unavailable"


def accelerometer_bias(samples: list[dict[str, Any]]) -> dict[str, float]:
    stationary = []
    for sample in samples:
        gyro = sample.get("gyroscopeRadPS") or {}
        accel = sample.get("accelerometerG") or {}
        gyro_magnitude = math.sqrt(sum(float(gyro.get(axis, 0.0)) ** 2 for axis in ("x", "y", "z")))
        accel_magnitude = math.sqrt(sum(float(accel.get(axis, 0.0)) ** 2 for axis in ("x", "y", "z")))
        if float(sample.get("speedKmh") or 0.0) <= 0.8 and gyro_magnitude <= 0.08 and abs(accel_magnitude - 1.0) <= 0.08:
            stationary.append(accel)
    if len(stationary) < 5:
        return {"x": 0.0, "y": 0.0, "z": 0.0}
    return {
        "x": sum(float(sample.get("x", 0.0)) for sample in stationary) / len(stationary),
        "y": sum(float(sample.get("y", 0.0)) for sample in stationary) / len(stationary),
        "z": sum(float(sample.get("z", 0.0)) for sample in stationary) / len(stationary) - 1.0,
    }


def compensated_acceleration(sample: dict[str, Any], bias: dict[str, float]) -> dict[str, float]:
    accelerometer = sample.get("accelerometerG") or {}
    return {
        "east": (float(accelerometer.get("x", 0.0)) - bias["x"]) * GRAVITY_METERS_PER_SECOND_SQUARED,
        "north": (float(accelerometer.get("y", 0.0)) - bias["y"]) * GRAVITY_METERS_PER_SECOND_SQUARED,
    }


def is_location_fix(sample: dict[str, Any]) -> bool:
    return sample.get("sampleSource") == "locationFix" and sample.get("gpsCoordinate") is not None


def initial_velocity(speed_kmh: float, heading_degrees: float) -> dict[str, float]:
    speed_mps = max(0.0, float(speed_kmh or 0.0)) / 3.6
    radians = math.radians(heading_degrees)
    return {"east": math.sin(radians) * speed_mps, "north": math.cos(radians) * speed_mps}


def local_meters(anchor: dict[str, Any], coordinate: dict[str, Any]) -> dict[str, float]:
    anchor_lat = math.radians(float(anchor.get("latitude", 0.0)))
    anchor_lon = math.radians(float(anchor.get("longitude", 0.0)))
    lat = math.radians(float(coordinate.get("latitude", 0.0)))
    lon = math.radians(float(coordinate.get("longitude", 0.0)))
    return {"east": (lon - anchor_lon) * max(0.000001, math.cos(anchor_lat)) * EARTH_RADIUS_METERS, "north": (lat - anchor_lat) * EARTH_RADIUS_METERS}


def distance_meters(start: dict[str, Any], end: dict[str, Any]) -> float:
    local = local_meters(start, end)
    return math.hypot(local["east"], local["north"])


def bearing_degrees(start: dict[str, Any], end: dict[str, Any]) -> float:
    start_lat = math.radians(float(start.get("latitude", 0.0)))
    end_lat = math.radians(float(end.get("latitude", 0.0)))
    delta_lon = math.radians(float(end.get("longitude", 0.0)) - float(start.get("longitude", 0.0)))
    y = math.sin(delta_lon) * math.cos(end_lat)
    x = math.cos(start_lat) * math.sin(end_lat) - math.sin(start_lat) * math.cos(end_lat) * math.cos(delta_lon)
    degrees = math.degrees(math.atan2(y, x))
    return degrees + 360 if degrees < 0 else degrees


def timestamp_seconds(sample: dict[str, Any]) -> float:
    milliseconds = sample.get("timestampMillisecondsSince1970")
    if milliseconds is not None:
        return float(milliseconds) / 1_000.0
    return datetime.fromisoformat(str(sample["timestamp"]).replace("Z", "+00:00")).timestamp()


def timestamp_string(sample: dict[str, Any]) -> str:
    value = sample.get("timestamp")
    return str(value) if value else datetime.fromtimestamp(timestamp_seconds(sample), tz=timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def rounded(value: float) -> float:
    return 0.0 if not math.isfinite(value) else round(max(0.0, value), 3)


def deduplicate(values: list[str]) -> list[str]:
    result, seen = [], set()
    for value in values:
        if value not in seen:
            result.append(value)
            seen.add(value)
    return result
