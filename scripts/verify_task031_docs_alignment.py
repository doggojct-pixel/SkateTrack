#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

PLAN = "SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md"
SUBTASK = "Task-031d — Phase 1b Documentation Alignment Commit"
AGGREGATE_BRANCH = "task-031c-mode-guardrails"
DEVELOP_BASELINE = "1822845e2e1872f923bc1a332c69c10611537be7"
TASK031C_HEAD = "1d8188d4c9e7f540580eebb21a3588e465150ea9"

VALID_BRANCHES = {"develop", AGGREGATE_BRANCH}

ALLOWED_DIFF_PATHS = {
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "scripts/verify_task031_phase1b_preflight.py",
    "scripts/verify_task031_watchos_inventory.py",
    "scripts/verify_task031_mode_guardrails.py",
    "scripts/verify_task031_docs_alignment.py",
}

FORBIDDEN_PATH_PATTERNS = [
    r"^SkateTrack\.xcodeproj/",
    r"^watchOS/",
    r"^Shared/WatchBridge",
    r"\.entitlements$",
    r"\.xcdatamodel",
    r"PersistenceController",
    r"SessionRepository",
    r"SessionEntityMapper",
    r"SnowMode",
    r"SnowRun",
    r"SnowSegment",
    r"SnowPrototype",
    r"iOS/Features/Snow",
    r"watchOS/Features/Snow",
]

STATE_TOKENS = [
    "TASK031D_DOCS_ALIGNMENT_RESULT=PASSED",
    "TASK031D_AGGREGATE_TASK_BRANCH=task-031c-mode-guardrails",
    "TASK031D_MACOS_TEST_POLICY=DOCUMENTED_UNAVAILABLE_NO_MACOS_TEST_TARGET_IN_PBXPROJ",
    "MACOS_TEST_POLICY_CURRENT_STATE=DOCUMENTED_UNAVAILABLE_NO_MACOS_TEST_TARGET_IN_PBXPROJ",
    "WATCH_ROUTE_MINI_CARD_SCOPE=DEFERRED",
    "WATCH_ROUTE_MINI_CARD_REVIEW_AT_TASK036C=YES",
    "TASK031_FINAL_MERGE_TO_DEVELOP_PENDING=YES",
    "NEXT_TASK=Task-032a",
]

DEVLOG_TOKENS = [
    "Task-031d-001 Phase 1b Documentation Alignment",
    "WATCH_ROUTE_MINI_CARD_SCOPE=DEFERRED",
    "WATCH_ROUTE_MINI_CARD_REVIEW_AT_TASK036C=YES",
    "NEXT_TASK=Task-032a",
]

STRUCTURE_TOKENS = [
    "Task-031d Documentation Alignment Addendum",
    "scripts/verify_task031_docs_alignment.py",
    "WATCH_ROUTE_MINI_CARD_REVIEW_AT_TASK036C=YES",
]

LIMITATION_TOKENS = [
    "Task-031d macOS XCTest policy limitation",
    "DOCUMENTED_UNAVAILABLE_NO_MACOS_TEST_TARGET_IN_PBXPROJ",
    "Watch route mini-card deferred pending Task-036c review",
]

failures = 0
warnings = 0


def info(message: str) -> None:
    print(message)


def passed(message: str) -> None:
    print(f"PASS: {message}")


def fail(message: str) -> None:
    global failures
    print(f"FAIL: {message}")
    failures += 1


def run(command: list[str], repo: Path) -> tuple[int, str]:
    try:
        completed = subprocess.run(
            command,
            cwd=str(repo),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return completed.returncode, completed.stdout
    except FileNotFoundError as exc:
        return 127, f"{exc}\n"


def git(args: list[str], repo: Path) -> tuple[int, str]:
    return run(["git", *args], repo)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def require(path: Path) -> str:
    if path.exists():
        passed(f"required path exists: {path.as_posix()}")
        return read(path)
    fail(f"required path missing: {path.as_posix()}")
    return ""


def status_paths(repo: Path) -> list[str]:
    paths: list[str] = []
    for args in (["diff", "--name-only"], ["diff", "--cached", "--name-only"], ["ls-files", "--others", "--exclude-standard"]):
        code, out = git(list(args), repo)
        if code != 0:
            fail(f"unable to read git paths for {' '.join(args)}")
            continue
        for line in out.splitlines():
            line = line.strip()
            if line:
                paths.append(line)
    return sorted(set(paths))


def check_git(repo: Path) -> None:
    info("===== Git / aggregate branch baseline =====")
    code, branch = git(["branch", "--show-current"], repo)
    branch = branch.strip()
    print(f"CURRENT_BRANCH={branch}")
    if code == 0 and branch in VALID_BRANCHES:
        print("TASK031D_BRANCH_CONTEXT=ALLOWED")
        passed("current branch is valid for Task-031d docs alignment")
    else:
        print("TASK031D_BRANCH_CONTEXT=UNEXPECTED")
        fail(f"unexpected branch for Task-031d docs alignment: {branch}")

    code, head = git(["rev-parse", "HEAD"], repo)
    head = head.strip()
    print(f"CURRENT_HEAD_FULL={head}")
    if code != 0:
        fail("unable to read HEAD")

    for label, commit in [
        ("DEVELOP_BASELINE_REACHABLE", DEVELOP_BASELINE),
        ("TASK031C_HEAD_REACHABLE", TASK031C_HEAD),
    ]:
        code, _ = git(["merge-base", "--is-ancestor", commit, "HEAD"], repo)
        print(f"{label}_EXIT={code}")
        if code == 0:
            print(f"{label}=YES")
            passed(f"{commit[:7]} is reachable from HEAD")
        else:
            print(f"{label}=NO")
            fail(f"{commit[:7]} is not reachable from HEAD")


def check_scope(repo: Path) -> None:
    info("===== Task-031d changed-scope guard =====")
    changed = status_paths(repo)
    for path in changed:
        print(f"TASK031D_STATUS_PATH={path}")
    unexpected = [path for path in changed if path not in ALLOWED_DIFF_PATHS]
    print(f"UNEXPECTED_TASK031D_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        fail(f"unexpected Task-031d changed path: {path}")
    if not unexpected:
        passed("changed paths are limited to Task-031d docs/verifier scope")

    forbidden_changed = []
    for path in changed:
        for pattern in FORBIDDEN_PATH_PATTERNS:
            if re.search(pattern, path):
                forbidden_changed.append(path)
                break
    print(f"FORBIDDEN_TASK031D_CHANGED_SCOPE_COUNT={len(set(forbidden_changed))}")
    for path in sorted(set(forbidden_changed)):
        fail(f"forbidden changed path for Task-031d: {path}")
    if not forbidden_changed:
        passed("no product Swift, Xcode project, entitlement, schema, WatchBridge, watchOS, or Snow paths changed")


def check_docs(repo: Path) -> None:
    info("===== Task-031d documentation checkpoints =====")
    state = require(repo / "docs/process/PHASE_1B_AGENT_STATE.md")
    devlog = require(repo / "docs/history/DEV_LOG.md")
    structure = require(repo / "docs/reference/FILE_STRUCTURE.md")
    limitations = require(repo / "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md")

    for token in STATE_TOKENS:
        if token in state:
            passed(f"PHASE_1B_AGENT_STATE.md contains token: {token}")
        else:
            fail(f"PHASE_1B_AGENT_STATE.md missing token: {token}")

    for token in DEVLOG_TOKENS:
        if token in devlog:
            passed(f"DEV_LOG.md contains token: {token}")
        else:
            fail(f"DEV_LOG.md missing token: {token}")

    for token in STRUCTURE_TOKENS:
        if token in structure:
            passed(f"FILE_STRUCTURE.md contains token: {token}")
        else:
            fail(f"FILE_STRUCTURE.md missing token: {token}")

    for token in LIMITATION_TOKENS:
        if token in limitations:
            passed(f"KNOWN_LIMITATIONS_PRE_ADP.md contains token: {token}")
        else:
            fail(f"KNOWN_LIMITATIONS_PRE_ADP.md missing token: {token}")


def check_verifier_inventory(repo: Path) -> None:
    info("===== Task-031 verifier inventory =====")
    required = [
        "scripts/verify_task031_phase1b_preflight.py",
        "scripts/verify_task031_watchos_inventory.py",
        "scripts/verify_task031_mode_guardrails.py",
        "scripts/verify_task031_docs_alignment.py",
    ]
    for relative in required:
        text = require(repo / relative)
        if relative != "scripts/verify_task031_docs_alignment.py":
            if AGGREGATE_BRANCH in text:
                passed(f"{relative} allows aggregate Task-031 branch context")
            else:
                fail(f"{relative} does not include aggregate Task-031 branch context")


def main() -> int:
    repo = Path.cwd()
    info("===== Task-031d docs alignment verifier =====")
    info(f"Aligned Build Plan: {PLAN}")
    info(f"Aligned subtask: {SUBTASK}")
    info("Not implementing: WatchBridge, WatchConnectivity runtime behavior, Watch UI, Snow production, SnowPrototype UI, HealthKit, signing, entitlements, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    info(f"REPO={repo}")

    if not (repo / ".git").exists():
        fail("repo path does not contain .git")
    else:
        passed("repo path contains .git")

    check_git(repo)
    check_scope(repo)
    check_docs(repo)
    check_verifier_inventory(repo)

    info("===== Summary =====")
    print("TASK031D_DOCS_ALIGNMENT_RESULT=PASSED" if failures == 0 else "TASK031D_DOCS_ALIGNMENT_RESULT=FAILED")
    print("TASK031D_MACOS_TEST_POLICY=DOCUMENTED_UNAVAILABLE_NO_MACOS_TEST_TARGET_IN_PBXPROJ")
    print("WATCH_ROUTE_MINI_CARD_SCOPE=DEFERRED")
    print("WATCH_ROUTE_MINI_CARD_REVIEW_AT_TASK036C=YES")
    print("NEXT_TASK=Task-032a")
    print(f"WARNING_COUNT={warnings}")
    print(f"FAILURE_COUNT={failures}")
    print("VERIFY_TASK031D_DOCS_ALIGNMENT_RESULT=PASSED" if failures == 0 else "VERIFY_TASK031D_DOCS_ALIGNMENT_RESULT=FAILED")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
