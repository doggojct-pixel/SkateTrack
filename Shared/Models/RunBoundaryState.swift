// [協作區] Shared/Models/RunBoundaryState.swift
// 用途：定義 Snow Mode RunBoundaryDetector 的狀態機狀態。
// 委派至：RunBoundaryDetector、useSnowSession live boundary 與 Snow-Task-004 fixture tests。

import Foundation

enum RunBoundaryState: String, Codable, Sendable, Equatable, CaseIterable {
    case idle
    case active
    case pendingEnd
    case between
}
