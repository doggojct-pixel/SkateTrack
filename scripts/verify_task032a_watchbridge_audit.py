#!/usr/bin/env python3
# [協作區] scripts/verify_task032a_watchbridge_audit.py

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

EXPECTED_DEVELOP_HEAD = "891d460f8e221c50729201880102d554b01127ad"
TASK_BRANCH = "task-032-watchbridge-foundation"
ALLOWED_BRANCHES = {"develop", TASK_BRANCH}

ALLOWED_STATUS_PATHS = {
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/adr/ADR-WatchBridge-Contract-Placement.md",
    "scripts/verify_task032a_watchbridge_audit.py",
}

FORBIDDEN_CHANGED_PATTERNS = (
    r"\.swift$",
    r"^SkateTrack\.xcodeproj/",
    r"\.entitlements$",
    r"\.xcdatamodel",
    r"\.xcdatamodeld",
    r"PersistenceController",
    r"SessionRepository",
    r"SessionEntityMapper",
    r"^watchOS/",
    r"^Shared/WatchBridge/",
    r"(^Shared/Models/Snow|SnowMode|SnowSport|SnowSession|SnowRun|SnowSegment|SnowPrototype|watchOS/Features/Snow|iOS/Features/Snow)",
)

SOURCE_SCAN_DIRS = ["Shared", "iOS", "macOS", "watchOS", "Tests"]
WATCHCONNECTIVITY_RUNTIME_RE = re.compile(
    r"\b(import\s+WatchConnectivity|WCSession|WCSessionDelegate|sendMessage\s*\(|updateApplicationContext\s*\(|transferUserInfo\s*\(|transferFile\s*\()"
)
HEALTHKIT_RUNTIME_RE = re.compile(r"\b(import\s+HealthKit|HKWorkout|HKLiveWorkoutBuilder|HKHealthStore)\b")

failure_count = 0
warning_count = 0


def run(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, text=True, capture_output=True, check=False)


def emit(line: str = "") -> None:
    print(line)


def fail(message: str) -> None:
    global failure_count
    emit(f"FAIL: {message}")
    failure_count += 1


def warn(message: str) -> None:
    global warning_count
    emit(f"WARN: {message}")
    warning_count += 1


def pass_msg(message: str) -> None:
    emit(f"PASS: {message}")


def required_path(repo: Path, rel: str) -> Path:
    path = repo / rel
    if path.exists():
        pass_msg(f"required path exists: {rel}")
    else:
        fail(f"required path missing: {rel}")
    return path


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def changed_paths(repo: Path) -> list[str]:
    result = run(["git", "status", "--porcelain=v1"], repo)
    paths: list[str] = []
    for line in result.stdout.splitlines():
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path)
    return paths


def git_grep_count(repo: Path, pattern: str, paths: list[str]) -> int:
    args = ["git", "grep", "-n", pattern, "--", *paths]
    result = run(args, repo)
    if result.returncode not in (0, 1):
        warn(f"git grep returned {result.returncode} for pattern {pattern!r}")
    return len([line for line in result.stdout.splitlines() if line.strip()])


def scan_source_files(repo: Path, pattern: re.Pattern[str]) -> list[str]:
    hits: list[str] = []
    for root in SOURCE_SCAN_DIRS:
        base = repo / root
        if not base.exists():
            continue
        for path in base.rglob("*.swift"):
            rel = path.relative_to(repo).as_posix()
            text = read_text(path)
            if pattern.search(text):
                hits.append(rel)
    return hits


def require_tokens(path: Path, label: str, tokens: list[str]) -> None:
    text = read_text(path)
    for token in tokens:
        if token in text:
            pass_msg(f"{label} contains token: {token}")
        else:
            fail(f"{label} missing token: {token}")


def main() -> int:
    repo = Path.cwd()
    emit("===== Task-032a WatchBridge audit verifier =====")
    emit("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    emit("Aligned subtask: Task-032a — WatchBridge Source Audit + Contract Placement")
    emit("Not implementing: WatchBridge models, WatchConnectivity runtime behavior, command mirroring, Watch UI, HealthKit, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    emit(f"REPO={repo}")

    if (repo / ".git").exists():
        pass_msg("repo path contains .git")
    else:
        fail("repo path does not contain .git")

    emit("===== Git baseline =====")
    branch = run(["git", "branch", "--show-current"], repo).stdout.strip()
    head = run(["git", "rev-parse", "HEAD"], repo).stdout.strip()
    emit(f"CURRENT_BRANCH={branch}")
    emit(f"CURRENT_HEAD_FULL={head}")

    if branch in ALLOWED_BRANCHES:
        emit("TASK032A_BRANCH_CONTEXT=ALLOWED")
        pass_msg("current branch is valid for Task-032a audit verification")
    else:
        emit("TASK032A_BRANCH_CONTEXT=UNEXPECTED")
        fail(f"unexpected branch for Task-032a: {branch}")

    ancestor = run(["git", "merge-base", "--is-ancestor", EXPECTED_DEVELOP_HEAD, "HEAD"], repo)
    emit(f"DEVELOP_BASELINE_REACHABLE_EXIT={ancestor.returncode}")
    if ancestor.returncode == 0:
        emit("DEVELOP_BASELINE_REACHABLE=YES")
        pass_msg(f"{EXPECTED_DEVELOP_HEAD[:7]} is reachable from HEAD")
    else:
        emit("DEVELOP_BASELINE_REACHABLE=NO")
        fail(f"expected develop baseline {EXPECTED_DEVELOP_HEAD[:7]} is not reachable from HEAD")

    emit("===== Task-032a changed-scope guard =====")
    status_paths = changed_paths(repo)
    unexpected = [path for path in status_paths if path not in ALLOWED_STATUS_PATHS]
    for path in status_paths:
        emit(f"TASK032A_STATUS_PATH={path}")
    emit(f"UNEXPECTED_TASK032A_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        fail(f"unexpected Task-032a status path: {path}")
    if not unexpected:
        pass_msg("changed paths are limited to Task-032a docs/verifier scope")

    forbidden_changed = []
    for path in status_paths:
        if any(re.search(pattern, path) for pattern in FORBIDDEN_CHANGED_PATTERNS):
            forbidden_changed.append(path)
    emit(f"FORBIDDEN_TASK032A_CHANGED_SCOPE_COUNT={len(forbidden_changed)}")
    for path in forbidden_changed:
        fail(f"forbidden changed path for Task-032a: {path}")
    if not forbidden_changed:
        pass_msg("no product Swift, Xcode project, entitlement, schema, WatchBridge source, watchOS, or Snow paths changed")

    emit("===== Required audit inputs and docs =====")
    phase_state = required_path(repo, "docs/process/PHASE_1B_AGENT_STATE.md")
    dev_log = required_path(repo, "docs/history/DEV_LOG.md")
    file_structure = required_path(repo, "docs/reference/FILE_STRUCTURE.md")
    adr_index = required_path(repo, "docs/adr/ADR-INDEX.md")
    adr = required_path(repo, "docs/adr/ADR-WatchBridge-Contract-Placement.md")
    verifier = required_path(repo, "scripts/verify_task032a_watchbridge_audit.py")
    required_path(repo, "watchOS/App/SkateTrackWatchApp.swift")

    shared_watchbridge_path = repo / "Shared/WatchBridge"
    if shared_watchbridge_path.exists():
        emit("SHARED_WATCHBRIDGE_PATH_STATUS=PRESENT_UNEXPECTED_FOR_TASK032A")
        fail("Shared/WatchBridge should not be created by Task-032a docs/audit-only work")
    else:
        emit("SHARED_WATCHBRIDGE_PATH_STATUS=ABSENT_EXPECTED_UNTIL_TASK032B")
        pass_msg("Shared/WatchBridge remains absent until Task-032b creates contract files")

    emit("===== WatchConnectivity / duplicate layer audit =====")
    watchconnectivity_files = scan_source_files(repo, WATCHCONNECTIVITY_RUNTIME_RE)
    healthkit_files = scan_source_files(repo, HEALTHKIT_RUNTIME_RE)
    duplicate_bridge_count = len(watchconnectivity_files)
    emit(f"WATCHCONNECTIVITY_RUNTIME_FILE_COUNT={len(watchconnectivity_files)}")
    for path in watchconnectivity_files:
        emit(f"WATCHCONNECTIVITY_RUNTIME_FILE={path}")
    if not watchconnectivity_files:
        pass_msg("no runtime WatchConnectivity implementation exists in guarded Swift source paths")
    else:
        fail("runtime WatchConnectivity files already exist before Task-033a")

    emit(f"DUPLICATE_WATCHBRIDGE_LAYER_COUNT={duplicate_bridge_count}")
    if duplicate_bridge_count == 0:
        pass_msg("no duplicate WatchBridge runtime layer exists")
    else:
        fail("duplicate WatchBridge layer candidate count must remain zero")

    emit(f"HEALTHKIT_RUNTIME_FILE_COUNT={len(healthkit_files)}")
    if not healthkit_files:
        pass_msg("no HealthKit runtime implementation exists in guarded WatchBridge/source paths")
    else:
        for path in healthkit_files:
            emit(f"HEALTHKIT_RUNTIME_FILE={path}")
        fail("HealthKit runtime should not be introduced by Task-032a")

    watchbridge_doc_count = git_grep_count(repo, "WatchBridge", ["docs", "scripts"])
    emit(f"WATCHBRIDGE_DOC_TOKEN_COUNT={watchbridge_doc_count}")

    emit("===== Documentation checkpoints =====")
    require_tokens(
        phase_state,
        "PHASE_1B_AGENT_STATE.md",
        [
            "TASK032A_WATCHBRIDGE_AUDIT_RESULT=PASSED",
            "TASK032_AGGREGATE_TASK_BRANCH=task-032-watchbridge-foundation",
            "CONTRACT_PLACEMENT_DECIDED=YES",
            "WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge",
            "WATCHBRIDGE_CONTRACT_CREATION_TASK=Task-032b",
            "WATCHBRIDGE_RUNTIME_CREATION_TASK=Task-033a",
            "WATCHBRIDGE_TARGET_MEMBERSHIP_PLAN=IOS_AND_WATCHOS_REQUIRED_MACOS_OPTIONAL_FOR_COMPILE_ONLY_TOOLS",
            "DUPLICATE_WATCHBRIDGE_LAYER_COUNT=0",
            "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO",
            "WATCH_UI_IMPLEMENTED=NO",
            "NEXT_TASK=Task-032b",
        ],
    )
    require_tokens(
        dev_log,
        "DEV_LOG.md",
        [
            "Task-032a-001 WatchBridge Source Audit + Contract Placement",
            "CONTRACT_PLACEMENT_DECIDED=YES",
            "DUPLICATE_WATCHBRIDGE_LAYER_COUNT=0",
            "NEXT_TASK=Task-032b",
        ],
    )
    require_tokens(
        file_structure,
        "FILE_STRUCTURE.md",
        [
            "Task-032a WatchBridge Audit Addendum",
            "scripts/verify_task032a_watchbridge_audit.py",
            "docs/adr/ADR-WatchBridge-Contract-Placement.md",
            "Shared/WatchBridge/WatchBridgeEnvelope.swift",
        ],
    )
    require_tokens(
        adr_index,
        "ADR-INDEX.md",
        [
            "ADR-WatchBridge-Contract-Placement.md",
            "WatchBridge Contract Placement",
        ],
    )
    require_tokens(
        adr,
        "ADR-WatchBridge-Contract-Placement.md",
        [
            "CONTRACT_PLACEMENT_DECIDED=YES",
            "WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge",
            "Shared/WatchBridge/WatchBridgeEnvelope.swift",
            "WATCHBRIDGE_TARGET_MEMBERSHIP_PLAN=IOS_AND_WATCHOS_REQUIRED_MACOS_OPTIONAL_FOR_COMPILE_ONLY_TOOLS",
            "WatchConnectivity runtime behavior",
            "Task-033a owns the first real WatchConnectivity boundary shell",
        ],
    )

    emit("===== Summary =====")
    emit("TASK032A_WATCHBRIDGE_AUDIT_RESULT=PASSED" if failure_count == 0 else "TASK032A_WATCHBRIDGE_AUDIT_RESULT=FAILED")
    emit("CONTRACT_PLACEMENT_DECIDED=YES")
    emit("WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge")
    emit("WATCHBRIDGE_TARGET_MEMBERSHIP_PLAN=IOS_AND_WATCHOS_REQUIRED_MACOS_OPTIONAL_FOR_COMPILE_ONLY_TOOLS")
    emit(f"DUPLICATE_WATCHBRIDGE_LAYER_COUNT={duplicate_bridge_count}")
    emit(f"WARNING_COUNT={warning_count}")
    emit(f"FAILURE_COUNT={failure_count}")
    emit("VERIFY_TASK032A_WATCHBRIDGE_AUDIT_RESULT=PASSED" if failure_count == 0 else "VERIFY_TASK032A_WATCHBRIDGE_AUDIT_RESULT=FAILED")

    return 0 if failure_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
