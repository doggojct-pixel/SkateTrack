#!/usr/bin/env python3
"""Verify Task-027-preflight real-device GPS background recording safeguards.

Static checks only:
- Confirms generated iOS Info.plist includes UIBackgroundModes=location.
- Confirms GPSProvider enables background updates only when the plist declares location mode.
- Confirms GPSProvider requests an Always authorization upgrade during active ride sessions.
- Confirms GPSProvider disables automatic pausing while active background recording is requested.
- Confirms SensorFusionEngine emits location-driven samples so background location callbacks can preserve route data.
- Confirms start-screen copy explains real-device recording requirements.
This script does not validate runtime Core Location delivery on a physical iPhone.
"""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = {
    "SkateTrack.xcodeproj/project.pbxproj": [
        "INFOPLIST_KEY_UIBackgroundModes = location;",
        "INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription",
        "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription",
    ],
    "iOS/Core/SensorEngine/GPSProvider.swift": [
        "allowsBackgroundLocationUpdates",
        "showsBackgroundLocationIndicator",
        "pausesLocationUpdatesAutomatically = !shouldAllowBackgroundUpdates",
        "hasBackgroundLocationModeDeclared",
        "requestAlwaysAuthorizationUpgradeIfNeeded",
        "canRequestAlwaysAuthorizationUpgrade",
        "effectiveSpeedKilometersPerHour",
        "maximumAcceptedHorizontalAccuracy: CLLocationAccuracy = 35",
    ],
    "iOS/Core/SensorEngine/GPSAuthorizationHandler.swift": [
        "canRequestAlwaysAuthorizationUpgrade",
        "currentStatus == .authorizedWhenInUse",
    ],
    "iOS/Core/SensorEngine/SensorFusionEngine.swift": [
        "publishLocationDrivenMotionSampleIfNeeded",
        "sampleQueue.async",
        "lastLocationDrivenSampleDate",
    ],
    "Shared/Models/SessionSummaryMetrics.swift": [
        "motionSampleCount",
        "gpsSampleCount",
    ],
    "iOS/Core/SessionRecording/SessionMetricsAccumulator.swift": [
        "motionSampleCount += 1",
        "gpsSampleCount += 1",
        "lastCoordinateTimestamp",
        "minimumSegmentDistanceKilometers = 0.003",
        "maximumSegmentDistanceKilometers = 2.0",
        "previousCoordinateTimestamp",
        "Keep the previous GPS anchor",
    ],
    "iOS/Hooks/useSessionRecording.swift": [
        "motionSampleCount",
        "gpsSampleCount",
    ],
    "iOS/Features/SessionRecording/SessionStartView.swift": [
        "realDeviceRecordingNotice",
        "session-start-background-recording-notice",
    ],
    "Shared/Localization/en.lproj/Localizable.strings": [
        "session.start.backgroundRecording.title",
        "session.start.backgroundRecording.detail",
    ],
    "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
        "session.start.backgroundRecording.title",
        "session.start.backgroundRecording.detail",
    ],
    "docs/decisions/ADR-0008-real-device-background-gps-recording.md": [
        "UIBackgroundModes",
        "allowsBackgroundLocationUpdates",
        "Deferred",
    ],
}


def fail(message: str) -> None:
    print(f"GPS background recording check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        fail(f"missing file: {rel}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    for rel, tokens in REQUIRED.items():
        text = read(rel)
        for token in tokens:
            if token not in text:
                fail(f"missing {token!r} in {rel}")


    accumulator = read("iOS/Core/SessionRecording/SessionMetricsAccumulator.swift")
    distance_body_start = accumulator.find("private mutating func accumulateDistance")
    distance_body_end = accumulator.find("private mutating func accumulateElevation", distance_body_start)
    distance_body = accumulator[distance_body_start:distance_body_end]
    if "defer" in distance_body:
        fail("SessionMetricsAccumulator must not update GPS distance anchor with defer because duplicate 10Hz samples reset the coordinate timestamp")

    provider = read("iOS/Core/SensorEngine/GPSProvider.swift")
    if "allowsBackgroundLocationUpdates = true" in provider:
        fail("GPSProvider must not blindly set allowsBackgroundLocationUpdates=true without checking UIBackgroundModes")

    project = read("SkateTrack.xcodeproj/project.pbxproj")
    if project.count("INFOPLIST_KEY_UIBackgroundModes = location;") < 2:
        fail("UIBackgroundModes location must be present for both iOS Debug and Release build settings")

    print("GPS background recording check passed: background mode, provider flags, samples, diagnostics copy, and ADR are aligned")


if __name__ == "__main__":
    main()
