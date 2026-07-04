// [協作區] MacSessionBrowserView.swift
// 用途：macOS browser-first 只讀 Session 瀏覽器，從瀏覽器內開啟 .skatetrack package 並顯示 session。
// 委派至：MacSessionDetailView / MacPackageImportViewModel；不得 import 到資料庫、merge、restore、同步雲端或宣告 document association。

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MacSessionBrowserView: View {
    @ObservedObject private var viewModel: MacPackageImportViewModel

    init(viewModel: MacPackageImportViewModel) {
        self.viewModel = viewModel
    }

    private var preview: MacPackageImportPreview? {
        viewModel.preview
    }

    private var viewerModels: [MacSessionViewerModel] {
        viewModel.selectedViewerModels
    }

    private var selectedModel: MacSessionViewerModel? {
        viewModel.selectedViewerModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                MacPackageBrowserHeaderView(
                    preview: preview,
                    batchSummary: viewModel.batchSummary,
                    isReading: viewModel.isImporting,
                    openAction: openPackagePanel,
                    clearAction: viewModel.clearPreview
                )

                if let lastOpenResult = viewModel.lastOpenResult {
                    MacPackageOpenResultStatusView(result: lastOpenResult)
                }

                if let errorMessageKey = viewModel.errorMessageKey, viewModel.lastOpenResult == nil {
                    MacSessionBrowserStatusCard(
                        titleKey: "mac.viewer.open.error.title",
                        messageKey: errorMessageKey,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                }

                MacPackageAttentionSummaryView(
                    summary: viewModel.attentionSummary,
                    canAcknowledgeDuplicateFiles: viewModel.hasAcknowledgeableDuplicateFilePathWarnings,
                    acknowledgeDuplicateFilesAction: viewModel.acknowledgeDuplicateFilePathWarnings
                )

                MacPackageCardListView(
                    packages: viewModel.openedPackages,
                    selectedPackageID: viewModel.selectedPackageID,
                    batchSummary: viewModel.batchSummary,
                    selectPackageAction: { viewModel.selectPackage(id: $0) },
                    removePackageAction: viewModel.removePackage
                )

                if let preview {
                    viewerContent(preview: preview)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
            .padding(.bottom, 30)
            .frame(maxWidth: 1_120, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.72), Color.cyan.opacity(0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("mac.viewer.title")
        .onAppear { viewModel.ensureDefaultSelection() }
        .onChange(of: preview?.id) { _, _ in
            viewModel.ensureDefaultSelection()
        }
    }

    private func viewerContent(preview: MacPackageImportPreview) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            MacCurrentPackageSessionSummaryView(
                preview: preview,
                models: viewerModels,
                selectedModel: selectedModel
            )

            MacPackageSessionListView(
                models: viewerModels,
                selectedSessionID: viewModel.selectedSessionID,
                selectedModel: selectedModel,
                selectSessionAction: viewModel.selectSession
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
    }

    private var emptyState: some View {
        MacSessionViewerEmptyCard(
            titleKey: "mac.viewer.empty.title",
            subtitleKey: "mac.viewer.empty.subtitle",
            systemImage: "list.bullet.rectangle"
        )
    }

    private func openPackagePanel() {
        let panel = NSOpenPanel()
        panel.title = String(localized: "mac.viewer.open.panel.title")
        panel.prompt = String(localized: "mac.viewer.open.panel.prompt")
        panel.message = String(localized: "mac.viewer.open.panel.message")
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.data]

        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }
        viewModel.openPackages(from: panel.urls)
    }

}

private struct MacPackageBrowserHeaderView: View {
    let preview: MacPackageImportPreview?
    let batchSummary: MacPackageOpenBatchSummary
    let isReading: Bool
    let openAction: () -> Void
    let clearAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "rectangle.stack.badge.play")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 60, height: 60)
                    .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    Text("mac.viewer.open.title")
                        .font(.largeTitle.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("mac.viewer.open.subtitle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 18)

                VStack(alignment: .trailing, spacing: 10) {
                    Button(action: openAction) {
                        Label {
                            Text(LocalizedStringKey(isReading ? "mac.import.button.importing" : "mac.viewer.open.button"))
                        } icon: {
                            Image(systemName: "folder")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isReading)
                    .accessibilityLabel(Text("mac.accessibility.open_packages.button.label"))
                    .accessibilityHint(Text("mac.accessibility.open_packages.button.hint"))
                    .accessibilityIdentifier("mac-open-packages-button")
                    .help(Text("mac.accessibility.open_packages.button.hint"))

                    if preview != nil {
                        Button(role: .destructive, action: clearAction) {
                            Label("mac.viewer.open.clear", systemImage: "xmark.circle")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(Text("mac.accessibility.clear_packages.button.label"))
                        .accessibilityHint(Text("mac.accessibility.clear_packages.button.hint"))
                        .accessibilityIdentifier("mac-clear-packages-button")
                        .help(Text("mac.accessibility.clear_packages.button.hint"))
                    }
                }
            }

            if batchSummary.totalPackageCount > 1 {
                Label {
                    Text(String(format: String(localized: "mac.viewer.open.current_batch.format"), batchSummary.totalPackageCount, batchSummary.totalSessionCount))
                        .font(.callout.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                } icon: {
                    Image(systemName: "rectangle.stack.badge.play")
                        .foregroundStyle(.green)
                }
            } else if let preview {
                Label {
                    Text(String(format: String(localized: "mac.viewer.open.current_file.format"), preview.fileName))
                        .font(.callout.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                } icon: {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(.green)
                }
            }

            Label {
                Text("mac.viewer.open.readonly")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.green)
            }
        }
        .padding(24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("mac.accessibility.browser_header.label"))
        .accessibilityHint(Text("mac.accessibility.browser_header.hint"))
    }
}

private struct MacSessionBrowserStatusCard: View {
    let titleKey: String
    let messageKey: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(titleKey))
                    .font(.headline)
                Text(LocalizedStringKey(messageKey))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)
        }
        .padding(18)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MacCurrentPackageSessionSummaryView: View {
    let preview: MacPackageImportPreview
    let models: [MacSessionViewerModel]
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
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.11), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mac.accessibility.package_summary.label"))
        .accessibilityHint(Text("mac.accessibility.package_summary.hint"))
    }

    private var sessionCountText: String {
        if models.count == 1 {
            return String(localized: "mac.viewer.package.single_session")
        }
        return String(format: String(localized: "mac.viewer.package.session_count.format"), models.count)
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
