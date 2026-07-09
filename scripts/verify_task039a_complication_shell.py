#!/usr/bin/env python3
# [Collaboration] scripts/verify_task039a_complication_shell.py
"""Verifier for Task-039a Complication Shell."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "codex/task-039a-complication-shell"
EXPECTED_BASE_HEAD = "769815d9e693d6303ffb9e9f2c2881321d16a389"

ALLOWED_CHANGED_PATHS = {
    "Shared/WatchUI/WatchComplicationShellState.swift",
    "watchOS/Features/WatchComplicationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchComplicationShellStateTests.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task039a_complication_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
}

REQUIRED_FILES = [
    "Shared/WatchUI/WatchComplicationShellState.swift",
    "watchOS/Features/WatchComplicationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchComplicationShellStateTests.swift",
    "scripts/verify_task039a_complication_shell.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

SWIFT_FILES = [
    "Shared/WatchUI/WatchComplicationShellState.swift",
    "watchOS/Features/WatchComplicationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchComplicationShellStateTests.swift",
]

LOCALIZATION_KEYS = [
    "watch.complication.title",
    "watch.complication.detail",
    "watch.complication.status.unavailable",
    "watch.complication.status.placeholder",
    "watch.complication.speed.title",
    "watch.complication.speed.detail",
    "watch.complication.time.title",
    "watch.complication.time.detail",
    "watch.complication.distance.title",
    "watch.complication.distance.detail",
    "watch.complication.accessibility.label",
]

PRODUCT_SCAN_FILES = [
    "Shared/WatchUI/WatchComplicationShellState.swift",
    "watchOS/Features/WatchComplicationShellView.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
    "Tests/iOSTests/WatchComplicationShellStateTests.swift",
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

COMPLICATION_RUNTIME_PATTERNS = [
    r"\bimport\s+WidgetKit\b",
    r"\bimport\s+ClockKit\b",
    r"\bWidgetBundle\b",
    r"\bWidgetConfiguration\b",
    r"\bTimelineProvider\b",
    r"\bCLKComplication\w*\b",
    r"\bCLKComplicationDataSource\b",
]

PROJECT_EXTENSION_PATTERNS = [
    r"PBXNativeTarget[\s\S]{0,600}Complication",
    r"NSExtension",
    r"com\.apple\.developer\.widgetkit",
    r"INFOPLIST_KEY_NSExtension",
    r"PRODUCT_BUNDLE_IDENTIFIER[\s=]+[^;\n]*complication",
]

PRODUCTION_CLAIM_PATTERNS = [
    r"\bproduction\s+complications?\b",
    r"\bApp\s+Store\s+complications?\b",
    r"\bTestFlight\s+complications?\b",
    r"\bwatch\s+face\s+delivery\s+is\s+active\b",
    r"\blive\s+face\s+delivery\s+is\s+active\b",
    r"\bcomplications?\s+(are|is)\s+(enabled|active|ready|shipping|distributed)\b",
    r"錶面.*(已啟用|可使用|已發布)",
    r"コンプリケーション.*(有効です|利用できます|配布済み)",
]

NEGATION_HINTS = [
    "not",
    "unavailable",
    "disabled",
    "placeholder",
    "shell",
    "未",
    "尚未",
    "沒有",
    "利用できません",
    "有効ではありません",
]

failures: list[str] = []
production_claim_count = 0
runtime_usage_count = 0
extension_target_count = 0


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


def claim_hits(text: str) -> list[str]:
    hits: list[str] = []
    for pattern in PRODUCTION_CLAIM_PATTERNS:
        for match in re.finditer(pattern, text, flags=re.IGNORECASE):
            context = text[max(0, match.start() - 42): match.end() + 20].lower()
            if not any(hint.lower() in context for hint in NEGATION_HINTS):
                hits.append(match.group(0))
    return hits


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
    base_merge = run_git(["merge-base", "HEAD", EXPECTED_BASE_HEAD])
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD={head}")
    print(f"EXPECTED_BASE_HEAD={EXPECTED_BASE_HEAD}")
    record(branch == EXPECTED_BRANCH, "current branch matches Task-039a branch")
    record(head == EXPECTED_BASE_HEAD, "current HEAD remains at Task-039a base before commit")
    record(base_merge == EXPECTED_BASE_HEAD, "Task-039a branch is based on expected develop head")


def check_allowed_paths(paths: set[str]) -> None:
    print("TASK039A_CHANGED_PATHS=" + ",".join(sorted(paths)))
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

    verifier_lines = len(read("scripts/verify_task039a_complication_shell.py").splitlines())
    print(f"LINE_COUNT[scripts/verify_task039a_complication_shell.py]={verifier_lines}")
    record(verifier_lines <= 500, "Task-039a verifier line count <= 500")


def check_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    tokens = [
        "39A100000000000000000001 /* WatchComplicationShellState.swift */",
        "39A100000000000000000101 /* WatchComplicationShellState.swift in Sources */",
        "39A100000000000000000102 /* WatchComplicationShellState.swift in Sources */",
        "39A200000000000000000001 /* watchOS/Features/WatchComplicationShellView.swift */",
        "39A200000000000000000101 /* watchOS/Features/WatchComplicationShellView.swift in Sources */",
        "39A900000000000000000001 /* WatchComplicationShellStateTests.swift */",
        "39A900000000000000000101 /* WatchComplicationShellStateTests.swift in Sources */",
    ]
    for token in tokens:
        record(token in project, f"project contains membership token: {token}")

    watchui_group = re.search(r"36A000000000000000000000 /\* WatchUI \*/ = \{.*?\n\t\t\};", project, re.S)
    tests_group = re.search(r"12AC02000000000000000001 /\* iOSTests \*/ = \{.*?\n\t\t\};", project, re.S)
    recovered_group = re.search(r"397B7DA02FFCFC78001AC43D /\* Recovered References \*/ = \{.*?\n\t\t\};", project, re.S)
    record(watchui_group is not None and "WatchComplicationShellState.swift" in watchui_group.group(0), "state file is in WatchUI group")
    record(tests_group is not None and "WatchComplicationShellStateTests.swift" in tests_group.group(0), "test file is in iOSTests group")
    record(recovered_group is not None and "WatchComplicationShellView.swift" in recovered_group.group(0), "watch view file is in watchOS references group")

    for path in [
        "Shared/WatchUI/WatchComplicationShellState.swift",
        "watchOS/Features/WatchComplicationShellView.swift",
        "Tests/iOSTests/WatchComplicationShellStateTests.swift",
    ]:
        record((ROOT / path).exists(), f"project member path resolves on disk: {path}")


def check_localization() -> None:
    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            record(f'"{key}"' in text, f"{language} localization contains {key}")


def check_source_tokens() -> None:
    state = read("Shared/WatchUI/WatchComplicationShellState.swift")
    view = read("watchOS/Features/WatchComplicationShellView.swift")
    live_face = read("watchOS/Features/WatchLiveSessionFaceView.swift")
    tests = read("Tests/iOSTests/WatchComplicationShellStateTests.swift")

    for token in [
        "enum WatchComplicationShellAvailability",
        "enum WatchComplicationShellSlotKind",
        "case currentSpeed",
        "case elapsedTime",
        "case distance",
        "supportsFaceComplicationDistribution",
        "usesWidgetKitExtension",
        "usesClockKitExtension",
        "providesLiveTimeline",
        "requestsNewCapabilities",
    ]:
        record(token in state, f"state contains token: {token}")

    record("WatchComplicationShellView" in view, "watch shell view type exists")
    record("WatchComplicationShellView(" in live_face, "live face integrates complication shell")
    for token in [
        "testDefaultDisabledShellStateIsSafe",
        "testPlaceholderSlotsArePresentAndDisabled",
        "testShellDoesNotIntroduceComplicationRuntimeOrCapabilities",
        "testCopyKeysAvoidReleaseReadinessClaims",
    ]:
        record(token in tests, f"tests contain token: {token}")


def check_forbidden_scope() -> None:
    global extension_target_count, production_claim_count, runtime_usage_count
    product_text = "\n".join(read(path) for path in PRODUCT_SCAN_FILES if (ROOT / path).exists())
    task_copy = localized_values_for_task_keys()
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    project_diff = git_diff_for("SkateTrack.xcodeproj/project.pbxproj")

    runtime_usage_count = regex_count(COMPLICATION_RUNTIME_PATTERNS, product_text)
    extension_target_count = regex_count(PROJECT_EXTENSION_PATTERNS, project_diff)
    production_claim_count = len(claim_hits(product_text + "\n" + task_copy))
    healthkit_count = regex_count([r"\bimport\s+HealthKit\b", r"\bHKHealthStore\b"], product_text + "\n" + project)
    storekit_count = regex_count([r"\bimport\s+StoreKit\b", r"\bProduct\b", r"\bTransaction\b"], product_text)
    snow_count = regex_count([r"\bSnow\w*\b"], product_text)

    print(f"COMPLICATION_RUNTIME_API_USAGE_COUNT={runtime_usage_count}")
    print(f"WATCHOS_EXTENSION_TARGET_COUNT={extension_target_count}")
    print(f"PRODUCTION_COMPLICATION_CLAIM_COUNT={production_claim_count}")
    print(f"HEALTHKIT_PRODUCTION_USAGE_COUNT={healthkit_count}")
    print(f"PRODUCTION_STOREKIT_DEPENDENCY_COUNT={storekit_count}")
    print(f"SNOW_SCOPE_TOKEN_COUNT={snow_count}")
    record(runtime_usage_count == 0, "no WidgetKit/ClockKit complication runtime APIs")
    record(extension_target_count == 0, "no complication extension target or capability changes")
    record(production_claim_count == 0, "no production complication availability claims")
    record(healthkit_count == 0, "no production HealthKit usage")
    record(storekit_count == 0, "no production StoreKit dependency")
    record(snow_count == 0, "no Snow scope tokens in Task-039a product/test files")


def check_docs() -> None:
    doc_expectations = {
        "docs/history/DEV_LOG.md": [
            "TASK039A_COMPLICATION_SHELL_START",
            "VERIFY_TASK039A_COMPLICATION_SHELL_RESULT=PASSED",
            "PRODUCTION_COMPLICATION_CLAIM_COUNT=0",
            "NEXT_TASK=Task-039b",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "TASK039A_COMPLICATION_SHELL_START",
            "Shared/WatchUI/WatchComplicationShellState.swift",
            "watchOS/Features/WatchComplicationShellView.swift",
            "scripts/verify_task039a_complication_shell.py",
            "NEXT_TASK=Task-039b",
        ],
        "docs/process/PHASE_1B_AGENT_STATE.md": [
            "TASK039A_COMPLICATION_SHELL_START",
            "WATCH_COMPLICATION_SHELL_PRESENT=YES",
            "WATCH_FACE_COMPLICATION_EXTENSION_IMPLEMENTED=NO",
            "MANUAL_QA_TASK039A_COMPLICATION=PENDING_OPERATOR_CONFIRMATION",
            "NEXT_TASK=Task-039b",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "TASK039A_PRE_ADP_LIMITATIONS_START",
            "WATCH_FACE_COMPLICATION_DISTRIBUTION=NO",
            "WATCH_FACE_COMPLICATION_EXTENSION_IMPLEMENTED=NO",
        ],
        "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
            "TASK039A_COMPLICATION_MANUAL_QA_START",
            "MANUAL_QA_TASK039A_COMPLICATION=PENDING_OPERATOR_CONFIRMATION",
        ],
    }

    for path, tokens in doc_expectations.items():
        text = read(path)
        for token in tokens:
            record(token in text, f"{path} contains {token}")


def main() -> int:
    print("===== Task-039a Complication Shell verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-039a — Complication Shell")
    print("Not implementing: production complication extension, WidgetKit/ClockKit runtime, TestFlight/App Store distribution, Task-039b quick start, Task-039c reward foundation, StoreKit, HealthKit, Snow, route/speed/elevation mutation")

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

    print(f"PRODUCTION_COMPLICATION_CLAIM_COUNT={production_claim_count}")
    print(f"COMPLICATION_RUNTIME_API_USAGE_COUNT={runtime_usage_count}")
    print(f"WATCHOS_EXTENSION_TARGET_COUNT={extension_target_count}")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK039A_COMPLICATION_SHELL_RESULT=FAILED")
        for failure in failures:
            print(f"FAILURE: {failure}")
        return 1

    print("VERIFY_TASK039A_COMPLICATION_SHELL_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
