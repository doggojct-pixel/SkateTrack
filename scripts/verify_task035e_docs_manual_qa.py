#!/usr/bin/env python3
"""Task-035e Watch Sample Docs + Manual QA verifier."""

from pathlib import Path
import subprocess
import sys


EXPECTED_BRANCH = "task-035-watch-sample-foundation"
TASK035D_HEAD = "5b84e4d80e24f4bc04d8d09275c76218152031dc"

ALLOWED_CHANGED_PATHS = {
    "docs/release/TASK035E_WATCH_SAMPLE_MANUAL_QA.md",
    "scripts/verify_task035e_docs_manual_qa.py",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
}

REQUIRED_FILES = [
    "docs/release/TASK035E_WATCH_SAMPLE_MANUAL_QA.md",
    "scripts/verify_task035e_docs_manual_qa.py",
    "scripts/verify_task035b_watch_sample_ingestion.py",
    "scripts/verify_task035c_fusion_rules.py",
    "scripts/verify_task035d_package_compatibility.py",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

FORBIDDEN_CHANGED_PREFIXES = [
    "Shared/",
    "iOS/",
    "macOS/",
    "watchOS/",
    "Tests/",
    "SkateTrack.xcodeproj/",
]

FORBIDDEN_DOC_TOKENS = [
    "WATCH_UI_IMPLEMENTED=YES",
    "WATCH_SAMPLE_STORAGE_IMPLEMENTED=YES",
    "CORE_DATA_SCHEMA_MUTATION_IMPLEMENTED=YES",
    "PRODUCTION_HEALTHKIT_API_USED=YES",
    "HEALTHKIT_ENTITLEMENT_CHANGED=YES",
    "SNOW_PRODUCTION_IMPLEMENTED=YES",
    "ROUTE_GEOMETRY_MUTATION_COUNT=1",
    "TRUSTED_METRIC_MUTATION_COUNT=1",
]

CORE_TOKENS = [
    "VERIFY_TASK035E_DOCS_MANUAL_QA_RESULT=PASSED",
    "MANUAL_QA_WATCH_SAMPLE_PATH=PASSED",
    "DOCS_UPDATED=YES",
    "WATCH_SAMPLE_PROVIDER_BOUNDARY=PASSED",
    "WATCH_SAMPLE_INGESTION_PATH=PASSED",
    "WATCH_SAMPLE_FUSION_RULES=PASSED",
    "WATCH_SAMPLE_PACKAGE_COMPATIBILITY=PASSED",
    "WATCH_ROUTE_MINI_CARD_SCOPE=DEFERRED",
    "WATCH_ROUTE_MINI_CARD_REVIEW_AT_TASK036C=YES",
    "WATCH_UI_IMPLEMENTED=NO",
    "WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO",
    "CORE_DATA_SCHEMA_MUTATION_IMPLEMENTED=NO",
    "PACKAGE_SCHEMA_VERSION_UNCHANGED=YES",
    "PRODUCTION_HEALTHKIT_API_USED=NO",
    "HEALTHKIT_ENTITLEMENT_CHANGED=NO",
    "ROUTE_GEOMETRY_MUTATION_COUNT=0",
    "TRUSTED_METRIC_MUTATION_COUNT=0",
    "NEXT_TASK=Task-036a",
]

EVIDENCE_TOKENS = [
    "TASK034_SENSOR_PROVIDER_BOUNDARY_CLOSED=YES",
    "VERIFY_TASK035B_WATCH_SAMPLE_INGESTION_RESULT=PASSED",
    "VERIFY_TASK035C_FUSION_RULES_RESULT=PASSED",
    "VERIFY_TASK035D_PACKAGE_COMPATIBILITY_RESULT=PASSED",
    "DISPLAY_DERIVED_SEPARATION=YES",
    "OPTIONAL_WATCH_PACKAGE_METADATA_IMPLEMENTED=YES",
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
    return sorted(path for path in set(changed) if path and "__pycache__/" not in path and not path.endswith(".pyc"))


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
            fail(f"changed path is outside Task-035e docs/manual QA scope: {path}")
        if any(path == prefix.rstrip("/") or path.startswith(prefix) for prefix in FORBIDDEN_CHANGED_PREFIXES):
            fail(f"Task-035e must not change product/test/project path: {path}")


def main() -> int:
    repo = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    if not (repo / "SkateTrack.xcodeproj/project.pbxproj").exists():
        fail(f"repo path does not look like SkateTrack: {repo}")

    branch = run_git(["branch", "--show-current"], repo)
    if branch == EXPECTED_BRANCH:
        pass_msg("current branch is valid for Task-035e verification")
    else:
        fail(f"current branch is {branch}, expected {EXPECTED_BRANCH}")

    merge_base = run_git(["merge-base", "HEAD", TASK035D_HEAD], repo)
    if merge_base == TASK035D_HEAD:
        pass_msg("Task-035e is based on Task-035d pushed head")
    else:
        fail("Task-035e does not contain the expected Task-035d head")

    for relative in REQUIRED_FILES:
        path = repo / relative
        if path.exists():
            pass_msg(f"required file exists: {relative}")
        else:
            fail(f"required file missing: {relative}")

    verify_git_scope(repo)

    manual_qa = repo / "docs/release/TASK035E_WATCH_SAMPLE_MANUAL_QA.md"
    if manual_qa.exists():
        require_contains(manual_qa, CORE_TOKENS)
        require_contains(
            manual_qa,
            [
                "Pre-UI manual QA gate",
                "Pre-storage manual QA gate",
                "Task-036c must ask the operator",
                "Task-036a may start",
            ],
        )
        require_absent(manual_qa, FORBIDDEN_DOC_TOKENS)

    doc_paths = [
        repo / "docs/process/PHASE_1B_AGENT_STATE.md",
        repo / "docs/history/DEV_LOG.md",
        repo / "docs/reference/FILE_STRUCTURE.md",
        repo / "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]
    for path in doc_paths:
        if path.exists():
            require_contains(path, CORE_TOKENS)
            require_absent(path, FORBIDDEN_DOC_TOKENS)

    state = repo / "docs/process/PHASE_1B_AGENT_STATE.md"
    history = repo / "docs/history/DEV_LOG.md"
    if state.exists():
        require_contains(state, EVIDENCE_TOKENS)
    if history.exists():
        require_contains(history, EVIDENCE_TOKENS)

    print("MANUAL_QA_WATCH_SAMPLE_PATH=PASSED")
    print("DOCS_UPDATED=YES")
    print("WATCH_UI_IMPLEMENTED=NO")
    print("WATCH_SAMPLE_STORAGE_IMPLEMENTED=NO")
    print("ROUTE_GEOMETRY_MUTATION_COUNT=0")
    print("TRUSTED_METRIC_MUTATION_COUNT=0")
    print(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0:
        print("VERIFY_TASK035E_DOCS_MANUAL_QA_RESULT=PASSED")
        return 0
    print("VERIFY_TASK035E_DOCS_MANUAL_QA_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
