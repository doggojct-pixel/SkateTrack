#!/usr/bin/env python3
"""Verify Task-014a Fall Alert Overlay + SOS Event Skeleton."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "SkateTrack.xcodeproj/project.pbxproj"

REQUIRED_FILES = [
    "Shared/Models/SOSTriggerEvent.swift",
    "Shared/Models/EmergencyContact.swift",
    "iOS/Core/Safety/SOSEventDispatcher.swift",
    "iOS/Core/Safety/EmergencyContactStore.swift",
    "iOS/Core/Safety/SessionRecordingCoordinator+FallSafety.swift",
    "iOS/Hooks/useFallDetection.swift",
    "iOS/Features/FallDetection/FallDetectionAlertView.swift",
    "iOS/Features/FallDetection/FallDetectionOverlayPresenter.swift",
    "iOS/Features/FallDetection/EmergencyContactsSettingsView.swift",
    "iOS/Features/SessionRecording/LiveSpeedTraceView.swift",
    "iOS/Features/SessionRecording/LiveHUDView.swift",
]

REQUIRED_KEYS = [
    "fall.alert.title",
    "fall.alert.message",
    "fall.alert.countdown",
    "fall.alert.impact",
    "fall.alert.locationSaved",
    "fall.alert.locationUnavailable",
    "fall.alert.imOkay",
    "fall.alert.sosNow",
    "sos.message.template",
    "safety.contacts.title",
    "safety.contacts.noneConfigured",
    "safety.contacts.setNow",
    "sos.event.needsContacts",
    "sos.event.recorded",
]

REQUIRED_SNIPPETS = {
    "Shared/Models/SOSTriggerEvent.swift": [
        "enum SOSTriggerSource",
        "case manualHUD",
        "case fallImmediate",
        "case fallCountdownExpired",
        "struct SOSTriggerEvent",
        "relatedFallEvent: FallEvent?",
        "emergencyContacts: [EmergencyContact]",
        "contactSetupRequired",
        "messagePreview",
    ],
    "Shared/Models/EmergencyContact.swift": [
        "struct EmergencyContact",
        "EmergencyContactRelationship",
        "isUsableForSOS",
        "sanitizedPhoneNumber",
    ],
    "iOS/Core/Safety/SOSEventDispatcher.swift": [
        "final class SOSEventDispatcher",
        "eventPublisher",
        "func dispatch(",
        "EmergencyContactStore",
        "contactSetupRequired",
        "makeMessagePreview",
    ],
    "iOS/Core/Safety/EmergencyContactStore.swift": [
        "final class EmergencyContactStore",
        "@Published private(set) var contacts",
        "func saveContact",
        "func removeContact",
        "UserDefaults",
    ],
    "iOS/Core/Safety/SessionRecordingCoordinator+FallSafety.swift": [
        "fallCountdownPublisher",
        "sosTriggerEventPublisher",
        "func cancelActiveFallAlert()",
        "func sendImmediateSOSForActiveFall()",
        "func triggerManualSOS()",
        "func simulateFallAlertForDebug()",
        "scheduleDebugFallCountdown",
    ],
    "iOS/Hooks/useFallDetection.swift": [
        "final class FallDetectionViewModel",
        "FallDetectionAlertState",
        "FallDetectionActions",
        "simulateFallAlert",
        "simulateFallAlertForDebug",
        "func useFallDetection(",
    ],
    "iOS/Features/FallDetection/FallDetectionAlertView.swift": [
        "FallDetectionAlertView",
        "fall.alert.title",
        "fall.alert.imOkay",
        "fall.alert.sosNow",
        "fall-alert-countdown",
        "fall-alert-impact-badge",
        "fall-alert-contact-status-card",
        "fall-alert-manage-contacts-button",
    ],
    "iOS/Features/FallDetection/FallDetectionOverlayPresenter.swift": [
        "FallDetectionOverlayPresenter",
        "FallDetectionAlertView",
        "fall-detection-overlay",
        "SOSTriggerStatusBanner",
        "sos-trigger-status-overlay",
    ],
    "iOS/Features/FallDetection/EmergencyContactsSettingsView.swift": [
        "EmergencyContactsSettingsView",
        "EmergencyContactStore",
        "emergency-contacts-settings-view",
        "emergency-contact-save-button",
    ],
    "iOS/Features/SessionRecording/LiveHUDView.swift": [
        "@StateObject private var fallDetection",
        "FallDetectionOverlayPresenter",
        "fallDetection.actions.triggerManualSOS",
        "debug-simulate-fall-button",
        "live-hud-emergency-contacts-button",
        "EmergencyContactsSettingsView",
        "#if DEBUG",
        "LiveSpeedTraceView",
    ],
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": [
        "countdownPublisher",
        "sosTriggerPublisher",
        "fallCountdownSubject",
        "sosTriggerEventSubject",
        "fallCountdownExpired",
    ],
}

LINE_LIMITS = {
    "iOS/Features/SessionRecording/LiveHUDView.swift": 500,
    "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift": 450,
    "iOS/Hooks/useFallDetection.swift": 320,
    "iOS/Core/Safety/SOSEventDispatcher.swift": 350,
    "iOS/Core/Safety/EmergencyContactStore.swift": 260,
    "iOS/Features/FallDetection/FallDetectionAlertView.swift": 320,
    "iOS/Features/FallDetection/FallDetectionOverlayPresenter.swift": 220,
    "iOS/Features/FallDetection/EmergencyContactsSettingsView.swift": 320,
}

FORBIDDEN_UI_IMPORTS = {
    "iOS/Core/Safety/SOSEventDispatcher.swift": ["import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"],
    "iOS/Core/Safety/EmergencyContactStore.swift": ["import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"],
    "iOS/Core/Safety/SessionRecordingCoordinator+FallSafety.swift": ["import SwiftUI", "import UIKit", "import AppKit", "import WatchKit"],
}


def fail(message: str) -> None:
    print(f"Fall alert UI check failed: {message}")
    sys.exit(1)


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.exists():
        fail(f"missing {path}")
    return file_path.read_text(encoding="utf-8")


def localization_keys(path: str) -> set[str]:
    return set(re.findall(r'^"([^"]+)"\s*=', read(path), flags=re.MULTILINE))


project_text = PROJECT.read_text(encoding="utf-8")

for path in REQUIRED_FILES:
    text = read(path)
    if path.startswith("iOS/Features/") and not text.startswith("// [協作區]"):
        fail(f"{path} must start with collaboration-zone header")
    if path.startswith("iOS/Core/") and not text.startswith("// [自主區]"):
        fail(f"{path} must start with autonomous-zone header")
    if path in LINE_LIMITS and len(text.splitlines()) > LINE_LIMITS[path]:
        fail(f"{path} has {len(text.splitlines())} lines, expected <= {LINE_LIMITS[path]}")
    for forbidden in FORBIDDEN_UI_IMPORTS.get(path, []):
        if forbidden in text:
            fail(f"{path} must not contain {forbidden}")
    for snippet in REQUIRED_SNIPPETS.get(path, []):
        if snippet not in text:
            fail(f"{path} missing snippet: {snippet}")
    name = Path(path).name
    if name.endswith(".swift") and f"{name} in Sources" not in project_text:
        fail(f"{name} missing from Xcode Sources")

coordinator_text = read("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift")
for snippet in REQUIRED_SNIPPETS["iOS/Core/SessionRecording/SessionRecordingCoordinator.swift"]:
    if snippet not in coordinator_text:
        fail(f"SessionRecordingCoordinator.swift missing snippet: {snippet}")
if len(coordinator_text.splitlines()) > LINE_LIMITS["iOS/Core/SessionRecording/SessionRecordingCoordinator.swift"]:
    fail("SessionRecordingCoordinator.swift exceeds line limit")

localized_en = localization_keys("Shared/Localization/en.lproj/Localizable.strings")
localized_zh = localization_keys("Shared/Localization/zh-Hant.lproj/Localizable.strings")
for key in REQUIRED_KEYS:
    if key not in localized_en:
        fail(f"missing English localization key {key}")
    if key not in localized_zh:
        fail(f"missing Traditional Chinese localization key {key}")

print("Fall alert UI check passed: overlay, debug trigger, countdown bridge, SOS skeleton, localization, and project membership")
