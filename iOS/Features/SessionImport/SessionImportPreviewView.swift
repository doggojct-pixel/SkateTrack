// [協作區] iOS/Features/SessionImport/SessionImportPreviewView.swift
// 用途：呈現 Task-030d iOS 多檔 .skatetrack 匯入預覽、局部成功與安全確認。
// 委派至：SkateTrackPackageImportViewModel；不直接讀檔、不變更路線與可信指標。

import SwiftUI

struct SessionImportPreviewView: View {
    @ObservedObject var viewModel: SkateTrackPackageImportViewModel
    let onClose: () -> Void
    let onImportCompleted: () -> Void

    @State private var isCommitConfirmationPresented = false

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    grabber
                    header
                    summaryStrip
                    candidateContent
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "import.confirm.title",
            isPresented: $isCommitConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("import.action.importSelected") {
                Task {
                    await viewModel.commitSelectedCandidates()
                    onImportCompleted()
                }
            }
            Button("general.cancel", role: .cancel) {}
        } message: {
            Text(confirmMessage)
        }
        .alert("import.error.title", isPresented: errorBinding) {
            Button("general.ok", role: .cancel) { viewModel.errorKey = nil }
        } message: {
            if let errorKey = viewModel.errorKey {
                Text(LocalizedStringKey(errorKey))
            }
        }
        .accessibilityIdentifier("session-import-preview-view")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3,
                    SkateTrackSessionStartColors.navy2,
                    SkateTrackSessionStartColors.navy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [SkateTrackSessionStartColors.teal.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )
        }
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.white.opacity(0.10))
            .frame(width: 54, height: 6)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            .accessibilityHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("import.title")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("import.subtitle")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button("general.close") { onClose() }
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("session-import-close-button")
            }
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            summaryTile(value: "\(viewModel.batchSummary.totalCount)", labelKey: "import.preview.totalFiles", color: .white)
            summaryTile(value: "\(viewModel.batchSummary.readyCount)", labelKey: "import.preview.readyFiles", color: SkateTrackSessionStartColors.teal)
            summaryTile(value: "\(viewModel.batchSummary.blockedCount)", labelKey: "import.preview.attentionFiles", color: SkateTrackSessionStartColors.amber)
        }
        .accessibilityIdentifier("session-import-summary-strip")
    }

    private func summaryTile(value: String, labelKey: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
    }

    @ViewBuilder
    private var candidateContent: some View {
        if viewModel.isPreparing {
            loadingCard
        } else if viewModel.candidates.isEmpty {
            emptyCard
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("import.preview.title")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                ForEach(viewModel.candidates) { candidate in
                    SessionImportCandidateRowView(
                        candidate: candidate,
                        isSelected: viewModel.selectedCandidateIDs.contains(candidate.id),
                        commitResult: viewModel.commitResults.first { $0.candidateID == candidate.id },
                        onToggle: { viewModel.toggleSelection(for: candidate) }
                    )
                }
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView().tint(SkateTrackSessionStartColors.teal)
            Text("import.preview.validating")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("import.empty.title")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("import.empty.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if viewModel.commitResults.isEmpty {
                Button {
                    isCommitConfirmationPresented = true
                } label: {
                    footerButtonLabel(
                        titleKey: "import.action.importSelected",
                        systemImage: "square.and.arrow.down"
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedImportableCount == 0 || viewModel.isPreparing || viewModel.isCommitting)
                .opacity(viewModel.selectedImportableCount == 0 ? 0.45 : 1.0)
                .accessibilityIdentifier("session-import-commit-button")

                Button("import.action.cancel") { onClose() }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .buttonStyle(.plain)
            } else {
                resultSummary
                Button { onClose() } label: {
                    footerButtonLabel(titleKey: "import.action.done", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("session-import-done-button")
            }
        }
    }

    private func footerButtonLabel(titleKey: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(LocalizedStringKey(titleKey))
        }
        .font(.system(size: 17, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(SkateTrackSessionStartColors.teal)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var resultSummary: some View {
        let summary = viewModel.commitSummary
        return Text(resultSummaryText(summary))
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(SkateTrackSessionStartColors.card.opacity(0.70))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var confirmMessage: String {
        let format = NSLocalizedString("import.confirm.messageFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, viewModel.selectedImportableCount)
    }

    private func resultSummaryText(_ summary: SkateTrackImportCommitSummary) -> String {
        let format = NSLocalizedString("import.result.summaryFormat", comment: "")
        return String(
            format: format,
            locale: .autoupdatingCurrent,
            summary.importedPackageCount,
            summary.importedSessionCount,
            summary.skippedCount,
            summary.failedCount
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorKey != nil }, set: { if !$0 { viewModel.errorKey = nil } })
    }
}
