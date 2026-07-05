#!/usr/bin/env python3
"""Verify Task-031-prep ActivityViz-002 route fixture scope and baseline structure."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REQUIRED_FIXTURE_IDS = [
    "clean-gps-route",
    "startup-drift",
    "low-confidence-segment",
    "sparse-route",
    "duplicate-location-fixes",
    "large-jump",
    "too-few-points",
]
REQUIRED_FIXTURE_FILES = {
    "clean-gps-route": "clean_gps_route.json",
    "startup-drift": "startup_drift.json",
    "low-confidence-segment": "low_confidence_segment.json",
    "sparse-route": "sparse_route.json",
    "duplicate-location-fixes": "duplicate_location_fixes.json",
    "large-jump": "large_jump.json",
    "too-few-points": "too_few_points.json",
}
FORBIDDEN_UI_IMPORTS = re.compile(r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b", re.MULTILINE)
FORBIDDEN_STORED_TRUTH_TOKENS = ["displayDerived", "displayDerivedTotalAscentMeters"]


def fail(message: str, failures: list[str]) -> None:
    print(f"FAIL: {message}")
    failures.append(message)


def pass_(message: str) -> None:
    print(f"PASS: {message}")


def load_json(path: Path, failures: list[str]) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:  # noqa: BLE001 - verifier should report every parse failure clearly.
        fail(f"JSON parse failed: {path}: {error}", failures)
        return {}


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    failures: list[str] = []
    warnings: list[str] = []

    print("===== Task-031-prep ActivityViz-002 route fixture verifier =====")
    print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    print("Aligned subtask: task-031-prep-ActivityViz-002 — Route Pipeline Test Fixtures")
    print(f"REPO={repo}")

    test_file = repo / "Tests/ActivityVisualizationTests/RouteDisplayFixtureTests.swift"
    fixture_dir = repo / "Tests/Fixtures/ActivityVisualization"
    manifest_file = fixture_dir / "route_display_fixture_baselines.json"
    pbxproj = repo / "SkateTrack.xcodeproj/project.pbxproj"
    dev_log = repo / "docs/history/DEV_LOG.md"
    file_structure = repo / "docs/reference/FILE_STRUCTURE.md"
    shared_activityviz = repo / "Shared/ActivityVisualization"

    required_paths = [test_file, fixture_dir, manifest_file, pbxproj, dev_log, file_structure, shared_activityviz]
    for path in required_paths:
        if path.exists():
            pass_(f"required path exists: {path.relative_to(repo)}")
        else:
            fail(f"missing required path: {path.relative_to(repo)}", failures)

    if test_file.exists():
        test_text = test_file.read_text(encoding="utf-8")
        first_line = test_text.splitlines()[0] if test_text.splitlines() else ""
        line_count = len(test_text.splitlines())
        print(f"LINE_COUNT[{test_file.relative_to(repo)}]={line_count}")
        if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]"):
            pass_("RouteDisplayFixtureTests.swift has collaboration header")
        else:
            fail("RouteDisplayFixtureTests.swift is missing collaboration header", failures)
        if line_count <= 500:
            pass_("RouteDisplayFixtureTests.swift stays under 500 lines")
        else:
            fail("RouteDisplayFixtureTests.swift exceeds 500 lines", failures)
        for token in ["@testable import SkateTrack_iOS", "loadScenarioFixtures", "route_display_fixture_baselines.json", "Data(contentsOf:"]:
            if token in test_text:
                pass_(f"XCTest contains token: {token}")
            else:
                fail(f"XCTest missing token: {token}", failures)
        if "makeRouteSamples([" in test_text:
            fail("XCTest still contains hard-coded makeRouteSamples fixture arrays", failures)
        else:
            pass_("XCTest loads JSON fixtures instead of hard-coded route arrays")
        if FORBIDDEN_UI_IMPORTS.search(test_text):
            fail("RouteDisplayFixtureTests.swift imports a platform UI framework", failures)
        else:
            pass_("RouteDisplayFixtureTests.swift avoids UI framework imports")

    manifest = load_json(manifest_file, failures) if manifest_file.exists() else {}
    fixtures = manifest.get("fixtures", []) if isinstance(manifest, dict) else []
    ids = [entry.get("id") for entry in fixtures]
    if ids == REQUIRED_FIXTURE_IDS:
        pass_("manifest fixture order matches ActivityViz-002 scope")
    else:
        fail(f"manifest fixture order mismatch: {ids}", failures)

    for forbidden in FORBIDDEN_STORED_TRUTH_TOKENS:
        if forbidden in json.dumps(manifest, sort_keys=True):
            fail(f"manifest contains forbidden stored-truth token: {forbidden}", failures)
    if manifest:
        pass_("manifest contains no displayDerived stored-truth tokens")

    entries_by_id = {entry.get("id"): entry for entry in fixtures if isinstance(entry, dict)}
    for fixture_id in REQUIRED_FIXTURE_IDS:
        expected_file_name = REQUIRED_FIXTURE_FILES[fixture_id]
        entry = entries_by_id.get(fixture_id)
        if not entry:
            fail(f"manifest missing fixture id: {fixture_id}", failures)
            continue
        if entry.get("fileName") == expected_file_name:
            pass_(f"manifest file name matches: {fixture_id}")
        else:
            fail(f"manifest file name mismatch for {fixture_id}: {entry.get('fileName')}", failures)
        scenario_path = fixture_dir / expected_file_name
        if not scenario_path.exists():
            fail(f"missing scenario fixture file: {expected_file_name}", failures)
            continue
        scenario = load_json(scenario_path, failures)
        if scenario.get("id") != fixture_id:
            fail(f"scenario id mismatch in {expected_file_name}", failures)
        if scenario.get("fileName") != expected_file_name:
            fail(f"scenario fileName mismatch in {expected_file_name}", failures)
        if scenario.get("fixtureVersion") == 2:
            pass_(f"scenario fixtureVersion is 2: {fixture_id}")
        else:
            fail(f"scenario fixtureVersion is not 2: {fixture_id}", failures)
        for flag in ["displayOnly", "mutatesStoredRoute", "mutatesTrustedMetrics", "mutatesPackageSchema"]:
            if flag not in scenario:
                fail(f"scenario missing flag {flag}: {fixture_id}", failures)
        if scenario.get("displayOnly") is True and scenario.get("mutatesStoredRoute") is False and scenario.get("mutatesTrustedMetrics") is False and scenario.get("mutatesPackageSchema") is False:
            pass_(f"scenario is display-only/no-mutation: {fixture_id}")
        else:
            fail(f"scenario mutation flags are unsafe: {fixture_id}", failures)
        samples = scenario.get("samples", [])
        if scenario.get("rawSampleCount") == len(samples):
            pass_(f"raw sample count matches samples array: {fixture_id}")
        else:
            fail(f"raw sample count mismatch: {fixture_id}", failures)
        for key in ["semanticDistribution", "displayPointCount", "routeQuality"]:
            scenario_key = "expectedSemanticDistribution" if key == "semanticDistribution" else ("expectedDisplayPointCount" if key == "displayPointCount" else "expectedRouteQuality")
            if scenario.get(scenario_key) == entry.get(key):
                pass_(f"scenario matches manifest {key}: {fixture_id}")
            else:
                fail(f"scenario/manifest mismatch for {key}: {fixture_id}", failures)
        for quality_key in ["sampleCount", "gpsSampleCount", "uniqueCoordinateCount", "lowConfidenceSegmentCount", "staleLocationSampleCount", "longLocationUpdateGapCount", "longMotionSampleGapCount"]:
            if quality_key in scenario.get("expectedRouteQuality", {}):
                pass_(f"route quality includes {quality_key}: {fixture_id}")
            else:
                fail(f"route quality missing {quality_key}: {fixture_id}", failures)
        scenario_text = scenario_path.read_text(encoding="utf-8")
        for forbidden in FORBIDDEN_STORED_TRUTH_TOKENS:
            if forbidden in scenario_text:
                fail(f"scenario contains forbidden stored-truth token {forbidden}: {fixture_id}", failures)

    if pbxproj.exists():
        pbx_text = pbxproj.read_text(encoding="utf-8", errors="replace")
        if "RouteDisplayFixtureTests.swift" in pbx_text:
            pass_("project includes RouteDisplayFixtureTests.swift reference")
        else:
            fail("project missing RouteDisplayFixtureTests.swift reference", failures)
        if "RouteDisplayFixtureTests.swift in Sources" in pbx_text:
            pass_("RouteDisplayFixtureTests.swift is in iOSTests Sources")
        else:
            fail("RouteDisplayFixtureTests.swift missing from Sources build phase", failures)
        if "ActivityVisualizationTests" in pbx_text:
            pass_("project includes ActivityVisualizationTests group")
        else:
            fail("project missing ActivityVisualizationTests group", failures)

    if shared_activityviz.exists():
        shared_import_matches = []
        for swift_file in shared_activityviz.rglob("*.swift"):
            text = swift_file.read_text(encoding="utf-8")
            if FORBIDDEN_UI_IMPORTS.search(text):
                shared_import_matches.append(str(swift_file.relative_to(repo)))
        if shared_import_matches:
            fail(f"Shared/ActivityVisualization has UI imports: {shared_import_matches}", failures)
        else:
            pass_("Shared/ActivityVisualization has no platform UI imports")

    if dev_log.exists() and "ActivityViz-002" in dev_log.read_text(encoding="utf-8"):
        pass_("DEV_LOG documents ActivityViz-002")
    else:
        fail("DEV_LOG missing ActivityViz-002 entry", failures)
    if file_structure.exists():
        fs_text = file_structure.read_text(encoding="utf-8")
        for token in ["Tests/ActivityVisualizationTests", "Tests/Fixtures/ActivityVisualization"]:
            if token in fs_text:
                pass_(f"FILE_STRUCTURE documents {token}")
            else:
                fail(f"FILE_STRUCTURE missing {token}", failures)

    print("===== Summary =====")
    print(f"WARNING_COUNT={len(warnings)}")
    print(f"FAILURE_COUNT={len(failures)}")
    if failures:
        print("VERIFY_TASK031_PREP_002_ROUTE_FIXTURES_RESULT=FAILED")
        return 1
    print("VERIFY_TASK031_PREP_002_ROUTE_FIXTURES_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
