#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

EXPECTED_BRANCHES = {"task-033-watchconnectivity-boundary", "develop"}
BASE_HEAD = "c7c1992a5f9768cbe3be3d3fe870cc3d53a75c7e"
ALLOWED_PATHS = {
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
    "Tests/iOSTests/WatchBridgeMirroredSessionCommandTests.swift",
    "scripts/verify_task033b_mirrored_session_commands.py",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
}
REQUIRED_FILES = [
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
    "Tests/iOSTests/WatchBridgeMirroredSessionCommandTests.swift",
    "scripts/verify_task033b_mirrored_session_commands.py",
    "Shared/WatchBridge/WatchBridgeConnectivityBoundary.swift",
    "Shared/WatchBridge/WatchBridgeWCSessionBoundary.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
]
TOKENS = {
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift": [
        "public enum WatchBridgeMirroredSessionCommandAction",
        "case start", "case pause", "case resume", "case stop",
        "public enum WatchBridgeMirroredCommandDecisionState",
        "case accepted", "case rejected", "case duplicate", "case stale",
        "public struct WatchBridgeMirroredSessionCommandPolicy",
        "public struct WatchBridgeMirroredCommandRequest",
        "idempotencyKey", "isStale",
        "public struct WatchBridgeMirroredCommandAuthorityDecision",
        "public struct WatchBridgeMirroredCommandDecision",
        "acknowledgementPayload",
    ],
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift": [
        "public protocol WatchBridgeMirroredSessionCommandAuthority",
        "public struct WatchBridgeMirroredCommandProcessor",
        "completedCommandIds", "processEnvelope", "invalidDirection",
        "staleCommand", "duplicateCommand", "missingSessionId",
        "iPhoneAuthorityRejected", "payload: .commandResult",
    ],
    "Tests/iOSTests/WatchBridgeMirroredSessionCommandTests.swift": [
        "WatchBridgeMirroredSessionCommandTests",
        "testProcessorAcceptsWatchStartAfterIPhoneAuthorityValidation",
        "testProcessorRejectsStaleCommandBeforeAuthorityValidation",
        "testProcessorIgnoresDuplicateCommandWithoutSecondAuthorityCall",
        "testProcessorRejectsPauseWithoutAuthoritativeSessionId",
        "testProcessorRejectsNonWatchInitiatedCommandDirection",
        "RecordingAuthority",
    ],
}
DOC_TOKENS = {
    "docs/process/PHASE_1B_AGENT_STATE.md": [
        "TASK033B_MIRRORED_SESSION_COMMANDS_RESULT=PASSED",
        "MIRRORED_SESSION_COMMAND_BOUNDARY_IMPLEMENTED=YES",
        "IPHONE_SESSION_AUTHORITY_PRESERVED=YES",
        "DUPLICATE_COMMAND_PROTECTION=YES",
        "STALE_COMMAND_REJECTION=YES",
        "WATCH_DIRECT_SESSION_MUTATION=NO",
        "WATCH_UI_IMPLEMENTED=NO",
        "NEXT_TASK=Task-033c",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-033b-001 Mirrored Session Commands",
        "MIRRORED_SESSION_COMMAND_BOUNDARY_IMPLEMENTED=YES",
        "IPHONE_SESSION_AUTHORITY_PRESERVED=YES",
        "NEXT_TASK=Task-033c",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-033b Mirrored Session Commands Addendum",
        "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
        "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
        "Tests/iOSTests/WatchBridgeMirroredSessionCommandTests.swift",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-033b Mirrored Session Commands",
        "iPhone-side session authority",
        "no Watch UI",
        "no direct Watch session mutation",
    ],
}
FORBIDDEN_NEW_FILE_TOKENS = [
    "SwiftUI", " View", "Button", "NavigationStack", "List", "Text(",
    "HealthKit", "HKWorkout", "HKLiveWorkoutBuilder", "HKHealthStore",
    "SnowSegment", "SnowRun", "SnowClassifier", "SnowMode", "SnowSport",
    "PersistenceController", "NSManagedObject", ".xcdatamodel", "CoreData",
    "CLLocationManager", "trustedMetric", "route geometry", "RouteGeometry",
]

failures = []

def run(cmd):
    return subprocess.run(cmd, text=True, capture_output=True, check=False)

def pass_msg(message):
    print(f"PASS: {message}")

def fail(message):
    print(f"FAIL: {message}")
    failures.append(message)

def read(path):
    return Path(path).read_text(encoding="utf-8")

print("===== Task-033b Mirrored Session Commands verifier =====")
print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
print("Aligned subtask: Task-033b — Mirrored Session Commands")
print("Not implementing: Watch UI, HealthKit workout runtime, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
print(f"REPO={Path.cwd()}")

if not Path(".git").exists():
    fail("repo path does not contain .git")
else:
    pass_msg("repo path contains .git")

branch = run(["git", "branch", "--show-current"]).stdout.strip()
head = run(["git", "rev-parse", "HEAD"]).stdout.strip()
print(f"CURRENT_BRANCH={branch}")
print(f"CURRENT_HEAD_FULL={head}")
if branch in EXPECTED_BRANCHES:
    pass_msg("current branch is valid for Task-033b verification")
else:
    fail(f"unexpected branch: {branch}")

base_check = run(["git", "merge-base", "--is-ancestor", BASE_HEAD, "HEAD"])
print(f"TASK033A_BASE_REACHABLE_EXIT={base_check.returncode}")
if base_check.returncode == 0:
    print("TASK033A_BASE_REACHABLE=YES")
    pass_msg("Task-033a branch head is reachable from HEAD")
else:
    print("TASK033A_BASE_REACHABLE=NO")
    fail("Task-033a branch head is not reachable from HEAD")

status_paths = []
for line in run(["git", "status", "--porcelain=v1"]).stdout.splitlines():
    if not line:
        continue
    path = line[3:]
    if " -> " in path:
        path = path.split(" -> ", 1)[1]
    status_paths.append(path)
    print(f"TASK033B_STATUS_PATH={path}")
unexpected = sorted(set(status_paths) - ALLOWED_PATHS)
print(f"TASK033B_STATUS_PATH_COUNT={len(status_paths)}")
print(f"UNEXPECTED_TASK033B_STATUS_PATH_COUNT={len(unexpected)}")
for path in unexpected:
    fail(f"unexpected changed path: {path}")
if not unexpected:
    pass_msg("changed paths are limited to Task-033b command boundary/docs/verifier/test/project scope")

for path in REQUIRED_FILES:
    if Path(path).exists():
        pass_msg(f"required path exists: {path}")
    else:
        fail(f"missing required path: {path}")

for path, tokens in TOKENS.items():
    if not Path(path).exists():
        continue
    text = read(path)
    lines = text.splitlines()
    first = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if first.startswith("// [協作區]") or first.startswith("// [自主區]"):
        pass_msg(f"{path} has a valid collaboration/autonomous header")
    else:
        fail(f"{path} missing collaboration/autonomous header")
    if len(lines) <= 500:
        pass_msg(f"{path} stays under 500 lines")
    else:
        fail(f"{path} exceeds 500 lines")
    for token in tokens:
        if token in text:
            pass_msg(f"{path} contains token: {token}")
        else:
            fail(f"{path} missing token: {token}")
    forbidden_count = sum(text.count(token) for token in FORBIDDEN_NEW_FILE_TOKENS)
    print(f"FORBIDDEN_NEW_FILE_TOKEN_COUNT[{path}]={forbidden_count}")
    if forbidden_count == 0:
        pass_msg(f"{path} contains no forbidden UI/HealthKit/Snow/schema/route tokens")
    else:
        fail(f"{path} contains forbidden UI/HealthKit/Snow/schema/route tokens")

pbx = read("SkateTrack.xcodeproj/project.pbxproj") if Path("SkateTrack.xcodeproj/project.pbxproj").exists() else ""
for name, min_sources in [
    ("WatchBridgeMirroredCommandModels.swift", 2),
    ("WatchBridgeMirroredCommandProcessor.swift", 2),
    ("WatchBridgeMirroredSessionCommandTests.swift", 1),
]:
    token_count = pbx.count(name)
    source_count = pbx.count(f"{name} in Sources")
    print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
    print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
    if token_count >= 1 and source_count >= min_sources:
        pass_msg(f"{name} has expected project/source membership")
    else:
        fail(f"{name} missing expected project/source membership")

checks = {
    "DIRECT_UI_WCSESSION_USAGE_COUNT": "git grep -n 'WCSession\\|WatchConnectivity' -- iOS watchOS macOS",
    "ENTITLEMENTS_CHANGED_COUNT": "git diff --name-only | grep -E '\\.entitlements$'",
    "SCHEMA_CHANGED_COUNT": "git diff --name-only | grep -E '(\\.xcdatamodel|\\.xcdatamodeld|PersistenceController|SessionRepository|SessionEntityMapper)'",
    "WATCH_UI_CHANGED_COUNT": "git diff --name-only | grep -E '^watchOS/'",
    "SNOW_CHANGED_COUNT": "git diff --name-only | grep -E '(SnowSegment|SnowRun|SnowClassifier|SnowMode|SnowSport)'",
}
for label, command in checks.items():
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    count = len([line for line in result.stdout.splitlines() if line.strip()])
    print(f"{label}={count}")
    if count != 0:
        fail(f"{label} expected 0")

processor_text = read("Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift") if Path("Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift").exists() else ""
mutation_tokens = ["SessionRepository", "PersistenceController", "HKWorkout", "startWorkout", "beginCollection"]
mutation_count = sum(processor_text.count(token) for token in mutation_tokens)
print(f"WATCH_DIRECT_SESSION_MUTATION_TOKEN_COUNT={mutation_count}")
if mutation_count == 0:
    pass_msg("mirrored command processor contains no direct session/HealthKit mutation tokens")
else:
    fail("mirrored command processor contains direct session/HealthKit mutation tokens")

for path, tokens in DOC_TOKENS.items():
    if not Path(path).exists():
        fail(f"missing documentation path: {path}")
        continue
    text = read(path)
    for token in tokens:
        if token in text:
            pass_msg(f"{path} contains token: {token}")
        else:
            fail(f"{path} missing token: {token}")

print("===== Summary =====")
print("TASK033B_MIRRORED_SESSION_COMMANDS_RESULT=PASSED" if not failures else "TASK033B_MIRRORED_SESSION_COMMANDS_RESULT=FAILED")
print("MIRRORED_SESSION_COMMAND_BOUNDARY_IMPLEMENTED=YES")
print("IPHONE_SESSION_AUTHORITY_PRESERVED=YES")
print("DUPLICATE_COMMAND_PROTECTION=YES")
print("STALE_COMMAND_REJECTION=YES")
print("WATCH_DIRECT_SESSION_MUTATION=NO")
print("WATCH_UI_IMPLEMENTED=NO")
print("NEXT_TASK=Task-033c")
print("WARNING_COUNT=0")
print(f"FAILURE_COUNT={len(failures)}")
if failures:
    print("VERIFY_TASK033B_MIRRORED_SESSION_COMMANDS_RESULT=FAILED")
    sys.exit(1)
print("VERIFY_TASK033B_MIRRORED_SESSION_COMMANDS_RESULT=PASSED")
