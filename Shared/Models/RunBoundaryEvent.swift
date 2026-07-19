// [協作區] Shared/Models/RunBoundaryEvent.swift
// 用途：描述 RunBoundaryDetector 狀態機輸出的 run 邊界事件。
// 委派至：RunBoundaryDetector、future coordinator persistence boundary 與 Snow-Task-004 tests。

import Foundation

enum RunBoundaryEndReason: String, Codable, Sendable, Equatable {
    case pendingEndTimeout
    case highConfidenceTransport
    case manualEnd
}

enum RunBoundaryEvent: Sendable, Equatable {
    case stateChanged(from: RunBoundaryState, to: RunBoundaryState)
    case runStarted(SnowRun)
    case runEnded(run: SnowRun, segments: [SnowSegment], reason: RunBoundaryEndReason)
}
