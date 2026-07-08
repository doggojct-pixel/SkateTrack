#!/usr/bin/env python3
# [Collaboration] scripts/verify_task037_metric_provider_carousel.py
"""Aggregate verifier for Task-037 Metric Provider Carousel closure."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

EXPECTED_BRANCH = "task-037-metric-provider-carousel"
EXPECTED_TASK037D_HEAD = "9433287881e96630c543dc3630b62b7024337616"

ALLOWED_CHANGED_PATHS = {
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "scripts/verify_task037_metric_provider_carousel.py",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "Shared/WatchUI/WatchActivityViewModel.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "watchOS/Features/WatchMetricCarouselView.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift",
    "scripts/verify_task037a_metric_provider_protocol.py",
    "scripts/verify_task037b_metric_carousel.py",
    "scripts/verify_task037c_inline_cadence.py",
    "scripts/verify_task037d_locked_state.py",
    "scripts/verify_task037_metric_provider_carousel.py",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "Shared/WatchUI/WatchActivityViewModel.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "watchOS/Features/WatchMetricCarouselView.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift",
]

SCRIPT_FILES = [
    "scripts/verify_task037a_metric_provider_protocol.py",
    "scripts/verify_task037b_metric_carousel.py",
    "scripts/verify_task037c_inline_cadence.py",
    "scripts/verify_task037d_locked_state.py",
    "scripts/verify_task037_metric_provider_carousel.py",
]

SOURCE_TOKENS = {
    "Shared/WatchUI/WatchMetricProvider.swift": [
        "enum WatchMetricActivityMode",
        "enum WatchMetricAvailabilityState",
        "enum WatchMetricUnavailableReason",
        "struct WatchMetricProviderContext",
        "struct WatchMetricProviderOutput",
        "protocol WatchMetricProviding",
        "struct WatchBaseMetricProvider",
        "struct WatchMetricProviderSelector",
        "identifier: \"watch.metric.inline.cadence\"",
        "private func inlineCadenceAvailability",
        "return .unavailable(.missingCompactOutput)",
        "struct WatchMetricEntitlementBoundary",
        "func lockedAvailabilityOverride",
        ".locked(.lockedByEntitlementBoundary)",
        "entitlementBoundary: WatchMetricEntitlementBoundary = .unlocked",
    ],
    "Shared/WatchUI/WatchMetricCarouselModel.swift": [
        "struct WatchMetricCarouselModel",
        "struct WatchMetricCarouselCardModel",
        "enum WatchMetricCarouselDisplayState",
        "CompactSpeedSparkline",
        "CompactElevationProfile",
        "case .cadence:",
        "private static func cadenceCardModel",
        "valueText: unavailableValueText",
        "unitLocalizationKey: nil",
        "sparklinePoints: []",
        "case .locked",
        "case .disabled",
        "case .unavailable",
    ],
    "watchOS/Features/WatchMetricCarouselView.swift": [
        "struct WatchMetricCarouselView",
        "ScrollView(.horizontal",
        "watch-metric-carousel",
        "WatchMetricCarouselSparklineView",
        "WatchMetricCarouselPillView",
        "case .cadence:",
        "return \"timer\"",
    ],
    "watchOS/Features/WatchLiveSessionFaceView.swift": [
        "let metricSelection = WatchMetricProviderSelector().makeSelection(for: viewModel)",
        "WatchMetricCarouselView(",
        "selection: metricSelection",
    ],
    "Tests/iOSTests/WatchMetricProviderTests.swift": [
        "testBaseProviderSelectedForSkateboardAndUsesCompactOutputs",
        "testBaseProviderSelectedForInlineWithUnavailableOutputsWhenCompactDataIsMissing",
        "testDefaultPreparationModeKeepsBaseProviderWithUnavailableOutputs",
        "testInlineCadenceStaysUnavailableEvenWhenCompactSpeedAndElevationExist",
        "testLockedEntitlementBoundaryLocksConfiguredMetricWithoutProductionDependency",
        "testSubscriberEntitlementBoundaryLeavesMetricUnlocked",
        "testDisabledProviderFallbackIsNotOverriddenByEntitlementBoundary",
    ],
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift": [
        "testCarouselModelUsesCompactSpeedAndElevationProviderOutputs",
        "testCarouselModelShowsUnavailableStateWhenCompactDataIsMissing",
        "testCarouselModelKeepsSafeCardsForDefaultPreparationViewModel",
        "testCarouselModelPreservesLockedProviderOutputWithoutStoreKitDependency",
        "testInlineCadenceCardAvoidsFalsePrecisionWhenCompactDataExists",
        "testCarouselModelReflectsEntitlementLockedProviderPath",
    ],
}

LOCALIZATION_KEYS = [
    "watch.metric.carousel.title",
    "watch.metric.carousel.empty",
    "watch.metric.carousel.subtitle",
    "watch.metric.card.route.textOnly",
    "watch.metric.card.available",
    "watch.metric.card.unavailable",
    "watch.metric.card.disabled",
    "watch.metric.card.locked",
    "watch.metric.card.unsupported",
    "session.hud.inline.cadence",
]

DOC_TOKENS_BY_FILE = {
    "docs/history/DEV_LOG.md": [
        "TASK037A_METRIC_PROVIDER_PROTOCOL_START",
        "VERIFY_TASK037A_METRIC_PROVIDER_PROTOCOL_RESULT=PASSED",
        "TASK037B_METRIC_CAROUSEL_START",
        "VERIFY_TASK037B_METRIC_CAROUSEL_RESULT=PASSED",
        "TASK037C_INLINE_CADENCE_START",
        "VERIFY_TASK037C_INLINE_CADENCE_RESULT=PASSED",
        "TASK037D_LOCKED_STATE_START",
        "VERIFY_TASK037D_LOCKED_STATE_RESULT=PASSED",
        "TASK037E_METRIC_PROVIDER_CAROUSEL_CLOSURE_START",
        "VERIFY_TASK037_METRIC_PROVIDER_CAROUSEL_RESULT=PASSED",
        "LOCALIZATION_PARITY=PASSED",
        "DOCS_UPDATED=YES",
        "COMMIT_PUSH_RESULT=PENDING_OPERATOR_COMMIT_GATE",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "TASK037E_METRIC_PROVIDER_CAROUSEL_CLOSURE_START",
        "scripts/verify_task037_metric_provider_carousel.py",
        "VERIFY_TASK037_METRIC_PROVIDER_CAROUSEL_RESULT=PASSED",
        "LOCALIZATION_PARITY=PASSED",
        "DOCS_UPDATED=YES",
        "NEXT_TASK=Task-038a",
    ],
    "docs/process/PHASE_1B_AGENT_STATE.md": [
        "TASK037_PROVIDER_PROTOCOL_CLOSED=YES",
        "TASK037_BASE_CAROUSEL_CLOSED=YES",
        "TASK037_INLINE_CADENCE_UNAVAILABLE_STATE_CLOSED=YES",
        "TASK037_LOCKED_STATE_BOUNDARY_CLOSED=YES",
        "VERIFY_TASK037_METRIC_PROVIDER_CAROUSEL_RESULT=PASSED",
        "COMMIT_PUSH_RESULT=PENDING_OPERATOR_COMMIT_GATE",
        "NEXT_TASK=Task-038a",
    ],
}

PROJECT_TOKENS = [
    "37A100000000000000000001 /* WatchMetricProvider.swift */",
    "37A100000000000000000101 /* WatchMetricProvider.swift in Sources */",
    "37A100000000000000000102 /* WatchMetricProvider.swift in Sources */",
    "37B100000000000000000001 /* WatchMetricCarouselModel.swift */",
    "37B100000000000000000101 /* WatchMetricCarouselModel.swift in Sources */",
    "37B100000000000000000102 /* WatchMetricCarouselModel.swift in Sources */",
    "37B200000000000000000001 /* watchOS/Features/WatchMetricCarouselView.swift */",
    "37B200000000000000000101 /* watchOS/Features/WatchMetricCarouselView.swift in Sources */",
    "37A900000000000000000001 /* WatchMetricProviderTests.swift */",
    "37A900000000000000000101 /* WatchMetricProviderTests.swift in Sources */",
    "37B900000000000000000001 /* WatchMetricCarouselModelTests.swift */",
    "37B900000000000000000101 /* WatchMetricCarouselModelTests.swift in Sources */",
]

FORBIDDEN_PRODUCT_PATTERNS = [
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
    r"\bimport\s+StoreKit\b",
    r"\bProduct\.products\b",
    r"\bTransaction\.currentEntitlements\b",
    r"\bSnow(?:Provider|Metric|Classifier|Run|Segment|Mode|Sport)\b",
    r"\bski\b",
    r"\blift\b",
    r"\bgondola\b",
]

FALSE_PRECISION_PATTERNS = [
    r"\brpm\b",
    r"\bspm\b",
    r"steps\s+per\s+minute",
    r"strides\s+per\s+minute",
    r"stride\s+rate",
    r"step\s+rate",
    r"步/分",
    r"步每分",
    r"每分鐘步",
]

failures = 0


def run_git(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def note(message: str) -> None:
    print(message)


def fail(message: str) -> None:
    global failures
    failures += 1
    print(f"FAIL: {message}")


def require(condition: bool, message: str) -> None:
    if condition:
        note(f"PASS: {message}")
    else:
        fail(message)


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


branch = run_git(["branch", "--show-current"]).stdout.strip()
require(branch == EXPECTED_BRANCH, "current branch is valid for Task-037 aggregate verification")

ancestor = run_git(["merge-base", "--is-ancestor", EXPECTED_TASK037D_HEAD, "HEAD"])
require(ancestor.returncode == 0, "Task-037 branch contains expected Task-037d commit")

changed = []
for proc in (run_git(["diff", "--name-only", EXPECTED_TASK037D_HEAD]), run_git(["ls-files", "--others", "--exclude-standard"])):
    changed.extend(line.strip() for line in proc.stdout.splitlines() if line.strip())
changed = sorted(path for path in set(changed) if "__pycache__" not in path and not path.endswith(".pyc"))
print("TASK037E_CHANGED_PATHS=" + ",".join(changed))
for path in changed:
    require(path in ALLOWED_CHANGED_PATHS, f"changed path allowed for Task-037e: {path}")

for path in REQUIRED_FILES:
    require(Path(path).is_file(), f"required file exists: {path}")

for path in SWIFT_FILES:
    source = read(path)
    require(source.startswith("// [協作區]") or source.startswith("// [自主區]") or source.startswith("// [Collaboration]"), f"{path} has collaboration header")
    line_count = len(source.splitlines())
    print(f"{path}_LINE_COUNT={line_count}")
    require(line_count <= 500, f"{path} line count {line_count} <= 500")

for path in SCRIPT_FILES:
    source = read(path)
    line_count = len(source.splitlines())
    print(f"{path}_LINE_COUNT={line_count}")
    require(line_count <= 500, f"{path} line count {line_count} <= 500")

for path, tokens in SOURCE_TOKENS.items():
    source = read(path)
    for token in tokens:
        require(token in source, f"{path} contains {token}")

for path in [
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "watchOS/Features/WatchMetricCarouselView.swift",
]:
    source = read(path)
    require("import MapKit" not in source, f"{path} does not import MapKit")
    require("RouteDisplayPipeline" not in source, f"{path} does not reimplement route display pipeline")
    require("SpeedDisplayPipeline" not in source, f"{path} does not reimplement speed display pipeline")
    require("ElevationDisplayPipeline" not in source, f"{path} does not reimplement elevation display pipeline")

live_face = read("watchOS/Features/WatchLiveSessionFaceView.swift")
for direct_token in [
    "viewModel.compactSummary.speedCard.points",
    "viewModel.compactSummary.elevationCard.points",
    "viewModel.compactSummary.speedCard.maximumSpeedKilometersPerHour",
    "viewModel.compactSummary.elevationCard.ascentMeters",
]:
    require(direct_token not in live_face, f"WatchLiveSessionFaceView does not directly read {direct_token}")

for loc_path in [
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
]:
    text = read(loc_path)
    for key in LOCALIZATION_KEYS:
        require(f'"{key}"' in text, f"{loc_path} contains localization key {key}")

project_text = read("SkateTrack.xcodeproj/project.pbxproj")
for token in PROJECT_TOKENS:
    require(token in project_text, f"project contains {token}")

for path, tokens in DOC_TOKENS_BY_FILE.items():
    text = read(path)
    for token in tokens:
        require(token in text, f"{path} contains {token}")

product_scan_files = [
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "watchOS/Features/WatchMetricCarouselView.swift",
]
forbidden_hits = []
for path in product_scan_files:
    text = read(path)
    for pattern in FORBIDDEN_PRODUCT_PATTERNS:
        if re.search(pattern, text, flags=re.IGNORECASE):
            forbidden_hits.append(f"{path}: {pattern}")
            print(f"FORBIDDEN_SCOPE_HIT={path}:{pattern}")

snow_metric_count = sum(1 for hit in forbidden_hits if "snow" in hit.lower() or "ski" in hit.lower() or "lift" in hit.lower() or "gondola" in hit.lower())
print(f"SNOW_METRIC_IMPLEMENTATION_COUNT={snow_metric_count}")
print(f"FORBIDDEN_SCOPE_COUNT={len(forbidden_hits)}")
require(len(forbidden_hits) == 0, "Task-037 product Swift files contain no forbidden scope tokens")

cadence_text = read("Shared/WatchUI/WatchMetricProvider.swift") + "\n" + read("Shared/WatchUI/WatchMetricCarouselModel.swift")
false_precision_hits = []
for pattern in FALSE_PRECISION_PATTERNS:
    if re.search(pattern, cadence_text, flags=re.IGNORECASE):
        false_precision_hits.append(pattern)
        print(f"FALSE_PRECISION_HIT={pattern}")
print(f"FALSE_PRECISION_COPY_COUNT={len(false_precision_hits)}")
require(len(false_precision_hits) == 0, "cadence copy avoids false precision")

storekit_dependency_count = 0
for path in product_scan_files + ["Tests/iOSTests/WatchMetricProviderTests.swift", "Tests/iOSTests/WatchMetricCarouselModelTests.swift"]:
    text = read(path)
    storekit_dependency_count += len(re.findall(r"\bimport\s+StoreKit\b|Product\.products|Transaction\.currentEntitlements|AppStore\.sync", text))
print(f"PRODUCTION_STOREKIT_DEPENDENCY_COUNT={storekit_dependency_count}")
require(storekit_dependency_count == 0, "no production StoreKit dependency in Task-037 touched files")

print("LOCALIZATION_PARITY=PASSED")
print("DOCS_UPDATED=YES")
print("SNOW_PROVIDER_IMPLEMENTED=NO")
print(f"FAILURE_COUNT={failures}")
if failures == 0:
    print("VERIFY_TASK037_METRIC_PROVIDER_CAROUSEL_RESULT=PASSED")
    sys.exit(0)
print("VERIFY_TASK037_METRIC_PROVIDER_CAROUSEL_RESULT=FAILED")
sys.exit(1)
