// [協作區] BackupSyncSettingsView.swift
// 用途：呈現 Task-026a 本機備份匯出與 Google Drive disabled 狀態。
// 委派至：useBackupSync；此 View 不直接碰 provider、Core Data、OAuth、Drive scope 或 Google SDK。

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct BackupSyncSettingsView: View {
    @StateObject private var viewModel: BackupSyncViewModel
    @State private var shareItem: BackupSyncShareItem?
    @State private var isRestoreImporterPresented = false

    @MainActor
    init(viewModel: BackupSyncViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? useBackupSync())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            localBackupCard
            BackupRestorePreviewView(
                viewModel: viewModel,
                isImporterPresented: $isRestoreImporterPresented
            )
            driveStatusCard
            restoreDeferredCard
        }
        .onAppear { viewModel.refresh() }
        .sheet(item: $shareItem) { item in
            BackupSyncShareSheetView(activityItems: [item.url])
                .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $isRestoreImporterPresented,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else {
                    viewModel.handleRestoreImporterFailure()
                    return
                }
                viewModel.previewRestorePackage(from: url)
            case .failure:
                viewModel.handleRestoreImporterFailure()
            }
        }
        .accessibilityIdentifier("backup-sync-settings-view")
    }

    private var localBackupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle(
                titleKey: "backup.local.title",
                subtitleKey: "backup.local.subtitle",
                iconName: "externaldrive.badge.plus"
            )

            statusRow(titleKey: "backup.local.provider", valueKey: "backup.provider.local_package")
            statusRow(titleKey: "backup.local.status", valueKey: viewModel.statusMessageKey)
            statusRow(titleKey: "backup.local.last_export", valueKey: viewModel.latestExportSummaryKey)

            if let fileName = viewModel.latestExportFileName {
                Text(fileName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessageKey = viewModel.errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.createLocalBackup()
                } label: {
                    actionLabel(
                        titleKey: viewModel.isPreparingBackup ? "backup.local.action_preparing" : "backup.local.action_create",
                        iconName: "archivebox"
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isPreparingBackup)
                .accessibilityIdentifier("backup-create-local-button")

                if let export = viewModel.latestExport {
                    Button {
                        shareItem = BackupSyncShareItem(url: export.fileURL)
                    } label: {
                        actionLabel(titleKey: "backup.local.action_share", iconName: "square.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isPreparingBackup)
                    .accessibilityIdentifier("backup-share-local-button")
                }
            }
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("backup-local-card")
    }

    private var driveStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle(
                titleKey: "backup.drive.title",
                subtitleKey: "backup.drive.subtitle",
                iconName: "cloud.slash"
            )

            statusRow(titleKey: "backup.drive.provider", valueKey: "backup.provider.google_drive")
            statusRow(titleKey: "backup.drive.subscription", valueKey: viewModel.cloudAccessMessageKey)
            statusRow(titleKey: "backup.drive.status", valueKey: viewModel.driveAvailabilityMessageKey)

            Text("backup.drive.deferred_note")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("backup-drive-disabled-card")
    }

    private var restoreDeferredCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(
                titleKey: "backup.restore.deferred.title",
                subtitleKey: "backup.restore.deferred.subtitle",
                iconName: "arrow.uturn.backward.circle"
            )

            Text("backup.restore.deferred.note")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("backup-restore-deferred-card")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(SkateTrackSessionStartColors.card.opacity(0.84))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(SkateTrackSessionStartColors.border, lineWidth: 1)
            )
    }

    private func cardTitle(titleKey: String, subtitleKey: String, iconName: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .frame(width: 34, height: 34)
                .background(SkateTrackSessionStartColors.teal.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(subtitleKey))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statusRow(titleKey: String, valueKey: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Spacer(minLength: 14)
            Text(LocalizedStringKey(valueKey))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private func actionLabel(titleKey: String, iconName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
            Text(LocalizedStringKey(titleKey))
            if viewModel.isPreparingBackup {
                ProgressView()
                    .tint(SkateTrackSessionStartColors.teal)
            }
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundStyle(SkateTrackSessionStartColors.teal)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(SkateTrackSessionStartColors.teal.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SkateTrackSessionStartColors.teal.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct BackupSyncShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct BackupSyncShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("Backup Sync Settings") {
    ZStack {
        SkateTrackSessionStartColors.navy.ignoresSafeArea()
        ScrollView {
            BackupSyncSettingsView()
                .padding(20)
        }
    }
    .preferredColorScheme(.dark)
}
