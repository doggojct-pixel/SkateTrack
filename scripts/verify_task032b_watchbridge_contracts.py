#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

EXPECTED_BASE = "56410ccb13727e6b0e059a2d1ff2015d94333237"
ALLOWED_BRANCHES = {"task-032-watchbridge-foundation", "develop"}
CONTRACT_FILES = [
    Path("Shared/WatchBridge/WatchBridgeEnvelope.swift"),
    Path("Shared/WatchBridge/WatchBridgePayloads.swift"),
    Path("Shared/WatchBridge/WatchBridgeConnectionState.swift"),
    Path("Shared/WatchBridge/WatchBridgeCommandModels.swift"),
]
ALLOWED_STATUS_PATHS = {
    "Shared/WatchBridge/",
    "SkateTrack.xcodeproj/project.pbxproj",
    "Shared/WatchBridge/WatchBridgeEnvelope.swift",
    "Shared/WatchBridge/WatchBridgePayloads.swift",
    "Shared/WatchBridge/WatchBridgeConnectionState.swift",
    "Shared/WatchBridge/WatchBridgeCommandModels.swift",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task032b_watchbridge_contracts.py",
}
FORBIDDEN_RUNTIME_PATTERNS = [
    "WatchConnectivity",
    "WCSession",
    "WCSessionDelegate",
    "sendMessage",
    "updateApplicationContext",
    "transferUserInfo",
    "transferFile",
    "HKWorkout",
    "HKHealthStore",
    "HKLiveWorkoutBuilder",
]
FORBIDDEN_PATH_PATTERNS = [
    re.compile(r"(^|/)watchOS/"),
    re.compile(r"(^|/)iOS/"),
    re.compile(r"(^|/)macOS/"),
    re.compile(r"\.entitlements$"),
    re.compile(r"\.xcdatamodeld?($|/)"),
    re.compile(r"(^|/)Shared/Models/Snow"),
    re.compile(r"SnowPrototype|SnowRun|SnowSegment|SnowDistanceBreakdown"),
]

failure_count = 0
warning_count = 0


def run(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def print_section(title: str) -> None:
    print(f"===== {title} =====")


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def fail_msg(message: str) -> None:
    global failure_count
    failure_count += 1
    print(f"FAIL: {message}")


def warn_msg(message: str) -> None:
    global warning_count
    warning_count += 1
    print(f"WARN: {message}")


def require_path(path: Path) -> None:
    if path.exists():
        pass_msg(f"required path exists: {path}")
    else:
        fail_msg(f"required path missing: {path}")


def require_contains(path: Path, token: str) -> None:
    if not path.exists():
        fail_msg(f"cannot check token because path is missing: {path}")
        return
    text = path.read_text(encoding="utf-8")
    if token in text:
        pass_msg(f"{path} contains token: {token}")
    else:
        fail_msg(f"{path} missing token: {token}")


def status_paths() -> list[str]:
    raw = run(["git", "status", "--porcelain=v1"]).stdout
    paths: list[str] = []
    for line in raw.splitlines():
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path)
    return paths


print_section("Task-032b WatchBridge contracts verifier")
print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
print("Aligned subtask: Task-032b — WatchBridge Contract Models")
print("Not implementing: WatchConnectivity runtime behavior, command mirroring runtime, Watch UI, HealthKit, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
repo = Path.cwd()
print(f"REPO={repo}")

if (repo / ".git").exists():
    pass_msg("repo path contains .git")
else:
    fail_msg("repo path does not contain .git")

print_section("Git baseline")
branch = run(["git", "branch", "--show-current"]).stdout.strip()
head = run(["git", "rev-parse", "HEAD"]).stdout.strip()
print(f"CURRENT_BRANCH={branch}")
print(f"CURRENT_HEAD_FULL={head}")
if branch in ALLOWED_BRANCHES:
    print("TASK032B_BRANCH_CONTEXT=ALLOWED")
    pass_msg("current branch is valid for Task-032b contract verification")
else:
    print("TASK032B_BRANCH_CONTEXT=UNEXPECTED")
    fail_msg(f"unexpected branch for Task-032b: {branch}")

ancestor = run(["git", "merge-base", "--is-ancestor", EXPECTED_BASE, "HEAD"])
print(f"TASK032A_BASE_REACHABLE_EXIT={ancestor.returncode}")
if ancestor.returncode == 0:
    print("TASK032A_BASE_REACHABLE=YES")
    pass_msg("Task-032a branch head 56410cc is reachable from HEAD")
else:
    print("TASK032A_BASE_REACHABLE=NO")
    fail_msg("Task-032a branch head is not reachable from HEAD")

print_section("Task-032b changed-scope guard")
paths = status_paths()
for path in paths:
    print(f"TASK032B_STATUS_PATH={path}")
unexpected = [p for p in paths if p not in ALLOWED_STATUS_PATHS]
print(f"UNEXPECTED_TASK032B_STATUS_PATH_COUNT={len(unexpected)}")
if unexpected:
    for path in unexpected:
        fail_msg(f"unexpected Task-032b status path: {path}")
else:
    pass_msg("changed paths are limited to Task-032b contract/docs/verifier/project membership scope")

forbidden_changed = []
for path in paths:
    if path.startswith("Shared/WatchBridge/"):
        continue
    if path in {"SkateTrack.xcodeproj/project.pbxproj", "docs/history/DEV_LOG.md", "docs/process/PHASE_1B_AGENT_STATE.md", "docs/reference/FILE_STRUCTURE.md", "scripts/verify_task032b_watchbridge_contracts.py"}:
        continue
    if any(pattern.search(path) for pattern in FORBIDDEN_PATH_PATTERNS):
        forbidden_changed.append(path)
print(f"FORBIDDEN_TASK032B_CHANGED_SCOPE_COUNT={len(forbidden_changed)}")
if forbidden_changed:
    for path in forbidden_changed:
        fail_msg(f"forbidden changed path for Task-032b: {path}")
else:
    pass_msg("no watchOS UI, platform UI, entitlement, schema, Snow, or unrelated paths changed")

print_section("Contract files")
for path in CONTRACT_FILES:
    require_path(path)
    if path.exists():
        text = path.read_text(encoding="utf-8")
        first_line = text.splitlines()[0] if text.splitlines() else ""
        line_count = len(text.splitlines())
        print(f"FIRST_LINE[{path}]={first_line}")
        print(f"LINE_COUNT[{path}]={line_count}")
        if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]"):
            pass_msg(f"{path} has a valid collaboration/autonomous header")
        else:
            fail_msg(f"{path} missing valid collaboration/autonomous header")
        if line_count <= 500:
            pass_msg(f"{path} stays under 500 lines")
        else:
            fail_msg(f"{path} exceeds 500 lines")
        runtime_hits = [token for token in FORBIDDEN_RUNTIME_PATTERNS if token in text]
        print(f"FORBIDDEN_RUNTIME_TOKEN_COUNT[{path}]={len(runtime_hits)}")
        if runtime_hits:
            fail_msg(f"{path} contains forbidden runtime tokens: {runtime_hits}")
        else:
            pass_msg(f"{path} contains no WatchConnectivity/HealthKit runtime tokens")

required_tokens = {
    Path("Shared/WatchBridge/WatchBridgeEnvelope.swift"): [
        "public struct WatchBridgeEnvelope",
        "schemaVersion",
        "messageId",
        "correlationId",
        "WatchBridgePayload",
        "Codable",
        "Sendable",
    ],
    Path("Shared/WatchBridge/WatchBridgePayloads.swift"): [
        "public enum WatchBridgePayload",
        "case command",
        "case sessionSnapshot",
        "case compactActivity",
        "WatchBridgeAcknowledgement",
        "WatchBridgeErrorPayload",
    ],
    Path("Shared/WatchBridge/WatchBridgeConnectionState.swift"): [
        "public struct WatchBridgeConnectionState",
        "WatchBridgeConnectionStatus",
        "WatchBridgeTransportQuality",
        "lastUpdatedAt",
    ],
    Path("Shared/WatchBridge/WatchBridgeCommandModels.swift"): [
        "public enum WatchBridgeCommandKind",
        "public enum WatchBridgeSessionState",
        "public struct WatchBridgeCommandEnvelope",
        "requestSnapshot",
        "startSession",
        "pauseSession",
        "resumeSession",
        "endSession",
    ],
}
for path, tokens in required_tokens.items():
    for token in tokens:
        require_contains(path, token)

print_section("Project membership guard")
pbx = Path("SkateTrack.xcodeproj/project.pbxproj")
require_path(pbx)
pbx_text = pbx.read_text(encoding="utf-8") if pbx.exists() else ""
require_contains(pbx, "/* WatchBridge */")
for path in CONTRACT_FILES:
    name = path.name
    token_count = pbx_text.count(name)
    source_membership_count = len(re.findall(rf"/\* {re.escape(name)} in Sources \*/", pbx_text))
    print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
    print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_membership_count}")
    if token_count >= 3:
        pass_msg(f"{name} has project file references")
    else:
        fail_msg(f"{name} has insufficient project tokens")
    if source_membership_count >= 2:
        pass_msg(f"{name} is source-membered for iOS and watchOS")
    else:
        fail_msg(f"{name} is missing required iOS/watchOS source membership")

print_section("Runtime and UI guardrails")
guarded_swift_paths = [
    *CONTRACT_FILES,
]
combined = "\n".join(path.read_text(encoding="utf-8") for path in guarded_swift_paths if path.exists())
watch_connectivity_count = sum(combined.count(token) for token in ["WatchConnectivity", "WCSession", "WCSessionDelegate"])
healthkit_count = sum(combined.count(token) for token in ["HealthKit", "HKWorkout", "HKHealthStore", "HKLiveWorkoutBuilder"])
print(f"WATCHCONNECTIVITY_RUNTIME_TOKEN_COUNT={watch_connectivity_count}")
print(f"HEALTHKIT_RUNTIME_TOKEN_COUNT={healthkit_count}")
if watch_connectivity_count == 0:
    pass_msg("no WatchConnectivity runtime behavior in Task-032b contract files")
else:
    fail_msg("WatchConnectivity runtime behavior found in Task-032b contract files")
if healthkit_count == 0:
    pass_msg("no HealthKit runtime behavior in Task-032b contract files")
else:
    fail_msg("HealthKit runtime behavior found in Task-032b contract files")

print_section("Documentation checkpoints")
state = Path("docs/process/PHASE_1B_AGENT_STATE.md")
file_structure = Path("docs/reference/FILE_STRUCTURE.md")
dev_log = Path("docs/history/DEV_LOG.md")
script = Path("scripts/verify_task032b_watchbridge_contracts.py")
for path in [state, file_structure, dev_log, script]:
    require_path(path)

for token in [
    "TASK032B_WATCHBRIDGE_CONTRACTS_RESULT=PASSED",
    "WATCHBRIDGE_MODELS_IMPLEMENTED=YES",
    "WATCHBRIDGE_CONTRACT_NAMESPACE=Shared/WatchBridge",
    "WATCHBRIDGE_CONTRACT_SCHEMA_VERSION=1",
    "WATCHBRIDGE_CONTRACT_TARGET_MEMBERSHIP=IOS_AND_WATCHOS_REQUIRED_MACOS_OPTIONAL",
    "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO",
    "WATCH_UI_IMPLEMENTED=NO",
    "NEXT_TASK=Task-032c",
]:
    require_contains(state, token)

for token in [
    "Task-032b-001 WatchBridge Contract Models",
    "WATCHBRIDGE_CONTRACT_SCHEMA_VERSION=1",
    "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO",
    "NEXT_TASK=Task-032c",
]:
    require_contains(dev_log, token)

for token in [
    "Task-032b WatchBridge Contracts Addendum",
    "Shared/WatchBridge/WatchBridgeEnvelope.swift",
    "Shared/WatchBridge/WatchBridgePayloads.swift",
    "Shared/WatchBridge/WatchBridgeConnectionState.swift",
    "Shared/WatchBridge/WatchBridgeCommandModels.swift",
    "scripts/verify_task032b_watchbridge_contracts.py",
]:
    require_contains(file_structure, token)

print_section("Summary")
print("TASK032B_WATCHBRIDGE_CONTRACTS_RESULT=PASSED" if failure_count == 0 else "TASK032B_WATCHBRIDGE_CONTRACTS_RESULT=FAILED")
print("WATCHBRIDGE_CONTRACT_SCHEMA_VERSION=1")
print("WATCHBRIDGE_MODELS_IMPLEMENTED=YES" if failure_count == 0 else "WATCHBRIDGE_MODELS_IMPLEMENTED=REVIEW_REQUIRED")
print("WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO")
print("WATCH_UI_IMPLEMENTED=NO")
print("NEXT_TASK=Task-032c")
print(f"WARNING_COUNT={warning_count}")
print(f"FAILURE_COUNT={failure_count}")
print("VERIFY_TASK032B_WATCHBRIDGE_CONTRACTS_RESULT=PASSED" if failure_count == 0 else "VERIFY_TASK032B_WATCHBRIDGE_CONTRACTS_RESULT=FAILED")
sys.exit(1 if failure_count else 0)
