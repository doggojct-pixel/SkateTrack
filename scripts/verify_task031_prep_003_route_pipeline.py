#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_003_route_pipeline.py
# Purpose: Verify ActivityViz-003/003-1 Shared route pipeline extraction, split layout, project membership, and fixture parity hooks.
# Delegates to: route fixture XCTest, xcodebuild build/test gates, and manual QA for renderer parity.

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ROUTE_DIR = REPO / "Shared/ActivityVisualization/Route"
SPLIT_FILES = [
    ROUTE_DIR / "RouteDisplayPipeline.swift",
    ROUTE_DIR / "RouteDisplayPipeline+Filtering.swift",
    ROUTE_DIR / "RouteDisplayPipeline+Startup.swift",
    ROUTE_DIR / "RouteDisplayPipeline+Segmentation.swift",
    ROUTE_DIR / "RouteDisplayPipeline+Bounds.swift",
]
SPLIT_FILE_NAMES = [path.name for path in SPLIT_FILES]
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
    "clean-gps-route", "startup-drift", "low-confidence-segment", "sparse-route",
    "duplicate-location-fixes", "large-jump", "too-few-points",
]
REQUIRED_SPLIT_TOKENS = {
    "RouteDisplayPipeline.swift": [
        "struct RouteDisplayPipeline", "func makeDisplayRoute(", "samples: [MotionSample]",
        "startDate: Date", "fidelityPolicy: ActivityFidelityPolicy", "ActivityRouteDisplayPoint(",
        "RouteDisplayResult(", "RouteDisplaySummary(",
    ],
    "RouteDisplayPipeline+Filtering.swift": [
        "deduplicatedTrustedLocationFixes", "validCoordinate(from:", "isTrustedDisplayRouteSample", "locationFixKey",
    ],
    "RouteDisplayPipeline+Startup.swift": [
        "isStartupWarmupSample", "firstGPSLockAnchorTimestamp", "firstStableStartupAnchorTimestamp",
        "startupAnchorGuardApplies", "isPreferredFreshAnchor",
    ],
    "RouteDisplayPipeline+Segmentation.swift": [
        "makeRouteSegments", "RouteDisplaySegment(", "shouldStartNewRouteSegment",
        "shouldSuppressSmallAreaJitter", "smoothDisplayCoordinate", "interpolatedCoordinate",
    ],
    "RouteDisplayPipeline+Bounds.swift": [
        "distanceMeters", "RouteDisplayBounds(", "quality(for", "diagnosticsMessages", "emptyResult",
    ],
}

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


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def require_path(path: Path) -> None:
    if path.exists():
        ok(f"required path exists: {rel(path)}")
    else:
        fail(f"missing required path: {rel(path)}")


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        fail(f"cannot read missing file: {rel(path)}")
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
    paths = [root] if root.is_file() else [p for p in root.rglob("*.swift") if p.is_file()]
    count = 0
    for path in paths:
        for line in read_text(path).splitlines():
            if compiled.search(line):
                count += 1
    return count


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


def verify_split_files() -> None:
    all_text = "\n".join(read_text(path) for path in SPLIT_FILES)
    emit(f"ROUTE_PIPELINE_SPLIT_FILE_COUNT={len(SPLIT_FILES)}")
    for path in SPLIT_FILES:
        require_path(path)
        name = path.name
        text = read_text(path)
        emit(f"FIRST_LINE[{name}]={first_line(path)}")
        emit(f"LINE_COUNT[{name}]={line_count(path)}")
        if first_line(path).startswith("// [協作區]"):
            ok(f"{name} has collaboration header")
        else:
            fail(f"{name} missing collaboration header")
        if line_count(path) <= 500:
            ok(f"{name} stays under 500 lines")
        else:
            fail(f"{name} exceeds 500 lines")
        forbidden_imports = re.findall(r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b", text, flags=re.MULTILINE)
        emit(f"FORBIDDEN_UI_IMPORT_COUNT[{name}]={len(forbidden_imports)}")
        if forbidden_imports:
            fail(f"{name} imports platform UI frameworks")
        else:
            ok(f"{name} avoids platform UI imports")
        for token in REQUIRED_SPLIT_TOKENS.get(name, []):
            require_token(text, token, name)
    if "displayDerived" in all_text or "displayDerivedTotalAscentMeters" in all_text:
        fail("route pipeline split files contain displayDerived stored-truth tokens")
    else:
        ok("route pipeline split files do not contain displayDerived tokens")
    if all(path.name == "RouteDisplayPipeline.swift" or "extension RouteDisplayPipeline" in read_text(path) for path in SPLIT_FILES):
        ok("route pipeline helper files use RouteDisplayPipeline extensions")
    else:
        fail("route pipeline helper files do not use RouteDisplayPipeline extensions")


def verify_tests() -> None:
    text = read_text(TEST_FILE)
    emit(f"FIRST_LINE[RouteDisplayFixtureTests.swift]={first_line(TEST_FILE)}")
    emit(f"LINE_COUNT[RouteDisplayFixtureTests.swift]={line_count(TEST_FILE)}")
    if line_count(TEST_FILE) <= 500:
        ok("RouteDisplayFixtureTests.swift stays under 500 lines")
    else:
        fail("RouteDisplayFixtureTests.swift exceeds 500 lines")
    for token in [
        "testSharedRouteDisplayPipelineMatchesActivityViz002Baselines", "RouteDisplayPipeline()",
        "makeDisplayRoute(", "result.summary.displayPointCount", "result.summary.hasStartupWarmup",
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
    expected_files = sorted(["route_display_fixture_baselines.json"] + [f"{fixture_id.replace('-', '_')}.json" for fixture_id in REQUIRED_FIXTURE_IDS])
    emit(f"FIXTURE_JSON_FILE_COUNT={len(json_files)}")
    if json_files == expected_files:
        ok("fixture JSON inventory matches expected files")
    else:
        fail(f"unexpected fixture JSON inventory: {json_files}")


def verify_project_membership() -> None:
    text = read_text(PBXPROJ)
    file_structure_text = read_text(FILE_STRUCTURE)
    route_group_body = extract_pbx_object(text, "31A200000000000000000000", "Route")
    group_match = re.search(r"children = \((.*?)\);", route_group_body, flags=re.DOTALL)
    route_group_children = group_match.group(1) if group_match else ""
    expected_ids = {
        "RouteDisplayPipeline.swift": "31A250000000000000000001",
        "RouteDisplayPipeline+Filtering.swift": "31A251000000000000000001",
        "RouteDisplayPipeline+Startup.swift": "31A252000000000000000001",
        "RouteDisplayPipeline+Segmentation.swift": "31A253000000000000000001",
        "RouteDisplayPipeline+Bounds.swift": "31A254000000000000000001",
    }
    all_grouped = True
    all_file_refs = True
    all_sources = True
    for name, file_id in expected_ids.items():
        grouped = f"{file_id} /* {name} */" in route_group_children
        file_ref_pattern = re.escape(f"{file_id} /* {name} */ = {{isa = PBXFileReference;") + r"[^}]*path = \"?" + re.escape(name) + r"\"?;[^}]*sourceTree = \"<group>\";"
        file_ref = re.search(file_ref_pattern, text) is not None
        build_count = len(re.findall(re.escape(f"/* {name} in Sources */ = {{isa = PBXBuildFile;"), text))
        source_count = len(re.findall(re.escape(f"/* {name} in Sources */,"), text))
        docs = name in file_structure_text
        emit(f"PROJECT_GROUP_CONTAINS[{name}]={'YES' if grouped else 'NO'}")
        emit(f"PROJECT_FILEREF_GROUP_RELATIVE[{name}]={'YES' if file_ref else 'NO'}")
        emit(f"PROJECT_BUILD_FILE_COUNT[{name}]={build_count}")
        emit(f"PROJECT_SOURCE_PHASE_COUNT[{name}]={source_count}")
        emit(f"FILE_STRUCTURE_DOCUMENTS[{name}]={'YES' if docs else 'NO'}")
        all_grouped = all_grouped and grouped
        all_file_refs = all_file_refs and file_ref
        all_sources = all_sources and build_count == 3 and source_count == 3
        if docs:
            ok(f"FILE_STRUCTURE documents {name}")
        else:
            fail(f"FILE_STRUCTURE is missing {name}")
    repo_root_path_token_present = "path = Shared/ActivityVisualization/Route/RouteDisplayPipeline" in text
    emit(f"PROJECT_ROUTE_SPLIT_GROUP_CONTAINS_ALL={'YES' if all_grouped else 'NO'}")
    emit(f"PROJECT_ROUTE_SPLIT_FILEREFS_GROUP_RELATIVE={'YES' if all_file_refs else 'NO'}")
    emit(f"PROJECT_ROUTE_SPLIT_SOURCES_COMPLETE={'YES' if all_sources else 'NO'}")
    emit(f"PROJECT_ROUTE_SPLIT_REPO_ROOT_PATH_TOKEN_PRESENT={'YES' if repo_root_path_token_present else 'NO'}")
    if all_grouped and all_file_refs and all_sources and not repo_root_path_token_present:
        ok("route pipeline split files are grouped under Shared/ActivityVisualization/Route with iOS/macOS/watchOS source membership")
    else:
        fail("route pipeline split project membership is incomplete or path resolution may be wrong")


def verify_docs() -> None:
    dev_log = read_text(DEV_LOG)
    structure = read_text(FILE_STRUCTURE)
    require_token(dev_log, "Task-031-prep-ActivityViz-003 Shared Route Pipeline Extraction", "DEV_LOG")
    require_token(dev_log, "Task-031-prep-ActivityViz-003-1 Shared Route Pipeline Split Alignment", "DEV_LOG")
    require_token(structure, "ActivityViz-003-1 splits helper logic", "FILE_STRUCTURE")
    for name in SPLIT_FILE_NAMES:
        require_token(structure, name, "FILE_STRUCTURE")


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
            ok(f"renderer path present for diff guard: {rel(path)}")
        else:
            warn(f"renderer path missing from pack: {rel(path)}")


def main() -> int:
    emit("===== Task-031-prep ActivityViz-003/003-1 route pipeline verifier =====")
    emit("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    emit("Aligned subtask: task-031-prep-ActivityViz-003-1 — Shared Route Pipeline Split Alignment")
    emit(f"REPO={REPO}")
    for path in SPLIT_FILES + [TEST_FILE, PBXPROJ, DEV_LOG, FILE_STRUCTURE, FIXTURE_MANIFEST, SHARED_ACTIVITYVIZ]:
        require_path(path)
    verify_split_files()
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
