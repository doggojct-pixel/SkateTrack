#!/usr/bin/env python3
"""Verify Task-030e-009-1 duplicate attention acknowledgement."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacPackageAttentionState.swift",
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task030e_duplicate_acknowledgement.py",
    "scripts/verify_task030e_duplicate_attention.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]

CHECKED_SWIFT_FILES = [
    "macOS/Features/SessionBrowser/MacPackageAttentionState.swift",
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
]

STATE_TOKENS = [
    "private(set) var acknowledgedDuplicateFilePaths: Set<String>",
    "acknowledgedDuplicateFilePaths: Set<String> = []",
    "var hasAcknowledgeableDuplicateFilePathWarnings: Bool",
    "acknowledgedDuplicateFilePaths.subtract(reopenedPaths)",
    "mutating func acknowledgeDuplicateFilePathWarnings()",
    "acknowledgedDuplicateFilePaths.formUnion(duplicatePaths)",
    "acknowledgedDuplicateFilePaths.removeAll()",
    "pruneAcknowledgedDuplicateFilePaths()",
    "acknowledgedDuplicateFilePaths: acknowledgedDuplicateFilePaths",
]

CLASSIFIER_TOKENS = [
    "static func classifiedPreviews(",
    "acknowledgedDuplicateFilePaths: Set<String> = []",
    "!acknowledgedDuplicateFilePaths.contains(normalizedPath)",
]

VIEW_MODEL_TOKENS = [
    "var hasAcknowledgeableDuplicateFilePathWarnings: Bool",
    "func acknowledgeDuplicateFilePathWarnings()",
    "nextState.acknowledgeDuplicateFilePathWarnings()",
]

SUMMARY_VIEW_TOKENS = [
    "let canAcknowledgeDuplicateFiles: Bool",
    "let acknowledgeDuplicateFilesAction: () -> Void",
    "Button(action: acknowledgeDuplicateFilesAction)",
    "mac.viewer.attention.acknowledge_duplicate_files",
    "checkmark.circle.fill",
    ".background(.orange.opacity(0.24), in: Capsule())",
    ".stroke(.orange.opacity(0.58), lineWidth: 1)",
    ".buttonStyle(.plain)",
    "mac-attention-acknowledge-duplicate-files-button",
]

BROWSER_TOKENS = [
    "canAcknowledgeDuplicateFiles: viewModel.hasAcknowledgeableDuplicateFilePathWarnings",
    "acknowledgeDuplicateFilesAction: viewModel.acknowledgeDuplicateFilePathWarnings",
]

LOCALIZATION_KEYS = [
    "mac.viewer.attention.acknowledge_duplicate_files",
]

DOC_TOKENS = [
    "Task-030e-MacViewer-009-1 Duplicate Attention Acknowledgement",
    "acknowledgeDuplicateFilePathWarnings",
    "acknowledgedDuplicateFilePaths",
    "transient duplicate file path warning acknowledgement",
    "no merge",
    "no delete",
    "no winner selection",
    "no local history import",
]

FORBIDDEN_TOKENS = [
    "SessionRepository",
    "PersistenceController",
    "NSManagedObjectContext",
    "CoreData",
    "SkateTrackPackageWriter",
    "commitImport",
    "importSelected",
    "mergePackages",
    "resolveDuplicate",
    "pickWinner",
    "deleteDuplicate",
    "removeDuplicatePackage",
    "snapToRoad",
    "roadMatch",
    "mapMatch",
    "reconstructRoute",
    "mutateRouteGeometry",
    "routeGeometryMutationApplied = true",
    "trustedMetricsMutationApplied = true",
    "estimatedRouteDisplayEnabled = true",
    "showsUserLocation = true",
    "requestWhenInUseAuthorization",
    "CLLocationManager",
]


def fail(message: str) -> None:
    print(f"Task-030e-009-1 duplicate acknowledgement check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        fail(f"missing required file: {rel}")
    return path.read_text(encoding="utf-8")


def require(name: str, text: str, tokens: list[str]) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        fail(f"{name} missing token(s): " + ", ".join(missing))


def reject(name: str, text: str, tokens: list[str]) -> None:
    present = [token for token in tokens if token in text]
    if present:
        fail(f"{name} contains forbidden token(s): " + ", ".join(present))


def ensure_files() -> None:
    missing = [rel for rel in REQUIRED_FILES if not (ROOT / rel).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_swift_headers_and_line_counts() -> None:
    for rel in CHECKED_SWIFT_FILES:
        text = read(rel)
        lines = text.splitlines()
        valid_headers = {
            "// [協作區] " + Path(rel).name,
            "// [協作區] " + rel,
            "// [自主區] " + Path(rel).name,
            "// [自主區] " + rel,
        }
        if not lines or lines[0] not in valid_headers:
            fail(f"{rel} missing collaboration/autonomous header on first line")
        if len(lines) > 500:
            fail(f"{rel} exceeds 500 lines: {len(lines)}")


def ensure_localization() -> None:
    for lang in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}" = ' not in text:
                fail(f"missing localization key {key} in {lang}")


def main() -> int:
    ensure_files()
    attention_state = read("macOS/Features/SessionBrowser/MacPackageAttentionState.swift")
    summary_view = read("macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift")
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    state = read("macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift")
    view_model = read("macOS/Features/Import/MacPackageImportViewModel.swift")

    require("MacPackageAttentionState.swift", attention_state, CLASSIFIER_TOKENS)
    require("MacMultiPackageViewerState.swift", state, STATE_TOKENS)
    require("MacPackageImportViewModel.swift", view_model, VIEW_MODEL_TOKENS)
    require("MacPackageAttentionSummaryView.swift", summary_view, SUMMARY_VIEW_TOKENS)
    require("MacSessionBrowserView.swift", browser, BROWSER_TOKENS)
    ensure_swift_headers_and_line_counts()
    ensure_localization()

    docs = "\n".join(read(path) for path in ["docs/history/DEV_LOG.md", "docs/reference/FILE_STRUCTURE.md"])
    require("docs", docs, DOC_TOKENS)

    for rel in CHECKED_SWIFT_FILES:
        reject(rel, read(rel), FORBIDDEN_TOKENS)

    print("Task-030e-009-1 duplicate acknowledgement check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
