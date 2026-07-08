#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

EXPECTED_BRANCH = "task-037-metric-provider-carousel"
EXPECTED_TASK037A_HEAD = "ab9450249aefa1759a539b00a9be166a83d618f1"

REQUIRED_FILES = [
    Path("Shared/WatchUI/WatchMetricProvider.swift"),
    Path("Shared/WatchUI/WatchMetricCarouselModel.swift"),
    Path("watchOS/Features/WatchLiveSessionFaceView.swift"),
    Path("watchOS/Features/WatchMetricCarouselView.swift"),
    Path("Tests/iOSTests/WatchMetricProviderTests.swift"),
    Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift"),
    Path("scripts/verify_task037a_metric_provider_protocol.py"),
    Path("scripts/verify_task037b_metric_carousel.py"),
    Path("Shared/Localization/en.lproj/Localizable.strings"),
    Path("Shared/Localization/zh-Hant.lproj/Localizable.strings"),
    Path("Shared/Localization/ja.lproj/Localizable.strings"),
    Path("docs/history/DEV_LOG.md"),
    Path("docs/reference/FILE_STRUCTURE.md"),
    Path("docs/process/PHASE_1B_AGENT_STATE.md"),
    Path("SkateTrack.xcodeproj/project.pbxproj"),
]

SWIFT_FILES = [
    Path("Shared/WatchUI/WatchMetricProvider.swift"),
    Path("Shared/WatchUI/WatchMetricCarouselModel.swift"),
    Path("watchOS/Features/WatchLiveSessionFaceView.swift"),
    Path("watchOS/Features/WatchMetricCarouselView.swift"),
    Path("Tests/iOSTests/WatchMetricProviderTests.swift"),
    Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift"),
]

REQUIRED_LOCALIZATION_KEYS = [
    "watch.metric.carousel.title",
    "watch.metric.carousel.empty",
    "watch.metric.carousel.subtitle",
    "watch.metric.card.route.textOnly",
    "watch.metric.card.available",
    "watch.metric.card.unavailable",
    "watch.metric.card.disabled",
    "watch.metric.card.locked",
    "watch.metric.card.unsupported",
]

PROJECT_TOKENS = [
    "37B100000000000000000001 /* WatchMetricCarouselModel.swift */",
    "37B100000000000000000101 /* WatchMetricCarouselModel.swift in Sources */",
    "37B100000000000000000102 /* WatchMetricCarouselModel.swift in Sources */",
    "37B200000000000000000001 /* watchOS/Features/WatchMetricCarouselView.swift */",
    "37B200000000000000000101 /* watchOS/Features/WatchMetricCarouselView.swift in Sources */",
    "37B900000000000000000001 /* WatchMetricCarouselModelTests.swift */",
    "37B900000000000000000101 /* WatchMetricCarouselModelTests.swift in Sources */",
]

SOURCE_TOKENS = {
    Path("Shared/WatchUI/WatchMetricProvider.swift"): [
        "guard let normalized, !normalized.isEmpty else",
        "self = .skateboard",
    ],
    Path("Shared/WatchUI/WatchMetricCarouselModel.swift"): [
        "struct WatchMetricCarouselModel",
        "struct WatchMetricCarouselCardModel",
        "enum WatchMetricCarouselDisplayState",
        "WatchMetricProviderSelectionResult",
        "CompactSpeedSparkline",
        "CompactElevationProfile",
        "case .locked",
        "case .disabled",
        "case .unavailable",
    ],
    Path("watchOS/Features/WatchMetricCarouselView.swift"): [
        "struct WatchMetricCarouselView",
        "WatchMetricCarouselModel(selection: selection)",
        "ScrollView(.horizontal",
        "watch-metric-carousel",
        "WatchMetricCarouselSparklineView",
        "WatchMetricCarouselPillView",
        "watch.metric.carousel.subtitle",
    ],
    Path("watchOS/Features/WatchLiveSessionFaceView.swift"): [
        "let metricSelection = WatchMetricProviderSelector().makeSelection(for: viewModel)",
        "WatchMetricCarouselView(",
        "selection: metricSelection",
    ],
    Path("Tests/iOSTests/WatchMetricProviderTests.swift"): [
        "testDefaultPreparationModeKeepsBaseProviderWithUnavailableOutputs",
    ],
    Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift"): [
        "final class WatchMetricCarouselModelTests",
        "testCarouselModelUsesCompactSpeedAndElevationProviderOutputs",
        "testCarouselModelShowsUnavailableStateWhenCompactDataIsMissing",
        "testCarouselModelKeepsSafeCardsForDefaultPreparationViewModel",
        "testCarouselModelPreservesLockedProviderOutputWithoutStoreKitDependency",
        "testCarouselModelKeepsUnsupportedModeEmptyAndSafe",
        "CompactSpeedSparkline",
        "CompactElevationProfile",
    ],
}

DOC_TOKENS = [
    "TASK037B_METRIC_CAROUSEL_START",
    "VERIFY_TASK037B_METRIC_CAROUSEL_RESULT=PASSED",
    "COMPACT_SPEED_USAGE=YES",
    "COMPACT_ELEVATION_USAGE=YES",
    "SNOW_METRIC_IMPLEMENTATION_COUNT=0",
    "NEXT_TASK=Task-037c",
    "TASK037B_MANUALQA_UI_HOTFIX_003=YES",
    "DEFAULT_PREPARATION_CARDS_PRESENT=YES",
]

FORBIDDEN_SWIFT_PATTERNS = [
    r"\bimport\s+MapKit\b",
    r"\bMKMap",
    r"\bCLLocationCoordinate2D\b",
    r"\bRouteDisplayPipeline\b",
    r"\bSpeedDisplayPipeline\b",
    r"\bElevationDisplayPipeline\b",
    r"\bActivityVisualizationPipeline\b",
    r"\bHKHealthStore\b",
    r"\bHKWorkout\b",
    r"\bHKQuantitySample\b",
    r"\bStoreKit\b",
    r"\bsnow\b",
    r"\bski\b",
    r"\bsnowboard\b",
]


def run_git(args):
    return subprocess.run(["git", *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def fail(message):
    print(f"FAIL: {message}")
    return 1


def pass_msg(message):
    print(f"PASS: {message}")
    return 0


def read(path):
    return path.read_text(encoding="utf-8")


def main():
    failures = 0

    branch = run_git(["branch", "--show-current"])
    if branch.returncode == 0 and branch.stdout.strip() == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-037b verification")
    else:
        failures += fail(f"expected branch {EXPECTED_BRANCH}, got {branch.stdout.strip()!r}")

    merge_base = run_git(["merge-base", "--is-ancestor", EXPECTED_TASK037A_HEAD, "HEAD"])
    if merge_base.returncode == 0:
        pass_msg("Task-037b branch contains expected Task-037a commit")
    else:
        failures += fail(f"expected Task-037a head {EXPECTED_TASK037A_HEAD} is not reachable from HEAD")

    for path in REQUIRED_FILES:
        if path.exists():
            pass_msg(f"required file exists: {path}")
        else:
            failures += fail(f"missing required file: {path}")

    for path in SWIFT_FILES:
        if not path.exists():
            continue
        lines = read(path).splitlines()
        header_ok = bool(lines) and ("// [協作區]" in lines[0] or "// [Collaboration]" in lines[0])
        if header_ok:
            pass_msg(f"{path} has collaboration header")
        else:
            failures += fail(f"{path} missing collaboration header")
        if len(lines) <= 500:
            pass_msg(f"{path} line count {len(lines)} <= 500")
        else:
            failures += fail(f"{path} line count {len(lines)} exceeds 500")

    for path, tokens in SOURCE_TOKENS.items():
        text = read(path) if path.exists() else ""
        for token in tokens:
            if token in text:
                pass_msg(f"{path} contains {token}")
            else:
                failures += fail(f"{path} missing required token: {token}")

    face_text = read(Path("watchOS/Features/WatchLiveSessionFaceView.swift")) if Path("watchOS/Features/WatchLiveSessionFaceView.swift").exists() else ""
    direct_tokens = [
        "viewModel.compactSummary.speedCard.points",
        "viewModel.compactSummary.elevationCard.points",
        "viewModel.compactSummary.speedCard.maximumSpeedKilometersPerHour",
        "viewModel.compactSummary.elevationCard.ascentMeters",
    ]
    for token in direct_tokens:
        if token not in face_text:
            pass_msg(f"WatchLiveSessionFaceView no longer directly reads {token}")
        else:
            failures += fail(f"WatchLiveSessionFaceView still directly reads {token}")

    project = read(Path("SkateTrack.xcodeproj/project.pbxproj")) if Path("SkateTrack.xcodeproj/project.pbxproj").exists() else ""
    for token in PROJECT_TOKENS:
        if token in project:
            pass_msg(f"project contains {token}")
        else:
            failures += fail(f"project missing token: {token}")

    for path in [
        Path("Shared/WatchUI/WatchMetricCarouselModel.swift"),
        Path("watchOS/Features/WatchMetricCarouselView.swift"),
        Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift"),
    ]:
        if path.exists():
            pass_msg(f"relative path resolves: {path}")
        else:
            failures += fail(f"relative path does not resolve: {path}")

    for loc in ["en.lproj", "zh-Hant.lproj", "ja.lproj"]:
        path = Path("Shared/Localization") / loc / "Localizable.strings"
        text = read(path) if path.exists() else ""
        for key in REQUIRED_LOCALIZATION_KEYS:
            if f'"{key}"' in text:
                pass_msg(f"{path} contains localization key {key}")
            else:
                failures += fail(f"{path} missing localization key {key}")

    for path in [Path("docs/history/DEV_LOG.md"), Path("docs/reference/FILE_STRUCTURE.md"), Path("docs/process/PHASE_1B_AGENT_STATE.md")]:
        text = read(path) if path.exists() else ""
        for token in DOC_TOKENS:
            if token in text:
                pass_msg(f"{path} contains {token}")
            else:
                failures += fail(f"{path} missing docs token: {token}")

    forbidden_hits = []
    for path in SWIFT_FILES:
        if not path.exists():
            continue
        text = read(path)
        for pattern in FORBIDDEN_SWIFT_PATTERNS:
            for match in re.finditer(pattern, text, flags=re.IGNORECASE):
                forbidden_hits.append(f"{path}:{match.group(0)}")
    for hit in forbidden_hits:
        print(f"FORBIDDEN_SCOPE_HIT={hit}")
    if forbidden_hits:
        failures += fail("forbidden scope tokens found in Task-037b Swift/test files")
    else:
        pass_msg("Task-037b Swift/test files contain no forbidden scope tokens")

    compact_speed_usage = (
        "CompactSpeedSparkline" in (read(Path("Shared/WatchUI/WatchMetricCarouselModel.swift")) if Path("Shared/WatchUI/WatchMetricCarouselModel.swift").exists() else "")
        and ".compactSpeedSparkline" in (read(Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift")) if Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift").exists() else "")
    )
    compact_elevation_usage = (
        "CompactElevationProfile" in (read(Path("Shared/WatchUI/WatchMetricCarouselModel.swift")) if Path("Shared/WatchUI/WatchMetricCarouselModel.swift").exists() else "")
        and ".compactElevationProfile" in (read(Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift")) if Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift").exists() else "")
    )

    print(f"COMPACT_SPEED_USAGE={'YES' if compact_speed_usage else 'NO'}")
    print(f"COMPACT_ELEVATION_USAGE={'YES' if compact_elevation_usage else 'NO'}")
    print(f"SNOW_METRIC_IMPLEMENTATION_COUNT={len([h for h in forbidden_hits if 'snow' in h.lower() or 'ski' in h.lower()])}")
    print(f"FAILURE_COUNT={failures}")

    if failures == 0 and compact_speed_usage and compact_elevation_usage:
        print("VERIFY_TASK037B_METRIC_CAROUSEL_RESULT=PASSED")
        return 0

    print("VERIFY_TASK037B_METRIC_CAROUSEL_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
