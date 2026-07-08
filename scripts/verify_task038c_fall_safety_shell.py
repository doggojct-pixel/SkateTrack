#!/usr/bin/env python3
# [Collaboration] scripts/verify_task038c_fall_safety_shell.py
"""Verifier for Task-038c Fall Safety Presentation Shell."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "task-038-haptics-safety-shells"
EXPECTED_HEAD = "f96be0db6d9b30415e1083559dbcaaf0b57df21a"

ALLOWED_CHANGED_PATHS = {
    "Shared/WatchUI/WatchFallSafetyPresentationShellState.swift",
    "watchOS/Features/WatchFallSafetyPresentationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift",
    "scripts/verify_task038c_fall_safety_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "SkateTrack.xcodeproj/project.pbxproj",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchFallSafetyPresentationShellState.swift",
    "watchOS/Features/WatchFallSafetyPresentationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift",
    "scripts/verify_task038c_fall_safety_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchFallSafetyPresentationShellState.swift",
    "watchOS/Features/WatchFallSafetyPresentationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift",
]

LOCALIZATION_KEYS = [
    "watch.fallSafety.title",
    "watch.fallSafety.detail",
    "watch.fallSafety.limitation",
    "watch.fallSafety.status.shell",
    "watch.fallSafety.status.dismissed",
    "watch.fallSafety.status.falseAlarm",
    "watch.fallSafety.dismiss",
    "watch.fallSafety.falseAlarm",
    "watch.fallSafety.accessibility.label",
]

PRODUCT_SCAN_FILES = [
    "Shared/WatchUI/WatchFallSafetyPresentationShellState.swift",
    "watchOS/Features/WatchFallSafetyPresentationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift",
]

FORBIDDEN_PATH_PARTS = [
    "Shared/ActivityVisualization/",
    "watchOS/Features/WatchMetricCarouselView.swift",
    "Shared/Models/FallEvent.swift",
    "Shared/Models/SOSTriggerEvent.swift",
    "iOS/Features/FallDetection/",
    "iOS/Core/Safety/",
    "iOS/Core/SensorEngine/",
    "Shared/Snow/",
    "Snow",
    "SkateTrackPackage",
    ".xcdatamodeld",
    "StoreKit",
    "SessionMetricsAccumulator",
    "SensorFusionEngine",
    "MotionSample",
    "SessionData",
    "RouteDisplay",
    "SpeedDisplay",
    "ElevationDisplay",
]

HEALTHKIT_PRODUCTION_PATTERNS = [
    r"\bimport\s+HealthKit\b",
    r"\bHKHealthStore\b",
    r"\bHKWorkout\b",
    r"\bHKLiveWorkoutBuilder\b",
    r"\bHKQuantitySample\b",
    r"com\.apple\.developer\.healthkit",
]

WATCHKIT_HAPTIC_PATTERNS = [
    r"\bimport\s+WatchKit\b",
    r"\bWKInterfaceDevice\b",
    r"\.play\s*\(",
]

FALL_RUNTIME_PATTERNS = [
    r"\bFallEvent\b",
    r"\bSOSTriggerEvent\b",
    r"\bFallDetectionEngine\b",
    r"\bFallDetectionAlertView\b",
    r"\bFallDetectionOverlayPresenter\b",
    r"\bSOSEventDispatcher\b",
    r"\buseFallDetection\b",
    r"\bactiveFallEvent\b",
]

EMERGENCY_PROMISE_PATTERNS = [
    r"\bcalls?\s+emergency\b",
    r"\bcontacts?\s+emergency\b",
    r"\bemergency\s+(response|dispatch|calling|call|contact|service\s+promise)\b",
    r"\brescue\w*\b",
    r"\bSOS\b",
    r"\bdetects?\s+falls?\b",
    r"\bfall[\s-]+detection\b",
    r"\balways[\s-]+on\s+safety\b",
    r"\bmonitors?\s+health\b",
    r"\bmedical\b",
    r"\bdiagnos\w*\b",
    r"\btreat\w*\b",
    r"\bprevent\w*\b",
    r"\bclinical\b",
    r"自動.*(通報|通知|求救|救援)",
    r"救援",
    r"醫療",
    r"診斷",
    r"治療",
    r"予防",
    r"医療",
    r"臨床",
]

NEGATION_HINTS = [
    "does not",
    "do not",
    "without",
    "no ",
    "not ",
    "不會",
    "沒有",
    "行いません",
    "ありません",
]

failures: list[str] = []


def run_git(args: list[str]) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def git_diff_for(path: str) -> str:
    return subprocess.check_output(["git", "diff", "--", path], cwd=ROOT, text=True)


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


def promise_hits(text: str) -> list[str]:
    hits: list[str] = []
    for pattern in EMERGENCY_PROMISE_PATTERNS:
        for match in re.finditer(pattern, text, flags=re.IGNORECASE):
            context = text[max(0, match.start() - 44): match.end() + 18].lower()
            if not any(hint.lower() in context for hint in NEGATION_HINTS):
                hits.append(match.group(0))
    return hits


def check_baseline() -> None:
    branch = run_git(["branch", "--show-current"])
    head = run_git(["rev-parse", "HEAD"])
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD={head}")
    print(f"EXPECTED_HEAD_BEFORE_CHANGES={EXPECTED_HEAD}")
    record(branch == EXPECTED_BRANCH, "current branch matches Task-038 branch")
    record(head == EXPECTED_HEAD, "current HEAD matches Task-038c expected baseline")


def check_allowed_paths(paths: set[str]) -> None:
    print("TASK038C_CHANGED_PATHS=" + ",".join(sorted(paths)))
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

    verifier_lines = len(read("scripts/verify_task038c_fall_safety_shell.py").splitlines())
    print(f"LINE_COUNT[scripts/verify_task038c_fall_safety_shell.py]={verifier_lines}")
    record(verifier_lines <= 500, "Task-038c verifier line count <= 500")


def check_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    tokens = [
        "38C100000000000000000001 /* WatchFallSafetyPresentationShellState.swift */",
        "38C100000000000000000101 /* WatchFallSafetyPresentationShellState.swift in Sources */",
        "38C100000000000000000102 /* WatchFallSafetyPresentationShellState.swift in Sources */",
        "38C200000000000000000001 /* watchOS/Features/WatchFallSafetyPresentationShellView.swift */",
        "38C200000000000000000101 /* watchOS/Features/WatchFallSafetyPresentationShellView.swift in Sources */",
        "38C900000000000000000001 /* WatchFallSafetyPresentationShellStateTests.swift */",
        "38C900000000000000000101 /* WatchFallSafetyPresentationShellStateTests.swift in Sources */",
    ]
    for token in tokens:
        record(token in project, f"project contains membership token: {token}")

    watchui_group = re.search(r"36A000000000000000000000 /\* WatchUI \*/ = \{.*?\n\t\t\};", project, re.S)
    tests_group = re.search(r"12AC02000000000000000001 /\* iOSTests \*/ = \{.*?\n\t\t\};", project, re.S)
    recovered_group = re.search(r"397B7DA02FFCFC78001AC43D /\* Recovered References \*/ = \{.*?\n\t\t\};", project, re.S)
    record(watchui_group is not None and "WatchFallSafetyPresentationShellState.swift" in watchui_group.group(0), "state file is in WatchUI group")
    record(tests_group is not None and "WatchFallSafetyPresentationShellStateTests.swift" in tests_group.group(0), "test file is in iOSTests group")
    record(recovered_group is not None and "WatchFallSafetyPresentationShellView.swift" in recovered_group.group(0), "watch view file is in watchOS references group")

    for path in [
        "Shared/WatchUI/WatchFallSafetyPresentationShellState.swift",
        "watchOS/Features/WatchFallSafetyPresentationShellView.swift",
        "Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift",
    ]:
        record((ROOT / path).exists(), f"project member path resolves on disk: {path}")


def check_localization() -> None:
    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            record(f'"{key}"' in text, f"{language} localization contains {key}")


def check_source_tokens() -> None:
    state = read("Shared/WatchUI/WatchFallSafetyPresentationShellState.swift")
    view = read("watchOS/Features/WatchFallSafetyPresentationShellView.swift")
    live_face = read("watchOS/Features/WatchLiveSessionFaceView.swift")
    tests = read("Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift")

    for token in [
        "enum WatchFallSafetyPresentationShellPhase",
        "case presented",
        "case dismissed",
        "case falseAlarm",
        "falseAlarmPathPresent",
        "detectsFalls",
        "contactsEmergencyServices",
        "usesHealthKit",
        "allowsDeviceHapticPlayback",
        "WatchHapticIntentPolicy = .mockOnly",
    ]:
        record(token in state, f"state contains token: {token}")

    record("WatchFallSafetyPresentationShellView" in view, "watch shell view type exists")
    record("WatchFallSafetyPresentationShellView(" in live_face, "live face integrates fall safety shell")
    for token in [
        "testDefaultPresentedShellStateIsSafeAndShellOnly",
        "testManualDismissTransitionWorks",
        "testFalseAlarmPathExistsAndWorks",
        "testNoTransitionTriggersDispatchSensorOrHealthBoundaries",
        "testHapticIntentPolicyStaysMockOrDisabledAndNeverPlaysOnDevice",
    ]:
        record(token in tests, f"tests contain token: {token}")


def check_forbidden_scope() -> None:
    product_text = "\n".join(read(path) for path in PRODUCT_SCAN_FILES if (ROOT / path).exists())
    task_copy = localized_values_for_task_keys()
    project_diff = git_diff_for("SkateTrack.xcodeproj/project.pbxproj")
    healthkit_count = regex_count(HEALTHKIT_PRODUCTION_PATTERNS, product_text + "\n" + task_copy + "\n" + project_diff)
    watchkit_count = regex_count(WATCHKIT_HAPTIC_PATTERNS, product_text + "\n" + task_copy)
    fall_runtime_count = regex_count(FALL_RUNTIME_PATTERNS, product_text)
    snow_count = regex_count([r"\bSnow\w*\b"], product_text + "\n" + project_diff)
    emergency_hits = promise_hits(task_copy + "\n" + "\n".join(re.findall(r'"([^"]*)"', product_text)))

    print(f"HEALTHKIT_PRODUCTION_USAGE_COUNT={healthkit_count}")
    print(f"WATCHKIT_HAPTIC_PLAYBACK_COUNT={watchkit_count}")
    print(f"FALL_DETECTION_RUNTIME_TOKEN_COUNT={fall_runtime_count}")
    print(f"SNOW_SCOPE_TOKEN_COUNT={snow_count}")
    print(f"EMERGENCY_PROMISE_COPY_COUNT={len(emergency_hits)}")
    for hit in emergency_hits:
        print(f"EMERGENCY_PROMISE_COPY_HIT={hit}")

    record(healthkit_count == 0, "no production HealthKit usage tokens")
    record(watchkit_count == 0, "no WatchKit haptic playback tokens")
    record(fall_runtime_count == 0, "no FallEvent/SOS/FallDetection runtime usage")
    record(snow_count == 0, "no Snow scope tokens in Task-038c changed product/test files")
    record(not emergency_hits, "no emergency/fall/medical promise copy in Task-038c copy scan")


def check_docs() -> None:
    for path in [
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/process/PHASE_1B_AGENT_STATE.md",
    ]:
        text = read(path)
        for token in [
            "TASK038C_FALL_SAFETY_SHELL_START",
            "VERIFY_TASK038C_FALL_SAFETY_SHELL_RESULT=PASSED",
            "EMERGENCY_PROMISE_COPY_COUNT=0",
            "FALSE_ALARM_PATH_PRESENT=YES",
            "FALL_DETECTION_IMPLEMENTED=NO",
            "EMERGENCY_SERVICE_IMPLEMENTED=NO",
            "NEXT_TASK=Task-038d",
        ]:
            record(token in text, f"{path} contains {token}")


def main() -> int:
    print("===== Task-038c Fall Safety Presentation Shell verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-038c — Fall Safety Presentation Shell")
    print("Not implementing: Task-038d closure, fall detection, emergency service, SOS automation, production HealthKit, WatchKit haptic playback, Snow, route/speed/elevation mutation, ActivityVisualization, package/Core Data/StoreKit/sensor/session engines")

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
        print("VERIFY_TASK038C_FALL_SAFETY_SHELL_RESULT=FAILED")
        for failure in failures:
            print(f"FAILURE={failure}")
        return 1

    print("VERIFY_TASK038C_FALL_SAFETY_SHELL_RESULT=PASSED")
    print("EMERGENCY_PROMISE_COPY_COUNT=0")
    print("FALSE_ALARM_PATH_PRESENT=YES")
    print("FALL_DETECTION_IMPLEMENTED=NO")
    print("EMERGENCY_SERVICE_IMPLEMENTED=NO")
    print("HEALTHKIT_PRODUCTION_USAGE_COUNT=0")
    print("WATCHKIT_HAPTIC_PLAYBACK_COUNT=0")
    print("FAILURE_COUNT=0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
