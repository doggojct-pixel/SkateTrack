#!/usr/bin/env python3
"""Verify Snow-Task-001 production SportMode integration.

This gate intentionally checks production files. It must not pass if Snow Mode is
only represented by a parallel SnowPrototype namespace or documentation-only work.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    ROOT / "Shared/Models/SnowDiscipline.swift",
    ROOT / "Shared/Models/SportMode.swift",
    ROOT / "iOS/Features/SessionRecording/SnowDisciplineSelectorView.swift",
    ROOT / "docs/process/PHASE_1C_SNOW_AGENT_STATE.md",
]

LOCALIZATION_KEYS = [
    "snow.sport.title",
    "snow.discipline.snowboard",
    "snow.discipline.skiing",
    "session.start.snow.subtitle",
    "mode.description.snow.snowboard",
    "mode.description.snow.skiing",
    "mode.tag.snowboard",
    "mode.tag.skiing",
    "history.filter.snow",
]

REQUIRED_SNIPPETS = {
    "Shared/Models/SnowDiscipline.swift": [
        "enum SnowDiscipline",
        "case snowboard",
        "case skiing",
        "var localizationKey",
    ],
    "Shared/Models/SportMode.swift": [
        "case snow(SnowDiscipline)",
        "case .snow:",
        "case let .snow(discipline):",
        "return \"snow.sport.title\"",
        "return discipline.localizationKey",
        "return false",
    ],
    "iOS/Features/SessionRecording/SessionStartSupportTypes.swift": [
        "case snow",
        "return \"snow.sport.title\"",
        "return \"session.start.snow.subtitle\"",
        "return SkateTrackSessionStartColors.ice",
    ],
    "iOS/Features/SessionRecording/SportCategoryPickerView.swift": [
        "case .snow:",
        "Image(systemName: category.iconName)",
    ],
    "iOS/Features/SessionRecording/SnowDisciplineSelectorView.swift": [
        "struct SnowDisciplineSelectorView",
        "ForEach(SnowDiscipline.allCases",
        "ModeSelectionCardView",
        "snow-discipline-",
    ],
    "iOS/Features/SessionRecording/SessionStartView.swift": [
        "selectedSnowDiscipline",
        "newCategory == .inline || newCategory == .snow",
        "SnowDisciplineSelectorView",
        "return .snow(selectedSnowDiscipline)",
    ],
    "iOS/Features/SessionRecording/LiveHUDView.swift": [
        "case .snow(_)?",
        "case .snow:",
        "SkateTrackSessionStartColors.ice",
    ],
    "iOS/Core/SensorEngine/SensorCalibrationEngine.swift": [
        "case let .snow(discipline):",
        "snowPriorityPlan(for: discipline)",
        "private func snowPriorityPlan",
    ],
    "Shared/Models/EquipmentProfile.swift": [
        "case (.snow, .snow):",
        "case .snow:",
        "(.skateboard, .snow)",
        "(.inlineSkates, .snow)",
    ],
    "iOS/Hooks/useSessionHistory.swift": [
        "case snow",
        "return \"history.filter.snow\"",
        "if case .snow = session.sportMode",
    ],
    "iOS/Core/HealthReminders/MockWeatherProvider.swift": [
        "case .snow(_)?",
        "adjusted.temperatureCelsius -= 3.0",
    ],
    "docs/process/PHASE_1C_SNOW_AGENT_STATE.md": [
        "Snow-Task-001",
        "SportMode.snow(SnowDiscipline)",
        "Snow-Task-001 verification token: production snow sport enum integrated.",
    ],
    "docs/history/DEV_LOG.md": [
        "Snow-Task-001 Sport Mode Integration Foundation + Preflight",
        "production `SnowDiscipline`",
        "Snow-Task-001 verification token: production snow sport enum integrated.",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Phase 1c Snow Mode Production Branch",
        "Shared/Models/SnowDiscipline.swift",
        "scripts/verify_snow_sport_enum.py",
    ],
}

PROJECT_TOKENS = [
    "SnowDiscipline.swift in Sources",
    "SnowDisciplineSelectorView.swift in Sources",
    "29C100000000000000000001 /* SnowDiscipline.swift */",
    "29C110000000000000000001 /* SnowDisciplineSelectorView.swift */",
]

FORBIDDEN_PATH_PARTS = [
    "Shared/WatchBridge",
]


def fail(message: str) -> None:
    print(f"[snow-task-001] FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def read(path: Path) -> str:
    if not path.exists():
        fail(f"missing required file: {rel(path)}")
    return path.read_text(encoding="utf-8")


def switch_blocks(text: str) -> list[str]:
    blocks: list[str] = []
    for match in re.finditer(r"\bswitch\b", text):
        start = match.start()
        brace = text.find("{", match.end())
        if brace == -1:
            continue
        depth = 0
        for index in range(brace, len(text)):
            char = text[index]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    blocks.append(text[start:index + 1])
                    break
    return blocks


def verify_switch_audit() -> None:
    sport_related_names = ("SportMode", "sportMode", "selectedSportMode", "session.sportMode")
    skipped = {"Shared/Models/SpotProfile.swift"}  # SpotActivityFamily is not SportMode.
    for swift_file in sorted(ROOT.glob("**/*.swift")):
        path_text = rel(swift_file)
        if any(part in path_text for part in FORBIDDEN_PATH_PARTS):
            continue
        text = swift_file.read_text(encoding="utf-8")
        if "case skateboard(BoardMode)" in text and "case snow(SnowDiscipline)" not in text:
            fail("SportMode enum does not include production snow case")
        if path_text in skipped:
            continue
        for block in switch_blocks(text):
            if ".skateboard" not in block or ".inline" not in block:
                continue
            header = block.split("{", 1)[0]
            if path_text in {"Shared/Models/EquipmentProfile.swift", "iOS/Features/EquipmentManager/EditEquipmentView.swift", "iOS/Features/EquipmentManager/EquipmentCardView.swift"} and "sportMode" not in header and "SportMode" not in header:
                continue
            nearby = text[max(0, text.find(block) - 160):text.find(block)] + block[:160]
            if any(name in nearby or name in block for name in sport_related_names):
                if ".snow" not in block:
                    fail(f"sport-related switch missing explicit .snow handling: {path_text}")


def verify_localization() -> None:
    for language in ["en", "zh-Hant", "ja"]:
        text = read(ROOT / f"Shared/Localization/{language}.lproj/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if f'"{key}"' not in text:
                fail(f"missing localization key {key} in {language}")


def main() -> None:
    for path in REQUIRED_FILES:
        read(path)

    for file_name, snippets in REQUIRED_SNIPPETS.items():
        text = read(ROOT / file_name)
        for snippet in snippets:
            if snippet not in text:
                fail(f"missing token in {file_name}: {snippet}")

    project_text = read(ROOT / "SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project_text:
            fail(f"project missing token: {token}")

    all_text = "\n".join(path.read_text(encoding="utf-8") for path in ROOT.glob("**/*.swift"))
    if "SnowPrototype" in all_text:
        fail("production Snow-Task-001 must not introduce or depend on SnowPrototype namespace")

    if list(ROOT.glob("**/*.skatetrack")):
        fail(".skatetrack sample package must not be included in Snow-Task-001")

    verify_switch_audit()
    verify_localization()

    print("[snow-task-001] PASS: production SnowDiscipline and SportMode.snow integration are explicit, localized, and prototype-free.")


if __name__ == "__main__":
    main()
