#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_013_compact_adapter.py
# Purpose: Verifies Task-031-prep ActivityViz-013 Watch-ready compact adapter contract.
# Delegates to: source scope guards, target membership checks, and display-only invariants.

from pathlib import Path
import subprocess
import sys

REPO = Path.cwd()
failures = 0
warnings = 0

print("===== Task-031-prep ActivityViz-013 compact adapter verifier =====")
print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
print("Aligned subtask: task-031-prep-ActivityViz-013 — Watch-ready Compact Adapter Contract")
print(f"REPO={REPO}")


def fail(message: str) -> None:
    global failures
    failures += 1
    print(f"FAIL: {message}")


def warn(message: str) -> None:
    global warnings
    warnings += 1
    print(f"WARN: {message}")


def require_path(path: str) -> Path:
    resolved = REPO / path
    if resolved.exists():
        print(f"PASS: required path exists: {path}")
    else:
        fail(f"required path missing: {path}")
    return resolved


def read(path: str) -> str:
    resolved = require_path(path)
    if not resolved.exists():
        return ""
    return resolved.read_text(encoding="utf-8")


def check_token(text: str, path: str, token: str) -> None:
    if token in text:
        print(f"PASS: {path} contains token: {token}")
    else:
        fail(f"{path} missing token: {token}")


def check_absent(text: str, path: str, token: str) -> None:
    if token in text:
        fail(f"{path} contains forbidden token: {token}")
    else:
        print(f"PASS: {path} does not contain forbidden token: {token}")


def check_header_and_lines(path: str, max_lines: int = 500) -> None:
    resolved = require_path(path)
    if not resolved.exists():
        return
    lines = resolved.read_text(encoding="utf-8").splitlines()
    first_line = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first_line}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]"):
        print(f"PASS: {path} has collaboration/autonomous header")
    else:
        fail(f"{path} missing collaboration/autonomous header")
    if len(lines) <= max_lines:
        print(f"PASS: {path} stays under {max_lines} lines")
    else:
        fail(f"{path} exceeds {max_lines} lines")


def git_status(path: str) -> str:
    result = subprocess.run(
        ["git", "status", "--short", "--", path],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return result.stdout.strip()


def check_clean(path: str) -> None:
    status = git_status(path)
    key = path.upper().replace("/", "_").replace(".", "_").replace("-", "_") + "_STATUS"
    if status:
        print(f"{key}=DIRTY")
        print(status)
        fail(f"untouched guard dirty: {path}")
    else:
        print(f"{key}=CLEAN")
        print(f"PASS: untouched guard clean: {path}")


required_paths = [
    "Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
    "Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift",
    "Tests/ActivityVisualizationTests/CompactActivityVisualizationTests.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task031_prep_013_compact_adapter.py",
]
for path in required_paths:
    require_path(path)

for swift_path in [
    "Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Tests/ActivityVisualizationTests/CompactActivityVisualizationTests.swift",
]:
    check_header_and_lines(swift_path)

configuration = read("Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift")
compact = read("Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift")
tests = read("Tests/ActivityVisualizationTests/CompactActivityVisualizationTests.swift")
pbxproj = read("SkateTrack.xcodeproj/project.pbxproj")
dev_log = read("docs/history/DEV_LOG.md")
file_structure = read("docs/reference/FILE_STRUCTURE.md")

for token in [
    "let compactRoute: CompactRouteDisplay",
    "let speedSparkline: CompactSpeedSparkline",
    "let elevationProfile: CompactElevationProfile",
    "init(\n        routeQuality: ActivityVisualizationQuality",
    "compactRoute: CompactRouteDisplay(route: route)",
    "speedSparkline: CompactSpeedSparkline(speed: speed)",
    "elevationProfile: CompactElevationProfile(elevation: elevation)",
]:
    check_token(configuration, "ActivityVisualizationConfiguration.swift", token)

for token in [
    "struct CompactRoutePoint",
    "struct CompactRouteDisplay",
    "init(\n        points: [CompactRoutePoint] = []",
    "init(route: RouteDisplayResult, maximumPointCount: Int = 48)",
    "struct CompactSparklinePoint",
    "struct CompactSpeedSparkline",
    "init(speed: SpeedDisplayResult, maximumPointCount: Int = 48)",
    "struct CompactElevationProfile",
    "init(elevation: ElevationDisplayResult, maximumPointCount: Int = 48)",
    "private func compactSample<Element>",
    "private func normalizedValue",
    "private func clampedNormalizedValue",
]:
    check_token(compact, "CompactActivityVisualizationModels.swift", token)

for token in [
    "testUnifiedPipelineBuildsCompactRouteSpeedAndElevationPayloads",
    "testCompactRouteDisplayCanBeConstructedWithoutFullRouteDisplayResult",
    "testCompactSparklineAdaptersDownsampleAndNormalizeDisplayValues",
    "testEmptyCompactSummaryDoesNotRequireWatchUIOrRecordingState",
    "ActivityVisualizationPipeline().makeVisualization(",
    "CompactRouteDisplay(\n            points:",
    "CompactSpeedSparkline(speed: speed, maximumPointCount: 5)",
]:
    check_token(tests, "CompactActivityVisualizationTests.swift", token)

for token in ["import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"]:
    check_absent(compact, "CompactActivityVisualizationModels.swift", token)
    check_absent(tests, "CompactActivityVisualizationTests.swift", token)

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
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Tests/ActivityVisualizationTests/ActivityVisualizationPipelineTests.swift",
]:
    check_clean(path)

for token in [
    "CompactActivityVisualizationModels.swift",
    "CompactActivityVisualizationTests.swift",
    "31A600000000000000000000 /* Compact */",
]:
    check_token(pbxproj, "project.pbxproj", token)

source_count = sum(
    1 for line in pbxproj.splitlines()
    if "CompactActivityVisualizationModels.swift in Sources" in line and line.strip().endswith(",")
)
test_source_count = sum(
    1 for line in pbxproj.splitlines()
    if "CompactActivityVisualizationTests.swift in Sources" in line and line.strip().endswith(",")
)
print(f"PROJECT_SOURCE_PHASE_COUNT[CompactActivityVisualizationModels.swift]={source_count}")
print(f"PROJECT_TEST_SOURCE_PHASE_COUNT[CompactActivityVisualizationTests.swift]={test_source_count}")
if source_count == 3:
    print("PASS: CompactActivityVisualizationModels.swift has iOS/macOS/watchOS source membership")
else:
    fail("CompactActivityVisualizationModels.swift must have exactly 3 source memberships")
if test_source_count == 1:
    print("PASS: CompactActivityVisualizationTests.swift has one test source membership")
else:
    fail("CompactActivityVisualizationTests.swift must have exactly 1 test source membership")

for token in [
    "Task-031-prep-ActivityViz-013 Watch-ready Compact Adapter Contract",
    "CompactActivityVisualizationModels.swift",
    "CompactRouteDisplay",
    "CompactSpeedSparkline",
    "CompactElevationProfile",
    "no forced platform view migration",
    "no Watch UI",
    "no persistence/export/package schema change",
]:
    check_token(dev_log, "DEV_LOG.md", token)

for token in [
    "Task-031-prep ActivityViz-013 Watch-ready Compact Adapter Contract",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "CompactActivityVisualizationTests.swift",
    "verify_task031_prep_013_compact_adapter.py",
    "display-only compact summaries",
]:
    check_token(file_structure, "FILE_STRUCTURE.md", token)

shared_ui_result = subprocess.run(
    ["bash", "-lc", "git grep -n 'import SwiftUI\\|import MapKit\\|import UIKit\\|import AppKit\\|import WatchKit' -- Shared/ActivityVisualization || true"],
    cwd=REPO,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
shared_ui_lines = [line for line in shared_ui_result.stdout.splitlines() if line.strip()]
print(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={len(shared_ui_lines)}")
if shared_ui_lines:
    for line in shared_ui_lines:
        print(line)
    fail("Shared/ActivityVisualization contains platform UI imports")
else:
    print("PASS: Shared/ActivityVisualization avoids platform UI imports")

test_ui_result = subprocess.run(
    ["bash", "-lc", "git grep -n 'import SwiftUI\\|import MapKit\\|import UIKit\\|import AppKit\\|import WatchKit' -- Tests/ActivityVisualizationTests || true"],
    cwd=REPO,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
test_ui_lines = [line for line in test_ui_result.stdout.splitlines() if line.strip()]
print(f"TEST_UI_IMPORT_COUNT={len(test_ui_lines)}")
if test_ui_lines:
    for line in test_ui_lines:
        print(line)
    fail("ActivityVisualization tests contain platform UI imports")
else:
    print("PASS: ActivityVisualization tests avoid platform UI imports")

persistence_result = subprocess.run(
    [
        "bash",
        "-lc",
        "git grep -n 'CompactRouteDisplay\\|CompactSpeedSparkline\\|CompactElevationProfile\\|displayDerivedTotalAscentMeters\\|displayDerivedTotalDescentMeters\\|displayDerived' -- Shared/Models iOS/Core macOS/Core Shared/Persistence Shared/Repositories Shared/Packages macOS/Persistence macOS/Repositories 2>/dev/null || true",
    ],
    cwd=REPO,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
persistence_lines = [line for line in persistence_result.stdout.splitlines() if line.strip()]
print(f"COMPACT_OR_DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={len(persistence_lines)}")
if persistence_lines:
    for line in persistence_lines:
        print(line)
    fail("compact/displayDerived tokens found in persistence/export/package paths")
else:
    print("PASS: compact/displayDerived tokens absent from persistence/export/package paths")

print("===== Summary =====")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
if failures == 0:
    print("VERIFY_TASK031_PREP_013_COMPACT_ADAPTER_RESULT=PASSED")
    sys.exit(0)
print("VERIFY_TASK031_PREP_013_COMPACT_ADAPTER_RESULT=FAILED")
sys.exit(1)
