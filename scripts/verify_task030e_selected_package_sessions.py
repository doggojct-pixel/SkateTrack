#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-006 selected package sessions list."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacPackageSessionListView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "SkateTrack.xcodeproj/project.pbxproj",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_SESSION_LIST_TOKENS = [
    "// [協作區] macOS/Features/SessionBrowser/MacPackageSessionListView.swift",
    "struct MacPackageSessionListView: View",
    "let models: [MacSessionViewerModel]",
    "let selectedSessionID: UUID?",
    "let selectedModel: MacSessionViewerModel?",
    "let selectSessionAction: (UUID?) -> Void",
    "ForEach(models)",
    "MacPackageSessionListRow",
    "selectSessionAction(model.id)",
    "mac.viewer.sessions.title",
    "mac.viewer.sessions.sample_count.format",
    "mac.accessibility.session_list.label",
]

REQUIRED_BROWSER_TOKENS = [
    "MacPackageSessionListView(",
    "selectedSessionID: viewModel.selectedSessionID",
    "selectedModel: selectedModel",
    "selectSessionAction: viewModel.selectSession",
    "MacCurrentPackageSessionSummaryView(",
    "MacSessionDetailView(model: selectedModel, packageFileName: preview.fileName)",
]

FORBIDDEN_BROWSER_TOKENS = [
    "MacPackageSessionSelectorButton",
]

PROJECT_TOKENS = [
    "30E700000000000000000001 /* MacPackageSessionListView.swift */ = {isa = PBXFileReference;",
    "30E700000000000000000101 /* MacPackageSessionListView.swift in Sources */ = {isa = PBXBuildFile;",
    "30E700000000000000000001 /* MacPackageSessionListView.swift */",
    "30E700000000000000000101 /* MacPackageSessionListView.swift in Sources */",
]

LOCALIZATION_KEYS = [
    "mac.viewer.sessions.title",
    "mac.viewer.sessions.subtitle",
    "mac.viewer.sessions.single_count",
    "mac.viewer.sessions.count.format",
    "mac.viewer.sessions.sample_count.format",
    "mac.viewer.sessions.card.selected",
    "mac.viewer.sessions.card.not_selected",
    "mac.viewer.sessions.card.hint",
    "mac.accessibility.session_list.label",
    "mac.accessibility.session_list.hint",
]

DOC_TOKENS = [
    "Task-030e-MacViewer-006",
    "MacPackageSessionListView",
    "Selected Package Sessions List",
]

FORBIDDEN_SCOPE_TOKENS = [
    "MapKit",
    "MKMapView",
    "Map(",
    "roadMatch",
    "mapMatch",
    "snapToRoad",
    "reconstructRoute",
    "mutateRouteGeometry",
    "trustedMetricsMutationApplied = true",
    "routeGeometryMutationApplied = true",
    "estimatedRouteDisplayEnabled = true",
    "NSDocumentController",
    "UTType(exportedAs:",
    "bookmarkData",
    "CoreData",
]


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        raise AssertionError(f"Missing required file: {rel}")
    return path.read_text(encoding="utf-8")


def require_tokens(name: str, text: str, tokens: list[str]) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        joined = "\n".join(f"  - {token}" for token in missing)
        raise AssertionError(f"{name} missing required token(s):\n{joined}")


def reject_tokens(name: str, text: str, tokens: list[str]) -> None:
    present = [token for token in tokens if token in text]
    if present:
        joined = "\n".join(f"  - {token}" for token in present)
        raise AssertionError(f"{name} contains forbidden token(s):\n{joined}")


def verify_required_files() -> None:
    for rel in REQUIRED_FILES:
        if not (ROOT / rel).exists():
            raise AssertionError(f"Missing required file: {rel}")


def verify_swift_files() -> None:
    session_list = read("macOS/Features/SessionBrowser/MacPackageSessionListView.swift")
    browser = read("macOS/Features/SessionBrowser/MacSessionBrowserView.swift")
    require_tokens("MacPackageSessionListView.swift", session_list, REQUIRED_SESSION_LIST_TOKENS)
    require_tokens("MacSessionBrowserView.swift", browser, REQUIRED_BROWSER_TOKENS)
    reject_tokens("MacSessionBrowserView.swift", browser, FORBIDDEN_BROWSER_TOKENS)
    reject_tokens("MacPackageSessionListView.swift", session_list, FORBIDDEN_SCOPE_TOKENS)
    if len(session_list.splitlines()) > 500:
        raise AssertionError("MacPackageSessionListView.swift exceeds 500 lines")
    if len(browser.splitlines()) > 500:
        raise AssertionError("MacSessionBrowserView.swift exceeds 500 lines")


def verify_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    require_tokens("project.pbxproj", project, PROJECT_TOKENS)


def verify_localization() -> None:
    for lang in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{lang}.lproj/Localizable.strings")
        require_tokens(f"{lang} Localizable.strings", text, [f'"{key}" = ' for key in LOCALIZATION_KEYS])


def verify_docs() -> None:
    for rel in [
        "docs/history/DEV_LOG.md",
        "docs/reference/FILE_STRUCTURE.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]:
        require_tokens(rel, read(rel), DOC_TOKENS)


def main() -> int:
    try:
        verify_required_files()
        verify_swift_files()
        verify_project_membership()
        verify_localization()
        verify_docs()
    except AssertionError as error:
        print(f"Task-030e selected package sessions check failed: {error}")
        return 1
    print("Task-030e selected package sessions check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
