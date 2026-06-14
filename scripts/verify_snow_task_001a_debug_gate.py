#!/usr/bin/env python3
"""Verify Snow-Task-001a public-entry gate.

Snow Mode must remain a production SportMode case for later schema/classifier
work, but the normal user-facing Session Start entry must stay DEBUG-only until
Snow-Task-002 through Snow-Task-009 complete the production snow data path.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"[snow-task-001a] FAIL: {message}", file=sys.stderr)
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
    support = read("iOS/Features/SessionRecording/SessionStartSupportTypes.swift")
    for token in [
        "static func userFacingCases(isSnowEntryEnabled: Bool)",
        "return isSnowEntryEnabled ? allCases : allCases.filter { $0 != .snow }",
        "#else",
        "return allCases.filter { $0 != .snow }",
        "static var releaseSafeCases",
    ]:
        if token not in support:
            fail(f"SessionStartSportCategory public gate missing token: {token}")

    picker = read("iOS/Features/SessionRecording/SportCategoryPickerView.swift")
    if "let availableCategories: [SessionStartSportCategory]" not in picker or "ForEach(availableCategories)" not in picker:
        fail("SportCategoryPickerView must render an injected category list, not allCases")
    if "ForEach(SessionStartSportCategory.allCases)" in picker:
        fail("SportCategoryPickerView still exposes all sport categories directly")

    session_start = read("iOS/Features/SessionRecording/SessionStartView.swift")
    for token in [
        "DebugRuntimeOptions.shared",
        "availableSportCategories",
        "debugRuntimeOptions.isSnowModeEntryEnabled",
        "enforceAvailableSelectedCategory()",
        "selectedCategory = .skateboard",
    ]:
        if token not in session_start:
            fail(f"SessionStartView missing debug-toggle gate token: {token}")

    sport_mode = read("Shared/Models/SportMode.swift")
    if "case snow(SnowDiscipline)" not in sport_mode:
        fail("SportMode.snow must remain production code for later Snow tasks")
    nearby = sport_mode[max(0, sport_mode.find("case snow(SnowDiscipline)") - 80): sport_mode.find("case snow(SnowDiscipline)") + 120]
    if "#if DEBUG" in nearby or "#endif" in nearby:
        fail("SportMode.snow must not be wrapped in DEBUG-only compilation")

    for relative_path in [
        "iOS/Features/Debug/DebugFeatureFlag.swift",
        "iOS/Features/Debug/DebugToolsPanelView.swift",
    ]:
        require(relative_path, "snowModeEntry")
    require("iOS/Features/Debug/DebugRuntimeOptions.swift", "isSnowModeEntryEnabled")
    require("iOS/Features/Debug/DebugRuntimeOptions.swift", "snowModeEntryUserDefaultsKey")
    require("iOS/Features/Debug/DebugToolsPanelView.swift", "DebugToolAction.toggleSnowModeEntry.accessibilityIdentifier")

    for language in ["en", "zh-Hant", "ja"]:
        text = read(f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in [
            "debug.tools.snowMode.title",
            "debug.tools.snowMode.description",
            "debug.tools.snowMode.entryHint",
            "debug.tools.snowMode.toggle",
            "debug.tools.snowMode.entryEnabledHint",
            "debug.tools.snowMode.entryDisabledHint",
        ]:
            if f'"{key}"' not in text:
                fail(f"missing {key} in {language} localization")

    for relative_path in [
        "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
        "docs/history/DEV_LOG.md",
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    ]:
        require(relative_path, "Snow-Task-001a")
        require(relative_path, "snow mode public entry debug-gated")

    all_swift = "\n".join(path.read_text(encoding="utf-8") for path in ROOT.glob("**/*.swift"))
    if "SnowPrototype" in all_swift:
        fail("Snow-Task-001a must not introduce or depend on SnowPrototype namespace")
    if list(ROOT.glob("**/*.skatetrack")):
        fail(".skatetrack sample package must not be included in Snow-Task-001a")

    print("[snow-task-001a] PASS: Snow Mode production enum remains available while Session Start entry is controlled by a DEBUG toggle.")


if __name__ == "__main__":
    main()
