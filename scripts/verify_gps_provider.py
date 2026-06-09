#!/usr/bin/env python3
"""Validate Task-006 GPS Provider files and localization hooks."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    ROOT / "iOS/Core/SensorEngine/GPSProvider.swift",
    ROOT / "iOS/Core/SensorEngine/GPSAuthorizationHandler.swift",
    ROOT / "Shared/Localization/en.lproj/Localizable.strings",
    ROOT / "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    ROOT / "Shared/Localization/en.lproj/InfoPlist.strings",
    ROOT / "Shared/Localization/zh-Hant.lproj/InfoPlist.strings",
]
FORBIDDEN_IMPORTS = ["SwiftUI", "UIKit"]
LOCALIZABLE_KEYS = [
    "permission.location.whenInUse",
    "permission.location.always",
]
INFOPLIST_KEYS = [
    "NSLocationWhenInUseUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
]
PROJECT_REQUIRED_TOKENS = [
    "GPSProvider.swift in Sources",
    "GPSAuthorizationHandler.swift in Sources",
    "InfoPlist.strings in Resources",
    "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription",
    "INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription",
]


def fail(message: str) -> None:
    print(f"GPS provider check failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: Path) -> str:
    if not path.exists():
        fail(f"missing file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require_contains(text: str, token: str, context: str) -> None:
    if token not in text:
        fail(f"missing {token!r} in {context}")


def main() -> None:
    contents = {path: read(path) for path in REQUIRED_FILES}

    for path in REQUIRED_FILES[:2]:
        text = contents[path]
        if not text.startswith("// [自主區]"):
            fail(f"missing autonomous zone header: {path.relative_to(ROOT)}")
        if len(text.splitlines()) > 300:
            fail(f"file exceeds 300 lines: {path.relative_to(ROOT)}")
        for forbidden in FORBIDDEN_IMPORTS:
            if re.search(rf"^import\s+{forbidden}\b", text, re.MULTILINE):
                fail(f"forbidden import {forbidden}: {path.relative_to(ROOT)}")

    provider = contents[ROOT / "iOS/Core/SensorEngine/GPSProvider.swift"]
    authorization = contents[ROOT / "iOS/Core/SensorEngine/GPSAuthorizationHandler.swift"]

    for token in [
        "CLLocationManagerDelegate",
        "AnyPublisher<CLLocation, Never>",
        "speedKilometersPerHourPublisher",
        "kCLLocationAccuracyBest",
        "kCLLocationAccuracyHundredMeters",
        "horizontalAccuracy <= Self.maximumAcceptedHorizontalAccuracy",
        "max(metersPerSecond, 0) * 3.6",
    ]:
        require_contains(provider, token, "GPSProvider.swift")

    for token in [
        "requestWhenInUseAuthorization",
        "requestAlwaysAuthorization",
        "authorizedAlways",
        "authorizedWhenInUse",
        "notDetermined",
    ]:
        require_contains(authorization, token, "GPSAuthorizationHandler.swift")

    for lang in ["en.lproj", "zh-Hant.lproj"]:
        localizable = contents[ROOT / f"Shared/Localization/{lang}/Localizable.strings"]
        infoplist = contents[ROOT / f"Shared/Localization/{lang}/InfoPlist.strings"]
        for key in LOCALIZABLE_KEYS:
            require_contains(localizable, key, f"{lang}/Localizable.strings")
        for key in INFOPLIST_KEYS:
            require_contains(infoplist, key, f"{lang}/InfoPlist.strings")

    project = read(ROOT / "SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_REQUIRED_TOKENS:
        require_contains(project, token, "project.pbxproj")

    print("GPS provider check passed: 2 provider files, 2 permission keys")


if __name__ == "__main__":
    main()
