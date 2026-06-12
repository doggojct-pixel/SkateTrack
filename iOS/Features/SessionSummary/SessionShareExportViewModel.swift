// [協作區 — 邊界適配層] SessionShareExportViewModel.swift
// 用途：管理 Task-023b 分享卡匯出狀態、錯誤與暫存檔清理，避免 View 直接碰系統檔案 API。
// 委派至：SessionShareCardRenderer 產生 PNG；SessionShareExportService 寫入與清理檔案。

import Foundation
import Combine

@MainActor
final class SessionShareExportViewModel: ObservableObject {
    @Published private(set) var isExporting = false
    @Published var activePayload: SessionShareExportPayload?
    @Published var errorKey: String?
    @Published var photoSaveState: SessionSharePhotoSaveState = .idle

    private let renderer: SessionShareCardRenderer
    private let exportService: SessionShareExportService
    private let photoLibrarySaver: SessionSharePhotoLibrarySaver

    init() {
        self.renderer = SessionShareCardRenderer()
        self.exportService = SessionShareExportService()
        self.photoLibrarySaver = SessionSharePhotoLibrarySaver()
    }

    func prepareShare(card: SessionShareCardData) async {
        guard !isExporting else { return }
        isExporting = true
        errorKey = nil

        do {
            let pngData = try renderer.renderPNG(card: card)
            activePayload = try exportService.createExport(card: card, pngData: pngData)
        } catch let error as SessionShareExportError {
            errorKey = error.localizationKey
        } catch {
            errorKey = "summary.share.export.error.generic"
        }

        isExporting = false
    }

    func saveCardToPhotos(card: SessionShareCardData) async {
        guard !isExporting, !photoSaveState.isSaving else { return }
        photoSaveState = .saving

        do {
            let pngData = try renderer.renderPNG(card: card)
            try await photoLibrarySaver.savePNGData(pngData)
            photoSaveState = .saved
        } catch let error as SessionShareExportError {
            photoSaveState = .failed(error.localizationKey)
        } catch let error as SessionSharePhotoLibraryError {
            photoSaveState = .failed(error.localizationKey)
        } catch {
            photoSaveState = .failed("summary.share.photos.error.save")
        }
    }

    func cleanupActivePayload() {
        guard let payload = activePayload else { return }
        exportService.cleanup(payload)
        activePayload = nil
    }

    func resetPhotoSaveState() {
        photoSaveState = .idle
    }

    func dismissError() {
        errorKey = nil
    }
}
