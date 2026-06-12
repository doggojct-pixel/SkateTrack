#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

required_files = [
    "Shared/Models/Achievement.swift",
    "Shared/Models/WeeklyChallenge.swift",
    "iOS/Core/Achievements/AchievementCatalog.swift",
    "iOS/Core/Achievements/AchievementEngine.swift",
    "iOS/Core/Achievements/AchievementUnlockStore.swift",
    "iOS/Core/Achievements/WeeklyChallengeEngine.swift",
    "iOS/Hooks/useAchievements.swift",
    "iOS/Features/Achievements/AchievementListView.swift",
    "iOS/Features/Achievements/AchievementCardView.swift",
    "iOS/Features/Achievements/AchievementProgressRingView.swift",
    "iOS/Features/Achievements/WeeklyChallengeCardView.swift",
]

for relative in required_files:
    path = ROOT / relative
    if not path.exists():
        print(f"❌ Missing Task-024a file: {relative}")
        sys.exit(1)
    first_line = path.read_text().splitlines()[0]
    if "區" not in first_line:
        print(f"❌ Missing zone header: {relative}")
        sys.exit(1)
    line_count = len(path.read_text().splitlines())
    if line_count > 500:
        print(f"❌ File exceeds 500 lines: {relative} ({line_count})")
        sys.exit(1)

shared_text = (ROOT / "Shared/Models/Achievement.swift").read_text()
for token in ["AchievementDefinition", "AchievementProgress", "AchievementUnlockRecord", "Codable", "Sendable"]:
    if token not in shared_text:
        print(f"❌ Achievement.swift missing token: {token}")
        sys.exit(1)

weekly_text = (ROOT / "Shared/Models/WeeklyChallenge.swift").read_text()
for token in ["WeeklyChallengeDefinition", "WeeklyChallengeProgress", "WeeklyChallengeKind", "Codable", "Sendable"]:
    if token not in weekly_text:
        print(f"❌ WeeklyChallenge.swift missing token: {token}")
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
    "hasAccess(to: .advancedChallenges)",
]:
    if token not in hook_text:
        print(f"❌ useAchievements.swift missing token: {token}")
        sys.exit(1)

for relative in [
    "iOS/Core/Achievements/AchievementCatalog.swift",
    "iOS/Core/Achievements/AchievementEngine.swift",
    "iOS/Core/Achievements/AchievementUnlockStore.swift",
    "iOS/Core/Achievements/WeeklyChallengeEngine.swift",
]:
    text = (ROOT / relative).read_text()
    if "import SwiftUI" in text or "import UIKit" in text:
        print(f"❌ Core achievement file must not import UI frameworks: {relative}")
        sys.exit(1)

root_text = (ROOT / "iOS/App/RootNavigationView.swift").read_text()
for token in ["case achievements", "AchievementListView(subscriptionStatus:", "achievements.title"]:
    if token not in root_text:
        print(f"❌ RootNavigationView.swift missing token: {token}")
        sys.exit(1)

ui_text = (ROOT / "iOS/Features/Achievements/AchievementListView.swift").read_text()
for forbidden in ["SessionRepository", "EquipmentRepository", "SpotRepository", "CoreData"]:
    if forbidden in ui_text:
        print(f"❌ AchievementListView should not directly access repositories/CoreData: {forbidden}")
        sys.exit(1)
for token in ["SubscriptionPaywallView", ".advancedChallenges", "WeeklyChallengeCardView", "AchievementCardView"]:
    if token not in ui_text:
        print(f"❌ AchievementListView.swift missing token: {token}")
        sys.exit(1)

project_text = (ROOT / "SkateTrack.xcodeproj/project.pbxproj").read_text()
for relative in required_files:
    filename = Path(relative).name
    if filename not in project_text:
        print(f"❌ project.pbxproj missing source membership for: {filename}")
        sys.exit(1)

for lang in ["en.lproj", "zh-Hant.lproj"]:
    loc_text = (ROOT / "Shared/Localization" / lang / "Localizable.strings").read_text()
    for key in [
        "achievements.title",
        "achievements.firstRide.title",
        "challenges.weekly.title",
        "feature.advanced_challenges",
    ]:
        if f'"{key}"' not in loc_text:
            print(f"❌ {lang}/Localizable.strings missing key: {key}")
            sys.exit(1)

for doc in ["docs/DEV_LOG.md", "docs/FILE_STRUCTURE.md", "docs/decisions/ADR-0001-subscription-entitlement-strategy.md"]:
    text = (ROOT / doc).read_text()
    if "Task-024a" not in text:
        print(f"❌ {doc} missing Task-024a documentation")
        sys.exit(1)

print("✅ Task-024a achievements verification passed.")
