// [協作區] SessionShareCardMetricView.swift
// 用途：呈現分享卡內的單一摘要指標，保持分享卡 Preview 主檔案可讀。
// 委派至：SessionShareCardPreviewView 組合整張卡片；資料由 useSessionShareCard 提供。

import SwiftUI

struct SessionShareCardMetricView: View {
    let metric: SessionShareCardMetricData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: metric.systemImageName)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(accentColor)

                Text(LocalizedStringKey(metric.labelLocalizationKey))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .lineLimit(1)
            }

            Text(metric.value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accentColor.opacity(0.18), lineWidth: 1))
        .accessibilityIdentifier("session-share-card-metric-\(metric.id)")
    }

    private var accentColor: Color {
        switch metric.accentName {
        case .teal:
            return SkateTrackSessionStartColors.teal
        case .purple:
            return SkateTrackSessionStartColors.purple
        case .amber:
            return SkateTrackSessionStartColors.amber
        case .white:
            return .white
        }
    }
}
