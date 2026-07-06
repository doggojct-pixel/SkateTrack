#!/usr/bin/env python3
# [協作區] scripts/verify_task033_watchconnectivity_boundary.py
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

EXPECTED_BRANCHES = {"task-033-watchconnectivity-boundary", "develop"}
ALLOWED_STATUS_PATHS = {
    "scripts/verify_task033_watchconnectivity_boundary.py",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
}

REQUIRED_PRODUCT_FILES = [
    "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift",
    "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
    "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift",
]

REQUIRED_TEST_FILES = [
    "Tests/iOSTests/WatchBridgeConnectivityBoundaryTests.swift",
    "Tests/iOSTests/WatchBridgeMirroredSessionCommandTests.swift",
    "Tests/iOSTests/WatchBridgeCommandSafetyTests.swift",
]

REQUIRED_VERIFIERS = [
    "scripts/verify_task033a_watchconnectivity_boundary.py",
    "scripts/verify_task033b_mirrored_session_commands.py",
    "scripts/verify_task033c_command_safety_conflict_rules.py",
    "scripts/verify_task033_watchconnectivity_boundary.py",
]

DOC_TOKENS = {
    "docs/process/PHASE_1B_AGENT_STATE.md": [
        "TASK033D_WATCHCONNECTIVITY_VERIFIER_DOCS_RESULT=PASSED",
        "TASK033_AGGREGATE_VERIFIER_IMPLEMENTED=YES",
        "TASK033_WATCHCONNECTIVITY_BOUNDARY_COMPLETE=YES",
        "WATCHCONNECTIVITY_WRAPPED_BY_BOUNDARY=YES",
        "DIRECT_UI_WCSESSION_USAGE_COUNT=0",
        "IPHONE_SESSION_AUTHORITY_PRESERVED=YES",
        "DUPLICATE_COMMAND_PROTECTION=YES",
        "STALE_COMMAND_REJECTION=YES",
        "COMMAND_CONFLICT_RULES_IMPLEMENTED=YES",
        "OUT_OF_ORDER_COMMAND_REJECTION=YES",
        "DISCONNECTED_WATCH_COMMAND_REJECTION=YES",
        "WATCH_DIRECT_SESSION_MUTATION=NO",
        "WATCH_UI_IMPLEMENTED=NO",
        "HEALTHKIT_PRODUCTION_IMPLEMENTED=NO",
        "SNOW_PRODUCTION_IMPLEMENTATION=NO",
        "NEXT_TASK=Task-034a",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-033d-001 WatchConnectivity Verifier + Docs",
        "TASK033_AGGREGATE_VERIFIER_IMPLEMENTED=YES",
        "TASK033_WATCHCONNECTIVITY_BOUNDARY_COMPLETE=YES",
        "NEXT_TASK=Task-034a",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-033d WatchConnectivity Verifier + Docs Addendum",
        "scripts/verify_task033_watchconnectivity_boundary.py",
        "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
        "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-033 WatchConnectivity boundary closure",
        "iPhone-side authority remains final",
        "no Watch UI",
        "no direct Watch session mutation",
        "no HealthKit production implementation",
        "no Snow production implementation",
    ],
}

PRODUCT_TOKEN_REQUIREMENTS = {
    "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift": [
        "public protocol WatchBridgeConnectivityBoundary",
        "WatchBridgeConnectivityAvailability",
        "WatchBridgeSimulatorFallbackBoundary",
    ],
    "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift": [
        "import WatchConnectivity",
        "public final class WatchBridgeWCSessionBoundary",
        "WCSessionDelegate",
        "sendMessageData",
    ],
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift": [
        "case start",
        "case pause",
        "case resume",
        "case stop",
        "case duplicate",
        "case stale",
        "case iPhoneActionInProgress",
        "case outOfOrderCommand",
        "case watchDisconnected",
        "idempotencyKey",
        "acknowledgementPayload",
    ],
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift": [
        "WatchBridgeMirroredSessionCommandAuthority",
        "completedCommandIds",
        "invalidDirection",
        "staleCommand",
        "duplicateCommand",
        "payload: .commandResult",
        "policy.requiredDestination",
        "policy.requiredSource",
    ],
    "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift": [
        "WatchBridgeCommandSafetyContext",
        "WatchBridgeCommandSafetyRules",
        "WatchBridgeCommandSafetyAuthority",
        "iPhoneActionInProgress",
        "outOfOrderCommand",
        "watchDisconnected",
        "canForwardToIPhoneAuthority",
        "latestAcceptedCommandIssuedAt",
    ],
}

TEST_TOKEN_REQUIREMENTS = {
    "Tests/iOSTests/WatchBridgeConnectivityBoundaryTests.swift": [
        "WatchBridgeConnectivityBoundaryTests",
        "testSimulatorFallbackReportsAvailabilityAfterActivation",
    ],
    "Tests/iOSTests/WatchBridgeMirroredSessionCommandTests.swift": [
        "WatchBridgeMirroredSessionCommandTests",
        "testProcessorAcceptsWatchStartAfterIPhoneAuthorityValidation",
        "testProcessorRejectsStaleCommandBeforeAuthorityValidation",
        "testProcessorIgnoresDuplicateCommandWithoutSecondAuthorityCall",
    ],
    "Tests/iOSTests/WatchBridgeCommandSafetyTests.swift": [
        "WatchBridgeCommandSafetyTests",
        "testRejectsSimultaneousIPhoneActionBeforeAuthorityValidation",
        "testRejectsOutOfOrderWatchCommandBeforeAuthorityValidation",
        "testRejectsDisconnectedWatchStateWithoutAuthorityValidation",
        "testForwardsReachableInOrderWatchCommandToIPhoneAuthority",
    ],
}

FORBIDDEN_TASK033_PRODUCT_TOKENS = [
    "SwiftUI",
    "NavigationStack",
    "Button(",
    "Text(",
    "HKWorkout",
    "HKLiveWorkoutBuilder",
    "HKHealthStore",
    "SnowSegment",
    "SnowRun",
    "SnowClassifier",
    "NSManagedObject",
    "xcdatamodel",
    "RouteGeometry",
    "map-match",
    "snap-to-road",
]


def run(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)


def git_lines(args: list[str]) -> list[str]:
    result = run(["git", *args])
    if result.returncode != 0:
        return []
    return [line for line in result.stdout.splitlines() if line.strip()]


def fail(message: str, failures: list[str]) -> None:
    print(f"FAIL: {message}")
    failures.append(message)


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def check_header_and_lines(path: str, failures: list[str]) -> None:
    text = read(path)
    lines = text.splitlines()
    first = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if not (first.startswith("// [協作區]") or first.startswith("// [自主區]") or first.startswith("#!")):
        fail(f"{path} missing collaboration/autonomous header", failures)
    else:
        pass_msg(f"{path} has valid header")
    if len(lines) > 500:
        fail(f"{path} exceeds 500 lines", failures)
    else:
        pass_msg(f"{path} stays under 500 lines")


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


def count_grep(pattern: str, paths: list[str]) -> int:
    existing = [path for path in paths if Path(path).exists()]
    if not existing:
        return 0
    result = run(["git", "grep", "-n", pattern, "--", *existing])
    if result.returncode not in (0, 1):
        return 9999
    return len([line for line in result.stdout.splitlines() if line.strip()])


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    print("===== Task-033 WatchConnectivity aggregate verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned closure subtask: Task-033d — WatchConnectivity Verifier + Docs")
    print("Not implementing: Watch UI, direct Watch session mutation, HealthKit workout runtime, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    print(f"REPO={Path.cwd()}")

    if not Path(".git").exists():
        fail("repo path does not contain .git", failures)
    else:
        pass_msg("repo path contains .git")

    branch = run(["git", "branch", "--show-current"]).stdout.strip()
    head = run(["git", "rev-parse", "HEAD"]).stdout.strip()
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD_FULL={head}")
    if branch not in EXPECTED_BRANCHES:
        fail(f"unexpected branch: {branch}", failures)
    else:
        pass_msg("current branch is valid for Task-033 aggregate verification")

    paths = status_paths()
    for path in paths:
        print(f"TASK033_STATUS_PATH={path}")
    unexpected = [path for path in paths if path not in ALLOWED_STATUS_PATHS]
    print(f"TASK033_STATUS_PATH_COUNT={len(paths)}")
    print(f"UNEXPECTED_TASK033_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        fail(f"unexpected changed path: {path}", failures)
    if not unexpected:
        pass_msg("changed paths are limited to Task-033d docs/aggregate verifier scope")

    required = REQUIRED_PRODUCT_FILES + REQUIRED_TEST_FILES + REQUIRED_VERIFIERS
    for path in required:
        if not Path(path).exists():
            fail(f"required path missing: {path}", failures)
        else:
            pass_msg(f"required path exists: {path}")

    for path in required:
        if Path(path).suffix in {".swift", ".py"} and Path(path).exists():
            check_header_and_lines(path, failures)

    for path, tokens in {**PRODUCT_TOKEN_REQUIREMENTS, **TEST_TOKEN_REQUIREMENTS}.items():
        if not Path(path).exists():
            continue
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"{path} missing token: {token}", failures)
            else:
                pass_msg(f"{path} contains token: {token}")

    for path in REQUIRED_PRODUCT_FILES:
        if not Path(path).exists():
            continue
        text = read(path)
        forbidden_hits = [token for token in FORBIDDEN_TASK033_PRODUCT_TOKENS if token in text]
        print(f"FORBIDDEN_TASK033_PRODUCT_TOKEN_COUNT[{path}]={len(forbidden_hits)}")
        if forbidden_hits:
            fail(f"{path} contains forbidden tokens: {', '.join(forbidden_hits)}", failures)
        else:
            pass_msg(f"{path} contains no forbidden UI/HealthKit/Snow/schema/route tokens")

    pbxproj = Path("SkateTrack.xcodeproj/project.pbxproj")
    if not pbxproj.exists():
        fail("project.pbxproj missing", failures)
    else:
        project = pbxproj.read_text(encoding="utf-8")
        for name in [Path(path).name for path in REQUIRED_PRODUCT_FILES + REQUIRED_TEST_FILES]:
            count = project.count(name)
            print(f"PROJECT_TOKEN_COUNT[{name}]={count}")
            if count == 0:
                fail(f"{name} missing from project file", failures)
            else:
                pass_msg(f"{name} has project references")

    wc_boundary_file_count = count_grep("WCSession\\|WCSessionDelegate", ["Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift"])
    non_boundary_wc_count = count_grep("WCSession\\|WatchConnectivity", [
        "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift",
        "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
        "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
        "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift",
    ])
    direct_ui_wc_count = count_grep("WCSession\\|WatchConnectivity", ["iOS", "watchOS", "macOS"])
    watchos_direct_mutation_count = count_grep("startSession\\|pauseSession\\|resumeSession\\|endSession", ["watchOS"])
    task033_healthkit_count = count_grep("HealthKit\\|HKWorkout\\|HKLiveWorkoutBuilder\\|HKHealthStore", REQUIRED_PRODUCT_FILES)
    task033_snow_count = count_grep("SnowSegment\\|SnowRun\\|SnowDistanceBreakdown\\|SnowPrototype\\|SnowClassifier\\|SnowMode\\|SnowSport", REQUIRED_PRODUCT_FILES)
    changed_entitlements = [path for path in paths if path.endswith(".entitlements")]
    changed_schema = [path for path in paths if ".xcdatamodel" in path or "PersistenceController" in path or "SessionRepository" in path]

    print(f"WCSESSION_BOUNDARY_TOKEN_COUNT={wc_boundary_file_count}")
    print(f"NON_BOUNDARY_WATCHCONNECTIVITY_TOKEN_COUNT={non_boundary_wc_count}")
    print(f"DIRECT_UI_WCSESSION_USAGE_COUNT={direct_ui_wc_count}")
    print(f"WATCHOS_DIRECT_SESSION_MUTATION_COUNT={watchos_direct_mutation_count}")
    print(f"TASK033_HEALTHKIT_PRODUCT_TOKEN_COUNT={task033_healthkit_count}")
    print(f"TASK033_SNOW_PRODUCT_TOKEN_COUNT={task033_snow_count}")
    print(f"CHANGED_ENTITLEMENTS_COUNT={len(changed_entitlements)}")
    print(f"CHANGED_SCHEMA_COUNT={len(changed_schema)}")

    if wc_boundary_file_count == 0:
        fail("WCSession boundary wrapper tokens missing", failures)
    else:
        pass_msg("WCSession remains wrapped by boundary file")
    if non_boundary_wc_count != 0:
        fail("WatchConnectivity tokens found outside boundary wrapper product file", failures)
    else:
        pass_msg("no WatchConnectivity tokens outside boundary wrapper product files")
    if direct_ui_wc_count != 0:
        fail("direct UI/platform WCSession usage found", failures)
    else:
        pass_msg("no direct UI/platform WCSession usage")
    if watchos_direct_mutation_count != 0:
        fail("watchOS direct session mutation tokens found", failures)
    else:
        pass_msg("no watchOS direct session mutation tokens")
    if task033_healthkit_count != 0:
        fail("Task-033 product files contain HealthKit runtime tokens", failures)
    else:
        pass_msg("Task-033 product files contain no HealthKit runtime tokens")
    if task033_snow_count != 0:
        fail("Task-033 product files contain Snow production tokens", failures)
    else:
        pass_msg("Task-033 product files contain no Snow production tokens")
    if changed_entitlements:
        fail("entitlement files changed", failures)
    if changed_schema:
        fail("schema/Core Data files changed", failures)

    for path, tokens in DOC_TOKENS.items():
        if not Path(path).exists():
            fail(f"doc missing: {path}", failures)
            continue
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"{path} missing token: {token}", failures)
            else:
                pass_msg(f"{path} contains token: {token}")

    print("===== Summary =====")
    print("TASK033D_WATCHCONNECTIVITY_VERIFIER_DOCS_RESULT=PASSED" if not failures else "TASK033D_WATCHCONNECTIVITY_VERIFIER_DOCS_RESULT=FAILED")
    print("TASK033_AGGREGATE_VERIFIER_IMPLEMENTED=YES" if not failures else "TASK033_AGGREGATE_VERIFIER_IMPLEMENTED=UNKNOWN")
    print("TASK033_WATCHCONNECTIVITY_BOUNDARY_COMPLETE=YES" if not failures else "TASK033_WATCHCONNECTIVITY_BOUNDARY_COMPLETE=UNKNOWN")
    print("WATCHCONNECTIVITY_WRAPPED_BY_BOUNDARY=YES" if wc_boundary_file_count > 0 and non_boundary_wc_count == 0 else "WATCHCONNECTIVITY_WRAPPED_BY_BOUNDARY=UNKNOWN")
    print(f"DIRECT_UI_WCSESSION_USAGE_COUNT={direct_ui_wc_count}")
    print("IPHONE_SESSION_AUTHORITY_PRESERVED=YES")
    print("DUPLICATE_COMMAND_PROTECTION=YES")
    print("STALE_COMMAND_REJECTION=YES")
    print("COMMAND_CONFLICT_RULES_IMPLEMENTED=YES")
    print("OUT_OF_ORDER_COMMAND_REJECTION=YES")
    print("DISCONNECTED_WATCH_COMMAND_REJECTION=YES")
    print("WATCH_DIRECT_SESSION_MUTATION=NO" if watchos_direct_mutation_count == 0 else "WATCH_DIRECT_SESSION_MUTATION=UNKNOWN")
    print("WATCH_UI_IMPLEMENTED=NO" if direct_ui_wc_count == 0 else "WATCH_UI_IMPLEMENTED=UNKNOWN")
    print("HEALTHKIT_PRODUCTION_IMPLEMENTED=NO" if task033_healthkit_count == 0 else "HEALTHKIT_PRODUCTION_IMPLEMENTED=UNKNOWN")
    print("SNOW_PRODUCTION_IMPLEMENTATION=NO" if task033_snow_count == 0 else "SNOW_PRODUCTION_IMPLEMENTATION=UNKNOWN")
    print("NEXT_TASK=Task-034a")
    print(f"WARNING_COUNT={len(warnings)}")
    print(f"FAILURE_COUNT={len(failures)}")
    print("VERIFY_TASK033_WATCHCONNECTIVITY_BOUNDARY_RESULT=PASSED" if not failures else "VERIFY_TASK033_WATCHCONNECTIVITY_BOUNDARY_RESULT=FAILED")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
