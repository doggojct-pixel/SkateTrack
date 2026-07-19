#!/usr/bin/env python3
"""Generate deterministic Snow QA JSON fixtures for Snow-Task-009.

The fixtures are intentionally plain JSON/text files, not .skatetrack packages.
They exercise Snow payload, package schema v2, backup schema v1/v2, lift
exclusion, and low-confidence safety boundaries without adding runtime logic.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_DIR = ROOT / "Tests" / "Fixtures" / "Snow"

CAPABILITIES = [
    "snow-distance-breakdown-v1",
    "snow-lift-exclusion-v1",
    "snow-segments-v1",
    "snow-sports-v1",
]

BASE_DATE = "2026-01-15T09:00:00Z"
GENERATED_AT = "2026-01-15T12:00:00Z"


def uuid(suffix: str) -> str:
    return f"00000000-0000-0000-0000-{suffix}"


def segment(
    *,
    identifier: str,
    session_id: str,
    run_id: str | None,
    segment_type: str,
    start: str,
    end: str,
    distance: float,
    vertical_delta: float | None,
    start_altitude: float | None,
    end_altitude: float | None,
    average_speed: float,
    max_speed: float,
    confidence: float,
    counts_toward_ski_distance: bool | None = None,
) -> dict[str, Any]:
    data: dict[str, Any] = {
        "id": identifier,
        "sessionID": session_id,
        "type": segment_type,
        "startDate": start,
        "endDate": end,
        "distanceMeters": distance,
        "averageSpeedMetersPerSecond": average_speed,
        "maxSpeedMetersPerSecond": max_speed,
        "confidence": confidence,
        "sourceSampleIDs": [],
    }
    if run_id is not None:
        data["runID"] = run_id
    if vertical_delta is not None:
        data["verticalDeltaMeters"] = vertical_delta
    if start_altitude is not None:
        data["startAltitudeMeters"] = start_altitude
    if end_altitude is not None:
        data["endAltitudeMeters"] = end_altitude
    if counts_toward_ski_distance is None:
        counts_toward_ski_distance = segment_type in {"downhillRun", "flatTraverse"}
    data["countsTowardSkiDistance"] = counts_toward_ski_distance
    return data


def snow_run(
    *,
    identifier: str,
    session_id: str,
    run_number: int,
    start: str,
    end: str,
    distance: float,
    drop: float,
    top_speed: float,
    average_speed: float,
    segment_ids: list[str],
) -> dict[str, Any]:
    return {
        "id": identifier,
        "sessionID": session_id,
        "runNumber": run_number,
        "startDate": start,
        "endDate": end,
        "skiDistanceMeters": distance,
        "verticalDropMeters": drop,
        "topSpeedMetersPerSecond": top_speed,
        "averageSpeedMetersPerSecond": average_speed,
        "segmentIDs": segment_ids,
        "isManualEnd": False,
    }


def snow_payload(
    *,
    session_id: str,
    runs: list[dict[str, Any]],
    segments: list[dict[str, Any]],
    ski_distance: float,
    lift_distance: float,
    route_distance: float,
    unknown_distance: float,
    vertical_drop: float,
    vertical_gain: float,
    max_altitude: float | None,
    min_altitude: float | None,
) -> dict[str, Any]:
    vertical_metrics: dict[str, Any] = {
        "totalVerticalDropMeters": vertical_drop,
        "totalVerticalGainMeters": vertical_gain,
    }
    if max_altitude is not None:
        vertical_metrics["maxAltitudeMeters"] = max_altitude
    if min_altitude is not None:
        vertical_metrics["minAltitudeMeters"] = min_altitude

    return {
        "payloadVersion": "snow-payload-1.0",
        "sessionID": session_id,
        "runs": runs,
        "segments": segments,
        "distanceBreakdown": {
            "skiDistanceMeters": ski_distance,
            "liftDistanceMeters": lift_distance,
            "routeDistanceMeters": route_distance,
            "unknownDistanceMeters": unknown_distance,
        },
        "verticalMetrics": vertical_metrics,
        "generatedAt": GENERATED_AT,
        "capabilities": CAPABILITIES,
    }


def make_basic_payload() -> dict[str, Any]:
    session_id = uuid("000000001001")
    run_id = uuid("000000002001")
    downhill_id = uuid("000000003001")
    downhill = segment(
        identifier=downhill_id,
        session_id=session_id,
        run_id=run_id,
        segment_type="downhillRun",
        start="2026-01-15T09:05:00Z",
        end="2026-01-15T09:11:30Z",
        distance=1250.0,
        vertical_delta=-230.0,
        start_altitude=1780.0,
        end_altitude=1550.0,
        average_speed=8.4,
        max_speed=18.2,
        confidence=0.91,
    )
    run = snow_run(
        identifier=run_id,
        session_id=session_id,
        run_number=1,
        start="2026-01-15T09:05:00Z",
        end="2026-01-15T09:11:30Z",
        distance=1250.0,
        drop=230.0,
        top_speed=18.2,
        average_speed=8.4,
        segment_ids=[downhill_id],
    )
    return snow_payload(
        session_id=session_id,
        runs=[run],
        segments=[downhill],
        ski_distance=1250.0,
        lift_distance=0.0,
        route_distance=1250.0,
        unknown_distance=0.0,
        vertical_drop=230.0,
        vertical_gain=0.0,
        max_altitude=1780.0,
        min_altitude=1550.0,
    )


def make_lift_payload() -> dict[str, Any]:
    session_id = uuid("000000001002")
    run_id = uuid("000000002002")
    downhill_id = uuid("000000003002")
    lift_id = uuid("000000003003")
    downhill = segment(
        identifier=downhill_id,
        session_id=session_id,
        run_id=run_id,
        segment_type="downhillRun",
        start="2026-01-15T10:00:00Z",
        end="2026-01-15T10:07:45Z",
        distance=1260.0,
        vertical_delta=-240.0,
        start_altitude=1810.0,
        end_altitude=1570.0,
        average_speed=7.9,
        max_speed=17.6,
        confidence=0.88,
    )
    lift = segment(
        identifier=lift_id,
        session_id=session_id,
        run_id=None,
        segment_type="liftAscent",
        start="2026-01-15T10:12:00Z",
        end="2026-01-15T10:21:00Z",
        distance=950.0,
        vertical_delta=220.0,
        start_altitude=1570.0,
        end_altitude=1790.0,
        average_speed=1.8,
        max_speed=3.2,
        confidence=0.83,
        counts_toward_ski_distance=False,
    )
    run = snow_run(
        identifier=run_id,
        session_id=session_id,
        run_number=1,
        start="2026-01-15T10:00:00Z",
        end="2026-01-15T10:07:45Z",
        distance=1260.0,
        drop=240.0,
        top_speed=17.6,
        average_speed=7.9,
        segment_ids=[downhill_id],
    )
    return snow_payload(
        session_id=session_id,
        runs=[run],
        segments=[downhill, lift],
        ski_distance=1260.0,
        lift_distance=950.0,
        route_distance=2210.0,
        unknown_distance=0.0,
        vertical_drop=240.0,
        vertical_gain=220.0,
        max_altitude=1810.0,
        min_altitude=1570.0,
    )


def make_low_confidence_payload() -> dict[str, Any]:
    session_id = uuid("000000001003")
    unknown_id = uuid("000000003004")
    unknown = segment(
        identifier=unknown_id,
        session_id=session_id,
        run_id=None,
        segment_type="unknown",
        start="2026-01-15T11:00:00Z",
        end="2026-01-15T11:03:00Z",
        distance=80.0,
        vertical_delta=None,
        start_altitude=None,
        end_altitude=None,
        average_speed=0.9,
        max_speed=2.4,
        confidence=0.35,
        counts_toward_ski_distance=False,
    )
    return snow_payload(
        session_id=session_id,
        runs=[],
        segments=[unknown],
        ski_distance=0.0,
        lift_distance=0.0,
        route_distance=80.0,
        unknown_distance=80.0,
        vertical_drop=0.0,
        vertical_gain=0.0,
        max_altitude=None,
        min_altitude=None,
    )


def package_fixture(*, payload: dict[str, Any] | None) -> dict[str, Any]:
    session_id = payload["sessionID"] if payload is not None else uuid("000000001004")
    session = {
        "id": session_id,
        "startDate": BASE_DATE,
        "endDate": "2026-01-15T12:30:00Z",
        "sportMode": {"snow": {"_0": "skiing"}},
        "powerType": "humanPowered",
        "motionSamples": [],
        "trickEvents": [],
        "fallEvents": [],
    }
    manifest: dict[str, Any] = {
        "packageType": "export",
        "schemaVersion": 2,
        "appVersion": "task009-fixture",
        "buildNumber": "009",
        "createdAt": GENERATED_AT,
        "localeIdentifier": "en_US",
        "sessionCount": 1,
        "includesMotionSamples": False,
        "includesAccountData": False,
        "includesAchievements": False,
        "formatDescription": "portable-session-export",
    }
    if payload is not None:
        manifest["capabilities"] = CAPABILITIES
    package_session: dict[str, Any] = {
        "id": session_id,
        "session": session,
        "motionSamples": [],
        "exportedAt": GENERATED_AT,
        "privacyNotes": [
            "Task 009 deterministic JSON fixture; no account data, achievements, or Drive state included."
        ],
    }
    if payload is not None:
        package_session["snowPayload"] = payload
    return {"manifest": manifest, "sessions": [package_session]}


def snow_backup_session(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": uuid("000000004001"),
        "schemaVersion": "snow-backup-session-1.0",
        "sessionID": payload["sessionID"],
        "runs": payload["runs"],
        "segments": payload["segments"],
        "distanceBreakdown": payload["distanceBreakdown"],
        "verticalMetrics": payload["verticalMetrics"],
        "generatedAt": GENERATED_AT,
    }


def empty_sections() -> list[dict[str, Any]]:
    keys = [
        ("sessions", "sessions.json"),
        ("equipment", "equipment.json"),
        ("spots", "spots.json"),
        ("achievements", "achievements.json"),
        ("weeklyChallengeCompletions", "weekly-challenge-completions.json"),
    ]
    return [
        {"storeKey": key, "fileName": file_name, "jsonString": "[]", "itemCount": 0}
        for key, file_name in keys
    ]


def backup_fixture(*, schema_version: int, snow_sessions: list[dict[str, Any]] | None) -> dict[str, Any]:
    store_counts: dict[str, Any] = {
        "sessions": 0,
        "equipment": 0,
        "spots": 0,
        "achievements": 0,
        "weeklyChallengeCompletions": 0,
    }
    if schema_version >= 2 and snow_sessions is not None:
        store_counts["snowSessions"] = len(snow_sessions)
    payload: dict[str, Any] = {
        "manifest": {
            "packageType": "backup",
            "schemaVersion": schema_version,
            "appVersion": "task009-fixture",
            "buildNumber": "009",
            "createdAt": GENERATED_AT,
            "localeIdentifier": "en_US",
            "storeCounts": store_counts,
            "encodingIssues": [],
        },
        "sections": empty_sections(),
    }
    if snow_sessions is not None:
        payload["snowSessions"] = snow_sessions
    return payload


def write_json(output_dir: Path, name: str, value: dict[str, Any]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    path = output_dir / name
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def generate(output_dir: Path) -> None:
    basic = make_basic_payload()
    lift = make_lift_payload()
    low_confidence = make_low_confidence_payload()

    fixtures = {
        "qa_snow_basic_run.json": basic,
        "qa_snow_lift_exclusion.json": lift,
        "qa_snow_low_confidence.json": low_confidence,
        "qa_snow_package_v2_with_payload.json": package_fixture(payload=basic),
        "qa_snow_package_v2_without_payload.json": package_fixture(payload=None),
        "qa_snow_backup_v1_legacy.json": backup_fixture(schema_version=1, snow_sessions=None),
        "qa_snow_backup_v2_empty_snow_sessions.json": backup_fixture(schema_version=2, snow_sessions=[]),
        "qa_snow_backup_v2_with_snow_sessions.json": backup_fixture(
            schema_version=2,
            snow_sessions=[snow_backup_session(basic)],
        ),
    }
    for name, value in fixtures.items():
        write_json(output_dir, name, value)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate deterministic Snow QA JSON fixtures.")
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR), help="Directory where fixture JSON files are written.")
    args = parser.parse_args()
    output_dir = Path(args.output_dir).resolve()
    generate(output_dir)
    print(f"[snow-task-009-fixtures] Generated deterministic Snow QA fixtures in {output_dir}")


if __name__ == "__main__":
    main()
