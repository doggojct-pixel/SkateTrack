// [協作區 — 邊界適配層] useSkateTrackPackageExport.swift
// 用途：向 SwiftUI Views 暴露 .skatetrack 單筆 Session 匯出狀態，不讓 View 直接操作 writer / temp paths。
// 委派至：SkateTrackPackageExportProvider 建立 package；SessionShareSheetView 開啟系統分享表。

import Combine
import Foundation

@MainActor
final class SkateTrackPackageExportViewModel: ObservableObject {
    @Published private(set) var isExporting = false
    @Published var activePayload: SkateTrackPackageExportResult?
    @Published private(set) var statusKey: String?
    @Published private(set) var errorKey: String?

    private let provider: SkateTrackPackageExportProvider

    init(provider: SkateTrackPackageExportProvider = SkateTrackPackageExportProvider()) {
        self.provider = provider
    }

    func preparePackage(content: SessionSummaryContent) async {
        guard !isExporting else { return }
        isExporting = true
        statusKey = "skatetrack.package.export.preparing"
        errorKey = nil

        do {
            let payload = try await Task.detached(priority: .userInitiated) {
                try SkateTrackPackageExportProvider().createExport(content: content)
            }.value
            activePayload = payload
            statusKey = "skatetrack.package.export.ready"
        } catch let error as SkateTrackPackageError {
            errorKey = error.localizationKey
            statusKey = nil
        } catch {
            errorKey = "skatetrack.package.error.generic"
            statusKey = nil
        }

        isExporting = false
    }

    func cleanupActivePayload() {
        if let activePayload {
            provider.cleanup(activePayload)
        }
        activePayload = nil
        if statusKey == "skatetrack.package.export.ready" {
            statusKey = nil
        }
    }

    func dismissError() {
        errorKey = nil
    }
}

@MainActor
func useSkateTrackPackageExport(
    provider: SkateTrackPackageExportProvider = SkateTrackPackageExportProvider()
) -> SkateTrackPackageExportViewModel {
    SkateTrackPackageExportViewModel(provider: provider)
}
