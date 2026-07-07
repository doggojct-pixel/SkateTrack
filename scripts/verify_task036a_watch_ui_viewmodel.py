#!/usr/bin/env python3
"""Task-036a Watch UI Data Contract + View Model verifier."""

from pathlib import Path
import subprocess
import sys


EXPECTED_BRANCH = "task-036-watch-ui-data-contract"
EXPECTED_BASE_HEAD = "7b683a216569eb25740deaeac13e53683158db34"

REQUIRED_FILES = [
    "Shared/WatchUI/WatchActivityViewModel.swift",
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
    "scripts/verify_task036a_watch_ui_viewmodel.py",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

ALLOWED_CHANGED_PATHS = set(REQUIRED_FILES)

FORBIDDEN_CHANGED_PREFIXES = [
    "Shared/Persistence/",
    "Shared/Export/",
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SessionData.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Models/SkateTrackPackageManifest.swift",
    "iOS/Core/Import/",
    "iOS/Core/SessionRecording/",
    "iOS/Features/SessionRecording/",
    "iOS/Features/SessionSummary/SessionRouteMapView.swift",
    "iOS/Features/SessionSummary/SpeedTimelineChartView.swift",
    "iOS/Features/SessionSummary/ElevationProfileChartView.swift",
    "watchOS/App/Assets.xcassets/",
]

FORBIDDEN_WATCH_UI_TOKENS = [
    "import MapKit",
    "MKMap",
    "MKPolyline",
    "CLLocationCoordinate2D",
    "RouteDisplayPipeline(",
    "SpeedDisplayPipeline(",
    "ElevationDisplayPipeline(",
    "ActivityVisualizationPipeline(",
    "compactSample(",
    "normalizedValue(",
    "HKHealthStore",
    "HKWorkout",
    "HKQuantitySample",
    "com.apple.developer.healthkit",
    "Snow",
    "SnowUI",
    "schemaVersion",
    "NSManagedObjectModel",
    "routeCoordinates",
    "trustedDistance",
    "trustedSpeed",
    "trustedElevation",
]

VIEWMODEL_REQUIRED_TOKENS = [
    "WatchActivityViewModel",
    "WatchActivityConnectionViewState",
    "WatchActivitySessionViewState",
    "WatchActivityMetricViewState",
    "WatchActivitySampleViewState",
    "WatchActivityCompactSummaryViewState",
    "WatchBridgeActivitySnapshotPayload",
    "WatchBridgeConnectionStatusPayload",
    "WatchBridgeMetricUpdatePayload",
    "WatchSensorProviderSnapshot",
    "WatchSampleIngestionResult",
    "WatchSampleFusionResult",
    "ActivityVisualizationCompactSummary",
    "WatchBridgeCompactActivityDisplayPayload",
]

TEST_REQUIRED_TOKENS = [
    "WatchActivityViewModelTests",
    "testDefaultStateIsIdleUnknownAndDisplayEmpty",
    "testSnapshotBuildsConnectionSessionMetricsSamplesAndCompactSummaryState",
    "testBridgeDisplayPayloadProvidesDisplayStateWhenCompactSummaryIsUnavailable",
    "ActivityVisualizationCompactSummary",
    "WatchSampleIngestor",
    "WatchSampleFusionEngine",
]

DOC_REQUIRED_TOKENS = [
    "VERIFY_TASK036A_WATCH_UI_VIEWMODEL_RESULT=PASSED",
    "COMPACT_SUMMARY_CONSUMPTION=YES",
    "WATCH_UI_SEMANTIC_REIMPLEMENTATION_COUNT=0",
    "VIEWMODEL_STATE_TESTS_EXIT=0",
    "NEXT_TASK=Task-036b",
]

PROJECT_REQUIRED_TOKENS = [
    "36A000000000000000000000 /* WatchUI */",
    "36A100000000000000000001 /* WatchActivityViewModel.swift */",
    "36A100000000000000000101 /* WatchActivityViewModel.swift in Sources */",
    "36A100000000000000000102 /* WatchActivityViewModel.swift in Sources */",
    "36A900000000000000000001 /* WatchActivityViewModelTests.swift */",
    "36A900000000000000000101 /* WatchActivityViewModelTests.swift in Sources */",
]

failure_count = 0


def fail(message: str) -> None:
    global failure_count
    failure_count += 1
    print(f"FAIL: {message}")


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def run_git(args: list[str], repo: Path) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        fail(f"git {' '.join(args)} failed: {completed.stderr.strip()}")
        return ""
    return completed.stdout.strip()


def changed_paths(repo: Path) -> list[str]:
    changed = run_git(["diff", "--name-only", "HEAD", "--"], repo).splitlines()
    changed += run_git(["ls-files", "--others", "--exclude-standard"], repo).splitlines()
    return sorted(path for path in set(changed) if path)


def require_contains(path: Path, tokens: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token in text:
            pass_msg(f"{path} contains {token}")
        else:
            fail(f"{path} missing token: {token}")


def verify_changed_paths(repo: Path) -> None:
    for path in changed_paths(repo):
        if path not in ALLOWED_CHANGED_PATHS:
            fail(f"unexpected changed path for Task-036a: {path}")
        if any(path == prefix or path.startswith(prefix) for prefix in FORBIDDEN_CHANGED_PREFIXES):
            fail(f"forbidden Task-036a path changed: {path}")


def count_forbidden_watch_ui_tokens(repo: Path) -> int:
    count = 0
    for relative in ["Shared/WatchUI/WatchActivityViewModel.swift"]:
        path = repo / relative
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for token in FORBIDDEN_WATCH_UI_TOKENS:
            if token in text:
                print(f"FORBIDDEN_WATCH_UI_TOKEN={relative}:{token}")
                count += 1
    return count


def verify_project_membership(project: Path) -> None:
    text = project.read_text(encoding="utf-8")
    for token in PROJECT_REQUIRED_TOKENS:
        if token in text:
            pass_msg(f"project membership contains {token}")
        else:
            fail(f"project membership missing {token}")

    if "36A000000000000000000000 /* WatchUI */," in text and "F5168E4BB74FFD31A60E8CE0 /* Shared */" in text:
        pass_msg("WatchUI group is present under Shared project structure")
    else:
        fail("WatchUI group placement under Shared could not be confirmed")


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    if not (repo / "SkateTrack.xcodeproj/project.pbxproj").exists():
        fail(f"repo path does not look like SkateTrack: {repo}")

    branch = run_git(["branch", "--show-current"], repo)
    if branch == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-036a verification")
    else:
        fail(f"current branch is {branch}, expected {EXPECTED_BRANCH}")

    merge_base = run_git(["merge-base", "HEAD", EXPECTED_BASE_HEAD], repo)
    if merge_base == EXPECTED_BASE_HEAD:
        pass_msg("Task-036a contains the expected Task-035 develop merge base")
    else:
        fail("Task-036a does not contain the expected Task-035 develop merge base")

    for relative in REQUIRED_FILES:
        path = repo / relative
        if path.exists():
            pass_msg(f"required file exists: {relative}")
        else:
            fail(f"required file missing: {relative}")

    verify_changed_paths(repo)

    view_model = repo / "Shared/WatchUI/WatchActivityViewModel.swift"
    tests = repo / "Tests/iOSTests/WatchActivityViewModelTests.swift"
    project = repo / "SkateTrack.xcodeproj/project.pbxproj"

    if view_model.exists():
        require_contains(view_model, VIEWMODEL_REQUIRED_TOKENS)

    if tests.exists():
        require_contains(tests, TEST_REQUIRED_TOKENS)

    if project.exists():
        verify_project_membership(project)

    semantic_reimplementation_count = count_forbidden_watch_ui_tokens(repo)
    if semantic_reimplementation_count == 0:
        pass_msg("Watch UI files do not reimplement route/speed/elevation semantics")
    else:
        fail("Watch UI semantic reimplementation tokens were found")

    compact_consumption = view_model.exists() and "ActivityVisualizationCompactSummary" in view_model.read_text(encoding="utf-8")

    for relative in [
        "docs/process/PHASE_1B_AGENT_STATE.md",
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]:
        path = repo / relative
        if path.exists():
            require_contains(path, DOC_REQUIRED_TOKENS)

    print(f"COMPACT_SUMMARY_CONSUMPTION={'YES' if compact_consumption else 'NO'}")
    print(f"WATCH_UI_SEMANTIC_REIMPLEMENTATION_COUNT={semantic_reimplementation_count}")
    print("VIEWMODEL_STATE_TESTS_DECLARED=YES")
    print(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0 and compact_consumption and semantic_reimplementation_count == 0:
        print("VERIFY_TASK036A_WATCH_UI_VIEWMODEL_RESULT=PASSED")
        return 0

    print("VERIFY_TASK036A_WATCH_UI_VIEWMODEL_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
