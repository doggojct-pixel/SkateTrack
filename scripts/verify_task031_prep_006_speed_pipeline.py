#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "SkateTrack.xcodeproj/project.pbxproj"
FILE_STRUCTURE = ROOT / "docs/reference/FILE_STRUCTURE.md"
DEV_LOG = ROOT / "docs/history/DEV_LOG.md"
SPEED_MODELS = ROOT / "Shared/ActivityVisualization/Speed/SpeedDisplayModels.swift"
SPEED_PIPELINE = ROOT / "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift"
SPEED_TESTS = ROOT / "Tests/ActivityVisualizationTests/SpeedDisplayPipelineTests.swift"
IOS_SPEED_CHART = ROOT / "iOS/Features/SessionSummary/SpeedTimelineChartView.swift"
IOS_ADVANCED_CHARTS = ROOT / "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift"
MAC_SPEED_SPARKLINE = ROOT / "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift"
IOS_ROUTE = ROOT / "iOS/Features/SessionSummary/SessionRouteMapView.swift"
MAC_ROUTE = ROOT / "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift"
ROUTE_DIR = ROOT / "Shared/ActivityVisualization/Route"

WARNING_COUNT = 0
FAILURE_COUNT = 0


def warn(message: str) -> None:
    global WARNING_COUNT
    WARNING_COUNT += 1
    print(f"WARN: {message}")


def fail(message: str) -> None:
    global FAILURE_COUNT
    FAILURE_COUNT += 1
    print(f"FAIL: {message}")


def passed(message: str) -> None:
    print(f"PASS: {message}")


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text()


def require_path(path: Path) -> None:
    rel = path.relative_to(ROOT)
    if path.exists():
        passed(f"required path exists: {rel}")
    else:
        fail(f"missing required path: {rel}")


def require_token(text: str, token: str, label: str) -> None:
    if token in text:
        passed(f"{label} contains token: {token}")
    else:
        fail(f"{label} missing token: {token}")


def forbid_token(text: str, token: str, label: str) -> None:
    if token in text:
        fail(f"{label} contains forbidden token: {token}")
    else:
        passed(f"{label} does not contain forbidden token: {token}")


def git_status_short(path: str) -> str:
    result = subprocess.run(
        ["git", "status", "--short", "--", path],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return result.stdout.strip()


def count_ui_imports(path: Path) -> int:
    if not path.exists():
        return 0
    count = 0
    for swift_file in path.rglob("*.swift"):
        for line in read_text(swift_file).splitlines():
            stripped = line.strip()
            if stripped in {"import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"}:
                count += 1
    return count


def line_and_header_guard(path: Path) -> None:
    rel = path.relative_to(ROOT)
    text = read_text(path)
    lines = text.splitlines()
    first_line = lines[0] if lines else ""
    line_count = len(lines)
    print(f"FIRST_LINE[{rel}]={first_line}")
    print(f"LINE_COUNT[{rel}]={line_count}")
    if first_line.startswith("// [協作區") or first_line.startswith("// [自主區"):
        passed(f"{rel} has collaboration header")
    else:
        fail(f"{rel} missing collaboration header")
    if line_count <= 500:
        passed(f"{rel} stays under 500 lines")
    else:
        fail(f"{rel} exceeds 500 lines")


def project_membership_guard() -> None:
    project_text = read_text(PROJECT)
    checks = [
        ("SpeedDisplayPipeline.swift", 3),
        ("SpeedDisplayModels.swift", 3),
        ("SpeedDisplayPipelineTests.swift", 2),
    ]
    membership_failures = 0
    for name, minimum_count in checks:
        token_count = project_text.count(name)
        print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
        if token_count >= minimum_count:
            passed(f"project references {name}")
        else:
            fail(f"project membership incomplete for {name}")
            membership_failures += 1

    if "path = Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift" in project_text:
        fail("project contains repo-root SpeedDisplayPipeline path token")
        membership_failures += 1
    else:
        passed("SpeedDisplayPipeline.swift fileRef is group-relative")

    if "31A300000000000000000000 /* Speed */" in project_text and "31A310000000000000000001 /* SpeedDisplayPipeline.swift */" in project_text:
        passed("SpeedDisplayPipeline.swift is grouped under Shared/ActivityVisualization/Speed")
    else:
        fail("SpeedDisplayPipeline.swift group membership missing")
        membership_failures += 1

    print(f"PROJECT_MEMBERSHIP_FAILURE_COUNT={membership_failures}")


def route_stability_guard() -> None:
    paths = [
        ("iOS_SESSION_ROUTE_MAP_VIEW_STATUS", "iOS/Features/SessionSummary/SessionRouteMapView.swift"),
        ("MAC_ROUTE_DISPLAY_PIPELINE_STATUS", "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift"),
        ("SHARED_ROUTE_STATUS", "Shared/ActivityVisualization/Route"),
    ]
    for label, path in paths:
        status = git_status_short(path)
        if status:
            print(f"{label}={status}")
            fail(f"route migration guard changed unexpectedly: {path}")
        else:
            print(f"{label}=CLEAN")
            passed(f"route migration guard clean: {path}")


def speed_chart_untouched_guard() -> None:
    paths = [
        ("IOS_SPEED_TIMELINE_CHART_STATUS", "iOS/Features/SessionSummary/SpeedTimelineChartView.swift"),
        ("IOS_ADVANCED_CHARTS_STATUS", "iOS/Features/SessionSummary/SessionAdvancedChartsView.swift"),
        ("MAC_SPEED_SPARKLINE_STATUS", "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift"),
    ]
    for label, path in paths:
        status = git_status_short(path)
        if status:
            print(f"{label}={status}")
            fail(f"platform speed chart changed during ActivityViz-006: {path}")
        else:
            print(f"{label}=CLEAN")
            passed(f"platform speed chart untouched: {path}")


def main() -> int:
    print("===== Task-031-prep ActivityViz-006 speed pipeline verifier =====")
    print("Aligned Build Plan: Task-031-prep_Shared_Activity_Visualization_Pipeline_for_iOS_macOS_watchOS_EN_v1_1.md")
    print("Aligned subtask: task-031-prep-ActivityViz-006 — Shared Speed Display Pipeline Shell")
    print(f"REPO={ROOT}")

    for path in [
        SPEED_MODELS,
        SPEED_PIPELINE,
        SPEED_TESTS,
        IOS_SPEED_CHART,
        IOS_ADVANCED_CHARTS,
        MAC_SPEED_SPARKLINE,
        IOS_ROUTE,
        MAC_ROUTE,
        PROJECT,
        FILE_STRUCTURE,
        DEV_LOG,
    ]:
        require_path(path)

    if not SPEED_PIPELINE.exists() or not SPEED_MODELS.exists() or not SPEED_TESTS.exists():
        print("===== Summary =====")
        print(f"WARNING_COUNT={WARNING_COUNT}")
        print(f"FAILURE_COUNT={FAILURE_COUNT}")
        print("VERIFY_TASK031_PREP_006_SPEED_PIPELINE_RESULT=FAILED")
        return 1

    for path in [SPEED_MODELS, SPEED_PIPELINE, SPEED_TESTS]:
        line_and_header_guard(path)

    pipeline_text = read_text(SPEED_PIPELINE)
    models_text = read_text(SPEED_MODELS)
    tests_text = read_text(SPEED_TESTS)

    for token in [
        "struct SpeedDisplayPipeline",
        "func makeDisplaySpeed(",
        "samples: [MotionSample]",
        "fidelityPolicy: ActivityFidelityPolicy",
        "SpeedDisplayPoint(",
        "segmentID:",
        "SpeedDisplayResult(",
        "SpeedDisplaySummary(",
        "SpeedDisplayDiagnostics(",
        "downsample(",
        "smoothedSpeedPoints",
        "shouldStartNewChartSegment",
        "speed.droppedInvalidOrOutOfRangeSamples",
    ]:
        require_token(pipeline_text, token, "SpeedDisplayPipeline.swift")

    for token in [
        "let segmentID: Int",
        "segmentID: Int = 0",
        "let segmentCount: Int",
        "segmentCount: Int = 0",
    ]:
        require_token(models_text, token, "SpeedDisplayModels.swift")

    for token in [
        "final class SpeedDisplayPipelineTests",
        "testSharedSpeedPipelineBuildsDisplayOnlyPoints",
        "testSharedSpeedPipelineDropsInvalidAndOutOfRangeSamplesWithoutMutatingMetrics",
        "testSharedSpeedPipelineSegmentsGapsAndDownsamplesForDisplay",
        "SpeedDisplayPipeline()",
        "makeDisplaySpeed(",
        "XCTAssertEqual(samples[1].speedKmh",
    ]:
        require_token(tests_text, token, "SpeedDisplayPipelineTests.swift")

    for label, text in [
        ("SpeedDisplayPipeline.swift", pipeline_text),
        ("SpeedDisplayPipelineTests.swift", tests_text),
    ]:
        for token in ["import SwiftUI", "import MapKit", "import UIKit", "import AppKit", "import WatchKit"]:
            forbid_token(text, token, label)

    project_membership_guard()
    route_stability_guard()
    speed_chart_untouched_guard()

    shared_ui_import_count = count_ui_imports(ROOT / "Shared/ActivityVisualization")
    test_ui_import_count = count_ui_imports(ROOT / "Tests/ActivityVisualizationTests")
    print(f"SHARED_ACTIVITYVIZ_UI_IMPORT_COUNT={shared_ui_import_count}")
    print(f"TEST_UI_IMPORT_COUNT={test_ui_import_count}")
    if shared_ui_import_count == 0:
        passed("Shared/ActivityVisualization avoids platform UI imports")
    else:
        fail("Shared/ActivityVisualization imports platform UI frameworks")
    if test_ui_import_count == 0:
        passed("ActivityVisualization tests avoid platform UI imports")
    else:
        fail("ActivityVisualization tests import platform UI frameworks")

    persistence_export_paths = [
        ROOT / "Shared/Models",
        ROOT / "Shared/Persistence",
        ROOT / "Shared/Export",
        ROOT / "iOS/Core/Export",
        ROOT / "iOS/Core/Import",
    ]
    persistence_tokens = []
    for path in persistence_export_paths:
        if not path.exists():
            continue
        for file in path.rglob("*.swift"):
            text = read_text(file)
            if "displayDerived" in text or "displayDerivedTotalAscentMeters" in text:
                persistence_tokens.append(str(file.relative_to(ROOT)))
    print(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_COUNT={len(persistence_tokens)}")
    if persistence_tokens:
        for item in persistence_tokens:
            print(f"DISPLAY_DERIVED_PERSISTENCE_EXPORT_TOKEN={item}")
        fail("displayDerived tokens found in persistence/export/package paths")
    else:
        passed("displayDerived tokens absent from persistence/export/package paths")

    file_structure_text = read_text(FILE_STRUCTURE)
    dev_log_text = read_text(DEV_LOG)
    for token in [
        "Task-031-prep ActivityViz-006 Shared Speed Display Pipeline Shell",
        "SpeedDisplayPipeline.swift",
        "SpeedDisplayPipelineTests.swift",
        "verify_task031_prep_006_speed_pipeline.py",
    ]:
        require_token(file_structure_text, token, "FILE_STRUCTURE")
    for token in [
        "Task-031-prep-ActivityViz-006 Shared Speed Display Pipeline Shell",
        "SpeedDisplayPipeline",
        "makeDisplaySpeed",
        "SpeedDisplayPoint.segmentID",
        "speed charts untouched",
        "no speed metric mutation",
    ]:
        require_token(dev_log_text, token, "DEV_LOG")

    print("===== Summary =====")
    print(f"WARNING_COUNT={WARNING_COUNT}")
    print(f"FAILURE_COUNT={FAILURE_COUNT}")
    if FAILURE_COUNT == 0:
        print("VERIFY_TASK031_PREP_006_SPEED_PIPELINE_RESULT=PASSED")
        return 0
    print("VERIFY_TASK031_PREP_006_SPEED_PIPELINE_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # fail gracefully in one-click logs
        print(f"FAIL: unhandled verifier exception: {exc}")
        print("===== Summary =====")
        print("WARNING_COUNT=0")
        print("FAILURE_COUNT=1")
        print("VERIFY_TASK031_PREP_006_SPEED_PIPELINE_RESULT=FAILED")
        sys.exit(1)
