#!/usr/bin/env python3
"""Verify Task-016b Paywall UI + Locked Feature Flow integration."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Features/Subscription/SubscriptionPaywallView.swift",
    "iOS/Features/Subscription/SubscriberBenefitsListView.swift",
    "iOS/Features/Subscription/RestorePurchaseButton.swift",
    "iOS/Features/Subscription/LockedFeatureOverlayView.swift",
]

REQUIRED_LOCALIZATION_KEYS = [
    "subscription.paywall.nav_title",
    "subscription.paywall.eyebrow",
    "subscription.paywall.title",
    "subscription.paywall.subtitle.general",
    "subscription.paywall.subtitle.locked_feature",
    "subscription.paywall.current_status",
    "subscription.paywall.open_cta",
    "subscription.paywall.cta.debug_unlock",
    "subscription.paywall.cta.deferred",
    "subscription.paywall.cta.already_unlocked",
    "subscription.paywall.state.idle",
    "subscription.paywall.state.processing",
    "subscription.paywall.state.success",
    "subscription.paywall.state.cancelled",
    "subscription.paywall.state.failed",
    "subscription.paywall.debug_controls.title",
    "subscription.paywall.debug_success",
    "subscription.paywall.debug_cancelled",
    "subscription.paywall.debug_failed",
    "subscription.paywall.deferred_notice",
    "subscription.paywall.terms_privacy_placeholder",
    "subscription.restore.cta",
    "subscription.restore.deferred_note",
    "subscription.restore.local_result",
    "subscription.locked_feature.title",
    "subscription.locked_feature.description",
    "subscription.benefit.inline_modes.title",
    "subscription.benefit.inline_modes.description",
    "subscription.benefit.history.title",
    "subscription.benefit.history.description",
    "subscription.benefit.insights.title",
    "subscription.benefit.insights.description",
    "subscription.benefit.share.title",
    "subscription.benefit.share.description",
]


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def extract_keys(path: str) -> set[str]:
    text = read(path)
    return set(re.findall(r'^\s*"([^"]+)"\s*=', text, re.MULTILINE))


def verify_required_files() -> None:
    for relative in REQUIRED_FILES:
        path = ROOT / relative
        if not path.exists():
            fail(f"Missing required Paywall file: {relative}")
        if len(path.read_text(encoding="utf-8").splitlines()) > 500:
            fail(f"Swift file exceeds 500-line hard limit: {relative}")


def verify_project_membership() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for relative in REQUIRED_FILES:
        name = Path(relative).name
        if f"/* {name} */ = {{isa = PBXFileReference" not in project:
            fail(f"Missing PBXFileReference for {name}")
        if f"/* {name} in Sources */ = {{isa = PBXBuildFile" not in project:
            fail(f"Missing PBXBuildFile for {name}")
        if f"/* {name} in Sources */," not in project:
            fail(f"Missing PBXSourcesBuildPhase entry for {name}")
    if "iOS/Features/Subscription" not in project:
        fail("Missing iOS/Features/Subscription group in project.pbxproj")


def verify_localization() -> None:
    en = extract_keys("Shared/Localization/en.lproj/Localizable.strings")
    zh = extract_keys("Shared/Localization/zh-Hant.lproj/Localizable.strings")
    for key in REQUIRED_LOCALIZATION_KEYS:
        if key not in en:
            fail(f"Missing English localization key: {key}")
        if key not in zh:
            fail(f"Missing zh-Hant localization key: {key}")
    if en != zh:
        missing_in_zh = sorted(en - zh)
        missing_in_en = sorted(zh - en)
        fail(f"Localization key parity mismatch. Missing zh={missing_in_zh[:8]}, missing en={missing_in_en[:8]}")


def verify_paywall_boundaries() -> None:
    paywall = read("iOS/Features/Subscription/SubscriptionPaywallView.swift")
    if "import StoreKit" in paywall:
        fail("Task-016b Paywall must not import StoreKit; real purchases are deferred")
    if "setDebugSubscriptionOverride(true)" not in paywall:
        fail("Paywall must grant DEBUG simulated success through subscriptionStatus / FeatureFlagEngine boundary")
    if "SubscriptionPaywallActionState" not in paywall:
        fail("Missing Paywall action state model for success/cancelled/failed simulation")
    for token in ["case success", "case cancelled", "case failed"]:
        if token not in paywall:
            fail(f"Missing Paywall simulation state token: {token}")
    if "PurchaseProductCatalog" in paywall:
        fail("Paywall should not hardcode or read product IDs before StoreKit provider exists")
    if "subscription.price" in paywall or "$2.99" in paywall:
        fail("Paywall must not hardcode price text before StoreKit product metadata exists")


def verify_locked_flow() -> None:
    session_start = read("iOS/Features/SessionRecording/SessionStartView.swift")
    inline_selector = read("iOS/Features/SessionRecording/InlineModeSelectorView.swift")
    hook = read("iOS/Hooks/useSubscriptionStatus.swift")

    for token in ["@State private var paywallFeature", ".sheet(item: $paywallFeature)", "SubscriptionPaywallView(", "LockedFeatureOverlayView(", "showPaywall(for:"]:
        if token not in session_start:
            fail(f"SessionStartView missing locked Paywall routing token: {token}")
    if "onLockedModeTap(feature)" not in inline_selector:
        fail("InlineModeSelectorView must notify locked mode taps through onLockedModeTap(feature)")
    if "productionPurchaseAvailable" not in hook or "requestRestorePurchases" not in hook:
        fail("useSubscriptionStatus should expose Task-016b purchase/restore boundary helpers")


def verify_docs() -> None:
    dev_log = read("docs/history/DEV_LOG.md")
    structure = read("docs/reference/FILE_STRUCTURE.md")
    for token in ["Task-016b Paywall UI + Locked Feature Flow", "DEBUG-only Paywall simulation controls"]:
        if token not in dev_log:
            fail(f"DEV_LOG missing Task-016b token: {token}")
    for token in ["Task-016b Paywall UI + Locked Feature Flow", "iOS/Features/Subscription", "verify_subscription_paywall.py"]:
        if token not in structure:
            fail(f"FILE_STRUCTURE missing Task-016b token: {token}")


def main() -> None:
    verify_required_files()
    verify_project_membership()
    verify_localization()
    verify_paywall_boundaries()
    verify_locked_flow()
    verify_docs()
    print("✅ Task-016b Paywall UI + Locked Feature Flow verification passed.")


if __name__ == "__main__":
    main()
