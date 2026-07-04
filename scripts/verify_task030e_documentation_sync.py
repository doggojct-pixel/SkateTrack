#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-012 documentation sync."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

DOC_FILES = [
    "docs/DOCUMENTATION_INDEX.md",
    "docs/process/DEVELOPMENT_RULES.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/adr/ADR-INDEX.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]

REQUIRED_FILES = DOC_FILES + [
    "scripts/verify_task030e_documentation_sync.py",
    "scripts/verify_task030e_macos_multi_package_viewer.py",
    "scripts/run_task030e_macos_multi_package_viewer_oneclick.sh",
]

DOC_TOKENS: dict[str, list[str]] = {
    "docs/DOCUMENTATION_INDEX.md": [
        "Task-030e documentation sync",
        "Task-030e macOS multi-package viewer documentation routing",
        "one-click cleanup rule",
        "read-only package boundary",
    ],
    "docs/process/DEVELOPMENT_RULES.md": [
        "ONECLICK_CLEANUP_EXIT=0",
        "ONECLICK_RUN_DIR_REMOVED=YES",
        "verify_task030e_documentation_sync.py",
        "run_task030e_macos_multi_package_viewer_oneclick.sh",
    ],
    "docs/release/RELEASE_READINESS_PRE_ADP.md": [
        "Task-030e macOS package-viewer documentation sync",
        "verify_task030e_documentation_sync.py",
        "run_task030e_macos_multi_package_viewer_oneclick.sh",
        "ONECLICK_RUN_DIR_REMOVED=YES",
        "no import / merge / route mutation",
    ],
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
        "Task-030e macOS package viewer QA",
        "Acknowledge duplicate",
        "ONECLICK_RUN_DIR_REMOVED=YES",
        "read-only no-import boundary",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030e-MacViewer-012 — Documentation Sync and Current macOS Viewer Boundary",
        "read-only `.skatetrack` review surface",
        "ONECLICK_RUN_DIR_REMOVED=YES",
        "no import, no merge, no route mutation",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030e macOS multi-package viewer documentation sync",
        "read-only `.skatetrack` review surface",
        "one-click cleanup rule",
        "no import / merge / route mutation",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030e-MacViewer-012 Documentation Sync",
        "verify_task030e_documentation_sync.py",
        "one-click cleanup rule",
        "no route / metric / package mutation",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030e-MacViewer-012 Documentation Sync Addendum",
        "scripts/verify_task030e_documentation_sync.py",
        "docs source-of-truth alignment",
        "ONECLICK_RUN_DIR_REMOVED=YES",
    ],
}

FORBIDDEN_DOC_CLAIMS = [
    "Task-030e enables database import",
    "Task-030e enables package merge",
    "Task-030e enables route correction",
    "Task-030e enables Finder open-with",
    "Task-030e enables road matching",
    "Task-030e enables snap-to-road",
    "Task-030e enables local-history import",
]


def fail(message: str) -> None:
    print(f"Task-030e-012 documentation sync verification failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def ensure_required_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_doc_tokens() -> None:
    for path, tokens in DOC_TOKENS.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"{path} missing token: {token}")


def ensure_oneclick_sync() -> None:
    text = read("scripts/run_task030e_macos_multi_package_viewer_oneclick.sh")
    for token in [
        "verify_task030e_documentation_sync.py",
        "ONECLICK_CLEANUP_EXIT",
        "ONECLICK_RUN_DIR_REMOVED=\"YES\"",
        "rm -rf \"${RUN_DIR}\"",
        "Task-030e macOS multi-package viewer one-click verification",
    ]:
        if token not in text:
            fail(f"one-click runner missing token: {token}")
    if "Task-030e-MacViewer-011 — Verifier / Test Foundation" in text:
        fail("one-click runner should no longer describe itself as only the 011 subtask")


def ensure_consolidated_verifier_sync() -> None:
    text = read("scripts/verify_task030e_macos_multi_package_viewer.py")
    for token in [
        "verify_task030e_documentation_sync.py",
        "Task-030e-MacViewer-012 Documentation Sync",
        "ONECLICK_RUN_DIR_REMOVED=YES",
    ]:
        if token not in text:
            fail(f"consolidated verifier missing token: {token}")


def ensure_docs_whitespace() -> None:
    for relative in DOC_FILES:
        path = ROOT / relative
        data = path.read_bytes()
        if data.endswith(b"\n\n"):
            fail(f"{relative} has trailing blank line at EOF")
        if b"\r\n" in data:
            fail(f"{relative} uses CRLF line endings")


def ensure_no_forbidden_claims() -> None:
    combined = "\n".join(read(path) for path in DOC_FILES)
    for token in FORBIDDEN_DOC_CLAIMS:
        if token in combined:
            fail(f"forbidden documentation claim found: {token}")
    required_negative_claims = [
        "no import",
        "no merge",
        "no route mutation",
        "no Core Data write",
    ]
    for token in required_negative_claims:
        if token not in combined:
            fail(f"missing negative-scope claim: {token}")


def ensure_localization_not_changed_by_docs_task() -> None:
    # This docs-only task should not introduce new localization resources.
    for locale in ["en", "zh-Hant", "ja"]:
        path = ROOT / f"Shared/Localization/{locale}.lproj/Localizable.strings"
        if not path.exists():
            fail(f"missing localization file for {locale}")
        text = path.read_text(encoding="utf-8")
        if "Task-030e-MacViewer-012" in text:
            fail(f"docs task should not add user-facing localization keys in {locale}")


def main() -> None:
    ensure_required_files()
    ensure_doc_tokens()
    ensure_oneclick_sync()
    ensure_consolidated_verifier_sync()
    ensure_docs_whitespace()
    ensure_no_forbidden_claims()
    ensure_localization_not_changed_by_docs_task()
    print("Task-030e-012 documentation sync verification passed.")


if __name__ == "__main__":
    main()
