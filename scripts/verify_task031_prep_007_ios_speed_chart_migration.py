#!/usr/bin/env python3
# [工程設定] scripts/verify_task031_prep_007_ios_speed_chart_migration.py
# Purpose: Verify Task-031-prep ActivityViz-007 iOS speed chart migration scope.

from pathlib import Path
import subprocess
import sys

ROOT = Path.cwd()
FAILURES = 0
WARNINGS = 0


def rel(path: str) -> Path:
    return ROOT / path


def log(message: str) -> None:
    print(message)


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


def read(path: str) -> str:
    target = rel(path)
    try:
        return target.read_text(encoding="utf-8")
    except FileNotFoundError:
        fail(f"required path missing before read: {path}")
        return ""
    except Exception as exc:
        fail(f"unable to read {path}: {exc}")
        return ""


def git_status(path: str) -> str:
    try:
        completed = subprocess.run(
            ["git", "status", "--short", "--", path],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except Exception as exc:
        fail(f"git status failed for {path}: {exc}")
        return "ERROR"
    if completed.returncode != 0:
        fail(f"git status returned {completed.returncode} for {path}: {completed.stderr.strip()}")
        return "ERROR"
    return completed.stdout.strip()


def require_path(path: str) -> None:
    if rel(path).exists():
        pass_msg(f"required path exists: {path}")
    else:
        fail(f"required path missing: {path}")


def require_token(text: str, token: str, label: str) -> None:
    if token in text:
        pass_msg(f"{label} contains token: {token}")
    else:
        fail(f"{label} missing token: {token}")


def forbid_token(text: str, token: str, label: str) -> None:
    if token in text:
        fail(f"{label} contains forbidden token: {token}")
    else:
        pass_msg(f"{label} does not contain forbidden token: {token}")


def line_header_check(path: str) -> None:
    target = rel(path)
    if not target.exists():
        fail(f"cannot line/header check missing file: {path}")
        return
    lines = target.read_text(encoding="utf-8").splitlines()
    first_line = lines[0] if lines else ""
    line_count = len(lines)
    log(f"FIRST_LINE[{path}]={first_line}")
    log(f"LINE_COUNT[{path}]={line_count}")
    if first_line.startswith("// [協作區") or first_line.startswith("// [自主區"):
        pass_msg(f"{path} has collaboration header")
    else:
        fail(f"{path} missing collaboration header")
    if line_count <= 500:
        pass_msg(f"{path} stays under 500 lines")
    else:
        fail(f"{path} exceeds 500 lines")


log("===== Task-031-prep ActivityViz-007 iOS speed chart migration verifier =====")
log("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
log("Aligned subtask: task-031-prep-ActivityViz-007 — iOS Speed Chart Migration")
log(f"REPO={ROOT}")

required_paths = [
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
    "iOS/Features/SessionSummary/AdvancedChartsLockedView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayModels.swift",
    "Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]
for path in required_paths:
    require_path(path)

for path in [
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
]:
    line_header_check(path)

speed_view = read("iOS/Features/SessionSummary/SpeedTimelineChartView.swift")
advanced_view = read("iOS/Features/SessionSummary/SessionAdvancedChartsView.swift")
shared_pipeline = read("Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift")
dev_log = read("docs/history/DEV_LOG.md")
file_structure = read("docs/reference/FILE_STRUCTURE.md")

for token in [
    "let result: SpeedDisplayResult",
    "chartPoints(from result: SpeedDisplayResult)",
    "point.speedKilometersPerHour",
    "point.segmentID",
    "ChartCard(",
    "LineMark(",
    ".foregroundStyle(SkateTrackSessionStartColors.teal)",
    ".interpolationMethod(.linear)",
    "ChartEmptyState(",
    "summary-speed-timeline-chart",
    "speed-timeline-chart-view",
]:
    require_token(speed_view, token, "SpeedTimelineChartView.swift")

for token in [
    "private var speedResult: SpeedDisplayResult",
    "SpeedDisplayPipeline(",
    "SpeedDisplayConfiguration(maximumDisplayPointCount: 120)",
    ".makeDisplaySpeed(",
    "samples: content.motionSamples",
    "fidelityPolicy: fidelityPolicy",
    "SpeedTimelineChartView(result: speedResult)",
    "chartPoints(from result: SpeedDisplayResult)",
    "point.speedKilometersPerHour",
    "AdvancedChartsLockedView(speedPoints: speedPoints, elevationPoints: elevationPoints, onUnlock: onUnlock)",
    "ElevationProfileChartView(points: elevationPoints)",
]:
    require_token(advanced_view, token, "SessionAdvancedChartsView.swift")

for token in [
    "private func displaySpeedKilometersPerHour(for sample: MotionSample)",
    "SessionSummaryDisplayMetrics.displaySpeedKilometersPerHour(for: sample",
    "private func smoothedSpeedPoints(_ points: [SessionSummaryChartPoint])",
    "SpeedTimelineChartView(points: speedPoints)",
]:
    forbid_token(advanced_view, token, "SessionAdvancedChartsView.swift")

# Shared speed shell must remain the ActivityViz-006 implementation, not be rewritten by iOS renderer migration.
for token in [
    "struct SpeedDisplayPipeline",
    "func makeDisplaySpeed(",
    "SpeedDisplayPoint(",
    "SpeedDisplayResult(",
    "SpeedDisplaySummary(",
    "SpeedDisplayDiagnostics(",
]:
    require_token(shared_pipeline, token, "SpeedDisplayPipeline.swift")

for token in ["import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"]:
    forbid_token(shared_pipeline, token, "SpeedDisplayPipeline.swift")

status_expectations = {
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift": "CLEAN",
    "Shared/ActivityVisualization/Speed/SpeedDisplayModels.swift": "CLEAN",
    "Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift": "CLEAN",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift": "CLEAN",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift": "CLEAN",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift": "CLEAN",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift": "CLEAN",
    "Shared/ActivityVisualization/Route": "CLEAN",
}
for path in status_expectations:
    status = git_status(path)
    label = path.replace("/", "_").upper()
    if not status:
        log(f"{label}_STATUS=CLEAN")
        pass_msg(f"untouched guard clean: {path}")
    else:
        log(f"{label}_STATUS={status}")
        fail(f"untouched guard dirty: {path}")

for token in [
    "Task-031-prep-ActivityViz-007 iOS Speed Chart Migration",
    "SpeedTimelineChartView",
    "SessionAdvancedChartsView",
    "SpeedDisplayPipeline(configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 120))",
    "SpeedTimelineChartView(result: speedResult)",
    "MacSpeedSparklineView.swift` untouched",
    "no speed metric mutation",
]:
    require_token(dev_log, token, "DEV_LOG")

for token in [
    "Task-031-prep ActivityViz-007 iOS Speed Chart Migration",
    "SpeedTimelineChartView.swift",
    "SessionAdvancedChartsView.swift",
    "verify_task031_prep_007_ios_speed_chart_migration.py",
    "MacSpeedSparklineView.swift",
]:
    require_token(file_structure, token, "FILE_STRUCTURE")

try:
    shared_ui_import_count = int(subprocess.run(
        "grep -RInE '^[[:space:]]*import[[:space:]]+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)' Shared/ActivityVisualization 2>/dev/null | wc -l | tr -d ' '",
        cwd=ROOT,
        shell=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    ).stdout.strip() or "0")
except Exception as exc:
    shared_ui_import_count = -1
    fail(f"Shared UI import grep failed: {exc}")
log(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_import_count}")
if shared_ui_import_count == 0:
    pass_msg("Shared/ActivityVisualization avoids platform UI imports")
else:
    fail("Shared/ActivityVisualization contains platform UI imports")

try:
    test_ui_import_count = int(subprocess.run(
        "grep -RInE '^[[:space:]]*import[[:space:]]+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)' Tests/ActivityVisualizationTests 2>/dev/null | wc -l | tr -d ' '",
        cwd=ROOT,
        shell=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    ).stdout.strip() or "0")
except Exception as exc:
    test_ui_import_count = -1
    fail(f"test UI import grep failed: {exc}")
log(f"TEST_UI_IMPORT_COUNT={test_ui_import_count}")
if test_ui_import_count == 0:
    pass_msg("ActivityVisualization tests avoid platform UI imports")
else:
    fail("ActivityVisualization tests contain platform UI imports")

try:
    display_derived_count = int(subprocess.run(
        "grep -RInE 'displayDerived|displayDerivedTotalAscentMeters' Shared/Models Shared/Persistence Shared/Export iOS/Core/Export iOS/Core/Import 2>/dev/null | wc -l | tr -d ' '",
        cwd=ROOT,
        shell=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    ).stdout.strip() or "0")
except Exception as exc:
    display_derived_count = -1
    fail(f"displayDerived grep failed: {exc}")
log(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={display_derived_count}")
if display_derived_count == 0:
    pass_msg("displayDerived tokens absent from persistence/export/package paths")
else:
    fail("displayDerived tokens found in persistence/export/package paths")

log("===== Summary =====")
log(f"WARNING_COUNT={WARNINGS}")
log(f"FAILURE_COUNT={FAILURES}")
if FAILURES == 0:
    log("VERIFY_TASK031_PREP_007_IOS_SPEED_CHART_MIGRATION_RESULT=PASSED")
    sys.exit(0)
log("VERIFY_TASK031_PREP_007_IOS_SPEED_CHART_MIGRATION_RESULT=FAILED")
sys.exit(1)
