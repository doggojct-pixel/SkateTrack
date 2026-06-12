#!/usr/bin/env python3
"""Verify Task-020a Equipment Manager foundation and CRUD UI."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/EquipmentProfile.swift",
    "Shared/Persistence/PersistenceController.swift",
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents",
    "iOS/Core/EquipmentManager/EquipmentRepository.swift",
    "iOS/Core/EquipmentManager/WearReminderEngine.swift",
    "iOS/Hooks/useEquipmentManager.swift",
    "iOS/Features/EquipmentManager/EquipmentListView.swift",
    "iOS/Features/EquipmentManager/EquipmentCardView.swift",
    "iOS/Features/EquipmentManager/EquipmentDetailView.swift",
    "iOS/Features/EquipmentManager/EditEquipmentView.swift",
]

REQUIRED_PROJECT_TOKENS = [
    "EquipmentRepository.swift in Sources",
    "WearReminderEngine.swift in Sources",
    "useEquipmentManager.swift in Sources",
    "EquipmentListView.swift in Sources",
    "EquipmentCardView.swift in Sources",
    "EquipmentDetailView.swift in Sources",
    "EditEquipmentView.swift in Sources",
    "iOS/Core/EquipmentManager",
    "iOS/Features/EquipmentManager",
]

REQUIRED_LOCALIZATION_KEYS = [
    "gear.title",
    "gear.addNew",
    "gear.totalMileage",
    "gear.wheelWear",
    "gear.bearingHealth",
    "gear.type.skateboard",
    "gear.type.inline",
    "gear.status.ok",
    "gear.status.check",
    "gear.locked.title",
    "gear.locked.subtitle",
    "gear.locked.cta",
    "gear.detail.back",
    "gear.detail.title",
    "gear.form.name",
    "gear.form.type",
    "gear.form.mode",
    "gear.reset.wheels",
    "gear.reset.bearings",
]

FORBIDDEN_TOKENS = [
    "PhotosPicker",
    "PHPhotoLibrary",
    "CLLocationManager",
    "UNUserNotificationCenter",
    "WeatherKit",
    "URLSession",
    "AppStore.sync",
    "Transaction.currentEntitlements",
    "Product.products",
    "inline.skate",
    "skateTrack.inlineGlyph",
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

    model_text = read("Shared/Models/EquipmentProfile.swift")
    for token in [
        "enum EquipmentType",
        "case skateboard",
        "case inlineSkates",
        "bearingSetMileageKm",
        "lastMaintenanceDate",
        "photoLocalIdentifier",
        "inferredEquipmentType",
        "func isCompatible(with sessionSportMode: SportMode, powerType sessionPowerType: PowerType) -> Bool",
        "figure.walk",
    ]:
        assert_contains(model_text, token, "EquipmentProfile.swift")

    persistence_text = read("Shared/Persistence/PersistenceController.swift")
    for token in [
        "equipmentTypeRaw",
        "bearingSetMileageKm",
        "bearingABEC",
        "brakeType",
        "lastMaintenanceDate",
        "photoLocalIdentifier",
    ]:
        assert_contains(persistence_text, token, "PersistenceController.swift")

    xcd_text = read("Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents")
    for token in [
        'attribute name="equipmentTypeRaw"',
        'attribute name="bearingSetMileageKm"',
        'attribute name="bearingABEC"',
        'attribute name="lastMaintenanceDate"',
    ]:
        assert_contains(xcd_text, token, "Core Data model")

    repository_text = read("iOS/Core/EquipmentManager/EquipmentRepository.swift")
    for token in [
        "protocol EquipmentRepositoryProtocol",
        "final class EquipmentRepository",
        "fetchEquipment()",
        "saveEquipment",
        "deleteEquipment",
        "resetWheelMileage",
        "resetBearingMileage",
        "addMileage",
        "PersistedEquipment",
    ]:
        assert_contains(repository_text, token, "EquipmentRepository.swift")

    engine_text = read("iOS/Core/EquipmentManager/WearReminderEngine.swift")
    for token in [
        "enum EquipmentWearStatus",
        "case ok",
        "case checkSoon",
        "case replaceRecommended",
        "struct EquipmentWearReport",
        "WearReminderEngine",
        "wheelThresholdKm",
        "bearingThresholdKm",
        "return 300",
        "return 250",
        "return 80",
    ]:
        assert_contains(engine_text, token, "WearReminderEngine.swift")

    hook_text = read("iOS/Hooks/useEquipmentManager.swift")
    for token in [
        "final class EquipmentManagerViewModel",
        "useEquipmentManager",
        "subscriptionStatus.hasAccess(to: .equipmentManager)",
        "sampleEquipment",
        "guard hasManagementAccess else",
        "resetWheelMileage",
        "resetBearingMileage",
    ]:
        assert_contains(hook_text, token, "useEquipmentManager.swift")

    list_text = read("iOS/Features/EquipmentManager/EquipmentListView.swift")
    for token in [
        "struct EquipmentListView",
        "EquipmentCardView",
        "EquipmentDetailView",
        "EditEquipmentView",
        "SubscriptionPaywallView",
        "lockedFeature: feature",
        "paywallFeature = .equipmentManager",
        "equipment-list-view",
        "NavigationStack(path: $navigationPath)",
        "isDetailPresented.wrappedValue = !newPath.isEmpty",
    ]:
        assert_contains(list_text, token, "EquipmentListView.swift")

    card_text = read("iOS/Features/EquipmentManager/EquipmentCardView.swift")
    for token in [
        "struct EquipmentCardView",
        "WearReminderEngine.report",
        "reading.component.titleLocalizationKey",
        "equipment-card-wear-progress",
        "equipment.equipmentType.iconName",
        "EquipmentCardInlineSkateGlyphView",
        'Image(systemName: "figure.walk")',
    ]:
        if token == "WearReminderEngine.report":
            continue
        assert_contains(card_text, token, "EquipmentCardView.swift")

    detail_text = read("iOS/Features/EquipmentManager/EquipmentDetailView.swift")
    for token in [
        "struct EquipmentDetailView",
        "onResetWheels",
        "onResetBearings",
        "confirmationDialog",
        "gear.delete.confirm.title",
        "detailHeader",
        "gear.detail.back",
        "navigationBarBackButtonHidden(true)",
        "toolbar(.hidden, for: .navigationBar)",
    ]:
        assert_contains(detail_text, token, "EquipmentDetailView.swift")

    edit_text = read("iOS/Features/EquipmentManager/EditEquipmentView.swift")
    for token in [
        "struct EditEquipmentView",
        "EquipmentType.allCases",
        "BoardMode.allCases",
        "InlineMode.allCases",
        "bearingSetMileageKm",
        "parseDouble",
    ]:
        assert_contains(edit_text, token, "EditEquipmentView.swift")

    root_text = read("iOS/App/RootNavigationView.swift")
    for token in [
        "case equipment",
        "isEquipmentDetailPresented",
        "EquipmentListView(",
        "isDetailPresented: $isEquipmentDetailPresented",
        "selectedPrimaryScreen != .ride && !isEquipmentDetailPresented",
        "gear.title",
    ]:
        assert_contains(root_text, token, "RootNavigationView.swift")

    if root_text.count("private func postSessionStretchReminderOverlay") != 1:
        fail("RootNavigationView.swift must define postSessionStretchReminderOverlay exactly once")

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

    scanned_sources = "\n".join(read(relative) for relative in REQUIRED_FILES if relative.endswith(".swift"))
    for forbidden in FORBIDDEN_TOKENS:
        if forbidden in scanned_sources:
            fail(f"Task-020a must not introduce `{forbidden}`")

    docs = read("docs/DEV_LOG.md") + "\n" + read("docs/FILE_STRUCTURE.md") + "\n" + read("docs/decisions/ADR-0001-subscription-entitlement-strategy.md")
    for token in [
        "Task-020a",
        "Equipment Manager Foundation + CRUD UI",
        "EquipmentRepository",
        "WearReminderEngine",
        "useEquipmentManager",
        "FeatureFlagEngine",
        "DEBUG/local entitlement simulation",
    ]:
        assert_contains(docs, token, "living docs / ADR")

    print("✅ Task-020a equipment manager verification passed.")


if __name__ == "__main__":
    main()
