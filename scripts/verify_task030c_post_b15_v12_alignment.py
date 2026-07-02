#!/usr/bin/env python3
"""Verify Task-030c Post-b15 Localization Completion Plan v1.2 alignment.

This guard exists because future Task-030c hotfixes must be checked against
`Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2` before implementation.
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.exists():
        raise AssertionError(f"Missing required file: {relative_path}")
    return path.read_text()


def require_token(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token not in text:
        raise AssertionError(f"Missing token in {relative_path}: {token}")


def require_tokens(relative_path: str, tokens: list[str]) -> None:
    for token in tokens:
        require_token(relative_path, token)


def require_no_token(relative_path: str, token: str) -> None:
    text = read(relative_path)
    if token in text:
        raise AssertionError(f"Forbidden token in {relative_path}: {token}")


def require_first_line_marker(relative_path: str, marker: str) -> None:
    first_line = read(relative_path).splitlines()[0]
    if not first_line.startswith(marker):
        raise AssertionError(f"{relative_path} must start with {marker}")


def main() -> None:
    required_tokens = {
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b17-C"',
        ],
        "Shared/Models/LocalizationDiagnosticsReviewPack.swift": [
            'taskIdentifier: String = "Task-030c-b17-0"',
            'self.productionRouteMutationApplied = false',
        ],
        "iOS/Features/Debug/DebugToolsPanelView.swift": [
            'Text("debug.build.currentTaskID")',
            'Text("debug.build.badge")',
        ],
        "Shared/Localization/en.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-C";',
            '"debug.build.badge" = "DEBUG";',
        ],
        "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-C";',
            '"debug.build.badge" = "DEBUG";',
        ],
        "Shared/Localization/ja.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-C";',
            '"debug.build.badge" = "DEBUG";',
        ],
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2",
            "Task-030c-b17-0",
            "Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation",
            "Task-030c-b17-B",
            "Task-030c-b17-C",
            "Task-030c-b17-D",
            "Task-030c-b17-B Implementation Note",
            "Task-030c-b17-C Implementation Note",
            "Task-030c-b18-C",
            "non-code product decision checkpoint",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation",
            "Task-030c-b17-C — Anchor Closure Error and Confidence Scoring",
            "Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2",
            "not as b17-A/B/C/D completion",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b17-0 localization diagnostics review pack foundation",
            "Task-030c-b17-C anchor closure error and confidence scoring",
            "verify_task030c_post_b15_v12_alignment.py",
            "verify_task030c_b16c_wifi_rtt_accuracy_source_diagnostics.py",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b17-0 — Localization Diagnostics Review Pack Foundation",
            "Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation",
            "Task-030c-b17-C — Anchor Closure Error and Confidence Scoring",
        ],
        "scripts/verify_task030c_b16c_wifi_rtt_accuracy_source_diagnostics.py": [
            "verify_task030c_b16c_location_accuracy_source_diagnostics.py",
        ],
    }

    for relative_path, tokens in required_tokens.items():
        for token in tokens:
            require_token(relative_path, token)

    require_first_line_marker("Shared/Models/LocalizationDiagnosticsReviewPack.swift", "// [協作區]")
    require_first_line_marker("iOS/Core/SensorEngine/LocalizationDiagnosticsReviewBuilder.swift", "// [自主區]")
    require_first_line_marker("Tests/iOSTests/LocalizationDiagnosticsReviewPackTests.swift", "// [自主區]")

    require_no_token("iOS/Features/Debug/DebugToolsPanelView.swift", 'Text("Task-030c-b17")')
    require_no_token("iOS/Features/Debug/DebugToolsPanelView.swift", 'Text("Task-030c-b17-0")')
    require_no_token("iOS/Features/Debug/DebugToolsPanelView.swift", 'Text("DEBUG")')

    for relative_path in [
        "iOS/Core/SensorEngine/SensorFusionEngine.swift",
        "Shared/Models/MotionSample.swift",
        "Shared/Models/LocalizationDiagnosticsReviewPack.swift",
    ]:
        text = read(relative_path)
        if "estimatedRouteActive: true" in text:
            raise AssertionError(f"{relative_path} must not activate estimatedRouteActive")

    model_text = read("Shared/Models/LocalizationDiagnosticsReviewPack.swift")
    if re.search(r"let\s+productionRouteMutationApplied\s*=\s*true", model_text):
        raise AssertionError("LocalizationDiagnosticsReviewPack must not allow productionRouteMutationApplied true")

    require_first_line_marker("iOS/Core/SensorEngine/LocalTangentPlane.swift", "// [自主區]")
    require_first_line_marker("iOS/Core/SensorEngine/IMUBiasEstimator.swift", "// [自主區]")
    require_first_line_marker("iOS/Core/SensorEngine/GravityCompensatedMotionSample.swift", "// [自主區]")
    require_first_line_marker("Tests/iOSTests/IMULocalFrameBiasFoundationTests.swift", "// [自主區]")
    require_tokens("docs/adr/ADR-INDEX.md", [
        "Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation",
        "Task-030c_Post-b15_Localization_Completion_Plan_EN_v1.2",
    ])
    require_tokens("SkateTrack.xcodeproj/project.pbxproj", [
        "LocalTangentPlane.swift in Sources",
        "IMUBiasEstimator.swift in Sources",
        "GravityCompensatedMotionSample.swift in Sources",
        "IMULocalFrameBiasFoundationTests.swift in Sources",
        "DeadReckoningReplayDiagnostics.swift in Sources",
        "DeadReckoningEngine.swift in Sources",
        "DeadReckoningEngineReplayTests.swift in Sources",
        "DeadReckoningClosureDiagnostics.swift in Sources",
        "DeadReckoningClosureScorer.swift in Sources",
        "DeadReckoningClosureScoringTests.swift in Sources",
    ])
    require_first_line_marker("Shared/Models/DeadReckoningReplayDiagnostics.swift", "// [協作區]")
    require_first_line_marker("iOS/Core/SensorEngine/DeadReckoningEngine.swift", "// [自主區]")
    require_first_line_marker("Tests/iOSTests/DeadReckoningEngineReplayTests.swift", "// [自主區]")
    require_tokens("docs/adr/ADR-INDEX.md", [
        "Task-030c-b17-B — Replay-Only Dead Reckoning Engine v1",
        "estimatedPositionDriftRateMetersPerSecond",
        "Task-030c-b17-C — Anchor Closure Error and Confidence Scoring",
        "DeadReckoningClosureDiagnostics",
    ])
    require_first_line_marker("Shared/Models/DeadReckoningClosureDiagnostics.swift", "// [協作區]")
    require_first_line_marker("iOS/Core/SensorEngine/DeadReckoningClosureScorer.swift", "// [自主區]")
    require_first_line_marker("Tests/iOSTests/DeadReckoningClosureScoringTests.swift", "// [自主區]")
    print("Task-030c Post-b15 v1.2 alignment checks passed.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Task-030c Post-b15 v1.2 alignment check failed: {exc}", file=sys.stderr)
        sys.exit(1)
