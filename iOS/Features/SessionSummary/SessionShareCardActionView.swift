// [協作區] SessionShareCardActionView.swift
// 用途：呈現 Task-023b 快速匯出與 Task-023c 儲存到照片入口。
// 委派至：SessionShareExportViewModel 管理分享表、Photos 儲存與暫存檔清理。

import SwiftUI

struct SessionShareCardActionView: View {
    let card: SessionShareCardData
    @StateObject private var exportViewModel = SessionShareExportViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)
                    .frame(width: 34, height: 34)
                    .background(SkateTrackSessionStartColors.purple.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("summary.share.action.title")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("summary.share.action.subtitle")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 8) {
                Button {
                    Task { await exportViewModel.prepareShare(card: card) }
                } label: {
                    actionLabel(
                        title: exportViewModel.isExporting ? "summary.share.export.preparing" : "summary.share.action.button",
                        systemImage: "square.and.arrow.up",
                        isLoading: exportViewModel.isExporting,
                        tint: SkateTrackSessionStartColors.purple
                    )
                }
                .buttonStyle(.plain)
                .disabled(exportViewModel.isExporting || exportViewModel.photoSaveState.isSaving)

                Button {
                    Task { await exportViewModel.saveCardToPhotos(card: card) }
                } label: {
                    actionLabel(
                        title: exportViewModel.photoSaveState.isSaving ?
                            "summary.share.photos.saving" : "summary.share.photos.button",
                        systemImage: "photo.badge.plus",
                        isLoading: exportViewModel.photoSaveState.isSaving,
                        tint: SkateTrackSessionStartColors.accent
                    )
                }
                .buttonStyle(.plain)
                .disabled(exportViewModel.isExporting || exportViewModel.photoSaveState.isSaving)
            }

            if let messageKey = exportViewModel.photoSaveState.messageKey {
                Text(LocalizedStringKey(messageKey))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(photoSaveMessageColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("session-share-photo-save-status")
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .sheet(item: $exportViewModel.activePayload, onDismiss: {
            exportViewModel.cleanupActivePayload()
        }) { payload in
            SessionShareSheetView(itemURLs: payload.itemURLs) {
                exportViewModel.cleanupActivePayload()
            }
        }
        .alert("summary.share.export.error.title", isPresented: errorAlertBinding) {
            Button("summary.share.export.error.dismiss", role: .cancel) {
                exportViewModel.dismissError()
            }
        } message: {
            Text(LocalizedStringKey(exportViewModel.errorKey ?? "summary.share.export.error.generic"))
        }
        .accessibilityIdentifier("session-share-card-action-view")
    }

    private func actionLabel(
        title: LocalizedStringKey,
        systemImage: String,
        isLoading: Bool,
        tint: Color
    ) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .black))
            }
            Text(title)
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(isLoading ? 0.48 : 0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var photoSaveMessageColor: Color {
        switch exportViewModel.photoSaveState {
        case .saved:
            return SkateTrackSessionStartColors.accent
        case .failed:
            return .orange
        case .idle, .saving:
            return SkateTrackSessionStartColors.textSecondary
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { exportViewModel.errorKey != nil },
            set: { if !$0 { exportViewModel.dismissError() } }
        )
    }
}
