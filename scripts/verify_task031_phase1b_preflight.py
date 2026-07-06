#!/usr/bin/env python3
"""
Task-031a Phase 1b baseline preflight verifier.

Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md
Aligned subtask: Task-031a — Develop Baseline Lock + Source-of-Truth Preflight
Not implementing: Watch UI, WatchBridge implementation, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

EXPECTED_BASELINE_FULL = "b941c7c2519c8e152327b5f91e4322e87de39cd9"
EXPECTED_TASK031_PREP_FULL = "99e9737fa7878cee84259ea98012aa5988f59fde"
EXPECTED_PLAN = "SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md"
EXPECTED_SUBTASK = "Task-031a — Develop Baseline Lock + Source-of-Truth Preflight"

REQUIRED_ACTIVITYVIZ_FILES = [
    "Shared/ActivityVisualization/ActivityVisualizationConfiguration.swift",
    "Shared/ActivityVisualization/ActivityVisualizationDiagnostics.swift",
    "Shared/ActivityVisualization/ActivityVisualizationPipeline.swift",
    "Shared/ActivityVisualization/ActivityVisualizationQuality.swift",
    "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayModels.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline+Filtering.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline+Startup.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline+Segmentation.swift",
    "Shared/ActivityVisualization/Route/RouteDisplayPipeline+Bounds.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayModels.swift",
    "Shared/ActivityVisualization/Speed/SpeedDisplayPipeline.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayModels.swift",
    "Shared/ActivityVisualization/Elevation/ElevationDisplayPipeline.swift",
]

COMPACT_TOKENS = [
    "ActivityVisualizationCompactSummary",
    "CompactRouteDisplay",
    "CompactSpeedSparkline",
    "CompactElevationProfile",
]

ALLOWED_DIFF_PREFIXES = [
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/adr/ADR-Shared-Activity-Visualization-Pipeline.md",
    "scripts/verify_task031_phase1b_preflight.py",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "scripts/verify_task031_watchos_inventory.py",
    "scripts/verify_task031_mode_guardrails.py",
    "scripts/verify_task031_docs_alignment.py",
]

FORBIDDEN_SCOPE_PATTERNS = [
    "routeGeometryMutationApplied = true",
    "trustedMetricsMutationApplied = true",
    "estimatedRouteActive = true",
    "generalUserEstimatedRouteDisplayAllowed = true",
    "schemaMutationApplied = true",
]

WATCH_COMPACT_TOKENS = COMPACT_TOKENS + [
    "ActivityVisualizationPipeline",
    "RouteDisplayPipeline",
    "SpeedDisplayPipeline",
    "ElevationDisplayPipeline",
]

failures: list[str] = []
warnings: list[str] = []


def print_header(title: str) -> None:
    print(f"===== {title} =====")


def pass_line(message: str) -> None:
    print(f"PASS: {message}")


def warn_line(message: str) -> None:
    warnings.append(message)
    print(f"WARNING: {message}")


def fail_line(message: str) -> None:
    failures.append(message)
    print(f"FAIL: {message}")


def run_git(repo: Path, args: list[str]) -> tuple[int, str]:
    proc = subprocess.run(
        ["git", *args],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    return proc.returncode, proc.stdout.strip()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def require_path(repo: Path, relative: str) -> bool:
    path = repo / relative
    if path.exists():
        pass_line(f"required path exists: {relative}")
        return True
    fail_line(f"missing required path: {relative}")
    return False


def contains_token(path: Path, token: str, label: str | None = None) -> bool:
    if not path.exists():
        fail_line(f"cannot check token; missing file: {path}")
        return False
    data = read_text(path)
    if token in data:
        pass_line(f"{label or path.name} contains token: {token}")
        return True
    fail_line(f"{label or path.name} missing token: {token}")
    return False


def check_git_baseline(repo: Path) -> None:
    print_header("Git baseline")
    allowed_branches = {"develop", "task-031a-phase1b-baseline-preflight", "task-031c-mode-guardrails"}
    code, branch = run_git(repo, ["rev-parse", "--abbrev-ref", "HEAD"])
    if code == 0:
        print(f"CURRENT_BRANCH={branch}")
        if branch in allowed_branches:
            print("TASK031A_BRANCH_CONTEXT=ALLOWED")
            pass_line("current branch is valid for Task-031a baseline or task-branch preflight")
        else:
            print("TASK031A_BRANCH_CONTEXT=UNEXPECTED")
            fail_line(f"current branch is not valid for Task-031a preflight: {branch}")
    else:
        fail_line("unable to read current branch")

    code, head = run_git(repo, ["rev-parse", "HEAD"])
    if code == 0:
        print(f"CURRENT_HEAD_FULL={head}")
    else:
        fail_line("unable to read HEAD")
        head = ""

    code, _ = run_git(repo, ["merge-base", "--is-ancestor", EXPECTED_BASELINE_FULL, "HEAD"])
    if code == 0:
        print("DEVELOP_BASELINE_HEAD_CONFIRMED=YES")
        pass_line(f"baseline commit {EXPECTED_BASELINE_FULL[:7]} is reachable from HEAD")
    else:
        print("DEVELOP_BASELINE_HEAD_CONFIRMED=NO")
        fail_line(f"baseline commit {EXPECTED_BASELINE_FULL[:7]} is not reachable from HEAD")

    code, _ = run_git(repo, ["merge-base", "--is-ancestor", EXPECTED_TASK031_PREP_FULL, "HEAD"])
    if code == 0:
        print("TASK031_PREP_MERGED_TO_DEVELOP=YES")
        pass_line(f"Task-031-prep commit {EXPECTED_TASK031_PREP_FULL[:7]} is reachable from HEAD")
    else:
        print("TASK031_PREP_MERGED_TO_DEVELOP=NO")
        fail_line(f"Task-031-prep commit {EXPECTED_TASK031_PREP_FULL[:7]} is not reachable from HEAD")


def _is_allowed_task031a_path(path: str) -> bool:
    return any(path == item or path.startswith(item.rstrip("/") + "/") for item in ALLOWED_DIFF_PREFIXES)


def check_allowed_diff(repo: Path) -> None:
    print_header("Docs-only diff guard")
    unexpected: list[str] = []

    code, diff_files = run_git(repo, ["diff", "--name-only"])
    if code != 0:
        fail_line("unable to inspect working-tree diff")
        return
    worktree_paths = [line.strip() for line in diff_files.splitlines() if line.strip()]
    print(f"WORKTREE_DIFF_FILE_COUNT={len(worktree_paths)}")
    for path in worktree_paths:
        print(f"WORKTREE_DIFF_PATH={path}")
        if not _is_allowed_task031a_path(path):
            unexpected.append(path)

    code, diff_cached = run_git(repo, ["diff", "--cached", "--name-only"])
    if code != 0:
        fail_line("unable to inspect staged diff")
        return
    staged_paths = [line.strip() for line in diff_cached.splitlines() if line.strip()]
    print(f"STAGED_DIFF_FILE_COUNT={len(staged_paths)}")
    for path in staged_paths:
        print(f"STAGED_DIFF_PATH={path}")
        if not _is_allowed_task031a_path(path):
            unexpected.append(path)

    code, untracked = run_git(repo, ["ls-files", "--others", "--exclude-standard"])
    if code != 0:
        fail_line("unable to inspect untracked files")
        return
    untracked_paths = [line.strip() for line in untracked.splitlines() if line.strip()]
    print(f"UNTRACKED_FILE_COUNT={len(untracked_paths)}")
    for path in untracked_paths:
        print(f"UNTRACKED_PATH={path}")
        if not _is_allowed_task031a_path(path):
            unexpected.append(path)

    unique_unexpected = sorted(set(unexpected))
    print(f"UNEXPECTED_TASK031A_DIFF_PATH_COUNT={len(unique_unexpected)}")
    if unique_unexpected:
        for path in unique_unexpected:
            fail_line(f"unexpected changed path outside Task-031a allowed scope: {path}")
    else:
        pass_line("all working-tree, staged, and untracked changes are within Task-031a allowed docs/verifier scope")


def check_activity_visualization(repo: Path) -> None:
    print_header("Shared ActivityVisualization baseline")
    for relative in REQUIRED_ACTIVITYVIZ_FILES:
        require_path(repo, relative)

    for relative in REQUIRED_ACTIVITYVIZ_FILES:
        path = repo / relative
        if not path.exists():
            continue
        data = read_text(path)
        first_line = data.splitlines()[0] if data.splitlines() else ""
        line_count = len(data.splitlines())
        print(f"FIRST_LINE[{Path(relative).name}]={first_line}")
        print(f"LINE_COUNT[{Path(relative).name}]={line_count}")
        if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]"):
            pass_line(f"{relative} has a valid collaboration/autonomous header")
        else:
            fail_line(f"{relative} missing valid first-line collaboration/autonomous header")
        if line_count <= 500:
            pass_line(f"{relative} stays under 500 lines")
        else:
            fail_line(f"{relative} exceeds 500-line hard limit")
        forbidden_imports = ["import SwiftUI", "import UIKit", "import AppKit", "import MapKit", "import WatchKit"]
        hits = [token for token in forbidden_imports if token in data]
        if hits:
            fail_line(f"{relative} imports platform UI frameworks: {', '.join(hits)}")
        else:
            pass_line(f"{relative} avoids platform UI imports")

    compact_file = repo / "Shared/ActivityVisualization/Compact/CompactActivityVisualizationModels.swift"
    compact_present = True
    for token in COMPACT_TOKENS:
        if not contains_token(compact_file, token, "CompactActivityVisualizationModels.swift"):
            compact_present = False
    print(f"COMPACT_ADAPTER_TYPES_PRESENT={'YES' if compact_present else 'NO'}")


def check_project_membership(repo: Path) -> None:
    print_header("Xcode source membership guard")
    pbxproj = repo / "SkateTrack.xcodeproj/project.pbxproj"
    if not require_path(repo, "SkateTrack.xcodeproj/project.pbxproj"):
        print("SHARED_ACTIVITYVIZ_WATCHOS_MEMBERSHIP=NO")
        return
    data = read_text(pbxproj)
    all_ok = True
    for relative in REQUIRED_ACTIVITYVIZ_FILES:
        filename = Path(relative).name
        source_count = data.count(f"/* {filename} in Sources */")
        file_ref_count = data.count(f"/* {filename} */")
        path_token_present = f"path = {filename}" in data or f"path = {relative}" in data or filename in data
        print(f"PROJECT_SOURCE_PHASE_COUNT[{filename}]={source_count}")
        print(f"PROJECT_FILEREF_TOKEN_COUNT[{filename}]={file_ref_count}")
        print(f"PROJECT_PATH_TOKEN_PRESENT[{filename}]={'YES' if path_token_present else 'NO'}")
        if source_count >= 3 and path_token_present:
            pass_line(f"{filename} has apparent iOS/macOS/watchOS source membership")
        else:
            all_ok = False
            fail_line(f"{filename} does not show expected 3-target source membership")
    print(f"SHARED_ACTIVITYVIZ_WATCHOS_MEMBERSHIP={'YES' if all_ok else 'NO'}")


def check_watchos_consumption(repo: Path) -> None:
    print_header("watchOS pre-UI compact consumption guard")
    watch_dir = repo / "watchOS"
    if not watch_dir.exists():
        fail_line("watchOS directory is missing")
        print("WATCHOS_COMPACT_CONSUMPTION_PRE_UI=UNKNOWN")
        return
    swift_files = sorted(watch_dir.rglob("*.swift"))
    print(f"WATCHOS_SWIFT_FILE_COUNT={len(swift_files)}")
    consumption_hits = []
    recording_hits = []
    recording_tokens = ["SessionRecordingCoordinator", "WatchSessionCoordinator", "WCSession", "HKWorkout", "HealthKit"]
    for path in swift_files:
        data = read_text(path)
        rel = path.relative_to(repo)
        for token in WATCH_COMPACT_TOKENS:
            if token in data:
                consumption_hits.append(f"{rel}:{token}")
        for token in recording_tokens:
            if token in data:
                recording_hits.append(f"{rel}:{token}")
    print(f"WATCHOS_COMPACT_CONSUMPTION_TOKEN_COUNT={len(consumption_hits)}")
    if consumption_hits:
        for hit in consumption_hits:
            fail_line(f"unexpected watchOS compact visualization consumption before UI task: {hit}")
        print("WATCHOS_COMPACT_CONSUMPTION_PRE_UI=YES")
    else:
        pass_line("watchOS compact visualization consumption remains absent before Watch UI work")
        print("WATCHOS_COMPACT_CONSUMPTION_PRE_UI=NO")

    print(f"WATCH_RECORDING_IMPLEMENTATION_TOKEN_COUNT={len(recording_hits)}")
    if recording_hits:
        for hit in recording_hits:
            fail_line(f"unexpected watchOS recording/bridge token before scoped task: {hit}")
    else:
        pass_line("no Watch recording implementation tokens found in watchOS Swift files")


def check_docs_and_policy(repo: Path) -> None:
    print_header("Task-031a docs and policy checkpoints")
    required_docs = [
        "docs/process/PHASE_1B_AGENT_STATE.md",
        "docs/adr/ADR-Shared-Activity-Visualization-Pipeline.md",
        "docs/adr/ADR-INDEX.md",
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
        "scripts/verify_task031_phase1b_preflight.py",
    ]
    for relative in required_docs:
        require_path(repo, relative)

    state = repo / "docs/process/PHASE_1B_AGENT_STATE.md"
    contains_token(state, EXPECTED_PLAN, "PHASE_1B_AGENT_STATE.md")
    contains_token(state, "DEVELOP_BASELINE_HEAD_CONFIRMED=YES", "PHASE_1B_AGENT_STATE.md")
    contains_token(state, "TASK031_PREP_MERGED_TO_DEVELOP=YES", "PHASE_1B_AGENT_STATE.md")
    contains_token(state, "MACOS_TEST_POLICY_CHECK_OPENED=YES", "PHASE_1B_AGENT_STATE.md")
    contains_token(state, "WATCH_ROUTE_MINI_CARD_DECISION_OPENED=YES", "PHASE_1B_AGENT_STATE.md")
    contains_token(state, "SHARED_WATCHBRIDGE_PATH_STATUS=ABSENT_EXPECTED_UNTIL_TASK032A_AUDIT", "PHASE_1B_AGENT_STATE.md")

    adr = repo / "docs/adr/ADR-Shared-Activity-Visualization-Pipeline.md"
    contains_token(adr, "Shared decides visualization data semantics. Platforms decide rendering.", "ADR-Shared-Activity-Visualization-Pipeline.md")
    contains_token(adr, "No Watch UI implementation", "ADR-Shared-Activity-Visualization-Pipeline.md")
    contains_token(adr, "No Watch recording implementation", "ADR-Shared-Activity-Visualization-Pipeline.md")
    contains_token(adr, "No route geometry mutation", "ADR-Shared-Activity-Visualization-Pipeline.md")

    adr_index = repo / "docs/adr/ADR-INDEX.md"
    contains_token(adr_index, "ADR-Shared-Activity-Visualization-Pipeline.md", "ADR-INDEX.md")
    dev_log = repo / "docs/history/DEV_LOG.md"
    contains_token(dev_log, "Task-031a-001 Baseline Preflight", "DEV_LOG.md")
    file_structure = repo / "docs/reference/FILE_STRUCTURE.md"
    contains_token(file_structure, "Task-031a Baseline Preflight Addendum", "FILE_STRUCTURE.md")
    contains_token(file_structure, "scripts/verify_task031_phase1b_preflight.py", "FILE_STRUCTURE.md")

    all_docs = "\n".join(read_text(repo / p) for p in [
        "docs/process/PHASE_1B_AGENT_STATE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
    ] if (repo / p).exists())
    if "estimatedRouteActive = false" in all_docs or "estimatedRouteActive=false" in all_docs:
        pass_line("estimatedRouteActive=false safety posture is documented")
    else:
        fail_line("estimatedRouteActive=false safety posture is not documented")

    print("MACOS_TEST_POLICY_CHECK_OPENED=YES" if "MACOS_TEST_POLICY_CHECK_OPENED=YES" in read_text(state) else "MACOS_TEST_POLICY_CHECK_OPENED=NO")
    print("WATCH_ROUTE_MINI_CARD_DECISION_OPENED=YES" if "WATCH_ROUTE_MINI_CARD_DECISION_OPENED=YES" in read_text(state) else "WATCH_ROUTE_MINI_CARD_DECISION_OPENED=NO")


def check_forbidden_scope(repo: Path) -> None:
    print_header("Forbidden scope guard")
    if (repo / "Shared/WatchBridge").exists():
        fail_line("Shared/WatchBridge exists before Task-032a audit/contract task")
        print("SHARED_WATCHBRIDGE_PATH_STATUS=PRESENT_UNEXPECTED_BEFORE_TASK032A")
    else:
        pass_line("Shared/WatchBridge remains absent and is recorded as Task-032a audit input")
        print("SHARED_WATCHBRIDGE_PATH_STATUS=ABSENT_EXPECTED_UNTIL_TASK032A_AUDIT")

    production_snow_paths = [
        repo / "Shared/Models/SnowSegment.swift",
        repo / "Shared/Models/SnowRun.swift",
        repo / "Shared/Persistence/SnowSessionRepository.swift",
        repo / "iOS/Core/SnowSports",
        repo / "Shared/SnowSports",
    ]
    snow_count = sum(1 for path in production_snow_paths if path.exists())
    print(f"SNOW_PRODUCTION_PATH_COUNT={snow_count}")
    if snow_count == 0:
        pass_line("no production Snow implementation paths were added by Task-031a")
    else:
        fail_line("production Snow implementation path detected during Task-031a")

    scan_paths = [repo / "docs/process/PHASE_1B_AGENT_STATE.md", repo / "docs/history/DEV_LOG.md", repo / "docs/reference/FILE_STRUCTURE.md"]
    for path in scan_paths:
        if not path.exists():
            continue
        data = read_text(path)
        for pattern in FORBIDDEN_SCOPE_PATTERNS:
            if pattern in data:
                fail_line(f"forbidden positive safety mutation marker found in {path.relative_to(repo)}: {pattern}")
    pass_line("forbidden positive safety mutation marker scan completed")


def main() -> int:
    repo = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
    print_header("Task-031a Phase 1b preflight verifier")
    print(f"Aligned Build Plan: {EXPECTED_PLAN}")
    print(f"Aligned subtask: {EXPECTED_SUBTASK}")
    print("Not implementing: Watch UI, WatchBridge implementation, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    print(f"REPO={repo}")

    if not (repo / ".git").exists():
        fail_line("repo path does not contain .git")
    else:
        pass_line("repo path contains .git")

    if (repo / ".git").exists():
        check_git_baseline(repo)
        check_allowed_diff(repo)
    check_activity_visualization(repo)
    check_project_membership(repo)
    check_watchos_consumption(repo)
    check_docs_and_policy(repo)
    check_forbidden_scope(repo)

    print_header("Summary")
    print(f"WARNING_COUNT={len(warnings)}")
    print(f"FAILURE_COUNT={len(failures)}")
    if failures:
        print("VERIFY_TASK031A_PREFLIGHT_RESULT=FAILED")
        return 1
    print("VERIFY_TASK031A_PREFLIGHT_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # fail gracefully; do not crash with a traceback-only verifier.
        print(f"FAIL: verifier crashed unexpectedly: {exc}")
        print("FAILURE_COUNT=1")
        print("VERIFY_TASK031A_PREFLIGHT_RESULT=FAILED")
        raise SystemExit(1)
