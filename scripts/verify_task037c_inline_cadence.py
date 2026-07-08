#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

EXPECTED_BRANCH = "task-037-metric-provider-carousel"
EXPECTED_TASK037B_HEAD = "acd563937daae305281eecacb3c2581eeb42cfbe"

ALLOWED_CHANGED_PATHS = {
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "watchOS/Features/WatchMetricCarouselView.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift",
    "scripts/verify_task037c_inline_cadence.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
}

SWIFT_FILES = [
    Path("Shared/WatchUI/WatchMetricProvider.swift"),
    Path("Shared/WatchUI/WatchMetricCarouselModel.swift"),
    Path("watchOS/Features/WatchMetricCarouselView.swift"),
    Path("Tests/iOSTests/WatchMetricProviderTests.swift"),
    Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift"),
]

REQUIRED_FILES = [
    *SWIFT_FILES,
    Path("scripts/verify_task037c_inline_cadence.py"),
    Path("docs/history/DEV_LOG.md"),
    Path("docs/reference/FILE_STRUCTURE.md"),
    Path("docs/process/PHASE_1B_AGENT_STATE.md"),
]

SOURCE_TOKENS = {
    Path("Shared/WatchUI/WatchMetricProvider.swift"): [
        "case cadence",
        "identifier: \"watch.metric.inline.cadence\"",
        "kind: .cadence",
        "titleLocalizationKey: \"session.hud.inline.cadence\"",
        "accessibilityIdentifier: \"watch-metric-provider-inline-cadence\"",
        "private func inlineCadenceAvailability",
        "return .unavailable(.missingCompactOutput)",
        "if context.activityMode == .inline",
    ],
    Path("Shared/WatchUI/WatchMetricCarouselModel.swift"): [
        "case .cadence:",
        "private static func cadenceCardModel",
        "accessibilityIdentifier: \"watch-metric-carousel-inline-cadence-card\"",
        "valueText: unavailableValueText",
        "unitLocalizationKey: nil",
        "sparklinePoints: []",
    ],
    Path("watchOS/Features/WatchMetricCarouselView.swift"): [
        "card.kind == .route || card.kind == .cadence",
        "case .cadence:",
        "return \"timer\"",
    ],
    Path("Tests/iOSTests/WatchMetricProviderTests.swift"): [
        "testInlineCadenceStaysUnavailableEvenWhenCompactSpeedAndElevationExist",
        "[.route, .speed, .elevation, .cadence]",
        "XCTAssertNil(cadence?.speedSparkline)",
        "XCTAssertNil(cadence?.elevationProfile)",
        "XCTAssertNil(cadence?.compactRoute)",
    ],
    Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift"): [
        "testInlineCadenceCardAvoidsFalsePrecisionWhenCompactDataExists",
        "XCTAssertEqual(cadence?.valueText, \"--\")",
        "XCTAssertNil(cadence?.unitLocalizationKey)",
        "XCTAssertTrue(cadence?.sparklinePoints.isEmpty == true)",
    ],
}

DOC_TOKENS = [
    "TASK037C_INLINE_CADENCE_START",
    "VERIFY_TASK037C_INLINE_CADENCE_RESULT=PASSED",
    "UNAVAILABLE_STATE_PRESENT=YES",
    "FALSE_PRECISION_COPY_COUNT=0",
    "SNOW_METRIC_IMPLEMENTATION_COUNT=0",
    "NEXT_TASK=Task-037d",
]

FORBIDDEN_SCOPE_PATTERNS = [
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
    r"ストライド",
]


def run_git(args):
    return subprocess.run(["git", *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def read(path):
    return path.read_text(encoding="utf-8")


def fail(message):
    print(f"FAIL: {message}")
    return 1


def pass_msg(message):
    print(f"PASS: {message}")
    return 0


def changed_paths():
    paths = []
    diff = run_git(["diff", "--name-only"])
    if diff.returncode == 0:
        paths.extend([line.strip() for line in diff.stdout.splitlines() if line.strip()])
    cached = run_git(["diff", "--cached", "--name-only"])
    if cached.returncode == 0:
        paths.extend([line.strip() for line in cached.stdout.splitlines() if line.strip()])
    untracked = run_git(["ls-files", "--others", "--exclude-standard"])
    if untracked.returncode == 0:
        paths.extend([line.strip() for line in untracked.stdout.splitlines() if line.strip()])
    return sorted(set(paths))


def main():
    failures = 0

    branch = run_git(["branch", "--show-current"])
    if branch.returncode == 0 and branch.stdout.strip() == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-037c verification")
    else:
        failures += fail(f"expected branch {EXPECTED_BRANCH}, got {branch.stdout.strip()!r}")

    merge_base = run_git(["merge-base", "--is-ancestor", EXPECTED_TASK037B_HEAD, "HEAD"])
    if merge_base.returncode == 0:
        pass_msg("Task-037c branch contains expected Task-037b commit")
    else:
        failures += fail(f"expected Task-037b head {EXPECTED_TASK037B_HEAD} is not reachable from HEAD")

    changed = changed_paths()
    print("TASK037C_CHANGED_PATHS=" + ",".join(changed))
    for path in changed:
        if path in ALLOWED_CHANGED_PATHS:
            pass_msg(f"changed path allowed for Task-037c: {path}")
        else:
            failures += fail(f"unexpected changed path for Task-037c: {path}")

    for path in REQUIRED_FILES:
        if path.exists():
            pass_msg(f"required file exists: {path}")
        else:
            failures += fail(f"missing required file: {path}")

    for path in SWIFT_FILES:
        if not path.exists():
            continue
        lines = read(path).splitlines()
        header_ok = bool(lines) and "// [協作區]" in lines[0]
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

    provider_text = read(Path("Shared/WatchUI/WatchMetricProvider.swift")) if Path("Shared/WatchUI/WatchMetricProvider.swift").exists() else ""
    skateboard_only_three = "if context.activityMode == .inline" in provider_text and "outputs.append(cadenceOutput(context: context))" in provider_text
    if skateboard_only_three:
        pass_msg("inline cadence is appended only for inline mode")
    else:
        failures += fail("inline cadence output is not mode-gated")

    scan_text = "\n".join(read(path) for path in SWIFT_FILES if path.exists())
    unavailable_state_present = all(
        token in scan_text for token in [
            "case cadence",
            "return .unavailable(.missingCompactOutput)",
            "XCTAssertEqual(cadence?.valueText, \"--\")",
        ]
    )
    if unavailable_state_present:
        print("UNAVAILABLE_STATE_PRESENT=YES")
    else:
        print("UNAVAILABLE_STATE_PRESENT=NO")
        failures += fail("inline cadence unavailable state is incomplete")

    false_precision_count = 0
    for path in SWIFT_FILES:
        text = read(path).lower() if path.exists() else ""
        for pattern in FALSE_PRECISION_PATTERNS:
            false_precision_count += len(re.findall(pattern, text, flags=re.IGNORECASE))
    print(f"FALSE_PRECISION_COPY_COUNT={false_precision_count}")
    if false_precision_count == 0:
        pass_msg("cadence copy avoids false precision")
    else:
        failures += fail("cadence copy contains false precision unit/copy")

    forbidden_count = 0
    snow_metric_count = 0
    for path in SWIFT_FILES:
        text = read(path).lower() if path.exists() else ""
        snow_metric_count += len(re.findall(r"\bsnow\b", text, flags=re.IGNORECASE))
        for pattern in FORBIDDEN_SCOPE_PATTERNS:
            forbidden_count += len(re.findall(pattern, text, flags=re.IGNORECASE))
    print(f"SNOW_METRIC_IMPLEMENTATION_COUNT={snow_metric_count}")
    print(f"FORBIDDEN_SCOPE_COUNT={forbidden_count}")
    if forbidden_count == 0:
        pass_msg("Task-037c Swift/test files contain no forbidden scope tokens")
    else:
        failures += fail("Task-037c Swift/test files contain forbidden scope tokens")

    for path in [Path("docs/history/DEV_LOG.md"), Path("docs/reference/FILE_STRUCTURE.md"), Path("docs/process/PHASE_1B_AGENT_STATE.md")]:
        text = read(path) if path.exists() else ""
        for token in DOC_TOKENS:
            if token in text:
                pass_msg(f"{path} contains {token}")
            else:
                failures += fail(f"{path} missing docs token: {token}")

    print(f"FAILURE_COUNT={failures}")
    if failures == 0:
        print("VERIFY_TASK037C_INLINE_CADENCE_RESULT=PASSED")
        return 0
    print("VERIFY_TASK037C_INLINE_CADENCE_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
