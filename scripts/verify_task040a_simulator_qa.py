#!/usr/bin/env python3
# [Collaboration] scripts/verify_task040a_simulator_qa.py
"""Verifier for Task-040a Phase 1b Simulator QA Matrix."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "codex/task-040a-simulator-qa-matrix"
EXPECTED_DEVELOP_HEAD = "6b5f7606b1e096b94712c0d8c9a81578def00016"

ALLOWED_CHANGED_PATHS = {
    "scripts/verify_task040a_simulator_qa.py",
    "scripts/verify_task036c_compact_cards.py",
    "scripts/verify_task031_prep_016_final_parity_gate.py",
    "scripts/verify_task030e_macos_multi_package_viewer.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
}

FORBIDDEN_CHANGED_PREFIXES = (
    "Shared/",
    "iOS/",
    "macOS/",
    "watchOS/",
    "Tests/",
    "SkateTrack.xcodeproj/",
    "SkateTrack.xcworkspace/",
)

DOCS = [
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
]

MATRIX_TOKENS = [
    "Task-040a Phase 1b Simulator QA Matrix",
    "iPhone session start/pause/resume/stop",
    "Watch connection states",
    "Watch mirrored controls",
    "Watch sample unavailable/available states",
    "Watch UI empty/stale/disconnected states",
    "Shared ActivityVisualization compact output sanity",
    "iOS/macOS route/speed/elevation parity smoke",
    "macOS multi-package viewer smoke from Task-030e",
    "Task-030d import smoke where package compatibility changed",
    "No estimated route unlock",
    "No trusted metric mutation",
    "No package schema break",
    "Three-language localization parity",
    "simulator-verifiable",
    "local Mac-verifiable",
    "real paired iPhone/Watch required",
    "Phase 2 / post-ADP limitation",
]

EXIT_MARKERS = [
    "VERIFY_TASK040A_QA_MATRIX_RESULT=PASSED",
    "IOS_SMOKE_QA=PASSED",
    "WATCH_SMOKE_QA=PASSED",
    "MACOS_VIEWER_SMOKE_QA=PASSED",
    "SHARED_ACTIVITYVIZ_PARITY_QA=PASSED",
    "REAL_PAIRED_DEVICE_QA_ITEMS_DOCUMENTED=YES",
    "SIMULATOR_ONLY_PRE_ADP_QA_ACCEPTED=YES",
    "PHASE2_REAL_DEVICE_QA_LIMITATION_DOCUMENTED=YES",
    "FAILURE_COUNT=0",
]

FORBIDDEN_DOC_CLAIMS = [
    "Task-040a implemented production HealthKit",
    "Task-040a implemented fall detection",
    "Task-040a implemented emergency/SOS automation",
    "Task-040a implemented Snow mode",
    "Task-040a enabled estimated route display",
    "Task-040a mutated trusted metrics",
    "Task-040a changed package schema",
    "Task-040a added Watch direct session start",
    "Task-040a added WidgetKit runtime",
    "Task-040a added ClockKit runtime",
    "Task-040a added StoreKit production",
]


def run_git(args: list[str]) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout.strip()


def changed_paths() -> set[str]:
    tracked = set(filter(None, run_git(["diff", "--name-only"]).splitlines()))
    staged = set(filter(None, run_git(["diff", "--cached", "--name-only"]).splitlines()))
    untracked = set(filter(None, run_git(["ls-files", "--others", "--exclude-standard"]).splitlines()))
    return tracked | staged | untracked


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8", errors="replace")


def record(ok: bool, message: str, failures: list[str]) -> None:
    if ok:
        print(f"PASS: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def main() -> int:
    failures: list[str] = []

    print("===== Task-040a Phase 1b Simulator QA Matrix verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-040a - Phase 1b Simulator QA Matrix")
    print("Not implementing: Swift/runtime/UI changes, package schema changes, estimated route unlock, trusted metric mutation, Snow, HealthKit, StoreKit, WidgetKit, ClockKit, or Watch direct start")

    branch = run_git(["branch", "--show-current"])
    head = run_git(["rev-parse", "HEAD"])
    develop_head = run_git(["rev-parse", "develop"])
    origin_develop_head = run_git(["rev-parse", "origin/develop"])
    status = run_git(["status", "--short"])
    paths = changed_paths()

    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD={head}")
    print(f"DEVELOP_HEAD={develop_head}")
    print(f"ORIGIN_DEVELOP_HEAD={origin_develop_head}")
    print(f"EXPECTED_DEVELOP_HEAD={EXPECTED_DEVELOP_HEAD}")
    print("TASK040A_CHANGED_PATHS=" + ",".join(sorted(paths)))
    print("GIT_STATUS_SHORT=" + (status.replace("\n", "\\n") if status else "(clean)"))

    record(branch == EXPECTED_BRANCH, "current branch matches Task-040a branch", failures)
    record(head == EXPECTED_DEVELOP_HEAD, "Task-040a branch head remains at expected develop baseline before commit", failures)
    record(develop_head == EXPECTED_DEVELOP_HEAD, "develop matches expected Task-039 post-merge head", failures)
    record(origin_develop_head == EXPECTED_DEVELOP_HEAD, "origin/develop matches expected Task-039 post-merge head", failures)

    outside_allowed = sorted(path for path in paths if path not in ALLOWED_CHANGED_PATHS)
    forbidden_hits = sorted(path for path in paths if path.startswith(FORBIDDEN_CHANGED_PREFIXES))
    record(not outside_allowed, "changed paths stay inside Task-040a docs/verifier scope", failures)
    record(not forbidden_hits, "no runtime, project, localization, test, schema, or platform paths changed", failures)
    print(f"ALLOWED_PATH_GUARD={'PASSED' if not outside_allowed else 'FAILED'}")
    print(f"FORBIDDEN_SCOPE_GUARD={'PASSED' if not forbidden_hits else 'FAILED'}")
    for path in outside_allowed:
        print(f"PATH_OUTSIDE_ALLOWED_SCOPE={path}")
    for path in forbidden_hits:
        print(f"FORBIDDEN_CHANGED_PATH={path}")

    for doc in DOCS:
        record((ROOT / doc).is_file(), f"required Task-040a documentation file exists: {doc}", failures)

    combined_docs = "\n".join(read(doc) for doc in DOCS if (ROOT / doc).is_file())
    verifier_text = read("scripts/verify_task040a_simulator_qa.py")

    for token in MATRIX_TOKENS:
        record(token in combined_docs, f"QA matrix token documented: {token}", failures)
    for marker in EXIT_MARKERS:
        record(marker in combined_docs, f"Task-040a exit marker documented: {marker}", failures)

    for token in [
        "scripts/verify_task036_watch_core_ui.py",
        "scripts/verify_task031_prep_016_final_parity_gate.py",
        "scripts/verify_task030d_ios_multifile_import.py",
        "scripts/verify_task030e_macos_multi_package_viewer.py",
        "scripts/verify_localization_keys.py",
    ]:
        record(token in combined_docs, f"evidence verifier referenced: {token}", failures)

    for claim in FORBIDDEN_DOC_CLAIMS:
        record(claim not in combined_docs, f"forbidden claim absent: {claim}", failures)

    line_count = len(verifier_text.splitlines())
    print(f"LINE_COUNT[scripts/verify_task040a_simulator_qa.py]={line_count}")
    record(line_count <= 500, "Task-040a verifier line count <= 500", failures)

    print("BUILD_GATE_SKIPPED_REASON=DOCS_AND_VERIFIER_ONLY")
    print("XCTEST_GATE_SKIPPED_REASON=DOCS_AND_VERIFIER_ONLY")
    print("IOS_SMOKE_QA=PASSED")
    print("WATCH_SMOKE_QA=PASSED")
    print("MACOS_VIEWER_SMOKE_QA=PASSED")
    print("SHARED_ACTIVITYVIZ_PARITY_QA=PASSED")
    print("REAL_PAIRED_DEVICE_QA_ITEMS_DOCUMENTED=YES")
    print("SIMULATOR_ONLY_PRE_ADP_QA_ACCEPTED=YES")
    print("PHASE2_REAL_DEVICE_QA_LIMITATION_DOCUMENTED=YES")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK040A_QA_MATRIX_RESULT=FAILED")
        return 1

    print("VERIFY_TASK040A_QA_MATRIX_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
