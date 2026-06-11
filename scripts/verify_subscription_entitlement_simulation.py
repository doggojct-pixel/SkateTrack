#!/usr/bin/env python3
"""Verify Task-016a subscription entitlement simulation architecture."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/Subscription/SubscriptionEntitlementState.swift",
    "iOS/Core/Subscription/SubscriptionEntitlementProvider.swift",
    "iOS/Core/Subscription/LocalSubscriptionEntitlementProvider.swift",
    "iOS/Core/Subscription/DebugSubscriptionEntitlementProvider.swift",
    "iOS/Core/Subscription/SubscriptionEntitlementStore.swift",
    "iOS/Core/Subscription/PurchaseProductCatalog.swift",
    "iOS/Core/Subscription/FeatureFlagEngine.swift",
    "iOS/Hooks/useSubscriptionStatus.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "docs/decisions/ADR-0001-subscription-entitlement-strategy.md",
    "docs/DEV_LOG.md",
    "docs/FILE_STRUCTURE.md",
]

PROJECT_FILE = ROOT / "SkateTrack.xcodeproj" / "project.pbxproj"

REQUIRED_LOCALIZATION_KEYS = [
    "subscription.entitlement.status.unknown",
    "subscription.entitlement.status.free",
    "subscription.entitlement.status.subscriber",
    "subscription.entitlement.status.failed",
    "subscription.entitlement.status.not_configured",
    "subscription.entitlement.status.local_simulation_free",
    "subscription.entitlement.status.app_store_deferred",
    "subscription.entitlement.status.debug_override_inactive",
    "subscription.entitlement.status.debug_subscriber",
    "subscription.entitlement.status.debug_free",
    "subscription.entitlement.source.not_configured",
    "subscription.entitlement.source.local_simulation",
    "subscription.entitlement.source.debug_override",
    "subscription.entitlement.source.app_store_deferred",
    "debug.subscription.clear_override",
]

SOURCE_TOKENS = {
    "iOS/Core/Subscription/SubscriptionEntitlementProvider.swift": [
        "protocol SubscriptionEntitlementProviding",
        "func currentEntitlement() async -> SubscriptionEntitlementSnapshot",
    ],
    "iOS/Core/Subscription/SubscriptionEntitlementState.swift": [
        "enum SubscriptionEntitlementState",
        "enum SubscriptionEntitlementSource",
        "struct SubscriptionEntitlementSnapshot",
        "case localSimulation",
        "case debugOverride",
        "case appStoreDeferred",
    ],
    "iOS/Core/Subscription/LocalSubscriptionEntitlementProvider.swift": [
        "final class LocalSubscriptionEntitlementProvider",
        ".localFreeSimulation",
    ],
    "iOS/Core/Subscription/DebugSubscriptionEntitlementProvider.swift": [
        "#if DEBUG",
        "final class DebugSubscriptionEntitlementProvider",
        "#endif",
    ],
    "iOS/Core/Subscription/SubscriptionEntitlementStore.swift": [
        "final class SubscriptionEntitlementStore",
        "@Published private(set) var snapshot",
        "func refresh() async",
        "func apply(_ nextSnapshot",
    ],
    "iOS/Core/Subscription/PurchaseProductCatalog.swift": [
        "enum PurchaseProductCatalog",
        "com.skatetrack.subscription.monthly",
        "com.skatetrack.subscription.yearly",
    ],
    "iOS/Core/Subscription/FeatureFlagEngine.swift": [
        "SubscriptionEntitlementStore",
        "effectiveEntitlementSnapshot",
        "entitlementSourceDescriptionKey",
        "setDebugSubscriptionOverride",
        "clearDebugSubscriptionOverride",
    ],
    "iOS/Hooks/useSubscriptionStatus.swift": [
        "entitlementState",
        "entitlementSourceDescriptionKey",
        "entitlementStatusMessageKey",
        "debugSubscriptionOverrideActive",
    ],
}


def fail(message: str) -> int:
    print(message)
    return 1


def parse_keys(path: Path) -> set[str]:
    pattern = re.compile(r'^\s*"(?P<key>[^"]+)"\s*=')
    keys: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if match:
            keys.add(match.group("key"))
    return keys


def main() -> int:
    missing = [item for item in REQUIRED_FILES if not (ROOT / item).exists()]
    if missing:
        return fail("Missing Task-016a files:\n" + "\n".join(f"- {item}" for item in missing))

    for item in REQUIRED_FILES:
        if item.endswith((".swift", ".md")):
            text = (ROOT / item).read_text(encoding="utf-8")
            if item.endswith(".swift"):
                first_line = text.splitlines()[0]
                if "區" not in first_line:
                    return fail(f"Missing zone header on line 1: {item}")
                line_count = len(text.splitlines())
                if line_count > 500:
                    return fail(f"File exceeds 500-line limit: {item} ({line_count})")

    for item, tokens in SOURCE_TOKENS.items():
        text = (ROOT / item).read_text(encoding="utf-8")
        for token in tokens:
            if token not in text:
                return fail(f"{item} missing required token: {token}")

    project_text = PROJECT_FILE.read_text(encoding="utf-8")
    for item in REQUIRED_FILES:
        if item.startswith("iOS/Core/Subscription/") and item.endswith(".swift"):
            name = Path(item).name
            if name not in project_text:
                return fail(f"Xcode project missing source membership for {name}")
            file_reference_pattern = re.compile(
                rf"/\* {re.escape(name)} \*/ = \{{isa = PBXFileReference;[^}}]+path = {re.escape(name)};"
            )
            build_file_pattern = re.compile(
                rf"/\* {re.escape(name)} in Sources \*/ = \{{isa = PBXBuildFile;[^}}]+fileRef = [A-F0-9]+ /\* {re.escape(name)} \*/;"
            )
            source_phase_pattern = re.compile(rf"/\* {re.escape(name)} in Sources \*/,")
            if not file_reference_pattern.search(project_text):
                return fail(f"Xcode project missing PBXFileReference for {name}")
            if not build_file_pattern.search(project_text):
                return fail(f"Xcode project missing PBXBuildFile for {name}")
            if not source_phase_pattern.search(project_text):
                return fail(f"Xcode project missing PBXSourcesBuildPhase entry for {name}")

    defined_ids = set(re.findall(r"^\s*([A-Z0-9]{24}) /\* .*? \*/ = \{\s*\n\s*isa =", project_text, re.MULTILINE))
    defined_ids.update(re.findall(r"^\s*([A-Z0-9]{24}) /\* .*? \*/ = \{isa =", project_text, re.MULTILINE))
    referenced_file_ids = set(re.findall(r"fileRef = ([A-Z0-9]{24}) /\*", project_text))
    dangling_refs = sorted(referenced_file_ids - defined_ids)
    if dangling_refs:
        return fail("Xcode project contains PBXBuildFile entries with dangling fileRef IDs:\n" + "\n".join(f"- {item}" for item in dangling_refs))

    engine_text = (ROOT / "iOS/Core/Subscription/FeatureFlagEngine.swift").read_text(encoding="utf-8")
    forbidden_engine_tokens = [
        "entitlementState = .free",
        "return true\n    }\n\n    func hasAccess(to feature: GatedFeature)",
    ]
    for token in forbidden_engine_tokens:
        if token in engine_text:
            return fail(f"FeatureFlagEngine appears to contain stub entitlement logic: {token}")

    debug_provider_text = (ROOT / "iOS/Core/Subscription/DebugSubscriptionEntitlementProvider.swift").read_text(
        encoding="utf-8"
    )
    if not debug_provider_text.strip().endswith("#endif"):
        return fail("DebugSubscriptionEntitlementProvider.swift must end with #endif")

    for lang in ["en", "zh-Hant"]:
        keys = parse_keys(ROOT / "Shared" / "Localization" / f"{lang}.lproj" / "Localizable.strings")
        missing_keys = [key for key in REQUIRED_LOCALIZATION_KEYS if key not in keys]
        if missing_keys:
            return fail(
                f"Missing Task-016a localization keys for {lang}:\n"
                + "\n".join(f"- {key}" for key in missing_keys)
            )

    adr_text = (ROOT / "docs/decisions/ADR-0001-subscription-entitlement-strategy.md").read_text(encoding="utf-8")
    for token in [
        "Apple Developer Program",
        "SubscriptionEntitlementProviding",
        "FeatureFlagEngine",
        "AppStoreSubscriptionProvider",
        "No real App Store purchase flow",
    ]:
        if token not in adr_text:
            return fail(f"ADR-0001 missing decision token: {token}")

    file_structure_text = (ROOT / "docs/FILE_STRUCTURE.md").read_text(encoding="utf-8")
    for token in [
        "Task-016a Subscription Entitlement Simulation Architecture",
        "Real StoreKit monetization is deferred",
        "ADR-0001-subscription-entitlement-strategy.md",
    ]:
        if token not in file_structure_text:
            return fail(f"FILE_STRUCTURE.md missing Task-016a token: {token}")

    dev_log_text = (ROOT / "docs/DEV_LOG.md").read_text(encoding="utf-8")
    if "Task-016a Subscription Entitlement Simulation Architecture" not in dev_log_text:
        return fail("DEV_LOG.md missing Task-016a entry")

    print("Task-016a subscription entitlement simulation check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
