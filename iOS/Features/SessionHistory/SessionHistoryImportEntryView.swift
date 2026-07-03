// [協作區] iOS/Features/SessionHistory/SessionHistoryImportEntryView.swift
// 用途：在歷史紀錄標題區提供 Task-030d .skatetrack 多檔匯入入口。
// 委派至：useSkateTrackPackageImport 與 SessionImportPreviewView；不直接解析 package。

import SwiftUI
import UniformTypeIdentifiers

struct SessionHistoryImportEntryView: View {
    let isDisabled: Bool
    let onImportCompleted: () -> Void

    @StateObject private var importViewModel = SkateTrackPackageImportViewModel()
    @State private var isFileImporterPresented = false
    @State private var isPreviewPresented = false

    var body: some View {
        Button {
            isFileImporterPresented = true
        } label: {
            Text("history.import.button")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(isDisabled ? SkateTrackSessionStartColors.textTertiary : SkateTrackSessionStartColors.teal)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(isDisabled ? 0.035 : 0.06))
                .clipShape(Capsule())
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .accessibilityIdentifier("history-import-button")
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [Self.skateTrackPackageType],
            allowsMultipleSelection: true,
            onCompletion: handleFileImporterResult
        )
        .sheet(isPresented: $isPreviewPresented, onDismiss: handlePreviewDismiss) {
            SessionImportPreviewView(
                viewModel: importViewModel,
                onClose: { isPreviewPresented = false },
                onImportCompleted: onImportCompleted
            )
        }
    }

    private func handleFileImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            isPreviewPresented = true
            Task { await importViewModel.prepareImport(from: urls) }
        case .failure:
            isPreviewPresented = true
            importViewModel.reset()
        }
    }

    private func handlePreviewDismiss() {
        importViewModel.reset()
    }

    private static var skateTrackPackageType: UTType {
        UTType(filenameExtension: "skatetrack") ?? .data
    }
}
