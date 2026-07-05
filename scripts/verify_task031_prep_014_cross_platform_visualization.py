#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_014_cross_platform_visualization.py
# Purpose: Cross-platform verifier for Task-031-prep ActivityViz route/speed/elevation visualization invariants.
# Scope: static source, membership, ownership, and persistence/export safety checks only.

from pathlib import Path
import re
import subprocess
import sys

REPO = Path.cwd()
failures = 0
warnings = 0

print("===== Task-031-prep ActivityViz-014 cross-platform visualization verifier =====")
print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
print("Aligned subtask: task-031-prep-ActivityViz-014 — Cross-platform Visualization Verifier")
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


def check_token(text: str, label: str, token: str) -> None:
    if token in text:
        print(f"PASS: {label} contains token: {token}")
    else:
        fail(f"{label} missing token: {token}")


def check_absent(text: str, label: str, token: str) -> None:
    if token in text:
        fail(f"{label} contains forbidden token: {token}")
    else:
        print(f"PASS: {label} does not contain forbidden token: {token}")


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


def check_script_header_and_lines(path: str, max_lines: int = 500) -> None:
    resolved = require_path(path)
    if not resolved.exists():
        return
    lines = resolved.read_text(encoding="utf-8").splitlines()
    first_line = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first_line}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if any(line.startswith("# [協作區]") or line.startswith("# [自主區]") for line in lines[:3]):
        print(f"PASS: {path} has collaboration/autonomous script header")
    else:
        fail(f"{path} missing collaboration/autonomous script header")
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


def source_phase_count(pbxproj: str, filename: str) -> int:
    marker = f"/* {filename} in Sources */"
    return sum(1 for line in pbxproj.splitlines() if marker in line and line.strip().endswith(","))


def git_grep(pattern: str, paths: list[str]) -> list[str]:
    cmd = ["git", "grep", "-n", pattern, "--", *paths]
    result = subprocess.run(cmd, cwd=REPO, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False)
    return [line for line in result.stdout.splitlines() if line.strip()]


required_paths = [
    "Shared/ActivityVisualization",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Tests/ActivityVisualizationTests",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "watchOS",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task031_prep_003_route_pipeline.py",
    "scripts/verify_task031_prep_004_ios_route_migration.py",
    "scripts/verify_task031_prep_010_ios_elevation_migration.py",
    "scripts/verify_task031_prep_011_macos_elevation_migration.py",
    "scripts/verify_task031_prep_012_unified_pipeline.py",
    "scripts/verify_task031_prep_013_compact_adapter.py",
    "scripts/verify_task031_prep_014_cross_platform_visualization.py",
]
for path in required_paths:
    require_path(path)

shared_swift_files = sorted((REPO / "Shared/ActivityVisualization").rglob("*.swift"))
test_swift_files = sorted((REPO / "Tests/ActivityVisualizationTests").rglob("*.swift"))
print(f"SHARED_ACTIVITYVIZ_SWIFT_FILE_COUNT={len(shared_swift_files)}")
print(f"ACTIVITYVIZ_TEST_SWIFT_FILE_COUNT={len(test_swift_files)}")
if len(shared_swift_files) < 15:
    fail("expected at least 15 Shared/ActivityVisualization Swift files after ActivityViz-013")
if len(test_swift_files) < 5:
    fail("expected at least 5 ActivityVisualization test Swift files after ActivityViz-013")

for path in shared_swift_files:
    check_header_and_lines(str(path.relative_to(REPO)))
for path in test_swift_files:
    check_header_and_lines(str(path.relative_to(REPO)))
check_script_header_and_lines("scripts/verify_task031_prep_014_cross_platform_visualization.py")

configuration = read("Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift")
pipeline = read("Shared/ActivityVisualization/ActivityVisualizationPipeline.swift")
compact = read("Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift")
route = read("Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift")
speed = read("Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift")
elevation = read("Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift")
pbxproj = read("SkateTrack.xcodeproj/project.pbxproj")
dev_log = read("docs/history/DEV_LOG.md")
file_structure = read("docs/reference/FILE_STRUCTURE.md")

for token in [
    "struct ActivityVisualizationConfiguration",
    "struct ActivityVisualizationResult",
    "struct ActivityVisualizationCompactSummary",
    "CompactRouteDisplay(route: route)",
    "CompactSpeedSparkline(speed: speed)",
    "CompactElevationProfile(elevation: elevation)",
]:
    check_token(configuration, "ActivityVisualizationConfiguration.swift", token)

for token in [
    "struct ActivityVisualizationPipeline",
    "func makeVisualization(",
    "RouteDisplayPipeline(configuration: configuration.route).makeDisplayRoute(",
    "SpeedDisplayPipeline(configuration: configuration.speed).makeDisplaySpeed(",
    "ElevationDisplayPipeline(configuration: configuration.elevation).makeDisplayElevation(",
]:
    check_token(pipeline, "ActivityVisualizationPipeline.swift", token)

for token in [
    "struct RouteDisplayPipeline",
    "func makeDisplayRoute(",
    "RouteDisplayResult(",
    "ActivityRouteDisplayPoint(",
]:
    check_token(route, "RouteDisplayPipeline.swift", token)
for token in ["struct SpeedDisplayPipeline", "func makeDisplaySpeed(", "SpeedDisplayResult(", "SpeedDisplayPoint("]:
    check_token(speed, "SpeedDisplayPipeline.swift", token)
for token in ["struct ElevationDisplayPipeline", "func makeDisplayElevation(", "switch selectedSource", "ElevationDisplayResult("]:
    check_token(elevation, "ElevationDisplayPipeline.swift", token)
for token in [
    "struct CompactRouteDisplay",
    "struct CompactSpeedSparkline",
    "struct CompactElevationProfile",
    "init(route: RouteDisplayResult, maximumPointCount: Int = 48)",
    "init(speed: SpeedDisplayResult, maximumPointCount: Int = 48)",
    "init(elevation: ElevationDisplayResult, maximumPointCount: Int = 48)",
]:
    check_token(compact, "CompactActivityVisualizationModels.swift", token)

for token in ["import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"]:
    for path in ["Shared/ActivityVisualization", "Tests/ActivityVisualizationTests"]:
        lines = git_grep(token, [path])
        print(f"FORBIDDEN_UI_IMPORT_COUNT[{path}][{token}]={len(lines)}")
        if lines:
            for line in lines:
                print(line)
            fail(f"{path} contains forbidden UI import token: {token}")
        else:
            print(f"PASS: {path} avoids forbidden token: {token}")

for path in [
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "watchOS",
    "Shared/ActivityVisualization",
    "Tests/ActivityVisualizationTests",
    "SkateTrack.xcodeproj/project.pbxproj",
]:
    check_clean(path)

for path in shared_swift_files:
    filename = path.name
    count = source_phase_count(pbxproj, filename)
    print(f"PROJECT_SOURCE_PHASE_COUNT[{filename}]={count}")
    if count == 3:
        print(f"PASS: {filename} has iOS/macOS/watchOS source membership")
    else:
        fail(f"{filename} must have exactly 3 iOS/macOS/watchOS source memberships")

for path in test_swift_files:
    filename = path.name
    count = source_phase_count(pbxproj, filename)
    print(f"PROJECT_TEST_SOURCE_PHASE_COUNT[{filename}]={count}")
    if count == 1:
        print(f"PASS: {filename} has one ActivityVisualization test source membership")
    else:
        fail(f"{filename} must have exactly 1 ActivityVisualization test source membership")

for token in [
    "RouteDisplayPipeline.swift",
    "SpeedDisplayPipeline.swift",
    "ElevationDisplayPipeline.swift",
    "ActivityVisualizationPipeline.swift",
    "CompactActivityVisualizationModels.swift",
    "ActivityVisualizationPipelineTests.swift",
    "CompactActivityVisualizationTests.swift",
    "verify_task031_prep_014_cross_platform_visualization.py",
]:
    check_token(pbxproj + file_structure + dev_log, "project/docs aggregate", token)

persistence_lines = git_grep(
    "CompactRouteDisplay\\|CompactSpeedSparkline\\|CompactElevationProfile\\|displayDerivedTotalAscentMeters\\|displayDerivedTotalDescentMeters\\|displayDerived",
    [
        "Shared/Models",
        "iOS/Core",
        "macOS/Core",
        "Shared/Persistence",
        "Shared/Repositories",
        "Shared/Packages",
        "macOS/Persistence",
        "macOS/Repositories",
    ],
)
print(f"COMPACT_OR_DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={len(persistence_lines)}")
if persistence_lines:
    for line in persistence_lines:
        print(line)
    fail("compact/displayDerived tokens found in persistence/export/package paths")
else:
    print("PASS: compact/displayDerived tokens absent from persistence/export/package paths")

watch_lines = git_grep("WatchKit\\|Recording\\|startWorkout\\|HKWorkoutSession\\|CompactRouteDisplay", ["watchOS"])
print(f"WATCH_UI_RECORDING_COMPACT_USAGE_COUNT={len(watch_lines)}")
if watch_lines:
    for line in watch_lines:
        print(line)
    fail("ActivityViz-014 should not introduce Watch UI/recording/compact consumption")
else:
    print("PASS: watchOS has no Watch UI/recording/compact consumption changes for ActivityViz-014")

for token in [
    "Task-031-prep-ActivityViz-014 Cross-platform Visualization Verifier",
    "verify_task031_prep_014_cross_platform_visualization.py",
    "Shared ActivityVisualization source membership",
    "compact/displayDerived persistence/export/package guard",
    "no Watch UI",
    "no Watch recording",
    "no persistence/export/package schema change",
]:
    check_token(dev_log, "DEV_LOG.md", token)

for token in [
    "Task-031-prep ActivityViz-014 Cross-platform Visualization Verifier",
    "scripts/verify_task031_prep_014_cross_platform_visualization.py",
    "Cross-platform verifier",
    "ActivityViz-015 remains responsible for docs/ADR final sync",
]:
    check_token(file_structure, "FILE_STRUCTURE.md", token)

check_absent(dev_log, "DEV_LOG.md", "ActivityViz-014 implemented Watch UI")
check_absent(file_structure, "FILE_STRUCTURE.md", "ActivityViz-014 implemented Watch UI")

print("===== Summary =====")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
if failures == 0:
    print("VERIFY_TASK031_PREP_014_CROSS_PLATFORM_VISUALIZATION_RESULT=PASSED")
    sys.exit(0)
print("VERIFY_TASK031_PREP_014_CROSS_PLATFORM_VISUALIZATION_RESULT=FAILED")
sys.exit(1)
