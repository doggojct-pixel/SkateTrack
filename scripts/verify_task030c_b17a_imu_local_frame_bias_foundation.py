#!/usr/bin/env python3
"""Verify Task-030c-b17-A IMU local frame and bias foundation safety boundaries."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.exists():
        raise AssertionError(f"Missing required file: {relative_path}")
    return path.read_text(encoding="utf-8")


def require_tokens(relative_path: str, tokens: list[str]) -> None:
    text = read(relative_path)
    missing = [token for token in tokens if token not in text]
    if missing:
        raise AssertionError(f"{relative_path} missing tokens: {missing}")


def require_absent(relative_path: str, tokens: list[str]) -> None:
    text = read(relative_path)
    present = [token for token in tokens if token in text]
    if present:
        raise AssertionError(f"{relative_path} contains forbidden tokens: {present}")


def require_first_line_marker(relative_path: str, expected_marker: str) -> None:
    first_line = read(relative_path).splitlines()[0]
    if not first_line.startswith(expected_marker):
        raise AssertionError(f"{relative_path} first line must start with {expected_marker!r}")


def require_under_line_limit(relative_path: str, max_lines: int = 500) -> None:
    line_count = len(read(relative_path).splitlines())
    if line_count > max_lines:
        raise AssertionError(f"{relative_path} has {line_count} lines, exceeds {max_lines}")


def main() -> int:
    required = {
        "iOS/Core/SensorEngine/LocalTangentPlane.swift": [
            "struct LocalTangentPlane",
            "struct LocalTangentMeters",
            "eastMeters",
            "northMeters",
            "anchorCoordinate",
        ],
        "iOS/Core/SensorEngine/IMUBiasEstimator.swift": [
            "struct IMUBiasEstimatorConfig",
            "struct IMUBiasEstimate",
            "enum IMUBiasEstimator",
            "estimateAccelerometerBias",
            "minimumStationarySampleCount",
            "maximumGyroscopeMagnitudeRadPS",
        ],
        "iOS/Core/SensorEngine/GravityCompensatedMotionSample.swift": [
            "struct GravityCompensatedMotionSample",
            "gravitationalAccelerationMetersPerSecondSquared",
            "accelerometerBiasG",
            "gravityAxisG",
        ],
        "Tests/iOSTests/IMULocalFrameBiasFoundationTests.swift": [
            "testLocalTangentPlaneRoundTripNearTaipeiLatitude",
            "testIMUBiasEstimatorConvergesOnKnownSyntheticBias",
            "testIMUBiasEstimatorRefusesHighMotionSamples",
            "testGravityCompensatedMotionSampleRemovesBiasAndGravity",
        ],
        "Shared/Models/SessionData.swift": [
            'static let currentDebugBuildTaskID = "Task-030c-b17-D"',
        ],
        "Shared/Localization/en.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-D";',
        ],
        "Shared/Localization/zh-Hant.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-D";',
        ],
        "Shared/Localization/ja.lproj/Localizable.strings": [
            '"debug.build.currentTaskID" = "Task-030c-b17-D";',
        ],
        "SkateTrack.xcodeproj/project.pbxproj": [
            "LocalTangentPlane.swift in Sources",
            "IMUBiasEstimator.swift in Sources",
            "GravityCompensatedMotionSample.swift in Sources",
            "IMULocalFrameBiasFoundationTests.swift in Sources",
        ],
        "docs/adr/ADR-INDEX.md": [
            "Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation",
            "LocalTangentPlane",
            "IMUBiasEstimator",
        ],
        "docs/history/DEV_LOG.md": [
            "Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation",
            "LocalTangentPlane",
            "GravityCompensatedMotionSample",
        ],
        "docs/reference/FILE_STRUCTURE.md": [
            "Task-030c-b17-A local tangent coordinate frame and sensor bias foundation",
            "LocalTangentPlane.swift",
            "IMULocalFrameBiasFoundationTests.swift",
        ],
        "docs/release/KNOWN_LIMITATIONS_PRE_ADP.md": [
            "Task-030c-b17-A — Local Tangent Coordinate Frame and Sensor Bias Foundation",
            "No route geometry is generated",
        ],
        "docs/planning/Task-030c-b16_Localization_Foundation_Plan.md": [
            "Task-030c-b17-A Implementation Note",
            "local tangent coordinate frame",
            "sensor bias foundation",
        ],
    }

    for relative_path, tokens in required.items():
        require_tokens(relative_path, tokens)

    for relative_path in [
        "iOS/Core/SensorEngine/LocalTangentPlane.swift",
        "iOS/Core/SensorEngine/IMUBiasEstimator.swift",
        "iOS/Core/SensorEngine/GravityCompensatedMotionSample.swift",
        "Tests/iOSTests/IMULocalFrameBiasFoundationTests.swift",
    ]:
        marker = "// [自主區]"
        require_first_line_marker(relative_path, marker)
        require_under_line_limit(relative_path)
        require_absent(relative_path, [
            "estimatedRouteActive: true",
            "productionRouteMutationApplied = true",
            "rewriteRouteGeometry",
            "trustedDistanceOverride",
            "roadSnapping",
            "mapMatching",
            "CLLocationManager",
        ])

    require_absent("iOS/Features/Debug/DebugToolsPanelView.swift", [
        'Text("Task-030c-b17-A")',
        'Text("DEBUG")',
    ])

    sensor_fusion_text = read("iOS/Core/SensorEngine/SensorFusionEngine.swift")
    if "estimatedRouteActive: false" not in sensor_fusion_text:
        raise AssertionError("SensorFusionEngine must keep estimatedRouteActive false")
    if "estimatedRouteActive: true" in sensor_fusion_text:
        raise AssertionError("SensorFusionEngine must not activate estimated routes")

    model_text = "\n".join([
        read("iOS/Core/SensorEngine/LocalTangentPlane.swift"),
        read("iOS/Core/SensorEngine/IMUBiasEstimator.swift"),
        read("iOS/Core/SensorEngine/GravityCompensatedMotionSample.swift"),
    ])
    if re.search(r"let\s+estimatedRouteActive\s*=\s*true", model_text):
        raise AssertionError("b17-A foundation must not activate estimated routes")

    print("Task-030c-b17-A IMU local frame and bias foundation checks passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"Task-030c-b17-A check failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
