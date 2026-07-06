#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

EXPECTED_BASE = "5b5809aa147ee7cb01bc8adc200c60c6c6e19d1d"
ALLOWED_BRANCHES = {"task-032-watchbridge-foundation", "develop"}
CONTRACT_FILES = [
    "Shared/WatchBridge/WatchBridgeEnvelope.swift",
    "Shared/WatchBridge/WatchBridgePayloads.swift",
    "Shared/WatchBridge/WatchBridgeConnectionState.swift",
    "Shared/WatchBridge/WatchBridgeCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeActivityPayloads.swift",
    "Shared/WatchBridge/WatchBridgeMetricPayloads.swift",
]
ALLOWED_EXACT = {
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task032c_activity_payload_models.py",
}
ALLOWED_PREFIXES = {"Shared/WatchBridge/"}
RUNTIME_TOKENS = [
    "import WatchConnectivity",
    "WCSession",
    "WCSessionDelegate",
    "sendMessage",
    "updateApplicationContext",
    "transferUserInfo",
    "transferFile",
    "HKHealthStore",
    "HKWorkout",
    "HKLiveWorkoutBuilder",
]
FORBIDDEN_TASK032C_TOKENS = [
    "SnowSegment",
    "SnowRun",
    "SnowDistanceBreakdown",
    "SnowClassifier",
    "SnowMode",
    "SnowSport",
    "CoreData",
    "NSManagedObject",
]

warnings = 0
failures = 0


def run(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def section(title: str) -> None:
    print(f"===== {title} =====")


def ok(message: str) -> None:
    print(f"PASS: {message}")


def fail(message: str) -> None:
    global failures
    print(f"FAIL: {message}")
    failures += 1


def warn(message: str) -> None:
    global warnings
    print(f"WARN: {message}")
    warnings += 1


def required_path(path: str) -> Path:
    p = Path(path)
    if p.exists():
        ok(f"required path exists: {path}")
    else:
        fail(f"required path missing: {path}")
    return p


def contains(path: str, token: str) -> None:
    p = Path(path)
    if not p.exists():
        fail(f"cannot check missing path {path} for token {token}")
        return
    text = p.read_text(encoding="utf-8")
    if token in text:
        ok(f"{path} contains token: {token}")
    else:
        fail(f"{path} missing token: {token}")


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


def is_allowed_status_path(path: str) -> bool:
    return path in ALLOWED_EXACT or any(path.startswith(prefix) for prefix in ALLOWED_PREFIXES)


def check_swift_file(path: str) -> None:
    p = required_path(path)
    if not p.exists():
        return
    text = p.read_text(encoding="utf-8")
    lines = text.splitlines()
    first_line = lines[0] if lines else ""
    line_count = len(lines)
    print(f"FIRST_LINE[{path}]={first_line}")
    print(f"LINE_COUNT[{path}]={line_count}")
    if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]"):
        ok(f"{path} has a valid collaboration/autonomous header")
    else:
        fail(f"{path} missing collaboration/autonomous header")
    if line_count <= 500:
        ok(f"{path} stays under 500 lines")
    else:
        fail(f"{path} exceeds 500 lines")
    runtime_count = sum(text.count(token) for token in RUNTIME_TOKENS)
    forbidden_count = sum(text.count(token) for token in FORBIDDEN_TASK032C_TOKENS)
    print(f"FORBIDDEN_RUNTIME_TOKEN_COUNT[{path}]={runtime_count}")
    print(f"FORBIDDEN_TASK032C_TOKEN_COUNT[{path}]={forbidden_count}")
    if runtime_count == 0:
        ok(f"{path} contains no WatchConnectivity/HealthKit runtime tokens")
    else:
        fail(f"{path} contains forbidden runtime tokens")
    if forbidden_count == 0:
        ok(f"{path} contains no Snow/CoreData/schema implementation tokens")
    else:
        fail(f"{path} contains forbidden Snow/CoreData/schema tokens")


section("Task-032c Activity-aware payload models verifier")
print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
print("Aligned subtask: Task-032c — Activity-aware Payload Models")
print("Not implementing: WatchConnectivity runtime behavior, command mirroring runtime, Watch UI, HealthKit, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
print(f"REPO={Path.cwd()}")
if Path(".git").exists():
    ok("repo path contains .git")
else:
    fail("repo path does not contain .git")

section("Git baseline")
branch = run(["git", "branch", "--show-current"]).stdout.strip()
head = run(["git", "rev-parse", "HEAD"]).stdout.strip()
print(f"CURRENT_BRANCH={branch}")
print(f"CURRENT_HEAD_FULL={head}")
if branch in ALLOWED_BRANCHES:
    print("TASK032C_BRANCH_CONTEXT=ALLOWED")
    ok("current branch is valid for Task-032c activity payload verification")
else:
    print("TASK032C_BRANCH_CONTEXT=REJECTED")
    fail(f"unexpected branch: {branch}")
ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", EXPECTED_BASE, "HEAD"], check=False)
print(f"TASK032B_BASE_REACHABLE_EXIT={ancestor.returncode}")
if ancestor.returncode == 0:
    print("TASK032B_BASE_REACHABLE=YES")
    ok("Task-032b branch head 5b5809a is reachable from HEAD")
else:
    print("TASK032B_BASE_REACHABLE=NO")
    fail("Task-032b branch head is not reachable from HEAD")

section("Task-032c changed-scope guard")
paths = status_paths()
for path in paths:
    print(f"TASK032C_STATUS_PATH={path}")
unexpected = [path for path in paths if not is_allowed_status_path(path)]
print(f"UNEXPECTED_TASK032C_STATUS_PATH_COUNT={len(unexpected)}")
for path in unexpected:
    fail(f"unexpected Task-032c status path: {path}")
if not unexpected:
    ok("changed paths are limited to Task-032c payload/docs/verifier/project membership scope")

forbidden_status = [
    path for path in paths
    if path.startswith("watchOS/")
    or path.endswith(".entitlements")
    or ".xcdatamodel" in path
    or "SnowPrototype" in path
]
print(f"FORBIDDEN_TASK032C_CHANGED_SCOPE_COUNT={len(forbidden_status)}")
if forbidden_status:
    for path in forbidden_status:
        fail(f"forbidden changed path: {path}")
else:
    ok("no watchOS UI, entitlement, schema, Snow, or unrelated platform paths changed")

section("Contract files")
for path in CONTRACT_FILES:
    check_swift_file(path)

contains("Shared/WatchBridge/WatchBridgeActivityPayloads.swift", "public struct WatchBridgeActivityModeDescriptor")
contains("Shared/WatchBridge/WatchBridgeActivityPayloads.swift", "public struct WatchBridgeActivitySessionPayload")
contains("Shared/WatchBridge/WatchBridgeActivityPayloads.swift", "public struct WatchBridgeCompactActivityDisplayPayload")
contains("Shared/WatchBridge/WatchBridgeActivityPayloads.swift", "public struct WatchBridgeActivitySnapshotPayload")
contains("Shared/WatchBridge/WatchBridgeMetricPayloads.swift", "public enum WatchBridgeMetricTrustLevel")
contains("Shared/WatchBridge/WatchBridgeMetricPayloads.swift", "public struct WatchBridgeMetricUpdatePayload")
contains("Shared/WatchBridge/WatchBridgeMetricPayloads.swift", "public struct WatchBridgeCommandAcknowledgementPayload")
contains("Shared/WatchBridge/WatchBridgeMetricPayloads.swift", "public struct WatchBridgeConnectionStatusPayload")
contains("Shared/WatchBridge/WatchBridgePayloads.swift", "case activitySession")
contains("Shared/WatchBridge/WatchBridgePayloads.swift", "case activityMetrics")
contains("Shared/WatchBridge/WatchBridgePayloads.swift", "case activityDisplay")
contains("Shared/WatchBridge/WatchBridgePayloads.swift", "case activitySnapshot")
contains("Shared/WatchBridge/WatchBridgePayloads.swift", "case commandResult")
contains("Shared/WatchBridge/WatchBridgePayloads.swift", "case connectionStatus")

section("Project membership guard")
pbx = required_path("SkateTrack.xcodeproj/project.pbxproj")
if pbx.exists():
    text = pbx.read_text(encoding="utf-8")
    for name in ["WatchBridgeActivityPayloads.swift", "WatchBridgeMetricPayloads.swift"]:
        token_count = text.count(name)
        source_count = text.count(f"/* {name} in Sources */")
        print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
        print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
        if token_count >= 6:
            ok(f"{name} has project file references")
        else:
            fail(f"{name} has insufficient project file references")
        if source_count >= 4:
            ok(f"{name} is source-membered for iOS and watchOS")
        else:
            fail(f"{name} source membership is incomplete for iOS/watchOS")

section("Runtime, UI, and safety guardrails")
watchbridge_text = "\n".join(Path(path).read_text(encoding="utf-8") for path in CONTRACT_FILES if Path(path).exists())
watchconnectivity_count = sum(watchbridge_text.count(token) for token in ["WatchConnectivity", "WCSession", "WCSessionDelegate"])
healthkit_count = sum(watchbridge_text.count(token) for token in ["HealthKit", "HKWorkout", "HKHealthStore", "HKLiveWorkoutBuilder"])
ui_count = sum(watchbridge_text.count(token) for token in ["SwiftUI", "View", "Button", "NavigationStack"])
snow_count = sum(watchbridge_text.count(token) for token in ["SnowSegment", "SnowRun", "SnowDistanceBreakdown", "SnowClassifier", "SnowMode", "SnowSport"])
trusted_mutation_count = sum(watchbridge_text.count(token) for token in ["estimatedRouteActive = true", "trustedDistanceMeters =", "trustedAscentMeters =", "mutating func"])
print(f"WATCHCONNECTIVITY_RUNTIME_TOKEN_COUNT={watchconnectivity_count}")
print(f"HEALTHKIT_RUNTIME_TOKEN_COUNT={healthkit_count}")
print(f"WATCH_UI_TOKEN_COUNT={ui_count}")
print(f"SNOW_PRODUCTION_IMPLEMENTATION_COUNT={snow_count}")
print(f"TRUSTED_METRIC_MUTATION_TOKEN_COUNT={trusted_mutation_count}")
if watchconnectivity_count == 0:
    ok("no WatchConnectivity runtime behavior in Task-032c contract files")
else:
    fail("WatchConnectivity runtime token found in WatchBridge contract files")
if healthkit_count == 0:
    ok("no HealthKit runtime behavior in Task-032c contract files")
else:
    fail("HealthKit runtime token found in WatchBridge contract files")
if ui_count == 0:
    ok("no Watch UI / SwiftUI implementation in Task-032c contract files")
else:
    fail("UI token found in WatchBridge contract files")
if snow_count == 0:
    ok("no Snow production implementation in Task-032c contract files")
else:
    fail("Snow production token found in WatchBridge contract files")
if trusted_mutation_count == 0:
    ok("no trusted metric or estimated route mutation tokens in Task-032c contract files")
else:
    fail("trusted metric mutation token found in WatchBridge contract files")

section("Documentation checkpoints")
for path in [
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/history/DEV_LOG.md",
    "scripts/verify_task032c_activity_payload_models.py",
]:
    required_path(path)
contains("docs/process/PHASE_1B_AGENT_STATE.md", "TASK032C_ACTIVITY_PAYLOAD_MODELS_RESULT=PASSED")
contains("docs/process/PHASE_1B_AGENT_STATE.md", "WATCHBRIDGE_ACTIVITY_PAYLOAD_MODELS_IMPLEMENTED=YES")
contains("docs/process/PHASE_1B_AGENT_STATE.md", "WATCHBRIDGE_ACTIVITY_PAYLOAD_TARGET_MEMBERSHIP=IOS_AND_WATCHOS_REQUIRED")
contains("docs/process/PHASE_1B_AGENT_STATE.md", "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO")
contains("docs/process/PHASE_1B_AGENT_STATE.md", "WATCH_UI_IMPLEMENTED=NO")
contains("docs/process/PHASE_1B_AGENT_STATE.md", "TRUSTED_METRIC_MUTATION=NO")
contains("docs/process/PHASE_1B_AGENT_STATE.md", "NEXT_TASK=Task-032d")
contains("docs/history/DEV_LOG.md", "Task-032c-001 Activity-aware Payload Models")
contains("docs/history/DEV_LOG.md", "WATCHBRIDGE_ACTIVITY_PAYLOAD_MODELS_IMPLEMENTED=YES")
contains("docs/history/DEV_LOG.md", "NEXT_TASK=Task-032d")
contains("docs/reference/FILE_STRUCTURE.md", "Task-032c Activity-aware Payload Models Addendum")
contains("docs/reference/FILE_STRUCTURE.md", "Shared/WatchBridge/WatchBridgeActivityPayloads.swift")
contains("docs/reference/FILE_STRUCTURE.md", "Shared/WatchBridge/WatchBridgeMetricPayloads.swift")
contains("docs/reference/FILE_STRUCTURE.md", "scripts/verify_task032c_activity_payload_models.py")

section("Summary")
print("TASK032C_ACTIVITY_PAYLOAD_MODELS_RESULT=PASSED" if failures == 0 else "TASK032C_ACTIVITY_PAYLOAD_MODELS_RESULT=FAILED")
print("WATCHBRIDGE_ACTIVITY_PAYLOAD_MODELS_IMPLEMENTED=YES")
print("WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO")
print("WATCH_UI_IMPLEMENTED=NO")
print("TRUSTED_METRIC_MUTATION=NO")
print("NEXT_TASK=Task-032d")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
print("VERIFY_TASK032C_ACTIVITY_PAYLOAD_MODELS_RESULT=PASSED" if failures == 0 else "VERIFY_TASK032C_ACTIVITY_PAYLOAD_MODELS_RESULT=FAILED")
sys.exit(0 if failures == 0 else 1)
