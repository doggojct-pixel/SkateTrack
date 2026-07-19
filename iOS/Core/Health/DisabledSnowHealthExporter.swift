// [協作區] iOS/Core/Health/DisabledSnowHealthExporter.swift
// 用途：在尚未啟用正式健康資料 entitlement 前，提供安全的 no-op Snow health exporter。
// 委派至：Snow-Task-008b Health provider boundary。

import Foundation

struct DisabledSnowHealthExporter: SnowHealthExporting {
    let reason: String

    init(reason: String = "Snow Health export is unavailable before Apple Developer Program entitlement wiring.") {
        self.reason = reason
    }

    func exportSnowSession(_ request: SnowHealthExportRequest) async throws -> SnowHealthExportResult {
        SnowHealthExportResult(
            status: .unavailable,
            sampleCount: 0,
            message: reason
        )
    }
}
