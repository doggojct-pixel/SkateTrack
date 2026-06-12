#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required_files = [
    "Shared/Models/Achievement.swift",
    "Shared/Models/WeeklyChallenge.swift",
    "Shared/Models/WeeklyChallengeCompletionRecord.swift",
    "iOS/Core/Achievements/AchievementCatalog.swift",
    "iOS/Core/Achievements/AchievementEngine.swift",
    "iOS/Core/Achievements/AchievementUnlockStore.swift",
    "iOS/Core/Achievements/WeeklyChallengeEngine.swift",
    "iOS/Core/Achievements/WeeklyChallengeCompletionStore.swift",
    "iOS/Hooks/useAchievements.swift",
    "iOS/Hooks/useAchievementDashboard.swift",
    "iOS/Features/Achievements/AchievementListView.swift",
    "iOS/Features/Achievements/AchievementCardView.swift",
    "iOS/Features/Achievements/AchievementProgressRingView.swift",
    "iOS/Features/Achievements/WeeklyChallengeCardView.swift",
    "iOS/Features/Achievements/AchievementRelatedStatsLinksView.swift",
    "iOS/Features/Achievements/WeeklyChallengePeriodBadgeView.swift",
    "iOS/Features/SessionRecording/SessionStartAchievementDashboardCardView.swift",
    "docs/decisions/ADR-0005-achievements-and-challenges-scope-strategy.md",
]

for relative in required_files:
    path = ROOT / relative
    if not path.exists():
        print(f"❌ Missing Task-024 achievement file: {relative}")
        sys.exit(1)
    if relative.endswith(('.swift', '.md')):
        first_line = path.read_text().splitlines()[0]
        if relative.endswith('.swift') and "區" not in first_line:
            print(f"❌ Missing zone header: {relative}")
            sys.exit(1)
    line_count = len(path.read_text().splitlines())
    if relative.endswith('.swift') and line_count > 500:
        print(f"❌ File exceeds 500 lines: {relative} ({line_count})")
        sys.exit(1)

shared_text = (ROOT / "Shared/Models/Achievement.swift").read_text()
for token in [
    "AchievementDefinition",
    "AchievementProgress",
    "AchievementUnlockRecord",
    "case activeWeeks",
    "case equipmentProfiles",
    "Codable",
    "Sendable",
]:
    if token not in shared_text:
        print(f"❌ Achievement.swift missing token: {token}")
        sys.exit(1)

weekly_text = (ROOT / "Shared/Models/WeeklyChallenge.swift").read_text()
for token in [
    "WeeklyChallengeDefinition",
    "WeeklyChallengeProgress",
    "WeeklyChallengeKind",
    "weekIdentifier",
    "completedAt",
    "weeklyNoFallSessionCount",
    "weeklyGearTrackedSessionCount",
    "Codable",
    "Sendable",
]:
    if token not in weekly_text:
        print(f"❌ WeeklyChallenge.swift missing token: {token}")
        sys.exit(1)

completion_record_text = (ROOT / "Shared/Models/WeeklyChallengeCompletionRecord.swift").read_text()
for token in ["WeeklyChallengeCompletionRecord", "makeID", "completedAt", "Codable", "Sendable"]:
    if token not in completion_record_text:
        print(f"❌ WeeklyChallengeCompletionRecord.swift missing token: {token}")
        sys.exit(1)

feature_text = (ROOT / "Shared/Constants/FeatureFlags.swift").read_text()
for token in ["case advancedChallenges", "feature.advanced_challenges"]:
    if token not in feature_text:
        print(f"❌ FeatureFlags.swift missing advanced challenge token: {token}")
        sys.exit(1)

hook_text = (ROOT / "iOS/Hooks/useAchievements.swift").read_text()
for token in [
    "SessionRepositoryProtocol",
    "EquipmentRepositoryProtocol",
    "SpotRepositoryProtocol",
    "AchievementUnlockStore",
    "WeeklyChallengeCompletionStore",
    "newlyCompletedRecords",
    "hasAccess(to: .advancedChallenges)",
]:
    if token not in hook_text:
        print(f"❌ useAchievements.swift missing token: {token}")
        sys.exit(1)

dashboard_hook_text = (ROOT / "iOS/Hooks/useAchievementDashboard.swift").read_text()
for token in ["AchievementDashboardViewModel", "AchievementDashboardSnapshot", "WeeklyChallengeEngine", "SessionRepositoryProtocol"]:
    if token not in dashboard_hook_text:
        print(f"❌ useAchievementDashboard.swift missing token: {token}")
        sys.exit(1)

for relative in [
    "iOS/Core/Achievements/AchievementCatalog.swift",
    "iOS/Core/Achievements/AchievementEngine.swift",
    "iOS/Core/Achievements/AchievementUnlockStore.swift",
    "iOS/Core/Achievements/WeeklyChallengeEngine.swift",
    "iOS/Core/Achievements/WeeklyChallengeCompletionStore.swift",
]:
    text = (ROOT / relative).read_text()
    if "import SwiftUI" in text or "import UIKit" in text:
        print(f"❌ Core achievement file must not import UI frameworks: {relative}")
        sys.exit(1)

catalog_text = (ROOT / "iOS/Core/Achievements/AchievementCatalog.swift").read_text()
for token in ["gear_ready", "two_active_weeks_advanced", "five_safe_sessions_advanced"]:
    if token not in catalog_text:
        print(f"❌ AchievementCatalog.swift missing Task-024b definition: {token}")
        sys.exit(1)

weekly_engine_text = (ROOT / "iOS/Core/Achievements/WeeklyChallengeEngine.swift").read_text()
for token in ["weekly_safe_session", "weekly_gear_flow_advanced", "weekIdentifier", "newlyCompletedRecords"]:
    if token not in weekly_engine_text:
        print(f"❌ WeeklyChallengeEngine.swift missing Task-024b token: {token}")
        sys.exit(1)

root_text = (ROOT / "iOS/App/RootNavigationView.swift").read_text()
for token in [
    "case achievements",
    "AchievementListView(",
    "onOpenHistory:",
    "onOpenAchievements:",
    "achievements.title",
]:
    if token not in root_text:
        print(f"❌ RootNavigationView.swift missing token: {token}")
        sys.exit(1)

session_start_text = (ROOT / "iOS/Features/SessionRecording/SessionStartView.swift").read_text()
for token in ["AchievementDashboardViewModel", "SessionStartAchievementDashboardCardView", "useAchievementDashboard"]:
    if token not in session_start_text:
        print(f"❌ SessionStartView.swift missing dashboard token: {token}")
        sys.exit(1)

ui_text = (ROOT / "iOS/Features/Achievements/AchievementListView.swift").read_text()
for forbidden in ["SessionRepository", "EquipmentRepository", "SpotRepository", "CoreData"]:
    if forbidden in ui_text:
        print(f"❌ AchievementListView should not directly access repositories/CoreData: {forbidden}")
        sys.exit(1)
for token in [
    "SubscriptionPaywallView",
    ".advancedChallenges",
    "WeeklyChallengeCardView",
    "AchievementCardView",
    "AchievementRelatedStatsLinksView",
    "completedWeeklyChallengeCount",
]:
    if token not in ui_text:
        print(f"❌ AchievementListView.swift missing token: {token}")
        sys.exit(1)

for relative in [
    "iOS/Features/Achievements/WeeklyChallengeCardView.swift",
    "iOS/Features/Achievements/WeeklyChallengePeriodBadgeView.swift",
    "iOS/Features/SessionRecording/SessionStartAchievementDashboardCardView.swift",
]:
    text = (ROOT / relative).read_text()
    if "WeeklyChallengePeriodBadgeView" not in text and relative.endswith("WeeklyChallengeCardView.swift"):
        print("❌ WeeklyChallengeCardView.swift missing period badge")
        sys.exit(1)

project_text = (ROOT / "SkateTrack.xcodeproj/project.pbxproj").read_text()
for relative in required_files:
    if relative.endswith(".md"):
        continue
    filename = Path(relative).name
    if filename not in project_text:
        print(f"❌ project.pbxproj missing source membership for: {filename}")
        sys.exit(1)

main_sources_match = re.search(
    r'2EAF53E66952909850FC43F9 /\* Sources \*/ = \{.*?files = \((.*?)\);\s*runOnlyForDeploymentPostprocessing = 0;',
    project_text,
    flags=re.S,
)
if not main_sources_match:
    print("❌ Could not locate SkateTrack-iOS Sources build phase")
    sys.exit(1)
main_sources = main_sources_match.group(1)
if main_sources.count("WeeklyChallengeCompletionRecord.swift in Sources") != 1:
    print("❌ WeeklyChallengeCompletionRecord.swift must appear exactly once in SkateTrack-iOS Compile Sources")
    sys.exit(1)

for lang in ["en.lproj", "zh-Hant.lproj"]:
    loc_text = (ROOT / "Shared/Localization" / lang / "Localizable.strings").read_text()
    for key in [
        "achievements.title",
        "achievements.dashboard.title",
        "achievements.related.title",
        "achievements.gearReady.title",
        "achievements.advanced.activeWeeks.title",
        "challenges.weekly.title",
        "challenges.period.format",
        "challenges.weeklySafeSession.title",
        "feature.advanced_challenges",
    ]:
        if f'"{key}"' not in loc_text:
            print(f"❌ {lang}/Localizable.strings missing key: {key}")
            sys.exit(1)

for doc in [
    "docs/DEV_LOG.md",
    "docs/FILE_STRUCTURE.md",
    "docs/decisions/ADR-0001-subscription-entitlement-strategy.md",
    "docs/decisions/ADR-0005-achievements-and-challenges-scope-strategy.md",
]:
    text = (ROOT / doc).read_text()
    if "Task-024b" not in text:
        print(f"❌ {doc} missing Task-024b documentation")
        sys.exit(1)

adr5 = (ROOT / "docs/decisions/ADR-0005-achievements-and-challenges-scope-strategy.md").read_text()
adr5_lower = adr5.lower()
for token in ["deferred scope", "game center", "global leaderboards", "remote challenge", "push notifications"]:
    if token not in adr5_lower:
        print(f"❌ ADR-0005 missing deferred scope token: {token}")
        sys.exit(1)

print("✅ Task-024 achievements verification passed.")
