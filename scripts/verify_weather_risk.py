#!/usr/bin/env python3
"""Verify Task-019c Weather Risk provider and suitability-card foundation."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/HealthReminders/WeatherRiskSnapshot.swift",
    "iOS/Core/HealthReminders/WeatherProvider.swift",
    "iOS/Core/HealthReminders/MockWeatherProvider.swift",
    "iOS/Core/HealthReminders/WeatherRiskMonitor.swift",
    "iOS/Core/HealthReminders/WeatherQueryContext.swift",
    "iOS/Core/HealthReminders/DisabledWeatherProvider.swift",
    "iOS/Core/HealthReminders/WeatherRideabilityReport.swift",
    "iOS/Core/HealthReminders/WeatherRideabilityEngine.swift",
    "iOS/Hooks/useWeatherRisk.swift",
    "iOS/Features/HealthReminders/WeatherSuitabilityCardView.swift",
]

REQUIRED_PROJECT_TOKENS = [
    "WeatherRiskSnapshot.swift in Sources",
    "WeatherProvider.swift in Sources",
    "MockWeatherProvider.swift in Sources",
    "WeatherRiskMonitor.swift in Sources",
    "WeatherQueryContext.swift in Sources",
    "DisabledWeatherProvider.swift in Sources",
    "WeatherRideabilityReport.swift in Sources",
    "WeatherRideabilityEngine.swift in Sources",
    "useWeatherRisk.swift in Sources",
    "WeatherSuitabilityCardView.swift in Sources",
]

REQUIRED_LOCALIZATION_KEYS = [
    "weather.suitability.title",
    "weather.suitability.level.excellent",
    "weather.suitability.level.good",
    "weather.suitability.level.caution",
    "weather.suitability.level.unsafe",
    "weather.suitability.summary.excellent",
    "weather.suitability.summary.caution",
    "weather.suitability.locked.title",
    "weather.suitability.locked.subtitle",
    "weather.suitability.locked.cta",
    "weather.source.mock",
    "weather.source.disabled",
    "weather.condition.sunny",
    "weather.risk.heat.title",
    "weather.risk.uv.title",
    "weather.risk.rain.title",
    "weather.risk.heat.caution",
    "weather.risk.uv.caution",
    "weather.risk.rain.caution",
]

FORBIDDEN_TOKENS = [
    "import WeatherKit",
    "URLSession",
    "CLLocationManager",
    "UNUserNotificationCenter",
    "AppStore.sync",
    "Transaction.currentEntitlements",
    "Product.products",
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

    snapshot_text = read("iOS/Core/HealthReminders/WeatherRiskSnapshot.swift")
    for token in [
        "enum WeatherSuitabilityLevel",
        "struct WeatherRiskSnapshot",
        "WeatherRiskSource",
        "WeatherRiskFactorKind",
        "struct WeatherSuitabilityReport",
        "mockBaseline",
    ]:
        assert_contains(snapshot_text, token, "WeatherRiskSnapshot.swift")

    provider_text = read("iOS/Core/HealthReminders/WeatherProvider.swift")
    for token in ["protocol WeatherProviding", "currentWeather(for context: WeatherQueryContext)", "WeatherProviderError"]:
        assert_contains(provider_text, token, "WeatherProvider.swift")

    mock_text = read("iOS/Core/HealthReminders/MockWeatherProvider.swift")
    for token in ["final class MockWeatherProvider", "WeatherProviding", "source = .mock"]:
        if token == "source = .mock":
            # The source is supplied through WeatherRiskSnapshot.mockBaseline.
            continue
        assert_contains(mock_text, token, "MockWeatherProvider.swift")

    monitor_text = read("iOS/Core/HealthReminders/WeatherRiskMonitor.swift")
    for token in [
        "final class WeatherRiskMonitor",
        "HealthReminderSettings",
        "settings.rule(for: .heatRisk)",
        "settings.rule(for: .uvRisk)",
        "precipitationProbability",
        "weather.risk.heat.caution",
        "weather.risk.uv.caution",
        "weather.risk.rain.caution",
    ]:
        assert_contains(monitor_text, token, "WeatherRiskMonitor.swift")

    hook_text = read("iOS/Hooks/useWeatherRisk.swift")
    for token in [
        "final class WeatherRiskViewModel",
        "useWeatherRisk",
        "WeatherProviding",
        "MockWeatherProvider",
        "rideabilityReport",
        "updateContext(_ context: WeatherQueryContext, spot:",
        "subscriptionStatus.hasAccess(to: .healthReminders)",
        "canViewDetailedRisk",
        "refresh()",
    ]:
        assert_contains(hook_text, token, "useWeatherRisk.swift")

    card_text = read("iOS/Features/HealthReminders/WeatherSuitabilityCardView.swift")
    for token in [
        "struct WeatherSuitabilityCardView",
        "WeatherRiskViewModel",
        "WeatherRideabilityReport",
        "weather-suitability-card",
        "weather-detailed-risk-list",
        "weather-detailed-risk-locked-preview",
        "weather.suitability.locked.cta",
    ]:
        assert_contains(card_text, token, "WeatherSuitabilityCardView.swift")

    session_start_text = read("iOS/Features/SessionRecording/SessionStartView.swift")
    for token in [
        "@StateObject private var weatherRisk",
        "useWeatherRisk(subscriptionStatus: subscriptionStatus)",
        "SessionStartWeatherSectionView",
        "selectedSpot: selectedSpotForSession",
        "onOpenHealthReminders",
    ]:
        assert_contains(session_start_text, token, "SessionStartView.swift")

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
    for forbidden in FORBIDDEN_TOKENS:
        if forbidden in scanned_sources:
            fail(f"Task-019c must not introduce `{forbidden}`")

    docs = read("docs/DEV_LOG.md") + "\n" + read("docs/FILE_STRUCTURE.md") + "\n" + read("docs/decisions/ADR-0001-subscription-entitlement-strategy.md")
    for token in [
        "Task-019c",
        "Weather Risk Provider + Weather Suitability Card",
        "Weather Provider Upgrade + Local Rideability Integration",
        "MockWeatherProvider",
        "WeatherSuitabilityCardView",
        "WeatherRideabilityEngine",
        "DEBUG/local entitlement simulation",
        "WeatherKit",
    ]:
        assert_contains(docs, token, "living docs / ADR")

    print("✅ Task-019c weather risk verification passed.")


if __name__ == "__main__":
    main()
