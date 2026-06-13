#!/usr/bin/env python3
"""Task-030b Pre-ADP release readiness / documentation consolidation gate.

This script verifies the consolidated documentation structure introduced in
Task-030b. It intentionally treats old per-topic ADR files and the stage-specific
Task026-030 technical-risk document as retired from active source control.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
DECISIONS = DOCS / "decisions"
PROJECT = ROOT / "SkateTrack.xcodeproj"
PROJECT_FILE = PROJECT / "project.pbxproj"
SCHEME_ROOT = PROJECT / "xcshareddata" / "xcschemes"

REQUIRED_FILES = [
    DOCS / "DOCUMENTATION_INDEX.md",
    DOCS / "DEVELOPMENT_RULES.md",
    DOCS / "KNOWN_LIMITATIONS_PRE_ADP.md",
    DOCS / "RELEASE_READINESS_PRE_ADP.md",
    DOCS / "MANUAL_QA_MATRIX_PRE_ADP.md",
    DOCS / "DEV_LOG.md",
    DOCS / "FILE_STRUCTURE.md",
    DECISIONS / "ADR-INDEX.md",
]

RETIRED_FILES = [
    *(DECISIONS / f"ADR-{number:04d}-{slug}.md" for number, slug in [
        (1, "subscription-entitlement-strategy"),
        (2, "developer-account-dependent-services"),
        (3, "gps-denied-indoor-recording-strategy"),
        (4, "export-targets-and-package-strategy"),
        (5, "achievements-and-challenges-scope-strategy"),
        (6, "backup-provider-and-package-strategy"),
        (7, "portable-skatetrack-package-strategy"),
        (8, "real-device-background-gps-recording"),
        (9, "localization-and-privacy-copy-strategy"),
        (10, "accessibility-privacy-quality-gate"),
        (11, "pre-adp-release-readiness-strategy"),
    ]),
    DOCS / "Task026-030_TechRisk_Solutions.md",
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

DOCUMENTATION_INDEX_TERMS = [
    "DOCUMENTATION_INDEX.md",
    "DEVELOPMENT_RULES.md",
    "KNOWN_LIMITATIONS_PRE_ADP.md",
    "ADR-INDEX.md",
    "Consolidated / removed documents",
    "Task-030b verification token: documentation index consolidated.",
]

DEVELOPMENT_RULES_TERMS = [
    "develop",
    "Hotfix package rules",
    "compile fixes",
    "Swift source files should generally remain under 500 lines",
    "Localizable.strings",
    "macOS layout rules",
    "Apple Developer Program / external-service boundary",
    "Do not claim",
    "Task-030b verification token: consolidated development rules.",
]

KNOWN_LIMITATION_TERMS = [
    "L-001 StoreKit Production Subscription",
    "L-002 Google Sign-In Production",
    "L-003 Google Drive Sync / Task-026c-blocked",
    "L-004 CloudKit / iCloud Sync",
    "L-005 WeatherKit Live Data",
    "L-006 TestFlight / App Store Submission",
    "L-007 Custom `.skatetrack` UTType / Finder Open-With / Document Association",
    "L-008 Real-device Background GPS Release Validation",
    "L-009 Fall Detection Diagnostics / Safe Test Mode",
    "L-010 Native Japanese Review",
    "L-011 Deferred Localization Roadmap",
    "pt-BR",
    "es",
    "Task-030b verification token: consolidated pre-ADP limitations.",
]

ADR_INDEX_TERMS = [
    "ADR-0001 Subscription Entitlement Strategy",
    "ADR-0002 Developer Account Dependent Services",
    "ADR-0007 Portable `.skatetrack` Package Strategy",
    "ADR-0011 Pre-ADP Release Readiness Strategy",
    "Future ADR rule",
    "Task-030b verification token: ADR index consolidated.",
]

RELEASE_TERMS = [
    "Documentation source-of-truth gate",
    "docs/DEVELOPMENT_RULES.md",
    "docs/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/decisions/ADR-INDEX.md",
    "Pre-ADP local-first development build",
    "Do not claim production subscriptions",
    "Do not claim real Google login",
    "Do not claim cloud sync",
    "Do not claim live WeatherKit",
    "Do not claim Finder open-with or custom UTType",
    "Do not claim upload readiness",
    "read-only `.skatetrack` package viewer",
    "Task-030b verification token: consolidated release readiness documentation.",
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
    "Task-030b verification token: consolidated manual QA matrix.",
]

FILE_STRUCTURE_TERMS = [
    "Task-030b Documentation Consolidation + Deferred Feature Handoff Package",
    "docs/DOCUMENTATION_INDEX.md",
    "docs/DEVELOPMENT_RULES.md",
    "docs/decisions/ADR-INDEX.md",
    "Task-030b removes the old per-topic ADR files",
]

FORBIDDEN_PROJECT_TOKENS = [
    "UTExportedTypeDeclarations",
    "CFBundleDocumentTypes",
    "com.apple.developer.icloud",
    "com.apple.developer.associated-domains",
    "com.apple.developer.weatherkit",
    "GoogleService-Info.plist",
]

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
        print("Missing Task-030b consolidated documentation / verify files:")
        for item in missing + missing_scripts:
            print(f"- {item}")
        return False
    return True


def check_retired_files_removed() -> bool:
    existing = [rel(path) for path in RETIRED_FILES if path.exists()]
    if existing:
        print("Retired Task-030b documentation files still exist. Remove them after consolidation:")
        for item in existing:
            print(f"- {item}")
        return False
    return True


def check_terms(path: Path, terms: list[str], label: str) -> bool:
    text = read(path)
    missing = [term for term in terms if term not in text]
    if missing:
        print(f"{label} is missing required Task-030b terms:")
        for term in missing:
            print(f"- {term}")
        return False
    return True


def check_docs() -> bool:
    return all([
        check_terms(DOCS / "DOCUMENTATION_INDEX.md", DOCUMENTATION_INDEX_TERMS, "DOCUMENTATION_INDEX.md"),
        check_terms(DOCS / "DEVELOPMENT_RULES.md", DEVELOPMENT_RULES_TERMS, "DEVELOPMENT_RULES.md"),
        check_terms(DOCS / "KNOWN_LIMITATIONS_PRE_ADP.md", KNOWN_LIMITATION_TERMS, "KNOWN_LIMITATIONS_PRE_ADP.md"),
        check_terms(DECISIONS / "ADR-INDEX.md", ADR_INDEX_TERMS, "ADR-INDEX.md"),
        check_terms(DOCS / "RELEASE_READINESS_PRE_ADP.md", RELEASE_TERMS, "RELEASE_READINESS_PRE_ADP.md"),
        check_terms(DOCS / "MANUAL_QA_MATRIX_PRE_ADP.md", MANUAL_QA_TERMS, "MANUAL_QA_MATRIX_PRE_ADP.md"),
        check_terms(DOCS / "FILE_STRUCTURE.md", FILE_STRUCTURE_TERMS, "FILE_STRUCTURE.md"),
    ])


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
        check_retired_files_removed(),
        check_docs(),
        check_project_settings(),
        check_scheme_hygiene(),
        check_production_unlock_patterns(),
        check_docs_no_overclaim(),
    ]
    if not all(checks):
        return 1
    print("Task-030b release readiness check passed: documentation index, development rules, known limitations, ADR index, schemes, project settings, and service-boundary gates are aligned")
    return 0


if __name__ == "__main__":
    sys.exit(main())
