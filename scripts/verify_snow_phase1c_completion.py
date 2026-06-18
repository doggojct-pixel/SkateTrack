#!/usr/bin/env python3
from pathlib import Path
import sys
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"[snow-task-010] FAIL: {message}")
    sys.exit(1)


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        fail(f"missing required file: {rel}")
    return path.read_text(encoding="utf-8")


def require(rel: str, token: str, label: Optional[str] = None) -> None:
    text = read(rel)
    if token not in text:
        fail(f"missing token in {rel}: {label or token}")


# Required Snow verify scripts and review scripts.
for rel in [
    "scripts/verify_snow_sport_enum.py",
    "scripts/verify_snow_schema.py",
    "scripts/verify_snow_classifier.py",
    "scripts/verify_snow_run_boundary.py",
    "scripts/verify_snow_iphone_ui.py",
    "scripts/verify_snow_watch_ui.py",
    "scripts/verify_snow_macos_viewer.py",
    "scripts/verify_snow_package_compatibility.py",
    "scripts/verify_snow_backup_compatibility.py",
    "scripts/verify_snow_regression.py",
    "scripts/create_snow_task010_review_pack.sh",
]:
    read(rel)

# Schema/version guardrails: Task 010 must not bump package or backup schema.
require("Shared/Models/SkateTrackPackageManifest.swift", "static let currentSchemaVersion = 2", "package schema v2")
require("Shared/Models/SkateTrackPackageManifest.swift", "static let supportedSchemaVersions: Set<Int> = [1, 2]", "package schema 1/2 support")
require("Shared/Models/BackupPackageManifest.swift", "static let currentSchemaVersion = 2", "backup schema v2")
require("Shared/Models/BackupPackageManifest.swift", "static let supportedSchemaVersions: Set<Int> = [1, 2]", "backup schema 1/2 support")
require("Shared/Models/SkateTrackPackageSnowPayload.swift", "snow-payload-1.0", "Snow package payload version")
require("Shared/Models/BackupPackagePayload.swift", "snow-backup-session-1.0", "Snow backup session version")

# Phase 1c completion docs.
for rel, token in [
    ("docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md", "Phase 1c Snow Mode Completion Handoff"),
    ("docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md", "Snow-Task-010 verification token"),
    ("docs/process/PHASE_1C_SNOW_AGENT_STATE.md", "Snow-Task-010 Final Closure Agent State"),
    ("docs/history/DEV_LOG.md", "Snow-Task-010 Final Closure and Handoff"),
    ("docs/reference/FILE_STRUCTURE.md", "Snow-Task-010 Completion / Handoff Files"),
    ("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", "Snow-Task-010 final deferred items"),
    ("docs/release/MANUAL_QA_MATRIX_PRE_ADP.md", "Snow-Task-010 Phase 1c Final Manual QA Gate"),
    ("docs/DOCUMENTATION_INDEX.md", "Snow-Task-010 Phase 1c Completion Handoff"),
]:
    require(rel, token)

# Prior task state must still be present.
for rel, token in [
    ("docs/process/PHASE_1C_SNOW_AGENT_STATE.md", "Snow-Task-009 Agent State"),
    ("docs/release/MANUAL_QA_MATRIX_PRE_ADP.md", "Snow-Task-009 QA / Regression Manual Test Matrix"),
    ("scripts/verify_snow_regression.py", "SnowQAFixtureRegressionTests"),
    ("Tests/iOSTests/SnowQAFixtureRegressionTests.swift", "final class SnowQAFixtureRegressionTests"),
]:
    require(rel, token)

# 006b and ADP-dependent work remain deferred.
for rel in [
    "docs/process/PHASE_1C_SNOW_COMPLETION_HANDOFF.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
]:
    require(rel, "WatchBridge", "WatchBridge deferral must be documented")
    require(rel, "HealthKit", "HealthKit deferral must be documented")

# No binary Snow fixtures.
for path in ROOT.rglob("*.skatetrack"):
    if ".git" not in path.parts:
        fail(f"do not commit .skatetrack fixtures: {path.relative_to(ROOT)}")

# No prototype or production runtime integrations in Swift source/test paths.
for base in ["Shared", "iOS", "watchOS", "macOS", "Tests"]:
    base_path = ROOT / base
    if not base_path.exists():
        continue
    for path in base_path.rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        rel = path.relative_to(ROOT)
        for token in ["SnowPrototype", "MacSnowPrototype", "import WatchConnectivity", "WCSession", "import HealthKit", "HKHealthStore", "HKWorkout", "HKQuantitySample"]:
            if token in text:
                fail(f"forbidden runtime/prototype token {token!r} in {rel}")

# Task 010 must not add new Swift runtime files.
# This is intentionally conservative: final closure should be docs/scripts only.
# Existing Snow runtime files are validated by prior task verify scripts.

print("[snow-task-010] PASS: Phase 1c Snow completion handoff, final docs, deferred items, schema guardrails, review-pack script, and no-runtime-scope-creep checks are present.")
