// [協作區] MacSnowUnavailableDataView.swift
// 用途：顯示 macOS Snow viewer 的 packageSchemaPending / unavailable transparent fallback。
// 委派至：MacSnowRootView；不得假裝正式 package Snow payload 已可用。

import SwiftUI

struct MacSnowUnavailableDataView: View {
    let availability: MacSnowAnalysisAvailability

    var body: some View {
        let content = contentForAvailability
        MacSnowEmptyState(
            titleKey: content.titleKey,
            messageKey: content.messageKey,
            systemImage: content.systemImage
        )
        .padding(24)
        .background(MacSnowStyle.backgroundGradient)
    }

    private var contentForAvailability: (titleKey: String, messageKey: String, systemImage: String) {
        switch availability {
        case .available:
            return (
                titleKey: "mac.snow.unavailable.title",
                messageKey: "mac.snow.unavailable.message",
                systemImage: "snowflake"
            )
        case .packageSchemaPending:
            return (
                titleKey: "mac.snow.unavailable.title",
                messageKey: "mac.snow.unavailable.package_schema_pending",
                systemImage: "shippingbox"
            )
        case .unavailable:
            return (
                titleKey: "mac.snow.unavailable.title",
                messageKey: "mac.snow.unavailable.message",
                systemImage: "exclamationmark.triangle"
            )
        }
    }
}
