#!/usr/bin/env python3
"""Verify Task-026c-blocked and Task-027a portable .skatetrack package boundaries."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Export/SkateTrackPackageWriter.swift",
    "Shared/Export/SkateTrackPackageReader.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Hooks/useSkateTrackPackageExport.swift",
    "iOS/Features/SessionSummary/SessionPackageExportActionView.swift",
    "scripts/verify_skatetrack_package.py",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/adr/ADR-INDEX.md",
]

FORBIDDEN_TOKENS = [
    "GoogleService-Info.plist",
    "GIDSignIn",
    "GoogleSignIn",
    "Drive API",
    "UTExportedTypeDeclarations",
    "com.apple.developer",
    "NSUbiquitousContainers",
    "CloudKit",
]

SHARED_EXPORT_FILES = [
    "Shared/Export/SkateTrackPackageWriter.swift",
    "Shared/Export/SkateTrackPackageReader.swift",
]

PACKAGE_SOURCES = [
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Export/SkateTrackPackageWriter.swift",
    "Shared/Export/SkateTrackPackageReader.swift",
    "iOS/Core/Export/SkateTrackPackageExportProvider.swift",
    "iOS/Hooks/useSkateTrackPackageExport.swift",
    "iOS/Features/SessionSummary/SessionPackageExportActionView.swift",
]

LOCALIZATION_KEYS = [
    "skatetrack.package.export.title",
    "skatetrack.package.export.button",
    "skatetrack.package.export.ready",
    "skatetrack.package.error.unsupported_schema",
    "skatetrack.package.error.account_data",
    "skatetrack.package.error.achievements",
]

PROJECT_MEMBERSHIP_TOKENS = [
    "SkateTrackPackageManifest.swift",
    "SkateTrackPackagePayload.swift",
    "SkateTrackPackageWriter.swift",
    "SkateTrackPackageReader.swift",
    "SkateTrackPackageExportProvider.swift",
    "useSkateTrackPackageExport.swift",
    "SessionPackageExportActionView.swift",
]


def fail(message: str) -> None:
    print(f"Task-027 package check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_package_schema() -> None:
    manifest = read("Shared/Models/SkateTrackPackageManifest.swift")
    payload = read("Shared/Models/SkateTrackPackagePayload.swift")
    for token in [
        "enum SkateTrackPackageType",
        "case export",
        "static let currentSchemaVersion = 1",
        "schemaVersion: Int",
        "includesAccountData",
        "includesAchievements",
        "static func validate",
    ]:
        if token not in manifest:
            fail(f"manifest missing token: {token}")
    for token in ["SkateTrackPackagePayload", "SkateTrackPackageSession", "SessionData", "MotionSample"]:
        if token not in payload:
            fail(f"payload missing token: {token}")
    for forbidden in ["Achievement", "WeeklyChallenge", "AuthSession", "AuthTokenStore", "GoogleSignIn"]:
        if re.search(rf"\b{re.escape(forbidden)}\b", payload):
            fail(f"portable payload should not include {forbidden}")


def ensure_shared_export_boundary() -> None:
    for path in SHARED_EXPORT_FILES:
        text = read(path)
        if "#if os(" in text or "#if canImport" in text:
            fail(f"Shared/Export must stay platform-neutral: {path}")
        if "temporaryDirectory" in text or "documentDirectory" in text or "NSOpenPanel" in text:
            fail(f"Shared/Export must not decide platform paths: {path}")
        if "UIKit" in text or "SwiftUI" in text or "AppKit" in text:
            fail(f"Shared/Export must not import UI frameworks: {path}")


def ensure_ios_boundary() -> None:
    provider = read("iOS/Core/Export/SkateTrackPackageExportProvider.swift")
    hook = read("iOS/Hooks/useSkateTrackPackageExport.swift")
    view = read("iOS/Features/SessionSummary/SessionPackageExportActionView.swift")
    summary = read("iOS/Features/SessionSummary/SessionSummaryShareStubView.swift")
    if "SkateTrackPackageWriter" not in provider or "temporaryDirectory" not in provider:
        fail("iOS provider must own temporary export path and delegate writing to Shared writer")
    if "SessionSummaryContent" not in hook or "SkateTrackPackageExportProvider" not in hook:
        fail("hook must expose package export through provider boundary")
    if "SessionShareSheetView" not in view:
        fail("package export UI must use existing system share sheet bridge")
    if "SessionPackageExportActionView(content: content)" not in summary:
        fail("Session summary share section must expose package export action")


def ensure_no_forbidden_services() -> None:
    checked_paths = PACKAGE_SOURCES + [
        "SkateTrack.xcodeproj/project.pbxproj",
        "docs/adr/ADR-INDEX.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]
    for path in checked_paths:
        text = read(path)
        for token in FORBIDDEN_TOKENS:
            if token not in text:
                continue
            if path.startswith("docs/"):
                # Documentation is expected to name deferred external services / capabilities
                # as long as source code and project settings do not enable them.
                continue
            fail(f"forbidden production/external-service token {token!r} found in {path}")


def ensure_localization() -> None:
    for lang in ["en.lproj", "zh-Hant.lproj"]:
        text = read(f"Shared/Localization/{lang}/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {lang}")


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_MEMBERSHIP_TOKENS:
        if token not in project:
            fail(f"missing project membership for {token}")
    if "UTExportedTypeDeclarations" in project or "com.apple.developer" in project:
        fail("project contains custom document type / entitlement changes in Task-027a context")


def ensure_docs() -> None:
    doc_text = "\n".join(
        read(path)
        for path in [
            "docs/history/DEV_LOG.md",
            "docs/reference/FILE_STRUCTURE.md",
            "docs/adr/ADR-INDEX.md",
            "docs/adr/ADR-INDEX.md",
            "docs/adr/ADR-INDEX.md",
            "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
        ]
    )
    for token in [
        "Task-026c-blocked",
        "Task-027a",
        "packageType = export",
        "custom UTType",
        "macOS Import Stub",
        "DisabledDriveProvider",
    ]:
        if token not in doc_text:
            fail(f"documentation missing token: {token}")


def main() -> int:
    ensure_files()
    ensure_package_schema()
    ensure_shared_export_boundary()
    ensure_ios_boundary()
    ensure_no_forbidden_services()
    ensure_localization()
    ensure_project_membership()
    ensure_docs()
    print("Task-027 package check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
