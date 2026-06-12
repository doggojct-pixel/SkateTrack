// [協作區] SessionShareCardPreviewView.swift
// 用途：呈現 Task-023a 本機分享卡預覽，不負責圖片輸出或系統分享。
// 委派至：useSessionShareCard 提供資料；Task-023b 才接圖片輸出與系統分享。

import SwiftUI

struct SessionShareCardPreviewView: View {
    let card: SessionShareCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            heroMetrics
            metricsGrid
            attributionRows
            footer
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(SkateTrackSessionStartColors.border.opacity(0.9), lineWidth: 1))
        .shadow(color: SkateTrackSessionStartColors.teal.opacity(0.12), radius: 22, x: 0, y: 12)
        .accessibilityIdentifier("session-share-card-preview")
    }

    private var cardBackground: some View {
        ZStack {
            SkateTrackSessionStartColors.card.opacity(0.96)
            LinearGradient(
                colors: [SkateTrackSessionStartColors.teal.opacity(0.18), SkateTrackSessionStartColors.purple.opacity(0.14), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("summary.share.card.eyebrow")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)

                Text(LocalizedStringKey(card.sportModeLocalizationKey))
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(card.dateLine)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 7) {
                Text("summary.share.brand")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)

                Text(LocalizedStringKey(card.powerTypeLocalizationKey))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }

    private var heroMetrics: some View {
        HStack(alignment: .bottom, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.distanceText)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.teal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("summary.metric.distance")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(card.maxSpeedText)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.purple)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("summary.metric.maxSpeed")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(card.metrics) { metric in
                SessionShareCardMetricView(metric: metric)
            }
        }
    }

    private var attributionRows: some View {
        VStack(alignment: .leading, spacing: 9) {
            attributionRow(
                icon: "mappin.and.ellipse",
                labelKey: "summary.share.spot",
                value: card.spotName ?? NSLocalizedString("summary.share.spot.none", comment: "")
            )
            attributionRow(
                icon: "skateboard.fill",
                labelKey: "summary.share.equipment",
                value: card.equipmentName ?? NSLocalizedString("summary.share.equipment.none", comment: "")
            )
            attributionRow(icon: "map.fill", labelKey: "summary.share.route", valueKey: card.routeStatusLocalizationKey)
            attributionRow(icon: "shield.checkered", labelKey: "summary.share.safety", value: card.safetyStatusText)
        }
    }

    private func attributionRow(icon: String, labelKey: String, value: String) -> some View {
        attributionRowContent(icon: icon, labelKey: labelKey) {
            Text(value)
        }
    }

    private func attributionRow(icon: String, labelKey: String, valueKey: String) -> some View {
        attributionRowContent(icon: icon, labelKey: labelKey) {
            Text(LocalizedStringKey(valueKey))
        }
    }

    private func attributionRowContent<Value: View>(
        icon: String,
        labelKey: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .frame(width: 24)

            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)

            Spacer(minLength: 8)

            value()
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(SkateTrackSessionStartColors.teal)
                .frame(width: 7, height: 7)
            Text("summary.share.footer")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            Spacer(minLength: 0)
        }
    }
}
