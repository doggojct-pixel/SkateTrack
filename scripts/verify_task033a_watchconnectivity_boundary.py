#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

REPO = Path.cwd()
EXPECTED_BASE = "873c9620bafb6c8246ce1e55639f5f2c8080b907"
ALLOWED_BRANCHES = {"task-033-watchconnectivity-boundary", "develop"}
ALLOWED_STATUS_PATHS = {
    "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift",
    "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
    "Tests/iOSTests/WatchBridgeConnectivityBoundaryTests.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "scripts/verify_task033a_watchconnectivity_boundary.py",
}
PRODUCT_FILES = [
    "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift",
    "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
]
TEST_FILES = ["Tests/iOSTests/WatchBridgeConnectivityBoundaryTests.swift"]
WATCHCONNECTIVITY_BOUNDARY_FILE = "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift"

failure_count = 0
warning_count = 0

def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=False)

def emit(message: str) -> None:
    print(message)

def fail(message: str) -> None:
    global failure_count
    failure_count += 1
    print(f"FAIL: {message}")

def pass_if(condition: bool, ok: str, bad: str) -> None:
    if condition:
        emit(f"PASS: {ok}")
    else:
        fail(bad)

def read(path: str) -> str:
    return (REPO / path).read_text(encoding="utf-8")

def status_paths() -> list[str]:
    result = run(["git", "status", "--porcelain=v1"])
    paths: list[str] = []
    for line in result.stdout.splitlines():
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path)
    return paths

def token_count(paths: list[str], tokens: list[str]) -> int:
    count = 0
    for path in paths:
        full = REPO / path
        if not full.exists() or not full.is_file():
            continue
        text = full.read_text(encoding="utf-8", errors="ignore")
        count += sum(text.count(token) for token in tokens)
    return count

def grep_count(root_paths: list[str], tokens: list[str], exclude: set[str] | None = None) -> int:
    exclude = exclude or set()
    count = 0
    for root in root_paths:
        base = REPO / root
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            rel = path.relative_to(REPO).as_posix()
            if rel in exclude:
                continue
            try:
                text = path.read_text(encoding="utf-8", errors="ignore")
            except UnicodeDecodeError:
                continue
            count += sum(text.count(token) for token in tokens)
    return count

def require_path(path: str) -> None:
    pass_if((REPO / path).exists(), f"required path exists: {path}", f"missing required path: {path}")

def check_swift_file(path: str) -> None:
    require_path(path)
    full = REPO / path
    if not full.exists():
        return
    lines = full.read_text(encoding="utf-8").splitlines()
    first = lines[0] if lines else ""
    emit(f"FIRST_LINE[{path}]={first}")
    emit(f"LINE_COUNT[{path}]={len(lines)}")
    pass_if(first.startswith("// [協作區]") or first.startswith("// [自主區]"), f"{path} has a valid collaboration/autonomous header", f"{path} missing collaboration/autonomous header")
    pass_if(len(lines) <= 500, f"{path} stays under 500 lines", f"{path} exceeds 500 lines")

emit("===== Task-033a WatchConnectivity boundary verifier =====")
emit("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
emit("Aligned subtask: Task-033a — WatchConnectivity Boundary Shell")
emit("Not implementing: production session-control mirroring, Watch UI, HealthKit workout runtime, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
emit(f"REPO={REPO}")
pass_if((REPO / ".git").exists(), "repo path contains .git", "repo path does not contain .git")

emit("===== Git baseline =====")
branch = run(["git", "branch", "--show-current"]).stdout.strip()
head = run(["git", "rev-parse", "HEAD"]).stdout.strip()
emit(f"CURRENT_BRANCH={branch}")
emit(f"CURRENT_HEAD_FULL={head}")
pass_if(branch in ALLOWED_BRANCHES, "current branch is valid for Task-033a verification", f"unexpected branch {branch}")
base_reachable = run(["git", "merge-base", "--is-ancestor", EXPECTED_BASE, "HEAD"])
emit(f"TASK032_DEVELOP_BASE_REACHABLE_EXIT={base_reachable.returncode}")
emit(f"TASK032_DEVELOP_BASE_REACHABLE={'YES' if base_reachable.returncode == 0 else 'NO'}")
pass_if(base_reachable.returncode == 0, "Task-032 develop baseline is reachable from HEAD", "Task-032 develop baseline is not reachable from HEAD")

emit("===== Task-033a changed-scope guard =====")
paths = status_paths()
for path in paths:
    emit(f"TASK033A_STATUS_PATH={path}")
unexpected = [path for path in paths if path not in ALLOWED_STATUS_PATHS]
emit(f"TASK033A_STATUS_PATH_COUNT={len(paths)}")
emit(f"UNEXPECTED_TASK033A_STATUS_PATH_COUNT={len(unexpected)}")
for path in unexpected:
    fail(f"unexpected Task-033a status path: {path}")
pass_if(not unexpected, "changed paths are limited to Task-033a boundary/docs/verifier/test/project scope", "unexpected changed paths found")

forbidden_scope = [
    path for path in paths
    if path.endswith(".entitlements")
    or ".xcdatamodel" in path
    or path.startswith("watchOS/")
    or path.startswith("iOS/Features/")
    or path.startswith("macOS/")
    or "Snow" in path
]
emit(f"FORBIDDEN_TASK033A_CHANGED_SCOPE_COUNT={len(forbidden_scope)}")
for path in forbidden_scope:
    fail(f"forbidden Task-033a changed path: {path}")
pass_if(not forbidden_scope, "no UI, entitlement, schema, Snow, or unrelated platform paths changed", "forbidden changed scope found")

emit("===== Boundary product and test files =====")
for path in PRODUCT_FILES + TEST_FILES:
    check_swift_file(path)

required_tokens = {
    "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift": [
        "public protocol WatchBridgeConnectivityBoundary",
        "public struct WatchBridgeConnectivityAvailability",
        "public enum WatchBridgeConnectivitySendResult",
        "public struct WatchBridgeSimulatorFallbackBoundary",
        "mutating func activate",
        "mutating func refreshAvailability",
        "mutating func send",
    ],
    "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift": [
        "import WatchConnectivity",
        "public final class WatchBridgeWCSessionBoundary",
        "WCSessionDelegate",
        "WCSession",
        "session.activate()",
        "sessionReachabilityDidChange",
        "sendMessageData",
    ],
    "Tests/iOSTests/WatchBridgeConnectivityBoundaryTests.swift": [
        "WatchBridgeConnectivityBoundaryTests",
        "testSimulatorFallbackReportsAvailabilityAfterActivation",
        "testSimulatorFallbackQueuesEnvelopeOnlyAfterActivation",
        "testConnectivityAvailabilityCanRepresentRuntimeUnavailableFallback",
    ],
}
for path, tokens in required_tokens.items():
    text = read(path) if (REPO / path).exists() else ""
    for token in tokens:
        pass_if(token in text, f"{path} contains token: {token}", f"{path} missing token: {token}")

emit("===== Project membership guard =====")
pbx_path = REPO / "SkateTrack.xcodeproj/project.pbxproj"
require_path("SkateTrack.xcodeproj/project.pbxproj")
pbx = pbx_path.read_text(encoding="utf-8") if pbx_path.exists() else ""
for name in ["WatchBridgeConnectivityBoundary.swift", "WatchBridgeWCSessionBoundary.swift"]:
    token_count_in_project = pbx.count(name)
    source_count = pbx.count(f"{name} in Sources")
    emit(f"PROJECT_TOKEN_COUNT[{name}]={token_count_in_project}")
    emit(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
    pass_if(token_count_in_project >= 3, f"{name} has project file references", f"{name} missing project file references")
    pass_if(source_count >= 2, f"{name} is source-membered for iOS and watchOS", f"{name} missing iOS/watchOS source membership")

name = "WatchBridgeConnectivityBoundaryTests.swift"
token_count_in_project = pbx.count(name)
source_count = pbx.count(f"{name} in Sources")
emit(f"PROJECT_TOKEN_COUNT[{name}]={token_count_in_project}")
emit(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
pass_if(token_count_in_project >= 2, f"{name} has project file references", f"{name} missing project references")
pass_if(source_count >= 1, f"{name} is source-membered for SkateTrack-iOSTests", f"{name} missing iOSTests source membership")

emit("===== Runtime, UI, and safety guardrails =====")
watchbridge_paths = [p.relative_to(REPO).as_posix() for p in (REPO / "Shared/WatchBridge").glob("*.swift")]
watchconnectivity_file_count = sum(
    1 for path in watchbridge_paths
    if "WatchConnectivity" in read(path) or "WCSession" in read(path)
)
non_boundary_wc_count = token_count(
    [path for path in watchbridge_paths if path != WATCHCONNECTIVITY_BOUNDARY_FILE],
    ["WatchConnectivity", "WCSession", "WCSessionDelegate", "sendMessageData", "sendMessage"]
)
direct_ui_wcsession_usage_count = grep_count(
    ["iOS", "watchOS", "macOS"],
    ["WCSession", "WatchConnectivity"],
    exclude=set(PRODUCT_FILES),
)
watchbridge_healthkit_count = token_count(PRODUCT_FILES, ["HealthKit", "HKWorkout", "HKLiveWorkoutBuilder", "HKHealthStore"])
watchbridge_ui_count = token_count(PRODUCT_FILES, ["SwiftUI", "View", "Button", "NavigationStack", "Text("])
watchbridge_snow_count = token_count(PRODUCT_FILES, ["SnowSegment", "SnowRun", "SnowClassifier", "SnowMode", "SnowSport"])
session_control_runtime_count = token_count(PRODUCT_FILES, ["startSession", "pauseSession", "resumeSession", "endSession", "command mirroring", "session-control mirroring"])
trusted_mutation_count = token_count(PRODUCT_FILES, ["trusted metric mutation", "route geometry mutation", "estimated route"])

emit(f"WATCHCONNECTIVITY_BOUNDARY_FILE_COUNT={watchconnectivity_file_count}")
emit(f"NON_BOUNDARY_WCSESSION_TOKEN_COUNT={non_boundary_wc_count}")
emit(f"DIRECT_UI_WCSESSION_USAGE_COUNT={direct_ui_wcsession_usage_count}")
emit(f"WATCHBRIDGE_HEALTHKIT_RUNTIME_TOKEN_COUNT={watchbridge_healthkit_count}")
emit(f"WATCHBRIDGE_UI_TOKEN_COUNT={watchbridge_ui_count}")
emit(f"WATCHBRIDGE_SNOW_PRODUCTION_TOKEN_COUNT={watchbridge_snow_count}")
emit(f"SESSION_CONTROL_MIRRORING_RUNTIME_TOKEN_COUNT={session_control_runtime_count}")
emit(f"WATCHBRIDGE_TRUSTED_METRIC_MUTATION_TOKEN_COUNT={trusted_mutation_count}")
pass_if(watchconnectivity_file_count == 1, "WCSession is isolated to the boundary wrapper file", "WCSession tokens are not isolated to one boundary file")
pass_if(non_boundary_wc_count == 0, "no WatchConnectivity tokens outside the boundary wrapper", "WatchConnectivity tokens found outside boundary wrapper")
pass_if(direct_ui_wcsession_usage_count == 0, "no direct UI/platform WCSession usage", "direct UI/platform WCSession usage found")
pass_if(watchbridge_healthkit_count == 0, "no HealthKit runtime tokens in Task-033a product files", "HealthKit runtime tokens found in Task-033a product files")
pass_if(watchbridge_ui_count == 0, "no Watch UI / SwiftUI implementation in Task-033a product files", "UI tokens found in Task-033a product files")
pass_if(watchbridge_snow_count == 0, "no Snow production implementation in Task-033a product files", "Snow production tokens found")
pass_if(session_control_runtime_count == 0, "no production session-control mirroring in Task-033a product files", "session-control mirroring tokens found")
pass_if(trusted_mutation_count == 0, "no trusted metric or route geometry mutation tokens", "trusted metric/route mutation tokens found")

emit("===== Documentation checkpoints =====")
doc_tokens = {
    "docs/process/PHASE_1B_AGENT_STATE.md": [
        "TASK033A_WATCHCONNECTIVITY_BOUNDARY_RESULT=PASSED",
        "WATCHCONNECTIVITY_BOUNDARY_SHELL_IMPLEMENTED=YES",
        "WCSESSION_WRAPPED_BY_BOUNDARY=YES",
        "SIMULATOR_FALLBACK_PRESENT=YES",
        "DIRECT_UI_WCSESSION_USAGE_COUNT=0",
        "SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO",
        "WATCH_UI_IMPLEMENTED=NO",
        "NEXT_TASK=Task-033b",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-033a-001C WatchConnectivity Boundary Shell",
        "WCSESSION_WRAPPED_BY_BOUNDARY=YES",
        "SIMULATOR_FALLBACK_PRESENT=YES",
        "NEXT_TASK=Task-033b",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-033a WatchConnectivity Boundary Shell Addendum",
        "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift",
        "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
        "Tests/iOSTests/WatchBridgeConnectivityBoundaryTests.swift",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-033a WatchConnectivity Boundary Shell",
        "no production session-control mirroring runtime",
        "no Watch UI",
    ],
}
for path, tokens in doc_tokens.items():
    require_path(path)
    text = read(path) if (REPO / path).exists() else ""
    for token in tokens:
        pass_if(token in text, f"{path} contains token: {token}", f"{path} missing token: {token}")

emit("===== Summary =====")
emit("TASK033A_WATCHCONNECTIVITY_BOUNDARY_RESULT=PASSED" if failure_count == 0 else "TASK033A_WATCHCONNECTIVITY_BOUNDARY_RESULT=FAILED")
emit("WCSESSION_WRAPPED_BY_BOUNDARY=YES" if failure_count == 0 else "WCSESSION_WRAPPED_BY_BOUNDARY=UNKNOWN")
emit("SIMULATOR_FALLBACK_PRESENT=YES" if failure_count == 0 else "SIMULATOR_FALLBACK_PRESENT=UNKNOWN")
emit(f"DIRECT_UI_WCSESSION_USAGE_COUNT={direct_ui_wcsession_usage_count}")
emit("SESSION_CONTROL_MIRRORING_RUNTIME_IMPLEMENTED=NO")
emit("WATCH_UI_IMPLEMENTED=NO")
emit("NEXT_TASK=Task-033b")
emit(f"WARNING_COUNT={warning_count}")
emit(f"FAILURE_COUNT={failure_count}")
emit("VERIFY_TASK033A_WATCHCONNECTIVITY_BOUNDARY_RESULT=PASSED" if failure_count == 0 else "VERIFY_TASK033A_WATCHCONNECTIVITY_BOUNDARY_RESULT=FAILED")
raise SystemExit(0 if failure_count == 0 else 1)
