#!/usr/bin/env python3
"""Verify Task-030c-b11-r3-3 diagnostics persistence across Core Data save/fetch/export."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SessionData.swift",
    "Shared/Persistence/SessionEntityMapper.swift",
    "Shared/Persistence/PersistenceController.swift",
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Features/Debug/DebugToolsPanelView.swift",
    "Tests/iOSTests/SessionRepositoryTests.swift",
    "scripts/verify_task030c_diagnostics_persistence.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/adr/ADR-INDEX.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_TOKENS = {
    "Shared/Models/SessionData.swift": [
        "static let currentDebugBuildTaskID = \"Task-030c-b13-B-1\"",
        "let diagnosticsStatus: String?",
    ],
    "Shared/Persistence/SessionEntityMapper.swift": [
        "debugRecordingDiagnosticsData",
        "try session.debugRecordingDiagnostics.map { try encode($0) }",
        "decode(RecordingDebugDiagnostics.self",
        "debugRecordingDiagnostics:",
    ],
    "Shared/Persistence/PersistenceController.swift": [
        "binaryAttribute(\"debugRecordingDiagnosticsData\", optional: true)",
        "description.shouldMigrateStoreAutomatically = true",
        "description.shouldInferMappingModelAutomatically = true",
    ],
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents": [
        "debugRecordingDiagnosticsData",
        "attributeType=\"Binary\"",
    ],
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift": [
        "sessionWithDiagnosticsFallback",
        "missingFromPersistedSession",
        "let exportSession = try sessionWithDiagnosticsFallback(content.session)",
        "packageFormatCapabilities(for: effectiveSamples, session: exportSession)",
        "debug-build-identity-v1",
        "diagnostics-export-status-v1",
    ],
    "Tests/iOSTests/SessionRepositoryTests.swift": [
        "Task-030c-b11-r3-3",
        "debugRecordingDiagnostics?.buildIdentity.debugBuildTaskID",
        "debugRecordingDiagnostics?.diagnosticsStatus",
        "RecordingDebugDiagnostics(",
    ],
    "iOS/Features/Debug/DebugToolsPanelView.swift": [
        "Task-030c-b13-B-1",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030c-b11-r3-3",
        "Persist Diagnostics Through Session Export",
        "debugRecordingDiagnosticsData",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030c-b11-r3-3",
        "debugRecordingDiagnosticsData",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030c-b11-r3-3",
        "Core Data",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030c-b11-r3-3",
        "missingFromPersistedSession",
    ],
}

FORBIDDEN_TOKENS = [
    "MKDirections",
    "MKRoute",
    "GoogleMaps",
    "GIDSignIn",
    "CloudKit",
    "NSUbiquitousContainers",
    "StoreKit",
    "HealthKit",
]


def fail(message: str) -> None:
    print(f"Task-030c-b11-r3-3 diagnostics persistence check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def main() -> None:
    for path in REQUIRED_FILES:
        read(path)

    for path, tokens in REQUIRED_TOKENS.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"missing token {token!r} in {path}")

    mapper_text = read("Shared/Persistence/SessionEntityMapper.swift")
    if mapper_text.count("debugRecordingDiagnosticsData") < 2:
        fail("SessionEntityMapper must both write and read debugRecordingDiagnosticsData")

    export_text = read("iOS/Core/Export/SkateTrackPackageExportProvider.swift")
    if export_text.find("let exportSession = try sessionWithDiagnosticsFallback") > export_text.find("packageFormatCapabilities"):
        fail("exportSession fallback must be created before packageFormatCapabilities is evaluated")

    combined = "\n".join(
        read(path)
        for path in [
            "Shared/Models/SessionData.swift",
            "Shared/Persistence/SessionEntityMapper.swift",
            "Shared/Persistence/PersistenceController.swift",
            "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
        ]
    )
    for token in FORBIDDEN_TOKENS:
        if token in combined:
            fail(f"unexpected production integration token found: {token}")

    print("Task-030c-b11-r3-3 diagnostics persistence checks passed.")


if __name__ == "__main__":
    main()
