#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_009_elevation_pipeline.py
# Purpose: Verify ActivityViz-009 Shared elevation display pipeline shell, project membership, and scope boundaries.

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PBXPROJ = REPO / "SkateTrack.xcodeproj/project.pbxproj"
DEV_LOG = REPO / "docs/history/DEV_LOG.md"
FILE_STRUCTURE = REPO / "docs/reference/FILE_STRUCTURE.md"
ELEVATION_DIR = REPO / "Shared/ActivityVisualization/Elevation"
PIPELINE = ELEVATION_DIR / "ElevationDisplayPipeline.swift"
MODELS = ELEVATION_DIR / "ElevationDisplayModels.swift"
TEST_FILE = REPO / "Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift"
FAILURES: list[str] = []
WARNINGS: list[str] = []


def emit(message: str) -> None:
    print(message)


def fail(message: str) -> None:
    FAILURES.append(message)
    emit(f"FAIL: {message}")


def warn(message: str) -> None:
    WARNINGS.append(message)
    emit(f"WARNING: {message}")


def ok(message: str) -> None:
    emit(f"PASS: {message}")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        fail(f"cannot read missing file: {rel(path)}")
    except Exception as exc:
        fail(f"cannot read {rel(path)}: {type(exc).__name__}: {exc}")
    return ""


def require_path(path: Path) -> None:
    if path.exists():
        ok(f"required path exists: {rel(path)}")
    else:
        fail(f"missing required path: {rel(path)}")


def line_count(path: Path) -> int:
    return len(read_text(path).splitlines())


def first_line(path: Path) -> str:
    lines = read_text(path).splitlines()
    return lines[0] if lines else ""


def require_header_and_line_limit(path: Path, limit: int = 500) -> None:
    first = first_line(path)
    count = line_count(path)
    emit(f"FIRST_LINE[{rel(path)}]={first}")
    emit(f"LINE_COUNT[{rel(path)}]={count}")
    if first.startswith("// [協作區]") or first.startswith("// [自主區]"):
        ok(f"{path.name} has collaboration header")
    else:
        fail(f"{path.name} missing collaboration header")
    if count <= limit:
        ok(f"{path.name} stays under {limit} lines")
    else:
        fail(f"{path.name} exceeds {limit} lines")


def require_token(path: Path, token: str, label: str | None = None) -> None:
    text = read_text(path)
    label = label or rel(path)
    if token in text:
        ok(f"{label} contains token: {token}")
    else:
        fail(f"{label} missing token: {token}")


def require_absent(path: Path, token: str, label: str | None = None) -> None:
    text = read_text(path)
    label = label or rel(path)
    if token in text:
        fail(f"{label} contains forbidden token: {token}")
    else:
        ok(f"{label} does not contain forbidden token: {token}")


def grep_count(root: Path, pattern: str) -> int:
    compiled = re.compile(pattern)
    if not root.exists():
        return 0
    paths = [root] if root.is_file() else [p for p in root.rglob("*.swift") if p.is_file()]
    count = 0
    for path in paths:
        for line in read_text(path).splitlines():
            if compiled.search(line):
                count += 1
    return count


def token_count(paths: list[Path], tokens: tuple[str, ...]) -> int:
    count = 0
    for root in paths:
        if not root.exists():
            continue
        files = [root] if root.is_file() else [p for p in root.rglob("*") if p.is_file()]
        for path in files:
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            for token in tokens:
                count += text.count(token)
    return count


def git_status(relative: str) -> str:
    result = subprocess.run(
        ["git", "status", "--short", "--", relative],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        fail(f"git status failed for {relative}: {result.stderr.strip()}")
    return result.stdout.strip()


def require_clean(relative: str) -> None:
    status = git_status(relative)
    key = relative.upper().replace("/", "_").replace(".", "_").replace("-", "_")
    if status:
        emit(f"{key}_STATUS={status}")
        fail(f"untouched guard changed: {relative}")
    else:
        emit(f"{key}_STATUS=CLEAN")
        ok(f"untouched guard clean: {relative}")


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


def verify_source_files() -> None:
    for path in [MODELS, PIPELINE, TEST_FILE]:
        require_path(path)
        require_header_and_line_limit(path)

    for token in [
        "case barometerRelative",
        "case coreLocationAbsolute",
        "case debugSimulated",
        "let segmentID: Int",
        "let selectedSource: ElevationDisplaySource",
        "let segmentCount: Int",
        "let hasAbsoluteAnchor: Bool",
        "displayDerivedTotalAscentMeters",
    ]:
        require_token(MODELS, token)

    for token in [
        "struct ElevationDisplayPipeline",
        "func makeDisplayElevation(",
        "samples: [MotionSample]",
        "fidelityPolicy: ActivityFidelityPolicy",
        "selectedElevationDisplaySource",
        "absoluteElevationDisplayAnchor",
        "altitudeMicroDipDisplayGuardedPoints",
        "smoothedElevationPoints",
        "shouldStartNewElevationSegment",
        "displayDerivedTotalAscentMeters(from:",
        "switch selectedSource",
        "case .barometerRelative:",
        "guard let relativeAltitude = trustedBarometerRelativeAltitude(for: sample) else { return nil }",
        "case .debugSimulated:",
        "case .coreLocationAbsolute, .motionSample, .displayDerived:",
        "ElevationDisplayResult(",
        "ElevationDisplaySummary(",
        "ElevationDisplayDiagnostics(",
    ]:
        require_token(PIPELINE, token)

    for token in [
        "testSharedElevationPipelineBuildsAnchoredBarometerProfile",
        "testSharedElevationPipelineDropsUntrustedCoreLocationSamplesAndSegmentsGaps",
        "testSharedElevationPipelineDownsamplesWithoutChangingStoredSamples",
        "ElevationDisplayPipeline()",
        "makeDisplayElevation(",
        "displayDerivedTotalAscentMeters",
        "XCTAssertEqual(samples[3].altitudeMeters, 90)",
    ]:
        require_token(TEST_FILE, token)

    for forbidden in ["import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"]:
        require_absent(PIPELINE, forbidden)
        require_absent(MODELS, forbidden)
        require_absent(TEST_FILE, forbidden)


def verify_project_membership() -> None:
    text = read_text(PBXPROJ)
    file_structure = read_text(FILE_STRUCTURE)
    elevation_group = extract_pbx_object(text, "31A400000000000000000000", "Elevation")
    tests_group = extract_pbx_object(text, "31B200000000000000000000", "ActivityVisualizationTests")
    checks = {
        "ElevationDisplayModels.swift": "31A400000000000000000001",
        "ElevationDisplayPipeline.swift": "31A410000000000000000001",
    }
    all_grouped = True
    all_file_refs = True
    all_sources = True
    for name, file_id in checks.items():
        grouped = f"{file_id} /* {name} */" in elevation_group
        file_ref = re.search(
            re.escape(f"{file_id} /* {name} */ = {{isa = PBXFileReference;")
            + r"[^}]*path = \"?" + re.escape(name) + r"\"?;[^}]*sourceTree = \"<group>\";",
            text,
        ) is not None
        build_count = len(re.findall(re.escape(f"/* {name} in Sources */ = {{isa = PBXBuildFile;"), text))
        source_count = len(re.findall(re.escape(f"/* {name} in Sources */,"), text))
        docs = name in file_structure
        emit(f"PROJECT_GROUP_CONTAINS[{name}]={'YES' if grouped else 'NO'}")
        emit(f"PROJECT_FILEREF_GROUP_RELATIVE[{name}]={'YES' if file_ref else 'NO'}")
        emit(f"PROJECT_BUILD_FILE_COUNT[{name}]={build_count}")
        emit(f"PROJECT_SOURCE_PHASE_COUNT[{name}]={source_count}")
        emit(f"FILE_STRUCTURE_DOCUMENTS[{name}]={'YES' if docs else 'NO'}")
        all_grouped = all_grouped and grouped
        all_file_refs = all_file_refs and file_ref
        all_sources = all_sources and build_count == 3 and source_count == 3
        if not docs:
            fail(f"FILE_STRUCTURE is missing {name}")
    test_grouped = "31B400000000000000000001 /* ElevationDisplayPipelineTests.swift */" in tests_group
    test_ref = "31B400000000000000000001 /* ElevationDisplayPipelineTests.swift */ = {isa = PBXFileReference;" in text
    test_build_count = len(re.findall(re.escape("/* ElevationDisplayPipelineTests.swift in Sources */ = {isa = PBXBuildFile;"), text))
    test_source_count = len(re.findall(re.escape("/* ElevationDisplayPipelineTests.swift in Sources */,"), text))
    emit(f"PROJECT_TEST_GROUP_CONTAINS[ElevationDisplayPipelineTests.swift]={'YES' if test_grouped else 'NO'}")
    emit(f"PROJECT_TEST_BUILD_FILE_COUNT[ElevationDisplayPipelineTests.swift]={test_build_count}")
    emit(f"PROJECT_TEST_SOURCE_PHASE_COUNT[ElevationDisplayPipelineTests.swift]={test_source_count}")
    if not (test_grouped and test_ref and test_build_count == 1 and test_source_count == 1):
        fail("ElevationDisplayPipelineTests.swift project membership is incomplete")
    repo_root_path_token_present = "path = Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline" in text
    emit(f"PROJECT_ELEVATION_FILEREFS_GROUP_RELATIVE={'YES' if all_file_refs else 'NO'}")
    emit(f"PROJECT_ELEVATION_SOURCES_COMPLETE={'YES' if all_sources else 'NO'}")
    emit(f"PROJECT_ELEVATION_REPO_ROOT_PATH_TOKEN_PRESENT={'YES' if repo_root_path_token_present else 'NO'}")
    if all_grouped and all_file_refs and all_sources and not repo_root_path_token_present:
        ok("elevation pipeline files are grouped under Shared/ActivityVisualization/Elevation with iOS/macOS/watchOS source membership")
    else:
        fail("elevation pipeline project membership is incomplete or path resolution may be wrong")


def verify_docs() -> None:
    for token in [
        "Task-031-prep-ActivityViz-009 Shared Elevation Display Pipeline Shell",
        "ElevationDisplayPipeline",
        "makeDisplayElevation",
        "ElevationDisplayPipelineTests",
        "elevation renderers untouched",
        "no elevation metric mutation",
    ]:
        require_token(DEV_LOG, token, "DEV_LOG")
    for token in [
        "Task-031-prep ActivityViz-009 Shared Elevation Display Pipeline Shell",
        "Shared/ActivityVisualization/Elevation/",
        "ElevationDisplayPipeline.swift",
        "ElevationDisplayPipelineTests.swift",
        "verify_task031_prep_009_elevation_pipeline.py",
    ]:
        require_token(FILE_STRUCTURE, token, "FILE_STRUCTURE")


def verify_scope_guards() -> None:
    for relative in [
        "Shared/ActivityVisualization/Route",
        "Shared/ActivityVisualization/Speed",
        "Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift",
        "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
        "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
        "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
        "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
        "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
        "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
        "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
        "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    ]:
        require_clean(relative)
    shared_ui_count = grep_count(REPO / "Shared/ActivityVisualization", r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b")
    test_ui_count = grep_count(REPO / "Tests/ActivityVisualizationTests", r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b")
    persistence_count = token_count(
        [
            REPO / "Shared/Models",
            REPO / "Shared/Persistence",
            REPO / "Shared/Export",
            REPO / "iOS/Core/Export",
            REPO / "iOS/Core/Import",
            REPO / "macOS",
        ],
        ("displayDerived", "displayDerivedTotalAscentMeters"),
    )
    emit(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_count}")
    emit(f"TEST_UI_IMPORT_COUNT={test_ui_count}")
    emit(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={persistence_count}")
    if shared_ui_count == 0:
        ok("Shared/ActivityVisualization avoids platform UI imports")
    else:
        fail("Shared/ActivityVisualization contains platform UI imports")
    if test_ui_count == 0:
        ok("ActivityVisualization tests avoid platform UI imports")
    else:
        fail("ActivityVisualization tests contain platform UI imports")
    if persistence_count == 0:
        ok("displayDerived tokens absent from persistence/export/package/macOS paths")
    else:
        fail("displayDerived tokens found outside the Shared elevation display shell/docs")


def main() -> int:
    emit("===== Task-031-prep ActivityViz-009 elevation pipeline verifier =====")
    emit("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    emit("Aligned subtask: task-031-prep-ActivityViz-009 — Shared Elevation Display Pipeline Shell")
    emit(f"REPO={REPO}")
    for path in [PBXPROJ, DEV_LOG, FILE_STRUCTURE, ELEVATION_DIR, MODELS, PIPELINE, TEST_FILE]:
        require_path(path)
    verify_source_files()
    verify_project_membership()
    verify_docs()
    verify_scope_guards()
    emit("===== Summary =====")
    emit(f"WARNING_COUNT={len(WARNINGS)}")
    emit(f"FAILURE_COUNT={len(FAILURES)}")
    if FAILURES:
        emit("VERIFY_TASK031_PREP_009_ELEVATION_PIPELINE_RESULT=FAILED")
        return 1
    emit("VERIFY_TASK031_PREP_009_ELEVATION_PIPELINE_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        emit("===== Verifier internal error =====")
        fail(f"verifier raised unexpected exception: {type(exc).__name__}: {exc}")
        emit("===== Summary =====")
        emit(f"WARNING_COUNT={len(WARNINGS)}")
        emit(f"FAILURE_COUNT={len(FAILURES)}")
        emit("VERIFY_TASK031_PREP_009_ELEVATION_PIPELINE_RESULT=FAILED")
        sys.exit(1)
