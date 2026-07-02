#!/usr/bin/env python3
"""Verify Task-030c-b15-B-3 simulator save pipeline and debug recording pipeline stay wired."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

def read(rel: str) -> str:
    p = ROOT / rel
    if not p.exists():
        raise AssertionError(f"Missing file: {rel}")
    return p.read_text(encoding="utf-8")

def require(rel: str, token: str) -> None:
    text = read(rel)
    if token not in text:
        raise AssertionError(f"Missing token in {rel}: {token}")

def forbid(rel: str, token: str) -> None:
    text = read(rel)
    if token in text:
        raise AssertionError(f"Forbidden token in {rel}: {token}")

def main() -> None:
    required = [
        ("Shared/Models/SessionData.swift", 'static let currentDebugBuildTaskID = "Task-030c-b17-A"'),
        ("iOS/Features/Debug/DebugToolsPanelView.swift", 'Text("debug.build.currentTaskID")'),
        ("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift", "Task-030c-b15-B-3: DEBUG mock recording must run on the main queue"),
        ("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift", "DispatchSource.makeTimerSource(queue: .main)"),
        ("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift", "deadline: .now() + .milliseconds(150)"),
        ("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift", "Task-030c-b15-B-3: append every DEBUG simulated sample to the mock buffer"),
        ("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift", "dataSource == .mock || sample.sampleSource == .debugSimulated"),
        ("iOS/Core/SessionRecording/SessionRecordingCoordinator.swift", "debugSimulatorPersistableSamples"),
        ("Shared/Persistence/SessionRepository.swift", "static let skateTrackSessionDidSave"),
        ("Shared/Persistence/SessionRepository.swift", "NotificationCenter.default.post(name: .skateTrackSessionDidSave"),
        ("Shared/Persistence/SessionRepository.swift", "avoid leaving DEBUG simulator motion sample files orphaned"),
        ("Shared/Persistence/SessionRepository.swift", "fetchSessionObject(id: session.id"),
        ("Shared/Persistence/SessionRepository.swift", "objects.compactMap"),
        ("Shared/Persistence/SessionEntityMapper.swift", "safeEncodedDebugRecordingDiagnostics"),
        ("Shared/Persistence/SessionEntityMapper.swift", "nonConformingFloatEncodingStrategy"),
        ("Shared/Persistence/MotionSampleFileStore.swift", "nonConformingFloatEncodingStrategy"),
        ("iOS/Features/SessionHistory/SessionHistoryView.swift", "NotificationCenter.default.publisher(for: .skateTrackSessionDidSave)"),
        ("iOS/Features/SessionHistory/SessionHistoryView.swift", "await history.reload()"),
        ("iOS/Features/SessionRecording/LiveHUDView.swift", "Task-030c-b15-B-3: DEBUG simulated speed should drive the trace directly"),
        ("iOS/Features/SessionRecording/LiveHUDView.swift", "sessionRecording.state.latestMotionSample?.sampleSource == .debugSimulated"),
        ("Shared/Localization/zh-Hant.lproj/Localizable.strings", '"summary.metric.elevationGain" = "總爬升量";'),
        ("Shared/Localization/en.lproj/Localizable.strings", '"summary.metric.elevationGain" = "Total elevation gain";'),
        ("Shared/Localization/ja.lproj/Localizable.strings", '"summary.metric.elevationGain" = "総獲得標高";'),
        ("iOS/Core/SensorEngine/SensorFusionEngine.swift", "estimatedRouteActive: false"),
        ("docs/adr/ADR-INDEX.md", "Task-030c-b15-B-3"),
        ("docs/history/DEV_LOG.md", "Task-030c-b15-B-3"),
        ("docs/release/KNOWN_LIMITATIONS_PRE_ADP.md", "Task-030c-b15-B-3"),
        ("docs/reference/FILE_STRUCTURE.md", "Task-030c-b15-B-3"),
    ]
    for rel, token in required:
        require(rel, token)
    forbid("iOS/Core/SessionRecording/SessionRecordingCoordinator+DebugMock.swift", "DispatchSource.makeTimerSource(queue: DispatchQueue.global")
    print("Task-030c-b15-B-3 simulator save pipeline guard checks passed.")

if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"Task-030c-b15-B-3 simulator save pipeline guard check failed: {exc}", file=sys.stderr)
        sys.exit(1)
