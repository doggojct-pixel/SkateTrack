#!/usr/bin/env python3
"""Task-030a Pre-ADP release readiness verification gate.

This script verifies that Task-030a remains a documentation / quality-gate task:
release-readiness docs exist, known limitations are explicit, schemes are not
polluted by local language / location testing state, and project settings do not
silently add production capabilities, custom UTTypes, document association, or
external-service unlocks.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
PROJECT = ROOT / "SkateTrack.xcodeproj"
PROJECT_FILE = PROJECT / "project.pbxproj"
SCHEME_ROOT = PROJECT / "xcshareddata" / "xcschemes"

REQUIRED_FILES = [
    DOCS / "RELEASE_READINESS_PRE_ADP.md",
    DOCS / "MANUAL_QA_MATRIX_PRE_ADP.md",
    DOCS / "KNOWN_LIMITATIONS_PRE_ADP.md",
    DOCS / "DEV_LOG.md",
    DOCS / "FILE_STRUCTURE.md",
    DOCS / "Task026-030_TechRisk_Solutions.md",
    DOCS / "decisions" / "ADR-0011-pre-adp-release-readiness-strategy.md",
]

REQUIRED_VERIFY_SCRIPTS = [
    "verify_task030_release_readiness.py",
    "verify_localization_keys.py",
    "verify_task029_localization_privacy.py",
    "verify_task029b_accessibility_privacy_gate.py",
    "verify_macos_session_viewer.py",
    "verify_macos_route_chart_viewer.py",
    "verify_macos_package_preview.py",
    "verify_skatetrack_package.py",
    "verify_backup_sync.py",
    "verify_backup_restore_preview.py",
    "verify_account_provider.py",
    "verify_gps_background_recording.py",
    "verify_shared_models.py",
]

RELEASE_READINESS_TERMS = [
    "Pre-ADP local-first development build",
    "python3 scripts/verify_task030_release_readiness.py",
    "xcodebuild",
    "SkateTrack-iOS",
    "SkateTrack-macOS",
    "System Language",
    "Google Drive",
    "StoreKit",
    "CloudKit",
    "WeatherKit",
    "TestFlight",
    "custom UTType",
    "document association",
    "real-device background GPS",
    "Fall Detection",
    "Task-030a verification token: pre-ADP release readiness gate",
]

MANUAL_QA_TERMS = [
    "English",
    "Traditional Chinese",
    "Japanese",
    "iOS ride recording",
    "macOS package viewer",
    "Accessibility spot checks",
    "Privacy and service boundary checks",
    "Build and scheme hygiene",
    "Task-030a verification token: manual QA matrix pre-ADP",
]

KNOWN_LIMITATION_TERMS = [
    "StoreKit Production Subscription",
    "Google Sign-In Production",
    "Google Drive Sync",
    "Custom `.skatetrack` Document Association",
    "WeatherKit Live Data",
    "TestFlight Upload",
    "CloudKit / iCloud Sync",
    "Real-device Background GPS Release Validation",
    "Fall Detection Diagnostics / Safe Test Mode",
    "Native Japanese Review",
    "Deferred Localization Roadmap",
    "pt-BR",
    "es",
]

ADR_TERMS = [
    "Accepted — Task-030a",
    "Pre-ADP release-readiness gate",
    "No new production services are added",
    "No signing, provisioning, Bundle ID, entitlement, custom UTType, or document-association change is introduced",
    "Real-device background GPS testing",
    "Fall Detection must not be validated through unsafe human-impact tests",
    "Task-030a verification token: pre-ADP release readiness strategy",
]

FILE_STRUCTURE_TERMS = [
    "Task-030a Pre-ADP Release Readiness Audit + Verify Gate",
    "scripts/verify_task030_release_readiness.py",
    "docs/RELEASE_READINESS_PRE_ADP.md",
    "docs/MANUAL_QA_MATRIX_PRE_ADP.md",
]

TECH_RISK_TERMS = [
    "Task-030a Pre-ADP Release Readiness Gate",
    "Do not commit Xcode scheme changes",
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "pre-ADP release readiness gate",
]

# These should never be introduced into the project file before the relevant
# Apple Developer Program / document-association tasks. UIBackgroundModes=location
# is already an intentional Task-027-preflight setting and is not forbidden.
FORBIDDEN_PROJECT_TOKENS = [
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "com.apple.developer.icloud",
    "com.apple.developer.associated-domains",
    "com.apple.developer.weatherkit",
    "GoogleService-Info.plist",
]

# Shared schemes may allow simulator location, but they should not capture a
# current scenario or fixed app language / region from local QA sessions.
FORBIDDEN_SCHEME_PATTERNS = [
    "LocationScenarioReference",
    "CurrentLocationScenarioIdentifier",
    'language = "',
    'region = "',
    "AppleLanguages",
    "AppleLocale",
]

PRODUCTION_UNLOCK_PATTERNS = {
    "iOS": [
        "GoogleService-Info.plist",
        "client_secret",
        "Product.products(",
        "CKContainer(",
        "WeatherService(",
    ],
    "macOS": [
        "GoogleService-Info.plist",
        "client_secret",
        "CKContainer(",
    ],
    "Shared": [
        "client_secret",
        "refresh_token",
    ],
}


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_required_files() -> bool:
    missing = [rel(path) for path in REQUIRED_FILES if not path.exists()]
    missing_scripts = [f"scripts/{name}" for name in REQUIRED_VERIFY_SCRIPTS if not (ROOT / "scripts" / name).exists()]
    if missing or missing_scripts:
        print("Missing Task-030a release-readiness files:")
        for item in missing + missing_scripts:
            print(f"- {item}")
        return False
    return True


def check_terms(path: Path, terms: list[str], label: str) -> bool:
    text = read(path)
    missing = [term for term in terms if term not in text]
    if missing:
        print(f"{label} is missing required release-readiness terms:")
        for term in missing:
            print(f"- {term}")
        return False
    return True


def check_docs() -> bool:
    return all(
        [
            check_terms(DOCS / "RELEASE_READINESS_PRE_ADP.md", RELEASE_READINESS_TERMS, "RELEASE_READINESS_PRE_ADP.md"),
            check_terms(DOCS / "MANUAL_QA_MATRIX_PRE_ADP.md", MANUAL_QA_TERMS, "MANUAL_QA_MATRIX_PRE_ADP.md"),
            check_terms(DOCS / "KNOWN_LIMITATIONS_PRE_ADP.md", KNOWN_LIMITATION_TERMS, "KNOWN_LIMITATIONS_PRE_ADP.md"),
            check_terms(DOCS / "decisions" / "ADR-0011-pre-adp-release-readiness-strategy.md", ADR_TERMS, "ADR-0011"),
            check_terms(DOCS / "FILE_STRUCTURE.md", FILE_STRUCTURE_TERMS, "FILE_STRUCTURE.md"),
            check_terms(DOCS / "Task026-030_TechRisk_Solutions.md", TECH_RISK_TERMS, "Task026-030_TechRisk_Solutions.md"),
        ]
    )


def check_project_settings() -> bool:
    if not PROJECT_FILE.exists():
        print("Missing project.pbxproj")
        return False
    text = read(PROJECT_FILE)
    found = [token for token in FORBIDDEN_PROJECT_TOKENS if token in text]
    if found:
        print("Project file contains pre-ADP forbidden project settings / production artifacts:")
        for token in found:
            print(f"- {token}")
        return False
    return True


def check_scheme_hygiene() -> bool:
    if not SCHEME_ROOT.exists():
        print("Missing shared Xcode schemes directory")
        return False
    failed = False
    for scheme in sorted(SCHEME_ROOT.glob("*.xcscheme")):
        text = read(scheme)
        found = [pattern for pattern in FORBIDDEN_SCHEME_PATTERNS if pattern in text]
        if found:
            print(f"Shared scheme contains local QA state in {rel(scheme)}:")
            for pattern in found:
                print(f"- {pattern}")
            failed = True
    return not failed


def check_production_unlock_patterns() -> bool:
    failed = False
    for directory, patterns in PRODUCTION_UNLOCK_PATTERNS.items():
        root = ROOT / directory
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in {".swift", ".plist", ".strings", ".md"}:
                continue
            text = read(path)
            found = [pattern for pattern in patterns if pattern in text]
            if found:
                print(f"Potential production-service unlock token in {rel(path)}:")
                for pattern in found:
                    print(f"- {pattern}")
                failed = True
    return not failed


def check_docs_no_overclaim() -> bool:
    docs_text = "\n".join(read(path) for path in REQUIRED_FILES if path.exists())
    required_negations = [
        "Do not claim production subscriptions",
        "Do not claim real Google login",
        "Do not claim cloud sync",
        "Do not claim live WeatherKit",
        "Do not claim Finder open-with or custom UTType",
        "Do not claim upload readiness",
        "read-only `.skatetrack` package viewer",
    ]
    missing = [term for term in required_negations if term not in docs_text]
    if missing:
        print("Release docs are missing required no-overclaim statements:")
        for term in missing:
            print(f"- {term}")
        return False
    return True


def main() -> int:
    checks = [
        check_required_files(),
        check_docs(),
        check_project_settings(),
        check_scheme_hygiene(),
        check_production_unlock_patterns(),
        check_docs_no_overclaim(),
    ]
    if not all(checks):
        return 1
    print("Task-030a release readiness check passed: docs, known limitations, schemes, project settings, and service-boundary gates are aligned")
    return 0


if __name__ == "__main__":
    sys.exit(main())
