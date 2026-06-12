// [協作區] MacImportView.swift
// 用途：macOS NSOpenPanel 匯入 .skatetrack package，顯示只讀 preview。
// 委派至：MacPackageImportViewModel / Shared/Export reader；不宣告 custom UTType 或 document association。

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MacImportView: View {
    @StateObject private var viewModel = MacPackageImportViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                MacImportHeroCard(
                    isImporting: viewModel.isImporting,
                    openAction: openPackagePanel,
                    clearAction: viewModel.clearPreview,
                    hasPreview: viewModel.preview != nil
                )

                if let errorMessageKey = viewModel.errorMessageKey {
                    MacImportStatusCard(
                        titleKey: "mac.import.error.title",
                        messageKey: errorMessageKey,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                }

                if let preview = viewModel.preview {
                    MacPackagePreviewView(preview: preview)
                } else {
                    MacImportEmptyStateView(lastReadFileName: viewModel.lastReadFileName)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: 980, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.72), Color.cyan.opacity(0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("mac.import.title")
    }

    private func openPackagePanel() {
        let panel = NSOpenPanel()
        panel.title = String(localized: "mac.import.panel.title")
        panel.prompt = String(localized: "mac.import.panel.prompt")
        panel.message = String(localized: "mac.import.panel.message")
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.data]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        viewModel.importPackage(from: url)
    }
}

private struct MacImportHeroCard: View {
    let isImporting: Bool
    let openAction: () -> Void
    let clearAction: () -> Void
    let hasPreview: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 68, height: 68)
                    .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("mac.import.hero.title")
                        .font(.largeTitle.bold())
                    Text("mac.import.hero.subtitle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                Button(action: openAction) {
                    Label {
                        Text(LocalizedStringKey(isImporting ? "mac.import.button.importing" : "mac.import.button.choose"))
                    } icon: {
                        Image(systemName: "folder")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)

                if hasPreview {
                    Button(role: .destructive, action: clearAction) {
                        Label("mac.import.button.clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Text("mac.import.hero.boundary")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MacImportStatusCard: View {
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

private struct MacImportEmptyStateView: View {
    let lastReadFileName: String?

    var body: some View {
        MacLockedFeatureCardView(
            titleKey: lastReadFileName == nil ? "mac.import.empty.title" : "mac.import.empty.after_error.title",
            subtitleKey: lastReadFileName == nil ? "mac.import.empty.subtitle" : "mac.import.empty.after_error.subtitle",
            systemImage: "doc.badge.plus"
        )
    }
}

#Preview {
    NavigationStack {
        MacImportView()
    }
}
