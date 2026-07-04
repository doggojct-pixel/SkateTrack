#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-014 final merge gate documentation and tooling."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "docs/release/TASK030E_FINAL_MERGE_GATE.md",
    "docs/release/TASK030E_MANUAL_QA_GATE.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/DOCUMENTATION_INDEX.md",
    "docs/process/DEVELOPMENT_RULES.md",
    "docs/adr/ADR-INDEX.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task030e_final_merge_gate.py",
    "scripts/verify_task030e_manual_qa_gate.py",
    "scripts/verify_task030e_documentation_sync.py",
    "scripts/verify_task030e_macos_multi_package_viewer.py",
    "scripts/run_task030e_macos_multi_package_viewer_oneclick.sh",
]

DOC_FILES = [
    "docs/release/TASK030E_FINAL_MERGE_GATE.md",
    "docs/release/TASK030E_MANUAL_QA_GATE.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/DOCUMENTATION_INDEX.md",
    "docs/process/DEVELOPMENT_RULES.md",
    "docs/adr/ADR-INDEX.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
]

FINAL_GATE_TOKENS: dict[str, list[str]] = {
    "docs/release/TASK030E_FINAL_MERGE_GATE.md": [
        "Task-030e-MacViewer-014 final merge gate checklist",
        "Required branch preconditions",
        "Required automated evidence",
        "Manual signoff carried into final merge",
        "Final no-scope-expansion checks",
        "Merge command policy",
        "task030e_014_oneclick",
        "verify_task030e_final_merge_gate.py",
        "origin/develop ancestry",
        "ONECLICK_RUN_DIR_REMOVED=YES",
        "leave `main` untouched",
    ],
    "docs/DOCUMENTATION_INDEX.md": [
        "Task-030e final merge checklist",
        "docs/release/TASK030E_FINAL_MERGE_GATE.md",
        "Final Merge Gate routing",
        "develop merge readiness",
    ],
    "docs/process/DEVELOPMENT_RULES.md": [
        "docs/release/TASK030E_FINAL_MERGE_GATE.md",
        "verify_task030e_final_merge_gate.py",
        "Task-030e final merge gate",
        "leave `main` untouched",
    ],
    "docs/release/RELEASE_READINESS_PRE_ADP.md": [
        "Task-030e-MacViewer-014 final merge gate",
        "TASK030E_FINAL_MERGE_GATE.md",
        "verify_task030e_final_merge_gate.py",
        "develop merge readiness",
    ],
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
        "Task-030e-MacViewer-014 final merge gate",
        "TASK030E_FINAL_MERGE_GATE.md",
        "manual QA gate remains a merge blocker",
        "task030e_014_oneclick",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030e-MacViewer-014 — Final Merge Gate",
        "merge-readiness checklist and verifier only",
        "no import / merge / route mutation",
        "Task-031-prep remains deferred",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030e macOS multi-package viewer final merge gate",
        "develop merge readiness",
        "final no-scope-expansion review",
        "no schema / Core Data mutation",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030e-MacViewer-014 Final Merge Gate",
        "TASK030E_FINAL_MERGE_GATE.md",
        "verify_task030e_final_merge_gate.py",
        "develop merge readiness",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030e-MacViewer-014 Final Merge Gate Addendum",
        "TASK030E_FINAL_MERGE_GATE.md",
        "verify_task030e_final_merge_gate.py",
        "final merge gate checklist",
    ],
}

FORBIDDEN_RUNTIME_CLAIMS = [
    "Task-030e-MacViewer-014 implements package import",
    "Task-030e-MacViewer-014 implements package merge",
    "Task-030e-MacViewer-014 implements route correction",
    "Task-030e-MacViewer-014 implements Core Data write",
    "Task-030e-MacViewer-014 implements schema change",
    "Task-030e-MacViewer-014 implements location permission",
    "Task-030e-MacViewer-014 implements user-location display",
    "Task-030e-MacViewer-014 implements Task-031",
]


def fail(message: str) -> None:
    print(f"Task-030e-014 final merge gate verification failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def ensure_required_files() -> None:
    missing = [relative for relative in REQUIRED_FILES if not (ROOT / relative).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_final_gate_tokens() -> None:
    for path, tokens in FINAL_GATE_TOKENS.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"{path} missing token: {token}")


def ensure_oneclick_and_consolidated_verifier_sync() -> None:
    oneclick = read("scripts/run_task030e_macos_multi_package_viewer_oneclick.sh")
    for token in [
        "task-030e-MacViewer-014 — Final Merge Gate",
        "task-030e-MacViewer-013 — Manual QA Gate",
        "verify_task030e_final_merge_gate.py",
        "verify_task030e_manual_qa_gate.py",
        "ONECLICK_CLEANUP_EXIT",
        "ONECLICK_RUN_DIR_REMOVED=\"YES\"",
        "rm -rf \"${RUN_DIR}\"",
    ]:
        if token not in oneclick:
            fail(f"one-click runner missing token: {token}")

    consolidated = read("scripts/verify_task030e_macos_multi_package_viewer.py")
    for token in [
        "after 014",
        "after 013",
        "verify_task030e_final_merge_gate.py",
        "Task-030e-MacViewer-014 Final Merge Gate",
        "TASK030E_FINAL_MERGE_GATE.md",
    ]:
        if token not in consolidated:
            fail(f"consolidated verifier missing token: {token}")


def ensure_docs_whitespace() -> None:
    for relative in DOC_FILES:
        path = ROOT / relative
        data = path.read_bytes()
        if data.endswith(b"\n\n"):
            fail(f"{relative} has trailing blank line at EOF")
        if b"\r\n" in data:
            fail(f"{relative} uses CRLF line endings")
        for line_number, line in enumerate(data.splitlines(), start=1):
            if line.rstrip(b" \t") != line:
                fail(f"{relative}:{line_number} has trailing whitespace")


def ensure_no_forbidden_claims() -> None:
    combined = "\n".join(read(path) for path in DOC_FILES)
    for token in FORBIDDEN_RUNTIME_CLAIMS:
        if token in combined:
            fail(f"forbidden runtime claim found: {token}")
    required_boundaries = [
        "no import",
        "no package merge",
        "no route geometry mutation",
        "no trusted metrics mutation",
        "no package schema change",
        "no Core Data write",
        "no location permission",
        "no user-location display",
        "leave `main` untouched",
    ]
    for token in required_boundaries:
        if token not in combined:
            fail(f"missing final merge boundary token: {token}")


def ensure_final_gate_is_docs_and_tooling_only() -> None:
    final_doc = read("docs/release/TASK030E_FINAL_MERGE_GATE.md")
    for token in [
        "This file is the Task-030e final merge gate checklist",
        "It does not add product behavior",
        "merge-readiness gate",
    ]:
        if token not in final_doc:
            fail(f"final gate doc missing docs/tooling-only token: {token}")


def ensure_localization_not_changed_by_final_gate() -> None:
    for locale in ["en", "zh-Hant", "ja"]:
        path = ROOT / f"Shared/Localization/{locale}.lproj/Localizable.strings"
        if not path.exists():
            fail(f"missing localization file for {locale}")
        if "Task-030e-MacViewer-014" in path.read_text(encoding="utf-8"):
            fail(f"final merge gate should not add user-facing localization keys in {locale}")


def main() -> None:
    ensure_required_files()
    ensure_final_gate_tokens()
    ensure_oneclick_and_consolidated_verifier_sync()
    ensure_docs_whitespace()
    ensure_no_forbidden_claims()
    ensure_final_gate_is_docs_and_tooling_only()
    ensure_localization_not_changed_by_final_gate()
    print("Task-030e-014 final merge gate verification passed.")


if __name__ == "__main__":
    main()
