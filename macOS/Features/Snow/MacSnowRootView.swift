// [協作區] MacSnowRootView.swift
// 用途：組合 macOS Snow read-only viewer；只有 availability.available 才顯示六個分析 view。
// 委派至：MacRootView DEBUG preview 與後續 repository/package adapter。

import SwiftUI

struct MacSnowRootView: View {
    @ObservedObject var viewModel: MacSnowAnalysisViewModel
    @State private var selectedAnalysisID: UUID?

    var body: some View {
        switch viewModel.availability {
        case let .available(analysis):
            ZStack {
                MacSnowStyle.backgroundGradient
                    .ignoresSafeArea()
                MacSnowStyle.auroraGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(analysis: analysis)
                        MacSnowSessionBrowserView(
                            analyses: [analysis],
                            selectedAnalysisID: Binding(
                                get: { selectedAnalysisID ?? analysis.id },
                                set: { selectedAnalysisID = $0 }
                            )
                        )
                        MacSnowDashboardView(analysis: analysis)

                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 16) {
                                MacSnowRouteElevationView(analysis: analysis)
                                    .frame(minWidth: 520)
                                MacSnowSegmentTimelineView(
                                    analysis: analysis,
                                    selectedSegmentID: $viewModel.selectedSegmentID
                                )
                                .frame(minWidth: 390)
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                MacSnowRouteElevationView(analysis: analysis)
                                MacSnowSegmentTimelineView(
                                    analysis: analysis,
                                    selectedSegmentID: $viewModel.selectedSegmentID
                                )
                            }
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 16) {
                                MacSnowSegmentInspectorView(analysis: analysis)
                                MacSnowDistanceInspectorView(analysis: analysis)
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                MacSnowSegmentInspectorView(analysis: analysis)
                                MacSnowDistanceInspectorView(analysis: analysis)
                            }
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: 1320, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .foregroundStyle(MacSnowStyle.snowText)
            .navigationTitle(Text(analysis.title))
        case .packageSchemaPending, .unavailable:
            ZStack {
                MacSnowStyle.backgroundGradient
                    .ignoresSafeArea()
                MacSnowUnavailableDataView(availability: viewModel.availability)
                    .padding(28)
            }
            .navigationTitle(Text(LocalizedStringKey("mac.snow.dashboard.title")))
        }
    }

    private func header(analysis: MacSnowSessionAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SKATETRACK SNOW · READ-ONLY REVIEW")
                        .font(.caption.weight(.semibold).monospaced())
                        .tracking(2)
                        .foregroundStyle(MacSnowStyle.ice)
                    Text(analysis.title)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(MacSnowStyle.snowText)
                    Text(analysis.subtitle)
                        .font(.callout)
                        .foregroundStyle(MacSnowStyle.text2)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 8) {
                    MacSnowStatusPill(
                        titleKey: "mac.snow.guardrail.read_only",
                        systemImage: "lock",
                        tint: MacSnowStyle.ice
                    )
                    if analysis.source == .debugMock {
                        MacSnowStatusPill(
                            titleKey: "mac.snow.guardrail.debug_mock",
                            systemImage: "ladybug",
                            tint: MacSnowStyle.amber
                        )
                    }
                    if analysis.source == .importedPackage {
                        MacSnowStatusPill(
                            titleKey: "mac.snow.guardrail.package_008",
                            systemImage: "shippingbox",
                            tint: MacSnowStyle.text2
                        )
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                MacSnowStyle.panelGradient
                Circle()
                    .fill(MacSnowStyle.ice.opacity(0.15))
                    .frame(width: 280, height: 280)
                    .blur(radius: 72)
                    .offset(x: 92, y: -128)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(MacSnowStyle.iceStroke, lineWidth: 1)
        )
        .shadow(color: MacSnowStyle.ice.opacity(0.11), radius: 28, x: 0, y: 10)
    }
}
