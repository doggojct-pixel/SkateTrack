#!/usr/bin/env python3
# [工程設定] Verifies Task-031-prep ActivityViz-012 unified activity visualization pipeline.

from pathlib import Path
import re
import subprocess
import sys

REPO = Path(__file__).resolve().parents[1]
FAILURES = 0
WARNINGS = 0

print("===== Task-031-prep ActivityViz-012 unified pipeline verifier =====")
print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
print("Aligned subtask: task-031-prep-ActivityViz-012 — Unified ActivityVisualizationPipeline Entry Point")
print(f"REPO={REPO}")


def fail(message: str) -> None:
    global FAILURES
    FAILURES += 1
    print(f"FAIL: {message}")


def warn(message: str) -> None:
    global WARNINGS
    WARNINGS += 1
    print(f"WARN: {message}")


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def rel(path: str) -> Path:
    return REPO / path


def read(path: str) -> str:
    return rel(path).read_text(encoding="utf-8")


def require_path(path: str) -> None:
    if rel(path).exists():
        pass_msg(f"required path exists: {path}")
    else:
        fail(f"required path missing: {path}")


def require_token(path: str, token: str) -> None:
    try:
        text = read(path)
    except FileNotFoundError:
        fail(f"cannot read missing file for token check: {path}")
        return
    if token in text:
        pass_msg(f"{path} contains token: {token}")
    else:
        fail(f"{path} missing token: {token}")


def forbid_token(path: str, token: str) -> None:
    try:
        text = read(path)
    except FileNotFoundError:
        fail(f"cannot read missing file for forbidden token check: {path}")
        return
    if token in text:
        fail(f"{path} contains forbidden token: {token}")
    else:
        pass_msg(f"{path} does not contain forbidden token: {token}")


def check_header_and_line_count(path: str, max_lines: int = 500) -> None:
    p = rel(path)
    if not p.exists():
        fail(f"missing file for header/line count: {path}")
        return
    lines = p.read_text(encoding="utf-8").splitlines()
    first_line = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first_line}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]"):
        pass_msg(f"{path} has collaboration header")
    else:
        fail(f"{path} missing collaboration header")
    if len(lines) <= max_lines:
        pass_msg(f"{path} stays under {max_lines} lines")
    else:
        fail(f"{path} exceeds {max_lines} lines")


def git_status(path: str) -> str:
    result = subprocess.run(
        ["git", "status", "--short", "--", path],
        cwd=REPO,
        text=True,
        capture_output=True,
        check=False,
    )
    return result.stdout.strip()


def expect_clean(path: str) -> None:
    status = git_status(path)
    label = path.upper().replace("/", "_").replace(".", "_") + "_STATUS"
    print(f"{label}={status or 'CLEAN'}")
    if status:
        fail(f"untouched guard changed: {path}")
    else:
        pass_msg(f"untouched guard clean: {path}")


def grep_shared_ui_imports() -> int:
    root = rel("Shared/ActivityVisualization")
    count = 0
    pattern = re.compile(r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b")
    for path in root.rglob("*.swift"):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if pattern.search(line):
                print(f"FORBIDDEN_SHARED_UI_IMPORT={path.relative_to(REPO)}:{line_number}:{line}")
                count += 1
    print(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={count}")
    return count


def grep_tests_ui_imports() -> int:
    root = rel("Tests/ActivityVisualizationTests")
    count = 0
    pattern = re.compile(r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b")
    for path in root.rglob("*.swift"):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if pattern.search(line):
                print(f"FORBIDDEN_TEST_UI_IMPORT={path.relative_to(REPO)}:{line_number}:{line}")
                count += 1
    print(f"TEST_UI_IMPORT_COUNT={count}")
    return count


def count_display_derived_persistence_tokens() -> int:
    allowed = {
        "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
        "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
        "Shared/ActivityVisualization/Elevation/ElevationDisplayModels.swift",
        "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
        "Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift",
    }
    roots = [
        "Shared/Models",
        "iOS/Core",
        "macOS/Core",
        "Shared/Persistence",
        "Shared/Repositories",
        "Shared/Packages",
        "macOS/Persistence",
        "macOS/Repositories",
        "iOS/Features/SessionSummary",
        "macOS/Features/SessionBrowser",
    ]
    pattern = re.compile(r"displayDerivedTotalAscentMeters|displayDerivedTotalDescentMeters|displayDerived")
    count = 0
    for root in roots:
        base = rel(root)
        if not base.exists():
            continue
        for path in base.rglob("*.swift"):
            relative = str(path.relative_to(REPO))
            if relative in allowed:
                continue
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
                if pattern.search(line):
                    print(f"DISPLAY_DERIVED_FORBIDDEN={relative}:{line_number}:{line}")
                    count += 1
    print(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={count}")
    return count


def check_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    checks = [
        ("ActivityVisualizationPipeline.swift", "PROJECT_GROUP_CONTAINS", "ActivityVisualizationPipeline.swift"),
        ("ActivityVisualizationPipelineTests.swift", "PROJECT_TEST_GROUP_CONTAINS", "ActivityVisualizationPipelineTests.swift"),
    ]
    for label, key, token in checks:
        present = token in project
        print(f"{key}[{label}]={'YES' if present else 'NO'}")
        if present:
            pass_msg(f"project contains {label}")
        else:
            fail(f"project missing {label}")

    source_count = project.count("/* ActivityVisualizationPipeline.swift in Sources */,")
    test_source_count = project.count("/* ActivityVisualizationPipelineTests.swift in Sources */,")
    print(f"PROJECT_SOURCE_PHASE_COUNT[ActivityVisualizationPipeline.swift]={source_count}")
    print(f"PROJECT_TEST_SOURCE_PHASE_COUNT[ActivityVisualizationPipelineTests.swift]={test_source_count}")
    if source_count == 3:
        pass_msg("ActivityVisualizationPipeline.swift has iOS/macOS/watchOS source membership")
    else:
        fail("ActivityVisualizationPipeline.swift expected 3 source memberships")
    if test_source_count == 1:
        pass_msg("ActivityVisualizationPipelineTests.swift has one test source membership")
    else:
        fail("ActivityVisualizationPipelineTests.swift expected 1 test source membership")


required_paths = [
    "Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/ActivityVisualizationDiagnostics.swift",
    "Shared/ActivityVisualization/ActivityVisualizationQuality.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
    "Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift",
    "Tests/ActivityVisualizationTests/RouteDisplayFixtureTests.swift",
    "Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift",
    "Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task031_prep_012_unified_pipeline.py",
]
for path in required_paths:
    require_path(path)

for path in [
    "Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
]:
    check_header_and_line_count(path)

for token in [
    "struct ActivityVisualizationConfiguration",
    "struct ActivityVisualizationResult",
    "struct ActivityVisualizationCompactSummary",
    "ActivityVisualizationPreparedSummary",
    "init(\n        routeQuality: ActivityVisualizationQuality",
    "init(\n        route: RouteDisplayResult,",
    "let compactSummary: ActivityVisualizationCompactSummary",
]:
    require_token("Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift", token)

for token in [
    "struct ActivityVisualizationPipeline",
    "func makeVisualization(",
    "RouteDisplayPipeline(configuration: configuration.route).makeDisplayRoute(",
    "SpeedDisplayPipeline(configuration: configuration.speed).makeDisplaySpeed(",
    "ElevationDisplayPipeline(configuration: configuration.elevation).makeDisplayElevation(",
    "ActivityVisualizationDiagnostics(",
    "ActivityVisualizationResult(",
    "ActivityVisualizationCompactSummary(",
]:
    require_token("Shared/ActivityVisualization/ActivityVisualizationPipeline.swift", token)

for token in [
    "testUnifiedPipelineMatchesFocusedSubPipelineOutputs",
    "testUnifiedPipelineAggregatesDiagnosticsWithoutMutatingSamples",
    "testUnifiedPipelineEmptySamplesProduceUnavailableCompactSummary",
    "ActivityVisualizationPipeline(configuration: configuration).makeVisualization(",
    "XCTAssertEqual(result.route, expectedRoute)",
    "XCTAssertEqual(result.speed, expectedSpeed)",
    "XCTAssertEqual(result.elevation, expectedElevation)",
    "XCTAssertFalse(result.compactSummary.hasAnyDisplayData)",
]:
    require_token("Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift", token)

for token in [
    "import SwiftUI",
    "import MapKit",
    "import UIKit",
    "import AppKit",
    "import WatchKit",
]:
    forbid_token("Shared/ActivityVisualization/ActivityVisualizationPipeline.swift", token)
    forbid_token("Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift", token)
    forbid_token("Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift", token)

for path in [
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "Shared/ActivityVisualization/Route",
    "Shared/ActivityVisualization/Speed",
    "Shared/ActivityVisualization/Elevation",
]:
    expect_clean(path)

for token in [
    "Task-031-prep-ActivityViz-012 Unified ActivityVisualizationPipeline Entry Point",
    "ActivityVisualizationPipeline.makeVisualization",
    "ActivityVisualizationResult",
    "ActivityVisualizationCompactSummary",
    "focused sub-pipelines preserved",
    "no forced platform view migration",
    "no persistence/export/package schema change",
]:
    require_token("docs/history/DEV_LOG.md", token)

for token in [
    "Task-031-prep ActivityViz-012 Unified ActivityVisualizationPipeline Entry Point",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "ActivityVisualizationPipelineTests.swift",
    "verify_task031_prep_012_unified_pipeline.py",
    "ActivityViz-013 remains responsible for the Watch-ready compact adapter contract",
]:
    require_token("docs/reference/FILE_STRUCTURE.md", token)

check_project_membership()

shared_ui_count = grep_shared_ui_imports()
test_ui_count = grep_tests_ui_imports()
display_derived_count = count_display_derived_persistence_tokens()
if shared_ui_count == 0:
    pass_msg("Shared/ActivityVisualization avoids platform UI imports")
else:
    fail("Shared/ActivityVisualization contains forbidden platform UI imports")
if test_ui_count == 0:
    pass_msg("ActivityVisualization tests avoid platform UI imports")
else:
    fail("ActivityVisualization tests contain forbidden platform UI imports")
if display_derived_count == 0:
    pass_msg("displayDerived tokens absent from persistence/export/package paths except allowed display adapters")
else:
    fail("displayDerived tokens found in forbidden persistence/export/package paths")

print("===== Summary =====")
print(f"WARNING_COUNT={WARNINGS}")
print(f"FAILURE_COUNT={FAILURES}")
if FAILURES == 0:
    print("VERIFY_TASK031_PREP_012_UNIFIED_PIPELINE_RESULT=PASSED")
    sys.exit(0)
print("VERIFY_TASK031_PREP_012_UNIFIED_PIPELINE_RESULT=FAILED")
sys.exit(1)
