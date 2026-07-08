#!/usr/bin/env python3
# [Collaboration] scripts/verify_task038_haptics_safety.py
"""Aggregate verifier for Task-038 Haptics/Safety closure preparation."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "task-038-haptics-safety-shells"
EXPECTED_HEAD = "d019aa79e94e296567a8373f6e00cdc60487eada"

ALLOWED_CHANGED_PATHS = {
    "AGENTS.md",
    "scripts/verify_task038_haptics_safety.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
}

FORBIDDEN_CHANGED_PREFIXES = (
    "Shared/ActivityVisualization/",
    "Shared/Localization/",
    "Shared/Models/",
    "Shared/Persistence/",
    "Shared/Snow/",
    "Shared/WatchSensors/",
    "iOS/",
    "macOS/",
    "watchOS/",
    "Tests/",
    "SkateTrack.xcodeproj/",
)

REQUIRED_TASK038_FILES = [
    "Shared/WatchUI/WatchLiveControlState.swift",
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
    "scripts/verify_task038a_haptic_intent.py",
    "Shared/WatchUI/WatchHealthReminderShellState.swift",
    "watchOS/Features/WatchHealthReminderShellView.swift",
    "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
    "scripts/verify_task038b_health_reminder_shell.py",
    "Shared/WatchUI/WatchFallSafetyPresentationShellState.swift",
    "watchOS/Features/WatchFallSafetyPresentationShellView.swift",
    "Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift",
    "scripts/verify_task038c_fall_safety_shell.py",
]

TASK038_SCAN_FILES = [
    "Shared/WatchUI/WatchLiveControlState.swift",
    "Shared/WatchUI/WatchHealthReminderShellState.swift",
    "Shared/WatchUI/WatchFallSafetyPresentationShellState.swift",
    "watchOS/Features/WatchHealthReminderShellView.swift",
    "watchOS/Features/WatchFallSafetyPresentationShellView.swift",
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
    "Tests/iOSTests/WatchHealthReminderShellStateTests.swift",
    "Tests/iOSTests/WatchFallSafetyPresentationShellStateTests.swift",
]

DOCS = [
    "AGENTS.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
]

TASK038_MARKERS = [
    "VERIFY_TASK038A_HAPTIC_INTENT_RESULT=PASSED",
    "RATE_LIMIT_PRESENT=YES",
    "DUPLICATE_SUPPRESSION_PRESENT=YES",
    "HAPTIC_DEVICE_PLAYBACK_IMPLEMENTED=NO",
    "VERIFY_TASK038B_HEALTH_REMINDER_SHELL_RESULT=PASSED",
    "MEDICAL_CLAIM_COUNT=0",
    "HEALTHKIT_PRODUCTION_USAGE_COUNT=0",
    "VERIFY_TASK038C_FALL_SAFETY_SHELL_RESULT=PASSED",
    "EMERGENCY_PROMISE_COPY_COUNT=0",
    "FALSE_ALARM_PATH_PRESENT=YES",
    "FALL_DETECTION_IMPLEMENTED=NO",
    "EMERGENCY_SERVICE_IMPLEMENTED=NO",
    "WATCHKIT_HAPTIC_PLAYBACK_COUNT=0",
]

MANUAL_QA_TOKENS = [
    "MANUAL_QA_HAPTICS_SAFETY=PENDING_OPERATOR_CONFIRMATION",
    "在 watchOS simulator 開啟 live session face。",
    "確認 haptic intent 仍只是 mock/disabled intent 狀態",
    "完成後回報 MANUAL_QA_HAPTICS_SAFETY=PASSED",
]

KNOWN_LIMITATION_TOKENS = [
    "Task-038 Haptics/Safety Closure",
    "KNOWN_LIMITATIONS_UPDATED=YES",
    "no WatchKit haptic playback",
    "no production HealthKit",
    "presentation-only",
    "no emergency/SOS automation",
]


def run_git(args: list[str]) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=REPO,
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout.strip()


def read(path: str) -> str:
    return (REPO / path).read_text(encoding="utf-8")


def changed_paths() -> set[str]:
    tracked = set(filter(None, run_git(["diff", "--name-only"]).splitlines()))
    staged = set(filter(None, run_git(["diff", "--cached", "--name-only"]).splitlines()))
    untracked = set(filter(None, run_git(["ls-files", "--others", "--exclude-standard"]).splitlines()))
    return tracked | staged | untracked


def section(text: str, start: str, end: str) -> str:
    if start not in text or end not in text:
        return ""
    return text.split(start, 1)[1].split(end, 1)[0]


def record(ok: bool, message: str, failures: list[str]) -> None:
    if ok:
        print(f"PASS: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def count_hits(paths: list[str], tokens: list[str]) -> list[str]:
    hits: list[str] = []
    for rel in paths:
        path = REPO / rel
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for token in tokens:
            if token in text:
                hits.append(f"{rel}:{token}")
    return hits


def main() -> int:
    manual_qa_passed = (
        "--manual-qa-passed" in sys.argv[1:]
        or os.environ.get("MANUAL_QA_HAPTICS_SAFETY") == "PASSED"
    )
    failures: list[str] = []

    print("===== Task-038 Haptics/Safety aggregate verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-038d — Haptics/Safety Verifier + Manual QA")
    print("Not implementing: develop merge, Task-039a, Swift/runtime changes, production HealthKit, WatchKit haptic playback, fall detection, emergency/SOS automation, Snow")

    branch = run_git(["branch", "--show-current"])
    head = run_git(["rev-parse", "HEAD"])
    status = run_git(["status", "--short"])
    paths = changed_paths()

    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD={head}")
    print(f"EXPECTED_HEAD_BEFORE_CHANGES={EXPECTED_HEAD}")
    print("TASK038D_CHANGED_PATHS=" + ",".join(sorted(paths)))
    print("GIT_STATUS_SHORT=" + (status.replace("\n", "\\n") if status else "(clean)"))

    record(branch == EXPECTED_BRANCH, "current branch matches Task-038 branch", failures)
    record(head == EXPECTED_HEAD, "current HEAD matches Task-038d expected pre-commit baseline", failures)

    outside_allowed = sorted(path for path in paths if path not in ALLOWED_CHANGED_PATHS)
    forbidden_path_hits = sorted(
        path for path in paths if path.startswith(FORBIDDEN_CHANGED_PREFIXES)
    )
    record(not outside_allowed, "changed paths are docs/verifier-only", failures)
    record(not forbidden_path_hits, "no forbidden runtime/product paths changed", failures)
    if outside_allowed:
        print("ALLOWED_PATH_GUARD=FAILED")
        for path in outside_allowed:
            print(f"PATH_OUTSIDE_ALLOWED_SCOPE={path}")
    else:
        print("ALLOWED_PATH_GUARD=PASSED")
    if forbidden_path_hits:
        print("FORBIDDEN_SCOPE_GUARD=FAILED")
        for path in forbidden_path_hits:
            print(f"FORBIDDEN_CHANGED_PATH={path}")
    else:
        print("FORBIDDEN_SCOPE_GUARD=PASSED")

    for rel in REQUIRED_TASK038_FILES:
        record((REPO / rel).is_file(), f"required Task-038 file exists: {rel}", failures)

    combined_docs = "\n".join(read(path) for path in DOCS if (REPO / path).is_file())
    for marker in TASK038_MARKERS:
        record(marker in combined_docs, f"Task-038 evidence marker present: {marker}", failures)

    healthkit_hits = count_hits(
        TASK038_SCAN_FILES,
        ["HKHealthStore", "HKSample", "HKQuantity", "requestAuthorization("],
    )
    watchkit_hits = count_hits(
        TASK038_SCAN_FILES,
        ["import WatchKit", "WKInterfaceDevice.current()", ".play("],
    )
    emergency_runtime_hits = count_hits(
        TASK038_SCAN_FILES,
        ["FallDetectionEngine", "SOSEventDispatcher", "SOSTriggerEvent(", "EmergencyContactStore"],
    )
    snow_hits = count_hits(TASK038_SCAN_FILES, ["Snow", "Ski", "Gondola", "Lift"])

    print(f"HEALTHKIT_PRODUCTION_USAGE_COUNT={len(healthkit_hits)}")
    print(f"WATCHKIT_HAPTIC_PLAYBACK_COUNT={len(watchkit_hits)}")
    print(f"FALL_OR_EMERGENCY_RUNTIME_TOKEN_COUNT={len(emergency_runtime_hits)}")
    print(f"SNOW_SCOPE_TOKEN_COUNT={len(snow_hits)}")
    for hit in healthkit_hits:
        print(f"HEALTHKIT_PRODUCTION_USAGE_HIT={hit}")
    for hit in watchkit_hits:
        print(f"WATCHKIT_HAPTIC_PLAYBACK_HIT={hit}")
    for hit in emergency_runtime_hits:
        print(f"FALL_OR_EMERGENCY_RUNTIME_HIT={hit}")
    for hit in snow_hits:
        print(f"SNOW_SCOPE_HIT={hit}")
    record(not healthkit_hits, "no production HealthKit usage in Task-038 Watch files", failures)
    record(not watchkit_hits, "no WatchKit haptic playback in Task-038 Watch files", failures)
    record(not emergency_runtime_hits, "no fall detection or emergency/SOS automation added by Task-038 Watch files", failures)
    record(not snow_hits, "no Snow scope in Task-038 Watch files", failures)

    known = read("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md")
    for token in KNOWN_LIMITATION_TOKENS:
        record(token in known, f"known limitations Task-038 token present: {token}", failures)

    manual_sources = read("docs/process/PHASE_1B_AGENT_STATE.md")
    manual_sources += "\n" + read("docs/release/MANUAL_QA_MATRIX_PRE_ADP.md")
    for token in MANUAL_QA_TOKENS:
        record(token in manual_sources, f"manual QA checklist token present: {token}", failures)

    state = read("docs/process/PHASE_1B_AGENT_STATE.md")
    task038d_state = section(
        state,
        "<!-- TASK038D_HAPTICS_SAFETY_CLOSURE_PREP_START -->",
        "<!-- TASK038D_HAPTICS_SAFETY_CLOSURE_PREP_END -->",
    )
    record(bool(task038d_state), "Task-038d state section present", failures)
    record("NEXT_TASK=Task-039a" in task038d_state, "Task-038d state points next to Task-039a", failures)
    record("COMMIT_PUSH_RESULT=PENDING_OPERATOR_COMMIT_GATE" in task038d_state, "Task-038d does not claim commit/push passed", failures)
    record("DEVELOP_MERGE" not in task038d_state and "MERGE_TO_DEVELOP_RESULT=PASSED" not in task038d_state, "Task-038d does not claim develop merge", failures)

    print("BUILD_GATE_SKIPPED_REASON=DOCS_AND_VERIFIER_ONLY")
    print("XCTEST_GATE_SKIPPED_REASON=DOCS_AND_VERIFIER_ONLY")

    if failures:
        print(f"FAILURE_COUNT={len(failures)}")
        print("VERIFY_TASK038_HAPTICS_SAFETY_PRE_QA_RESULT=FAILED")
        for failure in failures:
            print(f"FAILURE={failure}")
        return 1

    if manual_qa_passed:
        print("VERIFY_TASK038_HAPTICS_SAFETY_RESULT=PASSED")
        print("MANUAL_QA_HAPTICS_SAFETY=PASSED")
        print("KNOWN_LIMITATIONS_UPDATED=YES")
        print("FAILURE_COUNT=0")
    else:
        print("VERIFY_TASK038_HAPTICS_SAFETY_PRE_QA_RESULT=PASSED")
        print("MANUAL_QA_HAPTICS_SAFETY=PENDING_OPERATOR_CONFIRMATION")
        print("KNOWN_LIMITATIONS_UPDATED=YES")
        print("FAILURE_COUNT=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
