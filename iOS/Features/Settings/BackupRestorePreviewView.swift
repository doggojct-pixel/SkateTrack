// [協作區] BackupRestorePreviewView.swift
// 用途：呈現 Task-026b 非破壞性還原預覽、validation issues 與 conflict policy simulation。
// 委派至：useBackupSync；此 View 不讀寫 Core Data、不覆蓋本機資料、不直接觸碰 provider。

import SwiftUI

struct BackupRestorePreviewView: View {
    @ObservedObject var viewModel: BackupSyncViewModel
    @Binding var isImporterPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle(
                titleKey: "backup.restore.preview.title",
                subtitleKey: "backup.restore.preview.subtitle",
                iconName: "doc.text.magnifyingglass"
            )

            statusRow(titleKey: "backup.restore.preview.status", valueKey: viewModel.restorePreviewSummaryKey)

            if let fileName = viewModel.restorePreviewFileName {
                Text(fileName)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessageKey = viewModel.restorePreviewErrorMessageKey {
                Text(LocalizedStringKey(errorMessageKey))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                isImporterPresented = true
            } label: {
                actionLabel(
                    titleKey: viewModel.isPreparingRestorePreview
                        ? "backup.restore.preview.action_checking"
                        : "backup.restore.preview.action_choose",
                    iconName: "folder.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPreparingRestorePreview)
            .accessibilityIdentifier("backup-restore-preview-import-button")

            if let preview = viewModel.restorePreview {
                previewSummary(preview)
                storePreviewList(preview)
                policySimulationCard
                validationIssues(preview)
            } else {
                deferredPolicyNote
            }
        }
        .padding(18)
        .background(cardBackground)
        .accessibilityIdentifier("backup-restore-preview-card")
    }

    private var deferredPolicyNote: some View {
        Text("backup.restore.preview.empty_note")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func previewSummary(_ preview: BackupRestorePreview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(SkateTrackSessionStartColors.border)
            statusRow(titleKey: "backup.restore.preview.schema", rawValue: "v\(preview.manifest.schemaVersion)")
            statusRow(titleKey: "backup.restore.preview.package_type", valueKey: "backup.package.type.backup")
            statusRow(titleKey: "backup.restore.preview.total_items", rawValue: "\(preview.totalDecodedItems)")
            statusRow(
                titleKey: "backup.restore.preview.created_at",
                rawValue: DateFormatter.localizedString(
                    from: preview.manifest.createdAt,
                    dateStyle: .medium,
                    timeStyle: .short
                )
            )
        }
    }

    private func storePreviewList(_ preview: BackupRestorePreview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("backup.restore.preview.sections")
                .tracking(1.2)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            ForEach(preview.stores) { store in
                HStack(alignment: .firstTextBaseline) {
                    Text(LocalizedStringKey(store.storeKey.localizationKey))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer(minLength: 10)
                    Text("\(store.decodedItemCount) / \(store.expectedItemCount)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.teal)
                    Text(LocalizedStringKey(store.status.localizationKey))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(store.status == .decoded ? SkateTrackSessionStartColors.textSecondary : SkateTrackSessionStartColors.amber)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private var policySimulationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("backup.restore.policy.title")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            policyRow(titleKey: BackupConflictPolicy.localWins.localizationKey, statusKey: "backup.restore.policy.local_wins_preview")
            policyRow(titleKey: BackupConflictPolicy.remoteWins.localizationKey, statusKey: "backup.restore.policy.deferred")
            policyRow(titleKey: BackupConflictPolicy.mergeByDate.localizationKey, statusKey: "backup.restore.policy.deferred")

            Text("backup.restore.policy.note")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(SkateTrackSessionStartColors.navy2.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func validationIssues(_ preview: BackupRestorePreview) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(LocalizedStringKey(preview.hasValidationIssues ? "backup.restore.issues.title" : "backup.restore.issues.none"))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(preview.hasValidationIssues ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal)

            ForEach(preview.validationIssues.prefix(4)) { issue in
                Text(issue.message)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
        statusRow(titleKey: titleKey, rawValue: nil, valueKey: valueKey)
    }

    private func statusRow(titleKey: String, rawValue: String) -> some View {
        statusRow(titleKey: titleKey, rawValue: rawValue, valueKey: nil)
    }

    private func statusRow(titleKey: String, rawValue: String? = nil, valueKey: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)
            Spacer(minLength: 14)
            if let rawValue {
                Text(rawValue)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
            } else if let valueKey {
                Text(LocalizedStringKey(valueKey))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func policyRow(titleKey: String, statusKey: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer(minLength: 10)
            Text(LocalizedStringKey(statusKey))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func actionLabel(titleKey: String, iconName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
            Text(LocalizedStringKey(titleKey))
            if viewModel.isPreparingRestorePreview {
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

#Preview("Backup Restore Preview") {
    ZStack {
        SkateTrackSessionStartColors.navy.ignoresSafeArea()
        ScrollView {
            BackupRestorePreviewView(
                viewModel: BackupSyncViewModel(),
                isImporterPresented: .constant(false)
            )
            .padding(20)
        }
    }
    .preferredColorScheme(.dark)
}
