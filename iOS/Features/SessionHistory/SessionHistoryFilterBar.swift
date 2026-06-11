// [協作區] SessionHistoryFilterBar.swift
// 用途：提供 History 的 All / Skate / Inline / Electric 篩選列。
// 委派至：useSessionHistory.swift 套用實際篩選邏輯。

import SwiftUI

struct SessionHistoryFilterBar: View {
    @Binding var selectedFilter: SessionHistoryFilter
    let accentColor: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SessionHistoryFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(LocalizedStringKey(filter.localizationKey))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(filter == selectedFilter ? .white : SkateTrackSessionStartColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(filterBackground(for: filter))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(filter == selectedFilter ? accentColor.opacity(0.58) : SkateTrackSessionStartColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("history-filter-\(filter.rawValue)")
                }
            }
            .padding(.horizontal, 20)
        }
        .accessibilityIdentifier("history-filter-bar")
    }

    private func filterBackground(for filter: SessionHistoryFilter) -> Color {
        filter == selectedFilter ? accentColor.opacity(0.32) : SkateTrackSessionStartColors.card.opacity(0.78)
    }
}
