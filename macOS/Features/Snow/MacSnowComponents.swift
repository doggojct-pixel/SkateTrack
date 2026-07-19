// [協作區] MacSnowComponents.swift
// 用途：提供 macOS Snow viewer 共用唯讀 UI 元件，不承載 package 或 persistence 邏輯。
// 委派至：MacSnowDashboardView、Timeline、Inspector 與 Distance Inspector。

import SwiftUI

struct MacSnowSection<Content: View>: View {
    let titleKey: String
    let subtitleKey: String?
    let systemImage: String
    private let content: Content

    init(
        titleKey: String,
        subtitleKey: String? = nil,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.titleKey = titleKey
        self.subtitleKey = subtitleKey
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Label {
                    Text(LocalizedStringKey(titleKey))
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(MacSnowStyle.ice)
                }
                .font(.headline.bold())
                .foregroundStyle(MacSnowStyle.snowText)

                Spacer(minLength: 12)
            }

            if let subtitleKey {
                Text(LocalizedStringKey(subtitleKey))
                    .font(.caption)
                    .foregroundStyle(MacSnowStyle.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MacSnowStyle.panelGradient, in: RoundedRectangle(cornerRadius: MacSnowStyle.panelCornerRadius, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(MacSnowStyle.ice.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 58)
                .offset(x: 70, y: -92)
                .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: MacSnowStyle.panelCornerRadius, style: .continuous)
                .stroke(MacSnowStyle.sectionStroke, lineWidth: 1)
        )
        .shadow(color: MacSnowStyle.ice.opacity(0.055), radius: 24, x: 0, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(LocalizedStringKey(titleKey)))
    }
}

struct MacSnowMetricTile: View {
    let titleKey: String
    let value: String
    let systemImage: String
    var footnoteKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .foregroundStyle(MacSnowStyle.ice)
                Text(LocalizedStringKey(titleKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MacSnowStyle.text2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(MacSnowStyle.snowText)
                .lineLimit(1)
                .minimumScaleFactor(0.70)

            if let footnoteKey {
                Text(LocalizedStringKey(footnoteKey))
                    .font(.caption2)
                    .foregroundStyle(MacSnowStyle.text2.opacity(0.86))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .background(MacSnowStyle.metricGradient, in: RoundedRectangle(cornerRadius: MacSnowStyle.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MacSnowStyle.cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

struct MacSnowStatusPill: View {
    let titleKey: String
    let systemImage: String
    var tint: Color = MacSnowStyle.ice

    var body: some View {
        Label {
            Text(LocalizedStringKey(titleKey))
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.15), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.26), lineWidth: 1))
        .foregroundStyle(tint)
        .accessibilityElement(children: .combine)
    }
}

struct MacSnowEmptyState: View {
    let titleKey: String
    let messageKey: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(MacSnowStyle.ice)
            Text(LocalizedStringKey(titleKey))
                .font(.title3.bold())
                .foregroundStyle(MacSnowStyle.snowText)
            Text(LocalizedStringKey(messageKey))
                .font(.callout)
                .foregroundStyle(MacSnowStyle.text2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
        }
        .padding(32)
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(MacSnowStyle.cardGradient, in: RoundedRectangle(cornerRadius: MacSnowStyle.panelCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MacSnowStyle.panelCornerRadius, style: .continuous)
                .stroke(MacSnowStyle.sectionStroke, lineWidth: 1)
        )
    }
}
