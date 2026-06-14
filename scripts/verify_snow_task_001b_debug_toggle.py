#!/usr/bin/env python3
"""Verify Snow-Task-001b Debug Tools toggle controls the Snow Mode entry.

Snow Mode must remain production model code, but the Ride start screen entry
should be hidden by default and exposed only through a DEBUG runtime toggle.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"[snow-task-001b] FAIL: {message}", file=sys.stderr)
    sys.exit(1)

def read(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.exists():
        fail(f"missing required file: {relative_path}")
    return path.read_text(encoding="utf-8")

def require(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token not in text:
        fail(f"missing token in {relative_path}: {token}")

def main() -> None:
    sport_mode = read("Shared/Models/SportMode.swift")
    if "case snow(SnowDiscipline)" not in sport_mode:
        fail("SportMode.snow must remain production code")
    nearby = sport_mode[max(0, sport_mode.find("case snow(SnowDiscipline)") - 80): sport_mode.find("case snow(SnowDiscipline)") + 140]
    if "#if DEBUG" in nearby or "#endif" in nearby:
        fail("SportMode.snow must not be wrapped in DEBUG compilation")

    support = read("iOS/Features/SessionRecording/SessionStartSupportTypes.swift")
    for token in [
        "static func userFacingCases(isSnowEntryEnabled: Bool)",
        "isSnowEntryEnabled ? allCases : allCases.filter { $0 != .snow }",
        "return allCases.filter { $0 != .snow }",
        "static var releaseSafeCases",
    ]:
        if token not in support:
            fail(f"SessionStartSportCategory missing toggle gate token: {token}")

    picker = read("iOS/Features/SessionRecording/SportCategoryPickerView.swift")
    for token in [
        "let availableCategories: [SessionStartSportCategory]",
        "ForEach(availableCategories)",
        "SessionStartSportCategory.releaseSafeCases",
    ]:
        if token not in picker:
            fail(f"SportCategoryPickerView missing injected list token: {token}")
    if "ForEach(SessionStartSportCategory.allCases)" in picker:
        fail("SportCategoryPickerView must not render all cases directly")

    session_start = read("iOS/Features/SessionRecording/SessionStartView.swift")
    for token in [
        "DebugRuntimeOptions.shared",
        "availableSportCategories",
        "SessionStartSportCategory.userFacingCases(isSnowEntryEnabled: debugRuntimeOptions.isSnowModeEntryEnabled)",
        "enforceAvailableSelectedCategory()",
        "selectedCategory = .skateboard",
    ]:
        if token not in session_start:
            fail(f"SessionStartView missing toggle behavior token: {token}")

    debug_runtime = read("iOS/Features/Debug/DebugRuntimeOptions.swift")
    for token in [
        "snowModeEntryUserDefaultsKey",
        "isSnowModeEntryEnabled",
        "UserDefaults.standard.set",
    ]:
        if token not in debug_runtime:
            fail(f"DebugRuntimeOptions missing snow toggle state token: {token}")

    debug_action = read("iOS/Features/Debug/DebugToolAction.swift")
    if "case toggleSnowModeEntry" not in debug_action or "debug-tools-snow-mode-entry-toggle" not in debug_action:
        fail("DebugToolAction missing snow toggle accessibility action")

    debug_panel = read("iOS/Features/Debug/DebugToolsPanelView.swift")
    for token in [
        "$debugRuntimeOptions.isSnowModeEntryEnabled",
        "debug.tools.snowMode.toggle",
        "DebugToolAction.toggleSnowModeEntry.accessibilityIdentifier",
        "debug.tools.snowMode.entryEnabledHint",
        "debug.tools.snowMode.entryDisabledHint",
    ]:
        if token not in debug_panel:
            fail(f"DebugToolsPanelView missing snow toggle token: {token}")

    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in [
            "debug.tools.snowMode.toggle",
            "debug.tools.snowMode.entryEnabledHint",
            "debug.tools.snowMode.entryDisabledHint",
        ]:
            if f'"{key}"' not in text:
                fail(f"missing {key} in {language} localization")

    all_swift = "\n".join(path.read_text(encoding="utf-8") for path in ROOT.glob("**/*.swift"))
    if "SnowPrototype" in all_swift:
        fail("production Snow tasks must not introduce or depend on SnowPrototype namespace")
    if list(ROOT.glob("**/*.skatetrack")):
        fail(".skatetrack sample package must not be included")

    print("[snow-task-001b] PASS: Debug Tools toggle controls Snow Mode Session Start entry while production enum remains available.")

if __name__ == "__main__":
    main()
