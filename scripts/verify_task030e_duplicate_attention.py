#!/usr/bin/env python3
"""Verify Task-030e-009 macOS duplicate / attention states."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacPackageAttentionState.swift",
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_task030e_duplicate_attention.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]

CHECKED_SWIFT_FILES = [
    "macOS/Features/SessionBrowser/MacPackageAttentionState.swift",
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
]

ATTENTION_STATE_TOKENS = [
    "struct MacPackageAttentionWarning: Identifiable, Equatable",
    "case duplicateFilePath",
    "case duplicatePackageIdentifier",
    "case duplicateSessionIdentifier",
    "struct MacPackageAttentionSummary: Equatable",
    "enum MacPackageAttentionClassifier",
    "classifiedPreviews(from previews: [MacPackageImportPreview])",
    "uniquePreviewsByPath",
    "duplicateSessionIdentifiers(in:",
    "packageIdentifierCandidate(for preview: MacPackageImportPreview) -> String?",
    "SkateTrackPackageManifest v1 currently has no dedicated package identifier",
    "replacingAttentionWarnings",
]

SUMMARY_VIEW_TOKENS = [
    "struct MacPackageAttentionSummaryView: View",
    "mac.viewer.attention.title",
    "mac.viewer.attention.message.format",
    "mac.viewer.attention.readonly",
    "mac.viewer.attention.summary.duplicate_file.format",
    "mac.viewer.attention.summary.duplicate_package.format",
    "mac.viewer.attention.summary.duplicate_session.format",
    "mac.accessibility.attention_summary.label",
]

CARD_TOKENS = [
    "package.hasAttentionWarnings",
    "attentionSection",
    "mac.viewer.attention.card.badge",
    "warning.titleKey",
    "Color.orange.opacity",
]

BROWSER_TOKENS = [
    "MacPackageAttentionSummaryView(summary: viewModel.attentionSummary)",
]

STATE_TOKENS = [
    "var attentionSummary: MacPackageAttentionSummary",
    "MacPackageAttentionClassifier.classifiedPreviews(from: packages)",
    "MacPackageAttentionClassifier.classifiedPreviews(from: previews)",
    "mutating func mergeOpenedPreviews(_ previews: [MacPackageImportPreview])",
    "let combinedPreviews = packages + previews",
    "normalizedPath(for: previews[0].fileURL)",
]

VIEW_MODEL_TOKENS = [
    "let attentionWarnings: [MacPackageAttentionWarning]",
    "attentionWarnings: [MacPackageAttentionWarning] = []",
    "var attentionSummary: MacPackageAttentionSummary",
    "nextState.mergeOpenedPreviews(result.previews)",
]

STALE_REPLACEMENT_TOKENS = [
    "nextState.replace(with: result.previews)",
]

PROJECT_TOKENS = [
    "MacPackageAttentionState.swift",
    "MacPackageAttentionState.swift in Sources",
    "MacPackageAttentionSummaryView.swift",
    "MacPackageAttentionSummaryView.swift in Sources",
]

LOCALIZATION_KEYS = [
    "mac.viewer.attention.title",
    "mac.viewer.attention.message.format",
    "mac.viewer.attention.readonly",
    "mac.viewer.attention.summary.duplicate_file.format",
    "mac.viewer.attention.summary.duplicate_package.format",
    "mac.viewer.attention.summary.duplicate_session.format",
    "mac.viewer.attention.card.badge",
    "mac.viewer.attention.duplicate_file.title",
    "mac.viewer.attention.duplicate_file.detail",
    "mac.viewer.attention.duplicate_package.title",
    "mac.viewer.attention.duplicate_package.detail",
    "mac.viewer.attention.duplicate_session.title",
    "mac.viewer.attention.duplicate_session.detail",
    "mac.accessibility.attention_summary.label",
    "mac.accessibility.attention_summary.hint",
]

DOC_TOKENS = [
    "Task-030e-MacViewer-009 Duplicate and Attention States",
    "MacPackageAttentionState",
    "MacPackageAttentionSummaryView",
    "exact duplicate file path warnings",
    "duplicate session identifier warnings",
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
    print(f"Task-030e-009 duplicate / attention check failed: {message}", file=sys.stderr)
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


def ensure_project_membership(project: str) -> None:
    require("project.pbxproj", project, PROJECT_TOKENS)
    mac_sources = re.search(r"A2EF5573281ED5113A3645DD /\* Sources \*/ = \{.*?files = \((.*?)\);", project, re.S)
    if not mac_sources:
        fail("could not locate macOS Sources build phase")
    sources = mac_sources.group(1)
    for source in ["MacPackageAttentionState.swift in Sources", "MacPackageAttentionSummaryView.swift in Sources"]:
        if source not in sources:
            fail(f"macOS Sources build phase missing {source}")


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
    cards = read("macOS/Features/SessionBrowser/MacPackageCardListView.swift")
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    state = read("macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift")
    view_model = read("macOS/Features/Import/MacPackageImportViewModel.swift")
    project = read("SkateTrack.xcodeproj/project.pbxproj")

    require("MacPackageAttentionState.swift", attention_state, ATTENTION_STATE_TOKENS)
    require("MacPackageAttentionSummaryView.swift", summary_view, SUMMARY_VIEW_TOKENS)
    require("MacPackageCardListView.swift", cards, CARD_TOKENS)
    require("MacSessionBrowserView.swift", browser, BROWSER_TOKENS)
    require("MacMultiPackageViewerState.swift", state, STATE_TOKENS)
    require("MacPackageImportViewModel.swift", view_model, VIEW_MODEL_TOKENS)
    reject("MacPackageImportViewModel.swift", view_model, STALE_REPLACEMENT_TOKENS)
    ensure_project_membership(project)
    ensure_swift_headers_and_line_counts()
    ensure_localization()

    docs = "\n".join(read(path) for path in ["docs/history/DEV_LOG.md", "docs/reference/FILE_STRUCTURE.md"])
    require("docs", docs, DOC_TOKENS)

    for rel in CHECKED_SWIFT_FILES:
        reject(rel, read(rel), FORBIDDEN_TOKENS)
    reject("project.pbxproj", project, ["UTExportedTypeDeclarations", "CFBundleDocumentTypes", "LSSupportsOpeningDocumentsInPlace"])

    print("Task-030e-009 duplicate / attention check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
