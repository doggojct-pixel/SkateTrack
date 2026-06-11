// [協作區] HeartRateZonePlaceholderView.swift
// 用途：呈現 Task-018c 心率區間佔位，避免在 HealthKit / 穿戴資料存在前顯示假健康數據。
// 委派至：後續 HealthKit / watchOS 任務接上真實心率資料。

import SwiftUI

struct HeartRateZonePlaceholderView: View {
    var body: some View {
        ChartCard(
            titleKey: "summary.advancedCharts.heartRate.title",
            subtitleKey: "summary.advancedCharts.heartRate.subtitle",
            systemImage: "heart.text.square.fill",
            accentColor: SkateTrackSessionStartColors.amber
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(SkateTrackSessionStartColors.amber.opacity(0.12 + Double(index) * 0.05))
                        .frame(width: CGFloat(72 + index * 54), height: 10)
                }

                Text("summary.advancedCharts.heartRate.noFakeData")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityIdentifier("heart-rate-zone-placeholder-view")
    }
}

struct ChartCard<Content: View>: View {
    let titleKey: String
    let subtitleKey: String
    let systemImage: String
    let accentColor: Color
    private let content: Content

    init(
        titleKey: String,
        subtitleKey: String,
        systemImage: String,
        accentColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(LocalizedStringKey(subtitleKey))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            content
        }
        .padding(14)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border.opacity(0.72), lineWidth: 1))
    }
}

struct ChartEmptyState: View {
    let titleKey: String
    let subtitleKey: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(titleKey))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(LocalizedStringKey(subtitleKey))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
