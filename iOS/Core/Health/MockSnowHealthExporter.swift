// [協作區] iOS/Core/Health/MockSnowHealthExporter.swift
// 用途：DEBUG-only Snow health export mock，用於本機測試 provider wiring，不寫入任何系統健康資料。
// 委派至：Snow-Task-008b Health provider boundary。

import Foundation

#if DEBUG
struct MockSnowHealthExporter: SnowHealthExporting {
    let status: SnowHealthExportStatus
    let sampleCount: Int
    let message: String?

    init(
        status: SnowHealthExportStatus = .prepared,
        sampleCount: Int = 1,
        message: String? = "DEBUG mock Snow Health export prepared."
    ) {
        self.status = status
        self.sampleCount = max(0, sampleCount)
        self.message = message
    }

    func exportSnowSession(_ request: SnowHealthExportRequest) async throws -> SnowHealthExportResult {
        SnowHealthExportResult(
            status: status,
            sampleCount: sampleCount,
            message: message
        )
    }
}
#endif
