// [協作區] MacLockedFeatureCardView.swift
// 用途：macOS 尚未完成的 Phase 1a / Phase 2 功能統一以 locked card 顯示，方便 Task-029 accessibility pass。
// 委派至：Task-028 macOS shell 與後續 macOS viewer；不包含任何付費狀態或交易狀態。

import SwiftUI

struct MacLockedFeatureCardView: View {
    let titleKey: String
    let subtitleKey: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 52, height: 52)
                    .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(titleKey))
                        .font(.title2.bold())
                    Text(LocalizedStringKey(subtitleKey))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            Label {
                Text("mac.import.locked.footer")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.orange)
            }
        }
        .padding(24)
        .frame(maxWidth: 620, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    MacLockedFeatureCardView(
        titleKey: "mac.import.locked.analytics.title",
        subtitleKey: "mac.import.locked.analytics.subtitle",
        systemImage: "chart.xyaxis.line"
    )
    .padding()
}
