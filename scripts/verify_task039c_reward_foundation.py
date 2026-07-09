#!/usr/bin/env python3
# [Collaboration] scripts/verify_task039c_reward_foundation.py
"""Verifier for Task-039c Early-Bird Reward Foundation."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "codex/task-039c-reward-foundation"
EXPECTED_BASE_HEAD = "c2102844b1efb2e3fb322aa2d2cf9ae26478b977"

ALLOWED_CHANGED_PATHS = {
    "Shared/WatchUI/WatchRewardFoundationState.swift",
    "Tests/iOSTests/WatchRewardFoundationStateTests.swift",
    "scripts/verify_task039c_reward_foundation.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchRewardFoundationState.swift",
    "Tests/iOSTests/WatchRewardFoundationStateTests.swift",
    "scripts/verify_task039c_reward_foundation.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchRewardFoundationState.swift",
    "Tests/iOSTests/WatchRewardFoundationStateTests.swift",
]

PRODUCT_SCAN_FILES = [
    "Shared/WatchUI/WatchRewardFoundationState.swift",
    "Tests/iOSTests/WatchRewardFoundationStateTests.swift",
]

FORBIDDEN_PATH_PARTS = [
    "Shared/ActivityVisualization/",
    "Shared/Models/",
    "Shared/Persistence/",
    "Shared/Export/",
    "Shared/WatchSensors/",
    "Shared/WatchBridge/",
    "iOS/Core/",
    "iOS/Features/",
    "watchOS/Features/",
    "macOS/",
    "Snow",
    "StoreKit",
    "HealthKit",
    "RouteDisplay",
    "SpeedDisplay",
    "ElevationDisplay",
    "SessionMetricsAccumulator",
    "SensorFusionEngine",
    "MotionSample",
    "SessionData",
    "SkateTrackPackage",
    ".xcdatamodeld",
]

STOREKIT_PATTERNS = [
    r"\bimport\s+StoreKit\b",
    r"\bStoreKit\b",
    r"\bProduct\b",
    r"\bTransaction\b",
    r"\bAppStore\b",
    r"\bsubscription\b",
    r"\bpaywall\b",
    r"\bpurchase\w*\b",
]

FORBIDDEN_RUNTIME_PATTERNS = [
    r"\bimport\s+HealthKit\b",
    r"\bimport\s+WidgetKit\b",
    r"\bimport\s+ClockKit\b",
    r"\bHKHealthStore\b",
    r"\bSessionRecordingCoordinator\b",
    r"\bSensorFusionEngine\b",
    r"\bWatchBridgeCommandEnvelope\s*\(",
    r"\bstartSession\s*\(",
]

RELEASE_CLAIM_PATTERNS = [
    r"\breward[s]?\s+(are|is)\s+(live|active|available|shipping|released|ready)\b",
    r"\bproduction\s+reward[s]?\b",
    r"\bApp\s+Store\s+reward[s]?\b",
    r"\bmarketing\s+campaign\b",
    r"\bearly[- ]bird\s+reward[s]?\s+(are|is)\s+(live|active|available|shipping|released|ready)\b",
]

PROJECT_FORBIDDEN_PATTERNS = [
    r"NSExtension",
    r"com\.apple\.developer\.in-app-payments",
    r"com\.apple\.developer\.storekit",
    r"PRODUCT_BUNDLE_IDENTIFIER[\s=]+[^;\n]*(reward|store|purchase)",
]

failures: list[str] = []
storekit_dependency_count = 0
release_claim_count = 0
runtime_usage_count = 0


def run_git(args: list[str]) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def record(condition: bool, message: str) -> None:
    if condition:
        print(f"PASS: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8", errors="replace")


def changed_paths() -> set[str]:
    diff = run_git(["diff", "--name-only", EXPECTED_BASE_HEAD]).splitlines()
    untracked = run_git(["ls-files", "--others", "--exclude-standard"]).splitlines()
    return {path for path in diff + untracked if path}


def git_diff_for(path: str) -> str:
    return subprocess.check_output(["git", "diff", EXPECTED_BASE_HEAD, "--", path], cwd=ROOT, text=True)


def regex_count(patterns: list[str], text: str) -> int:
    return sum(len(re.findall(pattern, text, flags=re.IGNORECASE)) for pattern in patterns)


def check_baseline() -> None:
    branch = run_git(["branch", "--show-current"])
    head = run_git(["rev-parse", "HEAD"])
    base_merge = run_git(["merge-base", "HEAD", EXPECTED_BASE_HEAD])
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD={head}")
    print(f"EXPECTED_BASE_HEAD={EXPECTED_BASE_HEAD}")
    record(branch == EXPECTED_BRANCH, "current branch matches Task-039c branch")
    record(head == EXPECTED_BASE_HEAD, "current HEAD remains at Task-039c base before commit")
    record(base_merge == EXPECTED_BASE_HEAD, "Task-039c branch is based on Task-039b head")


def check_allowed_paths(paths: set[str]) -> None:
    print("TASK039C_CHANGED_PATHS=" + ",".join(sorted(paths)))
    for path in sorted(paths):
        record(path in ALLOWED_CHANGED_PATHS, f"changed path allowed: {path}")
        record(
            not any(part in path for part in FORBIDDEN_PATH_PARTS),
            f"changed path avoids forbidden scope: {path}",
        )


def check_required_files() -> None:
    for path in REQUIRED_FILES:
        record((ROOT / path).exists(), f"required file exists: {path}")


def check_headers_and_lines() -> None:
    for path in SWIFT_FILES:
        lines = read(path).splitlines()
        first = lines[0] if lines else ""
        print(f"LINE_COUNT[{path}]={len(lines)}")
        record(
            first.startswith("// [協作區]") or first.startswith("// [自主區]"),
            f"{path} has required collaboration header",
        )
        record(len(lines) <= 500, f"{path} line count <= 500")

    verifier_lines = len(read("scripts/verify_task039c_reward_foundation.py").splitlines())
    print(f"LINE_COUNT[scripts/verify_task039c_reward_foundation.py]={verifier_lines}")
    record(verifier_lines <= 500, "Task-039c verifier line count <= 500")


def check_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    tokens = [
        "39C100000000000000000001 /* WatchRewardFoundationState.swift */",
        "39C100000000000000000101 /* WatchRewardFoundationState.swift in Sources */",
        "39C100000000000000000102 /* WatchRewardFoundationState.swift in Sources */",
        "39C900000000000000000001 /* WatchRewardFoundationStateTests.swift */",
        "39C900000000000000000101 /* WatchRewardFoundationStateTests.swift in Sources */",
    ]
    for token in tokens:
        record(token in project, f"project contains membership token: {token}")

    watchui_group = re.search(r"36A000000000000000000000 /\* WatchUI \*/ = \{.*?\n\t\t\};", project, re.S)
    tests_group = re.search(r"12AC02000000000000000001 /\* iOSTests \*/ = \{.*?\n\t\t\};", project, re.S)
    record(watchui_group is not None and "WatchRewardFoundationState.swift" in watchui_group.group(0), "state file is in WatchUI group")
    record(tests_group is not None and "WatchRewardFoundationStateTests.swift" in tests_group.group(0), "test file is in iOSTests group")

    for path in [
        "Shared/WatchUI/WatchRewardFoundationState.swift",
        "Tests/iOSTests/WatchRewardFoundationStateTests.swift",
    ]:
        record((ROOT / path).exists(), f"project member path resolves on disk: {path}")


def check_source_tokens() -> None:
    state = read("Shared/WatchUI/WatchRewardFoundationState.swift")
    tests = read("Tests/iOSTests/WatchRewardFoundationStateTests.swift")

    for token in [
        "enum WatchRewardFoundationAvailability",
        "case localShellOnly",
        "enum WatchRewardFoundationEntryKind",
        "case firstSession",
        "case steadyWeek",
        "case safetyReview",
        "usesMonetizationFramework",
        "usesProductionMonetization",
        "grantsEntitlement",
        "unlocksPaidFeatures",
        "exposesReleaseClaim",
        "syncsRemoteRewardState",
    ]:
        record(token in state, f"state contains token: {token}")

    for token in [
        "testLocalShellIsNonMonetizedAndLocalOnly",
        "testDefaultEntriesArePresentAndUnearned",
        "testProgressIsClampedToLocalDisplayRange",
        "testCodableRoundTripPreservesLocalState",
    ]:
        record(token in tests, f"tests contain token: {token}")


def check_forbidden_scope() -> None:
    global storekit_dependency_count, release_claim_count, runtime_usage_count
    product_text = "\n".join(read(path) for path in PRODUCT_SCAN_FILES if (ROOT / path).exists())
    project_diff = git_diff_for("SkateTrack.xcodeproj/project.pbxproj")

    storekit_dependency_count = regex_count(STOREKIT_PATTERNS, product_text + "\n" + project_diff)
    release_claim_count = regex_count(RELEASE_CLAIM_PATTERNS, product_text)
    runtime_usage_count = regex_count(FORBIDDEN_RUNTIME_PATTERNS, product_text + "\n" + project_diff)
    snow_count = regex_count([r"\bSnow\w*\b"], product_text)

    print(f"STOREKIT_DEPENDENCY_COUNT={storekit_dependency_count}")
    print(f"RELEASE_CLAIM_COUNT={release_claim_count}")
    print(f"FORBIDDEN_RUNTIME_USAGE_COUNT={runtime_usage_count}")
    print(f"SNOW_SCOPE_TOKEN_COUNT={snow_count}")
    record(storekit_dependency_count == 0, "no StoreKit, paywall, purchase, transaction, or subscription dependency")
    record(release_claim_count == 0, "no release or marketing reward claims")
    record(runtime_usage_count == 0, "no forbidden runtime/session/provider APIs")
    record(snow_count == 0, "no Snow scope tokens in Task-039c product/test files")


def check_docs() -> None:
    doc_expectations = {
        "docs/history/DEV_LOG.md": [
            "TASK039C_REWARD_FOUNDATION_START",
            "VERIFY_TASK039C_REWARD_FOUNDATION_RESULT=PASSED",
            "STOREKIT_DEPENDENCY_COUNT=0",
            "NEXT_TASK=Task-040a",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "TASK039C_REWARD_FOUNDATION_START",
            "Shared/WatchUI/WatchRewardFoundationState.swift",
            "scripts/verify_task039c_reward_foundation.py",
            "NEXT_TASK=Task-040a",
        ],
        "docs/process/PHASE_1B_AGENT_STATE.md": [
            "TASK039C_REWARD_FOUNDATION_START",
            "WATCH_REWARD_FOUNDATION_PRESENT=YES",
            "STOREKIT_DEPENDENCY_COUNT=0",
            "MANUAL_QA_TASK039C_REWARD_FOUNDATION=NOT_REQUIRED_STATE_ONLY",
            "NEXT_TASK=Task-040a",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "TASK039C_PRE_ADP_LIMITATIONS_START",
            "WATCH_REWARD_FOUNDATION_LOCAL_ONLY=YES",
            "PRODUCTION_STOREKIT_REWARD_DEPENDENCY=NO",
        ],
    }

    for path, tokens in doc_expectations.items():
        text = read(path)
        for token in tokens:
            record(token in text, f"{path} contains {token}")


def main() -> int:
    print("===== Task-039c Early-Bird Reward Foundation verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-039c — Early-Bird Reward Foundation")
    print("Not implementing: production StoreKit, paywall, purchase flow, subscription, rewards economy, Task-040 QA, Snow, HealthKit, Watch-side direct session start, schema/package mutation")

    paths = changed_paths()
    check_baseline()
    check_allowed_paths(paths)
    check_required_files()
    check_headers_and_lines()
    check_project_membership()
    check_source_tokens()
    check_forbidden_scope()
    check_docs()

    print(f"STOREKIT_DEPENDENCY_COUNT={storekit_dependency_count}")
    print(f"RELEASE_CLAIM_COUNT={release_claim_count}")
    print(f"FORBIDDEN_RUNTIME_USAGE_COUNT={runtime_usage_count}")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK039C_REWARD_FOUNDATION_RESULT=FAILED")
        for failure in failures:
            print(f"FAILURE: {failure}")
        return 1

    print("VERIFY_TASK039C_REWARD_FOUNDATION_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
