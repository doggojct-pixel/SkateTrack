// [協作區] macOS/Features/SessionBrowser/MacPackageAttentionSummaryView.swift
// 用途：顯示 Task-030e macOS read-only duplicate / attention 摘要，不提供 merge、delete 或 winner selection。
// 委派至：MacSessionBrowserView；不得寫入資料庫、merge、restore、sync 或修改 package payload。

import SwiftUI

struct MacPackageAttentionSummaryView: View {
    let summary: MacPackageAttentionSummary
    let canAcknowledgeDuplicateFiles: Bool
    let acknowledgeDuplicateFilesAction: () -> Void

    var body: some View {
        if summary.hasAttention {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Label {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("mac.viewer.attention.title")
                                .font(.headline)
                            Text(messageText)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }

                    Spacer(minLength: 12)

                    if canAcknowledgeDuplicateFiles {
                        Button(action: acknowledgeDuplicateFilesAction) {
                            Label {
                                Text("mac.viewer.attention.acknowledge_duplicate_files")
                                    .font(.callout.weight(.bold))
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .foregroundStyle(.orange)
                            .background(.orange.opacity(0.24), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.orange.opacity(0.58), lineWidth: 1)
                            )
                            .shadow(color: .orange.opacity(0.18), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("mac-attention-acknowledge-duplicate-files-button")
                    }
                }

                attentionRows

                Text("mac.viewer.attention.readonly")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.orange.opacity(0.22), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("mac.accessibility.attention_summary.label"))
            .accessibilityHint(Text("mac.accessibility.attention_summary.hint"))
        }
    }

    private var messageText: String {
        String(
            format: String(localized: "mac.viewer.attention.message.format"),
            summary.packageCount
        )
    }

    private var attentionRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            attentionRow(
                isVisible: summary.duplicateFilePathCount > 0,
                key: "mac.viewer.attention.summary.duplicate_file.format",
                count: summary.duplicateFilePathCount,
                systemImage: "doc.on.doc"
            )
            attentionRow(
                isVisible: summary.duplicatePackageIdentifierCount > 0,
                key: "mac.viewer.attention.summary.duplicate_package.format",
                count: summary.duplicatePackageIdentifierCount,
                systemImage: "shippingbox"
            )
            attentionRow(
                isVisible: summary.duplicateSessionIdentifierCount > 0,
                key: "mac.viewer.attention.summary.duplicate_session.format",
                count: summary.duplicateSessionIdentifierCount,
                systemImage: "list.bullet.rectangle"
            )
        }
    }

    @ViewBuilder
    private func attentionRow(
        isVisible: Bool,
        key: String,
        count: Int,
        systemImage: String
    ) -> some View {
        if isVisible {
            Label {
                Text(String(format: NSLocalizedString(key, comment: ""), count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.orange)
            }
        }
    }
}
