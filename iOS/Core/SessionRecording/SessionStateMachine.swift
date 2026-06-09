// [自主區] iOS/Core/SessionRecording/SessionStateMachine.swift
// 用途：定義 Session 記錄狀態與合法轉移規則，防止 View 或 Coordinator 跳過 lifecycle 步驟。
// 委派至：SessionRecordingCoordinator 與 Task-012 之後的 Session UI 流程。

import Foundation

enum SessionRecordingStatus: String, Equatable, Sendable, CaseIterable {
    case idle
    case preparing
    case recording
    case paused
    case ending
    case saving
    case failed

    var localizationKey: String {
        switch self {
        case .idle:
            return "session.status.idle"
        case .preparing:
            return "session.status.preparing"
        case .recording:
            return "session.status.recording"
        case .paused:
            return "session.status.paused"
        case .ending, .saving:
            return "session.status.saving"
        case .failed:
            return "session.error.sensorUnavailable"
        }
    }
}

enum SessionStateTransitionError: Error, Sendable, Equatable {
    case invalidTransition(from: SessionRecordingStatus, to: SessionRecordingStatus)
}

struct SessionStateMachine: Equatable, Sendable {
    private(set) var status: SessionRecordingStatus = .idle

    mutating func transition(to newStatus: SessionRecordingStatus) throws {
        guard canTransition(from: status, to: newStatus) else {
            throw SessionStateTransitionError.invalidTransition(from: status, to: newStatus)
        }
        status = newStatus
    }

    mutating func resetToIdle() {
        status = .idle
    }

    func canTransition(from current: SessionRecordingStatus, to next: SessionRecordingStatus) -> Bool {
        if current == next {
            return true
        }

        switch current {
        case .idle:
            return next == .preparing
        case .preparing:
            return next == .recording || next == .failed || next == .idle
        case .recording:
            return next == .paused || next == .ending || next == .idle
        case .paused:
            return next == .recording || next == .ending || next == .idle
        case .ending:
            return next == .saving || next == .idle
        case .saving:
            return next == .idle || next == .failed
        case .failed:
            return next == .idle
        }
    }
}
