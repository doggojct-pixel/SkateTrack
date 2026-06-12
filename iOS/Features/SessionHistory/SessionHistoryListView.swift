// [協作區] SessionHistoryListView.swift
// 用途：依月份分組顯示 Session History 清單，並支援多選刪除模式。
// 委派至：SessionHistoryCardView 呈現單筆卡片，SessionHistoryView 處理點擊、選取與刪除確認。

import SwiftUI

struct SessionHistoryListView: View {
    let sections: [SessionHistoryMonthSection]
    let isSelectionMode: Bool
    let selectedSessionIDs: Set<UUID>
    let onEntryTap: (SessionHistoryEntry) -> Void
    let onToggleSelection: (SessionHistoryEntry) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.title)
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 2)

                    VStack(spacing: 10) {
                        ForEach(section.entries) { entry in
                            SessionHistoryCardView(
                                entry: entry,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedSessionIDs.contains(entry.session.id)
                            ) {
                                onEntryTap(entry)
                            } onToggleSelection: {
                                onToggleSelection(entry)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("history-session-list")
    }
}
