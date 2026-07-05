#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_005_macos_route_migration.py
# Purpose: Verify ActivityViz-005 macOS route migration to Shared RouteDisplayPipeline without iOS, Shared, or persistence scope expansion.

from pathlib import Path
import re
import subprocess
import sys

REPO = Path.cwd()
MAC_ROUTE = REPO / "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift"
IOS_ROUTE = REPO / "iOS/Features/SessionSummary/SessionRouteMapView.swift"
MAC_PREVIEW = REPO / "macOS/Features/SessionBrowser/MacRoutePreviewView.swift"
MAC_CONTEXT = REPO / "macOS/Features/SessionBrowser/MacRouteMapContextView.swift"
MAC_INSPECTION = REPO / "macOS/Features/SessionBrowser/MacRouteInspectionView.swift"
MAC_PRESENTER = REPO / "macOS/Features/SessionBrowser/MacRouteInspectionWindowPresenter.swift"
MAC_STYLE = REPO / "macOS/Features/SessionBrowser/MacRouteVisualStyle.swift"
SHARED_ROUTE_DIR = REPO / "Shared/ActivityVisualization/Route"
DEV_LOG = REPO / "docs/history/DEV_LOG.md"
FILE_STRUCTURE = REPO / "docs/reference/FILE_STRUCTURE.md"
PROJECT = REPO / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_PATHS = [
    MAC_ROUTE,
    IOS_ROUTE,
    MAC_PREVIEW,
    MAC_CONTEXT,
    MAC_INSPECTION,
    MAC_PRESENTER,
    MAC_STYLE,
    SHARED_ROUTE_DIR / "RouteDisplayPipeline.swift",
    SHARED_ROUTE_DIR / "RouteDisplayPipeline+Filtering.swift",
    SHARED_ROUTE_DIR / "RouteDisplayPipeline+Startup.swift",
    SHARED_ROUTE_DIR / "RouteDisplayPipeline+Segmentation.swift",
    SHARED_ROUTE_DIR / "RouteDisplayPipeline+Bounds.swift",
    SHARED_ROUTE_DIR / "RouteDisplayModels.swift",
    REPO / "Tests/ActivityVisualizationTests/RouteDisplayFixtureTests.swift",
    REPO / "Tests/Fixtures/ActivityVisualization/route_display_fixture_baselines.json",
    DEV_LOG,
    FILE_STRUCTURE,
    PROJECT,
]

REQUIRED_MAC_TOKENS = [
    "RouteDisplayPipeline().makeDisplayRoute(",
    "RouteDisplayResult",
    "ActivityRouteDisplayPoint",
    "RouteDisplayConfidence",
    "routeDisplayResult(session: SessionData, samples: [MotionSample]) -> RouteDisplayResult",
    "routePoints(from result: RouteDisplayResult)",
    "macRoutePoint(from point: ActivityRouteDisplayPoint)",
    "macRouteConfidence(for confidence: RouteDisplayConfidence)",
    "MacRoutePoint(",
    "isStartupWarmup: point.semantic == .startupWarmup",
    "deriveDistanceKilometers(from: routeSamples)",
    "deriveElevationGainMeters(from: sortedSamples)",
    "deriveMovingRatio(from: sortedSamples)",
    "speedPoints(from samples: [MotionSample])",
]

REMOVED_MAC_PIPELINE_HELPERS = [
    "startupStableAnchorClusterWindowSeconds",
    "startupStableAnchorMinimumCandidateCount",
    "startupGPSLockSearchWindowSeconds",
    "startupConvergenceWarmupSeconds",
    "startupRouteVisualSuppressionMaximumSeconds",
    "private static func routePoints(session: SessionData, from samples:",
    "private static func shouldSkipJitter",
    "private static func displayCoordinateForPoint",
    "private static func deduplicatedTrustedLocationFixes",
    "private static func isTrustedDisplayRouteSample",
    "private static func isStartupWarmupSample",
    "private static func startupGuardWarmup",
    "private static func startupAnchorGuardApplies",
    "private static func firstGPSLockAnchorTimestamp",
    "private static func isPreferredFreshAnchor",
    "private static func shouldSuppressSmallAreaJitter",
    "private static func smoothDisplayCoordinate",
    "private static func smoothingWeight",
    "private static func locationFixKey",
]

MAC_RENDERER_TOKENS = {
    MAC_PREVIEW: [
        "MacRoutePreviewView",
        "MacRouteMapContextView(points: points, summary: summary)",
        "MacRouteVisualLegendView",
        "MacRouteInspectionWindowPresenter.shared.open",
    ],
    MAC_CONTEXT: [
        "MKMapView",
        "MKPolylineRenderer",
        "MKMarkerAnnotationView",
        "makeRouteSegments(from points: [MacRoutePoint])",
        "MacRouteVisualStyle",
        "endpointAnnotations(for:",
    ],
    MAC_INSPECTION: [
        "MacRouteInspectionView",
        "MacRouteVisualLegendView",
    ],
    MAC_STYLE: [
        "MacRouteVisualStyle",
        "trustedGreenRoute",
        "brightOrangeAccent",
        "fluorescentPinkGlow",
    ],
}

DOC_TOKENS = [
    "Task-031-prep-ActivityViz-005 macOS Route Migration",
    "RouteDisplayPipeline().makeDisplayRoute",
    "SessionRouteMapView.swift` untouched",
]

FILE_STRUCTURE_TOKENS = [
    "Task-031-prep ActivityViz-005 macOS Route Migration",
    "MacRouteDisplayPipeline.swift",
    "verify_task031_prep_005_macos_route_migration.py",
]

UI_IMPORT_RE = re.compile(r"^\s*import\s+(SwiftUI|MapKit|UIKit|AppKit|WatchKit)\b", re.MULTILINE)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def pass_line(message: str) -> None:
    print(f"PASS: {message}")


def fail_line(message: str, failures: list[str]) -> None:
    print(f"FAIL: {message}")
    failures.append(message)


def git_status_for(path: str) -> str:
    completed = subprocess.run(
        ["git", "status", "--short", "--", path],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return completed.stdout.strip()


def main() -> int:
    print("===== Task-031-prep ActivityViz-005 macOS route migration verifier =====")
    print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    print("Aligned subtask: task-031-prep-ActivityViz-005 — macOS Route Migration")
    print(f"REPO={REPO}")
    failures: list[str] = []
    warnings: list[str] = []

    for path in REQUIRED_PATHS:
        if path.exists():
            pass_line(f"required path exists: {path.relative_to(REPO)}")
        else:
            fail_line(f"required path missing: {path.relative_to(REPO)}", failures)

    if failures:
        print("===== Summary =====")
        print(f"WARNING_COUNT={len(warnings)}")
        print(f"FAILURE_COUNT={len(failures)}")
        print("VERIFY_TASK031_PREP_005_MACOS_ROUTE_MIGRATION_RESULT=FAILED")
        return 1

    mac_text = read_text(MAC_ROUTE)
    first_line = mac_text.splitlines()[0] if mac_text.splitlines() else ""
    line_count = len(mac_text.splitlines())
    print(f"FIRST_LINE[MacRouteDisplayPipeline.swift]={first_line}")
    print(f"LINE_COUNT[MacRouteDisplayPipeline.swift]={line_count}")
    if first_line.startswith("// [協作區]"):
        pass_line("MacRouteDisplayPipeline.swift has collaboration header")
    else:
        fail_line("MacRouteDisplayPipeline.swift missing collaboration header", failures)
    if line_count <= 500:
        pass_line("MacRouteDisplayPipeline.swift stays under 500 lines after migration")
    else:
        fail_line("MacRouteDisplayPipeline.swift exceeds 500 lines after migration", failures)

    for token in REQUIRED_MAC_TOKENS:
        if token in mac_text:
            pass_line(f"MacRouteDisplayPipeline.swift contains token: {token}")
        else:
            fail_line(f"MacRouteDisplayPipeline.swift missing token: {token}", failures)

    for token in REMOVED_MAC_PIPELINE_HELPERS:
        if token in mac_text:
            fail_line(f"MacRouteDisplayPipeline.swift still contains duplicated route-prep helper: {token}", failures)
        else:
            pass_line(f"MacRouteDisplayPipeline.swift removed duplicated route-prep helper: {token}")

    for path, tokens in MAC_RENDERER_TOKENS.items():
        text = read_text(path)
        for token in tokens:
            if token in text:
                pass_line(f"macOS renderer ownership token preserved in {path.name}: {token}")
            else:
                fail_line(f"macOS renderer ownership token missing in {path.name}: {token}", failures)

    shared_texts = []
    for path in (REPO / "Shared/ActivityVisualization").rglob("*.swift"):
        shared_texts.append((path, read_text(path)))
    shared_ui_import_count = sum(len(UI_IMPORT_RE.findall(text)) for _, text in shared_texts)
    print(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_import_count}")
    if shared_ui_import_count == 0:
        pass_line("Shared/ActivityVisualization avoids platform UI imports")
    else:
        fail_line("Shared/ActivityVisualization contains platform UI imports", failures)

    ios_status = git_status_for("iOS/Features/SessionSummary/SessionRouteMapView.swift")
    mac_status = git_status_for("macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift")
    shared_status = subprocess.run(
        ["git", "status", "--short", "--", "Shared/ActivityVisualization"],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    ).stdout.strip()
    print(f"IOS_SESSION_ROUTE_MAP_VIEW_STATUS={ios_status or 'CLEAN'}")
    print(f"MAC_ROUTE_DISPLAY_PIPELINE_STATUS={mac_status or 'CLEAN'}")
    print(f"SHARED_ACTIVITYVIZ_STATUS_COUNT={len([line for line in shared_status.splitlines() if line.strip()])}")
    if ios_status:
        fail_line("SessionRouteMapView.swift changed during ActivityViz-005", failures)
    else:
        pass_line("SessionRouteMapView.swift remains untouched after ActivityViz-004")
    if not mac_status:
        fail_line("MacRouteDisplayPipeline.swift should be changed during ActivityViz-005", failures)
    else:
        pass_line("MacRouteDisplayPipeline.swift is the macOS migration target")
    if shared_status:
        fail_line("Shared/ActivityVisualization changed during ActivityViz-005", failures)
    else:
        pass_line("Shared/ActivityVisualization remains untouched during ActivityViz-005")

    changed_forbidden_scope = subprocess.run(
        [
            "git", "grep", "-nE",
            "displayDerived|displayDerivedTotalAscentMeters",
            "--", "Shared/Models", "Shared/Persistence", "Shared/Export", "iOS/Core/Export", "iOS/Core/Import",
        ],
        cwd=REPO,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    display_derived_count = 0 if changed_forbidden_scope.returncode == 1 else len([line for line in changed_forbidden_scope.stdout.splitlines() if line.strip()])
    print(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={display_derived_count}")
    if display_derived_count == 0:
        pass_line("displayDerived tokens absent from persistence/export/package paths")
    else:
        fail_line("displayDerived token found in persistence/export/package paths", failures)

    dev_log = read_text(DEV_LOG)
    file_structure = read_text(FILE_STRUCTURE)
    for token in DOC_TOKENS:
        if token in dev_log:
            pass_line(f"DEV_LOG contains token: {token}")
        else:
            fail_line(f"DEV_LOG missing token: {token}", failures)
    for token in FILE_STRUCTURE_TOKENS:
        if token in file_structure:
            pass_line(f"FILE_STRUCTURE contains token: {token}")
        else:
            fail_line(f"FILE_STRUCTURE missing token: {token}", failures)

    print("===== Summary =====")
    print(f"WARNING_COUNT={len(warnings)}")
    print(f"FAILURE_COUNT={len(failures)}")
    if failures:
        print("VERIFY_TASK031_PREP_005_MACOS_ROUTE_MIGRATION_RESULT=FAILED")
        return 1
    print("VERIFY_TASK031_PREP_005_MACOS_ROUTE_MIGRATION_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:  # noqa: BLE001 - verifier must report internal failures clearly.
        print(f"FAIL: verifier internal exception: {error.__class__.__name__}: {error}")
        print("===== Summary =====")
        print("WARNING_COUNT=0")
        print("FAILURE_COUNT=1")
        print("VERIFY_TASK031_PREP_005_MACOS_ROUTE_MIGRATION_RESULT=FAILED")
        sys.exit(1)
