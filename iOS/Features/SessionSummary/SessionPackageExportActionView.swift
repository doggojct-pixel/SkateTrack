// [協作區] SessionPackageExportActionView.swift
// 用途：在 Session Summary 提供 Task-027a 單筆 .skatetrack 可攜式檔案匯出入口。
// 委派至：SkateTrackPackageExportViewModel 建立暫存檔；SessionShareSheetView 開啟 iOS 系統分享表。

import SwiftUI

struct SessionPackageExportActionView: View {
    let content: SessionSummaryContent
    @StateObject private var exportViewModel = SkateTrackPackageExportViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Button {
                Task { await exportViewModel.preparePackage(content: content) }
            } label: {
                actionLabel
            }
            .buttonStyle(.plain)
            .disabled(exportViewModel.isExporting)

            if let statusKey = exportViewModel.statusKey {
                Text(LocalizedStringKey(statusKey))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("session-package-export-status")
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
        .alert("skatetrack.package.error.title", isPresented: errorAlertBinding) {
            Button("summary.share.export.error.dismiss", role: .cancel) {
                exportViewModel.dismissError()
            }
        } message: {
            Text(LocalizedStringKey(exportViewModel.errorKey ?? "skatetrack.package.error.generic"))
        }
        .accessibilityIdentifier("session-package-export-action-view")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .frame(width: 34, height: 34)
                .background(SkateTrackSessionStartColors.teal.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("skatetrack.package.export.title")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("skatetrack.package.export.subtitle")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var actionLabel: some View {
        HStack(spacing: 8) {
            if exportViewModel.isExporting {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            } else {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 12, weight: .black))
            }

            Text(LocalizedStringKey(exportViewModel.isExporting ? "skatetrack.package.export.preparing" : "skatetrack.package.export.button"))
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(SkateTrackSessionStartColors.teal.opacity(exportViewModel.isExporting ? 0.48 : 0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { exportViewModel.errorKey != nil },
            set: { if !$0 { exportViewModel.dismissError() } }
        )
    }
}
