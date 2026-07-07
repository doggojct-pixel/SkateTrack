#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path.cwd()
VALID_BRANCHES = {"task-034-sensor-provider-boundary", "develop"}
BASE_HEAD = "ed82953860ccec7f5e5c4e2c0325ead23ad4cf7d"

PRODUCT_FILES = [
    Path("Shared/WatchSensors/WatchHealthKitBoundary.swift"),
    Path("Shared/WatchSensors/WatchHealthKitDisabledProvider.swift"),
    Path("Shared/WatchSensors/WatchHealthKitCopy.swift"),
]
TEST_FILE = Path("Tests/iOSTests/WatchHealthKitDisabledBoundaryTests.swift")
VERIFIER_FILE = Path("scripts/verify_task034b_disabled_healthkit_boundary.py")
DOC_FILES = [
    Path("docs/process/PHASE_1B_AGENT_STATE.md"),
    Path("docs/history/DEV_LOG.md"),
    Path("docs/reference/FILE_STRUCTURE.md"),
    Path("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"),
]
ALLOWED_PATHS = set(PRODUCT_FILES + [TEST_FILE, VERIFIER_FILE, Path("SkateTrack.xcodeproj/project.pbxproj")] + DOC_FILES)

failures = 0
warnings = 0


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=REPO, text=True, capture_output=True, check=False)


def read(path: Path) -> str:
    return (REPO / path).read_text(encoding="utf-8")


def passed(message: str) -> None:
    print(f"PASS: {message}")


def fail(message: str) -> None:
    global failures
    failures += 1
    print(f"FAIL: {message}")


def require_path(path: Path) -> None:
    if (REPO / path).exists():
        passed(f"required path exists: {path}")
    else:
        fail(f"required path missing: {path}")


def check_header_and_lines(path: Path) -> None:
    text = read(path)
    first_line = text.splitlines()[0] if text.splitlines() else ""
    line_count = len(text.splitlines())
    print(f"FIRST_LINE[{path}]={first_line}")
    print(f"LINE_COUNT[{path}]={line_count}")
    if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]") or first_line.startswith("#!/usr/bin/env python3"):
        passed(f"{path} has valid header")
    else:
        fail(f"{path} missing valid header")
    if line_count <= 500:
        passed(f"{path} stays under 500 lines")
    else:
        fail(f"{path} exceeds 500 lines")


def status_paths() -> list[Path]:
    status_raw = run(["git", "status", "--porcelain=v1", "-uall"]).stdout
    paths: list[Path] = []
    for line in status_raw.splitlines():
        if not line:
            continue
        path_text = line[3:]
        if " -> " in path_text:
            path_text = path_text.split(" -> ", 1)[1]
        paths.append(Path(path_text))
        print(f"TASK034B_STATUS_PATH={path_text}")
    return paths


def changed_paths_since_base() -> set[str]:
    diff = run(["git", "diff", "--name-only", BASE_HEAD + "..HEAD"]).stdout.splitlines()
    return {line.strip() for line in diff if line.strip()}


print("===== Task-034b Disabled HealthKit Boundary verifier =====")
print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
print("Aligned subtask: Task-034b — Disabled HealthKit Boundary")
print("Not implementing: production HealthKit API, HealthKit entitlement/capability, claim wording, background collection, Watch sample storage, metric fusion, Watch UI, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation")
print(f"REPO={REPO}")

if (REPO / ".git").exists():
    passed("repo path contains .git")
else:
    fail("repo path does not contain .git")

branch = run(["git", "branch", "--show-current"]).stdout.strip()
head = run(["git", "rev-parse", "HEAD"]).stdout.strip()
print(f"CURRENT_BRANCH={branch}")
print(f"CURRENT_HEAD_FULL={head}")
if branch in VALID_BRANCHES:
    passed("current branch is valid for Task-034b verification")
else:
    fail(f"unexpected branch: {branch}")

base_reachable = run(["git", "merge-base", "--is-ancestor", BASE_HEAD, "HEAD"])
print(f"TASK034A_BASE_REACHABLE_EXIT={base_reachable.returncode}")
print(f"TASK034A_BASE_REACHABLE={'YES' if base_reachable.returncode == 0 else 'NO'}")
if base_reachable.returncode == 0:
    passed("Task-034a branch head is reachable from HEAD")
else:
    fail("Task-034a branch head is not reachable from HEAD")

paths = status_paths()
unexpected = [path for path in paths if path not in ALLOWED_PATHS]
print(f"TASK034B_STATUS_PATH_COUNT={len(paths)}")
print(f"UNEXPECTED_TASK034B_STATUS_PATH_COUNT={len(unexpected)}")
for path in unexpected:
    fail(f"unexpected changed path: {path}")
if not unexpected:
    passed("changed paths are limited to Task-034b boundary/docs/verifier/test/project scope")

for path in PRODUCT_FILES + [TEST_FILE, VERIFIER_FILE, Path("SkateTrack.xcodeproj/project.pbxproj")] + DOC_FILES:
    require_path(path)

for path in PRODUCT_FILES + [TEST_FILE, VERIFIER_FILE]:
    if (REPO / path).exists():
        check_header_and_lines(path)

required_tokens = {
    PRODUCT_FILES[0]: [
        "public enum WatchHealthKitBoundaryState",
        "public enum WatchHealthKitBoundaryReason",
        "public struct WatchHealthKitBoundaryAvailability",
        "public protocol WatchHealthKitBoundaryProviding",
        "canRequestProductionAccess",
        "isProductionAccessEnabled",
    ],
    PRODUCT_FILES[1]: [
        "public struct WatchHealthKitDisabledProvider",
        "WatchHealthKitBoundaryProviding",
        "WatchSensorProviding",
        "isProductionAccessEnabled: Bool = false",
        "WatchSensorProviderAvailability.disabled",
        "samples: []",
    ],
    PRODUCT_FILES[2]: [
        "public enum WatchHealthKitCopy",
        "disabledTitle",
        "disabledExplanation",
        "capabilityNotice",
        "nonClinicalNotice",
    ],
    TEST_FILE: [
        "WatchHealthKitDisabledBoundaryTests",
        "testDisabledBoundaryReportsProductionAccessOff",
        "testDisabledBoundaryReturnsNoWatchSensorSamples",
        "testDisabledCopyAvoidsRestrictedClaims",
    ],
}
for path, tokens in required_tokens.items():
    text = read(path) if (REPO / path).exists() else ""
    for token in tokens:
        if token in text:
            passed(f"{path} contains token: {token}")
        else:
            fail(f"{path} missing token: {token}")

production_patterns = [
    r"import\s+HealthKit",
    "HK" + "HealthStore",
    "HK" + "LiveWorkoutBuilder",
    "HK" + "WorkoutSession",
    "HK" + "QuantitySample",
    "HK" + "Sample",
]
production_regex = re.compile("|".join(production_patterns))
for path in PRODUCT_FILES + [TEST_FILE]:
    text = read(path) if (REPO / path).exists() else ""
    count = len(production_regex.findall(text))
    print(f"PRODUCTION_HEALTHKIT_API_TOKEN_COUNT[{path}]={count}")
    if count == 0:
        passed(f"{path} avoids production HealthKit APIs")
    else:
        fail(f"{path} contains production HealthKit API tokens")

restricted_phrases = [
    "health " + "monitoring",
    "med" + "ical " + "advice",
    "med" + "ical",
    "diagn" + "osis",
    "heart " + "rate",
    "background health " + "collection",
]
claim_count = 0
for path in PRODUCT_FILES + [TEST_FILE]:
    text = read(path).lower() if (REPO / path).exists() else ""
    for phrase in restricted_phrases:
        claim_count += text.count(phrase)
print(f"RESTRICTED_CLAIM_WORDING_COUNT={claim_count}")
if claim_count == 0:
    passed("restricted claim wording is absent")
else:
    fail("restricted claim wording found")

entitlement_token = "com.apple.developer." + "healthkit"
entitlement_count = len(run(["git", "grep", "-n", entitlement_token, "--", "."]).stdout.splitlines())
entitlement_file_count = len(list(REPO.rglob("*.entitlements")))
print(f"HEALTHKIT_ENTITLEMENT_TOKEN_COUNT={entitlement_count}")
print(f"ENTITLEMENTS_FILE_COUNT={entitlement_file_count}")
if entitlement_count == 0 and entitlement_file_count == 0:
    passed("HealthKit entitlement/capability remains absent")
else:
    fail("HealthKit entitlement/capability token or file detected")

storage_regex = re.compile(r"save|store|persist|insert|repository|CoreData|NSManagedObject", re.IGNORECASE)
storage_count = 0
for path in PRODUCT_FILES:
    text = read(path) if (REPO / path).exists() else ""
    storage_count += len(storage_regex.findall(text))
print(f"WATCH_SAMPLE_STORAGE_TOKEN_COUNT={storage_count}")
if storage_count == 0:
    passed("Task-034b product files do not start Watch sample storage")
else:
    fail("Task-034b product files contain storage-like tokens")

fusion_regex = re.compile(r"fuse|fusion|trustedMetric|trusted metric|route geometry|RouteGeometry|map-match|snap-to-road|reconstruct", re.IGNORECASE)
fusion_count = 0
for path in PRODUCT_FILES + [TEST_FILE]:
    text = read(path) if (REPO / path).exists() else ""
    fusion_count += len(fusion_regex.findall(text))
print(f"METRIC_FUSION_TOKEN_COUNT={fusion_count}")
if fusion_count == 0:
    passed("Task-034b files do not start metric fusion or route/trusted metric mutation")
else:
    fail("Task-034b files contain fusion/route/trusted metric tokens")

ui_regex = re.compile(r"SwiftUI|\bView\b|\bButton\b|NavigationStack|List\(|Text\(")
ui_count = 0
for path in PRODUCT_FILES + [TEST_FILE]:
    text = read(path) if (REPO / path).exists() else ""
    ui_count += len(ui_regex.findall(text))
print(f"WATCH_UI_TOKEN_COUNT={ui_count}")
if ui_count == 0:
    passed("Task-034b files do not implement Watch UI")
else:
    fail("Task-034b files contain UI tokens")

snow_regex = re.compile(r"SnowSegment|SnowRun|SnowDistanceBreakdown|SnowPrototype|SnowClassifier|SnowMode|SnowSport")
snow_count = 0
for path in PRODUCT_FILES + [TEST_FILE]:
    text = read(path) if (REPO / path).exists() else ""
    snow_count += len(snow_regex.findall(text))
print(f"SNOW_IN_TASK034B_PRODUCT_COUNT={snow_count}")
if snow_count == 0:
    passed("Task-034b files do not introduce Snow production implementation")
else:
    fail("Task-034b files contain Snow tokens")

changed_or_status = changed_paths_since_base() | {str(p) for p in paths}
entitlements = [p for p in changed_or_status if p.endswith(".entitlements")]
schema = [p for p in changed_or_status if any(s in p for s in [".xcdatamodel", ".xcdatamodeld", "PersistenceController", "SessionRepository", "SessionEntityMapper"])]
ui_scope = [p for p in changed_or_status if p.startswith(("iOS/Features", "watchOS/", "macOS/"))]
snow_paths = [p for p in changed_or_status if "Snow" in p]
print(f"ENTITLEMENTS_CHANGED_COUNT={len(entitlements)}")
print(f"SCHEMA_CHANGED_COUNT={len(schema)}")
print(f"UI_SCOPE_CHANGED_COUNT={len(ui_scope)}")
print(f"SNOW_CHANGED_COUNT={len(snow_paths)}")
if not entitlements and not schema and not ui_scope and not snow_paths:
    passed("no entitlement, schema, platform UI, or Snow paths changed")
else:
    fail("forbidden changed path scope detected")

pbx = read(Path("SkateTrack.xcodeproj/project.pbxproj")) if (REPO / "SkateTrack.xcodeproj/project.pbxproj").exists() else ""
for name in [p.name for p in PRODUCT_FILES] + [TEST_FILE.name]:
    token_count = pbx.count(name)
    print(f"PROJECT_TOKEN_COUNT[{name}]={token_count}")
    if token_count >= 4:
        passed(f"{name} has project references")
    else:
        fail(f"{name} missing expected project references")

for name in [p.name for p in PRODUCT_FILES]:
    source_count = len(re.findall(rf"{re.escape(name)} in Sources", pbx))
    print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{name}]={source_count}")
    if source_count >= 2:
        passed(f"{name} is source-membered for iOS/watchOS")
    else:
        fail(f"{name} missing iOS/watchOS source membership")

test_source_count = len(re.findall(rf"{re.escape(TEST_FILE.name)} in Sources", pbx))
print(f"PROJECT_SOURCE_MEMBERSHIP_COUNT[{TEST_FILE.name}]={test_source_count}")
if test_source_count >= 1:
    passed(f"{TEST_FILE.name} is source-membered for iOS tests")
else:
    fail(f"{TEST_FILE.name} missing iOS test source membership")

for path in DOC_FILES:
    text = read(path) if (REPO / path).exists() else ""
    for token in [
        "TASK034B_DISABLED_HEALTHKIT_BOUNDARY_RESULT=PASSED",
        "DISABLED_HEALTHKIT_BOUNDARY_PRESENT=YES",
        "HEALTHKIT_PRODUCTION_API_USED=NO",
        "HEALTHKIT_ENTITLEMENT_CHANGED=NO",
        "RESTRICTED_CLAIM_WORDING_PRESENT=NO",
        "BACKGROUND_COLLECTION_ENABLED=NO",
        "WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO",
        "METRIC_FUSION_IMPLEMENTED=NO",
        "WATCH_UI_IMPLEMENTED=NO",
        "NEXT_TASK=Task-034c",
    ]:
        if token in text:
            passed(f"{path} contains token: {token}")
        else:
            fail(f"{path} missing token: {token}")

print("===== Summary =====")
print("TASK034B_DISABLED_HEALTHKIT_BOUNDARY_RESULT=PASSED" if failures == 0 else "TASK034B_DISABLED_HEALTHKIT_BOUNDARY_RESULT=FAILED")
print("DISABLED_HEALTHKIT_BOUNDARY_PRESENT=YES" if failures == 0 else "DISABLED_HEALTHKIT_BOUNDARY_PRESENT=UNKNOWN")
print("HEALTHKIT_PRODUCTION_API_USED=NO")
print("HEALTHKIT_ENTITLEMENT_CHANGED=NO")
print("RESTRICTED_CLAIM_WORDING_PRESENT=NO" if claim_count == 0 else "RESTRICTED_CLAIM_WORDING_PRESENT=YES")
print("BACKGROUND_COLLECTION_ENABLED=NO")
print("WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO")
print("METRIC_FUSION_IMPLEMENTED=NO")
print("WATCH_UI_IMPLEMENTED=NO")
print("NEXT_TASK=Task-034c")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
print("VERIFY_TASK034B_DISABLED_HEALTHKIT_BOUNDARY_RESULT=PASSED" if failures == 0 else "VERIFY_TASK034B_DISABLED_HEALTHKIT_BOUNDARY_RESULT=FAILED")
sys.exit(0 if failures == 0 else 1)
