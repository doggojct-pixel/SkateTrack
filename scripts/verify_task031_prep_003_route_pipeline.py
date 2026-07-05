#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_003_route_pipeline.py
# Purpose: Verify ActivityViz-003 Shared route pipeline extraction scope, project membership, and fixture parity hooks.
# Delegates to: route fixture XCTest, xcodebuild build/test gates, and manual QA for renderer parity.

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PIPELINE = REPO / "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift"
TEST_FILE = REPO / "Tests/ActivityVisualizationTests/RouteDisplayFixtureTests.swift"
PBXPROJ = REPO / "SkateTrack.xcodeproj/project.pbxproj"
DEV_LOG = REPO / "docs/history/DEV_LOG.md"
FILE_STRUCTURE = REPO / "docs/reference/FILE_STRUCTURE.md"
FIXTURE_MANIFEST = REPO / "Tests/Fixtures/ActivityVisualization/route_display_fixture_baselines.json"
SHARED_ACTIVITYVIZ = REPO / "Shared/ActivityVisualization"
FORBIDDEN_RENDERER_PATHS = [
    REPO / "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    REPO / "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
]
REQUIRED_FIXTURE_IDS = [
    "clean-gps-route",
    "startup-drift",
    "low-confidence-segment",
    "sparse-route",
    "duplicate-location-fixes",
    "large-jump",
    "too-few-points",
]

failure_count = 0
warning_count = 0


def emit(message: str) -> None:
    print(message)


def fail(message: str) -> None:
    global failure_count
    failure_count += 1
    emit(f"FAIL: {message}")


def warn(message: str) -> None:
    global warning_count
    warning_count += 1
    emit(f"WARNING: {message}")


def ok(message: str) -> None:
    emit(f"PASS: {message}")


def require_path(path: Path) -> None:
    if path.exists():
        ok(f"required path exists: {path.relative_to(REPO)}")
    else:
        fail(f"missing required path: {path.relative_to(REPO)}")


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        fail(f"cannot read missing file: {path.relative_to(REPO)}")
        return ""


def line_count(path: Path) -> int:
    return len(read_text(path).splitlines())


def first_line(path: Path) -> str:
    text = read_text(path)
    return text.splitlines()[0] if text.splitlines() else ""


def require_token(text: str, token: str, label: str) -> None:
    if token in text:
        ok(f"{label} contains token: {token}")
    else:
        fail(f"{label} missing token: {token}")


def grep_count(root: Path, pattern: str) -> int:
    compiled = re.compile(pattern)
    count = 0
    if root.is_file():
        paths = [root]
    else:
        paths = [p for p in root.rglob("*.swift") if p.is_file()]
    for path in paths:
        for line in read_text(path).splitlines():
            if compiled.search(line):
                count += 1
    return count


def verify_pipeline_file() -> None:
    text = read_text(PIPELINE)
    emit(f"FIRST_LINE[RouteDisplayPipeline.swift]={first_line(PIPELINE)}")
    emit(f"LINE_COUNT[RouteDisplayPipeline.swift]={line_count(PIPELINE)}")
    if first_line(PIPELINE).startswith("// [協作區]"):
        ok("RouteDisplayPipeline.swift has collaboration header")
    else:
        fail("RouteDisplayPipeline.swift missing collaboration header")
    if line_count(PIPELINE) <= 500:
        ok("RouteDisplayPipeline.swift stays under 500 lines")
    else:
        fail("RouteDisplayPipeline.swift exceeds 500 lines")
    for token in [
        "struct RouteDisplayPipeline",
        "func makeDisplayRoute(",
        "samples: [MotionSample]",
        "startDate: Date",
        "fidelityPolicy: ActivityFidelityPolicy",
        "ActivityRouteDisplayPoint(",
        "RouteDisplaySegment(",
        "RouteDisplayResult(",
        "RouteDisplaySummary(",
        "validCoordinate(from:",
        "deduplicatedTrustedLocationFixes",
        "isStartupWarmupSample",
        "firstGPSLockAnchorTimestamp",
        "shouldSuppressSmallAreaJitter",
        "smoothDisplayCoordinate",
        "displayDerived",
    ]:
        if token == "displayDerived":
            if token in text:
                fail("RouteDisplayPipeline.swift contains displayDerived stored-truth token")
            else:
                ok("RouteDisplayPipeline.swift does not contain displayDerived tokens")
        else:
            require_token(text, token, "RouteDisplayPipeline.swift")
    forbidden_imports = re.findall(r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b", text, flags=re.MULTILINE)
    emit(f"PIPELINE_FORBIDDEN_UI_IMPORT_COUNT={len(forbidden_imports)}")
    if forbidden_imports:
        fail("RouteDisplayPipeline.swift imports platform UI frameworks")
    else:
        ok("RouteDisplayPipeline.swift avoids platform UI imports")


def verify_tests() -> None:
    text = read_text(TEST_FILE)
    emit(f"FIRST_LINE[RouteDisplayFixtureTests.swift]={first_line(TEST_FILE)}")
    emit(f"LINE_COUNT[RouteDisplayFixtureTests.swift]={line_count(TEST_FILE)}")
    if line_count(TEST_FILE) <= 500:
        ok("RouteDisplayFixtureTests.swift stays under 500 lines")
    else:
        fail("RouteDisplayFixtureTests.swift exceeds 500 lines")
    for token in [
        "testSharedRouteDisplayPipelineMatchesActivityViz002Baselines",
        "RouteDisplayPipeline()",
        "makeDisplayRoute(",
        "result.summary.displayPointCount",
        "result.summary.hasStartupWarmup",
        "result.summary.hasLowConfidenceSegments",
    ]:
        require_token(text, token, "RouteDisplayFixtureTests.swift")


def verify_fixtures() -> None:
    data = json.loads(read_text(FIXTURE_MANIFEST) or "{}")
    ids = [entry.get("id") for entry in data.get("fixtures", [])]
    emit(f"FIXTURE_IDS={','.join(str(i) for i in ids)}")
    if ids == REQUIRED_FIXTURE_IDS:
        ok("fixture order matches ActivityViz-002 baseline")
    else:
        fail("fixture order changed unexpectedly")
    fixture_dir = FIXTURE_MANIFEST.parent
    json_files = sorted(path.name for path in fixture_dir.glob("*.json"))
    emit(f"FIXTURE_JSON_FILE_COUNT={len(json_files)}")
    expected_files = sorted(["route_display_fixture_baselines.json"] + [f"{fixture_id.replace('-', '_')}.json" for fixture_id in REQUIRED_FIXTURE_IDS])
    if json_files == expected_files:
        ok("fixture JSON inventory matches expected files")
    else:
        fail(f"unexpected fixture JSON inventory: {json_files}")


def extract_pbx_object(text: str, object_id: str, label: str) -> str:
    marker = f"{object_id} /* {label} */ = {{"
    start = text.find(marker)
    if start == -1:
        return ""
    cursor = start + len(marker)
    depth = 1
    while cursor < len(text) and depth > 0:
        char = text[cursor]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        cursor += 1
    return text[start:cursor]


def verify_project_membership() -> None:
    text = read_text(PBXPROJ)
    file_structure_text = read_text(FILE_STRUCTURE)
    ref_count = text.count("RouteDisplayPipeline.swift")
    build_file_ids = re.findall(
        r"31A25000000000000000010[123] /\* RouteDisplayPipeline\.swift in Sources \*/ = \{isa = PBXBuildFile;",
        text,
    )
    source_phase_ids = re.findall(
        r"31A25000000000000000010[123] /\* RouteDisplayPipeline\.swift in Sources \*/,",
        text,
    )
    route_group_body = extract_pbx_object(text, "31A200000000000000000000", "Route")
    route_group_children_match = re.search(r"children = \((.*?)\);", route_group_body, flags=re.DOTALL)
    route_group_children = route_group_children_match.group(1) if route_group_children_match else ""
    route_group_contains_pipeline = "31A250000000000000000001 /* RouteDisplayPipeline.swift */" in route_group_children
    pipeline_file_ref_match = re.search(
        r"31A250000000000000000001 /\* RouteDisplayPipeline\.swift \*/ = \{isa = PBXFileReference;[^}]*path = RouteDisplayPipeline\.swift;[^}]*sourceTree = \"<group>\";",
        text,
    )
    repo_root_path_token_present = "path = Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift" in text
    file_structure_documents_pipeline = "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift" in file_structure_text
    emit(f"PROJECT_ROUTE_PIPELINE_TOKEN_COUNT={ref_count}")
    emit(f"PROJECT_ROUTE_PIPELINE_BUILD_FILE_ID_COUNT={len(build_file_ids)}")
    emit(f"PROJECT_ROUTE_PIPELINE_SOURCE_PHASE_ID_COUNT={len(source_phase_ids)}")
    emit(f"PROJECT_ROUTE_GROUP_CONTAINS_PIPELINE={'YES' if route_group_contains_pipeline else 'NO'}")
    emit(f"PROJECT_ROUTE_PIPELINE_FILEREF_GROUP_RELATIVE={'YES' if pipeline_file_ref_match else 'NO'}")
    emit(f"PROJECT_ROUTE_PIPELINE_REPO_ROOT_PATH_TOKEN_PRESENT={'YES' if repo_root_path_token_present else 'NO'}")
    emit(f"FILE_STRUCTURE_DOCUMENTS_ROUTE_PIPELINE={'YES' if file_structure_documents_pipeline else 'NO'}")
    if ref_count >= 7:
        ok("project includes RouteDisplayPipeline.swift references")
    else:
        fail("project missing RouteDisplayPipeline.swift references")
    if len(build_file_ids) == 3 and len(source_phase_ids) == 3:
        ok("RouteDisplayPipeline.swift has build files and iOS/macOS/watchOS source entries")
    else:
        fail("RouteDisplayPipeline.swift build/source phase membership is incomplete")
    if route_group_contains_pipeline and pipeline_file_ref_match and not repo_root_path_token_present:
        ok("RouteDisplayPipeline.swift is grouped under Shared/ActivityVisualization/Route for correct relative path resolution")
    else:
        fail("RouteDisplayPipeline.swift project membership may resolve incorrectly")
    if file_structure_documents_pipeline:
        ok("FILE_STRUCTURE documents RouteDisplayPipeline.swift path before project membership validation")
    else:
        fail("FILE_STRUCTURE is missing RouteDisplayPipeline.swift path")


def verify_docs() -> None:
    dev_log = read_text(DEV_LOG)
    structure = read_text(FILE_STRUCTURE)
    require_token(dev_log, "Task-031-prep-ActivityViz-003 Shared Route Pipeline Extraction", "DEV_LOG")
    require_token(structure, "RouteDisplayPipeline.swift", "FILE_STRUCTURE")
    require_token(structure, "ActivityViz-003 Shared route pipeline extraction", "FILE_STRUCTURE")


def verify_scope_guards() -> None:
    shared_ui_count = grep_count(SHARED_ACTIVITYVIZ, r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b")
    emit(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_count}")
    if shared_ui_count:
        fail("Shared/ActivityVisualization contains platform UI imports")
    else:
        ok("Shared/ActivityVisualization avoids platform UI imports")
    persistence_display_count = grep_count(REPO / "Shared/Models", r"displayDerived|displayDerivedTotalAscentMeters")
    emit(f"DISPLAY_DERIVED_SHARED_MODELS_COUNT={persistence_display_count}")
    if persistence_display_count:
        fail("displayDerived token leaked into Shared/Models")
    else:
        ok("displayDerived tokens absent from Shared/Models")
    for path in FORBIDDEN_RENDERER_PATHS:
        if path.exists():
            ok(f"renderer path present for diff guard: {path.relative_to(REPO)}")
        else:
            warn(f"renderer path missing from pack: {path.relative_to(REPO)}")


def main() -> int:
    emit("===== Task-031-prep ActivityViz-003 route pipeline verifier =====")
    emit("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    emit("Aligned subtask: task-031-prep-ActivityViz-003 — Shared Route Pipeline Extraction")
    emit(f"REPO={REPO}")
    for path in [PIPELINE, TEST_FILE, PBXPROJ, DEV_LOG, FILE_STRUCTURE, FIXTURE_MANIFEST, SHARED_ACTIVITYVIZ]:
        require_path(path)
    verify_pipeline_file()
    verify_tests()
    verify_fixtures()
    verify_project_membership()
    verify_docs()
    verify_scope_guards()
    emit("===== Summary =====")
    emit(f"WARNING_COUNT={warning_count}")
    emit(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0:
        emit("VERIFY_TASK031_PREP_003_ROUTE_PIPELINE_RESULT=PASSED")
        return 0
    emit("VERIFY_TASK031_PREP_003_ROUTE_PIPELINE_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        emit("===== Verifier internal error =====")
        fail(f"verifier raised unexpected exception: {type(exc).__name__}: {exc}")
        emit("===== Summary =====")
        emit(f"WARNING_COUNT={warning_count}")
        emit(f"FAILURE_COUNT={failure_count}")
        emit("VERIFY_TASK031_PREP_003_ROUTE_PIPELINE_RESULT=FAILED")
        sys.exit(1)
