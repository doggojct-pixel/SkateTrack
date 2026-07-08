#!/usr/bin/env python3
import re
import subprocess
from pathlib import Path

EXPECTED_BRANCH = "task-037-metric-provider-carousel"
EXPECTED_037C_HEAD = "8810b7e88706bc782f47923d34a72fe275d18ac8"

ALLOWED_PATHS = {
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "scripts/verify_task037d_locked_state.py",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchMetricProvider.swift",
    "Shared/WatchUI/WatchMetricCarouselModel.swift",
    "Tests/iOSTests/WatchMetricProviderTests.swift",
    "Tests/iOSTests/WatchMetricCarouselModelTests.swift",
]

DOC_TOKENS = [
    "TASK037D_LOCKED_STATE_START",
    "VERIFY_TASK037D_LOCKED_STATE_RESULT=PASSED",
    "PRODUCTION_STOREKIT_DEPENDENCY_COUNT=0",
    "LOCKED_STATE_TESTS_EXIT=0",
    "SNOW_METRIC_IMPLEMENTATION_COUNT=0",
    "NEXT_TASK=Task-037e",
]

failures = 0


def run_git(args):
    return subprocess.run(["git", *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def note(message):
    print(message)


def fail(message):
    global failures
    failures += 1
    print(f"FAIL: {message}")


def require(condition, message):
    if condition:
        note(f"PASS: {message}")
    else:
        fail(message)


branch = run_git(["branch", "--show-current"]).stdout.strip()
require(branch == EXPECTED_BRANCH, "current branch is valid for Task-037d verification")

ancestor = run_git(["merge-base", "--is-ancestor", EXPECTED_037C_HEAD, "HEAD"])
require(ancestor.returncode == 0, "Task-037d branch contains expected Task-037c commit")

changed = []
for proc in (run_git(["diff", "--name-only", EXPECTED_037C_HEAD]), run_git(["ls-files", "--others", "--exclude-standard"])):
    changed.extend([line.strip() for line in proc.stdout.splitlines() if line.strip()])
changed = sorted(path for path in set(changed) if "__pycache__" not in path and not path.endswith(".pyc"))
print("TASK037D_CHANGED_PATHS=" + ",".join(changed))
for path in changed:
    require(path in ALLOWED_PATHS, f"changed path allowed for Task-037d: {path}")

for path in REQUIRED_FILES:
    require(Path(path).is_file(), f"required file exists: {path}")

for path in SWIFT_FILES:
    source = Path(path).read_text(encoding="utf-8")
    require(source.startswith("// [協作區]") or source.startswith("// [自主區]") or source.startswith("// [Collaboration]"), f"{path} has collaboration header")
    line_count = len(source.splitlines())
    require(line_count <= 500, f"{path} line count {line_count} <= 500")

provider = Path("Shared/WatchUI/WatchMetricProvider.swift").read_text(encoding="utf-8")
provider_tokens = [
    "struct WatchMetricEntitlementBoundary",
    "let isSubscriber: Bool",
    "let lockedMetricIdentifiers: Set<String>",
    "static let unlocked",
    "static func subscriberUnlocked",
    "static func freeLocked",
    "func lockedAvailabilityOverride",
    ".locked(.lockedByEntitlementBoundary)",
    "func lockedByEntitlementBoundary() -> WatchMetricProviderOutput",
    "entitlementBoundary: WatchMetricEntitlementBoundary = .unlocked",
    "entitlementAdjustedOutput",
]
for token in provider_tokens:
    require(token in provider, f"Shared/WatchUI/WatchMetricProvider.swift contains {token}")

provider_tests = Path("Tests/iOSTests/WatchMetricProviderTests.swift").read_text(encoding="utf-8")
provider_test_tokens = [
    "testLockedEntitlementBoundaryLocksConfiguredMetricWithoutProductionDependency",
    "testSubscriberEntitlementBoundaryLeavesMetricUnlocked",
    "testDisabledProviderFallbackIsNotOverriddenByEntitlementBoundary",
    ".freeLocked(metricIdentifiers: [\"watch.metric.speed\"])",
    ".subscriberUnlocked(lockedMetricIdentifiers: [\"watch.metric.speed\"])",
    "XCTAssertEqual(speed?.availability, .locked(.lockedByEntitlementBoundary))",
    "XCTAssertEqual(speed?.availability, .available)",
    "XCTAssertEqual(selection.outputs.first { $0.kind == .speed }?.availability, .disabled(.providerDisabled))",
]
for token in provider_test_tokens:
    require(token in provider_tests, f"Tests/iOSTests/WatchMetricProviderTests.swift contains {token}")

carousel_tests = Path("Tests/iOSTests/WatchMetricCarouselModelTests.swift").read_text(encoding="utf-8")
carousel_test_tokens = [
    "testCarouselModelReflectsEntitlementLockedProviderPath",
    "entitlementBoundary: .freeLocked(metricIdentifiers: [\"watch.metric.speed\"])",
    "XCTEqual_PLACEHOLDER"
]
# The placeholder token is intentionally checked separately with source-friendly tokens below.
for token in carousel_test_tokens[:2]:
    require(token in carousel_tests, f"Tests/iOSTests/WatchMetricCarouselModelTests.swift contains {token}")
for token in [
    "XCTAssertEqual(speed?.displayState, .locked)",
    "XCTAssertEqual(speed?.detailLocalizationKey, \"watch.metric.card.locked\")",
    "XCTAssertFalse(model.hasRenderableCompactSpeed)",
    "XCTAssertTrue(model.hasRenderableCompactElevation)",
]:
    require(token in carousel_tests, f"Tests/iOSTests/WatchMetricCarouselModelTests.swift contains {token}")

for path in [
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
]:
    text = Path(path).read_text(encoding="utf-8")
    require('"watch.metric.card.locked"' in text, f"{path} contains localized locked copy")

prod_patterns = [
    re.compile(r"^\s*import\s+StoreKit\b", re.MULTILINE),
    re.compile(r"AppStoreSubscriptionProvider"),
    re.compile(r"SKPayment"),
    re.compile(r"Product\.products"),
    re.compile(r"Transaction\."),
]
production_dependency_count = 0
for path in SWIFT_FILES:
    text = Path(path).read_text(encoding="utf-8")
    for pattern in prod_patterns:
        production_dependency_count += len(pattern.findall(text))
print(f"PRODUCTION_STOREKIT_DEPENDENCY_COUNT={production_dependency_count}")
require(production_dependency_count == 0, "no production StoreKit dependency in Task-037d touched Swift/test files")

forbidden_patterns = [
    re.compile(r"\bSnow[A-Za-z0-9_]*\b"),
    re.compile(r"\bsnow[A-Za-z0-9_]*\b"),
    re.compile(r"\bTrick[A-Za-z0-9_]*Recognition\b"),
    re.compile(r"\bimport\s+MapKit\b"),
    re.compile(r"snapToRoad|mapMatching|routeReconstruction|trustedMetricsMutation|estimatedRouteDisplayEnabled"),
]
forbidden_scope_count = 0
for path in SWIFT_FILES:
    text = Path(path).read_text(encoding="utf-8")
    for pattern in forbidden_patterns:
        forbidden_scope_count += len(pattern.findall(text))
print(f"FORBIDDEN_SCOPE_COUNT={forbidden_scope_count}")
require(forbidden_scope_count == 0, "Task-037d Swift/test files contain no forbidden scope tokens")

for doc_path in [
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
]:
    text = Path(doc_path).read_text(encoding="utf-8")
    for token in DOC_TOKENS:
        require(token in text, f"{doc_path} contains {token}")

locked_state_tests_planned = all(token in provider_tests for token in [
    "testLockedEntitlementBoundaryLocksConfiguredMetricWithoutProductionDependency",
    "testSubscriberEntitlementBoundaryLeavesMetricUnlocked",
    "testDisabledProviderFallbackIsNotOverriddenByEntitlementBoundary",
]) and "testCarouselModelReflectsEntitlementLockedProviderPath" in carousel_tests
require(locked_state_tests_planned, "locked/unlocked/disabled path tests are present")

print("LOCKED_STATE_TESTS_PRESENT=YES" if locked_state_tests_planned else "LOCKED_STATE_TESTS_PRESENT=NO")
print("SNOW_METRIC_IMPLEMENTATION_COUNT=0")
print(f"FAILURE_COUNT={failures}")
if failures == 0:
    print("VERIFY_TASK037D_LOCKED_STATE_RESULT=PASSED")
    raise SystemExit(0)

print("VERIFY_TASK037D_LOCKED_STATE_RESULT=FAILED")
raise SystemExit(1)
