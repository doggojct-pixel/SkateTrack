#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path.cwd()
BASE_HEAD = "a327feed58c136325514430eeb194f15aca7fa88"
VALID_BRANCHES = {"task-034-sensor-provider-boundary", "develop"}

PRODUCT_FILES = [
    Path("Shared/WatchSensors/WatchSensorProviderProtocols.swift"),
    Path("Shared/WatchSensors/WatchSensorSampleModels.swift"),
    Path("Shared/WatchSensors/WatchSensorMockProvider.swift"),
    Path("Shared/WatchSensors/WatchSensorDisabledProvider.swift"),
]
TEST_FILE = Path("Tests/iOSTests/WatchSensorProviderAvailabilityTests.swift")
VERIFIER_FILE = Path("scripts/verify_task034a_watch_sensor_provider_protocols.py")
DOC_FILES = [
    Path("docs/process/PHASE_1B_AGENT_STATE.md"),
    Path("docs/history/DEV_LOG.md"),
    Path("docs/reference/FILE_STRUCTURE.md"),
    Path("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md"),
]
ALLOWED_PATHS = set(PRODUCT_FILES + [TEST_FILE, VERIFIER_FILE, Path("SkateTrack.xcodeproj/project.pbxproj")] + DOC_FILES)

failures = 0
warnings = 0

def run(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=REPO, text=True, capture_output=True, check=False)

def fail(message: str) -> None:
    global failures
    failures += 1
    print(f"FAIL: {message}")

def passed(message: str) -> None:
    print(f"PASS: {message}")

def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def require_path(path: Path) -> None:
    if (REPO / path).exists():
        passed(f"required path exists: {path}")
    else:
        fail(f"required path missing: {path}")

def check_header_and_lines(path: Path) -> None:
    text = read(path)
    first = text.splitlines()[0] if text.splitlines() else ""
    line_count = len(text.splitlines())
    print(f"FIRST_LINE[{path}]={first}")
    print(f"LINE_COUNT[{path}]={line_count}")
    if first.startswith("// [協作區]") or first.startswith("// [自主區]") or first.startswith("#!/usr/bin/env python3"):
        passed(f"{path} has valid header")
    else:
        fail(f"{path} missing valid header")
    if line_count <= 500:
        passed(f"{path} stays under 500 lines")
    else:
        fail(f"{path} exceeds 500 lines")

print("===== Task-034a Watch Sensor Provider Protocols verifier =====")
print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
print("Aligned subtask: Task-034a — Watch Sensor Provider Protocols")
print("Not implementing: Watch sample storage, metric fusion, production HealthKit API, HealthKit entitlement, Watch UI, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation")
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
    passed("current branch is valid for Task-034a verification")
else:
    fail(f"unexpected branch: {branch}")

base_reachable = run(["git", "merge-base", "--is-ancestor", BASE_HEAD, "HEAD"])
print(f"TASK033_DEVELOP_BASE_REACHABLE_EXIT={base_reachable.returncode}")
print(f"TASK033_DEVELOP_BASE_REACHABLE={'YES' if base_reachable.returncode == 0 else 'NO'}")
if base_reachable.returncode == 0:
    passed("Task-033 develop baseline is reachable from HEAD")
else:
    fail("Task-033 develop baseline is not reachable from HEAD")

status_raw = run(["git", "status", "--porcelain=v1"]).stdout
status_paths: list[Path] = []
for line in status_raw.splitlines():
    if not line:
        continue
    path_text = line[3:]
    if " -> " in path_text:
        path_text = path_text.split(" -> ", 1)[1]
    status_paths.append(Path(path_text))
    print(f"TASK034A_STATUS_PATH={path_text}")

def is_allowed_status_path(path: Path) -> bool:
    text = str(path).rstrip("/")
    if Path(text) in ALLOWED_PATHS:
        return True
    prefix = text + "/"
    return any(str(allowed).startswith(prefix) for allowed in ALLOWED_PATHS)

unexpected = [path for path in status_paths if not is_allowed_status_path(path)]
print(f"TASK034A_STATUS_PATH_COUNT={len(status_paths)}")
print(f"UNEXPECTED_TASK034A_STATUS_PATH_COUNT={len(unexpected)}")
for path in unexpected:
    fail(f"unexpected changed path: {path}")
if not unexpected:
    passed("changed paths are limited to Task-034a provider/contracts/docs/verifier/test/project scope")

for path in PRODUCT_FILES + [TEST_FILE, VERIFIER_FILE, Path("SkateTrack.xcodeproj/project.pbxproj")] + DOC_FILES:
    require_path(path)

for path in PRODUCT_FILES + [TEST_FILE, VERIFIER_FILE]:
    if (REPO / path).exists():
        check_header_and_lines(path)

required_tokens = {
    PRODUCT_FILES[0]: [
        "public enum WatchSensorProviderKind",
        "public enum WatchSensorProviderAvailabilityStatus",
        "public enum WatchSensorProviderUnavailableReason",
        "public struct WatchSensorProviderAvailability",
        "canProvideWatchOriginatedData",
        "public protocol WatchSensorProviding",
        "func availability",
        "func snapshot",
    ],
    PRODUCT_FILES[1]: [
        "public enum WatchSensorSampleKind",
        "public struct WatchSensorSample",
        "public struct WatchSensorProviderSnapshot",
        "sampleCount",
        "isUsable",
    ],
    PRODUCT_FILES[2]: [
        "public struct WatchSensorMockProvider",
        "WatchSensorProviding",
        "scriptedSamples",
        "maximumSampleCount",
    ],
    PRODUCT_FILES[3]: [
        "public struct WatchSensorDisabledProvider",
        "WatchSensorProviding",
        "providerDisabled",
        "samples: []",
    ],
    TEST_FILE: [
        "WatchSensorProviderAvailabilityTests",
        "testDisabledProviderReportsDisabledUnavailableState",
        "testMockProviderReportsAvailableAndLimitsScriptedSamples",
        "testMockProviderReturnsNoSamplesWhenAvailabilityIsUnavailable",
        "testSampleConfidenceIsClampedToProviderContractRange",
    ],
}
for path, tokens in required_tokens.items():
    text = read(path) if (REPO / path).exists() else ""
    for token in tokens:
        if token in text:
            passed(f"{path} contains token: {token}")
        else:
            fail(f"{path} missing token: {token}")

forbidden_patterns = re.compile(
    r"import\s+HealthKit|HKHealthStore|HKWorkout|HKLiveWorkoutBuilder|HKWorkoutSession|HKQuantitySample|HKSample|CoreData|NSManagedObject|PersistenceController|SessionRepository|\.xcdatamodel|fuse|fusion|SnowSegment|SnowRun|SnowDistanceBreakdown|SnowPrototype|SnowClassifier|SnowMode|SnowSport|SwiftUI|\bView\b|\bButton\b|NavigationStack|List\(|Text\(|RouteGeometry|map-match|snap-to-road|trustedMetric|trusted metric",
    re.IGNORECASE,
)
for path in PRODUCT_FILES:
    text = read(path) if (REPO / path).exists() else ""
    count = len(forbidden_patterns.findall(text))
    print(f"FORBIDDEN_TASK034A_PRODUCT_TOKEN_COUNT[{path}]={count}")
    if count == 0:
        passed(f"{path} contains no forbidden HealthKit/storage/fusion/UI/Snow/route tokens")
    else:
        fail(f"{path} contains forbidden tokens")

storage_pattern = re.compile(r"save|store|persist|insert|repository|CoreData|NSManagedObject", re.IGNORECASE)
storage_count = 0
for path in PRODUCT_FILES:
    text = read(path) if (REPO / path).exists() else ""
    storage_count += len(storage_pattern.findall(text))
print(f"WATCH_SAMPLE_STORAGE_TOKEN_COUNT={storage_count}")
if storage_count == 0:
    passed("Task-034a product files do not start watch sample storage")
else:
    fail("Task-034a product files contain storage-like tokens")

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

changed = run(["git", "diff", "--name-only", BASE_HEAD + "..HEAD"]).stdout.splitlines()
status_names = {str(p) for p in status_paths}
changed_or_status = set(changed) | status_names
entitlements = [p for p in changed_or_status if p.endswith(".entitlements")]
schema = [p for p in changed_or_status if any(s in p for s in [".xcdatamodel", ".xcdatamodeld", "PersistenceController", "SessionRepository", "SessionEntityMapper"])]
ui_scope = [p for p in changed_or_status if p.startswith(("iOS/Features", "watchOS/", "macOS/"))]
snow = [p for p in changed_or_status if "Snow" in p]
print(f"ENTITLEMENTS_CHANGED_COUNT={len(entitlements)}")
print(f"SCHEMA_CHANGED_COUNT={len(schema)}")
print(f"UI_SCOPE_CHANGED_COUNT={len(ui_scope)}")
print(f"SNOW_CHANGED_COUNT={len(snow)}")
if not entitlements and not schema and not ui_scope and not snow:
    passed("no entitlement, schema, platform UI, or Snow paths changed")
else:
    fail("forbidden changed path scope detected")

watch_ui = run(["git", "grep", "-n", "SwiftUI\\|View\\|Button\\|NavigationStack\\|List\\|Text(", "--", "Shared/WatchSensors"]).stdout
watch_ui_count = len(watch_ui.splitlines()) if watch_ui else 0
print(f"WATCH_UI_SWIFTUI_COUNT={watch_ui_count}")
if watch_ui_count == 0:
    passed("no Watch UI or SwiftUI implementation in Task-034a provider files")
else:
    fail("Watch UI / SwiftUI tokens found")

health = run(["git", "grep", "-n", "HealthKit\\|HKHealthStore\\|HKWorkout\\|HKLiveWorkoutBuilder\\|HKWorkoutSession\\|HKQuantitySample\\|HKSample", "--", "Shared/WatchSensors", "Tests/iOSTests/WatchSensorProviderAvailabilityTests.swift"]).stdout
health_count = len(health.splitlines()) if health else 0
print(f"PRODUCTION_HEALTHKIT_API_COUNT={health_count}")
if health_count == 0:
    passed("Task-034a provider/test files do not use production HealthKit APIs")
else:
    fail("production HealthKit API tokens found")

for path in DOC_FILES:
    text = read(path) if (REPO / path).exists() else ""
    for token in [
        "TASK034A_WATCH_SENSOR_PROVIDER_PROTOCOLS_RESULT=PASSED",
        "WATCH_SENSOR_PROVIDER_PROTOCOLS_IMPLEMENTED=YES",
        "MOCK_SENSOR_PROVIDER_PRESENT=YES",
        "DISABLED_SENSOR_PROVIDER_PRESENT=YES",
        "PROVIDER_AVAILABILITY_TESTS=YES",
        "PRODUCTION_HEALTHKIT_API_USED=NO",
        "WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO",
        "METRIC_FUSION_IMPLEMENTED=NO",
        "WATCH_UI_IMPLEMENTED=NO",
        "NEXT_TASK=Task-034b",
    ]:
        if token in text:
            passed(f"{path} contains token: {token}")
        else:
            fail(f"{path} missing token: {token}")

print("===== Summary =====")
print("TASK034A_WATCH_SENSOR_PROVIDER_PROTOCOLS_RESULT=PASSED" if failures == 0 else "TASK034A_WATCH_SENSOR_PROVIDER_PROTOCOLS_RESULT=FAILED")
print("WATCH_SENSOR_PROVIDER_PROTOCOLS_IMPLEMENTED=YES" if failures == 0 else "WATCH_SENSOR_PROVIDER_PROTOCOLS_IMPLEMENTED=UNKNOWN")
print("MOCK_SENSOR_PROVIDER_PRESENT=YES" if failures == 0 else "MOCK_SENSOR_PROVIDER_PRESENT=UNKNOWN")
print("DISABLED_SENSOR_PROVIDER_PRESENT=YES" if failures == 0 else "DISABLED_SENSOR_PROVIDER_PRESENT=UNKNOWN")
print("PROVIDER_AVAILABILITY_TESTS=YES" if failures == 0 else "PROVIDER_AVAILABILITY_TESTS=UNKNOWN")
print("PRODUCTION_HEALTHKIT_API_USED=NO")
print("WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO")
print("METRIC_FUSION_IMPLEMENTED=NO")
print("WATCH_UI_IMPLEMENTED=NO")
print("NEXT_TASK=Task-034b")
print(f"WARNING_COUNT={warnings}")
print(f"FAILURE_COUNT={failures}")
print("VERIFY_TASK034A_WATCH_SENSOR_PROVIDER_PROTOCOLS_RESULT=PASSED" if failures == 0 else "VERIFY_TASK034A_WATCH_SENSOR_PROVIDER_PROTOCOLS_RESULT=FAILED")
sys.exit(0 if failures == 0 else 1)
