#!/usr/bin/env python3
"""Verify Task-022 weather provider upgrade and local rideability integration."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/HealthReminders/WeatherQueryContext.swift",
    "iOS/Core/HealthReminders/DisabledWeatherProvider.swift",
    "iOS/Core/HealthReminders/WeatherRideabilityReport.swift",
    "iOS/Core/HealthReminders/WeatherRideabilityEngine.swift",
    "iOS/Core/HealthReminders/WeatherProvider.swift",
    "iOS/Core/HealthReminders/MockWeatherProvider.swift",
    "iOS/Hooks/useWeatherRisk.swift",
    "iOS/Features/SessionRecording/SessionStartWeatherSectionView.swift",
    "iOS/Features/HealthReminders/WeatherSuitabilityCardView.swift",
    "iOS/Features/HealthReminders/WeatherRiskFactorRowView.swift",
    "iOS/Features/HealthReminders/WeatherRideabilityStatusChipView.swift",
    "iOS/Features/Spots/SpotRideabilityCardView.swift",
    "iOS/Features/Spots/SpotDetailView.swift",
    "iOS/Features/Spots/SpotListView.swift",
    "iOS/Features/Spots/SpotMapView.swift",
]

REQUIRED_PROJECT_TOKENS = [
    "WeatherQueryContext.swift in Sources",
    "DisabledWeatherProvider.swift in Sources",
    "WeatherRideabilityReport.swift in Sources",
    "WeatherRideabilityEngine.swift in Sources",
    "SessionStartWeatherSectionView.swift in Sources",
    "WeatherRiskFactorRowView.swift in Sources",
    "WeatherRideabilityStatusChipView.swift in Sources",
    "SpotRideabilityCardView.swift in Sources",
]

REQUIRED_LOCALIZATION_KEYS = [
    "weather.source.disabled",
    "weather.context.rideStart",
    "weather.context.spotPreview",
    "weather.context.noSpot",
    "weather.rideability.summary.excellent",
    "weather.rideability.summary.good",
    "weather.rideability.summary.caution",
    "weather.rideability.summary.unsafe",
    "weather.rideability.factor.surface.title",
    "weather.rideability.factor.crowd.title",
    "weather.rideability.factor.safety.title",
    "weather.rideability.factor.local.title",
    "weather.rideability.factor.local.none",
    "weather.rideability.factor.surface.unknown",
    "weather.rideability.factor.crowd.busy",
    "weather.rideability.factor.safety.caution",
    "weather.rideability.spot.title",
    "weather.rideability.spot.locked.title",
    "weather.rideability.spot.locked.subtitle",
    "spots.surface.unknown",
]

FORBIDDEN_SOURCE_PATTERNS = [
    r"import\s+WeatherKit",
    r"import\s+CoreLocation",
    r"CLLocationManager",
    r"URLSession",
    r"api[_-]?key",
    r"secret",
    r"Product\.products",
    r"Transaction\.currentEntitlements",
    r"AppStore\.sync",
]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def assert_contains(text: str, token: str, context: str) -> None:
    if token not in text:
        fail(f"Missing `{token}` in {context}")


def extract_keys(path: str) -> set[str]:
    text = read(path)
    return set(re.findall(r'^"([^"]+)"\s*=', text, flags=re.MULTILINE))


def main() -> None:
    for relative in REQUIRED_FILES:
        path = ROOT / relative
        if not path.exists():
            fail(f"Missing required file: {relative}")
        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if line_count > 500:
            fail(f"{relative} exceeds 500-line limit: {line_count}")

    provider_text = read("iOS/Core/HealthReminders/WeatherProvider.swift")
    for token in [
        "protocol WeatherProviding",
        "currentWeather(for context: WeatherQueryContext)",
        "currentWeather()",
        "externalServiceNotConfigured",
    ]:
        assert_contains(provider_text, token, "WeatherProvider.swift")

    context_text = read("iOS/Core/HealthReminders/WeatherQueryContext.swift")
    for token in ["WeatherQueryPurpose", "rideStart", "spotPreview", "coordinate", "sportMode"]:
        assert_contains(context_text, token, "WeatherQueryContext.swift")

    disabled_text = read("iOS/Core/HealthReminders/DisabledWeatherProvider.swift")
    for token in ["final class DisabledWeatherProvider", "WeatherProviding", "disabledFallback"]:
        assert_contains(disabled_text, token, "DisabledWeatherProvider.swift")

    report_text = read("iOS/Core/HealthReminders/WeatherRideabilityReport.swift")
    for token in [
        "enum WeatherRideabilityFactorKind",
        "struct WeatherRideabilityFactor",
        "struct WeatherRideabilityReport",
        "summaryKey",
        "weather.rideability.summary.caution",
    ]:
        assert_contains(report_text, token, "WeatherRideabilityReport.swift")

    engine_text = read("iOS/Core/HealthReminders/WeatherRideabilityEngine.swift")
    for token in [
        "final class WeatherRideabilityEngine",
        "surfaceFactor(for spot:",
        "crowdFactor(for spot:",
        "safetyFactor(for spot:",
        "WeatherRideabilityFactorKind(weatherRiskKind:",
    ]:
        assert_contains(engine_text, token, "WeatherRideabilityEngine.swift")

    hook_text = read("iOS/Hooks/useWeatherRisk.swift")
    for token in [
        "rideabilityReport",
        "WeatherRideabilityEngine",
        "updateContext(_ context: WeatherQueryContext, spot:",
        "provider.currentWeather(for: currentContext)",
        "subscriptionStatus.hasAccess(to: .healthReminders)",
    ]:
        assert_contains(hook_text, token, "useWeatherRisk.swift")

    session_start_text = read("iOS/Features/SessionRecording/SessionStartView.swift")
    for token in ["SessionStartWeatherSectionView", "selectedSpot: selectedSpotForSession"]:
        assert_contains(session_start_text, token, "SessionStartView.swift")
    if len(session_start_text.splitlines()) >= 450:
        fail("SessionStartView.swift should stay comfortably below 450 lines after Task-022")

    spot_detail_text = read("iOS/Features/Spots/SpotDetailView.swift")
    for token in ["SpotRideabilityCardView", "WeatherRiskViewModel", "onOpenHealthReminders"]:
        assert_contains(spot_detail_text, token, "SpotDetailView.swift")

    spot_list_text = read("iOS/Features/Spots/SpotListView.swift")
    for token in ["useWeatherRisk(subscriptionStatus:", "rideabilityLevel(for:", "HealthReminderSettingsView"]:
        assert_contains(spot_list_text, token, "SpotListView.swift")

    spot_map_text = read("iOS/Features/Spots/SpotMapView.swift")
    for token in ["rideabilityLevelProvider", "WeatherRideabilityStatusChipView"]:
        assert_contains(spot_map_text, token, "SpotMapView.swift")

    card_text = read("iOS/Features/HealthReminders/WeatherSuitabilityCardView.swift")
    for token in [
        "WeatherRideabilityReport",
        "WeatherRiskFactorRowView",
        "WeatherRideabilityStatusChipView",
        "weather.context.noSpot",
        "weather-detailed-risk-list",
    ]:
        assert_contains(card_text, token, "WeatherSuitabilityCardView.swift")

    project_text = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in REQUIRED_PROJECT_TOKENS:
        assert_contains(project_text, token, "project.pbxproj")

    en_keys = extract_keys("Shared/Localization/en.lproj/Localizable.strings")
    zh_keys = extract_keys("Shared/Localization/zh-Hant.lproj/Localizable.strings")
    for key in REQUIRED_LOCALIZATION_KEYS:
        if key not in en_keys:
            fail(f"Missing English localization key: {key}")
        if key not in zh_keys:
            fail(f"Missing zh-Hant localization key: {key}")

    scanned_sources = "\n".join(read(relative) for relative in REQUIRED_FILES)
    for pattern in FORBIDDEN_SOURCE_PATTERNS:
        if re.search(pattern, scanned_sources, flags=re.IGNORECASE):
            fail(f"Task-022 must not introduce forbidden source pattern: {pattern}")

    docs = read("docs/history/DEV_LOG.md") + "\n" + read("docs/reference/FILE_STRUCTURE.md") + "\n" + read("docs/adr/ADR-INDEX.md")
    for token in [
        "Task-022",
        "Weather Provider Upgrade + Local Rideability Integration",
        "DisabledWeatherProvider",
        "WeatherRideabilityEngine",
        "provider boundary",
        "no WeatherKit",
    ]:
        assert_contains(docs, token, "living docs / ADR-0002")

    print("✅ Task-022 weather rideability verification passed.")


if __name__ == "__main__":
    main()
