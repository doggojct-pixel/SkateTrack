// [協作區] SessionSummaryMetricsGridView.swift
// 用途：呈現 Task-018a Session Summary 的核心指標網格。
// 委派至：SessionSummaryView 提供格式化後的核心數值。

import SwiftUI

struct SessionSummaryMetricItem: Identifiable {
    let id: String
    let value: String
    let labelKey: String
    let accent: Color
}

struct SessionSummaryMetricsGridView: View {
    let items: [SessionSummaryMetricItem]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(items.chunked(into: 2).enumerated()), id: \.offset) { _, rowItems in
                HStack(spacing: 10) {
                    ForEach(rowItems) { item in
                        metricTile(item)
                    }

                    if rowItems.count == 1 {
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .accessibilityIdentifier("session-summary-metrics-grid")
    }

    private func metricTile(_ item: SessionSummaryMetricItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(item.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(item.labelKey))
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .tracking(0.9)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(SkateTrackSessionStartColors.border.opacity(0.72), lineWidth: 1))
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map { index in
            Array(self[index..<Swift.min(index + size, count)])
        }
    }
}
