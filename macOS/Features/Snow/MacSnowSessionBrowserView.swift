// [協作區] MacSnowSessionBrowserView.swift
// 用途：顯示 macOS Snow viewer 的唯讀 session list / source context。
// 委派至：MacSnowRootView；正式 package-sourced browser wiring deferred to Snow-Task-008。

import SwiftUI

struct MacSnowSessionBrowserView: View {
    let analyses: [MacSnowSessionAnalysis]
    @Binding var selectedAnalysisID: UUID?

    var body: some View {
        MacSnowSection(
            titleKey: "mac.snow.session.browser.title",
            subtitleKey: "mac.snow.session.browser.subtitle",
            systemImage: "list.bullet.rectangle"
        ) {
            if analyses.isEmpty {
                MacSnowEmptyState(
                    titleKey: "mac.snow.session.browser.empty",
                    messageKey: "mac.snow.session.browser.empty.message",
                    systemImage: "tray"
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(analyses) { analysis in
                        Button {
                            selectedAnalysisID = analysis.id
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "snowflake")
                                    .foregroundStyle(MacSnowStyle.ice)
                                    .font(.title3)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(analysis.title)
                                        .font(.headline)
                                        .foregroundStyle(MacSnowStyle.snowText)
                                    Text(analysis.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(MacSnowStyle.text2)
                                    Text(MacSnowFormatters.dateTime(analysis.startDate))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(MacSnowStyle.text3)
                                }
                                Spacer()
                                Text(MacSnowFormatters.distanceKilometers(analysis.distanceBreakdown.skiDistanceMeters))
                                    .font(.callout.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(MacSnowStyle.snowText)
                                Image(systemName: selectedAnalysisID == analysis.id ? "checkmark.circle.fill" : "chevron.right")
                                    .foregroundStyle(selectedAnalysisID == analysis.id ? MacSnowStyle.ice : MacSnowStyle.text2)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                selectedAnalysisID == analysis.id ? MacSnowStyle.selectedRowGradient : MacSnowStyle.cardGradient,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
