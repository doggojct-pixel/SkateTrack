#!/usr/bin/env python3
"""Verify DEBUG-only tools are centralized and mock speed is not the default app runtime."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    ROOT / "iOS/Features/Debug/DebugFeatureFlag.swift",
    ROOT / "iOS/Features/Debug/DebugToolAction.swift",
    ROOT / "iOS/Features/Debug/DebugRuntimeOptions.swift",
    ROOT / "iOS/Features/Debug/DebugMockSessionFactory.swift",
    ROOT / "iOS/Features/Debug/DebugToolsPanelView.swift",
]



def ensure_unique_debug_build_file_membership(pbx_text: str) -> None:
    expected = {
        "DebugFeatureFlag.swift": "14D000000000000000000101",
        "DebugToolAction.swift": "14D000000000000000000102",
        "DebugRuntimeOptions.swift": "14D000000000000000000103",
        "DebugMockSessionFactory.swift": "14D000000000000000000104",
        "DebugToolsPanelView.swift": "14D000000000000000000105",
    }
    for filename, build_id in expected.items():
        definition = f"{build_id} /* {filename} in Sources */ = {{isa = PBXBuildFile;"
        source_entry = f"{build_id} /* {filename} in Sources */,"
        if definition not in pbx_text:
            sys.exit(f"project.pbxproj missing unique PBXBuildFile definition for {filename}")
        if source_entry not in pbx_text:
            sys.exit(f"project.pbxproj missing unique Compile Sources entry for {filename}")

    duplicate_legacy_id_count = pbx_text.count("14D000000000000000000101 /* Debug")
    if duplicate_legacy_id_count != 2:
        sys.exit("project.pbxproj has duplicate debug PBXBuildFile IDs; Xcode may skip files in Compile Sources")


for file_path in REQUIRED_FILES:
    if not file_path.exists():
        sys.exit(f"Missing required debug tools file: {file_path.relative_to(ROOT)}")

app_text = (ROOT / "iOS/App/SkateTrackApp.swift").read_text()
if "makeMockCoordinator" in app_text:
    sys.exit("SkateTrackApp.swift must not create a mock coordinator for normal app runtime")
if "useSessionRecording()" not in app_text:
    sys.exit("SkateTrackApp.swift should create the normal real session recording view model")

root_text = (ROOT / "iOS/App/RootNavigationView.swift").read_text()
for token in [
    "DebugRuntimeOptions.shared",
    "DebugToolsPanelView(",
    "DebugToolAction.openPanel.accessibilityIdentifier",
]:
    if token not in root_text:
        sys.exit(f"RootNavigationView.swift missing debug tools token: {token}")

start_text = (ROOT / "iOS/Features/SessionRecording/SessionStartView.swift").read_text()
if "debugSection" in start_text:
    sys.exit("SessionStartView.swift should not keep a separate debugSection")

live_text = (ROOT / "iOS/Features/SessionRecording/LiveHUDView.swift").read_text()
if "debugSimulateFallButton" in live_text or "debug-simulate-fall-button" in live_text:
    sys.exit("LiveHUDView.swift should not keep a separate simulate-fall debug button")

session_hook_text = (ROOT / "iOS/Hooks/useSessionRecording.swift").read_text()
for token in [
    "debugDemoSpeedSessionEnabled",
    "setDebugDemoSpeedSessionEnabled",
    "coordinator.setDataSource(isEnabled ? .mock : .live)",
    "SessionRecordingPreviewPanel",
    "debug.status.title",
    "metricTile(",
]:
    if token not in session_hook_text:
        sys.exit(f"useSessionRecording.swift missing debug demo/status token: {token}")

coordinator_text = (ROOT / "iOS/Core/SessionRecording/SessionRecordingCoordinator.swift").read_text()
debug_extension_path = ROOT / "iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift"
debug_extension_text = debug_extension_path.read_text() if debug_extension_path.exists() else ""
combined_debug_text = coordinator_text + "\n" + debug_extension_text
for token in [
    "var debugDataSource: SessionRecordingDataSource",
    "static func makeMockCoordinator()",
    "DebugOutdoorRouteSimulator",
    "speedSource: .debugSimulated",
    "simulatedAltitudeMeters",
]:
    if token not in combined_debug_text:
        sys.exit(f"SessionRecordingCoordinator debug support missing expected token: {token}")

panel_text = (ROOT / "iOS/Features/Debug/DebugToolsPanelView.swift").read_text()
for token in [
    "DebugMockSessionFactory.setDemoSpeedSessionEnabled",
    "fallDetection.actions.simulateFallAlert",
    "SubscriptionDebugPanel(subscriptionStatus:",
    "emergencyContactStore.clearContacts()",
    "DebugToolAction.toggleSnowModeEntry.accessibilityIdentifier",
    "debug-tools-panel",
    "debugBuildSignatureCard",
    "Task-030c-b11-r3-3",
    "debug-build-signature-card",
    "recordingDiagnosticsContextSection",
    "debug-recording-context-picker",
]:
    if token not in panel_text:
        sys.exit(f"DebugToolsPanelView.swift missing token: {token}")

pbx_text = (ROOT / "SkateTrack.xcodeproj/project.pbxproj").read_text()
for filename in [path.name for path in REQUIRED_FILES]:
    if filename not in pbx_text:
        sys.exit(f"project.pbxproj missing debug file membership: {filename}")
ensure_unique_debug_build_file_membership(pbx_text)

localization_files = [
    ROOT / "Shared/Localization/en.lproj/Localizable.strings",
    ROOT / "Shared/Localization/zh-Hant.lproj/Localizable.strings",
]
for loc in localization_files:
    text = loc.read_text()
    for key in [
        "debug.tools.title",
        "debug.tools.simulateFall.button",
        "debug.tools.demoSpeed.toggle",
        "debug.tools.resetContacts.button",
        "debug.status.title",
        "debug.build.title",
        "debug.tools.recordingContext.title",
    ]:
        if key not in text:
            sys.exit(f"{loc.relative_to(ROOT)} missing localization key: {key}")

print("Debug tools check passed: centralized debug entry, explicit simulated route mode, and app runtime real-sensor default")
