#!/usr/bin/env python3
"""Verify Snow-Task-008a package schema boundary guardrails."""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"[snow-task-008a] FAIL: {message}")
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


def forbid(rel: str, token: str, label: str | None = None) -> None:
    text = read(rel)
    if token in text:
        fail(f"forbidden {label or token!r} in {rel}")


manifest = "Shared/Models/SkateTrackPackageManifest.swift"
payload = "Shared/Models/SkateTrackPackagePayload.swift"
snow_payload = "Shared/Models/SkateTrackPackageSnowPayload.swift"
reader = "Shared/Export/SkateTrackPackageReader.swift"
writer = "Shared/Export/SkateTrackPackageWriter.swift"
tests = "Tests/iOSTests/SkateTrackPackageSnowCompatibilityTests.swift"
export_provider = "iOS/Core/Export/SkateTrackPackageExportProvider.swift"
export_hook = "iOS/Hooks/useSkateTrackPackageExport.swift"
pbx = "SkateTrack.xcodeproj/project.pbxproj"
import_view_model = "macOS/Features/Import/MacPackageImportViewModel.swift"
import_preview = "macOS/Features/Import/MacPackagePreviewView.swift"
mac_snow_mapper = "macOS/Core/Snow/MacSnowSessionAnalysisMapper.swift"

for rel in [manifest, payload, snow_payload, reader, writer, tests, export_provider, export_hook, import_view_model, import_preview, mac_snow_mapper, pbx]:
    if not (ROOT / rel).exists():
        fail(f"missing required file: {rel}")

require(manifest, "static let currentSchemaVersion = 2", "schema version 2")
require(manifest, "supportedSchemaVersions", "supported schema versions")
require(manifest, "[1, 2]", "schema versions [1, 2]")
require(manifest, "let capabilities: [String]?", "optional capabilities")
require(manifest, "export-format and diagnostics features", "formatCapabilities semantic domain")
require(manifest, "Optional extension-payload features", "payload capabilities semantic domain")
require(manifest, "decodeIfPresent([String].self", "legacy capability decoding")
require(manifest, "supportedSchemaVersions.contains", "schema validation set")
require(manifest, "declaresSnowPackagePayload", "snow package capability helper")

require(snow_payload, "SkateTrackPackageSnowPayload", "Snow package payload type")
require(snow_payload, 'currentPayloadVersion = "snow-payload-1.0"', "package-specific snow payload version")
require(snow_payload, "SkateTrackPackageSnowCapability", "Snow package capability enum")
for token in [
    'snow-sports-v1',
    'snow-segments-v1',
    'snow-distance-breakdown-v1',
    'snow-lift-exclusion-v1',
    "let runs: [SnowRun]",
    "let segments: [SnowSegment]",
    "let distanceBreakdown: SnowDistanceBreakdown",
    "let verticalMetrics: SnowVerticalMetrics",
    "init?(snowState: SnowSessionState",
    "makeSnowSessionState()",
]:
    require(snow_payload, token)

require(payload, "let snowPayload: SkateTrackPackageSnowPayload?", "optional session snowPayload")
require(payload, "snowPayload: SkateTrackPackageSnowPayload? = nil", "nil default snowPayload")
require(payload, "var hasSnowPayload", "snowPayload helper")

require(export_provider, "func createExport(content: SessionSummaryContent) async throws", "async package export provider")
require(export_provider, "snowRepository: SnowSessionRepositoryProtocol", "SnowSessionRepository boundary injection")
require(export_provider, "makeSnowPayloadIfAvailable", "Snow payload availability boundary")
require(export_provider, "snowRepository.fetchState(sessionID: session.id)", "repository-backed Snow state lookup")
require(export_provider, "SkateTrackPackageSnowPayload(snowState: state", "repository state to package snow payload")
require(export_provider, "capabilities: snowPayload == nil ? nil : SkateTrackPackageSnowCapability.allRawValues", "Snow capabilities only when payload exists")
require(export_provider, "guard session.sportMode.isSnow else { return nil }", "non-Snow exports skip repository fetch")
require(export_hook, "try await provider.createExport(content: content)", "async export hook call")

require(mac_snow_mapper, "makeAvailabilityFromPackage", "package-backed Snow analysis mapper entry point")
require(mac_snow_mapper, "SkateTrackPackageSession", "package session mapper input")
require(mac_snow_mapper, "SkateTrackPackageSnowPayload?", "optional package snow payload mapper input")
require(mac_snow_mapper, "snowPayload.makeSnowSessionState()", "package payload to SnowSessionState conversion")
require(mac_snow_mapper, "source: .importedPackage", "imported package analysis source")
require(mac_snow_mapper, "snowPayloadSessionMismatch", "payload/session mismatch safety")
require(import_view_model, "var snowAnalysisAvailability: MacSnowAnalysisAvailability?", "import preview Snow availability")
require(import_view_model, "guard case .snow(_) = packageSession.session.sportMode else { return nil }", "Snow-only package viewer routing")
require(import_view_model, "MacSnowSessionAnalysisMapper.makeAvailabilityFromPackage", "import view model package mapper call")
require(import_preview, "MacSnowPackagePreviewRouteView", "Snow package preview route wrapper")
require(import_preview, "MacSnowRootView(viewModel: viewModel)", "direct MacSnowRootView package display")
require(import_preview, "preview.snowAnalysisAvailability", "Snow package preview availability routing")


for token in [
    "testDecodeSchemaVersion1PackageWithoutSnowFieldsSucceeds",
    "testDecodeSchemaVersion2PackageWithoutSnowPayloadSucceeds",
    "testDecodeSchemaVersion2PackageWithSnowPayloadSucceeds",
    "testFormatDiagnosticsAndSnowPayloadCapabilitiesRemainDisjoint",
    "testDecodeUnknownSchemaVersionFails",
    "testSnowPayloadInitializerRejectsEmptyStatePlaceholders",
    "testExportProviderOmitsSnowPayloadForNonSnowSession",
    "testExportProviderOmitsSnowPayloadForSnowSessionWithoutRepositoryState",
    "testExportProviderIncludesSnowPayloadForSnowSessionWithRepositoryState",
    "FakeSnowSessionRepository",
]:
    require(tests, token)

for token in [
    "SkateTrackPackageSnowPayload.swift",
    "SkateTrackPackageSnowCompatibilityTests.swift",
    "SkateTrackPackageSnowPayload.swift in Sources",
    "SkateTrackPackageSnowCompatibilityTests.swift in Sources",
]:
    require(pbx, token)

# Snow-Task-008a originally blocked backup/health work. After 008a is
# committed, Snow-Task-008b is explicitly allowed to extend backup
# compatibility. Health provider files remain outside the package step until
# the dedicated 008b Health boundary step.
for rel in [
    "Shared/Models/BackupPackageManifest.swift",
    "Shared/Models/BackupPackagePayload.swift",
    "iOS/Core/Sync/BackupPackageEncoder.swift",
    "iOS/Core/Sync/BackupPackageDecoder.swift",
]:
    if (ROOT / rel).exists():
        text = read(rel)
        if "SnowBackupSession" in text or "snowSessions" in text:
            continue

health_dir = ROOT / "iOS/Core/Health"
if health_dir.exists():
    for path in health_dir.rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        if "SnowHealth" in text and "import HealthKit" in text:
            fail(f"008b Health boundary must not import HealthKit yet: {path.relative_to(ROOT)}")
backup_verify = ROOT / "scripts/verify_snow_backup_compatibility.py"
if health_dir.exists() and any("SnowHealth" in path.read_text(encoding="utf-8") for path in health_dir.rglob("*.swift")):
    if not backup_verify.exists() or "SnowHealthExporting.swift" not in backup_verify.read_text(encoding="utf-8"):
        fail("008b Health boundary must be verified by verify_snow_backup_compatibility.py")

# Guard against prototype or WatchBridge / WatchConnectivity leakage in the touched package path.
production_scan_roots = ["Shared/Models", "Shared/Export", "iOS/Core/Export", "macOS/Core/Snow", "macOS/Features/Import"]
for scan_root in production_scan_roots:
    root_path = ROOT / scan_root
    if not root_path.exists():
        continue
    for path in root_path.rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        rel_path = path.relative_to(ROOT)
        for forbidden in ["SnowPrototype", "MacSnowPrototype"]:
            if forbidden in text:
                fail(f"production package compatibility must not reference {forbidden}: {rel_path}")
        if "WCSession" in text or "WatchConnectivity" in text:
            fail(f"008a must not add WatchBridge/WatchConnectivity scope: {rel_path}")

# HealthKit must not appear in Shared in this package step.
for path in (ROOT / "Shared").rglob("*.swift"):
    if "import HealthKit" in path.read_text(encoding="utf-8"):
        fail(f"Shared must not import HealthKit: {path.relative_to(ROOT)}")

# No committed package fixtures.
for path in ROOT.rglob("*.skatetrack"):
    if ".git" not in path.parts:
        fail(f"do not commit .skatetrack fixtures: {path.relative_to(ROOT)}")


# Documentation and review-pack script are part of the final 008a gate.
for rel in [
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/DOCUMENTATION_INDEX.md",
    "scripts/create_snow_task008a_review_pack.sh",
]:
    if not (ROOT / rel).exists():
        fail(f"missing required 008a documentation/review-pack file: {rel}")

for rel in [
    "docs/history/DEV_LOG.md",
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/DOCUMENTATION_INDEX.md",
]:
    require(rel, "Snow-Task-008a", "Snow-Task-008a documentation token")

require("scripts/create_snow_task008a_review_pack.sh", "/Users/doggo/Documents/App軟體區/upload", "upload output directory")
require("scripts/create_snow_task008a_review_pack.sh", "SnowTask008a_ReviewPack.zip", "008a review pack zip name")
require("scripts/create_snow_task008a_review_pack.sh", "SAFETY_CHECK_HEALTHKIT_IN_SHARED.txt", "HealthKit shared safety check")
require("scripts/create_snow_task008a_review_pack.sh", "makeAvailabilityFromPackage", "mapper source inclusion token")

print("[snow-task-008a] PASS: package schema v2, schema 1/2 decode boundary, optional capabilities, optional snowPayload, Snow payload model, iOS export provider wiring, macOS imported package viewer wiring, tests, macOS import wiring, documentation, review-pack script, project membership, and 008a scope guardrails are present.")
