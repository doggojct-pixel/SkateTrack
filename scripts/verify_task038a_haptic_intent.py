#!/usr/bin/env python3
# [Collaboration] scripts/verify_task038a_haptic_intent.py
"""Verifier for Task-038a Haptic Intent Model."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

EXPECTED_BRANCH = "task-038-haptics-safety-shells"
EXPECTED_BASE_HEAD = "2f414119f3adc7bfd222ffd4d8917a058c48098b"

ALLOWED_CHANGED_PATHS = {
    "Shared/WatchUI/WatchLiveControlState.swift",
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
    "scripts/verify_task038a_haptic_intent.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchLiveControlState.swift",
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
    "scripts/verify_task038a_haptic_intent.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchLiveControlState.swift",
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
]

SOURCE_TOKENS = {
    "Shared/WatchUI/WatchLiveControlState.swift": [
        "enum WatchHapticIntentKind",
        "case sessionStart",
        "case commandRejected",
        "case safetyNotice",
        "enum WatchHapticIntentTargetSupport",
        "case unavailable",
        "case mockOnly",
        "case deviceSupported",
        "enum WatchHapticIntentDecisionState",
        "case scheduled",
        "case rateLimited",
        "case duplicateSuppressed",
        "struct WatchHapticIntent",
        "var duplicateSuppressionKey",
        "var isSensorDerivedClaim: Bool",
        "false",
        "struct WatchHapticIntentPolicy",
        "minimumIntervalSeconds",
        "duplicateSuppressionSeconds",
        "static let disabled",
        "static let mockOnly",
        "static func deviceSupported",
        "struct WatchHapticIntentDecision",
        "var shouldPlayOnDevice",
        "struct WatchHapticIntentGate",
        "lastAcceptedByKind",
        "lastAcceptedByDuplicateKey",
        "func resolve",
    ],
    "Tests/iOSTests/WatchActivityViewModelTests.swift": [
        "testHapticIntentSchedulesDevicePlaybackWithoutSensorClaim",
        "testHapticIntentRateLimitsRepeatedKindWithDifferentCorrelation",
        "testHapticIntentDuplicateSuppressionUsesCorrelationKey",
        "testHapticIntentFallsBackToMockOnlyWhenDevicePlaybackIsNotAvailable",
        "testHapticIntentIsDisabledWhenTargetSupportIsUnavailable",
        "XCTAssertEqual(second.state, .rateLimited)",
        "XCTAssertEqual(second.state, .duplicateSuppressed)",
        "XCTAssertEqual(decision.state, .mockOnly)",
        "XCTAssertEqual(decision.state, .disabled)",
        "XCTAssertFalse(decision.intent.isSensorDerivedClaim)",
    ],
}

DOC_TOKENS = [
    "TASK038A_HAPTIC_INTENT_START",
    "VERIFY_TASK038A_HAPTIC_INTENT_RESULT=PASSED",
    "RATE_LIMIT_PRESENT=YES",
    "DUPLICATE_SUPPRESSION_PRESENT=YES",
    "HAPTIC_TARGET_SUPPORT_BOUNDARY=MOCK_OR_DISABLED_WHEN_UNAVAILABLE",
    "HAPTIC_DEVICE_PLAYBACK_IMPLEMENTED=NO",
    "SENSOR_CLAIM_HAPTIC_TRIGGER_COUNT=0",
    "NEXT_TASK=Task-038b",
]

FORBIDDEN_PATTERNS = [
    r"\bWKInterfaceDevice\b",
    r"\.play\s*\(",
    r"\bimport\s+WatchKit\b",
    r"\bHKHealthStore\b",
    r"\bHKWorkout\b",
    r"\bimport\s+HealthKit\b",
    r"\bimport\s+StoreKit\b",
    r"\bSnowProvider\b",
    r"\bSnowMetric\b",
    r"\bSnowClassifier\b",
    r"\bMapKit\b",
    r"\bemergency service\b",
    r"\bautomatic emergency\b",
    r"\bmedical monitoring\b",
    r"\bdiagnos",
    r"\bfall detected\b",
]

failures: list[str] = []


def run_git(args: list[str]) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()


def check(condition: bool, message: str) -> None:
    if condition:
        print(f"PASS: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8", errors="replace")


def changed_paths() -> set[str]:
    changed = set(run_git(["diff", "--name-only", EXPECTED_BASE_HEAD]).splitlines())
    untracked = set(run_git(["ls-files", "--others", "--exclude-standard"]).splitlines())
    return {path for path in changed | untracked if path}


def check_branch_and_base() -> None:
    branch = run_git(["branch", "--show-current"])
    check(branch == EXPECTED_BRANCH, "current branch is valid for Task-038a verification")
    contains = subprocess.run(
        ["git", "merge-base", "--is-ancestor", EXPECTED_BASE_HEAD, "HEAD"],
        text=True,
    )
    check(contains.returncode == 0, "Task-038a branch contains expected Task-037 develop merge head")


def check_allowed_paths() -> None:
    paths = changed_paths()
    print("TASK038A_CHANGED_PATHS=" + ",".join(sorted(paths)))
    for path in sorted(paths):
        check(path in ALLOWED_CHANGED_PATHS, f"changed path allowed for Task-038a: {path}")
    missing = ALLOWED_CHANGED_PATHS - paths
    for path in sorted(missing):
        check(False, f"expected Task-038a changed path present: {path}")


def check_required_files() -> None:
    for path in REQUIRED_FILES:
        check(Path(path).exists(), f"required file exists: {path}")


def check_line_headers() -> None:
    for path in SWIFT_FILES:
        text = read(path)
        first_line = text.splitlines()[0] if text.splitlines() else ""
        check(
            first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]") or first_line.startswith("// [Collaboration]"),
            f"{path} has collaboration header",
        )
        line_count = len(text.splitlines())
        print(f"{path}_LINE_COUNT={line_count}")
        check(line_count <= 500, f"{path} line count {line_count} <= 500")

    verifier_lines = len(read("scripts/verify_task038a_haptic_intent.py").splitlines())
    print(f"scripts/verify_task038a_haptic_intent.py_LINE_COUNT={verifier_lines}")
    check(verifier_lines <= 500, "Task-038a verifier line count <= 500")


def check_tokens() -> None:
    for path, tokens in SOURCE_TOKENS.items():
        text = read(path)
        for token in tokens:
            check(token in text, f"{path} contains {token}")

    for doc in [
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/process/PHASE_1B_AGENT_STATE.md",
    ]:
        text = read(doc)
        for token in DOC_TOKENS:
            check(token in text, f"{doc} contains {token}")


def check_forbidden_scope() -> None:
    combined = "\n".join(read(path) for path in SWIFT_FILES)
    hits: list[str] = []
    for pattern in FORBIDDEN_PATTERNS:
        if re.search(pattern, combined, re.IGNORECASE):
            hits.append(pattern)

    print(f"FORBIDDEN_SCOPE_COUNT={len(hits)}")
    for hit in hits:
        print(f"FORBIDDEN_SCOPE_HIT={hit}")
    check(not hits, "Task-038a Swift/test files contain no forbidden haptic/safety scope tokens")


def check_policy_markers() -> None:
    text = read("Shared/WatchUI/WatchLiveControlState.swift")
    tests = read("Tests/iOSTests/WatchActivityViewModelTests.swift")

    rate_limit_present = "minimumIntervalSeconds" in text and ".rateLimited" in text and "testHapticIntentRateLimits" in tests
    duplicate_present = "duplicateSuppressionSeconds" in text and ".duplicateSuppressed" in text and "testHapticIntentDuplicateSuppression" in tests
    device_playback_implementation_count = len(re.findall(r"\bWKInterfaceDevice\b|\.play\s*\(", text))
    sensor_claim_count = 0
    if "isSensorDerivedClaim: Bool" not in text or "false" not in text:
        sensor_claim_count = 1

    print(f"RATE_LIMIT_PRESENT={'YES' if rate_limit_present else 'NO'}")
    print(f"DUPLICATE_SUPPRESSION_PRESENT={'YES' if duplicate_present else 'NO'}")
    print(f"HAPTIC_DEVICE_PLAYBACK_IMPLEMENTED={'NO' if device_playback_implementation_count == 0 else 'YES'}")
    print(f"SENSOR_CLAIM_HAPTIC_TRIGGER_COUNT={sensor_claim_count}")

    check(rate_limit_present, "rate limit model and tests are present")
    check(duplicate_present, "duplicate suppression model and tests are present")
    check(device_playback_implementation_count == 0, "no direct device haptic playback implementation")
    check(sensor_claim_count == 0, "haptic intents do not claim sensor-derived detection")


def main() -> int:
    check_branch_and_base()
    check_allowed_paths()
    check_required_files()
    check_line_headers()
    check_tokens()
    check_forbidden_scope()
    check_policy_markers()

    failure_count = len(failures)
    print(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0:
        print("VERIFY_TASK038A_HAPTIC_INTENT_RESULT=PASSED")
        return 0

    print("VERIFY_TASK038A_HAPTIC_INTENT_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
