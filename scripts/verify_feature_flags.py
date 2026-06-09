#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
feature_file = ROOT / "Shared" / "Constants" / "FeatureFlags.swift"
engine_file = ROOT / "iOS" / "Core" / "Subscription" / "FeatureFlagEngine.swift"
hook_file = ROOT / "iOS" / "Hooks" / "useSubscriptionStatus.swift"

expected = [
    "unlimitedHistory",
    "advancedCharts",
    "healthReminders",
    "equipmentManager",
    "spotManagement",
    "googleDriveSync",
    "inlineFitnessMode",
    "inlineAggressiveMode",
    "inlineSlalomMode",
    "sessionShareCard",
]

required_files = [feature_file, engine_file, hook_file]
missing_files = [str(path.relative_to(ROOT)) for path in required_files if not path.exists()]
if missing_files:
    print("Missing Task-004 files:")
    for item in missing_files:
        print(f"- {item}")
    sys.exit(1)

feature_text = feature_file.read_text()
missing_features = [name for name in expected if f"case {name}" not in feature_text]
if missing_features:
    print("Missing gated features:")
    for item in missing_features:
        print(f"- {item}")
    sys.exit(1)

for path in required_files:
    first_line = path.read_text().splitlines()[0]
    if "區" not in first_line:
        print(f"Missing zone header on line 1: {path.relative_to(ROOT)}")
        sys.exit(1)

engine_text = engine_file.read_text()
checks = [
    "func hasAccess(to feature: GatedFeature) -> Bool",
    "func hasAccess(to feature: FreeFeature) -> Bool",
    "#if DEBUG",
    "setDebugSubscriptionOverride",
]
for token in checks:
    if token not in engine_text:
        print(f"FeatureFlagEngine.swift missing required token: {token}")
        sys.exit(1)

hook_text = hook_file.read_text()
for token in ["isSubscriber", "func hasAccess(to feature: GatedFeature) -> Bool", "SubscriptionDebugPanel"]:
    if token not in hook_text:
        print(f"useSubscriptionStatus.swift missing required token: {token}")
        sys.exit(1)

for path in required_files:
    line_count = len(path.read_text().splitlines())
    if line_count > 500:
        print(f"File exceeds 500 lines: {path.relative_to(ROOT)} ({line_count})")
        sys.exit(1)

print(f"Feature flag check passed: {len(expected)} gated features")
