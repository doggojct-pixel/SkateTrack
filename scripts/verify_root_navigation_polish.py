#!/usr/bin/env python3
"""Verify Task-025c sticky root navigation polish and debug entry placement."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/App/RootNavigationView.swift",
    "iOS/Features/SessionRecording/SessionStartView.swift",
    "iOS/Features/SessionRecording/SessionStartHeaderMetricsView.swift",
    "iOS/Features/SessionRecording/SessionStartStickyRootNavigationView.swift",
    "docs/DEV_LOG.md",
    "docs/FILE_STRUCTURE.md",
]


def fail(message: str) -> None:
    print(f"❌ Task-025c root navigation polish verification failed: {message}")
    sys.exit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def verify_files() -> None:
    for relative in REQUIRED_FILES:
        path = ROOT / relative
        if not path.exists():
            fail(f"Missing required file: {relative}")
        if relative.endswith(".swift"):
            line_count = len(path.read_text(encoding="utf-8").splitlines())
            if line_count > 500:
                fail(f"{relative} exceeds 500-line limit: {line_count}")


def verify_sticky_navigation() -> None:
    session_start = read("iOS/Features/SessionRecording/SessionStartView.swift")
    header = read("iOS/Features/SessionRecording/SessionStartHeaderMetricsView.swift")
    sticky = read("iOS/Features/SessionRecording/SessionStartStickyRootNavigationView.swift")

    for token in [
        "navigationRowMinY: navigationRowMinY",
        "isMeasured: navigationRowMinY < .greatestFiniteMagnitude",
        "isPinned: shouldShowStickyRootNavigation(topInset: stickyTopInset)",
        "SessionStartScrollOffsetPreferenceKey.self",
        "SessionStartNavigationPositionPreferenceKey.self",
    ]:
        if token not in session_start:
            fail(f"SessionStartView missing continuous sticky token: {token}")

    for token in [
        "session-start-root-navigation-anchor",
        ".opacity(0)",
        ".allowsHitTesting(false)",
        ".accessibilityHidden(true)",
        "navigationPositionReader",
    ]:
        if token not in header:
            fail(f"SessionStartHeaderMetricsView missing hidden anchor token: {token}")

    for token in [
        "navigationRowMinY",
        "displayedTopPosition",
        "max(navigationRowMinY, pinnedTopPosition)",
        "stickyNavigationBackgroundFadeDistance",
        "stickyBackgroundOpacity",
        "isMeasured ? 1 : 0",
        "session-start-sticky-root-navigation",
    ]:
        if token not in sticky:
            fail(f"SessionStartStickyRootNavigationView missing continuous sticky token: {token}")

    if "isVisible" in sticky:
        fail("Sticky navigation should not use threshold-only isVisible overlay switching after Task-025c")


def verify_debug_entry() -> None:
    root = read("iOS/App/RootNavigationView.swift")
    for token in [
        "debugToolsBottomPadding",
        ".padding(.bottom, debugToolsBottomPadding)",
        "debug-tools-bottom-entry",
        "selectedPrimaryScreen == .ride ? 118 : 28",
    ]:
        if token not in root:
            fail(f"RootNavigationView missing bottom debug-entry token: {token}")

    debug_block_match = re.search(r"private var debugToolsButton: some View \{(?P<body>.*?)\n    \}\n    #endif", root, flags=re.S)
    if not debug_block_match:
        fail("Could not find debugToolsButton body")
    debug_block = debug_block_match.group("body")
    if ".padding(.top," in debug_block:
        fail("debugToolsButton must not keep a top padding placement")
    if "Spacer()\n            HStack" not in debug_block:
        fail("debugToolsButton should be bottom-aligned before the trailing HStack")


def verify_scope_boundaries() -> None:
    source_files = [
        "iOS/App/RootNavigationView.swift",
        "iOS/Features/SessionRecording/SessionStartView.swift",
        "iOS/Features/SessionRecording/SessionStartHeaderMetricsView.swift",
        "iOS/Features/SessionRecording/SessionStartStickyRootNavigationView.swift",
    ]
    combined = "\n".join(read(relative) for relative in source_files)
    for forbidden in [
        "import GoogleSignIn",
        "GoogleService-Info.plist",
        "REVERSED_CLIENT_ID",
        "com.googleusercontent.apps",
        "INFOPLIST_KEY_CFBundleURLTypes",
    ]:
        if forbidden in combined:
            fail(f"Task-025c must not introduce Google production configuration: {forbidden}")


def verify_docs() -> None:
    docs = "\n".join([
        read("docs/DEV_LOG.md"),
        read("docs/FILE_STRUCTURE.md"),
    ])
    for token in [
        "Task-025c",
        "Root Navigation Sticky Polish",
        "Debug Entry Placement",
        "Deferred from Task-025c",
        "Task-025d",
        "verify_root_navigation_polish.py",
    ]:
        if token not in docs:
            fail(f"Living docs missing Task-025c token: {token}")


def main() -> None:
    verify_files()
    verify_sticky_navigation()
    verify_debug_entry()
    verify_scope_boundaries()
    verify_docs()
    print("✅ Task-025c root navigation sticky polish verification passed.")


if __name__ == "__main__":
    main()
