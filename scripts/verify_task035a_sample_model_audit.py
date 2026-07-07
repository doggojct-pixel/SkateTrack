#!/usr/bin/env python3
"""Task-035a verifier: Watch sample model audit and compatibility plan."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


EXPECTED_BRANCH = "task-035-watch-sample-foundation"
EXPECTED_BASE_HEAD = "9cc55651db592339ca12b13dd05333d1e8c26599"

ALLOWED_CHANGED_PATHS = {
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "scripts/verify_task035a_sample_model_audit.py",
}

REQUIRED_AUDIT_PATHS = [
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SessionData.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Persistence/MotionSampleFileStore.swift",
    "Shared/Persistence/SessionRepository.swift",
    "Shared/Persistence/SessionEntityMapper.swift",
    "Shared/Persistence/PersistenceController.swift",
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents",
    "Shared/Export/SkateTrackPackageReader.swift",
    "Shared/Export/SkateTrackPackageWriter.swift",
    "Shared/WatchSensors/WatchSensorSampleModels.swift",
    "Shared/WatchSensors/WatchSensorProviderProtocols.swift",
    "iOS/Core/Import/SkateTrackPackageImportCoordinator.swift",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

CORE_DOC_TOKENS = [
    "VERIFY_TASK035A_SAMPLE_MODEL_AUDIT_RESULT=PASSED",
    "SCHEMA_CHANGE_REQUIRED=YES",
    "COMPATIBILITY_PLAN_PRESENT_IF_REQUIRED=YES",
    "SCHEMA_CHANGE_MINIPLAN_REVIEWED_IF_REQUIRED=YES",
    "TASK035B_ALLOWED_TO_START=YES",
    "WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO",
    "MODEL_SCHEMA_MUTATION_IMPLEMENTED=NO",
    "CORE_DATA_SCHEMA_MUTATION_IMPLEMENTED=NO",
    "PACKAGE_SCHEMA_MUTATION_IMPLEMENTED=NO",
    "PACKAGE_FORMAT_MUTATION_IMPLEMENTED=NO",
    "NEXT_TASK=Task-035b",
]

DOC_MARKERS = {
    "docs/process/PHASE_1B_AGENT_STATE.md": "TASK035A_SAMPLE_MODEL_AUDIT_STATE_START",
    "docs/history/DEV_LOG.md": "TASK035A_SAMPLE_MODEL_AUDIT_DEVLOG_START",
    "docs/reference/FILE_STRUCTURE.md": "TASK035A_SAMPLE_MODEL_AUDIT_FILE_STRUCTURE_START",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": "TASK035A_PRE_ADP_LIMITATIONS_START",
}

PLAN_DETAIL_TOKENS = [
    "TASK030D_IMPORT_COMPATIBILITY_REVIEWED=YES",
    "TASK030E_VIEWER_COMPATIBILITY_REVIEWED=YES",
    "ROLLBACK_RESTORE_SAFETY_REVIEWED=YES",
    "PRODUCTION_HEALTHKIT_API_USED=NO",
    "HEALTHKIT_ENTITLEMENT_CHANGED=NO",
    "METRIC_FUSION_IMPLEMENTED=NO",
    "WATCH_UI_IMPLEMENTED=NO",
    "SNOW_PRODUCTION_IMPLEMENTED=NO",
    "ROUTE_GEOMETRY_MUTATION=NO",
    "TRUSTED_METRIC_MUTATION=NO",
]

FORBIDDEN_CHANGED_PREFIXES = (
    "Shared/Models/",
    "Shared/Persistence/",
    "Shared/Export/",
    "Shared/WatchSensors/",
    "Shared/WatchBridge/",
    "iOS/",
    "macOS/",
    "Tests/",
    "SkateTrack.xcodeproj/",
)

FORBIDDEN_PRODUCT_TOKENS = [
    "HKHealthStore",
    "HKWorkout",
    "HKLiveWorkoutBuilder",
    "HKWorkoutSession",
    "HKQuantitySample",
    "HKSample",
    "enableBackgroundDelivery",
    "com.apple.developer.healthkit",
]


failures: list[str] = []


def run(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, text=True, capture_output=True, check=False)


def rel(path: Path, repo: Path) -> str:
    return path.relative_to(repo).as_posix()


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    failures.append(message)


def require_file(repo: Path, path: str) -> str:
    full_path = repo / path
    if not full_path.exists():
        fail(f"required path missing: {path}")
        return ""
    pass_msg(f"required path exists: {path}")
    return read(full_path)


def require_token(name: str, text: str, token: str) -> None:
    if token in text:
        pass_msg(f"{name} contains token: {token}")
    else:
        fail(f"{name} missing token: {token}")


def changed_paths(repo: Path) -> set[str]:
    diff = run(["git", "diff", "--name-only", "HEAD"], repo)
    untracked = run(["git", "ls-files", "--others", "--exclude-standard"], repo)
    paths = set()
    if diff.returncode == 0:
        paths.update(line.strip() for line in diff.stdout.splitlines() if line.strip())
    if untracked.returncode == 0:
        paths.update(line.strip() for line in untracked.stdout.splitlines() if line.strip())
    return {path for path in paths if "__pycache__/" not in path and not path.endswith(".pyc")}


def verify_git_context(repo: Path) -> None:
    if not (repo / ".git").exists():
        fail("repo path does not contain .git")
        return
    pass_msg("repo path contains .git")

    branch = run(["git", "branch", "--show-current"], repo).stdout.strip()
    print(f"CURRENT_BRANCH={branch}")
    if branch == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-035a")
    else:
        fail(f"current branch is {branch}, expected {EXPECTED_BRANCH}")

    merge_base = run(["git", "merge-base", "--is-ancestor", EXPECTED_BASE_HEAD, "HEAD"], repo)
    print(f"TASK035A_BASE_HEAD={EXPECTED_BASE_HEAD}")
    if merge_base.returncode == 0:
        pass_msg("Task-035a expected base head is reachable from HEAD")
    else:
        fail("Task-035a expected base head is not reachable from HEAD")


def verify_path_guard(repo: Path) -> None:
    paths = changed_paths(repo)
    unexpected = sorted(paths - ALLOWED_CHANGED_PATHS)
    print(f"TASK035A_CHANGED_PATH_COUNT={len(paths)}")
    print(f"TASK035A_UNEXPECTED_CHANGED_PATH_COUNT={len(unexpected)}")
    if unexpected:
        for path in unexpected:
            print(f"UNEXPECTED_CHANGED_PATH={path}")
        fail("changed paths exceed Task-035a docs/verifier scope")
    else:
        pass_msg("changed paths are limited to Task-035a docs/verifier scope")

    forbidden = sorted(
        path
        for path in paths
        if path not in ALLOWED_CHANGED_PATHS and path.startswith(FORBIDDEN_CHANGED_PREFIXES)
    )
    print(f"TASK035A_FORBIDDEN_PRODUCT_PATH_CHANGE_COUNT={len(forbidden)}")
    if forbidden:
        for path in forbidden:
            print(f"FORBIDDEN_PRODUCT_PATH_CHANGE={path}")
        fail("Task-035a must not modify product/model/schema/package/test paths")
    else:
        pass_msg("Task-035a product/model/schema/package/test paths remain untouched")


def verify_audit_sources(repo: Path) -> None:
    texts = {path: require_file(repo, path) for path in REQUIRED_AUDIT_PATHS}

    motion = texts["Shared/Models/MotionSample.swift"]
    for token in [
        "enum MotionSampleSource",
        "case timerFusion",
        "case locationFix",
        "case debugSimulated",
        "let sampleSource: MotionSampleSource?",
    ]:
        require_token("MotionSample.swift", motion, token)
    if "case watch" in motion or "watchOrigin" in motion:
        fail("MotionSample already contains Watch-origin sample source tokens; audit assumptions changed")
    else:
        pass_msg("MotionSample has no Watch-origin durable source case")

    watch_sample = texts["Shared/WatchSensors/WatchSensorSampleModels.swift"]
    for token in [
        "public struct WatchSensorSample",
        "public let kind: WatchSensorSampleKind",
        "public let unitSymbol: String",
        "public let providerKind: WatchSensorProviderKind",
        "public let confidence: Double",
    ]:
        require_token("WatchSensorSampleModels.swift", watch_sample, token)

    session = texts["Shared/Models/SessionData.swift"]
    require_token("SessionData.swift", session, "let motionSamples: [MotionSample]")
    if "watchSensorSamples" in session or "WatchSensorSample" in session:
        fail("SessionData already stores Watch sensor samples; audit assumptions changed")
    else:
        pass_msg("SessionData does not store Watch sensor samples")

    manifest = texts["Shared/Models/SkateTrackPackageManifest.swift"]
    require_token("SkateTrackPackageManifest.swift", manifest, "static let currentSchemaVersion = 1")
    require_token("SkateTrackPackageManifest.swift", manifest, "unsupportedSchemaVersion")

    payload = texts["Shared/Models/SkateTrackPackagePayload.swift"]
    require_token("SkateTrackPackagePayload.swift", payload, "let motionSamples: [MotionSample]")
    if "watchSensorSamples" in payload or "WatchSensorSample" in payload:
        fail("Package payload already stores Watch sensor samples; audit assumptions changed")
    else:
        pass_msg("Package payload does not store Watch sensor samples")

    importer = texts["iOS/Core/Import/SkateTrackPackageImportCoordinator.swift"]
    for token in [
        "sessionForImport",
        "packageSession.motionSamples",
        "schema / route / trusted metrics",
    ]:
        require_token("SkateTrackPackageImportCoordinator.swift", importer, token)

    core_data = texts["Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents"]
    require_token("SkateTrackDataModel contents", core_data, 'attribute name="sampleFileName"')
    if "watchSample" in core_data or "WatchSample" in core_data:
        fail("Core Data model already includes Watch sample storage; audit assumptions changed")
    else:
        pass_msg("Core Data model has no Watch sample storage")

    persistence = texts["Shared/Persistence/MotionSampleFileStore.swift"]
    require_token("MotionSampleFileStore.swift", persistence, "func save(_ samples: [MotionSample]")
    require_token("MotionSampleFileStore.swift", persistence, "func load(fileName: String?) throws -> [MotionSample]")


def verify_docs(repo: Path) -> None:
    docs = [
        "docs/process/PHASE_1B_AGENT_STATE.md",
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]
    for doc in docs:
        text = require_file(repo, doc)
        require_token(doc, text, DOC_MARKERS[doc])
        for token in CORE_DOC_TOKENS:
            require_token(doc, text, token)
    for doc in [
        "docs/process/PHASE_1B_AGENT_STATE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]:
        text = require_file(repo, doc)
        for token in PLAN_DETAIL_TOKENS:
            require_token(doc, text, token)


def verify_forbidden_scope(repo: Path) -> None:
    changed = changed_paths(repo)
    source_changes = [
        path for path in changed
        if path.startswith(("Shared/", "iOS/", "macOS/", "Tests/", "SkateTrack.xcodeproj/"))
    ]
    print(f"TASK035A_SOURCE_CHANGE_COUNT={len(source_changes)}")
    if source_changes:
        for path in sorted(source_changes):
            print(f"TASK035A_SOURCE_CHANGE={path}")
        fail("Task-035a must not change source, tests, project, model, or package implementation files")
    else:
        pass_msg("Task-035a has no source/test/project implementation changes")

    grep_paths = [
        "Shared/Models",
        "Shared/Persistence",
        "Shared/Export",
        "Shared/WatchSensors",
        "Shared/WatchBridge",
        "iOS",
        "macOS",
        "Tests",
    ]
    matches: list[str] = []
    for token in FORBIDDEN_PRODUCT_TOKENS:
        result = run(["git", "grep", "-n", token, "--", *grep_paths], repo)
        if result.returncode == 0:
            for line in result.stdout.splitlines():
                if "Shared/WatchSensors/WatchHealthKit" in line:
                    continue
                matches.append(line)
    print(f"TASK035A_FORBIDDEN_HEALTHKIT_PRODUCT_TOKEN_COUNT={len(matches)}")
    if matches:
        for line in matches:
            print(line)
        fail("forbidden HealthKit production tokens found outside disabled boundary allowance")
    else:
        pass_msg("no forbidden HealthKit production tokens outside disabled boundary allowance")


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    print("===== VERIFY_TASK035A_SAMPLE_MODEL_AUDIT =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-035a - Watch Sample Model Extension Audit")
    print("Not implementing: Watch sample ingestion, schema/Core Data/package mutation, metric fusion, Watch UI, Snow production")
    print(f"REPO={repo}")

    verify_git_context(repo)
    verify_path_guard(repo)
    verify_audit_sources(repo)
    verify_docs(repo)
    verify_forbidden_scope(repo)

    if failures:
        print("VERIFY_TASK035A_SAMPLE_MODEL_AUDIT_RESULT=FAILED")
        print("SCHEMA_CHANGE_REQUIRED=YES")
        print("COMPATIBILITY_PLAN_PRESENT_IF_REQUIRED=CHECK_FAILED")
        print("SCHEMA_CHANGE_MINIPLAN_REVIEWED_IF_REQUIRED=CHECK_FAILED")
        print("TASK035B_ALLOWED_TO_START=NO")
        print(f"FAILURE_COUNT={len(failures)}")
        return 1

    print("VERIFY_TASK035A_SAMPLE_MODEL_AUDIT_RESULT=PASSED")
    print("SCHEMA_CHANGE_REQUIRED=YES")
    print("COMPATIBILITY_PLAN_PRESENT_IF_REQUIRED=YES")
    print("SCHEMA_CHANGE_MINIPLAN_REVIEWED_IF_REQUIRED=YES")
    print("TASK035B_ALLOWED_TO_START=YES")
    print("WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO")
    print("MODEL_SCHEMA_MUTATION_IMPLEMENTED=NO")
    print("CORE_DATA_SCHEMA_MUTATION_IMPLEMENTED=NO")
    print("PACKAGE_SCHEMA_MUTATION_IMPLEMENTED=NO")
    print("PACKAGE_FORMAT_MUTATION_IMPLEMENTED=NO")
    print("FAILURE_COUNT=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
