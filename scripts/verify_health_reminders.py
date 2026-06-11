#!/usr/bin/env python3
"""Verify Task-019a/019b Health Reminder settings and in-app banner foundation."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/HealthReminders/HealthReminderRule.swift",
    "iOS/Core/HealthReminders/HealthReminderSettingsStore.swift",
    "iOS/Core/HealthReminders/HealthReminderEvent.swift",
    "iOS/Core/HealthReminders/HealthReminderScheduler.swift",
    "iOS/Hooks/useHealthReminders.swift",
    "iOS/Features/HealthReminders/HealthReminderSettingsView.swift",
    "iOS/Features/HealthReminders/HealthReminderBannerView.swift",
]

REQUIRED_PROJECT_TOKENS = [
    "HealthReminderRule.swift in Sources",
    "HealthReminderSettingsStore.swift in Sources",
    "HealthReminderEvent.swift in Sources",
    "HealthReminderScheduler.swift in Sources",
    "useHealthReminders.swift in Sources",
    "HealthReminderSettingsView.swift in Sources",
    "HealthReminderBannerView.swift in Sources",
    "iOS/Core/HealthReminders",
    "iOS/Features/HealthReminders",
]

REQUIRED_LOCALIZATION_KEYS = [
    "health.reminders.nav_title",
    "health.reminders.title",
    "health.reminders.entry.title",
    "health.reminders.entry.subtitle.locked",
    "health.reminders.entry.subtitle.unlocked",
    "health.reminders.access.locked.title",
    "health.reminders.access.unlocked.title",
    "health.reminders.locked.cta",
    "health.reminders.hydration.title",
    "health.reminders.rest.title",
    "health.reminders.cooldown.title",
    "health.reminders.heat.title",
    "health.reminders.uv.title",
    "health.reminders.banner.hydration.title",
    "health.reminders.banner.hydration.message",
    "health.reminders.banner.rest.title",
    "health.reminders.banner.rest.message",
    "health.reminders.banner.cooldown.title",
    "health.reminders.banner.cooldown.message",
    "health.reminders.banner.dismiss",
]

FORBIDDEN_SOURCE_TOKENS = [
    "UNUserNotificationCenter",
    "WeatherKit",
    "WeatherService",
    "AppStore.sync",
    "Transaction.currentEntitlements",
    "Product.products",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


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

    rule_text = read("iOS/Core/HealthReminders/HealthReminderRule.swift")
    for token in [
        "enum HealthReminderKind",
        "case hydration",
        "case rest",
        "case cooldownStretch",
        "case heatRisk",
        "case uvRisk",
        "struct HealthReminderSettings",
    ]:
        assert_contains(rule_text, token, "HealthReminderRule.swift")

    store_text = read("iOS/Core/HealthReminders/HealthReminderSettingsStore.swift")
    for token in [
        "final class HealthReminderSettingsStore",
        "UserDefaults",
        "setEnabled",
        "setIntervalMinutes",
        "setThreshold",
        "resetToDefaults",
    ]:
        assert_contains(store_text, token, "HealthReminderSettingsStore.swift")

    event_text = read("iOS/Core/HealthReminders/HealthReminderEvent.swift")
    for token in [
        "enum HealthReminderEventKind",
        "case hydration",
        "case rest",
        "case cooldownStretch",
        "struct HealthReminderEvent",
    ]:
        assert_contains(event_text, token, "HealthReminderEvent.swift")

    scheduler_text = read("iOS/Core/HealthReminders/HealthReminderScheduler.swift")
    for token in [
        "final class HealthReminderScheduler",
        "nextEvent",
        "status: SessionRecordingStatus",
        "case .recording",
        "case .ending, .saving",
        "return nil",
        "reset()",
    ]:
        assert_contains(scheduler_text, token, "HealthReminderScheduler.swift")

    hook_text = read("iOS/Hooks/useHealthReminders.swift")
    for token in [
        "final class HealthReminderViewModel",
        "useHealthReminders",
        "subscriptionStatus.hasAccess(to: .healthReminders)",
        "guard canEditSettings else { return }",
        "activeReminderEvent",
        "updateSessionReminderState",
        "dismissActiveReminder",
    ]:
        assert_contains(hook_text, token, "useHealthReminders.swift")

    view_text = read("iOS/Features/HealthReminders/HealthReminderSettingsView.swift")
    for token in [
        "HealthReminderSettingsEntryCardView",
        "HealthReminderSettingsView",
        "SubscriptionPaywallView",
        "lockedFeature: .healthReminders",
        "HealthReminderRuleCard",
        "readOnlyRulesPreview",
        "Stepper",
        "Toggle",
    ]:
        assert_contains(view_text, token, "HealthReminderSettingsView.swift")

    banner_text = read("iOS/Features/HealthReminders/HealthReminderBannerView.swift")
    for token in [
        "struct HealthReminderBannerView",
        "HealthReminderEvent",
        "health.reminders.banner.dismiss",
        "health-reminder-banner",
    ]:
        assert_contains(banner_text, token, "HealthReminderBannerView.swift")

    live_hud_text = read("iOS/Features/SessionRecording/LiveHUDView.swift")
    for token in [
        "subscriptionStatus: SubscriptionStatusViewModel",
        "useHealthReminders(subscriptionStatus: subscriptionStatus)",
        "HealthReminderBannerView",
        "updateSessionReminderState",
    ]:
        assert_contains(live_hud_text, token, "LiveHUDView.swift")

    session_start_text = read("iOS/Features/SessionRecording/SessionStartView.swift")
    for token in [
        "isHealthReminderSettingsPresented",
        "HealthReminderSettingsEntryCardView",
        "HealthReminderSettingsView(subscriptionStatus: subscriptionStatus)",
    ]:
        assert_contains(session_start_text, token, "SessionStartView.swift")

    root_text = read("iOS/App/RootNavigationView.swift")
    for token in [
        "pendingPostSessionStretchReminderEvent",
        "schedulePostSessionStretchReminderIfNeeded",
        "HealthReminderSettingsStore.shared.settings.rule(for: .cooldownStretch)",
        "postSessionStretchReminderTask",
        "postSessionStretchReminderOverlay",
        "HealthReminderBannerView",
        "post-session-stretch-reminder-overlay",
    ]:
        assert_contains(root_text, token, "RootNavigationView.swift")

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
    for forbidden in FORBIDDEN_SOURCE_TOKENS:
        if forbidden in scanned_sources:
            fail(f"Task-019a must not introduce `{forbidden}`")

    docs = read("docs/DEV_LOG.md") + "\n" + read("docs/FILE_STRUCTURE.md") + "\n" + read("docs/decisions/ADR-0001-subscription-entitlement-strategy.md")
    for token in [
        "Task-019a",
        "Task-019b",
        "Health Reminder Rules + Settings Foundation",
        "Health Reminder Scheduler + In-App Reminder Banner",
        "GatedFeature.healthReminders",
        "DEBUG/local entitlement simulation",
        "WeatherKit",
        "UserNotifications scheduling",
    ]:
        assert_contains(docs, token, "living docs / ADR")

    print("✅ Task-019a/019b health reminder verification passed.")


if __name__ == "__main__":
    main()
