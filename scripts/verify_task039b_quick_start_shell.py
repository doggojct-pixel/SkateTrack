#!/usr/bin/env python3
# [Collaboration] scripts/verify_task039b_quick_start_shell.py
"""Verifier for Task-039b Quick Start Shell."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "codex/task-039b-quick-start-shell"
EXPECTED_BASE_HEAD = "fc52d885a74f7e5c42bca9bd38ca65a8e1077282"

ALLOWED_CHANGED_PATHS = {
    "Shared/WatchUI/WatchQuickStartShellState.swift",
    "watchOS/Features/WatchQuickStartShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchQuickStartShellStateTests.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task039b_quick_start_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchQuickStartShellState.swift",
    "watchOS/Features/WatchQuickStartShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchQuickStartShellStateTests.swift",
    "scripts/verify_task039b_quick_start_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchQuickStartShellState.swift",
    "watchOS/Features/WatchQuickStartShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchQuickStartShellStateTests.swift",
]

LOCALIZATION_KEYS = [
    "watch.quickStart.title",
    "watch.quickStart.detail",
    "watch.quickStart.status.providerUnavailable",
    "watch.quickStart.status.iPhoneAuthority",
    "watch.quickStart.lastMode.title",
    "watch.quickStart.lastMode.detail",
    "watch.quickStart.outdoor.title",
    "watch.quickStart.outdoor.detail",
    "watch.quickStart.readyCheck.title",
    "watch.quickStart.readyCheck.detail",
    "watch.quickStart.accessibility.label",
]

PRODUCT_SCAN_FILES = [
    "Shared/WatchUI/WatchQuickStartShellState.swift",
    "watchOS/Features/WatchQuickStartShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchQuickStartShellStateTests.swift",
]

FORBIDDEN_PATH_PARTS = [
    "Shared/ActivityVisualization/",
    "Shared/Models/",
    "Shared/Persistence/",
    "Shared/Export/",
    "Shared/WatchSensors/",
    "iOS/Core/",
    "iOS/Features/",
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

FORBIDDEN_RUNTIME_PATTERNS = [
    r"\bimport\s+StoreKit\b",
    r"\bimport\s+HealthKit\b",
    r"\bimport\s+WidgetKit\b",
    r"\bimport\s+ClockKit\b",
    r"\bHKHealthStore\b",
    r"\bTransaction\b",
    r"\bProduct\b",
    r"\bWidgetBundle\b",
    r"\bTimelineProvider\b",
    r"\bCLKComplication\w*\b",
    r"\bSessionRecordingCoordinator\b",
    r"\bSensorFusionEngine\b",
    r"\bstartRecording\b",
    r"\bstartSession\s*\(",
]

PROJECT_FORBIDDEN_PATTERNS = [
    r"NSExtension",
    r"com\.apple\.developer\.widgetkit",
    r"INFOPLIST_KEY_NSExtension",
    r"PRODUCT_BUNDLE_IDENTIFIER[\s=]+[^;\n]*(quick|widget|complication)",
]

failures: list[str] = []
runtime_usage_count = 0
project_forbidden_count = 0


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
    record(branch == EXPECTED_BRANCH, "current branch matches Task-039b branch")
    record(head == EXPECTED_BASE_HEAD, "current HEAD remains at Task-039b base before commit")
    record(base_merge == EXPECTED_BASE_HEAD, "Task-039b branch is based on Task-039a head")


def check_allowed_paths(paths: set[str]) -> None:
    print("TASK039B_CHANGED_PATHS=" + ",".join(sorted(paths)))
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

    verifier_lines = len(read("scripts/verify_task039b_quick_start_shell.py").splitlines())
    print(f"LINE_COUNT[scripts/verify_task039b_quick_start_shell.py]={verifier_lines}")
    record(verifier_lines <= 500, "Task-039b verifier line count <= 500")


def check_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    tokens = [
        "39B100000000000000000001 /* WatchQuickStartShellState.swift */",
        "39B100000000000000000101 /* WatchQuickStartShellState.swift in Sources */",
        "39B100000000000000000102 /* WatchQuickStartShellState.swift in Sources */",
        "39B200000000000000000001 /* watchOS/Features/WatchQuickStartShellView.swift */",
        "39B200000000000000000101 /* watchOS/Features/WatchQuickStartShellView.swift in Sources */",
        "39B900000000000000000001 /* WatchQuickStartShellStateTests.swift */",
        "39B900000000000000000101 /* WatchQuickStartShellStateTests.swift in Sources */",
    ]
    for token in tokens:
        record(token in project, f"project contains membership token: {token}")

    watchui_group = re.search(r"36A000000000000000000000 /\* WatchUI \*/ = \{.*?\n\t\t\};", project, re.S)
    tests_group = re.search(r"12AC02000000000000000001 /\* iOSTests \*/ = \{.*?\n\t\t\};", project, re.S)
    recovered_group = re.search(r"397B7DA02FFCFC78001AC43D /\* Recovered References \*/ = \{.*?\n\t\t\};", project, re.S)
    record(watchui_group is not None and "WatchQuickStartShellState.swift" in watchui_group.group(0), "state file is in WatchUI group")
    record(tests_group is not None and "WatchQuickStartShellStateTests.swift" in tests_group.group(0), "test file is in iOSTests group")
    record(recovered_group is not None and "WatchQuickStartShellView.swift" in recovered_group.group(0), "watch view file is in watchOS references group")

    for path in [
        "Shared/WatchUI/WatchQuickStartShellState.swift",
        "watchOS/Features/WatchQuickStartShellView.swift",
        "Tests/iOSTests/WatchQuickStartShellStateTests.swift",
    ]:
        record((ROOT / path).exists(), f"project member path resolves on disk: {path}")


def check_localization() -> None:
    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            record(f'"{key}"' in text, f"{language} localization contains {key}")


def check_source_tokens() -> None:
    state = read("Shared/WatchUI/WatchQuickStartShellState.swift")
    view = read("watchOS/Features/WatchQuickStartShellView.swift")
    live_face = read("watchOS/Features/WatchLiveSessionFaceView.swift")
    tests = read("Tests/iOSTests/WatchQuickStartShellStateTests.swift")

    for token in [
        "enum WatchQuickStartShellAvailability",
        "case iPhoneAuthorityRequired",
        "case providerUnavailable",
        "enum WatchQuickStartAuthority",
        "case iPhone",
        "requiresIPhoneAuthority",
        "allowsDirectWatchStart",
        "startsSessionFromWatch",
        "writesSessionRuntime",
        "makeStartCommand",
    ]:
        record(token in state, f"state contains token: {token}")

    record("WatchQuickStartShellView" in view, "watch shell view type exists")
    record("WatchQuickStartShellView(" in live_face, "live face integrates quick start shell")
    for token in [
        "testDisabledShellRequiresIPhoneAuthority",
        "testProviderUnavailableStateRemainsDisabled",
        "testQuickStartOptionsArePresentAndDisabled",
        "testViewModelInitializerUsesConnectionProviderState",
    ]:
        record(token in tests, f"tests contain token: {token}")


def check_forbidden_scope() -> None:
    global runtime_usage_count, project_forbidden_count
    product_text = "\n".join(read(path) for path in PRODUCT_SCAN_FILES if (ROOT / path).exists())
    project_diff = git_diff_for("SkateTrack.xcodeproj/project.pbxproj")

    runtime_usage_count = regex_count(FORBIDDEN_RUNTIME_PATTERNS, product_text)
    project_forbidden_count = regex_count(PROJECT_FORBIDDEN_PATTERNS, project_diff)
    snow_count = regex_count([r"\bSnow\w*\b"], product_text)
    command_send_count = regex_count([r"WatchBridgeCommandEnvelope\s*\("], product_text)

    print(f"FORBIDDEN_RUNTIME_USAGE_COUNT={runtime_usage_count}")
    print(f"FORBIDDEN_PROJECT_TARGET_COUNT={project_forbidden_count}")
    print(f"SNOW_SCOPE_TOKEN_COUNT={snow_count}")
    print(f"WATCH_START_COMMAND_CONSTRUCTION_COUNT={command_send_count}")
    print("IPHONE_AUTHORITY_PRESERVED=YES" if "requiresIPhoneAuthority" in product_text else "IPHONE_AUTHORITY_PRESERVED=NO")
    print("DISABLED_PROVIDER_AWARE=YES" if "isProviderAware" in product_text else "DISABLED_PROVIDER_AWARE=NO")
    record(runtime_usage_count == 0, "no forbidden runtime/session/provider APIs")
    record(project_forbidden_count == 0, "no extension target or capability changes")
    record(snow_count == 0, "no Snow scope tokens in Task-039b product/test files")
    record(command_send_count == 0, "no Watch-side start command construction")


def check_docs() -> None:
    doc_expectations = {
        "docs/history/DEV_LOG.md": [
            "TASK039B_QUICK_START_SHELL_START",
            "VERIFY_TASK039B_QUICK_START_SHELL_RESULT=PASSED",
            "IPHONE_AUTHORITY_PRESERVED=YES",
            "NEXT_TASK=Task-039c",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "TASK039B_QUICK_START_SHELL_START",
            "Shared/WatchUI/WatchQuickStartShellState.swift",
            "watchOS/Features/WatchQuickStartShellView.swift",
            "scripts/verify_task039b_quick_start_shell.py",
            "NEXT_TASK=Task-039c",
        ],
        "docs/process/PHASE_1B_AGENT_STATE.md": [
            "TASK039B_QUICK_START_SHELL_START",
            "WATCH_QUICK_START_SHELL_PRESENT=YES",
            "IPHONE_AUTHORITY_PRESERVED=YES",
            "MANUAL_QA_TASK039B_QUICK_START=PENDING_OPERATOR_CONFIRMATION",
            "NEXT_TASK=Task-039c",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "TASK039B_PRE_ADP_LIMITATIONS_START",
            "WATCH_QUICK_START_DIRECT_START=NO",
            "IPHONE_SESSION_START_AUTHORITY=YES",
        ],
        "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
            "TASK039B_QUICK_START_MANUAL_QA_START",
            "MANUAL_QA_TASK039B_QUICK_START=PENDING_OPERATOR_CONFIRMATION",
        ],
    }

    for path, tokens in doc_expectations.items():
        text = read(path)
        for token in tokens:
            record(token in text, f"{path} contains {token}")


def main() -> int:
    print("===== Task-039b Quick Start Shell verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-039b — Quick Start Shell")
    print("Not implementing: Task-039c reward foundation, production StoreKit, HealthKit, Snow, Watch-side session runtime start, entitlements, route/speed/elevation mutation, schema/package changes")

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

    print(f"FORBIDDEN_RUNTIME_USAGE_COUNT={runtime_usage_count}")
    print(f"FORBIDDEN_PROJECT_TARGET_COUNT={project_forbidden_count}")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK039B_QUICK_START_SHELL_RESULT=FAILED")
        for failure in failures:
            print(f"FAILURE: {failure}")
        return 1

    print("VERIFY_TASK039B_QUICK_START_SHELL_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
