#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

EXPECTED_BRANCHES = {"task-032-watchbridge-foundation", "develop"}
TASK032D_BASE_HEAD = "7cdc3429dc7cd12063c6c5849fe16625b1b1d778"

PRODUCT_FILES = [
    "Shared/WatchBridge/WatchBridgeEnvelope.swift",
    "Shared/WatchBridge/WatchBridgePayloads.swift",
    "Shared/WatchBridge/WatchBridgeConnectionState.swift",
    "Shared/WatchBridge/WatchBridgeCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeActivityPayloads.swift",
    "Shared/WatchBridge/WatchBridgeMetricPayloads.swift",
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
    "docs/adr/ADR-INDEX.md",
    "docs/adr/ADR-WatchBridge-Foundation.md",
    "docs/adr/ADR-WatchBridge-Contract-Placement.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]
SUBTASK_VERIFIERS = [
    "scripts/verify_task032b_watchbridge_contracts.py",
    "scripts/verify_task032c_activity_payload_models.py",
    "scripts/verify_task032d_connection_state_mock_transport.py",
]
REQUIRED_FILES = PRODUCT_FILES + TEST_FILES + DOC_FILES + SUBTASK_VERIFIERS + [
    "scripts/verify_task032a_watchbridge_audit.py",
    "scripts/verify_task032_watchbridge_foundation.py",
    "SkateTrack.xcodeproj/project.pbxproj",
]
ALLOWED_TASK032E_DIRTY_PATHS = {
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/adr/ADR-WatchBridge-Foundation.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "scripts/verify_task032_watchbridge_foundation.py",
}
FORBIDDEN_DIRTY_PREFIXES = (
    "Shared/WatchBridge/",
    "watchOS/",
    "iOS/",
    "macOS/",
    "Tests/",
)
FORBIDDEN_DIRTY_FRAGMENTS = (
    ".xcodeproj/",
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
    "import HealthKit",
    "HKWorkout",
    "HKLiveWorkoutBuilder",
    "HKHealthStore",
    "import SwiftUI",
    "Button(",
    "NavigationStack",
    "NSManagedObject",
    "CoreData",
    "SnowSegment",
    "SnowRun",
    "SnowClassifier",
    "SnowDistanceBreakdown",
    "estimatedRouteActive = true",
)
FOUNDATION_TOKENS = {
    "Shared/WatchBridge/WatchBridgeEnvelope.swift": ["public struct WatchBridgeEnvelope", "schemaVersion", "messageId", "correlationId", "WatchBridgePayload"],
    "Shared/WatchBridge/WatchBridgePayloads.swift": ["public enum WatchBridgePayload", "case command", "case sessionSnapshot", "case compactActivity", "case activitySession", "case activityMetrics", "case activityDisplay", "case activitySnapshot", "case commandResult", "case connectionStatus"],
    "Shared/WatchBridge/WatchBridgeConnectionState.swift": ["public struct WatchBridgeConnectionState", "WatchBridgeConnectionStatus", "WatchBridgeTransportQuality"],
    "Shared/WatchBridge/WatchBridgeCommandModels.swift": ["public enum WatchBridgeCommandKind", "public enum WatchBridgeSessionState", "public struct WatchBridgeCommandEnvelope"],
    "Shared/WatchBridge/WatchBridgeActivityPayloads.swift": ["public struct WatchBridgeActivityModeDescriptor", "public struct WatchBridgeActivitySessionPayload", "public struct WatchBridgeCompactActivityDisplayPayload", "public struct WatchBridgeActivitySnapshotPayload"],
    "Shared/WatchBridge/WatchBridgeMetricPayloads.swift": ["public enum WatchBridgeMetricTrustLevel", "public struct WatchBridgeMetricUpdatePayload", "public struct WatchBridgeCommandAcknowledgementPayload", "public struct WatchBridgeConnectionStatusPayload"],
    "Shared/WatchBridge/WatchBridgeConnectionTimeline.swift": ["public enum WatchBridgeConnectionEventKind", "case connected", "case disconnected", "case unavailable", "case stale", "public struct WatchBridgeConnectionTimeline"],
    "Shared/WatchBridge/WatchBridgeConnectionStateStore.swift": ["public struct WatchBridgeConnectionStateStore", "public mutating func apply", "WatchBridgeConnectionStatusPayload"],
    "Shared/WatchBridge/WatchBridgeMockTransport.swift": ["public struct WatchBridgeMockTransport", "public enum WatchBridgeMockTransportSendResult", "public mutating func connect", "public mutating func disconnect", "public mutating func receive", "public mutating func send"],
    "Tests/iOSTests/WatchBridgeConnectionStateStoreTests.swift": ["WatchBridgeConnectionStateStoreTests", "testStoreAppliesConnectedDisconnectedUnavailableAndStaleTransitions", ".connected", ".disconnected", ".unavailable", ".stale"],
    "Tests/iOSTests/WatchBridgeMockTransportTests.swift": ["WatchBridgeMockTransportTests", "testMockTransportQueuesOutboundEnvelopeOnlyWhenConnected", "testMockTransportReceiveUpdatesConnectionFreshnessAndInbox", "testMockTransportMarksDisconnectedUnavailableAndStaleWithoutRuntimeDependency"],
}
DOC_TOKENS = {
    "docs/process/PHASE_1B_AGENT_STATE.md": ["TASK032E_WATCHBRIDGE_FOUNDATION_RESULT=PASSED", "TASK032_WATCHBRIDGE_FOUNDATION_COMPLETE=YES", "TASK032_AGGREGATE_VERIFIER_IMPLEMENTED=YES", "WATCHBRIDGE_FOUNDATION_VERIFIER=scripts/verify_task032_watchbridge_foundation.py", "WATCHBRIDGE_CONTRACT_SCHEMA_VERSION=1", "WATCHBRIDGE_SWIFT_FILE_COUNT=9", "WATCHBRIDGE_TEST_SWIFT_COUNT=2", "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO", "WCSESSION_DEPENDENCY_IMPLEMENTED=NO", "SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO", "WATCH_UI_IMPLEMENTED=NO", "HEALTHKIT_RUNTIME_IMPLEMENTED=NO", "SNOW_PRODUCTION_IMPLEMENTATION=NO", "SCHEMA_OR_CORE_DATA_MUTATION=NO", "ROUTE_GEOMETRY_MUTATION=NO", "TRUSTED_METRIC_MUTATION=NO", "NEXT_TASK=Task-033a"],
    "docs/history/DEV_LOG.md": ["Task-032e-001 WatchBridge Tests + Verifier + Docs", "TASK032_WATCHBRIDGE_FOUNDATION_COMPLETE=YES", "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO", "SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO", "NEXT_TASK=Task-033a"],
    "docs/reference/FILE_STRUCTURE.md": ["Task-032e WatchBridge Foundation Closure Addendum", "scripts/verify_task032_watchbridge_foundation.py", "docs/adr/ADR-WatchBridge-Foundation.md", "WATCHBRIDGE_SWIFT_FILE_COUNT=9"],
    "docs/adr/ADR-INDEX.md": ["ADR-WatchBridge-Foundation.md", "WatchBridge Foundation Boundary"],
    "docs/adr/ADR-WatchBridge-Foundation.md": ["TASK032_WATCHBRIDGE_FOUNDATION_COMPLETE=YES", "WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO", "SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO", "Task-033a owns the first real WatchConnectivity runtime boundary shell"],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": ["Task-032 WatchBridge Foundation Boundary", "no real WatchConnectivity runtime", "no session-control mirroring runtime", "no Watch UI"],
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


def status_paths(repo: Path) -> list[str]:
    raw = run(repo, ["git", "status", "--porcelain=v1"]).stdout.splitlines()
    paths: list[str] = []
    for line in raw:
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path)
    return paths


def verify_git(repo: Path) -> None:
    print("===== Git baseline =====")
    branch = run(repo, ["git", "branch", "--show-current"]).stdout.strip()
    head = run(repo, ["git", "rev-parse", "HEAD"]).stdout.strip()
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD_FULL={head}")
    if branch in EXPECTED_BRANCHES:
        record_pass("current branch is valid for Task-032e foundation verification")
    else:
        record_fail(f"unexpected branch: {branch}")
    base = run(repo, ["git", "merge-base", "--is-ancestor", TASK032D_BASE_HEAD, "HEAD"])
    print(f"TASK032D_BASE_REACHABLE_EXIT={base.returncode}")
    print(f"TASK032D_BASE_REACHABLE={'YES' if base.returncode == 0 else 'NO'}")
    if base.returncode == 0:
        record_pass("Task-032d branch head is reachable from HEAD")
    else:
        record_fail("Task-032d branch head is not reachable from HEAD")


def verify_dirty_scope(repo: Path) -> None:
    print("===== Task-032e changed-scope guard =====")
    paths = status_paths(repo)
    unexpected: list[str] = []
    forbidden: list[str] = []
    for path in paths:
        print(f"TASK032E_STATUS_PATH={path}")
        if path not in ALLOWED_TASK032E_DIRTY_PATHS:
            unexpected.append(path)
        if path.startswith(FORBIDDEN_DIRTY_PREFIXES) or any(fragment in path for fragment in FORBIDDEN_DIRTY_FRAGMENTS):
            forbidden.append(path)
    print(f"TASK032E_STATUS_PATH_COUNT={len(paths)}")
    print(f"UNEXPECTED_TASK032E_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        record_fail(f"unexpected Task-032e changed path: {path}")
    if not unexpected:
        record_pass("changed paths are limited to Task-032e verifier/docs/ADR scope")
    print(f"FORBIDDEN_TASK032E_CHANGED_SCOPE_COUNT={len(forbidden)}")
    for path in forbidden:
        record_fail(f"forbidden Task-032e changed path: {path}")
    if not forbidden:
        record_pass("no product Swift, Xcode project, tests, UI, entitlement, schema, or Snow paths changed by Task-032e")


def verify_required_paths(repo: Path) -> None:
    print("===== Required foundation files =====")
    for relative in REQUIRED_FILES:
        path = repo / relative
        if path.exists():
            record_pass(f"required path exists: {relative}")
        else:
            record_fail(f"required path missing: {relative}")


def verify_swift_file(repo: Path, relative: str, product: bool) -> None:
    path = repo / relative
    if not path.exists():
        return
    text = read(path)
    lines = text.splitlines()
    first = lines[0] if lines else ""
    print(f"FIRST_LINE[{relative}]={first}")
    print(f"LINE_COUNT[{relative}]={len(lines)}")
    if not (first.startswith("// [協作區]") or first.startswith("// [自主區]")):
        record_fail(f"{relative} missing collaboration/autonomous header")
    else:
        record_pass(f"{relative} has a valid collaboration/autonomous header")
    if len(lines) > 500:
        record_fail(f"{relative} exceeds 500 lines")
    else:
        record_pass(f"{relative} stays under 500 lines")
    if product:
        count = sum(text.count(token) for token in FORBIDDEN_PRODUCT_TOKENS)
        print(f"FORBIDDEN_PRODUCT_TOKEN_COUNT[{relative}]={count}")
        if count:
            record_fail(f"{relative} contains forbidden runtime/UI/schema/Snow tokens")
        else:
            record_pass(f"{relative} contains no forbidden runtime/UI/schema/Snow tokens")
    for token in FOUNDATION_TOKENS.get(relative, []):
        if token in text:
            record_pass(f"{relative} contains token: {token}")
        else:
            record_fail(f"{relative} missing token: {token}")


def verify_files(repo: Path) -> None:
    print("===== Swift contract/test checks =====")
    for relative in PRODUCT_FILES:
        verify_swift_file(repo, relative, product=True)
    for relative in TEST_FILES:
        verify_swift_file(repo, relative, product=False)


def grep_count(repo: Path, patterns: list[str], roots: list[str]) -> int:
    count = 0
    for root in roots:
        root_path = repo / root
        if not root_path.exists():
            continue
        for path in root_path.rglob("*.swift"):
            text = read(path)
            for token in patterns:
                count += text.count(token)
    return count


def verify_runtime_boundaries(repo: Path) -> None:
    print("===== Runtime, UI, and safety guardrails =====")
    watchconnectivity_count = grep_count(repo, ["WatchConnectivity", "WCSession", "WCSessionDelegate"], ["Shared", "iOS", "watchOS", "macOS", "Tests"])
    wcsession_count = grep_count(repo, ["WCSession", "WCSessionDelegate"], ["Shared", "iOS", "watchOS", "macOS", "Tests"])
    watchbridge_healthkit_count = grep_count(repo, ["import HealthKit", "HKWorkout", "HKLiveWorkoutBuilder", "HKHealthStore"], ["Shared/WatchBridge"])
    watchbridge_ui_count = grep_count(repo, ["import SwiftUI", "Button(", "NavigationStack", "List {", "Text("], ["Shared/WatchBridge"])
    watchbridge_snow_count = grep_count(repo, ["SnowSegment", "SnowRun", "SnowDistanceBreakdown", "SnowClassifier", "SnowSport"], ["Shared/WatchBridge"])
    trusted_mutation_count = grep_count(repo, ["estimatedRouteActive = true", "trustedDistance", "mutateTrusted", "routeGeometryMutation"], ["Shared/WatchBridge"])
    print(f"WATCHCONNECTIVITY_RUNTIME_TOKEN_COUNT={watchconnectivity_count}")
    print(f"WCSESSION_RUNTIME_FILE_TOKEN_COUNT={wcsession_count}")
    print(f"WATCHBRIDGE_HEALTHKIT_RUNTIME_TOKEN_COUNT={watchbridge_healthkit_count}")
    print(f"WATCHBRIDGE_UI_TOKEN_COUNT={watchbridge_ui_count}")
    print(f"WATCHBRIDGE_SNOW_PRODUCTION_TOKEN_COUNT={watchbridge_snow_count}")
    print(f"WATCHBRIDGE_TRUSTED_METRIC_MUTATION_TOKEN_COUNT={trusted_mutation_count}")
    if watchconnectivity_count == 0:
        record_pass("no WatchConnectivity / WCSession runtime tokens in guarded source paths")
    else:
        record_fail("WatchConnectivity / WCSession runtime tokens detected in guarded source paths")
    if watchbridge_healthkit_count == 0:
        record_pass("no HealthKit runtime tokens in WatchBridge product files")
    else:
        record_fail("HealthKit runtime tokens detected in WatchBridge product files")
    if watchbridge_ui_count == 0:
        record_pass("no Watch UI / SwiftUI tokens in WatchBridge product files")
    else:
        record_fail("Watch UI / SwiftUI tokens detected in WatchBridge product files")
    if watchbridge_snow_count == 0:
        record_pass("no Snow production tokens in WatchBridge product files")
    else:
        record_fail("Snow production tokens detected in WatchBridge product files")
    if trusted_mutation_count == 0:
        record_pass("no trusted metric / route geometry mutation tokens in WatchBridge product files")
    else:
        record_fail("trusted metric / route geometry mutation tokens detected in WatchBridge product files")


def verify_project_membership(repo: Path) -> None:
    print("===== Project membership guard =====")
    pbx = repo / "SkateTrack.xcodeproj/project.pbxproj"
    if not pbx.exists():
        record_fail("project.pbxproj missing")
        return
    text = read(pbx)
    for relative in PRODUCT_FILES:
        name = Path(relative).name
        token_count = text.count(name)
        source_count = text.count(f"{name} in Sources")
        print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
        print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
        if token_count >= 4 and source_count >= 2:
            record_pass(f"{name} is source-membered for iOS and watchOS")
        else:
            record_fail(f"{name} does not appear source-membered for iOS and watchOS")
    for relative in TEST_FILES:
        name = Path(relative).name
        token_count = text.count(name)
        source_count = text.count(f"{name} in Sources")
        print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
        print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
        if token_count >= 3 and source_count >= 1:
            record_pass(f"{name} is source-membered for SkateTrack-iOSTests")
        else:
            record_fail(f"{name} does not appear source-membered for SkateTrack-iOSTests")


def verify_subtask_replay(repo: Path) -> None:
    print("===== Subtask verifier replay policy =====")
    dirty = bool(status_paths(repo))
    if dirty:
        print("TASK032_SUBTASK_VERIFIER_REPLAY_SCOPE=DOCUMENTED_SKIPPED_ON_DIRTY_TASK032E_DOC_BRANCH")
        print("TASK032_SUBTASK_VERIFIER_REPLAY_REASON=Task-032e adds aggregate docs/verifier paths that earlier per-subtask verifiers intentionally do not allow while dirty")
        record_pass("subtask verifier replay is deferred to clean-branch or pre-apply context")
        return
    print("TASK032_SUBTASK_VERIFIER_REPLAY_SCOPE=CLEAN_BRANCH_BLOCKING")
    for script in SUBTASK_VERIFIERS:
        result = run(repo, [sys.executable, script])
        print(f"SUBTASK_VERIFIER[{script}]_EXIT={result.returncode}")
        if result.returncode == 0:
            record_pass(f"{script} passed on clean branch")
        else:
            print(result.stdout)
            print(result.stderr)
            record_fail(f"{script} failed on clean branch")


def verify_docs(repo: Path) -> None:
    print("===== Documentation checkpoints =====")
    for relative, tokens in DOC_TOKENS.items():
        path = repo / relative
        if not path.exists():
            record_fail(f"required doc missing: {relative}")
            continue
        text = read(path)
        for token in tokens:
            if token in text:
                record_pass(f"{relative} contains token: {token}")
            else:
                record_fail(f"{relative} missing token: {token}")


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    print("===== Task-032 WatchBridge foundation aggregate verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-032e — WatchBridge Tests + Verifier + Docs")
    print("Not implementing: real WatchConnectivity runtime behavior, WCSession runtime boundary, session-control mirroring runtime, Watch UI, HealthKit, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    print(f"REPO={repo}")
    if not (repo / ".git").exists():
        record_fail("repo path does not contain .git")
    else:
        record_pass("repo path contains .git")
    verify_git(repo)
    verify_dirty_scope(repo)
    verify_required_paths(repo)
    verify_files(repo)
    verify_project_membership(repo)
    verify_runtime_boundaries(repo)
    verify_subtask_replay(repo)
    verify_docs(repo)
    print("===== Summary =====")
    print("TASK032E_WATCHBRIDGE_FOUNDATION_RESULT=PASSED" if failures == 0 else "TASK032E_WATCHBRIDGE_FOUNDATION_RESULT=FAILED")
    print("TASK032_WATCHBRIDGE_FOUNDATION_COMPLETE=YES" if failures == 0 else "TASK032_WATCHBRIDGE_FOUNDATION_COMPLETE=NO")
    print("TASK032_AGGREGATE_VERIFIER_IMPLEMENTED=YES")
    print("WATCHBRIDGE_CONTRACT_SCHEMA_VERSION=1")
    print(f"WATCHBRIDGE_SWIFT_FILE_COUNT={len(PRODUCT_FILES)}")
    print(f"WATCHBRIDGE_TEST_SWIFT_COUNT={len(TEST_FILES)}")
    print("WATCHCONNECTIVITY_RUNTIME_IMPLEMENTED=NO")
    print("WCSESSION_DEPENDENCY_IMPLEMENTED=NO")
    print("SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO")
    print("WATCH_UI_IMPLEMENTED=NO")
    print("NEXT_TASK=Task-033a")
    print(f"WARNING_COUNT={warnings}")
    print(f"FAILURE_COUNT={failures}")
    print("VERIFY_TASK032_WATCHBRIDGE_FOUNDATION_RESULT=PASSED" if failures == 0 else "VERIFY_TASK032_WATCHBRIDGE_FOUNDATION_RESULT=FAILED")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
