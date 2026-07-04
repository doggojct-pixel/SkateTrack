#!/usr/bin/env python3
"""Verify Task-030e macOS multi-package viewer foundation after 011."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

TASK030E_VERIFIERS = [
    "scripts/verify_task030e_browser_first_ia.py",
    "scripts/verify_task030e_multi_package_state.py",
    "scripts/verify_task030e_multi_file_open.py",
    "scripts/verify_task030e_package_cards.py",
    "scripts/verify_task030e_selected_package_sessions.py",
    "scripts/verify_task030e_mapkit_route_context.py",
    "scripts/verify_task030e_route_visual_inspection.py",
    "scripts/verify_task030e_selected_session_detail_layout.py",
    "scripts/verify_task030e_elevation_profile.py",
    "scripts/verify_task030e_duplicate_attention.py",
    "scripts/verify_task030e_duplicate_acknowledgement.py",
    "scripts/verify_task030e_localization_accessibility.py",
    "scripts/verify_task030e_macos_multi_package_viewer.py",
]

REQUIRED_FILES = [
    "macOS/App/MacRootView.swift",
    "macOS/Features/Import/MacPackageImportViewModel.swift",
    "macOS/Features/SessionBrowser/MacSessionBrowserView.swift",
    "macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift",
    "macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift",
    "macOS/Features/SessionBrowser/MacPackageCardListView.swift",
    "macOS/Features/SessionBrowser/MacPackageSessionListView.swift",
    "macOS/Features/SessionBrowser/MacPackageAttentionState.swift",
    "macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift",
    "macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift",
    "macOS/Features/SessionBrowser/MacRouteMapContextView.swift",
    "macOS/Features/SessionBrowser/MacRoutePreviewView.swift",
    "macOS/Features/SessionBrowser/MacRouteInspectionView.swift",
    "macOS/Features/SessionBrowser/MacSpeedSparklineView.swift",
    "macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift",
    "Shared/Models/SkateTrackPackageManifest.swift",
    "Shared/Models/SkateTrackPackagePayload.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "Shared/Localization/ja.lproj/Localizable.strings",
    "scripts/run_task030e_macos_multi_package_viewer_oneclick.sh",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
]

REQUIRED_LOCALIZATION_KEYS = [
    "mac.viewer.title",
    "mac.viewer.open.button",
    "mac.viewer.open.clear",
    "mac.viewer.open.panel.title",
    "mac.viewer.open.partial_failure.title",
    "mac.viewer.package.current",
    "mac.viewer.sessions.title",
    "mac.viewer.detail.title",
    "mac.viewer.route.preview.title",
    "mac.viewer.route.inspect.open",
    "mac.viewer.route.inspect.close",
    "mac.viewer.chart.speed.title",
    "mac.viewer.chart.elevation.title",
    "mac.viewer.attention.title",
    "mac.viewer.attention.acknowledge_duplicate_files",
    "mac.accessibility.open_packages.button.label",
    "mac.accessibility.clear_packages.button.label",
    "mac.accessibility.acknowledge_duplicate_files.button.label",
    "mac.accessibility.route_inspect_open.button.label",
    "mac.accessibility.route_inspect_close.button.label",
    "mac.accessibility.speed_chart.label",
    "mac.accessibility.elevation_chart.label",
]

FORBIDDEN_SOURCE_TOKENS = [
    "SessionRepository(",
    "PersistenceController",
    "NSPersistent",
    "saveSession(",
    "deleteSession(",
    "restorePackage(",
    "mergePackage(",
    "importIntoLocalHistory",
    "winnerSelection",
    "CloudKit",
    "GoogleSignIn",
    "GIDSignIn",
    "WatchKit",
    "WatchBridge",
    "SensorFusionEngine(",
    "GPSProvider(",
    "requestWhenInUseAuthorization",
    "requestAlwaysAuthorization",
    "showsUserLocation = true",
    "mapMatch",
    "snapToRoad",
    "reconstructRoute",
    "mutateRouteGeometry",
    "trustedMetricsMutation",
]

MACOS_SWIFT_DIRS = [
    "macOS/App",
    "macOS/Features/Import",
    "macOS/Features/SessionBrowser",
    "macOS/Features/Shared",
]


def fail(message: str) -> None:
    print(f"Task-030e consolidated verifier failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def strip_comment_lines(text: str) -> str:
    return "\n".join(
        line for line in text.splitlines()
        if not line.strip().startswith("//")
    )


def require_tokens(path: str, tokens: list[str]) -> None:
    text = read(path)
    for token in tokens:
        if token not in text:
            fail(f"{path} missing token: {token}")


def swift_files() -> list[Path]:
    result: list[Path] = []
    for directory in MACOS_SWIFT_DIRS:
        base = ROOT / directory
        if base.exists():
            result.extend(sorted(base.rglob("*.swift")))
    return result


def localization_keys(locale: str) -> set[str]:
    path = ROOT / f"Shared/Localization/{locale}.lproj/Localizable.strings"
    keys: set[str] = set()
    pattern = re.compile(r'^\s*"([^"]+)"\s*=')
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if match:
            key = match.group(1)
            if key in keys:
                fail(f"duplicate localization key in {path.relative_to(ROOT)}: {key}")
            keys.add(key)
    return keys


def ensure_required_files() -> None:
    missing = [path for path in REQUIRED_FILES + TASK030E_VERIFIERS if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_browser_first_and_open_flow() -> None:
    require_tokens("macOS/App/MacRootView.swift", [
        "case sessionBrowser",
        "Session Browser",
        "MacSessionBrowserView",
    ])
    require_tokens("macOS/Features/SessionBrowser/MacSessionBrowserView.swift", [
        "NSOpenPanel()",
        "panel.allowsMultipleSelection = true",
        "viewModel.openPackages(from: panel.urls)",
        "MacPackageAttentionSummaryView(",
        "MacPackageCardListView(",
    ])
    require_tokens("macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift", [
        "func openPackages(from urls: [URL]) -> MacPackageOpenResult",
        "requestedFileCount: urls.count",
        "previews.append",
        "failures.append",
        "url.startAccessingSecurityScopedResource()",
        "url.stopAccessingSecurityScopedResource()",
    ])
    require_tokens("macOS/Features/Import/MacPackageImportViewModel.swift", [
        "private let openCoordinator: MacPackageOpenCoordinator",
        "func openPackages(from urls: [URL])",
        "nextState.mergeOpenedPreviews(result.previews)",
        "lastOpenResult = result",
        "func acknowledgeDuplicateFilePathWarnings()",
    ])


def ensure_multi_package_state() -> None:
    require_tokens("macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift", [
        "struct MacMultiPackageViewerState: Equatable",
        "private(set) var packages: [MacPackageImportPreview]",
        "private(set) var selection: MacMultiPackageViewerSelection",
        "private(set) var acknowledgedDuplicateFilePaths: Set<String>",
        "var batchSummary: MacPackageOpenBatchSummary",
        "mutating func mergeOpenedPreviews(_ previews: [MacPackageImportPreview])",
        "let combinedPreviews = packages + previews",
        "MacPackageAttentionClassifier.classifiedPreviews(",
        "mutating func acknowledgeDuplicateFilePathWarnings()",
        "mutating func removePackage(id: UUID)",
        "mutating func clear()",
    ])
    require_tokens("macOS/Features/SessionBrowser/MacPackageAttentionState.swift", [
        "case duplicateFilePath",
        "case duplicatePackageIdentifier",
        "case duplicateSessionIdentifier",
        "uniquePreviewsByPath(from previews:",
        "duplicateSessionIdentifiers(in:",
        "packageIdentifierCandidate(for preview: MacPackageImportPreview) -> String?",
        "SkateTrackPackageManifest v1 currently has no dedicated package identifier",
        "acknowledgedDuplicateFilePaths",
    ])


def ensure_route_boundaries() -> None:
    require_tokens("macOS/Features/SessionBrowser/MacRouteMapContextView.swift", [
        "import MapKit",
        "struct MacRouteMapContextView: NSViewRepresentable",
        "let points: [MacRoutePoint]",
        "mapView.showsUserLocation = false",
        "mapView.addOverlay(polyline, level: .aboveRoads)",
        "setVisibleMapRect",
    ])
    require_tokens("macOS/Features/SessionBrowser/MacRouteDisplayPipeline.swift", [
        "static func deriveMetrics(session: SessionData, samples: [MotionSample])",
        "MacDerivedMetricsResult",
        "MacRoutePoint",
        "routeQuality(",
        "deduplicatedTrustedLocationFixes",
    ])
    require_tokens("macOS/Features/SessionBrowser/MacElevationDisplayPipeline.swift", [
        "enum MacElevationDisplayPipeline",
        "elevationPoints(session: SessionData, samples: [MotionSample])",
        "display-only",
    ])


def ensure_no_forbidden_runtime_scope() -> None:
    for path in swift_files():
        text = strip_comment_lines(path.read_text(encoding="utf-8"))
        for token in FORBIDDEN_SOURCE_TOKENS:
            if token in text:
                fail(f"forbidden runtime token in {path.relative_to(ROOT)}: {token}")
    manifest = read("Shared/Models/SkateTrackPackageManifest.swift")
    if "packageIdentifier" in strip_comment_lines(manifest):
        fail("SkateTrackPackageManifest v1 should not add a packageIdentifier field")


def ensure_localization() -> None:
    key_sets = {locale: localization_keys(locale) for locale in ["en", "zh-Hant", "ja"]}
    if key_sets["en"] != key_sets["zh-Hant"] or key_sets["en"] != key_sets["ja"]:
        fail("localization key parity mismatch across en / zh-Hant / ja")
    for key in REQUIRED_LOCALIZATION_KEYS:
        if key not in key_sets["en"]:
            fail(f"missing Task-030e localization key: {key}")


def ensure_headers_and_line_counts() -> None:
    for path in swift_files():
        text = path.read_text(encoding="utf-8")
        first = text.splitlines()[0] if text.splitlines() else ""
        if not (first.startswith("// [協作區]") or first.startswith("// [自主區]")):
            fail(f"Swift file missing collaboration zone header: {path.relative_to(ROOT)}")
        line_count = len(text.splitlines())
        if line_count > 500:
            fail(f"Swift file exceeds 500 lines: {path.relative_to(ROOT)} has {line_count}")


def ensure_oneclick_foundation() -> None:
    oneclick = read("scripts/run_task030e_macos_multi_package_viewer_oneclick.sh")
    for token in [
        "verify_task030e_macos_multi_package_viewer.py",
        "verify_task030e_localization_accessibility.py",
        "xcodebuild",
        "LINE_CHECK_RESULT",
        "DIFF_CHECK_EXIT",
        "STATUS_EXIT",
        "OVERALL_RESULT",
        "ONECLICK_RESULT",
        "ONECLICK_ZIP_EXIT",
        "ONECLICK_CLEANUP_EXIT",
        "ONECLICK_RUN_DIR_REMOVED=\"YES\"",
        "rm -rf \"${RUN_DIR}\"",
    ]:
        if token not in oneclick:
            fail(f"one-click script missing token: {token}")
    if re.search(r"wc\s+-l.*total", oneclick):
        fail("one-click line check must not parse wc total as a Swift file")


def ensure_docs() -> None:
    dev_log = read("docs/history/DEV_LOG.md")
    file_structure = read("docs/reference/FILE_STRUCTURE.md")
    for token in [
        "Task-030e-MacViewer-011 Verifier / Test Foundation",
        "verify_task030e_macos_multi_package_viewer.py",
        "run_task030e_macos_multi_package_viewer_oneclick.sh",
        "ONECLICK_RUN_DIR_REMOVED=YES",
        "no package schema change",
    ]:
        if token not in dev_log + file_structure:
            fail(f"documentation missing token: {token}")
    limitations = read("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md")
    if "Task-030e" not in limitations:
        fail("known limitations must preserve Task-030e context")


def main() -> None:
    ensure_required_files()
    ensure_browser_first_and_open_flow()
    ensure_multi_package_state()
    ensure_route_boundaries()
    ensure_no_forbidden_runtime_scope()
    ensure_localization()
    ensure_headers_and_line_counts()
    ensure_oneclick_foundation()
    ensure_docs()
    print("Task-030e macOS multi-package viewer consolidated verification passed.")


if __name__ == "__main__":
    main()
