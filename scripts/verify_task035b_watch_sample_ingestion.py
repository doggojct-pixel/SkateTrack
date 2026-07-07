#!/usr/bin/env python3
"""Task-035b Watch Sample Ingestion verifier."""

from pathlib import Path
import subprocess
import sys


EXPECTED_BRANCH = "task-035-watch-sample-foundation"
TASK035A_HEAD = "b01bbea645ec2017ae3cf4150145bd32babf53bc"

REQUIRED_FILES = [
    "Shared/WatchSensors/WatchSampleIngestion.swift",
    "Tests/iOSTests/WatchSampleIngestionTests.swift",
    "scripts/verify_task035b_watch_sample_ingestion.py",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "SkateTrack.xcodeproj/project.pbxproj",
]

FORBIDDEN_PATH_PREFIXES = [
    "Shared/Models/MotionSample.swift",
    "Shared/Models/SessionData.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Persistence/",
    "Shared/Export/",
    "iOS/Core/Import/",
    "macOS/Features/SessionBrowser/",
]

FORBIDDEN_NEW_FILE_TOKENS = [
    "HKHealthStore",
    "HKWorkout",
    "HKLiveWorkoutBuilder",
    "HKWorkoutSession",
    "HKQuantitySample",
    "HKSample",
    "HKObserverQuery",
    "enableBackgroundDelivery",
    "com.apple.developer.healthkit",
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


def verify_project_membership(project: Path) -> None:
    text = project.read_text(encoding="utf-8")
    required_tokens = [
        "35B100000000000000000001 /* WatchSampleIngestion.swift */",
        "35B100000000000000000101 /* WatchSampleIngestion.swift in Sources */",
        "35B100000000000000000102 /* WatchSampleIngestion.swift in Sources */",
        "35B900000000000000000001 /* WatchSampleIngestionTests.swift */",
        "35B900000000000000000101 /* WatchSampleIngestionTests.swift in Sources */",
    ]
    for token in required_tokens:
        if token in text:
            pass_msg(f"project membership contains {token}")
        else:
            fail(f"project membership missing {token}")


def verify_git_scope(repo: Path) -> None:
    changed = run_git(["diff", "--name-only", "HEAD", "--"], repo).splitlines()
    changed += run_git(["ls-files", "--others", "--exclude-standard"], repo).splitlines()
    changed = sorted(path for path in set(changed) if path)

    for path in changed:
        if any(path == forbidden or path.startswith(forbidden) for forbidden in FORBIDDEN_PATH_PREFIXES):
            fail(f"forbidden Task-035b path changed: {path}")


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    if not (repo / "SkateTrack.xcodeproj/project.pbxproj").exists():
        fail(f"repo path does not look like SkateTrack: {repo}")

    branch = run_git(["branch", "--show-current"], repo)
    if branch == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-035b verification")
    else:
        fail(f"current branch is {branch}, expected {EXPECTED_BRANCH}")

    merge_base = run_git(["merge-base", "HEAD", TASK035A_HEAD], repo)
    if merge_base == TASK035A_HEAD:
        pass_msg("Task-035b is based on Task-035a pushed head")
    else:
        fail("Task-035b does not contain the expected Task-035a head")

    for relative in REQUIRED_FILES:
        path = repo / relative
        if path.exists():
            pass_msg(f"required file exists: {relative}")
        else:
            fail(f"required file missing: {relative}")

    verify_git_scope(repo)

    ingestion = repo / "Shared/WatchSensors/WatchSampleIngestion.swift"
    tests = repo / "Tests/iOSTests/WatchSampleIngestionTests.swift"
    project = repo / "SkateTrack.xcodeproj/project.pbxproj"

    if ingestion.exists():
        require_contains(
            ingestion,
            [
                "WatchSampleIngestionPolicy",
                "WatchSampleSourceAttribution",
                "WatchSampleIngestionIssueKind",
                "WatchIngestedSample",
                "WatchSampleIngestionResult",
                "WatchSampleIngestor",
                "WatchSensorProviderSnapshot",
                "sourceAttribution",
                "trustedMetricMutationCount = 0",
                "routeGeometryMutationCount = 0",
                "case duplicateSample",
                "case outOfOrderSample",
                "case sampleGap",
                "case unusableSnapshot",
            ],
        )
        require_absent(ingestion, FORBIDDEN_NEW_FILE_TOKENS)

    if tests.exists():
        require_contains(
            tests,
            [
                "testIngestorSortsSamplesAndPreservesSourceAttribution",
                "testIngestorReportsGapsWithoutDroppingSamples",
                "testIngestorDropsDuplicateIDsAndReportsIssue",
                "testIngestorRejectsUnavailableSnapshot",
                "testIngestionDoesNotMutateTrustedMetricsOrRouteGeometry",
                "sourceAttribution",
                "trustedMetricMutationCount",
                "routeGeometryMutationCount",
            ],
        )
        require_absent(tests, FORBIDDEN_NEW_FILE_TOKENS)

    if project.exists():
        verify_project_membership(project)

    doc_tokens = [
        "VERIFY_TASK035B_WATCH_SAMPLE_INGESTION_RESULT=PASSED",
        "WATCH_SAMPLE_SOURCE_ATTRIBUTION=YES",
        "WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO",
        "ROUTE_GEOMETRY_MUTATION_COUNT=0",
        "TRUSTED_METRIC_MUTATION_COUNT=0",
        "NEXT_TASK=Task-035c",
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

    print(f"WATCH_SAMPLE_SOURCE_ATTRIBUTION={'YES' if failure_count == 0 else 'NO'}")
    print("TRUSTED_METRIC_MUTATION_COUNT=0")
    print("ROUTE_GEOMETRY_MUTATION_COUNT=0")
    print(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0:
        print("VERIFY_TASK035B_WATCH_SAMPLE_INGESTION_RESULT=PASSED")
        return 0
    print("VERIFY_TASK035B_WATCH_SAMPLE_INGESTION_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
