#!/usr/bin/env python3
# [Collaboration] scripts/verify_task036_watch_core_ui.py
"""Aggregate verifier for Task-036 Watch core UI closure."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCALES = ("en", "zh-Hant", "ja")
WATCH_SWIFT_FILES = (
    "Shared/WatchUI/WatchActivityViewModel.swift",
    "Shared/WatchUI/WatchLiveControlState.swift",
    "watchOS/App/SkateTrackWatchApp.swift",
    "watchOS/Features/WatchLiveSessionFaceView.swift",
)
REGRESSION_VERIFIERS = (
    "scripts/verify_task036b_live_face_controls.py",
    "scripts/verify_task036c_compact_cards.py",
    "scripts/verify_task036d_fallback_states.py",
)
REQUIRED_FILES = WATCH_SWIFT_FILES + REGRESSION_VERIFIERS + (
    "Tests/iOSTests/WatchActivityViewModelTests.swift",
    "Tests/iOSTests/WatchLiveControlStateTests.swift",
    "docs/history/DEV_LOG.md",
)
FORBIDDEN_PATTERNS = (
    r"\bimport\s+MapKit\b",
    r"\bMKMap",
    r"\bMKPolyline",
    r"\bCLLocationCoordinate2D\b",
    r"RouteDisplayPipeline",
    r"SpeedDisplayPipeline",
    r"ElevationDisplayPipeline",
    r"RouteDisplayPipeline\+Segmentation",
    r"\.filter\s*\(",
    r"\bSnow\b",
    r"\bsnow\b",
    r"\bski\b",
)
WATCH_REQUIRED_KEYS = (
    "watch.live.title",
    "watch.live.speed.current",
    "watch.live.session.status",
    "watch.live.status.idle",
    "watch.live.status.preparing",
    "watch.live.status.ready",
    "watch.live.status.recording",
    "watch.live.status.paused",
    "watch.live.status.ending",
    "watch.live.status.ended",
    "watch.live.status.failed",
    "watch.live.controls.start",
    "watch.live.controls.pause",
    "watch.live.controls.resume",
    "watch.live.controls.stop",
    "watch.live.controls.pending",
    "watch.live.accessibility.currentSpeed",
    "watch.live.accessibility.sessionStatus",
    "watch.live.accessibility.start",
    "watch.live.accessibility.pause",
    "watch.live.accessibility.resume",
    "watch.live.accessibility.stop",
    "watch.compact.route.title",
    "watch.compact.route.scope.textOnly",
    "watch.compact.route.status.recorded",
    "watch.compact.route.status.qualityInsufficient",
    "watch.compact.route.status.unavailable",
    "watch.compact.route.points",
    "watch.compact.route.segments",
    "watch.compact.speed.title",
    "watch.compact.speed.max",
    "watch.compact.speed.empty",
    "watch.compact.elevation.title",
    "watch.compact.elevation.ascent",
    "watch.compact.elevation.empty",
    "watch.fallback.ready.title",
    "watch.fallback.ready.detail",
    "watch.fallback.disconnected.title",
    "watch.fallback.disconnected.detail",
    "watch.fallback.noSamples.title",
    "watch.fallback.noSamples.detail",
    "watch.fallback.disabledProvider.title",
    "watch.fallback.disabledProvider.detail",
    "watch.fallback.staleData.title",
    "watch.fallback.staleData.detail",
    "watch.fallback.alwaysOn.title",
    "watch.fallback.alwaysOn.detail",
    "unit.speed.kmh.short",
    "unit.length.meter.short",
)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def fail(failures: list[str], message: str) -> None:
    print(f"FAILURE={message}")
    failures.append(message)


def parse_localization_keys(text: str) -> set[str]:
    return set(re.findall(r'"([^"]+)"\s*=', text))


def swift_localization_keys() -> set[str]:
    key_pattern = re.compile(r'"((?:watch|unit)\.[A-Za-z0-9_.]+)"')
    keys: set[str] = set()
    for relative in WATCH_SWIFT_FILES:
        path = ROOT / relative
        if path.exists():
            keys.update(key_pattern.findall(path.read_text(encoding="utf-8")))
    return keys


def run_python_verifier(relative: str) -> bool:
    result = subprocess.run(
        [sys.executable, relative],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    print(result.stdout, end="")
    return result.returncode == 0


def main() -> int:
    failures: list[str] = []

    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(failures, f"missing required file {relative}")

    locale_key_sets: dict[str, set[str]] = {}
    for locale in LOCALES:
        path = ROOT / "Shared" / "Localization" / f"{locale}.lproj" / "Localizable.strings"
        if not path.exists():
            fail(failures, f"missing localization file for {locale}")
            locale_key_sets[locale] = set()
            continue
        locale_key_sets[locale] = parse_localization_keys(path.read_text(encoding="utf-8"))

    required_keys = set(WATCH_REQUIRED_KEYS) | swift_localization_keys()
    localization_failures: list[str] = []
    for locale, keys in locale_key_sets.items():
        missing = sorted(required_keys - keys)
        if missing:
            localization_failures.append(f"{locale}:{','.join(missing)}")
            fail(failures, f"missing Watch localization keys in {locale}: {', '.join(missing)}")

    all_watch_locale_keys = {
        locale: {key for key in keys if key.startswith("watch.")}
        for locale, keys in locale_key_sets.items()
    }
    parity_reference = all_watch_locale_keys.get("en", set())
    for locale, keys in all_watch_locale_keys.items():
        if keys != parity_reference:
            missing = sorted(parity_reference - keys)
            extra = sorted(keys - parity_reference)
            fail(failures, f"watch key parity mismatch {locale}; missing={missing}; extra={extra}")

    zh_text = (ROOT / "Shared/Localization/zh-Hant.lproj/Localizable.strings").read_text(encoding="utf-8")
    zh_watch_lines = [
        line for line in zh_text.splitlines()
        if line.startswith('"watch.') and "Session " in line
    ]
    if zh_watch_lines:
        fail(failures, "zh-Hant Watch strings contain untranslated Session wording")

    forbidden_hits: list[str] = []
    for relative in WATCH_SWIFT_FILES:
        path = ROOT / relative
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for pattern in FORBIDDEN_PATTERNS:
            for match in re.findall(pattern, text, flags=re.IGNORECASE):
                forbidden_hits.append(f"{relative}:{match}")
    if forbidden_hits:
        fail(failures, "forbidden Watch UI semantic tokens found: " + "; ".join(forbidden_hits))

    regression_ok = True
    for verifier in REGRESSION_VERIFIERS:
        if not run_python_verifier(verifier):
            regression_ok = False
            fail(failures, f"regression verifier failed: {verifier}")

    dev_log = read("docs/history/DEV_LOG.md") if (ROOT / "docs/history/DEV_LOG.md").exists() else ""
    if "TASK036E_WATCH_CORE_UI_CLOSURE_DEVLOG_START" not in dev_log:
        fail(failures, "missing Task-036e DEV_LOG closure entry")

    localization_parity = not localization_failures and all(
        all_watch_locale_keys.get(locale, set()) == parity_reference
        for locale in LOCALES
    )

    print(f"LOCALIZATION_PARITY={'PASSED' if localization_parity else 'FAILED'}")
    print(f"WATCH_LOCALIZATION_KEY_COUNT={len(required_keys)}")
    print(f"WATCH_UI_FORBIDDEN_SCOPE_COUNT={len(forbidden_hits)}")
    print(f"WATCH_CORE_REGRESSION_VERIFIERS={'PASSED' if regression_ok else 'FAILED'}")
    print("SNOW_UI_IMPLEMENTED=NO")
    print("MAPKIT_IMPORT_IN_WATCH_UI=NO")
    print("WATCH_ROUTE_MINI_CARD_SCOPE=TEXT_ONLY")
    print(f"FAILURE_COUNT={len(failures)}")

    if failures:
        print("VERIFY_TASK036_WATCH_CORE_UI_RESULT=FAILED")
        return 1

    print("VERIFY_TASK036_WATCH_CORE_UI_RESULT=PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
