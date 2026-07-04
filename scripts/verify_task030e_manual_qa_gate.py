#!/usr/bin/env python3
"""Verify Task-030e-MacViewer-013 manual QA gate documentation and tooling."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "docs/release/TASK030E_MANUAL_QA_GATE.md",
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md",
    "docs/release/RELEASE_READINESS_PRE_ADP.md",
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md",
    "docs/DOCUMENTATION_INDEX.md",
    "docs/process/DEVELOPMENT_RULES.md",
    "docs/adr/ADR-INDEX.md",
    "docs/history/DEV_LOG.md",
    "docs/reference/FILE_STRUCTURE.md",
    "scripts/verify_task030e_manual_qa_gate.py",
    "scripts/verify_task030e_documentation_sync.py",
    "scripts/verify_task030e_macos_multi_package_viewer.py",
    "scripts/run_task030e_macos_multi_package_viewer_oneclick.sh",
]

DOC_FILES = [
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

MANUAL_GATE_TOKENS: dict[str, list[str]] = {
    "docs/release/TASK030E_MANUAL_QA_GATE.md": [
        "Task-030e-MacViewer-013 manual QA gate checklist",
        "Required automated preconditions",
        "Manual QA package set",
        "Manual QA checklist",
        "Required uploaded evidence",
        "operator explicitly confirms manual QA success",
        "ONECLICK_RUN_DIR_REMOVED=YES",
        "no import",
        "no route geometry mutation",
        "no Core Data write",
    ],
    "docs/release/MANUAL_QA_MATRIX_PRE_ADP.md": [
        "Task-030e-MacViewer-013 manual QA gate",
        "docs/release/TASK030E_MANUAL_QA_GATE.md",
        "operator signoff required",
        "task030e_013_oneclick",
        "read-only no-import boundary",
    ],
    "docs/release/RELEASE_READINESS_PRE_ADP.md": [
        "Task-030e-MacViewer-013 manual QA closure additionally requires",
        "TASK030E_MANUAL_QA_GATE.md",
        "operator confirmation that manual QA passed",
        "task030e_013_oneclick",
        "no UI / schema / route mutation",
    ],
    "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
        "Task-030e-MacViewer-013 — Manual QA Gate and Final-Merge Preconditions",
        "Manual QA gate checklist and verifier only",
        "operator signoff required",
        "no import / merge / route mutation",
    ],
    "docs/DOCUMENTATION_INDEX.md": [
        "Task-030e manual QA signoff checklist",
        "docs/release/TASK030E_MANUAL_QA_GATE.md",
        "Manual QA Gate routing",
        "read-only no-import manual QA boundary",
    ],
    "docs/process/DEVELOPMENT_RULES.md": [
        "docs/release/TASK030E_MANUAL_QA_GATE.md",
        "explicit operator signoff before commit/push",
        "verify_task030e_manual_qa_gate.py",
        "no UI / schema / route mutation",
    ],
    "docs/adr/ADR-INDEX.md": [
        "Task-030e macOS multi-package viewer manual QA gate",
        "operator-run package scenarios",
        "task030e_013_oneclick",
        "no route / metric / schema mutation",
    ],
    "docs/history/DEV_LOG.md": [
        "Task-030e-MacViewer-013 Manual QA Gate",
        "TASK030E_MANUAL_QA_GATE.md",
        "verify_task030e_manual_qa_gate.py",
        "operator signoff required",
    ],
    "docs/reference/FILE_STRUCTURE.md": [
        "Task-030e-MacViewer-013 Manual QA Gate Addendum",
        "TASK030E_MANUAL_QA_GATE.md",
        "verify_task030e_manual_qa_gate.py",
        "manual QA failure blocks commit / push",
    ],
}

FORBIDDEN_RUNTIME_CLAIMS = [
    "Task-030e-MacViewer-013 implements package import",
    "Task-030e-MacViewer-013 implements package merge",
    "Task-030e-MacViewer-013 implements route correction",
    "Task-030e-MacViewer-013 implements Core Data write",
    "Task-030e-MacViewer-013 implements schema change",
    "Task-030e-MacViewer-013 implements location permission",
    "Task-030e-MacViewer-013 implements user-location display",
]


def fail(message: str) -> None:
    print(f"Task-030e-013 manual QA gate verification failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def ensure_required_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def ensure_manual_gate_tokens() -> None:
    for path, tokens in MANUAL_GATE_TOKENS.items():
        text = read(path)
        for token in tokens:
            if token not in text:
                fail(f"{path} missing token: {token}")


def ensure_oneclick_and_consolidated_verifier_sync() -> None:
    oneclick = read("scripts/run_task030e_macos_multi_package_viewer_oneclick.sh")
    for token in [
        "task-030e-MacViewer-013 — Manual QA Gate",
        "verify_task030e_manual_qa_gate.py",
        "ONECLICK_CLEANUP_EXIT",
        "ONECLICK_RUN_DIR_REMOVED=\"YES\"",
        "rm -rf \"${RUN_DIR}\"",
    ]:
        if token not in oneclick:
            fail(f"one-click runner missing token: {token}")

    consolidated = read("scripts/verify_task030e_macos_multi_package_viewer.py")
    for token in [
        "after 013",
        "verify_task030e_manual_qa_gate.py",
        "Task-030e-MacViewer-013 Manual QA Gate",
        "TASK030E_MANUAL_QA_GATE.md",
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
        "no merge",
        "no route geometry mutation",
        "no trusted metrics mutation",
        "no package schema change",
        "no Core Data write",
        "no location permission",
        "no user-location",
    ]
    for token in required_boundaries:
        if token not in combined:
            fail(f"missing manual QA boundary token: {token}")


def ensure_no_product_files_changed_by_manual_gate() -> None:
    # This verifier is intentionally source-token based: Task-030e-013 is docs/tooling only.
    manual_doc = read("docs/release/TASK030E_MANUAL_QA_GATE.md")
    if "This file is the Task-030e manual QA signoff checklist" not in manual_doc:
        fail("manual QA gate document must identify itself as a checklist, not a feature implementation")
    if "It does not add product behavior" not in manual_doc:
        fail("manual QA gate document must explicitly avoid product-behavior claims")


def main() -> None:
    ensure_required_files()
    ensure_manual_gate_tokens()
    ensure_oneclick_and_consolidated_verifier_sync()
    ensure_docs_whitespace()
    ensure_no_forbidden_claims()
    ensure_no_product_files_changed_by_manual_gate()
    print("Task-030e-013 manual QA gate verification passed.")


if __name__ == "__main__":
    main()
