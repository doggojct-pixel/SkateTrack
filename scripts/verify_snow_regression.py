#!/usr/bin/env python3
"""Verify Snow-Task-009 QA fixture regression guardrails."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A005_INTEGRATION_MODE = os.environ.get("SNOW_INTEGRATION_A005") == "1"

FIXTURES = [
    "qa_snow_basic_run.json",
    "qa_snow_lift_exclusion.json",
    "qa_snow_low_confidence.json",
    "qa_snow_package_v2_with_payload.json",
    "qa_snow_package_v2_without_payload.json",
    "qa_snow_backup_v1_legacy.json",
    "qa_snow_backup_v2_empty_snow_sessions.json",
    "qa_snow_backup_v2_with_snow_sessions.json",
]


def fail(message: str) -> None:
    print(f"[snow-task-009] FAIL: {message}")
    sys.exit(1)


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        fail(f"missing required file: {rel}")
    return path.read_text(encoding="utf-8")


def require(rel: str, token: str, label: str | None = None) -> None:
    if token not in read(rel):
        fail(f"missing {label or token!r} in {rel}")


def iter_snow_segments(value):
    if isinstance(value, dict):
        if isinstance(value.get("segments"), list):
            for segment in value["segments"]:
                if isinstance(segment, dict):
                    yield segment
        for child in value.values():
            yield from iter_snow_segments(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_snow_segments(child)


def load_json(rel: str) -> dict:
    try:
        return json.loads(read(rel))
    except Exception as exc:
        fail(f"invalid JSON fixture {rel}: {exc}")


def changed_files() -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "diff", "--name-only", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail("unable to inspect git diff against HEAD")
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


# Required files.
generator = "scripts/generate_snow_qa_fixtures.py"
tests = "Tests/iOSTests/SnowQAFixtureRegressionTests.swift"
pbx = "SkateTrack.xcodeproj/project.pbxproj"
fixture_dir = "Tests/Fixtures/Snow"
for rel in [generator, tests, pbx]:
    read(rel)
for fixture in FIXTURES:
    read(f"{fixture_dir}/{fixture}")

# Generator determinism: generated output must byte-match committed fixture files.
with tempfile.TemporaryDirectory(prefix="snow-task-009-fixtures-") as tmp:
    result = subprocess.run(
        [sys.executable, str(ROOT / generator), "--output-dir", tmp],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(f"fixture generator failed: {result.stderr or result.stdout}")
    tmp_path = Path(tmp)
    for fixture in FIXTURES:
        expected = (ROOT / fixture_dir / fixture).read_text(encoding="utf-8")
        generated = (tmp_path / fixture).read_text(encoding="utf-8")
        if generated != expected:
            fail(f"fixture generator output is not deterministic for {fixture}")

# Fixture schema/content markers.
basic = load_json(f"{fixture_dir}/qa_snow_basic_run.json")
if basic.get("payloadVersion") != "snow-payload-1.0":
    fail("basic Snow fixture must use snow-payload-1.0")
if basic.get("distanceBreakdown", {}).get("skiDistanceMeters", 0) <= 0:
    fail("basic Snow fixture must include positive ski distance")
if basic.get("verticalMetrics", {}).get("totalVerticalDropMeters", 0) <= 0:
    fail("basic Snow fixture must include vertical drop")

lift = load_json(f"{fixture_dir}/qa_snow_lift_exclusion.json")
segment_types = {segment.get("type") for segment in lift.get("segments", [])}
if "liftAscent" not in segment_types or "downhillRun" not in segment_types:
    fail("lift exclusion fixture must include both liftAscent and downhillRun segments")
if lift.get("distanceBreakdown", {}).get("liftDistanceMeters", 0) <= 0:
    fail("lift exclusion fixture must include lift distance")
if lift.get("distanceBreakdown", {}).get("skiDistanceMeters", 0) >= lift.get("distanceBreakdown", {}).get("routeDistanceMeters", 0):
    fail("lift exclusion fixture must keep route distance larger than ski distance")

low_conf = load_json(f"{fixture_dir}/qa_snow_low_confidence.json")
if not any(segment.get("confidence", 1) < 0.5 for segment in low_conf.get("segments", [])):
    fail("low-confidence fixture must include a confidence value below 0.5")

package_with_payload = load_json(f"{fixture_dir}/qa_snow_package_v2_with_payload.json")
manifest = package_with_payload.get("manifest", {})
if manifest.get("schemaVersion") != 2:
    fail("package v2 fixture must declare schemaVersion 2")
if sorted(manifest.get("capabilities", [])) != [
    "snow-distance-breakdown-v1",
    "snow-lift-exclusion-v1",
    "snow-segments-v1",
    "snow-sports-v1",
]:
    fail("package v2 fixture must declare Snow capability strings")
if package_with_payload.get("sessions", [{}])[0].get("snowPayload", {}).get("payloadVersion") != "snow-payload-1.0":
    fail("package v2 with payload fixture must include Snow payload version")

package_without_payload = load_json(f"{fixture_dir}/qa_snow_package_v2_without_payload.json")
if "snowPayload" in package_without_payload.get("sessions", [{}])[0]:
    fail("package v2 without payload fixture must omit snowPayload")
if "capabilities" in package_without_payload.get("manifest", {}):
    fail("package v2 without payload fixture must omit capabilities")

backup_v1 = load_json(f"{fixture_dir}/qa_snow_backup_v1_legacy.json")
if backup_v1.get("manifest", {}).get("schemaVersion") != 1:
    fail("backup v1 fixture must declare schemaVersion 1")
if "snowSessions" in backup_v1 or "snowSessions" in backup_v1.get("manifest", {}).get("storeCounts", {}):
    fail("backup v1 legacy fixture must omit snowSessions")

backup_v2_empty = load_json(f"{fixture_dir}/qa_snow_backup_v2_empty_snow_sessions.json")
if backup_v2_empty.get("manifest", {}).get("storeCounts", {}).get("snowSessions") != 0:
    fail("backup v2 empty fixture must declare snowSessions count 0")
if backup_v2_empty.get("snowSessions") != []:
    fail("backup v2 empty fixture must encode snowSessions as []")

backup_v2_populated = load_json(f"{fixture_dir}/qa_snow_backup_v2_with_snow_sessions.json")
if backup_v2_populated.get("manifest", {}).get("storeCounts", {}).get("snowSessions") != 1:
    fail("backup v2 populated fixture must declare one Snow session")
if backup_v2_populated.get("snowSessions", [{}])[0].get("schemaVersion") != "snow-backup-session-1.0":
    fail("backup v2 populated fixture must include SnowBackupSession schema version")

for fixture in FIXTURES:
    fixture_json = load_json(f"{fixture_dir}/{fixture}")
    for segment in iter_snow_segments(fixture_json):
        if "type" in segment and "distanceMeters" in segment and "countsTowardSkiDistance" not in segment:
            fail(f"Snow segment fixture must explicitly encode countsTowardSkiDistance: {fixture}")

# Test coverage and Xcode membership.
for token in [
    "final class SnowQAFixtureRegressionTests",
    "testBasicRunFixtureDecodesWithVerticalDrop",
    "testLiftExclusionFixturePreservesDistanceBreakdown",
    "testLowConfidenceFixtureMapsToSafeSnowState",
    "testPackageV2WithSnowPayloadFixtureDecodesThroughReader",
    "testPackageV2WithoutSnowPayloadFixtureRemainsSafe",
    "testBackupV1LegacyFixtureDecodesWithoutSnowSessions",
    "testBackupV2EmptySnowSessionsFixtureDecodes",
    "testBackupV2PopulatedSnowSessionsFixtureDecodes",
    "testHealthBoundaryRegressionRemainsNoOpOrDebugOnly",
]:
    require(tests, token)

for token in [
    "SnowQAFixtureRegressionTests.swift",
    "SnowQAFixtureRegressionTests.swift in Sources",
]:
    require(pbx, token, f"project membership token {token}")

# Existing verify scripts must remain available for cumulative checks.
for rel in [
    "scripts/verify_snow_backup_compatibility.py",
    "scripts/verify_snow_package_compatibility.py",
    "scripts/verify_snow_macos_viewer.py",
    "scripts/verify_snow_watch_ui.py",
    "scripts/verify_snow_iphone_ui.py",
    "scripts/verify_snow_run_boundary.py",
    "scripts/verify_snow_classifier.py",
    "scripts/verify_snow_schema.py",
    "scripts/verify_snow_sport_enum.py",
]:
    read(rel)


# Documentation and review-pack requirements for Step 2 / final Task 009.
for rel, token in [
    ("docs/release/MANUAL_QA_MATRIX_PRE_ADP.md", "Snow-Task-009 QA / Regression Manual Test Matrix"),
    ("docs/history/DEV_LOG.md", "Snow-Task-009 QA fixtures and regression matrix"),
    ("docs/process/PHASE_1C_SNOW_AGENT_STATE.md", "Snow-Task-009 Agent State"),
    ("docs/reference/FILE_STRUCTURE.md", "Snow-Task-009 QA / Regression Files"),
    ("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", "Snow-Task-009 QA limitation"),
    ("docs/DOCUMENTATION_INDEX.md", "Snow-Task-009 QA Fixtures and Regression Matrix"),
    ("scripts/create_snow_task009_review_pack.sh", "SnowTask009_ReviewPack.zip"),
]:
    require(rel, token, f"Snow-Task-009 documentation/review token {token}")

# Scope guardrails: no binary sample packages, no runtime integrations, no schema bump.
for path in ROOT.rglob("*.skatetrack"):
    if ".git" not in path.parts:
        fail(f"do not commit .skatetrack fixtures: {path.relative_to(ROOT)}")

for rel in [
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/BackupPackageManifest.swift",
]:
    require(rel, "static let currentSchemaVersion = 2", f"schema version must remain 2 in {rel}")

scan_roots = ["Shared", "iOS", "watchOS", "macOS", "Tests"]
for scan_root in scan_roots:
    root_path = ROOT / scan_root
    if not root_path.exists():
        continue
    for path in root_path.rglob("*.swift"):
        rel = path.relative_to(ROOT)
        text = path.read_text(encoding="utf-8")
        if "SnowPrototype" in text or "MacSnowPrototype" in text:
            fail(f"forbidden prototype token found in {rel}")
        if ("import WatchConnectivity" in text or "WCSession" in text) and not (
            A005_INTEGRATION_MODE and str(rel).startswith("Shared/WatchBridge/")
        ):
            fail(f"Task 009 must not add WatchConnectivity scope: {rel}")
        if "import HealthKit" in text:
            fail(f"Task 009 must not add HealthKit imports: {rel}")
        for forbidden in ["HKWorkout", "HKQuantitySample", "HKHealthStore"]:
            if forbidden in text:
                fail(f"Task 009 must not create HealthKit objects yet: {rel}")

if not A005_INTEGRATION_MODE:
    for path in changed_files():
        if path in {
            "Shared/Models/SnowSegment.swift",
            "Shared/Models/SnowRun.swift",
            "Shared/Models/SnowDistanceBreakdown.swift",
            "Shared/Models/SnowVerticalMetrics.swift",
            "Shared/Models/SnowSessionState.swift",
            "Shared/Models/MotionSample.swift",
        }:
            fail(f"Task 009 must not modify core Snow algorithm/value model file: {path}")
        if path.startswith("Shared/WatchBridge/"):
            fail(f"Task 009 must not modify WatchBridge: {path}")
else:
    integration_changes = changed_files()
    for path in integration_changes:
        if path.startswith("Shared/WatchBridge/"):
            fail(f"A005 integration must not modify WatchBridge before A006: {path}")
    if list(ROOT.rglob("WatchBridgeSnowSessionProvider.swift")):
        fail("A006 WatchBridgeSnowSessionProvider must not exist during A005")

print("[snow-task-009] PASS: deterministic Snow QA fixtures, fixture generator, regression tests, project membership, manual QA matrix, documentation, review-pack script, cumulative verify dependencies, and scope guardrails are present.")
