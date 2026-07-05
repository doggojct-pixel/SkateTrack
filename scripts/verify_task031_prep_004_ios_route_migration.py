#!/usr/bin/env python3
# [協作區] scripts/verify_task031_prep_004_ios_route_migration.py
# Purpose: Verify ActivityViz-004 iOS route migration to Shared RouteDisplayPipeline without renderer or persistence scope expansion.

from pathlib import Path
import re
import subprocess
import sys

REPO = Path.cwd()
SESSION_ROUTE = REPO / "iOS/Features/SessionSummary/SessionRouteMapView.swift"
MAC_ROUTE = REPO / "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift"
SHARED_ROUTE_DIR = REPO / "Shared/ActivityVisualization/Route"
DEV_LOG = REPO / "docs/history/DEV_LOG.md"
FILE_STRUCTURE = REPO / "docs/reference/FILE_STRUCTURE.md"
PROJECT = REPO / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_PATHS = [
    SESSION_ROUTE,
    MAC_ROUTE,
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

REQUIRED_SESSION_TOKENS = [
    "RouteDisplayPipeline().makeDisplayRoute(",
    "RouteDisplayResult",
    "ActivityRouteDisplayPoint",
    "RouteDisplaySemantic",
    "routeMapSegments(from result: RouteDisplayResult)",
    "routeMapSegmentStyle(for semantic: RouteDisplaySemantic)",
    "routeAccuracyDisclosureText(routeResult: RouteDisplayResult)",
    "MapPolyline(coordinates: segment.coordinates)",
    "Annotation(NSLocalizedString(\"summary.route.start\"",
    "Annotation(NSLocalizedString(\"summary.route.finish\"",
    "routePin(systemImage:",
    "session-route-map-empty",
]

REMOVED_IOS_PIPELINE_HELPERS = [
    "private struct RouteDisplayPoint",
    "private func makeDisplayRoutePoints",
    "private func deduplicatedTrustedLocationFixes",
    "private func isTrustedDisplayRouteSample",
    "private func isStartupWarmupSample",
    "private func firstStableStartupAnchorTimestamp",
    "private func startupAnchorGuardApplies",
    "private func firstGPSLockAnchorTimestamp",
    "private func isPreferredFreshAnchor",
    "private func makeRouteSegments(from points:",
    "private func shouldStartNewRouteSegment",
    "private func shouldSuppressSmallAreaJitter",
    "private func smoothDisplayCoordinate",
    "private func interpolatedCoordinate",
    "private func appendSegmentIfNeeded",
    "private func locationFixKey",
    "private func routeTimestamp(for sample:",
    "private func distanceMeters",
]

RENDERER_OWNERSHIP_TOKENS = [
    "private enum RouteMapSegmentStyle",
    "private static let fluorescentPink",
    "private static let brightOrange",
    "SkateTrackSessionStartColors.teal",
    "SkateTrackSessionStartColors.amber",
    "Map(initialPosition:",
    "MapPolyline",
    "Annotation",
    "RoundedRectangle",
    "LocalizedStringKey",
]

DOC_TOKENS = [
    "Task-031-prep-ActivityViz-004 iOS Route Migration",
    "RouteDisplayPipeline().makeDisplayRoute",
    "MacRouteDisplayPipeline.swift` untouched",
]

FILE_STRUCTURE_TOKENS = [
    "Task-031-prep ActivityViz-004 iOS Route Migration",
    "SessionRouteMapView.swift",
    "verify_task031_prep_004_ios_route_migration.py",
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
    print("===== Task-031-prep ActivityViz-004 iOS route migration verifier =====")
    print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    print("Aligned subtask: task-031-prep-ActivityViz-004 — iOS Route Migration")
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
        print("VERIFY_TASK031_PREP_004_IOS_ROUTE_MIGRATION_RESULT=FAILED")
        return 1

    session_text = read_text(SESSION_ROUTE)
    first_line = session_text.splitlines()[0] if session_text.splitlines() else ""
    line_count = len(session_text.splitlines())
    print(f"FIRST_LINE[SessionRouteMapView.swift]={first_line}")
    print(f"LINE_COUNT[SessionRouteMapView.swift]={line_count}")
    if first_line.startswith("// [協作區]"):
        pass_line("SessionRouteMapView.swift has collaboration header")
    else:
        fail_line("SessionRouteMapView.swift missing collaboration header", failures)
    if line_count <= 500:
        pass_line("SessionRouteMapView.swift stays under 500 lines after migration")
    else:
        fail_line("SessionRouteMapView.swift exceeds 500 lines after migration", failures)

    for token in REQUIRED_SESSION_TOKENS:
        if token in session_text:
            pass_line(f"SessionRouteMapView.swift contains token: {token}")
        else:
            fail_line(f"SessionRouteMapView.swift missing token: {token}", failures)

    for token in REMOVED_IOS_PIPELINE_HELPERS:
        if token in session_text:
            fail_line(f"SessionRouteMapView.swift still contains duplicated route-prep helper: {token}", failures)
        else:
            pass_line(f"SessionRouteMapView.swift removed duplicated route-prep helper: {token}")

    for token in RENDERER_OWNERSHIP_TOKENS:
        if token in session_text:
            pass_line(f"iOS renderer ownership token preserved: {token}")
        else:
            fail_line(f"iOS renderer ownership token missing: {token}", failures)

    if "import MapKit" in session_text and "import SwiftUI" in session_text:
        pass_line("SessionRouteMapView.swift keeps platform renderer imports in iOS")
    else:
        fail_line("SessionRouteMapView.swift missing iOS renderer imports", failures)

    shared_texts = []
    for path in (REPO / "Shared/ActivityVisualization").rglob("*.swift"):
        shared_texts.append((path, read_text(path)))
    shared_ui_import_count = sum(len(UI_IMPORT_RE.findall(text)) for _, text in shared_texts)
    print(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_import_count}")
    if shared_ui_import_count == 0:
        pass_line("Shared/ActivityVisualization avoids platform UI imports")
    else:
        fail_line("Shared/ActivityVisualization contains platform UI imports", failures)

    session_status = git_status_for("iOS/Features/SessionSummary/SessionRouteMapView.swift")
    mac_status = git_status_for("macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift")
    print(f"SESSION_ROUTE_MAP_VIEW_STATUS={session_status or 'CLEAN'}")
    print(f"MAC_ROUTE_DISPLAY_PIPELINE_STATUS={mac_status or 'CLEAN'}")
    if mac_status:
        fail_line("MacRouteDisplayPipeline.swift changed during ActivityViz-004", failures)
    else:
        pass_line("MacRouteDisplayPipeline.swift remains untouched for ActivityViz-005")

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
        print("VERIFY_TASK031_PREP_004_IOS_ROUTE_MIGRATION_RESULT=FAILED")
        return 1
    print("VERIFY_TASK031_PREP_004_IOS_ROUTE_MIGRATION_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:  # noqa: BLE001 - verifier must report internal failures clearly.
        print(f"FAIL: verifier internal exception: {error.__class__.__name__}: {error}")
        print("===== Summary =====")
        print("WARNING_COUNT=0")
        print("FAILURE_COUNT=1")
        print("VERIFY_TASK031_PREP_004_IOS_ROUTE_MIGRATION_RESULT=FAILED")
        sys.exit(1)
