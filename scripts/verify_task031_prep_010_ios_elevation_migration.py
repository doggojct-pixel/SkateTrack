#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_010_ios_elevation_migration.py
# Purpose: Verify ActivityViz-010 iOS elevation profile migration to Shared ElevationDisplayPipeline.

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SESSION_ADVANCED = REPO / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift"
ELEVATION_CHART = REPO / "iOS/Features/SessionSummary/ElevationProfileChartView.swift"
SPEED_CHART = REPO / "iOS/Features/SessionSummary/SpeedTimelineChartView.swift"
SESSION_ROUTE = REPO / "iOS/Features/SessionSummary/SessionRouteMapView.swift"
SHARED_ELEVATION_DIR = REPO / "Shared/ActivityVisualization/Elevation"
ELEVATION_PIPELINE = SHARED_ELEVATION_DIR / "ElevationDisplayPipeline.swift"
ELEVATION_MODELS = SHARED_ELEVATION_DIR / "ElevationDisplayModels.swift"
ELEVATION_TESTS = REPO / "Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift"
SHARED_SPEED_DIR = REPO / "Shared/ActivityVisualization/Speed"
SHARED_ROUTE_DIR = REPO / "Shared/ActivityVisualization/Route"
MAC_ELEVATION = REPO / "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift"
MAC_SPEED = REPO / "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift"
MAC_ROUTE = REPO / "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift"
MAC_VIEWER_MODEL = REPO / "macOS/Features/SessionBrowser/MacSessionViewerModel.swift"
MAC_DETAIL = REPO / "macOS/Features/SessionBrowser/MacSessionDetailView.swift"
DEV_LOG = REPO / "docs/history/DEV_LOG.md"
FILE_STRUCTURE = REPO / "docs/reference/FILE_STRUCTURE.md"
PBXPROJ = REPO / "SkateTrack.xcodeproj/project.pbxproj"
VERIFIER = REPO / "scripts/verify_task031_prep_010_ios_elevation_migration.py"

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


def verify_required_files() -> None:
    for path in [
        SESSION_ADVANCED,
        ELEVATION_CHART,
        SPEED_CHART,
        SESSION_ROUTE,
        ELEVATION_PIPELINE,
        ELEVATION_MODELS,
        ELEVATION_TESTS,
        SHARED_SPEED_DIR,
        SHARED_ROUTE_DIR,
        MAC_ELEVATION,
        MAC_SPEED,
        MAC_ROUTE,
        MAC_VIEWER_MODEL,
        MAC_DETAIL,
        PBXPROJ,
        DEV_LOG,
        FILE_STRUCTURE,
        VERIFIER,
    ]:
        require_path(path)


def verify_source_shape() -> None:
    for path in [SESSION_ADVANCED, ELEVATION_CHART, ELEVATION_PIPELINE, ELEVATION_MODELS, ELEVATION_TESTS]:
        require_header_and_line_limit(path)

    for token in [
        "private var elevationResult: ElevationDisplayResult",
        "ElevationDisplayPipeline(",
        "ElevationDisplayConfiguration(maximumDisplayPointCount: 120)",
        ").makeDisplayElevation(",
        "samples: content.motionSamples",
        "fidelityPolicy: fidelityPolicy",
        "private var elevationPoints: [SessionSummaryChartPoint]",
        "chartPoints(from: elevationResult)",
        "private func chartPoints(from result: ElevationDisplayResult)",
        "value: point.elevationMeters",
        "segmentID: point.segmentID",
        "ElevationProfileChartView(points: elevationPoints)",
        "SpeedTimelineChartView(result: speedResult)",
        "SpeedDisplayPipeline(",
        "SpeedDisplayConfiguration(maximumDisplayPointCount: 120)",
    ]:
        require_token(SESSION_ADVANCED, token)

    for forbidden in [
        "private enum ElevationDisplaySource",
        "preferredElevationDisplaySource(for",
        "AbsoluteElevationDisplayAnchor",
        "absoluteElevationDisplayAnchor(for",
        "robustAbsoluteElevationOffsetMeters",
        "fallbackAbsoluteElevationOffsetMeters",
        "displayElevationMeters(",
        "trustedBarometerRelativeAltitude(for",
        "trustedCoreLocationAbsoluteAltitude(for",
        "trustedDebugAltitude(for",
        "altitudeMicroDipDisplayGuardedPoints(",
        "smoothedElevationPoints(_ points: [SessionSummaryChartPoint])",
        "private func smooth(",
        "shouldStartNewChartSegment(after",
        "private func downsample(_ points: [SessionSummaryChartPoint]",
        "windowRadius: 5",
        "maximumStepValue: 0.45",
    ]:
        require_absent(SESSION_ADVANCED, forbidden)

    for token in [
        "import Charts",
        "struct ElevationProfileChartView: View",
        "let points: [SessionSummaryChartPoint]",
        "ChartCard(",
        "LineMark(",
        ".foregroundStyle(SkateTrackSessionStartColors.amber)",
        ".interpolationMethod(.linear)",
        "ChartEmptyState(",
        ".accessibilityIdentifier(\"summary-elevation-profile-chart\")",
        ".accessibilityIdentifier(\"elevation-profile-chart-view\")",
    ]:
        require_token(ELEVATION_CHART, token)

    for token in [
        "struct ElevationDisplayPipeline",
        "func makeDisplayElevation(",
        "ElevationDisplayResult(",
        "ElevationDisplaySummary(",
        "displayDerivedTotalAscentMeters(from:",
        "altitudeMicroDipDisplayGuardedPoints",
        "smoothedElevationPoints",
        "shouldStartNewElevationSegment",
    ]:
        require_token(ELEVATION_PIPELINE, token)


def verify_untouched_guards() -> None:
    # ActivityViz-010 only changes the iOS adapter, docs, and this verifier.
    for relative in [
        "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
        "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
        "iOS/Features/SessionSummary/SessionRouteMapView.swift",
        "Shared/ActivityVisualization/Elevation/ElevationDisplayModels.swift",
        "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
        "Tests/ActivityVisualizationTests/ElevationDisplayPipelineTests.swift",
        "Shared/ActivityVisualization/Speed",
        "Shared/ActivityVisualization/Route",
        "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
        "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
        "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
        "macOS/Features/SessionBrowser/MacSessionViewerModel.swift",
        "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
        "SkateTrack.xcodeproj/project.pbxproj",
    ]:
        require_clean(relative)


def verify_docs() -> None:
    for token in [
        "Task-031-prep-ActivityViz-010 iOS Elevation Profile Migration",
        "ElevationDisplayPipeline(configuration: ElevationDisplayConfiguration(maximumDisplayPointCount: 120))",
        "chartPoints(from result: ElevationDisplayResult)",
        "ElevationProfileChartView.swift` untouched",
        "no persistence/export/package schema change",
        "no elevation metric mutation",
    ]:
        require_token(DEV_LOG, token)

    for token in [
        "Task-031-prep ActivityViz-010 iOS Elevation Profile Migration",
        "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift",
        "ElevationProfileChartView.swift` remains the SwiftUI/Charts renderer",
        "verify_task031_prep_010_ios_elevation_migration.py",
        "macOS elevation migration remains deferred to ActivityViz-011",
    ]:
        require_token(FILE_STRUCTURE, token)


def verify_global_guards() -> None:
    ui_import_count = grep_count(REPO / "Shared/ActivityVisualization", r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b")
    test_ui_import_count = grep_count(REPO / "Tests/ActivityVisualizationTests", r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b")
    persistence_export_count = token_count(
        [
            REPO / "Shared/Models",
            REPO / "iOS/Core",
            REPO / "macOS/Features/Import",
            REPO / "Shared/Packages",
            REPO / "Shared/Persistence",
            REPO / "Shared/Repositories",
        ],
        ("displayDerived", "displayDerivedTotalAscentMeters", "displayDerivedTotalDescentMeters"),
    )
    emit(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={ui_import_count}")
    emit(f"TEST_UI_IMPORT_COUNT={test_ui_import_count}")
    emit(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={persistence_export_count}")
    if ui_import_count == 0:
        ok("Shared/ActivityVisualization avoids platform UI imports")
    else:
        fail("Shared/ActivityVisualization imports platform UI frameworks")
    if test_ui_import_count == 0:
        ok("ActivityVisualization tests avoid platform UI imports")
    else:
        fail("ActivityVisualization tests import platform UI frameworks")
    if persistence_export_count == 0:
        ok("displayDerived tokens absent from persistence/export/package paths")
    else:
        fail("displayDerived tokens found in persistence/export/package paths")


def main() -> int:
    emit("===== Task-031-prep ActivityViz-010 iOS elevation migration verifier =====")
    emit("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    emit("Aligned subtask: task-031-prep-ActivityViz-010 — iOS Elevation Profile Migration")
    emit(f"REPO={REPO}")

    try:
        verify_required_files()
        verify_source_shape()
        verify_untouched_guards()
        verify_docs()
        verify_global_guards()
    except Exception as exc:  # noqa: BLE001 - fail gracefully instead of traceback.
        fail(f"unexpected verifier error: {type(exc).__name__}: {exc}")

    emit("===== Summary =====")
    emit(f"WARNING_COUNT={len(WARNINGS)}")
    emit(f"FAILURE_COUNT={len(FAILURES)}")
    if FAILURES:
        emit("VERIFY_TASK031_PREP_010_IOS_ELEVATION_MIGRATION_RESULT=FAILED")
        return 1
    emit("VERIFY_TASK031_PREP_010_IOS_ELEVATION_MIGRATION_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
