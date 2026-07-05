#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_011_macos_elevation_migration.py
# Purpose: Verify ActivityViz-011 macOS elevation profile migration to Shared ElevationDisplayPipeline.

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAC_ELEVATION_PIPELINE = REPO / "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift"
MAC_VIEWER_MODEL = REPO / "macOS/Features/SessionBrowser/MacSessionViewerModel.swift"
MAC_DETAIL = REPO / "macOS/Features/SessionBrowser/MacSessionDetailView.swift"
MAC_SPEED_SPARKLINE = REPO / "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift"
MAC_ROUTE = REPO / "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift"
IOS_ADVANCED = REPO / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift"
IOS_ELEVATION_CHART = REPO / "iOS/Features/SessionSummary/ElevationProfileChartView.swift"
IOS_SPEED_CHART = REPO / "iOS/Features/SessionSummary/SpeedTimelineChartView.swift"
IOS_ROUTE = REPO / "iOS/Features/SessionSummary/SessionRouteMapView.swift"
SHARED_ELEVATION_PIPELINE = REPO / "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift"
SHARED_ELEVATION_MODELS = REPO / "Shared/ActivityVisualization/Elevation/ElevationDisplayModels.swift"
SHARED_ELEVATION_TESTS = REPO / "Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift"
SHARED_SPEED_DIR = REPO / "Shared/ActivityVisualization/Speed"
SHARED_ROUTE_DIR = REPO / "Shared/ActivityVisualization/Route"
PBXPROJ = REPO / "SkateTrack.xcodeproj/project.pbxproj"
DEV_LOG = REPO / "docs/history/DEV_LOG.md"
FILE_STRUCTURE = REPO / "docs/reference/FILE_STRUCTURE.md"
VERIFIER = REPO / "scripts/verify_task031_prep_011_macos_elevation_migration.py"

FAILURES: list[str] = []
WARNINGS: list[str] = []


def emit(message: str) -> None:
    print(message)


def fail(message: str) -> None:
    FAILURES.append(message)
    emit(f"FAIL: {message}")


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
    except Exception as exc:  # noqa: BLE001 - verifier must fail gracefully.
        fail(f"cannot read {rel(path)}: {type(exc).__name__}: {exc}")
    return ""


def require_path(path: Path) -> None:
    if path.exists():
        ok(f"required path exists: {rel(path)}")
    else:
        fail(f"missing required path: {rel(path)}")


def require_header_and_line_limit(path: Path, limit: int = 500) -> None:
    lines = read_text(path).splitlines()
    first = lines[0] if lines else ""
    count = len(lines)
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


def verify_required_files() -> None:
    for path in [
        MAC_ELEVATION_PIPELINE,
        MAC_VIEWER_MODEL,
        MAC_DETAIL,
        MAC_SPEED_SPARKLINE,
        MAC_ROUTE,
        IOS_ADVANCED,
        IOS_ELEVATION_CHART,
        IOS_SPEED_CHART,
        IOS_ROUTE,
        SHARED_ELEVATION_PIPELINE,
        SHARED_ELEVATION_MODELS,
        SHARED_ELEVATION_TESTS,
        SHARED_SPEED_DIR,
        SHARED_ROUTE_DIR,
        PBXPROJ,
        DEV_LOG,
        FILE_STRUCTURE,
        VERIFIER,
    ]:
        require_path(path)


def verify_source_shape() -> None:
    for path in [
        MAC_ELEVATION_PIPELINE,
        MAC_VIEWER_MODEL,
        MAC_DETAIL,
        MAC_SPEED_SPARKLINE,
        SHARED_ELEVATION_PIPELINE,
        SHARED_ELEVATION_MODELS,
        SHARED_ELEVATION_TESTS,
    ]:
        require_header_and_line_limit(path)

    for token in [
        "static func elevationResult(session: SessionData, samples: [MotionSample]) -> ElevationDisplayResult",
        "ElevationDisplayPipeline(",
        "ElevationDisplayConfiguration(maximumDisplayPointCount: 180)",
        ").makeDisplayElevation(",
        "samples: samples",
        "startDate: session.startDate",
        "fidelityPolicy: policy",
        "static func elevationPoints(from result: ElevationDisplayResult) -> [MacElevationPoint]",
        "point.elevationMeters",
        "point.segmentID",
        "displayDerivedTotalAscentMeters(",
        "result.summary.displayDerivedTotalAscentMeters",
    ]:
        require_token(MAC_ELEVATION_PIPELINE, token)

    for forbidden in [
        "private enum ElevationDisplaySource",
        "private struct AbsoluteElevationDisplayAnchor",
        "preferredElevationDisplaySource(for",
        "absoluteElevationDisplayAnchor(for",
        "displayElevationMeters(for",
        "trustedBarometerRelativeAltitude(for",
        "trustedCoreLocationAbsoluteAltitude(for",
        "trustedDebugAltitude(for",
        "robustMedianOffset(from",
        "smoothedElevationPoints(_",
        "shouldStartNewSegment(after",
        "downsample(elevationPoints:",
        "windowRadius",
        "maximumSmoothingStepMeters",
    ]:
        require_absent(MAC_ELEVATION_PIPELINE, forbidden)

    for token in [
        "let elevationResult: ElevationDisplayResult",
        "let elevationPoints: [MacElevationPoint]",
        "let displayElevationGainMeters: Double",
        "let elevationResult = MacSessionViewerModel.elevationDisplayResult(session: session, samples: samples)",
        "self.elevationResult = elevationResult",
        "elevationPoints = MacElevationDisplayPipeline.elevationPoints(from: elevationResult)",
        "displayElevationGainMeters = MacElevationDisplayPipeline.displayDerivedTotalAscentMeters(",
        "fallback: displayMetrics.elevationGainMeters",
        "private static func elevationDisplayResult(session: SessionData, samples: [MotionSample]) -> ElevationDisplayResult",
        "SpeedDisplayPipeline(",
        "SpeedDisplayConfiguration(maximumDisplayPointCount: 180)",
    ]:
        require_token(MAC_VIEWER_MODEL, token)

    for token in [
        "MacElevationProfileView(points: model.elevationPoints)",
        "MacSpeedSparklineView(result: model.speedResult)",
        "formattedElevation(model.displayElevationGainMeters)",
        "summary.metric.elevationGain",
    ]:
        require_token(MAC_DETAIL, token)

    for token in [
        "struct MacElevationProfileView: View",
        "let points: [MacElevationPoint]",
        "Path",
        "elevationPath(points:",
        ".stroke(.orange",
        "mac.viewer.chart.elevation.empty",
        "mac-elevation-chart",
    ]:
        require_token(MAC_SPEED_SPARKLINE, token)

    for token in [
        "struct ElevationDisplayPipeline",
        "func makeDisplayElevation(",
        "ElevationDisplayResult(",
        "ElevationDisplaySummary(",
        "displayDerivedTotalAscentMeters(from:",
        "altitudeMicroDipDisplayGuardedPoints",
        "smoothedElevationPoints",
        "shouldStartNewElevationSegment",
        "switch selectedSource",
    ]:
        require_token(SHARED_ELEVATION_PIPELINE, token)


def verify_boundaries() -> None:
    for relative in [
        "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
        "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
        "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
        "Shared/ActivityVisualization/Elevation/ElevationDisplayModels.swift",
        "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
        "Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift",
        "Shared/ActivityVisualization/Speed",
        "Shared/ActivityVisualization/Route",
        "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
        "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
        "SkateTrack.xcodeproj/project.pbxproj",
    ]:
        require_clean(relative)

    shared_ui_imports = grep_count(REPO / "Shared/ActivityVisualization", r"import (SwiftUI|MapKit|UIKit|AppKit|WatchKit)")
    test_ui_imports = grep_count(REPO / "Tests/ActivityVisualizationTests", r"import (SwiftUI|MapKit|UIKit|AppKit|WatchKit)")
    display_derived_persistence_export = token_count(
        [
            REPO / "Shared/Models",
            REPO / "iOS/Core",
            REPO / "Shared/Persistence",
            REPO / "Shared/Repositories",
        ],
        ("displayDerivedTotalAscentMeters", "displayDerivedTotalDescentMeters", "displayDerived"),
    )

    emit(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_imports}")
    emit(f"TEST_UI_IMPORT_COUNT={test_ui_imports}")
    emit(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={display_derived_persistence_export}")

    if shared_ui_imports == 0:
        ok("Shared/ActivityVisualization avoids platform UI imports")
    else:
        fail("Shared/ActivityVisualization contains platform UI imports")
    if test_ui_imports == 0:
        ok("ActivityVisualization tests avoid platform UI imports")
    else:
        fail("ActivityVisualization tests contain platform UI imports")
    if display_derived_persistence_export == 0:
        ok("displayDerived tokens absent from persistence/export/package paths except macOS display adapter")
    else:
        fail("displayDerived tokens leaked into persistence/export/package paths")


def verify_docs() -> None:
    for token in [
        "Task-031-prep-ActivityViz-011 macOS Elevation Profile Migration",
        "MacElevationDisplayPipeline.swift",
        "ElevationDisplayPipeline(configuration: ElevationDisplayConfiguration(maximumDisplayPointCount: 180))",
        "displayElevationGainMeters",
        "MacElevationProfileView",
        "SessionAdvancedChartsView.swift` untouched",
        "no persistence/export/package schema change",
        "no elevation metric mutation",
    ]:
        require_token(DEV_LOG, token, "docs/history/DEV_LOG.md")

    for token in [
        "Task-031-prep ActivityViz-011 macOS Elevation Profile Migration",
        "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
        "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
        "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
        "MacElevationProfileView remains the SwiftUI Path renderer",
        "verify_task031_prep_011_macos_elevation_migration.py",
        "Shared owns display data preparation only",
    ]:
        require_token(FILE_STRUCTURE, token, "docs/reference/FILE_STRUCTURE.md")


def main() -> int:
    emit("===== Task-031-prep ActivityViz-011 macOS elevation migration verifier =====")
    emit("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    emit("Aligned subtask: task-031-prep-ActivityViz-011 — macOS Elevation Profile Migration")
    emit(f"REPO={REPO}")
    verify_required_files()
    verify_source_shape()
    verify_boundaries()
    verify_docs()
    emit("===== Summary =====")
    emit(f"WARNING_COUNT={len(WARNINGS)}")
    emit(f"FAILURE_COUNT={len(FAILURES)}")
    if FAILURES:
        emit("VERIFY_TASK031_PREP_011_MACOS_ELEVATION_MIGRATION_RESULT=FAILED")
        return 1
    emit("VERIFY_TASK031_PREP_011_MACOS_ELEVATION_MIGRATION_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
