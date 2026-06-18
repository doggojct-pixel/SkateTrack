#!/usr/bin/env python3
"""Verify Snow-Task-008b backup compatibility boundary guardrails."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"[snow-task-008b] FAIL: {message}")
    sys.exit(1)


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        fail(f"missing required file: {rel}")
    return path.read_text(encoding="utf-8")


def require(rel: str, token: str, label: str | None = None) -> None:
    text = read(rel)
    if token not in text:
        fail(f"missing {label or token!r} in {rel}")


manifest = "Shared/Models/BackupPackageManifest.swift"
payload = "Shared/Models/BackupPackagePayload.swift"
preview = "Shared/Models/BackupRestorePreview.swift"
encoder = "iOS/Core/Sync/BackupPackageEncoder.swift"
decoder = "iOS/Core/Sync/BackupPackageDecoder.swift"
tests = "Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift"
macos_verify = "scripts/verify_snow_macos_viewer.py"
package_verify = "scripts/verify_snow_package_compatibility.py"

for rel in [manifest, payload, preview, encoder, decoder, tests, macos_verify, package_verify]:
    read(rel)

require(manifest, "static let currentSchemaVersion = 2", "backup schema version 2")
require(manifest, "supportedSchemaVersions", "supported backup schema versions")
require(manifest, "[1, 2]", "backup schema versions [1, 2]")
require(manifest, "supportedSchemaVersions.contains", "backup schema validation set")
require(manifest, "let snowSessions: Int?", "optional snowSessions count")
require(manifest, "snowSessions: Int? = nil", "legacy snowSessions count default")

require(payload, "struct SnowBackupSession", "SnowBackupSession model")
require(payload, 'currentSchemaVersion = "snow-backup-session-1.0"', "Snow backup session version")
require(payload, "let snowSessions: [SnowBackupSession]?", "optional snowSessions payload section")
require(payload, "snowSessions: [SnowBackupSession]? = nil", "legacy snowSessions payload default")
require(payload, "init?(snowState: SnowSessionState", "Snow state to backup payload boundary")
require(payload, "makeSnowSessionState()", "backup payload to Snow state boundary")
require(payload, "var isSnowAwareBackup", "Snow-aware backup helper")
for token in [
    "let runs: [SnowRun]",
    "let segments: [SnowSegment]",
    "let distanceBreakdown: SnowDistanceBreakdown",
    "let verticalMetrics: SnowVerticalMetrics",
]:
    require(payload, token)

require(preview, "let snowSessionCount: Int?", "restore preview Snow count")
require(preview, "var isSnowAwareBackup", "restore preview Snow-aware helper")
require(preview, "+ (snowSessionCount ?? 0)", "preview total count includes Snow sessions")

require(encoder, "let snowSessions: [SnowBackupSession]?", "encoder input Snow sessions")
require(encoder, "snowSessions: [SnowBackupSession]? = []", "new backups encode empty Snow array")
require(encoder, "snowSessions: input.snowSessions?.count", "manifest Snow count wiring")
require(encoder, "snowSessions: input.snowSessions", "payload Snow sessions wiring")

require(decoder, "BackupPackageManifest.supportedSchemaVersions.contains", "decoder schema 1/2 support")
require(decoder, "validateSnowSessions", "Snow session restore preview validation")
require(decoder, "snowSessionCount: payload.snowSessions?.count", "restore preview Snow count mapping")

for token in [
    "testDecodeBackupSchemaVersion1WithoutSnowSessionsSucceeds",
    "testEncodeBackupSchemaVersion2IncludesEmptySnowSessionsArray",
    "testDecodeBackupSchemaVersion2WithSnowSessionsSucceeds",
    "testDecodeBackupUnknownSchemaVersionFails",
    "makeBackupPayload",
]:
    require(tests, token)

require(macos_verify, "POST_007_ALLOWED_COMPATIBILITY_CHANGED_PATHS", "post-007 compatibility allowlist")
for token in [
    "Shared/Models/BackupPackageManifest.swift",
    "Shared/Models/BackupPackagePayload.swift",
    "Shared/Models/BackupRestorePreview.swift",
    "iOS/Core/Sync/BackupPackageEncoder.swift",
    "iOS/Core/Sync/BackupPackageDecoder.swift",
    "scripts/verify_snow_backup_compatibility.py",
]:
    require(macos_verify, token)

require(package_verify, "Snow-Task-008b is explicitly allowed to extend backup", "008a package verify post-008b compatibility note")

# 008b Step 2 adds a provider boundary only. It must remain iOS-scoped,
# DEBUG/mock/no-op capable, and must not import HealthKit until the future
# entitlement-backed implementation step.
health_files = [
    "iOS/Core/Health/SnowHealthExporting.swift",
    "iOS/Core/Health/DisabledSnowHealthExporter.swift",
    "iOS/Core/Health/MockSnowHealthExporter.swift",
]
for rel in health_files:
    read(rel)

require("iOS/Core/Health/SnowHealthExporting.swift", "protocol SnowHealthExporting", "Snow Health exporter protocol")
require("iOS/Core/Health/SnowHealthExporting.swift", "struct SnowHealthExportRequest", "Snow Health export request")
require("iOS/Core/Health/SnowHealthExporting.swift", "struct SnowHealthExportResult", "Snow Health export result")
require("iOS/Core/Health/SnowHealthExporting.swift", "enum SnowHealthExportStatus", "Snow Health export status")
require("iOS/Core/Health/SnowHealthExporting.swift", "func exportSnowSession", "Snow Health export function boundary")
require("iOS/Core/Health/DisabledSnowHealthExporter.swift", "struct DisabledSnowHealthExporter", "disabled Snow Health exporter")
require("iOS/Core/Health/DisabledSnowHealthExporter.swift", "status: .unavailable", "disabled exporter unavailable result")
require("iOS/Core/Health/MockSnowHealthExporter.swift", "#if DEBUG", "DEBUG-gated mock Snow Health exporter")
require("iOS/Core/Health/MockSnowHealthExporter.swift", "struct MockSnowHealthExporter", "mock Snow Health exporter")

for rel in health_files:
    text = read(rel)
    if "import HealthKit" in text:
        fail(f"008b Health provider boundary must not import HealthKit yet: {rel}")
    for forbidden in ["HKWorkout", "HKQuantitySample", "HKHealthStore"]:
        if forbidden in text:
            fail(f"008b Health provider boundary must not create HealthKit objects yet: {rel}")

for token in [
    "testDisabledSnowHealthExporterReturnsUnavailableWithoutHealthKit",
    "testMockSnowHealthExporterPreparesExportInDebug",
    "makeSnowHealthExportRequest",
]:
    require(tests, token)

project = read("SkateTrack.xcodeproj/project.pbxproj")
for token in [
    "SnowHealthExporting.swift",
    "DisabledSnowHealthExporter.swift",
    "MockSnowHealthExporter.swift",
    "SnowHealthExporting.swift in Sources",
    "DisabledSnowHealthExporter.swift in Sources",
    "MockSnowHealthExporter.swift in Sources",
]:
    if token not in project:
        fail(f"missing iOS Health provider project membership token: {token}")

# Guard against unrelated high-risk scope creep.
for rel in [
    "Shared/Models/SnowSegment.swift",
    "Shared/Models/SnowRun.swift",
    "Shared/Models/SnowDistanceBreakdown.swift",
    "Shared/Models/SnowVerticalMetrics.swift",
    "Shared/Models/SnowSessionState.swift",
    "Shared/Models/MotionSample.swift",
]:
    text = read(rel)
    if "snow-backup-session-1.0" in text or "SnowBackupSession" in text:
        fail(f"008b backup compatibility must not modify core Snow value model: {rel}")

for path in (ROOT / "Shared").rglob("*.swift"):
    if "import HealthKit" in path.read_text(encoding="utf-8"):
        fail(f"Shared must not import HealthKit: {path.relative_to(ROOT)}")

for scan_root in ["Shared/Models", "iOS/Core/Sync", "iOS/Core/Export", "macOS/Core/Snow", "macOS/Features/Import"]:
    root_path = ROOT / scan_root
    if not root_path.exists():
        continue
    for path in root_path.rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        rel = path.relative_to(ROOT)
        for forbidden in ["SnowPrototype", "MacSnowPrototype", "WatchConnectivity", "WCSession", "WatchBridge"]:
            if forbidden in text:
                fail(f"forbidden token {forbidden!r} found in {rel}")

for path in ROOT.rglob("*.skatetrack"):
    if ".git" not in path.parts:
        fail(f"do not commit .skatetrack fixtures: {path.relative_to(ROOT)}")


# Final 008b docs and review-pack requirements.
for rel in [
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/DOCUMENTATION_INDEX.md",
    "scripts/create_snow_task008b_review_pack.sh",
]:
    read(rel)

require("docs/process/PHASE_1C_SNOW_AGENT_STATE.md", "Snow-Task-008b Backup Compatibility and Health Provider Boundary", "008b agent-state documentation")
require("docs/history/DEV_LOG.md", "Snow-Task-008b backup compatibility and Health provider boundary", "008b dev log entry")
require("docs/reference/FILE_STRUCTURE.md", "Snow-Task-008b Backup / Health Boundary Files", "008b file structure section")
require("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", "Snow-Task-008b Health provider boundary limitation", "008b Health limitation note")
require("docs/release/MANUAL_QA_MATRIX_PRE_ADP.md", "Snow-Task-008b Backup / Health Boundary QA", "008b manual QA note")
require("docs/DOCUMENTATION_INDEX.md", "Snow-Task-008b Backup Compatibility and Health Boundary", "008b documentation index entry")
require("scripts/create_snow_task008b_review_pack.sh", "SnowTask008b_ReviewPack", "008b review pack output name")
require("scripts/create_snow_task008b_review_pack.sh", "SAFETY_CHECK_BACKUP_LEGACY_DECODE.txt", "008b backup safety check")
require("scripts/create_snow_task008b_review_pack.sh", "SAFETY_CHECK_HEALTH_PROVIDER_BOUNDARY.txt", "008b Health boundary safety check")
require("scripts/create_snow_task008b_review_pack.sh", "iOS/Core/Health/SnowHealthExporting.swift", "008b review pack Health source copy")
require("scripts/create_snow_task008b_review_pack.sh", "/Users/doggo/Documents/App軟體區/upload", "upload-dir review pack output")

print("[snow-task-008b] PASS: backup schema v2, schema 1/2 decode support, optional snowSessions section, SnowBackupSession model, encoder/decoder preview wiring, tests, and backup schema, Health provider boundary, documentation, review-pack script, and guardrails are present.")
