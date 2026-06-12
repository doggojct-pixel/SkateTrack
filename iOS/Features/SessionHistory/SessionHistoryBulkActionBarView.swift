// [協作區] SessionHistoryBulkActionBarView.swift
// 用途：提供 Session History 多選刪除工具列，讓大量清理舊紀錄時不污染主畫面邏輯。
// 委派至：SessionHistoryView 管理選取狀態與刪除確認，SessionRepository 執行本機刪除。

import SwiftUI

struct SessionHistoryBulkActionBarView: View {
    let selectedCount: Int
    let visibleCount: Int
    let onSelectAll: () -> Void
    let onClearSelection: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedCountText)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("history.selection.subtitle")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                }

                Spacer()

                deleteButton
            }

            HStack(spacing: 8) {
                compactButton(titleKey: "history.selection.selectAll", systemName: "checkmark.circle") {
                    onSelectAll()
                }
                .disabled(visibleCount == 0 || selectedCount == visibleCount)

                compactButton(titleKey: "history.selection.clear", systemName: "xmark.circle") {
                    onClearSelection()
                }
                .disabled(selectedCount == 0)
            }
        }
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("history-bulk-action-bar")
    }

    private var deleteButton: some View {
        Button(role: .destructive) { onDelete() } label: {
            Label("history.selection.delete", systemImage: "trash.fill")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(SkateTrackSessionStartColors.accent.opacity(selectedCount == 0 ? 0.34 : 0.84))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(selectedCount == 0)
    }

    private func compactButton(titleKey: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(LocalizedStringKey(titleKey), systemImage: systemName)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.055))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var selectedCountText: String {
        let format = NSLocalizedString("history.selection.countFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, selectedCount)
    }
}
