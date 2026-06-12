#!/usr/bin/env python3
"""Verify Task-020b session equipment selection and automatic mileage tracking."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "iOS/Core/EquipmentManager/EquipmentMileageTracker.swift",
    "iOS/Core/EquipmentManager/EquipmentRepository.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift",
    "iOS/Core/SessionRecording/SessionRecordingCoordinator+CompletionEffects.swift",
    "iOS/Hooks/useSessionRecording.swift",
    "iOS/Features/SessionRecording/SessionStartView.swift",
    "iOS/Features/EquipmentManager/SessionEquipmentPickerView.swift",
]

REQUIRED_PROJECT_TOKENS = [
    "EquipmentMileageTracker.swift in Sources",
    "SessionEquipmentPickerView.swift in Sources",
]

REQUIRED_LOCALIZATION_KEYS = [
    "gear.session.title",
    "gear.session.subtitle",
    "gear.session.optional",
    "gear.session.none",
    "gear.session.empty.title",
    "gear.session.locked.subtitle",
    "gear.session.locked.cta",
    "gear.error.mileageTrackingFailed",
]

FORBIDDEN_TOKENS = [
    "PhotosPicker",
    "PHPhotoLibrary",
    "UNUserNotificationCenter",
    "WeatherKit",
    "AppStore.sync",
    "Transaction.currentEntitlements",
    "Product.products",
    "inline.skate",
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

tracker_text = read("iOS/Core/EquipmentManager/EquipmentMileageTracker.swift")
for token in [
    "protocol EquipmentMileageTracking",
    "actor EquipmentMileageTracker",
    "applyMileageIfNeeded(to session: SessionData)",
    "session.equipmentID",
    "session.summaryMetrics?.distanceKilometers",
    "appliedSessionIDs",
    "skippedAlreadyApplied",
    "repository.addMileage",
]:
    assert_contains(tracker_text, token, "EquipmentMileageTracker.swift")

model_text = read("Shared/Models/EquipmentProfile.swift")
for token in [
    "func isCompatible(with sessionSportMode: SportMode, powerType sessionPowerType: PowerType) -> Bool",
    "equipmentMode == sessionMode && powerType == sessionPowerType",
    "equipmentMode == sessionMode && powerType == .humanPowered && sessionPowerType == .humanPowered",
]:
    assert_contains(model_text, token, "EquipmentProfile.swift")

repository_text = read("iOS/Core/EquipmentManager/EquipmentRepository.swift")
for token in [
    "func addMileage(id: UUID, distanceKilometers: Double) async throws -> EquipmentProfile?",
    "totalDistanceKm",
    "wheelSetMileageKm",
    "bearingSetMileageKm",
]:
    assert_contains(repository_text, token, "EquipmentRepository.swift")

coordinator_text = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
completion_effects_text = read("iOS/Core/SessionRecording/SessionRecordingCoordinator+CompletionEffects.swift")
for token in [
    "let equipmentMileageTracker: EquipmentMileageTracking",
    "equipmentMileageTracker: EquipmentMileageTracking = EquipmentMileageTracker.shared",
    "private var selectedEquipmentID: UUID?",
    "equipmentID: UUID? = nil",
    "equipmentSnapshot: EquipmentSessionSnapshot? = nil",
    "selectedEquipmentID = equipmentID",
    "selectedEquipmentSnapshot = equipmentSnapshot",
    "equipmentID: selectedEquipmentID",
    "equipmentSnapshot: selectedEquipmentSnapshot",
    "sessionRepository.saveCompletedSession(sessionData)",
    "await applyEquipmentMileageIfNeeded(for: savedSession)",
    "func applyEquipmentMileageIfNeeded(for session: SessionData) async",
]:
    assert_contains(coordinator_text + "\n" + completion_effects_text, token, "SessionRecordingCoordinator completion path")

save_index = coordinator_text.find("sessionRepository.saveCompletedSession(sessionData)")
apply_index = coordinator_text.find("await applyEquipmentMileageIfNeeded(for: savedSession)")
if save_index == -1 or apply_index == -1 or apply_index < save_index:
    fail("Equipment mileage must be applied only after saveCompletedSession succeeds")

discard_body = coordinator_text[coordinator_text.find("func discardCurrentSession"):coordinator_text.find("private func bindLiveSampleStream")]
if "applyEquipmentMileageIfNeeded" in discard_body:
    fail("discardCurrentSession must not apply equipment mileage")

hook_text = read("iOS/Hooks/useSessionRecording.swift")
for token in [
    "var selectedEquipmentID: UUID?",
    "let startSession: (SportMode, PowerType, UUID?, EquipmentSessionSnapshot?, UUID?, SpotSessionSnapshot?) async -> Void",
    "equipmentID: UUID?",
    "equipmentSnapshot: EquipmentSessionSnapshot?",
    "try await coordinator.startSession(",
]:
    assert_contains(hook_text, token, "useSessionRecording.swift")

start_text = read("iOS/Features/SessionRecording/SessionStartView.swift")
for token in [
    "@State private var selectedEquipmentID: UUID?",
    "@StateObject private var equipmentManager: EquipmentManagerViewModel",
    "SessionEquipmentPickerView(",
    "equipment: equipmentManager.equipment",
    "selectedPowerType: selectedPowerType",
    "hasAccess: equipmentManager.hasManagementAccess",
    "selectedEquipmentID: $selectedEquipmentID",
    "selectedEquipmentForSession",
    "clearIncompatibleSelectedEquipment",
    ".onChange(of: selectedPowerType)",
    "showPaywall(for: .equipmentManager)",
]:
    assert_contains(start_text, token, "SessionStartView.swift")

picker_text = read("iOS/Features/EquipmentManager/SessionEquipmentPickerView.swift")
for token in [
    "struct SessionEquipmentPickerView",
    "selectedPowerType: PowerType",
    "compatibleEquipment",
    "equipment.isCompatible(with: selectedSportMode, powerType: selectedPowerType)",
    "subtitle(for: gear)",
    "gear.session.locked.cta",
    "gear.session.none",
    "session-equipment-picker",
    "ScrollView(.horizontal",
]:
    assert_contains(picker_text, token, "SessionEquipmentPickerView.swift")

project_text = read("SkateTrack.xcodeproj/project.pbxproj")
for token in REQUIRED_PROJECT_TOKENS:
    assert_contains(project_text, token, "project.pbxproj")

for key in REQUIRED_LOCALIZATION_KEYS:
    for language in ("en", "zh-Hant"):
        keys = extract_keys(f"Shared/Localization/{language}.lproj/Localizable.strings")
        if key not in keys:
            fail(f"Missing localization key {key} in {language}")

scanned_sources = "\n".join(read(relative) for relative in REQUIRED_FILES)
for forbidden in FORBIDDEN_TOKENS:
    if forbidden in scanned_sources:
        fail(f"Task-020b must not introduce `{forbidden}`")

docs = read("docs/DEV_LOG.md") + "\n" + read("docs/FILE_STRUCTURE.md") + "\n" + read("docs/decisions/ADR-0001-subscription-entitlement-strategy.md")
for token in [
    "Task-020b",
    "Session Equipment Selection + Auto Mileage Tracking",
    "EquipmentMileageTracker",
    "SessionEquipmentPickerView",
    "mode / power compatibility",
    "saveCompletedSession",
    "DEBUG/local entitlement simulation",
]:
    assert_contains(docs, token, "living docs / ADR")

print("✅ Task-020b equipment mileage tracking verification passed.")
