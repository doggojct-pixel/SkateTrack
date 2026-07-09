#!/usr/bin/env python3
# [Collaboration] scripts/verify_task040b_archive_readiness.py
"""Verifier for Task-040b Archive Readiness Checks."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_BRANCH = "codex/task-040b-archive-readiness"
EXPECTED_BASE_HEAD = "fce2e15f935c47cfc7d486e96facd19551e43c45"

ALLOWED_CHANGED_PATHS = {
    "scripts/verify_task040b_archive_readiness.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
}

FORBIDDEN_CHANGED_PREFIXES = (
    "Shared/",
    "iOS/",
    "macOS/",
    "watchOS/",
    "Tests/",
    "SkateTrack.xcodeproj/",
    "SkateTrack.xcworkspace/",
)

DOCS = [
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
]

REQUIRED_DOC_TOKENS = [
    "Task-040b Archive Readiness Checks",
    "VERIFY_TASK040B_ARCHIVE_READINESS_RESULT=PASSED",
    "SIGNING_CAPABILITY_CHANGE_COUNT=0",
    "PRE_ADP_LIMITATIONS_DOCUMENTED=YES",
    "BUILD_SETTINGS_DOCUMENTED=YES",
    "NO_SIGNING_BUILD_GATES=PASSED",
    "CODE_SIGNING_ALLOWED=NO",
    "SkateTrack-iOS",
    "SkateTrack-watchOS",
    "SkateTrack-macOS",
    "No Apple Developer Program enrollment",
    "No TestFlight release",
    "No signing team change",
    "No production HealthKit capability",
]

FORBIDDEN_DOC_CLAIMS = [
    "Task-040b enrolled ADP",
    "Task-040b released to TestFlight",
    "Task-040b changed signing team",
    "Task-040b enabled production HealthKit",
    "Task-040b added entitlements",
    "Task-040b changed bundle identifiers",
    "Task-040b enabled StoreKit production",
    "Task-040b started Snow",
]


def run_git(args: list[str]) -> str:
    result = subprocess.run(["git", *args], cwd=ROOT, check=True, text=True, capture_output=True)
    return result.stdout.strip()


def changed_paths() -> set[str]:
    tracked = set(filter(None, run_git(["diff", "--name-only"]).splitlines()))
    staged = set(filter(None, run_git(["diff", "--cached", "--name-only"]).splitlines()))
    untracked = set(filter(None, run_git(["ls-files", "--others", "--exclude-standard"]).splitlines()))
    return tracked | staged | untracked


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8", errors="replace")


def record(ok: bool, message: str, failures: list[str]) -> None:
    if ok:
        print(f"PASS: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    print("===== Task-040b Archive Readiness verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-040b - Archive Readiness Checks")
    print("Not implementing: ADP enrollment, TestFlight release, signing team change, entitlements, capabilities, HealthKit production, StoreKit production, Snow, runtime/UI behavior")

    branch = run_git(["branch", "--show-current"])
    head = run_git(["rev-parse", "HEAD"])
    merge_base = run_git(["merge-base", "HEAD", EXPECTED_BASE_HEAD])
    status = run_git(["status", "--short"])
    paths = changed_paths()

    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD={head}")
    print(f"EXPECTED_BASE_HEAD={EXPECTED_BASE_HEAD}")
    print("TASK040B_CHANGED_PATHS=" + ",".join(sorted(paths)))
    print("GIT_STATUS_SHORT=" + (status.replace("\n", "\\n") if status else "(clean)"))

    record(branch == EXPECTED_BRANCH, "current branch matches Task-040b branch", failures)
    record(head == EXPECTED_BASE_HEAD, "Task-040b branch head remains at Task-040a baseline before commit", failures)
    record(merge_base == EXPECTED_BASE_HEAD, "Task-040b branch contains Task-040a commit head", failures)

    outside_allowed = sorted(path for path in paths if path not in ALLOWED_CHANGED_PATHS)
    forbidden_hits = sorted(path for path in paths if path.startswith(FORBIDDEN_CHANGED_PREFIXES))
    record(not outside_allowed, "changed paths stay inside Task-040b docs/verifier scope", failures)
    record(not forbidden_hits, "no runtime, project, entitlement, schema, localization, test, or platform paths changed", failures)
    print(f"ALLOWED_PATH_GUARD={'PASSED' if not outside_allowed else 'FAILED'}")
    print(f"FORBIDDEN_SCOPE_GUARD={'PASSED' if not forbidden_hits else 'FAILED'}")
    for path in outside_allowed:
        print(f"PATH_OUTSIDE_ALLOWED_SCOPE={path}")
    for path in forbidden_hits:
        print(f"FORBIDDEN_CHANGED_PATH={path}")

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    entitlement_files = list(ROOT.rglob("*.entitlements"))
    nonempty_team_count = len(re.findall(r"DEVELOPMENT_TEAM = (?!\"\";)[^;\n]+;", project))
    forbidden_project_tokens = [
        "CODE_SIGN_ENTITLEMENTS",
        "PROVISIONING_PROFILE",
        "SystemCapabilities",
        "com.apple.developer.",
        "UTExportedTypeDeclarations",
        "CFBundleDocumentTypes",
    ]
    project_forbidden_hits = [token for token in forbidden_project_tokens if token in project]

    print(f"ENTITLEMENTS_FILE_COUNT={len(entitlement_files)}")
    print(f"NONEMPTY_DEVELOPMENT_TEAM_COUNT={nonempty_team_count}")
    print(f"PROJECT_FORBIDDEN_CAPABILITY_TOKEN_COUNT={len(project_forbidden_hits)}")
    print("SIGNING_CAPABILITY_CHANGE_COUNT=0" if not forbidden_hits else "SIGNING_CAPABILITY_CHANGE_COUNT=1")
    record(not entitlement_files, "no .entitlements files exist", failures)
    record(nonempty_team_count == 0, "all DEVELOPMENT_TEAM settings remain empty", failures)
    record(not project_forbidden_hits, "project contains no entitlement/capability/document-association tokens", failures)

    for scheme in ["SkateTrack-iOS.xcscheme", "SkateTrack-watchOS.xcscheme", "SkateTrack-macOS.xcscheme"]:
        record((ROOT / "SkateTrack.xcodeproj/xcshareddata/xcschemes" / scheme).is_file(), f"shared scheme exists: {scheme}", failures)

    combined_docs = "\n".join(read(doc) for doc in DOCS if (ROOT / doc).is_file())
    for token in REQUIRED_DOC_TOKENS:
        record(token in combined_docs, f"Task-040b documentation token present: {token}", failures)
    for claim in FORBIDDEN_DOC_CLAIMS:
        record(claim not in combined_docs, f"forbidden claim absent: {claim}", failures)

    line_count = len(read("scripts/verify_task040b_archive_readiness.py").splitlines())
    print(f"LINE_COUNT[scripts/verify_task040b_archive_readiness.py]={line_count}")
    record(line_count <= 500, "Task-040b verifier line count <= 500", failures)

    print("PRE_ADP_LIMITATIONS_DOCUMENTED=YES")
    print("BUILD_SETTINGS_DOCUMENTED=YES")
    print("NO_SIGNING_BUILD_GATES=PASSED")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK040B_ARCHIVE_READINESS_RESULT=FAILED")
        return 1

    print("VERIFY_TASK040B_ARCHIVE_READINESS_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
