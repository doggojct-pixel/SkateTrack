// [協作區] macOS/Features/SessionBrowser/MacPackageOpenResultStatusView.swift
// 用途：顯示 Task-030e macOS 多檔開啟的 read-only partial-success / failure 摘要。
// 委派至：MacSessionBrowserView；不得顯示為資料庫匯入、不得寫入、merge、restore、sync 或修改 package。

import SwiftUI

struct MacPackageOpenResultStatusView: View {
    let result: MacPackageOpenResult

    var body: some View {
        if result.hasFailures {
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(titleKey))
                            .font(.headline)
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: result.isPartialSuccess ? "exclamationmark.triangle.fill" : "xmark.octagon.fill")
                        .foregroundStyle(result.isPartialSuccess ? .orange : .red)
                }

                failureRows
            }
            .padding(18)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("mac.accessibility.open_result.label"))
            .accessibilityHint(Text("mac.accessibility.open_result.hint"))
        }
    }

    private var failureRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(result.failures.prefix(3))) { failure in
                VStack(alignment: .leading, spacing: 3) {
                    Text(failure.fileName)
                        .font(.caption.monospaced().weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(LocalizedStringKey(failure.errorMessageKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if result.failures.count > 3 {
                Text(String(format: String(localized: "mac.viewer.open.failure.overflow.format"), result.failures.count - 3))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var titleKey: String {
        result.isPartialSuccess ? "mac.viewer.open.partial_failure.title" : "mac.viewer.open.failed.title"
    }

    private var message: String {
        if result.isPartialSuccess {
            return String(
                format: String(localized: "mac.viewer.open.partial_failure.message.format"),
                result.successfulPackageCount,
                result.requestedFileCount
            )
        }
        return String(
            format: String(localized: "mac.viewer.open.failed.message.format"),
            result.failedFileCount
        )
    }
}
