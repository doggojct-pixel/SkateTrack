#!/usr/bin/env python3
# [協作區] scripts/verify_task034_sensor_provider.py

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ALLOWED_BRANCHES = {"task-034-sensor-provider-boundary", "develop"}
TASK034B_HEAD = "37152a736e93062dda4fa1584ebfaceda8cd0add"

REQUIRED_PROVIDER_FILES = [
    "Shared/WatchSensors/WatchSensorProviderProtocols.swift",
    "Shared/WatchSensors/WatchSensorSampleModels.swift",
    "Shared/WatchSensors/WatchSensorMockProvider.swift",
    "Shared/WatchSensors/WatchSensorDisabledProvider.swift",
    "Shared/WatchSensors/WatchHealthKitBoundary.swift",
    "Shared/WatchSensors/WatchHealthKitDisabledProvider.swift",
    "Shared/WatchSensors/WatchHealthKitCopy.swift",
]

REQUIRED_TEST_FILES = [
    "Tests/iOSTests/WatchSensorProviderAvailabilityTests.swift",
    "Tests/iOSTests/WatchHealthKitDisabledBoundaryTests.swift",
]

REQUIRED_SCRIPT_FILES = [
    "scripts/verify_task034a_watch_sensor_provider_protocols.py",
    "scripts/verify_task034b_disabled_healthkit_boundary.py",
    "scripts/verify_task034_sensor_provider.py",
]

DOC_FILES = [
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

ALLOWED_STATUS_PATHS = set(DOC_FILES + ["scripts/verify_task034_sensor_provider.py"])

REQUIRED_DOC_TOKENS = [
    "TASK034_SENSOR_PROVIDER_BOUNDARY_CLOSED=YES",
    "VERIFY_TASK034_SENSOR_PROVIDER_RESULT=PASSED",
    "SENSOR_PROVIDER_TESTS_EXIT=0",
    "KNOWN_LIMITATIONS_UPDATED=YES",
    "PRODUCTION_HEALTHKIT_API_USED=NO",
    "HEALTHKIT_ENTITLEMENT_CHANGED=NO",
    "RESTRICTED_CLAIM_WORDING_PRESENT=NO",
    "BACKGROUND_COLLECTION_ENABLED=NO",
    "WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO",
    "METRIC_FUSION_IMPLEMENTED=NO",
    "WATCH_UI_IMPLEMENTED=NO",
    "SNOW_PRODUCTION_IMPLEMENTED=NO",
    "SCHEMA_CORE_DATA_PACKAGE_MUTATION=NO",
    "ROUTE_GEOMETRY_MUTATION=NO",
    "TRUSTED_METRIC_MUTATION=NO",
    "NEXT_TASK=Task-035a",
]

PRODUCTION_HEALTHKIT_RE = re.compile(
    r"\b(import\s+HealthKit|HKHealthStore|HKWorkout|HKLiveWorkoutBuilder|"
    r"HKWorkoutSession|HKQuantitySample|HKSample|HKObserverQuery|"
    r"enableBackgroundDelivery)\b"
)

RESTRICTED_COPY_PHRASES = [
    "health monitoring",
    "medical advice",
    "diagnosis",
    "heart rate",
    "heart-rate",
    "background health collection",
]

FORBIDDEN_PRODUCT_RE = re.compile(
    r"\b(CoreData|NSManagedObject|PersistenceController|SessionRepository|"
    r"SessionEntityMapper|WatchSampleStore|SampleStore|MetricFusion|"
    r"fuseMetrics|trustedMetric|RouteGeometry|SnowSegment|SnowRun|"
    r"SnowClassifier|SnowPrototype|SwiftUI|View|Button|NavigationStack)\b"
)


failure_count = 0
warning_count = 0


def run(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=str(cwd),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def fail(message: str) -> None:
    global failure_count
    failure_count += 1
    print(f"FAIL: {message}")


def warn(message: str) -> None:
    global warning_count
    warning_count += 1
    print(f"WARN: {message}")


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def status_paths(repo: Path) -> list[str]:
    result = run(["git", "status", "--porcelain=v1"], repo)
    paths: list[str] = []
    for line in result.stdout.splitlines():
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path)
    return paths


def check_repo(repo: Path) -> None:
    if (repo / ".git").exists():
        pass_msg("repo path contains .git")
    else:
        fail("repo path does not contain .git")

    branch = run(["git", "branch", "--show-current"], repo).stdout.strip()
    head = run(["git", "rev-parse", "HEAD"], repo).stdout.strip()
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD_FULL={head}")

    if branch in ALLOWED_BRANCHES:
        pass_msg("current branch is valid for Task-034c verification")
    else:
        allowed = ", ".join(sorted(ALLOWED_BRANCHES))
        fail(f"current branch is {branch}, expected one of: {allowed}")

    ancestor = run(["git", "merge-base", "--is-ancestor", TASK034B_HEAD, "HEAD"], repo)
    print(f"TASK034B_HEAD_REACHABLE_EXIT={ancestor.returncode}")
    if ancestor.returncode == 0:
        print("TASK034B_HEAD_REACHABLE=YES")
        pass_msg("Task-034b pushed head is reachable from HEAD")
    else:
        print("TASK034B_HEAD_REACHABLE=NO")
        fail("Task-034b pushed head is not reachable from HEAD")

    paths = status_paths(repo)
    unexpected = [path for path in paths if path not in ALLOWED_STATUS_PATHS]
    print(f"TASK034C_STATUS_PATH_COUNT={len(paths)}")
    print(f"UNEXPECTED_TASK034C_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        print(f"UNEXPECTED_TASK034C_STATUS_PATH={path}")
    if unexpected:
        fail("working tree contains paths outside Task-034c docs/verifier scope")
    else:
        pass_msg("changed paths are limited to Task-034c docs/verifier scope")


def check_required_files(repo: Path) -> None:
    for rel in REQUIRED_PROVIDER_FILES + REQUIRED_TEST_FILES + REQUIRED_SCRIPT_FILES + DOC_FILES:
        if (repo / rel).exists():
            pass_msg(f"required path exists: {rel}")
        else:
            fail(f"required path missing: {rel}")


def check_headers_and_lines(repo: Path) -> None:
    checked = REQUIRED_PROVIDER_FILES + REQUIRED_TEST_FILES + ["scripts/verify_task034_sensor_provider.py"]
    for rel in checked:
        path = repo / rel
        if not path.exists():
            continue
        text = read_text(path)
        lines = text.splitlines()
        first = lines[0] if lines else ""
        print(f"FIRST_LINE[{rel}]={first}")
        print(f"LINE_COUNT[{rel}]={len(lines)}")
        if rel.endswith(".swift"):
            if first.startswith("// [協作區]") or first.startswith("// [自主區]"):
                pass_msg(f"{rel} has valid collaboration header")
            else:
                fail(f"{rel} is missing collaboration header")
        if len(lines) <= 500:
            pass_msg(f"{rel} stays under 500 lines")
        else:
            fail(f"{rel} exceeds 500 lines")


def check_project_membership(repo: Path) -> None:
    project = repo / "SkateTrack.xcodeproj/project.pbxproj"
    if not project.exists():
        fail("project.pbxproj missing")
        return
    text = read_text(project)
    for rel in REQUIRED_PROVIDER_FILES + REQUIRED_TEST_FILES:
        name = Path(rel).name
        count = text.count(name)
        print(f"PROJECT_TOKEN_COUNT[{name}]={count}")
        if count > 0:
            pass_msg(f"{name} has project references")
        else:
            fail(f"{name} has no project reference")


def check_provider_contracts(repo: Path) -> None:
    required_tokens_by_file = {
        "Shared/WatchSensors/WatchSensorProviderProtocols.swift": [
            "public enum WatchSensorProviderKind",
            "public enum WatchSensorProviderAvailabilityStatus",
            "public enum WatchSensorProviderUnavailableReason",
            "public struct WatchSensorProviderAvailability",
            "canProvideWatchOriginatedData",
            "public protocol WatchSensorProviding",
            "func availability",
            "func snapshot",
        ],
        "Shared/WatchSensors/WatchSensorSampleModels.swift": [
            "public enum WatchSensorSampleKind",
            "public struct WatchSensorSample",
            "public struct WatchSensorProviderSnapshot",
            "sampleCount",
            "isUsable",
        ],
        "Shared/WatchSensors/WatchSensorMockProvider.swift": [
            "public struct WatchSensorMockProvider",
            "WatchSensorProviding",
            "scriptedSamples",
            "maximumSampleCount",
        ],
        "Shared/WatchSensors/WatchSensorDisabledProvider.swift": [
            "public struct WatchSensorDisabledProvider",
            "WatchSensorProviding",
            "providerDisabled",
            "samples: []",
        ],
        "Shared/WatchSensors/WatchHealthKitBoundary.swift": [
            "public enum WatchHealthKitBoundaryState",
            "public enum WatchHealthKitBoundaryReason",
            "public struct WatchHealthKitBoundaryAvailability",
            "public protocol WatchHealthKitBoundaryProviding",
            "canRequestProductionAccess",
            "isProductionAccessEnabled",
        ],
        "Shared/WatchSensors/WatchHealthKitDisabledProvider.swift": [
            "public struct WatchHealthKitDisabledProvider",
            "WatchHealthKitBoundaryProviding",
            "WatchSensorProviding",
            "isProductionAccessEnabled: Bool = false",
            "WatchSensorProviderAvailability.disabled",
            "samples: []",
        ],
        "Shared/WatchSensors/WatchHealthKitCopy.swift": [
            "public enum WatchHealthKitCopy",
            "disabledTitle",
            "disabledExplanation",
            "capabilityNotice",
            "nonClinicalNotice",
        ],
    }
    for rel, tokens in required_tokens_by_file.items():
        text = read_text(repo / rel) if (repo / rel).exists() else ""
        for token in tokens:
            if token in text:
                pass_msg(f"{rel} contains token: {token}")
            else:
                fail(f"{rel} missing token: {token}")


def check_tests_present(repo: Path) -> None:
    required_test_tokens = {
        "Tests/iOSTests/WatchSensorProviderAvailabilityTests.swift": [
            "WatchSensorProviderAvailabilityTests",
            "testDisabledProviderReportsDisabledUnavailableState",
            "testMockProviderReportsAvailableAndLimitsScriptedSamples",
            "testMockProviderReturnsNoSamplesWhenAvailabilityIsUnavailable",
            "testSampleConfidenceIsClampedToProviderContractRange",
        ],
        "Tests/iOSTests/WatchHealthKitDisabledBoundaryTests.swift": [
            "WatchHealthKitDisabledBoundaryTests",
            "testDisabledBoundaryReportsProductionAccessOff",
            "testDisabledBoundaryReturnsNoWatchSensorSamples",
            "testDisabledCopyAvoidsRestrictedClaims",
        ],
    }
    for rel, tokens in required_test_tokens.items():
        text = read_text(repo / rel) if (repo / rel).exists() else ""
        for token in tokens:
            if token in text:
                pass_msg(f"{rel} contains test token: {token}")
            else:
                fail(f"{rel} missing test token: {token}")


def check_forbidden_scope(repo: Path) -> None:
    product_text = ""
    for rel in REQUIRED_PROVIDER_FILES + REQUIRED_TEST_FILES:
        path = repo / rel
        if path.exists():
            product_text += "\n" + read_text(path)

    healthkit_matches = PRODUCTION_HEALTHKIT_RE.findall(product_text)
    print(f"PRODUCTION_HEALTHKIT_API_TOKEN_COUNT={len(healthkit_matches)}")
    if healthkit_matches:
        fail("production HealthKit API tokens found in Task-034 product/test files")
    else:
        pass_msg("no production HealthKit API tokens in Task-034 product/test files")

    project_text = read_text(repo / "SkateTrack.xcodeproj/project.pbxproj")
    entitlement_count = project_text.count("com.apple.developer.healthkit")
    print(f"HEALTHKIT_ENTITLEMENT_TOKEN_COUNT={entitlement_count}")
    if entitlement_count == 0:
        pass_msg("HealthKit entitlement/capability remains absent")
    else:
        fail("HealthKit entitlement/capability token found")

    copy_text = read_text(repo / "Shared/WatchSensors/WatchHealthKitCopy.swift").lower()
    claim_count = sum(copy_text.count(phrase) for phrase in RESTRICTED_COPY_PHRASES)
    print(f"RESTRICTED_CLAIM_WORDING_COUNT={claim_count}")
    if claim_count == 0:
        pass_msg("restricted claim wording is absent from disabled HealthKit copy")
    else:
        fail("restricted claim wording found in disabled HealthKit copy")

    forbidden_matches = FORBIDDEN_PRODUCT_RE.findall(product_text)
    print(f"FORBIDDEN_PRODUCT_SCOPE_TOKEN_COUNT={len(forbidden_matches)}")
    if forbidden_matches:
        fail("forbidden storage/fusion/UI/Snow/schema/route tokens found in Task-034 files")
    else:
        pass_msg("Task-034 files avoid storage, fusion, UI, Snow, schema, and route mutation scope")


def check_docs(repo: Path) -> None:
    known_limitations_ok = False
    for rel in DOC_FILES:
        path = repo / rel
        text = read_text(path) if path.exists() else ""
        for token in REQUIRED_DOC_TOKENS:
            if token in text:
                pass_msg(f"{rel} contains token: {token}")
            else:
                fail(f"{rel} missing token: {token}")
        if rel == "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md" and "TASK034C_PRE_ADP_LIMITATIONS_START" in text:
            known_limitations_ok = True

    if known_limitations_ok:
        print("KNOWN_LIMITATIONS_UPDATED=YES")
        pass_msg("Task-034c known limitations block is present")
    else:
        print("KNOWN_LIMITATIONS_UPDATED=NO")
        fail("Task-034c known limitations block missing")


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    print("===== Task-034c Sensor Provider aggregate verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-034c — Sensor Provider Tests + Docs")
    print(
        "Not implementing: production HealthKit API, HealthKit entitlement/capability, "
        "health monitoring claim, medical advice wording, diagnosis wording, heart-rate promise, "
        "background health collection, Watch sample storage, metric fusion, Watch UI, "
        "Snow production, schema/Core Data/package mutation, route geometry mutation, "
        "trusted metric mutation, merge develop"
    )
    print(f"REPO={repo}")

    check_repo(repo)
    check_required_files(repo)
    check_headers_and_lines(repo)
    check_project_membership(repo)
    check_provider_contracts(repo)
    check_tests_present(repo)
    check_forbidden_scope(repo)
    check_docs(repo)

    print("===== Summary =====")
    print("TASK034_SENSOR_PROVIDER_BOUNDARY_CLOSED=YES" if failure_count == 0 else "TASK034_SENSOR_PROVIDER_BOUNDARY_CLOSED=NO")
    print("SENSOR_PROVIDER_TESTS_EXPECTED=WatchSensorProviderAvailabilityTests,WatchHealthKitDisabledBoundaryTests")
    print("PRODUCTION_HEALTHKIT_API_USED=NO" if failure_count == 0 else "PRODUCTION_HEALTHKIT_API_USED=UNKNOWN")
    print("HEALTHKIT_ENTITLEMENT_CHANGED=NO" if failure_count == 0 else "HEALTHKIT_ENTITLEMENT_CHANGED=UNKNOWN")
    print("RESTRICTED_CLAIM_WORDING_PRESENT=NO" if failure_count == 0 else "RESTRICTED_CLAIM_WORDING_PRESENT=UNKNOWN")
    print("BACKGROUND_COLLECTION_ENABLED=NO" if failure_count == 0 else "BACKGROUND_COLLECTION_ENABLED=UNKNOWN")
    print("WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO" if failure_count == 0 else "WATCH_SAMPLE_STORAGE_IMPLEMENTED=UNKNOWN")
    print("METRIC_FUSION_IMPLEMENTED=NO" if failure_count == 0 else "METRIC_FUSION_IMPLEMENTED=UNKNOWN")
    print("WATCH_UI_IMPLEMENTED=NO" if failure_count == 0 else "WATCH_UI_IMPLEMENTED=UNKNOWN")
    print("SNOW_PRODUCTION_IMPLEMENTED=NO" if failure_count == 0 else "SNOW_PRODUCTION_IMPLEMENTED=UNKNOWN")
    print("SCHEMA_CORE_DATA_PACKAGE_MUTATION=NO" if failure_count == 0 else "SCHEMA_CORE_DATA_PACKAGE_MUTATION=UNKNOWN")
    print("ROUTE_GEOMETRY_MUTATION=NO" if failure_count == 0 else "ROUTE_GEOMETRY_MUTATION=UNKNOWN")
    print("TRUSTED_METRIC_MUTATION=NO" if failure_count == 0 else "TRUSTED_METRIC_MUTATION=UNKNOWN")
    print("NEXT_TASK=Task-035a" if failure_count == 0 else "NEXT_TASK=BLOCKED")
    print(f"WARNING_COUNT={warning_count}")
    print(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0:
        print("VERIFY_TASK034_SENSOR_PROVIDER_RESULT=PASSED")
        return 0
    print("VERIFY_TASK034_SENSOR_PROVIDER_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
