#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_008_macos_speed_chart_migration.py
# Purpose: Verify ActivityViz-008 macOS speed chart migration to Shared SpeedDisplayPipeline.

from __future__ import annotations

import subprocess
from pathlib import Path

REPO = Path.cwd()
FAILURES: list[str] = []
WARNINGS: list[str] = []


def log(message: str) -> None:
    print(message)


def fail(message: str) -> None:
    FAILURES.append(message)
    log(f"FAIL: {message}")


def warn(message: str) -> None:
    WARNINGS.append(message)
    log(f"WARNING: {message}")


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:  # no raw traceback in verifier output
        fail(f"unable to read {path}: {exc}")
        return ""


def require_path(relative: str) -> Path:
    path = REPO / relative
    if path.exists():
        log(f"PASS: required path exists: {relative}")
    else:
        fail(f"required path missing: {relative}")
    return path


def require_header_and_line_limit(relative: str, limit: int = 500) -> None:
    path = REPO / relative
    text = read_text(path)
    first_line = text.splitlines()[0] if text.splitlines() else ""
    line_count = len(text.splitlines())
    log(f"FIRST_LINE[{relative}]={first_line}")
    log(f"LINE_COUNT[{relative}]={line_count}")

    if first_line.startswith("// [協作區") or first_line.startswith("// [自主區"):
        log(f"PASS: {relative} has collaboration header")
    else:
        fail(f"{relative} missing collaboration header")

    if line_count <= limit:
        log(f"PASS: {relative} stays under {limit} lines")
    else:
        fail(f"{relative} exceeds {limit} lines")


def require_contains(relative: str, token: str) -> None:
    text = read_text(REPO / relative)
    if token in text:
        log(f"PASS: {relative} contains token: {token}")
    else:
        fail(f"{relative} missing token: {token}")


def require_absent(relative: str, token: str) -> None:
    text = read_text(REPO / relative)
    if token in text:
        fail(f"{relative} contains forbidden token: {token}")
    else:
        log(f"PASS: {relative} does not contain forbidden token: {token}")


def git_status(relative: str) -> str:
    result = subprocess.run(
        ["git", "status", "--short", "--", relative],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return result.stdout.strip()


def require_clean(relative: str) -> None:
    status = git_status(relative)
    key = relative.upper().replace("/", "_").replace(".", "_").replace("-", "_")
    if not status:
        log(f"{key}_STATUS=CLEAN")
        log(f"PASS: untouched guard clean: {relative}")
    else:
        log(f"{key}_STATUS={status}")
        fail(f"untouched guard changed: {relative}")


def count_grep(paths: list[str], forbidden: tuple[str, ...]) -> int:
    count = 0
    for relative in paths:
        path = REPO / relative
        if not path.exists():
            continue
        files = [path] if path.is_file() else [p for p in path.rglob("*") if p.is_file()]
        for file_path in files:
            try:
                text = file_path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            for line in text.splitlines():
                stripped = line.strip()
                if any(stripped.startswith(f"import {module}") for module in forbidden):
                    count += 1
    return count


def count_tokens(paths: list[str], tokens: tuple[str, ...]) -> int:
    count = 0
    for relative in paths:
        path = REPO / relative
        if not path.exists():
            continue
        files = [path] if path.is_file() else [p for p in path.rglob("*") if p.is_file()]
        for file_path in files:
            try:
                text = file_path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            for token in tokens:
                count += text.count(token)
    return count


def main() -> int:
    log("===== Task-031-prep ActivityViz-008 macOS speed chart migration verifier =====")
    log("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    log("Aligned subtask: task-031-prep-ActivityViz-008 — macOS Speed Chart Migration")
    log(f"REPO={REPO}")

    required_paths = [
        "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
        "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
        "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
        "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
        "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
        "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
        "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
        "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
        "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
        "Shared/ActivityVisualization/Speed/SpeedDisplayModels.swift",
        "Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift",
        "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "SkateTrack.xcodeproj/project.pbxproj",
    ]
    for relative in required_paths:
        require_path(relative)

    for relative in [
        "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
        "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
        "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    ]:
        require_header_and_line_limit(relative)

    speed_view = "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift"
    viewer_model = "macOS/Features/SessionBrowser/MacSessionViewerModel.swift"
    detail_view = "macOS/Features/SessionBrowser/MacSessionDetailView.swift"

    for token in [
        "let result: SpeedDisplayResult",
        "sparklinePoints(from result: SpeedDisplayResult)",
        "point.speedKilometersPerHour",
        "point.segmentID",
        "MacSpeedSparklinePoint",
        "MacSpeedSparklineSegment",
        "speedPath(points segmentPoints: [MacSpeedSparklinePoint], in size: CGSize)",
        ".stroke(.cyan",
        "gridLines(in: geometry.size)",
        "Text(\"mac.viewer.sparkline.empty\")",
        ".accessibilityIdentifier(\"mac-speed-chart\")",
    ]:
        require_contains(speed_view, token)

    for token in [
        "let speedResult: SpeedDisplayResult",
        "speedResult = MacSessionViewerModel.speedDisplayResult(session: session, samples: samples)",
        "private static func speedDisplayResult(session: SessionData, samples: [MotionSample]) -> SpeedDisplayResult",
        "SpeedDisplayPipeline(",
        "SpeedDisplayConfiguration(maximumDisplayPointCount: 180)",
        ".makeDisplaySpeed(",
        "samples: samples",
        "startDate: session.startDate",
        "fidelityPolicy: policy",
    ]:
        require_contains(viewer_model, token)

    for token in [
        "MacSpeedSparklineView(result: model.speedResult)",
        "MacElevationProfileView(points: model.elevationPoints)",
    ]:
        require_contains(detail_view, token)

    for token in [
        "MacSpeedSparklineView(points: model.speedPoints)",
        "speedPoints = MacSessionMetricsDeriver.speedPoints(from: samples)",
        "let speedPoints: [MacSpeedPoint]",
    ]:
        require_absent(viewer_model, token)
        require_absent(detail_view, token)

    # Ensure Shared speed pipeline is still present but not modified by ActivityViz-008.
    for token in [
        "struct SpeedDisplayPipeline",
        "func makeDisplaySpeed(",
        "SpeedDisplayPoint(",
        "SpeedDisplayResult(",
        "SpeedDisplaySummary(",
        "SpeedDisplayDiagnostics(",
    ]:
        require_contains("Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift", token)

    for token in [
        "import SwiftUI",
        "import MapKit",
        "import UIKit",
        "import AppKit",
        "import WatchKit",
    ]:
        require_absent("Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift", token)

    for relative in [
        "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
        "Shared/ActivityVisualization/Speed/SpeedDisplayModels.swift",
        "Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift",
        "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
        "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
        "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
        "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
        "Shared/ActivityVisualization/Route",
    ]:
        require_clean(relative)

    for token in [
        "Task-031-prep-ActivityViz-008 macOS Speed Chart Migration",
        "MacSpeedSparklineView",
        "MacSessionViewerModel",
        "MacSessionDetailView",
        "SpeedDisplayPipeline(configuration: SpeedDisplayConfiguration(maximumDisplayPointCount: 180))",
        "MacSpeedSparklineView(result: model.speedResult)",
        "SpeedTimelineChartView.swift` untouched",
        "no speed metric mutation",
    ]:
        require_contains("docs/history/DEV_LOG.md", token)

    for token in [
        "Task-031-prep ActivityViz-008 macOS Speed Chart Migration",
        "MacSpeedSparklineView.swift",
        "MacSessionViewerModel.swift",
        "MacSessionDetailView.swift",
        "verify_task031_prep_008_macos_speed_chart_migration.py",
    ]:
        require_contains("docs/reference/FILE_STRUCTURE.md", token)

    shared_ui_count = count_grep(["Shared/ActivityVisualization"], ("SwiftUI", "MapKit", "UIKit", "AppKit", "WatchKit"))
    test_ui_count = count_grep(["Tests/ActivityVisualizationTests"], ("SwiftUI", "MapKit", "UIKit", "AppKit", "WatchKit"))
    display_derived_count = count_tokens(
        ["Shared/Models", "Shared/Persistence", "Shared/Export", "iOS/Core/Export", "iOS/Core/Import"],
        ("displayDerived", "displayDerivedTotalAscentMeters"),
    )
    log(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_count}")
    log(f"TEST_UI_IMPORT_COUNT={test_ui_count}")
    log(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={display_derived_count}")

    if shared_ui_count == 0:
        log("PASS: Shared/ActivityVisualization avoids platform UI imports")
    else:
        fail("Shared/ActivityVisualization contains platform UI imports")
    if test_ui_count == 0:
        log("PASS: ActivityVisualization tests avoid platform UI imports")
    else:
        fail("ActivityVisualization tests contain platform UI imports")
    if display_derived_count == 0:
        log("PASS: displayDerived tokens absent from persistence/export/package paths")
    else:
        fail("displayDerived tokens found in persistence/export/package paths")

    log("===== Summary =====")
    log(f"WARNING_COUNT={len(WARNINGS)}")
    log(f"FAILURE_COUNT={len(FAILURES)}")
    if FAILURES:
        log("VERIFY_TASK031_PREP_008_MACOS_SPEED_CHART_MIGRATION_RESULT=FAILED")
        return 1
    log("VERIFY_TASK031_PREP_008_MACOS_SPEED_CHART_MIGRATION_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
