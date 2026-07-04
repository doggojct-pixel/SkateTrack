#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-010 localization / accessibility pass."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
    "macOS/Features/SessionBrowser/MacPackageSessionListView.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/verify_localization_keys.py",
    "scripts/verify_task030e_localization_accessibility.py",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]

CHECKED_SWIFT_FILES = [
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
    "macOS/Features/SessionBrowser/MacPackageSessionListView.swift",
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
]

ACCESSIBILITY_TOKENS = {
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift": [
        "mac.accessibility.acknowledge_duplicate_files.button.label",
        "mac.accessibility.acknowledge_duplicate_files.button.hint",
        "mac-attention-acknowledge-duplicate-files-button",
        ".help(Text(\"mac.accessibility.acknowledge_duplicate_files.button.hint\"))",
    ],
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift": [
        "mac.accessibility.open_packages.button.label",
        "mac.accessibility.open_packages.button.hint",
        "mac-open-packages-button",
        "mac.accessibility.clear_packages.button.label",
        "mac.accessibility.clear_packages.button.hint",
        "mac-clear-packages-button",
    ],
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift": [
        "mac.accessibility.route_inspect_open.button.label",
        "mac.accessibility.route_inspect_open.button.hint",
        "mac-route-inspect-open-titlebar-button",
        "mac-route-inspect-open-overlay-button",
    ],
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift": [
        "mac.accessibility.route_inspect_close.button.label",
        "mac.accessibility.route_inspect_close.button.hint",
        "mac-route-inspect-close-button",
    ],
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift": [
        "mac-speed-chart",
        "mac.accessibility.elevation_chart.label",
        "mac-elevation-chart",
    ],
    "macOS/Features/SessionBrowser/MacPackageCardListView.swift": [
        "mac-package-card-select-button",
        "mac.accessibility.package_card.remove.hint",
        "mac-package-card-remove-button",
    ],
    "macOS/Features/SessionBrowser/MacPackageSessionListView.swift": [
        "mac-session-list-card",
        ".help(Text(\"mac.viewer.sessions.card.hint\"))",
    ],
    "macOS/Features/SessionBrowser/MacSessionDetailView.swift": [
        "Text(verbatim: \"• \\(note)\")",
        ".accessibilityLabel(Text(LocalizedStringKey(titleKey)))",
        ".accessibilityValue(Text(value))",
    ],
}

LOCALIZATION_KEYS = [
    "mac.accessibility.open_packages.button.label",
    "mac.accessibility.open_packages.button.hint",
    "mac.accessibility.clear_packages.button.label",
    "mac.accessibility.clear_packages.button.hint",
    "mac.accessibility.acknowledge_duplicate_files.button.label",
    "mac.accessibility.acknowledge_duplicate_files.button.hint",
    "mac.accessibility.route_inspect_open.button.label",
    "mac.accessibility.route_inspect_open.button.hint",
    "mac.accessibility.route_inspect_close.button.label",
    "mac.accessibility.route_inspect_close.button.hint",
    "mac.accessibility.elevation_chart.label",
    "mac.accessibility.package_card.remove.hint",
]

JAPANESE_EXPECTED_SNIPPETS = [
    '"mac.package.preview.distance.format" = "%.2f km";',
    '"mac.package.preview.speed.format" = "%.1f km/h";',
    '"mac.package.preview.percent.format" = "%.0f%%";',
    '"mac.viewer.empty.no_session.subtitle" = "このパッケージは検証に成功しましたが、ビューアーで表示できるセッションペイロードが見つかりませんでした。";',
    '"mac.viewer.open.button" = "パッケージを開く";',
    '"mac.viewer.open.clear" = "パッケージをクリア";',
]

DOC_TOKENS = [
    "Task-030e-MacViewer-010 Localization / Accessibility Pass",
    "mac.accessibility.elevation_chart.label",
    "Japanese macOS viewer unit",
    "no route / metric / package mutation",
]

FORBIDDEN_TOKENS = [
    "SessionRepository(",
    "PersistenceController",
    "saveSession(",
    "deleteSession(",
    "CloudKit",
    "GoogleSignIn",
    "GIDSignIn",
    "mapMatch",
    "snapToRoad",
    "reconstructRoute",
    "mutateRouteGeometry",
    "trustedMetricsMutation",
    "CLLocationManager",
    "requestWhenInUseAuthorization",
    "showsUserLocation = true",
    "estimatedRouteDisplayEnabled = true",
]


def fail(message: str) -> None:
    print(f"Task-030e-010 localization/accessibility check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_swift_headers_and_line_counts() -> None:
    for path in CHECKED_SWIFT_FILES:
        full = ROOT / path
        lines = full.read_text(encoding="utf-8").splitlines()
        if not lines or lines[0].strip() not in {"// [協作區]", f"// [協作區] {Path(path).name}", f"// [協作區] {path}"}:
            fail(f"{path} missing required first-line collaboration zone header")
        if len(lines) > 500:
            fail(f"{path} exceeds 500-line hard limit: {len(lines)}")


def ensure_accessibility_tokens() -> None:
    for path, tokens in ACCESSIBILITY_TOKENS.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"{path} missing accessibility token: {token}")


def parse_keys(path: Path) -> dict[str, str]:
    keys: dict[str, str] = {}
    for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = re.match(r'\s*"([^"]+)"\s*=\s*"((?:\\.|[^"])*)";', line)
        if not match:
            continue
        key = match.group(1)
        if key in keys:
            fail(f"duplicate localization key in {path.relative_to(ROOT)}:{index}: {key}")
        keys[key] = match.group(2)
    return keys


def printf_placeholders(value: str) -> list[str]:
    return [
        match
        for match in re.findall(r'%(?:\d+\$)?[+#0\- ]*(?:\d+|\*)?(?:\.(?:\d+|\*))?[hlL]?[diuoxXfFeEgGaAcCsSp@%]', value)
        if match != "%%"
    ]


def ensure_localization() -> None:
    locale_paths = {
        locale: ROOT / "Shared" / "Localization" / f"{locale}.lproj" / "Localizable.strings"
        for locale in ["en", "zh-Hant", "ja"]
    }
    keys_by_locale = {locale: parse_keys(path) for locale, path in locale_paths.items()}

    base_keys = set(keys_by_locale["en"].keys())
    for locale in ["zh-Hant", "ja"]:
        if set(keys_by_locale[locale].keys()) != base_keys:
            missing = sorted(base_keys - set(keys_by_locale[locale].keys()))
            extra = sorted(set(keys_by_locale[locale].keys()) - base_keys)
            fail(f"localization key mismatch for {locale}; missing={missing[:8]} extra={extra[:8]}")

    for key in LOCALIZATION_KEYS:
        for locale in ["en", "zh-Hant", "ja"]:
            value = keys_by_locale[locale].get(key)
            if not value:
                fail(f"{locale} missing or empty localization key: {key}")

    for key, en_value in keys_by_locale["en"].items():
        en_placeholders = printf_placeholders(en_value)
        for locale in ["zh-Hant", "ja"]:
            locale_placeholders = printf_placeholders(keys_by_locale[locale][key])
            if len(en_placeholders) != len(locale_placeholders):
                fail(f"placeholder count mismatch for {locale}:{key}")

    ja_text = locale_paths["ja"].read_text(encoding="utf-8")
    for snippet in JAPANESE_EXPECTED_SNIPPETS:
        if snippet not in ja_text:
            fail(f"Japanese localization missing expected 010 alignment snippet: {snippet}")


def ensure_docs() -> None:
    dev_log = read("docs/history/DEV_LOG.md")
    file_structure = read("docs/reference/FILE_STRUCTURE.md")
    for token in DOC_TOKENS:
        if token not in dev_log and token not in file_structure:
            fail(f"docs missing 010 token: {token}")


def ensure_no_forbidden_scope() -> None:
    checked_paths = [
        "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
        "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
        "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
        "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
        "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
        "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
        "macOS/Features/SessionBrowser/MacPackageSessionListView.swift",
        "macOS/Features/SessionBrowser/MacSessionDetailView.swift",
    ]
    for path in checked_paths:
        text = read(path)
        for token in FORBIDDEN_TOKENS:
            if token in text:
                fail(f"{path} contains forbidden scope token: {token}")


def main() -> None:
    ensure_files()
    ensure_swift_headers_and_line_counts()
    ensure_accessibility_tokens()
    ensure_localization()
    ensure_docs()
    ensure_no_forbidden_scope()
    print("Task-030e-010 localization/accessibility verification passed.")


if __name__ == "__main__":
    main()
