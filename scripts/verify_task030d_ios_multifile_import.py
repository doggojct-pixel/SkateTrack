#!/usr/bin/env python3
"""Verify Task-030d iOS multi-file .skatetrack import foundation scope."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/Import/SkateTrackPackageImportModels.swift",
    "iOS/Core/Import/SkateTrackPackageImportCoordinator.swift",
    "iOS/Hooks/useSkateTrackPackageImport.swift",
    "iOS/Features/SessionHistory/SessionHistoryImportEntryView.swift",
    "iOS/Features/SessionImport/SessionImportPreviewView.swift",
    "iOS/Features/SessionImport/SessionImportCandidateRowView.swift",
    "Tests/iOSTests/SkateTrackPackageImportTests.swift",
    "scripts/verify_task030d_ios_multifile_import.py",
]

LOCALIZATION_FILES = [
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
]

LOCALIZATION_KEYS = [
    "history.import.button",
    "import.title",
    "import.subtitle",
    "import.preview.title",
    "import.preview.totalFiles",
    "import.preview.readyFiles",
    "import.preview.attentionFiles",
    "import.action.importSelected",
    "import.confirm.title",
    "import.status.ready",
    "import.status.alreadyImported",
    "import.status.duplicateCandidate",
    "import.status.unsupportedVersion",
    "import.status.corruptedPackage",
    "import.status.invalidManifest",
    "import.status.blocked",
    "import.error.securityScopedAccessFailed",
    "import.error.stagingCopyFailed",
    "import.error.commitFailed",
    "import.commit.status.imported",
    "import.accessibility.fileRowFormat",
]

PROJECT_TOKENS = [
    "SkateTrackPackageImportModels.swift",
    "SkateTrackPackageImportCoordinator.swift",
    "useSkateTrackPackageImport.swift",
    "SessionHistoryImportEntryView.swift",
    "SessionImportPreviewView.swift",
    "SessionImportCandidateRowView.swift",
    "SkateTrackPackageImportTests.swift",
]

FORBIDDEN_PATH_FRAGMENTS = [
    "watchOS/",
    "WatchBridge",
    "Task-031",
    "Task-030e",
]

FORBIDDEN_NEW_SOURCE_TOKENS = [
    "estimatedRouteDisplayEnabled = true",
    "generalUserEstimatedRouteDisplayAllowed = true",
    "estimatedRouteActive = true",
    "routeGeometryMutationApplied = true",
    "trustedMetricsMutationApplied = true",
    "schemaMutationApplied = true",
    "GoogleSignIn",
    "GIDSignIn",
    "CloudKit",
    "CKContainer",
    "UTExportedTypeDeclarations",
    "com.apple.developer",
]

REQUIRED_SOURCE_TOKENS = [
    ("iOS/Features/SessionHistory/SessionHistoryView.swift", "SessionHistoryImportEntryView"),
    ("iOS/Features/SessionHistory/SessionHistoryImportEntryView.swift", "allowsMultipleSelection: true"),
    ("iOS/Core/Import/SkateTrackPackageImportCoordinator.swift", "startAccessingSecurityScopedResource"),
    ("iOS/Core/Import/SkateTrackPackageImportCoordinator.swift", "saveCompletedSession"),
    ("iOS/Core/Import/SkateTrackPackageImportCoordinator.swift", "sessionExists"),
    ("iOS/Core/Import/SkateTrackPackageImportCoordinator.swift", "SkateTrackPackageReader"),
    ("iOS/Hooks/useSkateTrackPackageImport.swift", "selectedCandidateIDs"),
    ("iOS/Features/SessionImport/SessionImportPreviewView.swift", "confirmationDialog"),
]

DOC_TOKENS = [
    "Task-030d",
    "iOS multi-file .skatetrack import",
    "no silent overwrite",
    "no route geometry mutation",
]

SWIFT_HEADER_RE = re.compile(r"\A// \[(協作區|自主區)")


def fail(message: str) -> None:
    print(f"Task-030d import check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_required_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).is_file()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_swift_headers_and_line_counts() -> None:
    for path in REQUIRED_FILES:
        if not path.endswith(".swift"):
            continue
        text = read(path)
        if not SWIFT_HEADER_RE.search(text) and not path.startswith("Tests/"):
            fail(f"Swift file missing collaboration header: {path}")
        line_count = len(text.splitlines())
        if line_count > 500:
            fail(f"Swift file exceeds 500-line hard limit: {path} has {line_count} lines")


def ensure_localization() -> None:
    for loc_path in LOCALIZATION_FILES:
        text = read(loc_path)
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {loc_path}")


def ensure_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"missing project membership token: {token}")
    for forbidden in ["UTExportedTypeDeclarations", "com.apple.developer"]:
        if forbidden in project:
            fail(f"project should not add capabilities or document associations: {forbidden}")


def ensure_source_tokens() -> None:
    for path, token in REQUIRED_SOURCE_TOKENS:
        if token not in read(path):
            fail(f"{path} missing required token {token!r}")


def ensure_forbidden_tokens_absent() -> None:
    checked = [
        path for path in REQUIRED_FILES
        if path != "scripts/verify_task030d_ios_multifile_import.py"
    ] + [
        "iOS/Features/SessionHistory/SessionHistoryView.swift",
        "SkateTrack.xcodeproj/project.pbxproj",
    ]
    for path in checked:
        text = read(path)
        for token in FORBIDDEN_NEW_SOURCE_TOKENS:
            if token in text:
                fail(f"forbidden token {token!r} found in {path}")
        for fragment in FORBIDDEN_PATH_FRAGMENTS:
            if fragment in path:
                fail(f"forbidden path fragment {fragment!r} in changed import scope")


def ensure_docs() -> None:
    doc_text = "\n".join(
        read(path)
        for path in [
            "docs/history/DEV_LOG.md",
            "docs/reference/FILE_STRUCTURE.md",
            "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
        ]
    )
    for token in DOC_TOKENS:
        if token not in doc_text:
            fail(f"documentation missing token: {token}")


def main() -> int:
    ensure_required_files()
    ensure_swift_headers_and_line_counts()
    ensure_localization()
    ensure_project_membership()
    ensure_source_tokens()
    ensure_forbidden_tokens_absent()
    ensure_docs()
    print("Task-030d iOS multi-file .skatetrack import check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
