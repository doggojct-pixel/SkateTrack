#!/usr/bin/env python3
# [Collaboration] scripts/verify_task037a_metric_provider_protocol.py
"""Task-037a Metric Provider Protocol verifier."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

EXPECTED_BRANCH = "task-037-metric-provider-carousel"
EXPECTED_BASE_HEAD = "c6b118ba91958a0f5a335d6391b6c7f6d8fc3d7a"

REQUIRED_FILES = (
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
    "scripts/verify_task037a_metric_provider_protocol.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "SkateTrack.xcodeproj/project.pbxproj",
)

ALLOWED_CHANGED_PATHS = set(REQUIRED_FILES)

FORBIDDEN_CHANGED_PREFIXES = (
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
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "watchOS/App/SkateTrackWatchApp.swift",
    "watchOS/App/Assets.xcassets/",
    "Shared/Localization/",
)

PROVIDER_REQUIRED_TOKENS = (
    "enum WatchMetricActivityMode",
    "enum WatchMetricAvailabilityState",
    "enum WatchMetricUnavailableReason",
    "struct WatchMetricProviderContext",
    "struct WatchMetricProviderOutput",
    "protocol WatchMetricProviding",
    "struct WatchBaseMetricProvider",
    "struct WatchMetricProviderSelector",
    "func supports(activityMode: WatchMetricActivityMode) -> Bool",
    "func makeMetricOutputs(context: WatchMetricProviderContext) -> [WatchMetricProviderOutput]",
    "case unsupported(rawValue: String?)",
    "case lockedByEntitlementBoundary",
    "case compactSpeedSparkline",
    "case compactElevationProfile",
)

TEST_REQUIRED_TOKENS = (
    "final class WatchMetricProviderTests",
    "testBaseProviderSelectedForSkateboardAndUsesCompactOutputs",
    "testBaseProviderSelectedForInlineWithUnavailableOutputsWhenCompactDataIsMissing",
    "testUnsupportedModeHasNoProviderAndReturnsSafeUnavailableState",
    "testCustomProviderCanSupportFutureModeWithoutChangingBaseProvider",
    "testDisabledProviderFallbackDisablesMetricOutputs",
    "testStaleBridgeMakesOutputsUnavailableEvenWhenCompactDataExists",
    "WatchMetricProviderSelector",
    "WatchBaseMetricProvider",
)

PROJECT_REQUIRED_TOKENS = (
    "37A100000000000000000001 /* WatchMetricProvider.swift */",
    "37A100000000000000000101 /* WatchMetricProvider.swift in Sources */",
    "37A100000000000000000102 /* WatchMetricProvider.swift in Sources */",
    "37A900000000000000000001 /* WatchMetricProviderTests.swift */",
    "37A900000000000000000101 /* WatchMetricProviderTests.swift in Sources */",
)

DOC_REQUIRED_TOKENS = (
    "TASK037A_METRIC_PROVIDER_PROTOCOL_START",
    "VERIFY_TASK037A_METRIC_PROVIDER_PROTOCOL_RESULT=PASSED",
    "MODE_AWARE_PROVIDER_PRESENT=YES",
    "SNOW_PROVIDER_IMPLEMENTED=NO",
    "NEXT_TASK=Task-037b",
)

FORBIDDEN_SOURCE_PATTERNS = (
    r"\bimport\s+MapKit\b",
    r"\bMKMap",
    r"\bMKPolyline",
    r"\bCLLocationCoordinate2D\b",
    r"\bRouteDisplayPipeline\b",
    r"\bSpeedDisplayPipeline\b",
    r"\bElevationDisplayPipeline\b",
    r"\bActivityVisualizationPipeline\b",
    r"\bcompactSample\s*\(",
    r"\bnormalizedValue\s*\(",
    r"\bHKHealthStore\b",
    r"\bHKWorkout\b",
    r"\bHKQuantitySample\b",
    r"\bStoreKit\b",
    r"\bProduct\s*\(",
    r"\bski\b",
    r"\bsnow\b",
)

SWIFT_FILES_TO_SCAN = (
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
)

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


def require_contains(path: Path, tokens: tuple[str, ...]) -> None:
    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token in text:
            pass_msg(f"{path.relative_to(path.parents[2]) if len(path.parents) > 2 else path} contains {token}")
        else:
            fail(f"{path} missing token: {token}")


def verify_changed_paths(repo: Path) -> None:
    changed = changed_paths(repo)
    for path in changed:
        if path not in ALLOWED_CHANGED_PATHS:
            fail(f"unexpected changed path for Task-037a: {path}")
        if any(path == prefix or path.startswith(prefix) for prefix in FORBIDDEN_CHANGED_PREFIXES):
            fail(f"forbidden Task-037a path changed: {path}")
    print("TASK037A_CHANGED_PATHS=" + (",".join(changed) if changed else "NONE"))


def verify_headers_and_line_limits(repo: Path) -> None:
    for relative in SWIFT_FILES_TO_SCAN:
        path = repo / relative
        if not path.exists():
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        if lines and ("// [協作區]" in lines[0] or "// [Collaboration]" in lines[0]):
            pass_msg(f"{relative} has collaboration header")
        else:
            fail(f"{relative} missing collaboration header")
        if len(lines) <= 500:
            pass_msg(f"{relative} line count {len(lines)} <= 500")
        else:
            fail(f"{relative} line count {len(lines)} exceeds 500")


def verify_project_membership(repo: Path) -> None:
    project = repo / "SkateTrack.xcodeproj/project.pbxproj"
    text = project.read_text(encoding="utf-8")
    for token in PROJECT_REQUIRED_TOKENS:
        if token in text:
            pass_msg(f"project contains {token}")
        else:
            fail(f"project missing {token}")

    placement_checks = {
        "WatchUI group child": "37A100000000000000000001 /* WatchMetricProvider.swift */",
        "iOSTests group child": "37A900000000000000000001 /* WatchMetricProviderTests.swift */",
        "iOS target source": "37A100000000000000000101 /* WatchMetricProvider.swift in Sources */",
        "watchOS target source": "37A100000000000000000102 /* WatchMetricProvider.swift in Sources */",
        "iOSTests source": "37A900000000000000000101 /* WatchMetricProviderTests.swift in Sources */",
    }
    for label, token in placement_checks.items():
        if text.count(token) >= 1:
            pass_msg(f"project membership placement token found: {label}")
        else:
            fail(f"project membership placement token missing: {label}")

    for relative in ("Shared/WatchUI/WatchMetricProvider.swift", "Tests/iOSTests/WatchMetricProviderTests.swift"):
        if (repo / relative).exists():
            pass_msg(f"relative path resolves: {relative}")
        else:
            fail(f"relative path does not resolve: {relative}")


def count_forbidden_source_patterns(repo: Path) -> int:
    count = 0
    for relative in SWIFT_FILES_TO_SCAN:
        path = repo / relative
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for pattern in FORBIDDEN_SOURCE_PATTERNS:
            for match in re.finditer(pattern, text, flags=re.IGNORECASE):
                print(f"FORBIDDEN_SCOPE_TOKEN={relative}:{match.group(0)}")
                count += 1
    return count


def mode_aware_provider_present(provider_text: str, test_text: str) -> bool:
    required = (
        "WatchMetricActivityMode(descriptor:",
        "case .skateboard, .inline:",
        "case .unsupported",
        "WatchMetricProviderSelector(providers:",
        "testCustomProviderCanSupportFutureModeWithoutChangingBaseProvider",
    )
    return all(token in provider_text or token in test_text for token in required)


def snow_provider_implemented(repo: Path) -> bool:
    combined = ""
    for relative in SWIFT_FILES_TO_SCAN:
        path = repo / relative
        if path.exists():
            combined += "\n" + path.read_text(encoding="utf-8")
    return bool(re.search(r"snow|ski", combined, flags=re.IGNORECASE))


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    if not (repo / "SkateTrack.xcodeproj/project.pbxproj").exists():
        fail(f"repo path does not look like SkateTrack: {repo}")

    branch = run_git(["branch", "--show-current"], repo)
    if branch == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-037a verification")
    else:
        fail(f"current branch is {branch}, expected {EXPECTED_BRANCH}")

    merge_base_check = subprocess.run(
        ["git", "merge-base", "--is-ancestor", EXPECTED_BASE_HEAD, "HEAD"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if merge_base_check.returncode == 0:
        pass_msg("Task-037a branch contains expected Task-036 develop base")
    else:
        fail("Task-037a branch does not contain expected Task-036 develop base")

    for relative in REQUIRED_FILES:
        if (repo / relative).exists():
            pass_msg(f"required file exists: {relative}")
        else:
            fail(f"required file missing: {relative}")

    verify_changed_paths(repo)
    verify_headers_and_line_limits(repo)

    provider = repo / "Shared/WatchUI/WatchMetricProvider.swift"
    tests = repo / "Tests/iOSTests/WatchMetricProviderTests.swift"
    provider_text = provider.read_text(encoding="utf-8") if provider.exists() else ""
    test_text = tests.read_text(encoding="utf-8") if tests.exists() else ""

    if provider.exists():
        require_contains(provider, PROVIDER_REQUIRED_TOKENS)
    if tests.exists():
        require_contains(tests, TEST_REQUIRED_TOKENS)

    verify_project_membership(repo)

    for relative in (
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/process/PHASE_1B_AGENT_STATE.md",
    ):
        path = repo / relative
        if path.exists():
            require_contains(path, DOC_REQUIRED_TOKENS)

    forbidden_count = count_forbidden_source_patterns(repo)
    if forbidden_count == 0:
        pass_msg("Task-037a provider/test files contain no forbidden scope tokens")
    else:
        fail("Task-037a provider/test files contain forbidden scope tokens")

    mode_aware = mode_aware_provider_present(provider_text, test_text)
    snow_done = snow_provider_implemented(repo)

    print(f"MODE_AWARE_PROVIDER_PRESENT={'YES' if mode_aware else 'NO'}")
    print(f"SNOW_PROVIDER_IMPLEMENTED={'YES' if snow_done else 'NO'}")
    print(f"FORBIDDEN_SCOPE_COUNT={forbidden_count}")
    print(f"FAILURE_COUNT={failure_count}")

    if failure_count == 0 and mode_aware and not snow_done and forbidden_count == 0:
        print("VERIFY_TASK037A_METRIC_PROVIDER_PROTOCOL_RESULT=PASSED")
        return 0

    print("VERIFY_TASK037A_METRIC_PROVIDER_PROTOCOL_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
