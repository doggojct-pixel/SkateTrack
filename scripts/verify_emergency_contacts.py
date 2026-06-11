#!/usr/bin/env python3
"""Verify Task-014b Emergency Contacts Settings + SOS contact flow."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_FILES = {
    "Shared/Models/EmergencyContact.swift": [
        "struct EmergencyContact",
        "EmergencyContactRelationship",
        "isUsableForSOS",
        "sanitizedPhoneNumber",
    ],
    "iOS/Core/Safety/EmergencyContactStore.swift": [
        "final class EmergencyContactStore",
        "UserDefaults",
        "@Published private(set) var contacts",
        "func saveContact",
        "func removeContact",
        "func replaceContacts",
    ],
    "iOS/Core/Safety/SOSEventDispatcher.swift": [
        "EmergencyContactStore",
        "contactSetupRequired",
        "emergencyContacts: contacts",
        "makeMessagePreview",
    ],
    "Shared/Models/SOSTriggerEvent.swift": [
        "emergencyContacts: [EmergencyContact]",
        "messagePreview",
        "primaryEmergencyContact",
    ],
    "iOS/Features/FallDetection/EmergencyContactsSettingsView.swift": [
        "EmergencyContactsSettingsView",
        "emergency-contacts-settings-view",
        "emergency-contact-save-button",
        "emergency-contacts-empty-state",
    ],
    "iOS/Features/FallDetection/FallDetectionAlertView.swift": [
        "fall-alert-contact-status-card",
        "fall-alert-manage-contacts-button",
        "safety.contacts.noneConfigured",
        "safety.contacts.ready",
    ],
    "iOS/Features/FallDetection/FallDetectionOverlayPresenter.swift": [
        "SOSTriggerStatusBanner",
        "sos-trigger-status-overlay",
        "sos-status-manage-contacts-button",
    ],
    "iOS/Features/SessionRecording/LiveHUDView.swift": [
        "EmergencyContactStore.shared",
        "EmergencyContactsSettingsView",
        "live-hud-emergency-contacts-button",
    ],
}

REQUIRED_KEYS = [
    "safety.contacts.title",
    "safety.contacts.headline",
    "safety.contacts.description",
    "safety.contacts.namePlaceholder",
    "safety.contacts.phonePlaceholder",
    "safety.contacts.save",
    "safety.contacts.noneConfigured",
    "safety.contacts.ready",
    "safety.contacts.setNow",
    "sos.event.recorded",
    "sos.event.needsContacts",
    "sos.event.primaryContactFormat",
]

LINE_LIMITS = {
    "iOS/Features/SessionRecording/LiveHUDView.swift": 500,
    "iOS/Features/FallDetection/EmergencyContactsSettingsView.swift": 320,
    "iOS/Features/FallDetection/FallDetectionAlertView.swift": 320,
    "iOS/Features/FallDetection/FallDetectionOverlayPresenter.swift": 220,
    "iOS/Core/Safety/EmergencyContactStore.swift": 260,
    "iOS/Core/Safety/SOSEventDispatcher.swift": 350,
}


def fail(message: str) -> None:
    print(f"Emergency contacts check failed: {message}")
    sys.exit(1)


def read(path: str) -> str:
    target = ROOT / path
    if not target.exists():
        fail(f"missing {path}")
    return target.read_text(encoding="utf-8")


def localization_keys(path: str) -> set[str]:
    text = read(path)
    return set(re.findall(r'^"([^"]+)"\s*=', text, flags=re.MULTILINE))


project_text = PROJECT.read_text(encoding="utf-8")

for path, snippets in REQUIRED_FILES.items():
    text = read(path)
    if path.startswith("iOS/Features/") and not text.startswith("// [協作區]"):
        fail(f"{path} must start with collaboration-zone header")
    if path.startswith("iOS/Core/") and not text.startswith("// [自主區]"):
        fail(f"{path} must start with autonomous-zone header")
    if path in LINE_LIMITS and len(text.splitlines()) > LINE_LIMITS[path]:
        fail(f"{path} has {len(text.splitlines())} lines, expected <= {LINE_LIMITS[path]}")
    for snippet in snippets:
        if snippet not in text:
            fail(f"{path} missing snippet: {snippet}")
    name = Path(path).name
    if name.endswith(".swift") and f"{name} in Sources" not in project_text:
        fail(f"{name} missing from Xcode Sources")

localized_en = localization_keys("Shared/Localization/en.lproj/Localizable.strings")
localized_zh = localization_keys("Shared/Localization/zh-Hant.lproj/Localizable.strings")
for key in REQUIRED_KEYS:
    if key not in localized_en:
        fail(f"missing English localization key {key}")
    if key not in localized_zh:
        fail(f"missing Traditional Chinese localization key {key}")

print("Emergency contacts check passed: model, store, settings UI, SOS contact status, localization, and project membership")
