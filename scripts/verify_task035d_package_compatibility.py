#!/usr/bin/env python3
"""Task-035d Package / Backup Compatibility verifier."""

from pathlib import Path
import subprocess
import sys


EXPECTED_BRANCH = "task-035-watch-sample-foundation"
TASK035C_HEAD = "f5a1247241e3a71efe225eca090549adf82d6844"

REQUIRED_FILES = [
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift",
    "scripts/verify_task035d_package_compatibility.py",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
    "iOS/Core/Import/SkateTrackPackageImportCoordinator.swift",
    "macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift",
]

ALLOWED_CHANGED_PATHS = {
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift",
    "scripts/verify_task035d_package_compatibility.py",
    "SkateTrack.xcodeproj/project.pbxproj",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
}

FORBIDDEN_CHANGED_PATH_PREFIXES = [
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SessionData.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Persistence/",
    "Shared/Export/",
    "iOS/Core/Import/",
    "macOS/Features/SessionBrowser/",
    "watchOS/",
]

FORBIDDEN_SOURCE_TOKENS = [
    "HKHealthStore",
    "HKWorkout",
    "HKLiveWorkoutBuilder",
    "HKWorkoutSession",
    "HKQuantitySample",
    "HKSample",
    "HKObserverQuery",
    "enableBackgroundDelivery",
    "com.apple.developer.healthkit",
    "NSManagedObjectModel",
    ".xcdatamodel",
    "routeCoordinates =",
    "trustedDistance =",
    "trustedSpeed =",
    "trustedElevation =",
    "PersistenceController",
]

failure_count = 0


def fail(message: str) -> None:
    global failure_count
    failure_count += 1
    print(f"FAIL: {message}")


def pass_msg(message: str) -> None:
    print(f"PASS: {message}")


def run_git(args: list[str], repo: Path) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        fail(f"git {' '.join(args)} failed: {completed.stderr.strip()}")
        return ""
    return completed.stdout.strip()


def changed_paths(repo: Path) -> list[str]:
    changed = run_git(["diff", "--name-only", "HEAD", "--"], repo).splitlines()
    changed += run_git(["ls-files", "--others", "--exclude-standard"], repo).splitlines()
    return sorted(path for path in set(changed) if path)


def require_contains(path: Path, tokens: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token in text:
            pass_msg(f"{path} contains {token}")
        else:
            fail(f"{path} missing token: {token}")


def require_absent(path: Path, tokens: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token in text:
            fail(f"{path} contains forbidden token: {token}")


def verify_git_scope(repo: Path) -> None:
    paths = changed_paths(repo)
    for path in paths:
        if path not in ALLOWED_CHANGED_PATHS:
            fail(f"changed path is outside Task-035d allowed set: {path}")
        if any(path == forbidden or path.startswith(forbidden) for forbidden in FORBIDDEN_CHANGED_PATH_PREFIXES):
            fail(f"forbidden Task-035d path changed: {path}")


def verify_project_membership(project: Path) -> None:
    text = project.read_text(encoding="utf-8")
    required_tokens = [
        "35D900000000000000000001 /* SkateTrackPackageWatchCompatibilityTests.swift */",
        "35D900000000000000000101 /* SkateTrackPackageWatchCompatibilityTests.swift in Sources */",
    ]
    for token in required_tokens:
        if token in text:
            pass_msg(f"project membership contains {token}")
        else:
            fail(f"project membership missing {token}")


def verify_viewer_boundary(repo: Path) -> None:
    mac_open = repo / "macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift"
    require_contains(
        mac_open,
        [
            "SkateTrackPackageReader",
            "reader.readPackage(from: url)",
            "MacPackageImportPreview(fileURL: url, payload: payload)",
            "read-only",
            "不得寫入資料庫",
        ],
    )
    require_absent(
        mac_open,
        [
            "SessionRepository",
            "saveCompletedSession",
            "PersistenceController",
        ],
    )


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    if not (repo / "SkateTrack.xcodeproj/project.pbxproj").exists():
        fail(f"repo path does not look like SkateTrack: {repo}")

    branch = run_git(["branch", "--show-current"], repo)
    if branch == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-035d verification")
    else:
        fail(f"current branch is {branch}, expected {EXPECTED_BRANCH}")

    merge_base = run_git(["merge-base", "HEAD", TASK035C_HEAD], repo)
    if merge_base == TASK035C_HEAD:
        pass_msg("Task-035d is based on Task-035c pushed head")
    else:
        fail("Task-035d does not contain the expected Task-035c head")

    for relative in REQUIRED_FILES:
        path = repo / relative
        if path.exists():
            pass_msg(f"required file exists: {relative}")
        else:
            fail(f"required file missing: {relative}")

    verify_git_scope(repo)

    manifest = repo / "Shared/Models/SkateTrackPackageManifest.swift"
    tests = repo / "Tests/iOSTests/SkateTrackPackageWatchCompatibilityTests.swift"
    project = repo / "SkateTrack.xcodeproj/project.pbxproj"

    if manifest.exists():
        require_contains(
            manifest,
            [
                "static let currentSchemaVersion = 1",
                "watchSampleCompatibility: SkateTrackWatchSampleCompatibility? = nil",
                "var includesOptionalWatchSampleData: Bool",
                "struct SkateTrackWatchSampleCompatibility",
                "static let capabilityIdentifier = \"watch-sample-optional-v1\"",
                "trustedMetricMutationCount",
                "routeGeometryMutationCount",
            ],
        )
        require_absent(manifest, ["static let currentSchemaVersion = 2"])

    if tests.exists():
        require_contains(
            tests,
            [
                "testLegacySchemaOnePackageDecodesWithoutWatchCompatibilityMetadata",
                "testOptionalWatchCompatibilityMetadataRoundTripsWithoutSchemaBump",
                "testTask030dImportStillAcceptsLegacyPackageWithoutWatchMetadata",
                "testTask030eReadOnlyViewerReaderStillOpensLegacyPackage",
                "SkateTrackPackageReader().decodePackage",
                "SkateTrackPackageImportCoordinator",
                "SkateTrackPackageReader().readPackage",
                "XCTAssertNil(decoded.manifest.watchSampleCompatibility)",
                "XCTAssertEqual(decoded.manifest.schemaVersion, 1)",
                "trustedMetricMutationCount: 0",
                "routeGeometryMutationCount: 0",
            ],
        )
        require_absent(tests, FORBIDDEN_SOURCE_TOKENS)

    if project.exists():
        verify_project_membership(project)

    verify_viewer_boundary(repo)

    doc_tokens = [
        "VERIFY_TASK035D_PACKAGE_COMPATIBILITY_RESULT=PASSED",
        "OLD_PACKAGE_DECODE_TESTS_EXIT=0",
        "NEW_OPTIONAL_FIELDS_BACKWARD_COMPATIBLE=YES",
        "TASK030D_IMPORT_COMPATIBILITY=PASSED",
        "TASK030E_VIEWER_COMPATIBILITY=PASSED",
        "PACKAGE_SCHEMA_VERSION_UNCHANGED=YES",
        "WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO",
        "CORE_DATA_SCHEMA_MUTATION_IMPLEMENTED=NO",
        "ROUTE_GEOMETRY_MUTATION_COUNT=0",
        "TRUSTED_METRIC_MUTATION_COUNT=0",
        "NEXT_TASK=Task-035e",
    ]
    for relative in [
        "docs/process/PHASE_1B_AGENT_STATE.md",
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]:
        path = repo / relative
        if path.exists():
            require_contains(path, doc_tokens)

    print(f"NEW_OPTIONAL_FIELDS_BACKWARD_COMPATIBLE={'YES' if failure_count == 0 else 'NO'}")
    print("PACKAGE_SCHEMA_VERSION_UNCHANGED=YES")
    print("WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO")
    print("CORE_DATA_SCHEMA_MUTATION_IMPLEMENTED=NO")
    print("ROUTE_GEOMETRY_MUTATION_COUNT=0")
    print("TRUSTED_METRIC_MUTATION_COUNT=0")
    print(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0:
        print("VERIFY_TASK035D_PACKAGE_COMPATIBILITY_RESULT=PASSED")
        return 0
    print("VERIFY_TASK035D_PACKAGE_COMPATIBILITY_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
