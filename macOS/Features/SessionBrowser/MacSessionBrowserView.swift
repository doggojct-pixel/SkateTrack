// [協作區] MacSessionBrowserView.swift
// 用途：macOS 只讀 Session 瀏覽器 foundation，瀏覽目前已開啟 .skatetrack package 內的 session。
// 委派至：MacSessionDetailView；不得 import 到資料庫、merge、restore、同步雲端或宣告 document association。

import SwiftUI

struct MacSessionBrowserView: View {
    let preview: MacPackageImportPreview?
    let openImportAction: () -> Void

    @State private var selectedSessionID: UUID?

    private var viewerModels: [MacSessionViewerModel] {
        preview?.payload.sessions.map(MacSessionViewerModel.init) ?? []
    }

    private var selectedModel: MacSessionViewerModel? {
        if let selectedSessionID,
           let selected = viewerModels.first(where: { $0.id == selectedSessionID }) {
            return selected
        }
        return viewerModels.first
    }

    var body: some View {
        Group {
            if let preview {
                viewerContent(preview: preview)
            } else {
                emptyState
            }
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.72), Color.cyan.opacity(0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("mac.viewer.title")
        .onAppear { selectDefaultSessionIfNeeded() }
        .onChange(of: preview?.id) { _, _ in
            selectDefaultSessionIfNeeded(force: true)
        }
    }

    private func viewerContent(preview: MacPackageImportPreview) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                MacCurrentPackageSessionSummaryView(
                    preview: preview,
                    models: viewerModels,
                    selectedSessionID: $selectedSessionID,
                    selectedModel: selectedModel
                )

                if let selectedModel {
                    MacSessionDetailView(model: selectedModel, packageFileName: preview.fileName)
                } else {
                    MacSessionViewerEmptyCard(
                        titleKey: "mac.viewer.empty.no_session.title",
                        subtitleKey: "mac.viewer.empty.no_session.subtitle",
                        systemImage: "tray"
                    )
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
            .padding(.bottom, 30)
            .frame(maxWidth: 1_120, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                MacSessionViewerEmptyCard(
                    titleKey: "mac.viewer.empty.title",
                    subtitleKey: "mac.viewer.empty.subtitle",
                    systemImage: "list.bullet.rectangle"
                )

                Button(action: openImportAction) {
                    Label("mac.viewer.empty.button", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: 760, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private func selectDefaultSessionIfNeeded(force: Bool = false) {
        guard force || selectedSessionID == nil || !viewerModels.contains(where: { $0.id == selectedSessionID }) else { return }
        selectedSessionID = viewerModels.first?.id
    }
}

private struct MacCurrentPackageSessionSummaryView: View {
    let preview: MacPackageImportPreview
    let models: [MacSessionViewerModel]
    @Binding var selectedSessionID: UUID?
    let selectedModel: MacSessionViewerModel?

    private var currentModel: MacSessionViewerModel? {
        selectedModel ?? models.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Label("mac.viewer.package.current", systemImage: "lock.shield")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer(minLength: 12)
                Text(sessionCountText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 44, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentModel?.title ?? preview.primaryTitle)
                        .font(.title.bold())
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    Text(preview.fileName)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 6) {
                    if let currentModel {
                        Text(currentModel.startDate, style: .date)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(String(format: String(localized: "mac.package.preview.distance.format"), currentModel.displayMetrics.distanceKilometers))
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
                .frame(minWidth: 120, alignment: .trailing)
            }

            HStack(spacing: 8) {
                if let currentModel {
                    MacPackageSessionSummaryPill(titleKey: currentModel.sportModeKey, systemImage: "figure.skating")
                    MacPackageSessionSummaryPill(titleKey: currentModel.powerTypeKey, systemImage: "bolt")
                }
                MacPackageSessionSummaryPill(text: "mac.viewer.readonly.badge", systemImage: "lock")
            }

            if models.count > 1 {
                Divider().opacity(0.24)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(models) { model in
                            MacPackageSessionSelectorButton(
                                model: model,
                                isSelected: model.id == currentModel?.id
                            ) {
                                selectedSessionID = model.id
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.11), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var sessionCountText: String {
        if models.count == 1 {
            return String(localized: "mac.viewer.package.single_session")
        }
        return String(format: String(localized: "mac.viewer.package.session_count.format"), models.count)
    }
}

private struct MacPackageSessionSelectorButton: View {
    let model: MacSessionViewerModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(model.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 8) {
                    Text(String(format: String(localized: "mac.package.preview.distance.format"), model.displayMetrics.distanceKilometers))
                    Text(String(format: String(localized: "mac.package.preview.speed.format"), model.displayMetrics.maxSpeedKilometersPerHour))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isSelected ? .white.opacity(0.86) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(width: 190, alignment: .leading)
            .background(isSelected ? Color.accentColor : Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(model.title))
        .accessibilityHint(Text("mac.viewer.list.row.hint"))
    }
}

private struct MacPackageSessionSummaryPill: View {
    let titleKey: String?
    let text: String?
    let systemImage: String

    init(titleKey: String, systemImage: String) {
        self.titleKey = titleKey
        self.text = nil
        self.systemImage = systemImage
    }

    init(text: String, systemImage: String) {
        self.titleKey = nil
        self.text = text
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            if let titleKey {
                Text(LocalizedStringKey(titleKey))
            } else {
                Text(LocalizedStringKey(text ?? ""))
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08), in: Capsule())
    }
}

private struct MacSessionViewerEmptyCard: View {
    let titleKey: String
    let subtitleKey: String
    let systemImage: String

    var body: some View {
        MacLockedFeatureCardView(
            titleKey: titleKey,
            subtitleKey: subtitleKey,
            systemImage: systemImage
        )
    }
}
