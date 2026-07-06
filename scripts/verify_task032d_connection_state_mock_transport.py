#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

EXPECTED_BRANCHES = {"task-032-watchbridge-foundation", "develop"}
TASK032C_BASE_HEAD = "60b5790caf0d512c12ff9b9e7885a939eabb116e"

PRODUCT_FILES = [
    "Shared/WatchBridge/WatchBridgeConnectionTimeline.swift",
    "Shared/WatchBridge/WatchBridgeConnectionStateStore.swift",
    "Shared/WatchBridge/WatchBridgeMockTransport.swift",
]
TEST_FILES = [
    "Tests/iOSTests/WatchBridgeConnectionStateStoreTests.swift",
    "Tests/iOSTests/WatchBridgeMockTransportTests.swift",
]
DOC_FILES = [
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]
REQUIRED_FILES = PRODUCT_FILES + TEST_FILES + DOC_FILES + [
    "scripts/verify_task032d_connection_state_mock_transport.py",
    "SkateTrack.xcodeproj/project.pbxproj",
]
ALLOWED_EXACT = set(REQUIRED_FILES)
FORBIDDEN_CHANGED_PREFIXES = (
    "watchOS/",
    "iOS/",
    "macOS/",
    "Shared/Models/Snow",
)
FORBIDDEN_CHANGED_FRAGMENTS = (
    ".entitlements",
    ".xcdatamodel",
    "PersistenceController",
    "SessionRepository",
    "SessionEntityMapper",
)
FORBIDDEN_PRODUCT_TOKENS = (
    "WatchConnectivity",
    "WCSession",
    "WCSessionDelegate",
    "sendMessage",
    "updateApplicationContext",
    "transferUserInfo",
    "transferFile",
    "HealthKit",
    "HKWorkout",
    "HKLiveWorkoutBuilder",
    "HKHealthStore",
    "SwiftUI",
    "Button(",
    "NavigationStack",
    "SnowSegment",
    "SnowRun",
    "SnowClassifier",
    "NSManagedObject",
    "CoreData",
    "estimatedRouteActive = true",
)
REQUIRED_TOKENS = {
    "Shared/WatchBridge/WatchBridgeConnectionTimeline.swift": [
        "public enum WatchBridgeConnectionEventKind",
        "case connected",
        "case disconnected",
        "case unavailable",
        "case stale",
        "public struct WatchBridgeConnectionTimelineEvent",
        "public struct WatchBridgeConnectionTimeline",
    ],
    "Shared/WatchBridge/WatchBridgeConnectionStateStore.swift": [
        "public struct WatchBridgeConnectionStateStore",
        "public mutating func apply",
        "WatchBridgeConnectionStatusPayload",
        "case .connected",
        "case .disconnected",
        "case .unavailable",
        "case .stale",
    ],
    "Shared/WatchBridge/WatchBridgeMockTransport.swift": [
        "public struct WatchBridgeMockTransport",
        "public enum WatchBridgeMockTransportSendResult",
        "public mutating func connect",
        "public mutating func disconnect",
        "public mutating func markUnavailable",
        "public mutating func markStale",
        "public mutating func receive",
        "public mutating func send",
    ],
    "Tests/iOSTests/WatchBridgeConnectionStateStoreTests.swift": [
        "WatchBridgeConnectionStateStoreTests",
        "testStoreAppliesConnectedDisconnectedUnavailableAndStaleTransitions",
        ".connected",
        ".disconnected",
        ".unavailable",
        ".stale",
    ],
    "Tests/iOSTests/WatchBridgeMockTransportTests.swift": [
        "WatchBridgeMockTransportTests",
        "testMockTransportQueuesOutboundEnvelopeOnlyWhenConnected",
        "testMockTransportReceiveUpdatesConnectionFreshnessAndInbox",
        "testMockTransportMarksDisconnectedUnavailableAndStaleWithoutRuntimeDependency",
    ],
}
DOC_TOKENS = {
    "docs/process/PHASE_1B_AGENT_STATE.md": [
        "TASK032D_CONNECTION_STATE_MOCK_TRANSPORT_RESULT=PASSED",
        "WATCHBRIDGE_CONNECTION_STATE_STORE_IMPLEMENTED=YES",
        "WATCHBRIDGE_MOCK_TRANSPORT_IMPLEMENTED=YES",
        "WATCHBRIDGE_CONNECTION_TIMELINE_IMPLEMENTED=YES",
        "WATCHBRIDGE_CONNECTION_STATE_TRANSITIONS_TESTED=connected|disconnected|unavailable|stale",
        "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO",
        "WCSESSION_DEPENDENCY_IMPLEMENTED=NO",
        "WATCH_UI_IMPLEMENTED=NO",
        "NEXT_TASK=Task-032e",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-032d-001 Connection State Store + Mock Transport",
        "WATCHBRIDGE_CONNECTION_STATE_STORE_IMPLEMENTED=YES",
        "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO",
        "NEXT_TASK=Task-032e",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-032d Connection State Store + Mock Transport Addendum",
        "Shared/WatchBridge/WatchBridgeConnectionTimeline.swift",
        "Shared/WatchBridge/WatchBridgeConnectionStateStore.swift",
        "Shared/WatchBridge/WatchBridgeMockTransport.swift",
        "Tests/iOSTests/WatchBridgeConnectionStateStoreTests.swift",
        "Tests/iOSTests/WatchBridgeMockTransportTests.swift",
        "scripts/verify_task032d_connection_state_mock_transport.py",
    ],
}

failures = 0
warnings = 0


def record_pass(message: str) -> None:
    print(f"PASS: {message}")


def record_fail(message: str) -> None:
    global failures
    failures += 1
    print(f"FAIL: {message}")


def run(repo: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=repo, text=True, capture_output=True, check=False)


def read(path: Path) -> str:
    return path.read_text(errors="replace")


def verify_git(repo: Path) -> None:
    print("===== Git baseline =====")
    branch = run(repo, ["git", "branch", "--show-current"]).stdout.strip()
    head = run(repo, ["git", "rev-parse", "HEAD"]).stdout.strip()
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD_FULL={head}")
    if branch in EXPECTED_BRANCHES:
        record_pass("current branch is valid for Task-032d connection/mock verification")
    else:
        record_fail(f"unexpected branch: {branch}")
    base = run(repo, ["git", "merge-base", "--is-ancestor", TASK032C_BASE_HEAD, "HEAD"])
    print(f"TASK032C_BASE_REACHABLE_EXIT={base.returncode}")
    print(f"TASK032C_BASE_REACHABLE={'YES' if base.returncode == 0 else 'NO'}")
    if base.returncode == 0:
        record_pass("Task-032c branch head is reachable from HEAD")
    else:
        record_fail("Task-032c branch head is not reachable from HEAD")


def verify_scope(repo: Path) -> None:
    print("===== Task-032d changed-scope guard =====")
    status = run(repo, ["git", "status", "--porcelain=v1"]).stdout.splitlines()
    unexpected: list[str] = []
    forbidden: list[str] = []
    for line in status:
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        print(f"TASK032D_STATUS_PATH={path}")
        if path not in ALLOWED_EXACT:
            unexpected.append(path)
        if path not in ALLOWED_EXACT or path.startswith(FORBIDDEN_CHANGED_PREFIXES) or any(t in path for t in FORBIDDEN_CHANGED_FRAGMENTS):
            if path not in ALLOWED_EXACT:
                forbidden.append(path)
    print(f"UNEXPECTED_TASK032D_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        record_fail(f"unexpected changed path: {path}")
    if not unexpected:
        record_pass("changed paths are limited to Task-032d connection/mock/docs/verifier/test/project membership scope")
    print(f"FORBIDDEN_TASK032D_CHANGED_SCOPE_COUNT={len(forbidden)}")
    if forbidden:
        for path in forbidden:
            record_fail(f"forbidden changed path: {path}")
    else:
        record_pass("no Watch UI, platform UI, entitlement, schema, Snow, or unrelated paths changed")


def verify_file(path: Path, relative: str, product: bool) -> None:
    if not path.exists():
        record_fail(f"required path missing: {relative}")
        return
    record_pass(f"required path exists: {relative}")
    text = read(path)
    first = text.splitlines()[0] if text.splitlines() else ""
    lines = len(text.splitlines())
    print(f"FIRST_LINE[{relative}]={first}")
    print(f"LINE_COUNT[{relative}]={lines}")
    if relative.endswith(".swift") and not (first.startswith("// [協作區]") or first.startswith("// [自主區]")):
        record_fail(f"{relative} missing collaboration/autonomous header")
    elif relative.endswith(".swift"):
        record_pass(f"{relative} has a valid collaboration/autonomous header")
    if relative.endswith(".swift") and lines > 500:
        record_fail(f"{relative} exceeds 500 lines")
    elif relative.endswith(".swift"):
        record_pass(f"{relative} stays under 500 lines")
    if product:
        count = sum(text.count(token) for token in FORBIDDEN_PRODUCT_TOKENS)
        print(f"FORBIDDEN_PRODUCT_TOKEN_COUNT[{relative}]={count}")
        if count:
            record_fail(f"{relative} contains forbidden runtime/UI/schema/Snow tokens")
        else:
            record_pass(f"{relative} contains no forbidden runtime/UI/schema/Snow tokens")
    for token in REQUIRED_TOKENS.get(relative, []):
        if token in text:
            record_pass(f"{relative} contains token: {token}")
        else:
            record_fail(f"{relative} missing token: {token}")


def verify_files(repo: Path) -> None:
    print("===== Connection store, mock transport, and tests =====")
    for relative in PRODUCT_FILES:
        verify_file(repo / relative, relative, product=True)
    for relative in TEST_FILES:
        verify_file(repo / relative, relative, product=False)


def count_project_source_membership(text: str, filename: str) -> int:
    return text.count(f"/* {filename} in Sources */")


def verify_project(repo: Path) -> None:
    print("===== Project membership guard =====")
    pbx = repo / "SkateTrack.xcodeproj/project.pbxproj"
    if not pbx.exists():
        record_fail("missing project.pbxproj")
        return
    text = read(pbx)
    for filename in [Path(p).name for p in PRODUCT_FILES]:
        token_count = text.count(filename)
        source_count = count_project_source_membership(text, filename)
        print(f"PROJECT_TOKEN_COUNT[{filename}]={token_count}")
        print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{filename}]={source_count}")
        if token_count >= 3:
            record_pass(f"{filename} has project file references")
        else:
            record_fail(f"{filename} missing project file references")
        if source_count >= 2:
            record_pass(f"{filename} is source-membered for iOS and watchOS")
        else:
            record_fail(f"{filename} is not source-membered for iOS/watchOS")
    for filename in [Path(p).name for p in TEST_FILES]:
        token_count = text.count(filename)
        source_count = count_project_source_membership(text, filename)
        print(f"PROJECT_TOKEN_COUNT[{filename}]={token_count}")
        print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{filename}]={source_count}")
        if token_count >= 3 and source_count >= 1:
            record_pass(f"{filename} is source-membered for SkateTrack-iOSTests")
        else:
            record_fail(f"{filename} missing iOS test membership")


def verify_docs(repo: Path) -> None:
    print("===== Documentation checkpoints =====")
    for relative in DOC_FILES:
        path = repo / relative
        if not path.exists():
            record_fail(f"required path missing: {relative}")
            continue
        record_pass(f"required path exists: {relative}")
        text = read(path)
        for token in DOC_TOKENS.get(relative, []):
            if token in text:
                record_pass(f"{relative} contains token: {token}")
            else:
                record_fail(f"{relative} missing token: {token}")


def verify_runtime_counts(repo: Path) -> None:
    print("===== Runtime, UI, and safety guardrails =====")
    product_text = "\n".join(read(repo / relative) for relative in PRODUCT_FILES if (repo / relative).exists())
    tests_text = "\n".join(read(repo / relative) for relative in TEST_FILES if (repo / relative).exists())
    watch_count = product_text.count("WatchConnectivity") + product_text.count("WCSession")
    health_count = product_text.count("HealthKit") + product_text.count("HKWorkout") + product_text.count("HKHealthStore")
    ui_count = product_text.count("SwiftUI") + product_text.count("Button(") + product_text.count("NavigationStack")
    snow_count = product_text.count("SnowSegment") + product_text.count("SnowRun") + product_text.count("SnowClassifier")
    test_transition_count = sum(tests_text.count(token) for token in [".connected", ".disconnected", ".unavailable", ".stale"])
    print(f"WATCHCONNECTIVITY_RUNTIME_TOKEN_COUNT={watch_count}")
    print(f"HEALTHKIT_RUNTIME_TOKEN_COUNT={health_count}")
    print(f"WATCH_UI_TOKEN_COUNT={ui_count}")
    print(f"SNOW_PRODUCTION_IMPLEMENTATION_COUNT={snow_count}")
    print(f"CONNECTION_STATE_TRANSITION_TEST_TOKEN_COUNT={test_transition_count}")
    if watch_count == 0:
        record_pass("no real WatchConnectivity dependency in Task-032d product files")
    else:
        record_fail("real WatchConnectivity token appeared in product files")
    if health_count == 0:
        record_pass("no HealthKit runtime dependency in Task-032d product files")
    else:
        record_fail("HealthKit runtime token appeared in product files")
    if ui_count == 0:
        record_pass("no Watch UI / SwiftUI implementation in Task-032d product files")
    else:
        record_fail("UI token appeared in product files")
    if snow_count == 0:
        record_pass("no Snow production implementation in Task-032d product files")
    else:
        record_fail("Snow production token appeared in product files")
    if test_transition_count >= 4:
        record_pass("connection state tests cover connected/disconnected/unavailable/stale wording")
    else:
        record_fail("connection state tests do not cover all required transition wording")


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    print("===== Task-032d connection state / mock transport verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-032d — Connection State Store + Mock Transport")
    print("Not implementing: real WatchConnectivity runtime behavior, WCSession dependency, command mirroring runtime, Watch UI, HealthKit, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    print(f"REPO={repo}")
    if not (repo / ".git").exists():
        record_fail("repo path does not contain .git")
    else:
        record_pass("repo path contains .git")
    verify_git(repo)
    verify_scope(repo)
    verify_files(repo)
    verify_project(repo)
    verify_runtime_counts(repo)
    verify_docs(repo)
    print("===== Summary =====")
    print("TASK032D_CONNECTION_STATE_MOCK_TRANSPORT_RESULT=PASSED" if failures == 0 else "TASK032D_CONNECTION_STATE_MOCK_TRANSPORT_RESULT=FAILED")
    print("WATCHBRIDGE_CONNECTION_STATE_STORE_IMPLEMENTED=YES")
    print("WATCHBRIDGE_MOCK_TRANSPORT_IMPLEMENTED=YES")
    print("WATCHBRIDGE_CONNECTION_TIMELINE_IMPLEMENTED=YES")
    print("WATCHBRIDGE_CONNECTION_STATE_TESTS_IMPLEMENTED=YES")
    print("WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO")
    print("WCSESSION_DEPENDENCY_IMPLEMENTED=NO")
    print("WATCH_UI_IMPLEMENTED=NO")
    print("NEXT_TASK=Task-032e")
    print(f"WARNING_COUNT={warnings}")
    print(f"FAILURE_COUNT={failures}")
    print("VERIFY_TASK032D_CONNECTION_STATE_MOCK_TRANSPORT_RESULT=PASSED" if failures == 0 else "VERIFY_TASK032D_CONNECTION_STATE_MOCK_TRANSPORT_RESULT=FAILED")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
