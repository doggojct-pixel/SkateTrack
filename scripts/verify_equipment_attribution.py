#!/usr/bin/env python3
"""Verify Task-020c equipment attribution snapshots in History and Summary."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/EquipmentSessionSnapshot.swift",
    "Shared/Models/SessionData.swift",
    "Shared/Persistence/PersistenceController.swift",
    "Shared/Persistence/SessionEntityMapper.swift",
    "Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Hooks/useSessionRecording.swift",
    "iOS/Features/SessionRecording/SessionStartView.swift",
    "iOS/Features/SessionHistory/SessionHistoryCardView.swift",
    "iOS/Features/SessionSummary/SessionSummaryView.swift",
    "iOS/Features/SessionSummary/SessionEquipmentAttributionView.swift",
]

PROJECT_TOKENS = [
    "EquipmentSessionSnapshot.swift in Sources",
    "SessionEquipmentAttributionView.swift in Sources",
]

LOCALIZATION_KEYS = [
    "gear.snapshot.untitled",
    "history.gear.lineFormat",
    "history.gear.unsynced",
    "summary.gear.title",
    "summary.gear.detailFormat",
    "summary.gear.archived.badge",
    "summary.gear.unsynced.title",
    "summary.gear.unsynced.subtitle",
    "summary.gear.unsynced.badge",
]

FORBIDDEN_TOKENS = [
    "PhotosPicker",
    "PHPhotoLibrary",
    "AppStore.sync",
    "Transaction.currentEntitlements",
    "Product.products",
    "UNUserNotificationCenter",
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
    return set(re.findall(r'^"([^"]+)"\s*=', read(path), flags=re.MULTILINE))


for relative in REQUIRED_FILES:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    line_count = len(path.read_text(encoding="utf-8").splitlines())
    if line_count > 500:
        fail(f"{relative} exceeds 500-line limit: {line_count}")

snapshot_text = read("Shared/Models/EquipmentSessionSnapshot.swift")
for token in [
    "struct EquipmentSessionSnapshot",
    "let equipmentID: UUID",
    "let name: String",
    "let equipmentType: EquipmentType",
    "let sportMode: SportMode",
    "let powerType: PowerType",
    "init(equipment: EquipmentProfile",
    "displayName",
]:
    assert_contains(snapshot_text, token, "EquipmentSessionSnapshot.swift")

session_data_text = read("Shared/Models/SessionData.swift")
for token in [
    "let equipmentSnapshot: EquipmentSessionSnapshot?",
    "equipmentSnapshot: EquipmentSessionSnapshot? = nil",
    "case equipmentSnapshot",
    "decodeIfPresent(EquipmentSessionSnapshot.self, forKey: .equipmentSnapshot)",
]:
    assert_contains(session_data_text, token, "SessionData.swift")

persistence_text = read("Shared/Persistence/PersistenceController.swift")
model_text = read("Shared/Persistence/SkateTrackDataModel.xcdatamodeld/SkateTrackDataModel.xcdatamodel/contents")
mapper_text = read("Shared/Persistence/SessionEntityMapper.swift")
for token in ["equipmentSnapshotData", "binaryAttribute(\"equipmentSnapshotData\", optional: true)"]:
    assert_contains(persistence_text, token, "PersistenceController.swift")
assert_contains(model_text, "equipmentSnapshotData", "xcdatamodel contents")
for token in [
    "session.equipmentSnapshot.map",
    "equipmentSnapshotData",
    "decode(EquipmentSessionSnapshot.self",
    "equipmentSnapshot:",
]:
    assert_contains(mapper_text, token, "SessionEntityMapper.swift")

coordinator_text = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
for token in [
    "private var selectedEquipmentSnapshot: EquipmentSessionSnapshot?",
    "equipmentSnapshot: EquipmentSessionSnapshot? = nil",
    "selectedEquipmentSnapshot = equipmentSnapshot",
    "equipmentSnapshot: selectedEquipmentSnapshot",
    "selectedEquipmentSnapshot = nil",
]:
    assert_contains(coordinator_text, token, "SessionRecordingCoordinator.swift")

hook_text = read("iOS/Hooks/useSessionRecording.swift")
for token in [
    "let startSession: (SportMode, PowerType, UUID?, EquipmentSessionSnapshot?, UUID?, SpotSessionSnapshot?) async -> Void",
    "equipmentSnapshot: EquipmentSessionSnapshot?",
    "equipmentSnapshot: equipmentSnapshot",
]:
    assert_contains(hook_text, token, "useSessionRecording.swift")

start_text = read("iOS/Features/SessionRecording/SessionStartView.swift")
for token in [
    "selectedEquipmentForSession",
    "EquipmentSessionSnapshot(equipment:",
    "equipment?.id",
    "equipment.map",
]:
    assert_contains(start_text, token, "SessionStartView.swift")

history_text = read("iOS/Features/SessionHistory/SessionHistoryCardView.swift")
for token in [
    "history-card-equipment-snapshot",
    "session.equipmentSnapshot",
    "history.gear.lineFormat",
    "history.gear.unsynced",
]:
    assert_contains(history_text, token, "SessionHistoryCardView.swift")

summary_text = read("iOS/Features/SessionSummary/SessionSummaryView.swift")
summary_card_text = read("iOS/Features/SessionSummary/SessionEquipmentAttributionView.swift")
for token in [
    "SessionEquipmentAttributionView(session: content.session)",
    "shouldShowEquipmentAttribution",
]:
    assert_contains(summary_text, token, "SessionSummaryView.swift")
for token in [
    "struct SessionEquipmentAttributionView",
    "summary.gear.title",
    "summary.gear.detailFormat",
    "summary.gear.archived.badge",
    "summary.gear.unsynced.title",
    "session-equipment-attribution",
]:
    assert_contains(summary_card_text, token, "SessionEquipmentAttributionView.swift")

project_text = read("SkateTrack.xcodeproj/project.pbxproj")
for token in PROJECT_TOKENS:
    assert_contains(project_text, token, "project.pbxproj")

for key in LOCALIZATION_KEYS:
    for language in ("en", "zh-Hant"):
        keys = extract_keys(f"Shared/Localization/{language}.lproj/Localizable.strings")
        if key not in keys:
            fail(f"Missing localization key {key} in {language}")

combined = "\n".join(read(relative) for relative in REQUIRED_FILES)
for token in FORBIDDEN_TOKENS:
    if token in combined:
        fail(f"Task-020c must not introduce `{token}`")

docs = read("docs/DEV_LOG.md") + "\n" + read("docs/FILE_STRUCTURE.md") + "\n" + read("docs/decisions/ADR-0001-subscription-entitlement-strategy.md")
for token in [
    "Task-020c",
    "Equipment Attribution",
    "EquipmentSessionSnapshot",
    "SessionEquipmentAttributionView",
    "equipmentSnapshotData",
    "archived equipment snapshot",
]:
    assert_contains(docs, token, "living docs / ADR")

print("✅ Task-020c equipment attribution verification passed.")
