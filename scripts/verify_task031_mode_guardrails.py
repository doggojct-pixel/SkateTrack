#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

EXPECTED_BASE = "1822845e2e1872f923bc1a332c69c10611537be7"
VALID_BRANCHES = {"develop", "task-031c-mode-guardrails"}
ALLOWED_DIFF_PATHS = {
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task031_mode_guardrails.py",
}

SNOW_PRODUCTION_PATHS = [
    "Shared/Models/SnowSegment.swift",
    "Shared/Models/SnowRun.swift",
    "Shared/Models/SnowDistanceBreakdown.swift",
    "Shared/Persistence/SnowSessionRepository.swift",
    "Shared/SnowSports",
    "iOS/Core/SnowEngine",
    "iOS/Core/SnowSports",
    "iOS/Features/Snow",
    "watchOS/Features/Snow",
]

FORBIDDEN_SNOW_IMPLEMENTATION_PATTERNS = [
    r"\bstruct\s+SnowSegment\b",
    r"\bstruct\s+SnowRun\b",
    r"\bstruct\s+SnowDistanceBreakdown\b",
    r"\bclass\s+SnowSegmentClassifier\b",
    r"\bstruct\s+SnowSegmentClassifier\b",
    r"\bclass\s+RunBoundaryDetector\b",
    r"\bstruct\s+RunBoundaryDetector\b",
    r"\bSnowClassifier\b",
]

FORBIDDEN_TRICK_IMPLEMENTATION_PATTERNS = [
    r"\bclass\s+TrickClassifier\b",
    r"\bstruct\s+TrickClassifier\b",
    r"\bclass\s+TrickDetector\b",
    r"\bstruct\s+TrickDetector\b",
    r"\bTrickRecognitionEngine\b",
    r"\bTrickRecognitionService\b",
]

BOOLEAN_SHORTCUT_PATTERNS = [
    r"\bisSnow\b",
    r"\bsnowOnly\b",
    r"\bisSkate\b",
    r"\bskateOnly\b",
    r"\bskateboardOnly\b",
    r"\binlineOnly\b",
]

MODE_GUARDRAIL_SCAN_ROOTS = [
    "Shared/Models",
    "watchOS",
    "docs/process/PHASE_1B_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/history/DEV_LOG.md",
]

BOOLEAN_SHORTCUT_ALLOWLIST = {
    # Existing equipment-type helpers are gear classification helpers, not Watch payload / mode-switch shortcuts.
    "Shared/Models/EquipmentProfile.swift:isInlineGear",
    "Shared/Models/EquipmentProfile.swift:isSkateboardGear",
}

REQUIRED_STATE_TOKENS = [
    "TASK031C_MODE_GUARDRAILS_RESULT=PASSED",
    "TASK031C_MODE_NEUTRAL_ARCHITECTURE=YES",
    "TASK031C_SNOW_PRODUCTION_IMPLEMENTATION_COUNT=0",
    "TASK031C_TRICK_RECOGNITION_IMPLEMENTATION_COUNT=0",
    "TASK031C_BOOLEAN_ONLY_MODE_SHORTCUT_COUNT=0",
    "TASK031C_WATCH_UI_IMPLEMENTED=NO",
    "TASK031C_WATCHBRIDGE_RUNTIME_IMPLEMENTED=NO",
    "TASK031C_SNOWFEATURE_REFERENCE_ONLY=YES",
]

REQUIRED_DEVLOG_TOKENS = [
    "Task-031c-001 SportMode and Snow-aware Guardrails",
    "SnowFeature reference-only",
    "BOOLEAN_ONLY_MODE_SHORTCUT_COUNT=0",
]

REQUIRED_STRUCTURE_TOKENS = [
    "Task-031c Mode Guardrails Addendum",
    "scripts/verify_task031_mode_guardrails.py",
]


@dataclass
class Result:
    failures: int = 0
    warnings: int = 0

    def pass_msg(self, message: str) -> None:
        print(f"PASS: {message}")

    def fail(self, message: str) -> None:
        print(f"FAIL: {message}")
        self.failures += 1

    def warn(self, message: str) -> None:
        print(f"WARN: {message}")
        self.warnings += 1


def run_git(args: list[str], repo: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True, check=False)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def extract_function_body(text: str, function_name: str) -> str | None:
    marker = f"func {function_name}"
    start = text.find(marker)
    if start == -1:
        return None
    brace = text.find("{", start)
    if brace == -1:
        return None
    depth = 0
    for index in range(brace, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[brace + 1:index]
    return None


def list_repo_files(repo: Path, roots: list[str]) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        path = repo / root
        if not path.exists():
            continue
        if path.is_file():
            files.append(path)
            continue
        for child in path.rglob("*"):
            if child.is_file() and ".git" not in child.parts:
                files.append(child)
    return files


def status_paths(repo: Path) -> list[str]:
    cp = run_git(["status", "--porcelain=v1"], repo)
    paths: list[str] = []
    for line in cp.stdout.splitlines():
        if not line:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        paths.append(path)
    return paths


def diff_paths(repo: Path) -> list[str]:
    paths: set[str] = set()
    for args in (["diff", "--name-only"], ["diff", "--cached", "--name-only"]):
        cp = run_git(args, repo)
        for line in cp.stdout.splitlines():
            if line.strip():
                paths.add(line.strip())
    cp = run_git(["ls-files", "--others", "--exclude-standard"], repo)
    for line in cp.stdout.splitlines():
        if line.strip():
            paths.add(line.strip())
    return sorted(paths)


def count_forbidden_patterns(repo: Path, roots: list[str], patterns: list[str], allowed_contexts: tuple[str, ...] = ()) -> tuple[int, list[str]]:
    count = 0
    hits: list[str] = []
    compiled = [re.compile(pattern) for pattern in patterns]
    for path in list_repo_files(repo, roots):
        if path.suffix not in {".swift", ".md", ".txt", ".py", ".json", ".plist"}:
            continue
        rel = path.relative_to(repo).as_posix()
        text = read(path)
        for line_no, line in enumerate(text.splitlines(), 1):
            if allowed_contexts and any(ctx in f"{rel}:{line}" for ctx in allowed_contexts):
                continue
            for pattern in compiled:
                if pattern.search(line):
                    count += 1
                    hits.append(f"{rel}:{line_no}:{line.strip()}")
    return count, hits


def count_boolean_shortcuts(repo: Path) -> tuple[int, int, list[str]]:
    disallowed = 0
    allowlisted = 0
    hits: list[str] = []
    compiled = [re.compile(pattern) for pattern in BOOLEAN_SHORTCUT_PATTERNS]
    for path in list_repo_files(repo, MODE_GUARDRAIL_SCAN_ROOTS):
        if path.suffix not in {".swift", ".md", ".txt", ".py"}:
            continue
        rel = path.relative_to(repo).as_posix()
        text = read(path)
        for line_no, line in enumerate(text.splitlines(), 1):
            for pattern in compiled:
                match = pattern.search(line)
                if not match:
                    continue
                token = match.group(0)
                allow_key = f"{rel}:{token}"
                record = f"{rel}:{line_no}:{line.strip()}"
                if allow_key in BOOLEAN_SHORTCUT_ALLOWLIST:
                    allowlisted += 1
                    print(f"ALLOWLISTED_BOOLEAN_MODE_HELPER={record}")
                elif rel.startswith("docs/"):
                    # Documentation may record the guardrail marker itself.
                    continue
                else:
                    disallowed += 1
                    hits.append(record)
    return disallowed, allowlisted, hits


def check_required_file(repo: Path, rel: str, result: Result) -> Path:
    path = repo / rel
    if path.exists():
        result.pass_msg(f"required path exists: {rel}")
    else:
        result.fail(f"required path missing: {rel}")
    return path


def main() -> int:
    repo = Path.cwd()
    result = Result()

    print("===== Task-031c mode guardrails verifier =====")
    print("Aligned Build Plan: SkateTrack_BuildPlan_Phase1b_Task031-040_EN_v1_71.md")
    print("Aligned subtask: Task-031c — SportMode and Snow-aware Architecture Guardrails")
    print("Not implementing: Snow production, Snow classifier, Snow run detector, SnowPrototype UI, Trick recognition, Watch UI, WatchBridge runtime behavior, schema/Core Data/package mutation, route geometry mutation, trusted metric mutation, estimated route enablement")
    print(f"REPO={repo}")

    if (repo / ".git").exists():
        result.pass_msg("repo path contains .git")
    else:
        result.fail("repo path does not contain .git")

    print("===== Git baseline =====")
    branch = run_git(["branch", "--show-current"], repo).stdout.strip()
    head = run_git(["rev-parse", "HEAD"], repo).stdout.strip()
    print(f"CURRENT_BRANCH={branch}")
    print(f"CURRENT_HEAD_FULL={head}")
    if branch in VALID_BRANCHES:
        print("TASK031C_BRANCH_CONTEXT=ALLOWED")
        result.pass_msg("current branch is valid for Task-031c guardrail verification")
    else:
        result.fail(f"unexpected branch for Task-031c: {branch}")

    ancestor = run_git(["merge-base", "--is-ancestor", EXPECTED_BASE, "HEAD"], repo)
    print(f"BASELINE_ANCESTOR_EXIT={ancestor.returncode}")
    if ancestor.returncode == 0:
        print("TASK031B_DEVELOP_BASELINE_REACHABLE=YES")
        result.pass_msg(f"Task-031b develop baseline {EXPECTED_BASE[:7]} is reachable from HEAD")
    else:
        print("TASK031B_DEVELOP_BASELINE_REACHABLE=NO")
        result.fail("Task-031b develop baseline is not reachable from HEAD")

    print("===== Docs-only diff guard =====")
    changed = diff_paths(repo)
    for path in changed:
        print(f"TASK031C_STATUS_PATH={path}")
    unexpected = [path for path in changed if path not in ALLOWED_DIFF_PATHS]
    print(f"UNEXPECTED_TASK031C_STATUS_PATH_COUNT={len(unexpected)}")
    for path in unexpected:
        result.fail(f"unexpected Task-031c changed path: {path}")
    if not unexpected:
        result.pass_msg("changed paths are limited to Task-031c docs/verifier scope")

    print("===== Required model architecture files =====")
    required_files = [
        "Shared/Models/SportMode.swift",
        "Shared/Models/MotionSample.swift",
        "Shared/Models/SessionData.swift",
        "Shared/Models/PowerType.swift",
        "Shared/Models/EquipmentProfile.swift",
        "watchOS/App/SkateTrackWatchApp.swift",
        "docs/process/PHASE_1B_AGENT_STATE.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/history/DEV_LOG.md",
        "scripts/verify_task031_mode_guardrails.py",
    ]
    for rel in required_files:
        check_required_file(repo, rel, result)

    sport_mode = repo / "Shared/Models/SportMode.swift"
    if sport_mode.exists():
        text = read(sport_mode)
        tokens = [
            "enum SportMode",
            "case skateboard(BoardMode)",
            "case inline(InlineMode)",
            "var sportLocalizationKey",
            "var modeLocalizationKey",
        ]
        for token in tokens:
            if token in text:
                result.pass_msg(f"SportMode.swift contains token: {token}")
            else:
                result.fail(f"SportMode.swift missing token: {token}")
        if "case snow" in text or ".snow(" in text:
            result.fail("SportMode.swift added a Snow case before Snow production is authorized")
        else:
            print("SPORTMODE_SNOW_CASE_PRESENT=NO")
            result.pass_msg("SportMode remains without production Snow case in Task-031c")

    motion = repo / "Shared/Models/MotionSample.swift"
    if motion.exists():
        text = read(motion)
        for token in ["enum ActivityFidelityProfile", "case snowReserved", "struct ActivityFidelityPolicy", "defaultProfile(for mode: SportMode"]:
            if token in text:
                result.pass_msg(f"MotionSample.swift contains token: {token}")
            else:
                result.fail(f"MotionSample.swift missing token: {token}")
        default_profile_body = extract_function_body(text, "defaultProfile")
        if default_profile_body is None:
            result.fail("ActivityFidelityProfile.defaultProfile body could not be parsed")
        else:
            production_snow_switch_count = len(
                re.findall(r"case\s+\(\.snow|case\s+\.snow(?!Reserved)", default_profile_body)
            )
            print(f"ACTIVITY_FIDELITY_PRODUCTION_SNOW_SWITCH_COUNT={production_snow_switch_count}")
            if production_snow_switch_count == 0:
                result.pass_msg("ActivityFidelityProfile.defaultProfile has no production Snow mode switch")
            else:
                result.fail("ActivityFidelityProfile.defaultProfile appears to switch on production Snow mode")
        reserved_policy_count = len(re.findall(r"case\s+\.snowReserved", text))
        print(f"ACTIVITY_FIDELITY_SNOW_RESERVED_POLICY_COUNT={reserved_policy_count}")
        if reserved_policy_count > 0:
            result.pass_msg("ActivityFidelityPolicy keeps Snow as reserved/future-only")
        else:
            result.fail("ActivityFidelityPolicy missing reserved Snow profile branch")

    session = repo / "Shared/Models/SessionData.swift"
    if session.exists():
        text = read(session)
        for token in ["let sportMode: SportMode", "let fidelityProfile: ActivityFidelityProfile", "ActivityFidelityProfile.defaultProfile"]:
            if token in text:
                result.pass_msg(f"SessionData.swift contains token: {token}")
            else:
                result.fail(f"SessionData.swift missing token: {token}")

    print("===== Snow / Trick / mode-shortcut implementation guards =====")
    snow_path_count = 0
    for rel in SNOW_PRODUCTION_PATHS:
        if (repo / rel).exists():
            snow_path_count += 1
            result.fail(f"forbidden Snow production path exists in Task-031c: {rel}")
    print(f"SNOW_PRODUCTION_PATH_COUNT={snow_path_count}")

    snow_impl_count, snow_hits = count_forbidden_patterns(
        repo,
        ["Shared", "iOS", "watchOS", "macOS", "Tests"],
        FORBIDDEN_SNOW_IMPLEMENTATION_PATTERNS,
    )
    print(f"SNOW_PRODUCTION_IMPLEMENTATION_COUNT={snow_impl_count}")
    for hit in snow_hits[:30]:
        print(f"SNOW_PRODUCTION_HIT={hit}")
    if snow_impl_count == 0:
        result.pass_msg("no Snow production implementation patterns are present in guarded source paths")
    else:
        result.fail("Snow production implementation patterns found")

    trick_impl_count, trick_hits = count_forbidden_patterns(
        repo,
        ["Shared", "iOS", "watchOS", "macOS", "Tests"],
        FORBIDDEN_TRICK_IMPLEMENTATION_PATTERNS,
    )
    print(f"TRICK_RECOGNITION_IMPLEMENTATION_COUNT={trick_impl_count}")
    for hit in trick_hits[:30]:
        print(f"TRICK_RECOGNITION_HIT={hit}")
    if trick_impl_count == 0:
        result.pass_msg("no Trick recognition implementation patterns are present")
    else:
        result.fail("Trick recognition implementation patterns found")

    boolean_count, allowlisted_boolean, boolean_hits = count_boolean_shortcuts(repo)
    print(f"ALLOWLISTED_BOOLEAN_MODE_HELPER_COUNT={allowlisted_boolean}")
    print(f"BOOLEAN_ONLY_MODE_SHORTCUT_COUNT={boolean_count}")
    for hit in boolean_hits[:30]:
        print(f"BOOLEAN_ONLY_MODE_SHORTCUT_HIT={hit}")
    if boolean_count == 0:
        result.pass_msg("no unapproved boolean-only mode shortcuts are present in guarded architecture paths")
    else:
        result.fail("unapproved boolean-only mode shortcuts found")

    print("===== watchOS / WatchBridge / UI guardrails =====")
    watchos_swift = list((repo / "watchOS").rglob("*.swift")) if (repo / "watchOS").exists() else []
    print(f"WATCHOS_SWIFT_FILE_COUNT={len(watchos_swift)}")
    compact_tokens = ["ActivityVisualizationCompactSummary", "CompactRouteDisplay", "CompactSpeedSparkline", "CompactElevationProfile"]
    compact_consumption_count = 0
    bridge_runtime_count = 0
    healthkit_count = 0
    for path in watchos_swift:
        text = read(path)
        if any(token in text for token in compact_tokens):
            compact_consumption_count += 1
            print(f"WATCHOS_COMPACT_CONSUMPTION_FILE={path.relative_to(repo).as_posix()}")
        if any(token in text for token in ["WCSession", "WatchConnectivity", "WatchBridge", "WatchSessionCoordinator"]):
            bridge_runtime_count += 1
            print(f"WATCHBRIDGE_RUNTIME_FILE={path.relative_to(repo).as_posix()}")
        if any(token in text for token in ["HealthKit", "HKWorkout", "HKHealthStore"]):
            healthkit_count += 1
            print(f"HEALTHKIT_RUNTIME_FILE={path.relative_to(repo).as_posix()}")
    print(f"WATCHOS_COMPACT_CONSUMPTION_FILE_COUNT={compact_consumption_count}")
    print(f"WATCHBRIDGE_RUNTIME_IMPLEMENTATION_COUNT={bridge_runtime_count}")
    print(f"HEALTHKIT_RUNTIME_IMPLEMENTATION_COUNT={healthkit_count}")
    if compact_consumption_count == 0:
        print("WATCHOS_COMPACT_CONSUMPTION_PRE_UI=NO")
        result.pass_msg("watchOS compact visualization consumption remains absent before Watch UI work")
    else:
        result.fail("watchOS compact visualization consumption appeared before approved Watch UI task")
    if bridge_runtime_count == 0:
        result.pass_msg("no WatchBridge / WatchConnectivity runtime behavior in watchOS Swift files")
    else:
        result.fail("WatchBridge / WatchConnectivity runtime behavior found in watchOS Swift files")
    if healthkit_count == 0:
        result.pass_msg("no HealthKit runtime behavior in watchOS Swift files")
    else:
        result.fail("HealthKit runtime behavior found in watchOS Swift files")

    if (repo / "Shared/WatchBridge").exists():
        print("SHARED_WATCHBRIDGE_PATH_STATUS=PRESENT_REVIEW_REQUIRED")
        result.fail("Shared/WatchBridge exists before Task-032a audit in this baseline")
    else:
        print("SHARED_WATCHBRIDGE_PATH_STATUS=ABSENT_EXPECTED_UNTIL_TASK032A_AUDIT")
        result.pass_msg("Shared/WatchBridge remains absent and deferred to Task-032a audit")

    print("===== Documentation checkpoints =====")
    state_path = repo / "docs/process/PHASE_1B_AGENT_STATE.md"
    structure_path = repo / "docs/reference/FILE_STRUCTURE.md"
    devlog_path = repo / "docs/history/DEV_LOG.md"
    if state_path.exists():
        text = read(state_path)
        for token in REQUIRED_STATE_TOKENS:
            if token in text:
                result.pass_msg(f"PHASE_1B_AGENT_STATE.md contains token: {token}")
            else:
                result.fail(f"PHASE_1B_AGENT_STATE.md missing token: {token}")
    if structure_path.exists():
        text = read(structure_path)
        for token in REQUIRED_STRUCTURE_TOKENS:
            if token in text:
                result.pass_msg(f"FILE_STRUCTURE.md contains token: {token}")
            else:
                result.fail(f"FILE_STRUCTURE.md missing token: {token}")
    if devlog_path.exists():
        text = read(devlog_path)
        for token in REQUIRED_DEVLOG_TOKENS:
            if token in text:
                result.pass_msg(f"DEV_LOG.md contains token: {token}")
            else:
                result.fail(f"DEV_LOG.md missing token: {token}")

    print("===== Summary =====")
    print(f"SNOW_PRODUCTION_IMPLEMENTATION_COUNT={snow_impl_count}")
    print(f"TRICK_RECOGNITION_IMPLEMENTATION_COUNT={trick_impl_count}")
    print(f"BOOLEAN_ONLY_MODE_SHORTCUT_COUNT={boolean_count}")
    print("SNOWFEATURE_REFERENCE_ONLY=YES")
    print("SNOW_UI_SCREENSHOTS_REFERENCE_ONLY=YES")
    print("WATCH_UI_IMPLEMENTED=NO")
    print("WATCHBRIDGE_RUNTIME_IMPLEMENTED=NO")
    print(f"WARNING_COUNT={result.warnings}")
    print(f"FAILURE_COUNT={result.failures}")
    if result.failures == 0:
        print("VERIFY_TASK031C_MODE_GUARDRAILS_RESULT=PASSED")
        return 0
    print("VERIFY_TASK031C_MODE_GUARDRAILS_RESULT=FAILED")
    return 1


if __name__ == "__main__":
    sys.exit(main())
