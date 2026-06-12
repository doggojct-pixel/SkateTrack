#!/usr/bin/env python3
"""Task-029b accessibility / privacy / UX quality gate.

This check keeps the post-Task-029a three-language localization pass aligned
with VoiceOver labels, macOS viewer layout guardrails, and deferred-service
privacy copy. It intentionally avoids checking or adding production services,
signing, custom UTTypes, or document associations.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION_ROOT = ROOT / "Shared" / "Localization"
PROJECT_FILE = ROOT / "SkateTrack.xcodeproj" / "project.pbxproj"
DEV_LOG = ROOT / "docs" / "DEV_LOG.md"
FILE_STRUCTURE = ROOT / "docs" / "FILE_STRUCTURE.md"
TECH_RISK = ROOT / "docs" / "Task026-030_TechRisk_Solutions.md"
ADR = ROOT / "docs" / "decisions" / "ADR-0010-accessibility-privacy-quality-gate.md"
LANGUAGES = ("en", "zh-Hant", "ja")
STRING_ENTRY = re.compile(r'^\s*(?:"(?P<qkey>[^"]+)"|(?P<bkey>[A-Za-z0-9_]+))\s*=\s*"(?P<value>(?:\\.|[^"])*)"\s*;\s*$')

REQUIRED_LOCALIZATION_KEYS = [
    "session.hud.status.accessibility.label",
    "debug.tools.title",
    "safety.contacts.title",
    "safety.contacts.description",
    "mac.accessibility.package_summary.label",
    "mac.accessibility.package_summary.hint",
    "mac.accessibility.session_detail.label",
    "mac.accessibility.route_preview.label",
    "mac.accessibility.route_preview.hint",
    "mac.accessibility.route_preview.value.format",
    "mac.accessibility.speed_chart.label",
    "mac.accessibility.speed_chart.hint",
    "mac.viewer.privacy.readonly",
    "mac.viewer.route.preview.not_mapmatched",
    "account.google.drive_deferred",
    "backup.restore.deferred.note",
]

REQUIRED_SNIPPETS = {
    "iOS/App/RootNavigationView.swift": [
        '.accessibilityLabel(Text("debug.tools.title"))',
    ],
    "iOS/Features/SessionRecording/LiveHUDView.swift": [
        '.accessibilityLabel(Text("session.hud.status.accessibility.label"))',
        '.accessibilityLabel(Text("safety.contacts.title"))',
        '.accessibilityHint(Text("safety.contacts.description"))',
        '.accessibilityLabel(Text("debug.tools.title"))',
    ],
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift": [
        '.accessibilityLabel(Text("mac.accessibility.package_summary.label"))',
        '.accessibilityHint(Text("mac.accessibility.package_summary.hint"))',
    ],
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift": [
        '.accessibilityLabel(Text("mac.accessibility.session_detail.label"))',
        '.accessibilityElement(children: .contain)',
    ],
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift": [
        '.accessibilityLabel(Text("mac.accessibility.route_preview.label"))',
        '.accessibilityHint(Text("mac.accessibility.route_preview.hint"))',
        'mac.accessibility.route_preview.value.format',
    ],
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift": [
        '.accessibilityLabel(Text("mac.accessibility.speed_chart.label"))',
        '.accessibilityHint(Text("mac.accessibility.speed_chart.hint"))',
    ],
}

FORBIDDEN_SNIPPETS = {
    "iOS/App/RootNavigationView.swift": [
        '.accessibilityLabel("Debug Tools")',
    ],
    "iOS/Features/SessionRecording/LiveHUDView.swift": [
        '.accessibilityLabel("Debug Tools")',
        '.accessibilityLabel("Emergency Contacts")',
    ],
}

LAYOUT_GUARDRAILS = {
    "macOS/App/MacRootView.swift": [
        "NavigationSplitView",
        "navigationSplitViewColumnWidth(min: 224, ideal: 248, max: 300)",
        "MacSessionBrowserView(",
    ],
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift": [
        "MacCurrentPackageSessionSummaryView(",
        "MacSessionDetailView(model:",
        ".frame(maxWidth: 1_120",
    ],
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift": [
        "MacRoutePreviewView(points:",
        "MacSpeedSparklineView(points:",
        "LazyVGrid(columns: visualizationColumns",
    ],
}

PRIVACY_DOC_TERMS = [
    "accessibility",
    "privacy",
    "read-only",
    "Google Drive",
    "StoreKit",
    "CloudKit",
    "MapKit",
    "pt-BR",
    "es",
]

FORBIDDEN_PROJECT_TOKENS = [
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "com.apple.developer.icloud",
    "com.apple.developer.associated-domains",
]


def parse_strings(path: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("/*"):
            continue
        match = STRING_ENTRY.match(line)
        if not match:
            raise ValueError(f"Invalid strings syntax in {path.relative_to(ROOT)}:{index}: {line}")
        entries[match.group("qkey") or match.group("bkey")] = match.group("value")
    return entries


def check_localization_keys() -> bool:
    failed = False
    for language in LANGUAGES:
        path = LOCALIZATION_ROOT / f"{language}.lproj" / "Localizable.strings"
        if not path.exists():
            print(f"Missing localization file: {path.relative_to(ROOT)}")
            failed = True
            continue
        entries = parse_strings(path)
        missing = [key for key in REQUIRED_LOCALIZATION_KEYS if key not in entries or not entries[key].strip()]
        if missing:
            print(f"Missing Task-029b localization keys for {language}:")
            for key in missing:
                print(f"- {key}")
            failed = True
    return not failed


def check_required_snippets() -> bool:
    failed = False
    for relative, snippets in REQUIRED_SNIPPETS.items():
        path = ROOT / relative
        if not path.exists():
            print(f"Missing source file: {relative}")
            failed = True
            continue
        text = path.read_text(encoding="utf-8")
        missing = [snippet for snippet in snippets if snippet not in text]
        if missing:
            print(f"Missing accessibility / quality snippets in {relative}:")
            for snippet in missing:
                print(f"- {snippet}")
            failed = True
    return not failed


def check_forbidden_snippets() -> bool:
    failed = False
    for relative, snippets in FORBIDDEN_SNIPPETS.items():
        path = ROOT / relative
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        found = [snippet for snippet in snippets if snippet in text]
        if found:
            print(f"Found hard-coded accessibility copy in {relative}:")
            for snippet in found:
                print(f"- {snippet}")
            failed = True
    return not failed


def check_layout_guardrails() -> bool:
    failed = False
    for relative, snippets in LAYOUT_GUARDRAILS.items():
        path = ROOT / relative
        if not path.exists():
            print(f"Missing layout file: {relative}")
            failed = True
            continue
        text = path.read_text(encoding="utf-8")
        missing = [snippet for snippet in snippets if snippet not in text]
        if missing:
            print(f"macOS layout guardrail missing in {relative}:")
            for snippet in missing:
                print(f"- {snippet}")
            failed = True
    return not failed


def check_docs() -> bool:
    docs = [DEV_LOG, FILE_STRUCTURE, TECH_RISK, ADR]
    missing_docs = [str(path.relative_to(ROOT)) for path in docs if not path.exists()]
    if missing_docs:
        print("Missing Task-029b documentation:")
        for path in missing_docs:
            print(f"- {path}")
        return False

    combined = "\n".join(path.read_text(encoding="utf-8") for path in docs)
    missing_terms = [term for term in PRIVACY_DOC_TERMS if term not in combined]
    if missing_terms:
        print("Task-029b docs do not cover required quality/privacy terms:")
        for term in missing_terms:
            print(f"- {term}")
        return False
    return True


def check_project_file() -> bool:
    project = PROJECT_FILE.read_text(encoding="utf-8")
    forbidden = [token for token in FORBIDDEN_PROJECT_TOKENS if token in project]
    if forbidden:
        print("Unexpected production / document capability token found:")
        for token in forbidden:
            print(f"- {token}")
        return False
    return True


def main() -> int:
    checks = [
        check_localization_keys(),
        check_required_snippets(),
        check_forbidden_snippets(),
        check_layout_guardrails(),
        check_docs(),
        check_project_file(),
    ]
    if not all(checks):
        return 1
    print("Task-029b accessibility/privacy/UX quality gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
