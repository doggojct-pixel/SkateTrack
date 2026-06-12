// [協作區] SessionShareCardActionView.swift
// 用途：呈現 Task-023b 分享卡快速匯出入口，並開啟本機系統分享表。
// 委派至：SessionShareExportViewModel 管理 PNG / TXT / JSON 匯出與暫存檔清理。

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

            Button {
                Task { await exportViewModel.prepareShare(card: card) }
            } label: {
                HStack(spacing: 8) {
                    if exportViewModel.isExporting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(exportViewModel.isExporting ? "summary.share.export.preparing" : "summary.share.action.button")
                }
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(SkateTrackSessionStartColors.purple.opacity(exportViewModel.isExporting ? 0.48 : 0.72))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(exportViewModel.isExporting)
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

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { exportViewModel.errorKey != nil },
            set: { if !$0 { exportViewModel.dismissError() } }
        )
    }
}
