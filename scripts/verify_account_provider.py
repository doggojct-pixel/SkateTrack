#!/usr/bin/env python3
"""Verify Task-025a account provider foundation stays mock / disabled only."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "Shared/Models/AuthSession.swift",
    "iOS/Core/Account/AuthProvider.swift",
    "iOS/Core/Account/LocalAccountProvider.swift",
    "iOS/Core/Account/DisabledGoogleAuthProvider.swift",
    "iOS/Core/Account/AuthTokenStore.swift",
    "iOS/Hooks/useAccount.swift",
    "Shared/Localization/en.lproj/Localizable.strings",
    "Shared/Localization/zh-Hant.lproj/Localizable.strings",
    "docs/DEV_LOG.md",
    "docs/FILE_STRUCTURE.md",
    "docs/decisions/ADR-0002-developer-account-dependent-services.md",
]

PROJECT_TOKENS = [
    "AuthSession.swift in Sources",
    "iOS/Core/Account",
    "AuthProvider.swift in Sources",
    "LocalAccountProvider.swift in Sources",
    "DisabledGoogleAuthProvider.swift in Sources",
    "AuthTokenStore.swift in Sources",
    "useAccount.swift in Sources",
]

LOCALIZATION_KEYS = [
    "account.title",
    "account.provider.none",
    "account.provider.local_simulation",
    "account.provider.google_disabled",
    "account.status.signed_out",
    "account.status.local_simulation_signed_in",
    "account.status.google_unavailable",
    "account.auth.error.google_unconfigured",
    "account.auth.error.production_credentials_missing",
    "account.auth.error.token_storage_unavailable",
    "account.auth.error.local_simulation_release_unavailable",
    "account.auth.error.generic",
    "account.google.deferred.title",
    "account.google.deferred.subtitle",
    "account.privacy.local_first",
    "account.debug.sign_in_local",
    "account.debug.sign_out_local",
]

SOURCE_TOKENS = {
    "Shared/Models/AuthSession.swift": [
        "enum AuthProviderKind",
        "enum AuthSessionState",
        "struct AuthAccountProfile",
        "struct AuthSession",
        "localSimulationSignedIn",
        "googleUnavailable",
    ],
    "iOS/Core/Account/AuthProvider.swift": [
        "protocol AuthProvider",
        "protocol GoogleSignInProviding",
        "AuthProviderError",
        "isProductionProviderAvailable",
    ],
    "iOS/Core/Account/LocalAccountProvider.swift": [
        "final class LocalAccountProvider",
        "#if DEBUG",
        "localSimulationSignedIn",
        "local_simulation_release_unavailable",
    ],
    "iOS/Core/Account/DisabledGoogleAuthProvider.swift": [
        "final class DisabledGoogleAuthProvider",
        "GoogleSignInProviding",
        "google_unconfigured",
        "googleUnavailable",
    ],
    "iOS/Core/Account/AuthTokenStore.swift": [
        "protocol AuthTokenStoring",
        "final class AuthTokenStore",
        "hasProductionToken",
        "false",
        "not保存真 token".replace("not", "不"),
    ],
    "iOS/Hooks/useAccount.swift": [
        "final class AccountViewModel",
        "LocalAccountProvider.shared",
        "DisabledGoogleAuthProvider.shared",
        "signInWithLocalSimulation",
        "requestGoogleSignIn",
    ],
}

FORBIDDEN_SOURCE_PATTERNS = [
    r"import\s+GoogleSignIn",
    r"\bGIDSignIn\b",
    r"\bGIDConfiguration\b",
    r"class\s+GoogleSignInProvider\b",
    r"struct\s+GoogleSignInProvider\b",
    r"GoogleService-Info\.plist",
    r"REVERSED_CLIENT_ID",
    r"com\.googleusercontent\.apps",
    r"client[_-]?secret",
    r"oauth[_-]?client[_-]?id\s*=",
    r"URLSession",
    r"Drive\.Scopes",
    r"GTLRDrive",
]

FORBIDDEN_PROJECT_PATTERNS = [
    r"GoogleService-Info\.plist",
    r"com\.googleusercontent\.apps",
    r"REVERSED_CLIENT_ID",
    r"GoogleSignIn",
    r"INFOPLIST_KEY_CFBundleURLTypes",
]


def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def extract_keys(relative: str) -> set[str]:
    return set(re.findall(r'^"([^"]+)"\s*=', read(relative), flags=re.MULTILINE))


def verify_files() -> None:
    for relative in REQUIRED_FILES:
        path = ROOT / relative
        if not path.exists():
            fail(f"Missing required file: {relative}")
        if relative.endswith(".swift"):
            line_count = len(path.read_text(encoding="utf-8").splitlines())
            if line_count > 500:
                fail(f"{relative} exceeds 500-line limit: {line_count}")


def verify_project() -> None:
    project = read("SkateTrack.xcodeproj/project.pbxproj")
    for token in PROJECT_TOKENS:
        if token not in project:
            fail(f"project.pbxproj missing token: {token}")
    for pattern in FORBIDDEN_PROJECT_PATTERNS:
        if re.search(pattern, project, flags=re.IGNORECASE):
            fail(f"project.pbxproj contains forbidden Google production configuration: {pattern}")


def verify_localization() -> None:
    for locale in ["en.lproj", "zh-Hant.lproj"]:
        keys = extract_keys(f"Shared/Localization/{locale}/Localizable.strings")
        for key in LOCALIZATION_KEYS:
            if key not in keys:
                fail(f"Missing localization key {key} in {locale}")


def verify_sources() -> None:
    source_blob = []
    for relative, tokens in SOURCE_TOKENS.items():
        text = read(relative)
        source_blob.append(text)
        for token in tokens:
            if token not in text:
                fail(f"{relative} missing token: {token}")
        if relative.startswith("iOS/Core/Account") and "import SwiftUI" in text:
            fail(f"Core account source must not import SwiftUI: {relative}")

    scanned = "\n".join(source_blob)
    for pattern in FORBIDDEN_SOURCE_PATTERNS:
        if re.search(pattern, scanned, flags=re.IGNORECASE):
            fail(f"Task-025a must not introduce production Google source pattern: {pattern}")


def verify_docs() -> None:
    dev_log = read("docs/DEV_LOG.md")
    file_structure = read("docs/FILE_STRUCTURE.md")
    adr = read("docs/decisions/ADR-0002-developer-account-dependent-services.md")
    docs = "\n".join([dev_log, file_structure, adr])
    for token in [
        "Task-025a",
        "Account Provider Foundation",
        "DisabledGoogleAuthProvider",
        "LocalAccountProvider",
        "AuthTokenStore",
        "Google Sign-In production",
        "Deferred from Task-025a",
        "Task-025b",
        "Task-026",
    ]:
        if token not in docs:
            fail(f"Living docs / ADR missing Task-025a token: {token}")


def main() -> None:
    verify_files()
    verify_project()
    verify_localization()
    verify_sources()
    verify_docs()
    print("✅ Task-025a account provider verification passed.")


if __name__ == "__main__":
    main()
