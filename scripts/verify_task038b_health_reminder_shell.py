#!/usr/bin/env python3
# [Collaboration] scripts/verify_task038b_health_reminder_shell.py
"""Verifier for Task-038b Health Reminder Shell."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "task-038-haptics-safety-shells"
EXPECTED_HEAD = "b227fc4c8037f2752e194d354e172119acca2aac"

ALLOWED_CHANGED_PATHS = {
    "Shared/WatchUI/WatchHealthReminderShellState.swift",
    "watchOS/Features/WatchHealthReminderShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task038b_health_reminder_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "SkateTrack.xcodeproj/project.pbxproj",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchHealthReminderShellState.swift",
    "watchOS/Features/WatchHealthReminderShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
    "scripts/verify_task038b_health_reminder_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchHealthReminderShellState.swift",
    "watchOS/Features/WatchHealthReminderShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
]

LOCALIZATION_KEYS = [
    "watch.healthReminder.title",
    "watch.healthReminder.detail",
    "watch.healthReminder.status.disabled",
    "watch.healthReminder.status.shellOnly",
    "watch.healthReminder.hydration.title",
    "watch.healthReminder.hydration.detail",
    "watch.healthReminder.rest.title",
    "watch.healthReminder.rest.detail",
    "watch.healthReminder.stretch.title",
    "watch.healthReminder.stretch.detail",
    "watch.healthReminder.accessibility.label",
]

PRODUCT_SCAN_FILES = [
    "Shared/WatchUI/WatchHealthReminderShellState.swift",
    "watchOS/Features/WatchHealthReminderShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
]

HEALTHKIT_SCAN_FILES = PRODUCT_SCAN_FILES + [
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "SkateTrack.xcodeproj/project.pbxproj",
]

HEALTHKIT_PRODUCTION_PATTERNS = [
    r"\bimport\s+HealthKit\b",
    r"\bHKHealthStore\b",
    r"\bHKWorkout\b",
    r"\bHKLiveWorkoutBuilder\b",
    r"\bHKQuantitySample\b",
    r"com\.apple\.developer\.healthkit",
]

CLAIM_PATTERNS = [
    r"\bmedical\b",
    r"\bdiagnos\w*\b",
    r"\bprevent\w*\b",
    r"\btreat\w*\b",
    r"\bclinical\b",
    r"\bemergency\b",
    r"\brescue\b",
    r"\bfall[\s-]+detection\b",
    r"\balways[\s-]+on\s+safety\b",
    r"\bheart[\s-]+rate\s+monitoring\b",
]

FORBIDDEN_PATH_PARTS = [
    "Snow",
    "ActivityVisualization",
    "RouteDisplay",
    "SpeedDisplay",
    "ElevationDisplay",
    "SessionMetricsAccumulator",
    "SensorFusionEngine",
    "MotionSample",
    "SessionData",
    "SkateTrackPackage",
    ".xcdatamodeld",
    "StoreKit",
]

failures: list[str] = []


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
    diff = run_git(["diff", "--name-only", EXPECTED_HEAD]).splitlines()
    untracked = run_git(["ls-files", "--others", "--exclude-standard"]).splitlines()
    return {path for path in diff + untracked if path}


def regex_count(patterns: list[str], text: str) -> int:
    return sum(len(re.findall(pattern, text, flags=re.IGNORECASE)) for pattern in patterns)


def localized_values_for_task_keys() -> str:
    values: list[str] = []
    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            match = re.search(rf'"{re.escape(key)}"\s*=\s*"((?:\\.|[^"])*)";', text)
            if match:
                values.append(match.group(1))
    return "\n".join(values)


def check_baseline() -> None:
    branch = run_git(["branch", "--show-current"])
    head = run_git(["rev-parse", "HEAD"])
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD={head}")
    record(branch == EXPECTED_BRANCH, "current branch matches Task-038b branch")
    record(head == EXPECTED_HEAD, "current HEAD matches Task-038b expected baseline")


def check_allowed_paths(paths: set[str]) -> None:
    print("TASK038B_CHANGED_PATHS=" + ",".join(sorted(paths)))
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

    verifier_lines = len(read("scripts/verify_task038b_health_reminder_shell.py").splitlines())
    print(f"LINE_COUNT[scripts/verify_task038b_health_reminder_shell.py]={verifier_lines}")
    record(verifier_lines <= 500, "Task-038b verifier line count <= 500")


def check_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    membership_tokens = [
        "38B100000000000000000001 /* WatchHealthReminderShellState.swift */",
        "38B100000000000000000101 /* WatchHealthReminderShellState.swift in Sources */",
        "38B100000000000000000102 /* WatchHealthReminderShellState.swift in Sources */",
        "38B200000000000000000001 /* watchOS/Features/WatchHealthReminderShellView.swift */",
        "38B200000000000000000101 /* watchOS/Features/WatchHealthReminderShellView.swift in Sources */",
        "38B900000000000000000001 /* WatchHealthReminderShellStateTests.swift */",
        "38B900000000000000000101 /* WatchHealthReminderShellStateTests.swift in Sources */",
    ]
    for token in membership_tokens:
        record(token in project, f"project contains membership token: {token}")

    watchui_group = re.search(r"36A000000000000000000000 /\* WatchUI \*/ = \{.*?\n\t\t\};", project, re.S)
    tests_group = re.search(r"12AC02000000000000000001 /\* iOSTests \*/ = \{.*?\n\t\t\};", project, re.S)
    recovered_group = re.search(r"397B7DA02FFCFC78001AC43D /\* Recovered References \*/ = \{.*?\n\t\t\};", project, re.S)
    record(watchui_group is not None and "WatchHealthReminderShellState.swift" in watchui_group.group(0), "state file is in WatchUI group")
    record(tests_group is not None and "WatchHealthReminderShellStateTests.swift" in tests_group.group(0), "test file is in iOSTests group")
    record(recovered_group is not None and "WatchHealthReminderShellView.swift" in recovered_group.group(0), "watch view file is in watchOS references group")

    for path in [
        "Shared/WatchUI/WatchHealthReminderShellState.swift",
        "watchOS/Features/WatchHealthReminderShellView.swift",
        "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
    ]:
        record((ROOT / path).exists(), f"project member path resolves on disk: {path}")


def check_localization() -> None:
    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            record(f'"{key}"' in text, f"{language} localization contains {key}")


def check_source_tokens() -> None:
    state = read("Shared/WatchUI/WatchHealthReminderShellState.swift")
    view = read("watchOS/Features/WatchHealthReminderShellView.swift")
    tests = read("Tests/iOSTests/WatchHealthReminderShellStateTests.swift")
    live_face = read("watchOS/Features/WatchLiveSessionFaceView.swift")

    for token in [
        "enum WatchHealthReminderShellKind",
        "case hydration",
        "case rest",
        "case stretch",
        "allowsLiveBodyData",
        "requestsSensorAuthorization",
        "usesSensorDetection",
        "hapticPolicy: WatchHapticIntentPolicy = .mockOnly",
    ]:
        record(token in state, f"state contains token: {token}")

    record("WatchHealthReminderShellView" in view, "watch view type exists")
    record("WatchHealthReminderShellView(" in live_face, "live face integrates reminder shell")
    for token in [
        "testDefaultDisabledShellStateIsSafe",
        "testHydrationRestAndStretchReminderModelsArePresent",
        "testReminderCopyKeysAvoidRestrictedClaimLanguage",
        "testShellDoesNotIntroduceProductionHealthDataUsage",
        "testHapticIntentPolicyStaysMockOnlyAndIntentOnly",
    ]:
        record(token in tests, f"tests contain token: {token}")


def check_forbidden_scope() -> None:
    product_combined = "\n".join(read(path) for path in PRODUCT_SCAN_FILES if (ROOT / path).exists())
    product_combined += "\n" + localized_values_for_task_keys()
    healthkit_combined = "\n".join(read(path) for path in HEALTHKIT_SCAN_FILES if (ROOT / path).exists())
    healthkit_count = regex_count(HEALTHKIT_PRODUCTION_PATTERNS, healthkit_combined)
    medical_claim_count = regex_count(CLAIM_PATTERNS, product_combined)
    watchkit_haptic_count = regex_count([r"\bWKInterfaceDevice\b", r"\.play\s*\("], product_combined)

    print(f"HEALTHKIT_PRODUCTION_USAGE_COUNT={healthkit_count}")
    print(f"MEDICAL_CLAIM_COUNT={medical_claim_count}")
    print(f"WATCHKIT_HAPTIC_PLAYBACK_COUNT={watchkit_haptic_count}")
    record(healthkit_count == 0, "no production HealthKit usage tokens")
    record(medical_claim_count == 0, "no medical/emergency/fall promise copy in product scan")
    record(watchkit_haptic_count == 0, "no WatchKit haptic playback tokens")

    product_paths = [
        "Shared/WatchUI/WatchHealthReminderShellState.swift",
        "watchOS/Features/WatchHealthReminderShellView.swift",
        "watchOS/Features/WatchLiveSessionFaceView.swift",
        "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
    ]
    product_text = "\n".join(read(path) for path in product_paths)
    snow_count = regex_count([r"\bSnow\w*\b"], product_text)
    print(f"SNOW_SCOPE_TOKEN_COUNT={snow_count}")
    record(snow_count == 0, "no Snow scope in Task-038b product/test files")


def check_docs() -> None:
    for path in [
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/process/PHASE_1B_AGENT_STATE.md",
    ]:
        text = read(path)
        for token in [
            "TASK038B_HEALTH_REMINDER_SHELL_START",
            "VERIFY_TASK038B_HEALTH_REMINDER_SHELL_RESULT=PASSED",
            "WATCH_HEALTH_REMINDER_SHELL_CATEGORIES=hydration|rest|stretch",
            "MEDICAL_CLAIM_COUNT=0",
            "HEALTHKIT_PRODUCTION_USAGE_COUNT=0",
            "NEXT_TASK=Task-038c",
        ]:
            record(token in text, f"{path} contains {token}")


def main() -> int:
    print("===== Task-038b Health Reminder Shell verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-038b — Health Reminder Shell")
    print("Not implementing: Task-038c fall safety, Task-038d closure, production HealthKit, medical claims, emergency promises, Snow, route/speed/elevation mutation, WatchKit haptic playback")

    paths = changed_paths()
    check_baseline()
    check_allowed_paths(paths)
    check_required_files()
    check_headers_and_lines()
    check_project_membership()
    check_localization()
    check_source_tokens()
    check_forbidden_scope()
    check_docs()

    print(f"FAILURE_COUNT={len(failures)}")
    if failures:
        print("VERIFY_TASK038B_HEALTH_REMINDER_SHELL_RESULT=FAILED")
        for failure in failures:
            print(f"FAILURE={failure}")
        return 1

    print("VERIFY_TASK038B_HEALTH_REMINDER_SHELL_RESULT=PASSED")
    print("MEDICAL_CLAIM_COUNT=0")
    print("HEALTHKIT_PRODUCTION_USAGE_COUNT=0")
    print("FAILURE_COUNT=0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
