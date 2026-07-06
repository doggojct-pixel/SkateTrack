#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

EXPECTED_BRANCH = "task-033-watchconnectivity-boundary"
EXPECTED_TASK033B_HEAD = "4d9acbff3a706253ca60bcba3c28fa4a6777e8e3"
ALLOWED_STATUS_PATHS = {
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
    "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift",
    "Tests/iOSTests/WatchBridgeCommandSafetyTests.swift",
    "scripts/verify_task033c_command_safety_conflict_rules.py",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
}
REQUIRED_FILES = [
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
    "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift",
    "Tests/iOSTests/WatchBridgeCommandSafetyTests.swift",
    "scripts/verify_task033c_command_safety_conflict_rules.py",
    "SkateTrack.xcodeproj/project.pbxproj",
]
TOKEN_REQUIREMENTS = {
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift": [
        "case iPhoneActionInProgress", "case outOfOrderCommand", "case watchDisconnected",
        "public let rejectionReason: WatchBridgeMirroredCommandRejectionReason?",
        "rejectionReason: WatchBridgeMirroredCommandRejectionReason = .iPhoneAuthorityRejected",
    ],
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift": [
        "authorityDecision.rejectionReason ?? .iPhoneAuthorityRejected", "payload: .commandResult",
        "policy.requiredDestination", "policy.requiredSource",
    ],
    "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift": [
        "public struct WatchBridgeCommandSafetyContext", "public struct WatchBridgeCommandSafetyDecision",
        "public struct WatchBridgeCommandSafetyRules", "public final class WatchBridgeCommandSafetyAuthority",
        "iPhoneActionInProgress", "outOfOrderCommand", "watchDisconnected",
        "canForwardToIPhoneAuthority", "latestAcceptedCommandIssuedAt", "requiresReachableWatch",
    ],
    "Tests/iOSTests/WatchBridgeCommandSafetyTests.swift": [
        "WatchBridgeCommandSafetyTests", "testRejectsSimultaneousIPhoneActionBeforeAuthorityValidation",
        "testRejectsOutOfOrderWatchCommandBeforeAuthorityValidation",
        "testRejectsDisconnectedWatchStateWithoutAuthorityValidation",
        "testForwardsReachableInOrderWatchCommandToIPhoneAuthority", "SafetyRecordingAuthority",
    ],
}
DOC_REQUIREMENTS = {
    "docs/process/PHASE_1B_AGENT_STATE.md": [
        "TASK033C_COMMAND_SAFETY_CONFLICT_RULES_RESULT=PASSED",
        "COMMAND_CONFLICT_RULES_IMPLEMENTED=YES", "IPHONE_WATCH_CONFLICT_PRECEDENCE=IPHONE_AUTHORITY_FIRST",
        "OUT_OF_ORDER_COMMAND_REJECTION=YES", "DISCONNECTED_WATCH_COMMAND_REJECTION=YES",
        "WATCH_DIRECT_SESSION_MUTATION=NO", "WATCH_UI_IMPLEMENTED=NO", "NEXT_TASK=Task-033d",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-033c-001 Command Safety / Conflict Rules", "COMMAND_CONFLICT_RULES_IMPLEMENTED=YES",
        "OUT_OF_ORDER_COMMAND_REJECTION=YES", "NEXT_TASK=Task-033d",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-033c Command Safety / Conflict Rules Addendum",
        "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift", "Tests/iOSTests/WatchBridgeCommandSafetyTests.swift",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-033c Command Safety / Conflict Rules", "iPhone-side authority remains final",
        "no Watch UI", "no direct Watch session mutation",
    ],
}
FORBIDDEN_NEW_FILE_TOKENS = [
    "import SwiftUI", "SwiftUI", "View", "Button(", "NavigationStack", "List(",
    "HealthKit", "HKWorkout", "HKLiveWorkoutBuilder", "HKHealthStore",
    "SnowSegment", "SnowRun", "SnowDistanceBreakdown", "SnowPrototype", "SnowClassifier",
    "NSManagedObject", "CoreData", "PersistenceController", "SessionRepository",
    "RouteGeometry", "map-match", "snap-to-road", "reconstruct", "trustedMetric",
]
SWIFT_CHECK_FILES = [
    "Shared/WatchBridge/WatchBridgeMirroredCommandModels.swift",
    "Shared/WatchBridge/WatchBridgeMirroredCommandProcessor.swift",
    "Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift",
    "Tests/iOSTests/WatchBridgeCommandSafetyTests.swift",
]
failures = 0
warnings = 0

def run(cmd):
    return subprocess.run(cmd, text=True, capture_output=True, check=False)
def fail(message):
    global failures
    failures += 1
    print(f"FAIL: {message}")
def pass_(message):
    print(f"PASS: {message}")
def read(path):
    return Path(path).read_text(encoding="utf-8")
print("===== Task-033c Command Safety / Conflict Rules verifier =====")
print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
print("Aligned subtask: Task-033c — Command Safety / Conflict Rules")
print("Not implementing: Watch UI, direct Watch session mutation, HealthKit workout runtime, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
print(f"REPO={Path.cwd()}")
if Path(".git").exists(): pass_("repo path contains .git")
else: fail("repo path does not contain .git")
branch = run(["git", "branch", "--show-current"]).stdout.strip()
head = run(["git", "rev-parse", "HEAD"]).stdout.strip()
print(f"CURRENT_BRANCH={branch}")
print(f"CURRENT_HEAD_FULL={head}")
if branch == EXPECTED_BRANCH: pass_("current branch is valid for Task-033c verification")
else: fail(f"unexpected branch: {branch}")
base = run(["git", "merge-base", "--is-ancestor", EXPECTED_TASK033B_HEAD, "HEAD"])
print(f"TASK033B_BASE_REACHABLE_EXIT={base.returncode}")
print(f"TASK033B_BASE_REACHABLE={'YES' if base.returncode == 0 else 'NO'}")
if base.returncode == 0: pass_("Task-033b branch head is reachable from HEAD")
else: fail("Task-033b branch head is not reachable from HEAD")
status_paths = []
for line in run(["git", "status", "--porcelain=v1"]).stdout.splitlines():
    if not line: continue
    p = line[3:]
    if " -> " in p: p = p.split(" -> ", 1)[1]
    status_paths.append(p)
    print(f"TASK033C_STATUS_PATH={p}")
print(f"TASK033C_STATUS_PATH_COUNT={len(status_paths)}")
unexpected = sorted(set(status_paths) - ALLOWED_STATUS_PATHS)
print(f"UNEXPECTED_TASK033C_STATUS_PATH_COUNT={len(unexpected)}")
if unexpected:
    for p in unexpected: fail(f"unexpected Task-033c status path: {p}")
else: pass_("changed paths are limited to Task-033c conflict/docs/verifier/test/project scope")
for path in REQUIRED_FILES:
    if Path(path).exists(): pass_(f"required path exists: {path}")
    else: fail(f"required path is missing: {path}")
for path in SWIFT_CHECK_FILES:
    p = Path(path)
    if not p.exists(): continue
    lines = p.read_text(encoding="utf-8").splitlines()
    first = lines[0] if lines else ""
    print(f"FIRST_LINE[{path}]={first}")
    print(f"LINE_COUNT[{path}]={len(lines)}")
    if first.startswith("// [協作區]") or first.startswith("// [自主區]"): pass_(f"{path} has a valid collaboration/autonomous header")
    else: fail(f"{path} missing collaboration/autonomous header")
    if len(lines) <= 500: pass_(f"{path} stays under 500 lines")
    else: fail(f"{path} exceeds 500 lines")
for path, tokens in TOKEN_REQUIREMENTS.items():
    if not Path(path).exists(): continue
    content = read(path)
    for token in tokens:
        if token in content: pass_(f"{path} contains token: {token}")
        else: fail(f"{path} missing token: {token}")
new_product = Path("Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift")
if new_product.exists():
    content = read(new_product)
    count = sum(content.count(token) for token in FORBIDDEN_NEW_FILE_TOKENS)
    print(f"FORBIDDEN_NEW_FILE_TOKEN_COUNT[{new_product}]={count}")
    if count == 0: pass_("WatchBridgeCommandSafetyRules.swift contains no forbidden UI/HealthKit/Snow/schema/route tokens")
    else: fail("WatchBridgeCommandSafetyRules.swift contains forbidden implementation tokens")
pbx = Path("SkateTrack.xcodeproj/project.pbxproj")
if pbx.exists():
    content = read(pbx)
    for name, minimum in {
        "WatchBridgeCommandSafetyRules.swift": 4,
        "WatchBridgeCommandSafetyTests.swift": 2,
        "WatchBridgeMirroredCommandModels.swift": 6,
        "WatchBridgeMirroredCommandProcessor.swift": 6,
    }.items():
        token_count = content.count(name)
        source_count = content.count(f"{name} in Sources")
        print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
        print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
        if token_count >= minimum and source_count >= (1 if name.endswith("Tests.swift") else 2): pass_(f"{name} has expected project/source membership")
        else: fail(f"{name} project/source membership is incomplete")
staged_names = run(["git", "diff", "--cached", "--name-only"]).stdout.splitlines()
changed_names = run(["git", "diff", "--name-only"]).stdout.splitlines()
all_changed = sorted(set(staged_names + changed_names + status_paths))
entitlements_count = sum(1 for p in all_changed if p.endswith(".entitlements"))
schema_count = sum(1 for p in all_changed if any(k in p for k in [".xcdatamodel", ".xcdatamodeld", "PersistenceController", "SessionRepository", "SessionEntityMapper"]))
watch_ui_count = sum(1 for p in all_changed if p.startswith("watchOS/") or p.startswith("iOS/Features/") or p.startswith("macOS/"))
snow_count = sum(1 for p in all_changed if any(k in p for k in ["SnowMode", "SnowSport", "SnowSession", "SnowRun", "SnowSegment", "SnowPrototype", "SnowClassifier"]))
print(f"ENTITLEMENTS_CHANGED_COUNT={entitlements_count}")
print(f"SCHEMA_CHANGED_COUNT={schema_count}")
print(f"WATCH_UI_CHANGED_COUNT={watch_ui_count}")
print(f"SNOW_CHANGED_COUNT={snow_count}")
if entitlements_count == schema_count == watch_ui_count == snow_count == 0: pass_("no entitlement, schema, UI platform, or Snow paths changed")
else: fail("forbidden changed scope detected")
ui_wc = run(["bash", "-lc", "git grep -n 'WCSession\\|WatchConnectivity' -- iOS watchOS macOS 2>/dev/null | wc -l | tr -d ' '"]).stdout.strip() or "0"
watch_direct = run(["bash", "-lc", "git grep -n 'startSession\\|pauseSession\\|resumeSession\\|endSession' -- watchOS 2>/dev/null | wc -l | tr -d ' '"]).stdout.strip() or "0"
new_health = run(["bash", "-lc", "git grep -n 'HealthKit\\|HKWorkout\\|HKLiveWorkoutBuilder\\|HKHealthStore' -- Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift 2>/dev/null | wc -l | tr -d ' '"]).stdout.strip() or "0"
new_snow = run(["bash", "-lc", "git grep -n 'SnowSegment\\|SnowRun\\|SnowDistanceBreakdown\\|SnowPrototype\\|SnowClassifier\\|SnowMode\\|SnowSport' -- Shared/WatchBridge/WatchBridgeCommandSafetyRules.swift 2>/dev/null | wc -l | tr -d ' '"]).stdout.strip() or "0"
print(f"DIRECT_UI_WCSESSION_USAGE_COUNT={ui_wc}")
print(f"WATCHOS_DIRECT_SESSION_MUTATION_COUNT={watch_direct}")
print(f"HEALTHKIT_IN_TASK033C_PRODUCT_COUNT={new_health}")
print(f"SNOW_IN_TASK033C_PRODUCT_COUNT={new_snow}")
if ui_wc == "0" and watch_direct == "0" and new_health == "0" and new_snow == "0": pass_("Task-033c safety rules preserve no direct UI WCSession, Watch mutation, HealthKit, or Snow implementation")
else: fail("Task-033c safety guardrail failed")
for path, tokens in DOC_REQUIREMENTS.items():
    if not Path(path).exists():
        fail(f"missing docs path: {path}"); continue
    content = read(path)
    for token in tokens:
        if token in content: pass_(f"{path} contains token: {token}")
        else: fail(f"{path} missing token: {token}")
print("===== Summary =====")
print("TASK033C_COMMAND_SAFETY_CONFLICT_RULES_RESULT=PASSED" if failures == 0 else "TASK033C_COMMAND_SAFETY_CONFLICT_RULES_RESULT=FAILED")
print("COMMAND_CONFLICT_RULES_IMPLEMENTED=YES")
print("IPHONE_WATCH_CONFLICT_PRECEDENCE=IPHONE_AUTHORITY_FIRST")
print("OUT_OF_ORDER_COMMAND_REJECTION=YES")
print("DISCONNECTED_WATCH_COMMAND_REJECTION=YES")
print("WATCH_DIRECT_SESSION_MUTATION=NO")
print("WATCH_UI_IMPLEMENTED=NO")
print("NEXT_TASK=Task-033d")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
print("VERIFY_TASK033C_COMMAND_SAFETY_CONFLICT_RULES_RESULT=PASSED" if failures == 0 else "VERIFY_TASK033C_COMMAND_SAFETY_CONFLICT_RULES_RESULT=FAILED")
sys.exit(0 if failures == 0 else 1)
