#!/usr/bin/env python3
# [Task-031b] watchOS target / scheme / simulator inventory verifier.
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path
from typing import Iterable

PLAN = "SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md"
SUBTASK = "Task-031b — watchOS Target / Scheme / Simulator Inventory"
EXPECTED_BASELINE = "8d4e83e77c3f3a927c66710f0960d178a2b6f2de"
TASK_BRANCH = "task-031b-watchos-inventory"
WATCH_TARGET = "SkateTrack-watchOS"
WATCH_SCHEME = "SkateTrack-watchOS"

ACTIVITYVIZ_FILES = [
    "ActivityVisualizationConfiguration.swift",
    "ActivityVisualizationDiagnostics.swift",
    "ActivityVisualizationPipeline.swift",
    "ActivityVisualizationQuality.swift",
    "CompactActivityVisualizationModels.swift",
    "RouteDisplayModels.swift",
    "RouteDisplayPipeline.swift",
    "RouteDisplayPipeline+Filtering.swift",
    "RouteDisplayPipeline+Startup.swift",
    "RouteDisplayPipeline+Segmentation.swift",
    "RouteDisplayPipeline+Bounds.swift",
    "SpeedDisplayModels.swift",
    "SpeedDisplayPipeline.swift",
    "ElevationDisplayModels.swift",
    "ElevationDisplayPipeline.swift",
]

COMPACT_TOKENS = [
    "ActivityVisualizationCompactSummary",
    "CompactRouteDisplay",
    "CompactSpeedSparkline",
    "CompactElevationProfile",
]

FORBIDDEN_SHARED_IMPORTS = [
    "import SwiftUI",
    "import UIKit",
    "import AppKit",
    "import WatchKit",
    "import MapKit",
    "import HealthKit",
    "import WatchConnectivity",
]

ALLOWED_CHANGED_PATHS = {
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task031_watchos_inventory.py",
}

failure_count = 0
warning_count = 0


def info(message: str) -> None:
    print(message)


def fail(message: str) -> None:
    global failure_count
    print(f"FAIL: {message}")
    failure_count += 1


def warn(message: str) -> None:
    global warning_count
    print(f"WARNING: {message}")
    warning_count += 1


def passed(message: str) -> None:
    print(f"PASS: {message}")


def run(command: list[str], *, cwd: Path) -> tuple[int, str]:
    try:
        completed = subprocess.run(
            command,
            cwd=str(cwd),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        return completed.returncode, completed.stdout
    except FileNotFoundError as exc:
        return 127, f"{exc}\n"
    except Exception as exc:  # fail gracefully, never crash the verifier
        return 126, f"{type(exc).__name__}: {exc}\n"


def repo_root() -> Path:
    return Path.cwd()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception as exc:
        fail(f"unable to read {path}: {exc}")
        return ""


def require_path(path: Path) -> bool:
    if path.exists():
        passed(f"required path exists: {path.as_posix()}")
        return True
    fail(f"required path missing: {path.as_posix()}")
    return False


def git_output(args: list[str], repo: Path) -> tuple[int, str]:
    return run(["git", *args], cwd=repo)


def baseline_check(repo: Path) -> None:
    info("===== Git baseline =====")

    branch_exit, branch = git_output(["branch", "--show-current"], repo)
    branch = branch.strip()
    print(f"CURRENT_BRANCH={branch}")
    if branch in {"develop", TASK_BRANCH}:
        print("TASK031B_BRANCH_CONTEXT=ALLOWED")
        passed("current branch is valid for Task-031b inventory verification")
    else:
        fail(f"current branch must be develop or {TASK_BRANCH}, got {branch}")

    head_exit, head = git_output(["rev-parse", "HEAD"], repo)
    head = head.strip()
    print(f"CURRENT_HEAD_FULL={head}")

    ancestor_exit, _ = git_output(["merge-base", "--is-ancestor", EXPECTED_BASELINE, "HEAD"], repo)
    print(f"BASELINE_ANCESTOR_EXIT={ancestor_exit}")
    if ancestor_exit == 0:
        print("TASK031A_DEVELOP_BASELINE_REACHABLE=YES")
        passed(f"Task-031a develop baseline {EXPECTED_BASELINE[:7]} is reachable from HEAD")
    else:
        print("TASK031A_DEVELOP_BASELINE_REACHABLE=NO")
        fail(f"Task-031a develop baseline {EXPECTED_BASELINE} is not reachable from HEAD")


def parse_xcode_list(output: str) -> tuple[set[str], set[str]]:
    targets: set[str] = set()
    schemes: set[str] = set()
    current = None

    for raw in output.splitlines():
        line = raw.rstrip()
        stripped = line.strip()
        if stripped == "Targets:":
            current = "targets"
            continue
        if stripped == "Schemes:":
            current = "schemes"
            continue
        if stripped.endswith(":") and stripped not in {"Targets:", "Schemes:"}:
            current = None
            continue
        if current == "targets" and stripped:
            targets.add(stripped)
        if current == "schemes" and stripped:
            schemes.add(stripped)
    return targets, schemes


def xcode_inventory(repo: Path) -> None:
    info("===== Xcode watchOS target / scheme inventory =====")
    project = repo / "SkateTrack.xcodeproj" / "project.pbxproj"
    if not require_path(project):
        return

    list_exit, list_output = run(["xcodebuild", "-list", "-project", "SkateTrack.xcodeproj"], cwd=repo)
    print(f"XCODEBUILD_LIST_EXIT={list_exit}")
    if list_exit != 0:
        fail("xcodebuild -list failed")
        print(list_output)
        return

    targets, schemes = parse_xcode_list(list_output)
    for target in sorted(targets):
        print(f"XCODE_TARGET={target}")
    for scheme in sorted(schemes):
        print(f"XCODE_SCHEME={scheme}")

    target_found = WATCH_TARGET in targets
    scheme_found = WATCH_SCHEME in schemes

    print(f"WATCHOS_TARGET_FOUND={'YES' if target_found else 'NO'}")
    print(f"WATCHOS_SCHEME_FOUND={'YES' if scheme_found else 'NO'}")
    print(f"WATCHOS_TARGET_NAME={WATCH_TARGET}")
    print("WATCHOS_NO_SIGNING_BUILD_STYLE=TARGET_BUILD_GENERIC_WATCHOS_CODE_SIGNING_ALLOWED_NO")

    if target_found:
        passed(f"watchOS target found: {WATCH_TARGET}")
    else:
        fail(f"watchOS target missing: {WATCH_TARGET}")

    if scheme_found:
        passed(f"watchOS scheme found: {WATCH_SCHEME}")
    else:
        warn(f"watchOS scheme missing; target-only build would be required: {WATCH_TARGET}")

    settings_exit, settings_output = run(
        [
            "xcodebuild",
            "-project",
            "SkateTrack.xcodeproj",
            "-target",
            WATCH_TARGET,
            "-showBuildSettings",
            "CODE_SIGNING_ALLOWED=NO",
        ],
        cwd=repo,
    )
    print(f"WATCHOS_SHOW_BUILD_SETTINGS_EXIT={settings_exit}")
    if settings_exit != 0:
        fail("watchOS target build-settings inventory failed")
        print(settings_output)
        return

    def setting_value(name: str) -> str:
        match = re.search(rf"^\s*{re.escape(name)}\s*=\s*(.*?)\s*$", settings_output, re.MULTILINE)
        return match.group(1).strip() if match else "MISSING"

    build_setting_names = [
        "PRODUCT_BUNDLE_IDENTIFIER",
        "CODE_SIGN_STYLE",
        "DEVELOPMENT_TEAM",
        "WATCHOS_DEPLOYMENT_TARGET",
        "SDKROOT",
        "SUPPORTED_PLATFORMS",
        "CODE_SIGNING_ALLOWED",
    ]

    for name in build_setting_names:
        print(f"WATCHOS_BUILD_SETTING[{name}]={setting_value(name)}")

    if "CODE_SIGNING_ALLOWED = NO" in settings_output or "CODE_SIGNING_ALLOWED=NO" in settings_output:
        print("WATCHOS_CODE_SIGNING_ALLOWED_OVERRIDE=NO")
        passed("watchOS target inventory accepts CODE_SIGNING_ALLOWED=NO")
    else:
        print("WATCHOS_CODE_SIGNING_ALLOWED_OVERRIDE=NOT_CONFIRMED")
        fail("watchOS target build-settings output did not confirm CODE_SIGNING_ALLOWED=NO")


def collect_target_source_filenames(project_text: str, target_name: str) -> set[str]:
    target_line = f"/* {target_name} */ = {{"
    target_start = project_text.find(target_line)
    if target_start < 0:
        return set()

    target_end = project_text.find("\n\t\t};", target_start)
    target_block = project_text[target_start:target_end if target_end >= 0 else len(project_text)]

    source_ids = re.findall(r"([A-Za-z0-9]+) /\* Sources \*/", target_block)
    source_filenames: set[str] = set()

    for source_id in source_ids:
        phase_line = f"{source_id} /* Sources */ = {{"
        phase_start = project_text.find(phase_line)
        if phase_start < 0:
            continue
        phase_end = project_text.find("\n\t\t};", phase_start)
        phase_block = project_text[phase_start:phase_end if phase_end >= 0 else len(project_text)]
        for match in re.finditer(r"/\* ([^*]+\.swift) in Sources \*/", phase_block):
            source_filenames.add(match.group(1))

    return source_filenames


def project_membership(repo: Path) -> None:
    info("===== Shared ActivityVisualization watchOS source membership =====")
    project = repo / "SkateTrack.xcodeproj" / "project.pbxproj"
    if not project.exists():
        fail("project.pbxproj missing before membership check")
        return

    text = read_text(project)
    source_filenames = collect_target_source_filenames(text, WATCH_TARGET)

    print(f"WATCHOS_TARGET_SOURCE_FILE_COUNT={len(source_filenames)}")
    missing = []
    for filename in ACTIVITYVIZ_FILES:
        in_sources = filename in source_filenames
        path_token_present = filename in text
        print(f"WATCHOS_SOURCE_MEMBERSHIP[{filename}]={'YES' if in_sources else 'NO'}")
        print(f"PROJECT_PATH_TOKEN_PRESENT[{filename}]={'YES' if path_token_present else 'NO'}")
        if not in_sources or not path_token_present:
            missing.append(filename)

    if missing:
        print("SHARED_ACTIVITYVIZ_WATCHOS_MEMBERSHIP=NO")
        for filename in missing:
            fail(f"Shared/ActivityVisualization file missing from watchOS target sources: {filename}")
    else:
        print("SHARED_ACTIVITYVIZ_WATCHOS_MEMBERSHIP=YES")
        passed("all Shared/ActivityVisualization files appear in watchOS target source phase")

    print("MEMBERSHIP_REPAIR_APPLIED_IF_NEEDED=NA")


def swift_header_line_checks(repo: Path) -> None:
    info("===== Swift header / line / Shared import checks =====")
    roots = [repo / "watchOS", repo / "Shared" / "ActivityVisualization"]
    swift_files: list[Path] = []
    for root in roots:
        if root.exists():
            swift_files.extend(sorted(root.rglob("*.swift")))

    print(f"WATCHOS_AND_ACTIVITYVIZ_SWIFT_FILE_COUNT={len(swift_files)}")
    for path in swift_files:
        rel = path.relative_to(repo).as_posix()
        text = read_text(path)
        first_line = text.splitlines()[0] if text.splitlines() else ""
        line_count = len(text.splitlines())
        print(f"FIRST_LINE[{rel}]={first_line}")
        print(f"LINE_COUNT[{rel}]={line_count}")

        if first_line.startswith("// [協作區]") or first_line.startswith("// [自主區]"):
            passed(f"{rel} has a valid collaboration/autonomous header")
        else:
            fail(f"{rel} is missing required collaboration/autonomous header")

        if line_count <= 500:
            passed(f"{rel} stays under 500 lines")
        else:
            fail(f"{rel} exceeds the 500-line hard limit")

        if rel.startswith("Shared/ActivityVisualization/"):
            forbidden_hits = [token for token in FORBIDDEN_SHARED_IMPORTS if token in text]
            print(f"FORBIDDEN_SHARED_IMPORT_COUNT[{rel}]={len(forbidden_hits)}")
            if forbidden_hits:
                for token in forbidden_hits:
                    fail(f"{rel} imports forbidden platform framework: {token}")
            else:
                passed(f"{rel} avoids forbidden platform UI/permission imports")


def watchos_consumption_guard(repo: Path) -> None:
    info("===== watchOS pre-UI compact consumption guard =====")
    watch_root = repo / "watchOS"
    swift_files = sorted(watch_root.rglob("*.swift")) if watch_root.exists() else []
    compact_hit_files: set[str] = set()
    bridge_hit_files: set[str] = set()
    healthkit_hit_files: set[str] = set()

    for path in swift_files:
        rel = path.relative_to(repo).as_posix()
        text = read_text(path)
        if any(token in text for token in COMPACT_TOKENS):
            compact_hit_files.add(rel)
        if "WatchConnectivity" in text or "WCSession" in text or "WatchBridge" in text:
            bridge_hit_files.add(rel)
        if "HealthKit" in text or "HKHealthStore" in text:
            healthkit_hit_files.add(rel)

    print(f"WATCHOS_SWIFT_FILE_COUNT={len(swift_files)}")
    print(f"WATCHOS_COMPACT_CONSUMPTION_FILE_COUNT={len(compact_hit_files)}")
    print(f"WATCH_CONNECTIVITY_RUNTIME_FILE_COUNT={len(bridge_hit_files)}")
    print(f"HEALTHKIT_RUNTIME_FILE_COUNT={len(healthkit_hit_files)}")

    for rel in sorted(compact_hit_files):
        print(f"WATCHOS_COMPACT_CONSUMPTION_FILE={rel}")
    for rel in sorted(bridge_hit_files):
        print(f"WATCH_CONNECTIVITY_RUNTIME_FILE={rel}")
    for rel in sorted(healthkit_hit_files):
        print(f"HEALTHKIT_RUNTIME_FILE={rel}")

    if compact_hit_files:
        print("WATCHOS_COMPACT_CONSUMPTION_PRE_UI=YES")
        fail("watchOS compact visualization consumption exists before approved Watch UI subtasks")
    else:
        print("WATCHOS_COMPACT_CONSUMPTION_PRE_UI=NO")
        passed("watchOS compact visualization consumption remains absent before Watch UI work")

    if bridge_hit_files:
        fail("WatchConnectivity / WatchBridge runtime tokens found in watchOS Swift files")
    else:
        passed("no WatchConnectivity / WatchBridge runtime behavior found in watchOS Swift files")

    if healthkit_hit_files:
        fail("HealthKit runtime tokens found in watchOS Swift files")
    else:
        passed("no HealthKit runtime behavior found in watchOS Swift files")


def watchbridge_directory_inventory(repo: Path) -> None:
    info("===== WatchBridge / watchOS directory inventory =====")
    watchbridge = repo / "Shared" / "WatchBridge"
    watchos = repo / "watchOS"

    if watchbridge.exists():
        print("SHARED_WATCHBRIDGE_PATH_STATUS=PRESENT")
        for path in sorted(watchbridge.rglob("*")):
            if path.is_file():
                print(f"SHARED_WATCHBRIDGE_FILE={path.relative_to(repo).as_posix()}")
    else:
        print("SHARED_WATCHBRIDGE_PATH_STATUS=ABSENT_EXPECTED_UNTIL_TASK032A_AUDIT")
        passed("Shared/WatchBridge remains absent and is recorded as Task-032a audit input")

    if watchos.exists():
        for path in sorted(watchos.rglob("*")):
            if path.is_file():
                print(f"WATCHOS_FILE={path.relative_to(repo).as_posix()}")
    else:
        fail("watchOS directory missing")


def docs_and_state_checks(repo: Path) -> None:
    info("===== Task-031b docs and state checkpoints =====")
    state = repo / "docs/process/PHASE_1B_AGENT_STATE.md"
    file_structure = repo / "docs/reference/FILE_STRUCTURE.md"
    dev_log = repo / "docs/history/DEV_LOG.md"
    verifier = repo / "scripts/verify_task031_watchos_inventory.py"

    for path in [state, file_structure, dev_log, verifier]:
        require_path(path)

    state_text = read_text(state)
    file_structure_text = read_text(file_structure)
    dev_log_text = read_text(dev_log)

    tokens = [
        "TASK031B_WATCHOS_TARGET_FOUND=YES",
        "TASK031B_WATCHOS_SCHEME_FOUND=YES",
        "TASK031B_WATCHOS_NO_SIGNING_BUILD_TARGET=SkateTrack-watchOS",
        "TASK031B_WATCHOS_COMPACT_CONSUMPTION_PRE_UI=NO",
        "TASK031B_MEMBERSHIP_REPAIR_APPLIED_IF_NEEDED=NA",
        "TASK031B_SIGNING_CAPABILITY_CHANGE_COUNT=0",
        "TASK031B_WATCHBRIDGE_STATUS=ABSENT_EXPECTED_UNTIL_TASK032A_AUDIT",
    ]

    for token in tokens:
        if token in state_text:
            passed(f"PHASE_1B_AGENT_STATE.md contains token: {token}")
        else:
            fail(f"PHASE_1B_AGENT_STATE.md missing token: {token}")

    if "Task-031b WatchOS Inventory Addendum" in file_structure_text:
        passed("FILE_STRUCTURE documents Task-031b WatchOS Inventory Addendum")
    else:
        fail("FILE_STRUCTURE missing Task-031b WatchOS Inventory Addendum")

    if "scripts/verify_task031_watchos_inventory.py" in file_structure_text:
        passed("FILE_STRUCTURE documents verify_task031_watchos_inventory.py")
    else:
        fail("FILE_STRUCTURE missing verify_task031_watchos_inventory.py")

    if "Task-031b-001 WatchOS Target Inventory" in dev_log_text:
        passed("DEV_LOG documents Task-031b-001 WatchOS Target Inventory")
    else:
        fail("DEV_LOG missing Task-031b-001 WatchOS Target Inventory")


def forbidden_scope_change_guard(repo: Path) -> None:
    info("===== Forbidden changed-scope guard =====")
    status_exit, status_text = git_output(["status", "--porcelain=v1"], repo)
    changed: list[str] = []
    for line in status_text.splitlines():
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        changed.append(path)

    unexpected = [path for path in changed if path not in ALLOWED_CHANGED_PATHS]
    for path in changed:
        print(f"STATUS_PATH={path}")

    print(f"UNEXPECTED_TASK031B_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        fail(f"unexpected Task-031b changed path: {path}")

    forbidden_patterns = [
        r"^SkateTrack\.xcodeproj/",
        r"^watchOS/",
        r"^Shared/WatchBridge",
        r"\.entitlements$",
        r"\.xcdatamodel",
        r"PersistenceController",
        r"SessionRepository",
        r"SessionEntityMapper",
        r"SnowMode",
        r"SnowRun",
        r"SnowSegment",
        r"SnowPrototype",
        r"iOS/Features/Snow",
        r"watchOS/Features/Snow",
    ]

    forbidden_hits = [
        path for path in changed
        if any(re.search(pattern, path) for pattern in forbidden_patterns)
    ]

    print(f"SIGNING_CAPABILITY_CHANGE_COUNT={sum(1 for path in changed if path.startswith('SkateTrack.xcodeproj/') or path.endswith('.entitlements'))}")
    print(f"FORBIDDEN_CHANGED_SCOPE_COUNT={len(forbidden_hits)}")
    for path in forbidden_hits:
        fail(f"forbidden changed scope path: {path}")

    if not unexpected and not forbidden_hits:
        passed("changed paths are limited to Task-031b docs/verifier scope")


def main() -> int:
    repo = repo_root()
    print("===== Task-031b watchOS inventory verifier =====")
    print(f"Aligned Build Plan: {PLAN}")
    print(f"Aligned subtask: {SUBTASK}")
    print("Not implementing: signing, entitlements, HealthKit, WatchConnectivity runtime behavior, UI, capabilities, bundle identifiers, WatchBridge implementation, Snow production, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    print(f"REPO={repo}")

    if not (repo / ".git").exists():
        fail("repo path does not contain .git")
    else:
        passed("repo path contains .git")

    baseline_check(repo)
    xcode_inventory(repo)
    project_membership(repo)
    swift_header_line_checks(repo)
    watchos_consumption_guard(repo)
    watchbridge_directory_inventory(repo)
    docs_and_state_checks(repo)
    forbidden_scope_change_guard(repo)

    print("===== Summary =====")
    print(f"WARNING_COUNT={warning_count}")
    print(f"FAILURE_COUNT={failure_count}")
    if failure_count == 0:
        print("VERIFY_TASK031B_WATCHOS_INVENTORY_RESULT=PASSED")
        return 0

    print("VERIFY_TASK031B_WATCHOS_INVENTORY_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
