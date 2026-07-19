// [協作區] iOS/Core/Health/SnowHealthExporting.swift
// 用途：定義 Snow session 匯出到健康資料平台的可替換 provider boundary。
// 委派至：Snow-Task-008b Health provider boundary；正式 HealthKit writer 需待 Apple Developer Program / entitlement 後替換。

import Foundation

enum SnowHealthExportStatus: String, Codable, Sendable, Equatable {
    case unavailable
    case prepared
    case exported
    case skipped
}

struct SnowHealthExportRequest: Sendable, Equatable {
    let sessionID: UUID
    let state: SnowSessionState
    let startedAt: Date?
    let endedAt: Date?
    let metadata: [String: String]

    init(
        sessionID: UUID,
        state: SnowSessionState,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        metadata: [String: String] = [:]
    ) {
        self.sessionID = sessionID
        self.state = state
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.metadata = metadata
    }
}

struct SnowHealthExportResult: Sendable, Equatable {
    let status: SnowHealthExportStatus
    let sampleCount: Int
    let message: String?

    init(
        status: SnowHealthExportStatus,
        sampleCount: Int = 0,
        message: String? = nil
    ) {
        self.status = status
        self.sampleCount = max(0, sampleCount)
        self.message = message
    }
}

enum SnowHealthExportError: Error, Sendable, Equatable {
    case unavailable(String)
}

protocol SnowHealthExporting: Sendable {
    func exportSnowSession(_ request: SnowHealthExportRequest) async throws -> SnowHealthExportResult
}
