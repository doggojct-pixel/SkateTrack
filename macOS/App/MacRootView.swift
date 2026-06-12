// [協作區] MacRootView.swift
// 用途：定義 SkateTrack macOS 獨立 sidebar shell，承接 Task-027b .skatetrack 匯入預覽。
// 委派至：macOS/Features/Import 與後續 Task-028 macOS viewer；macOS 導覽結構需獨立於 iOS。

import SwiftUI

private enum MacRootDestination: String, CaseIterable, Identifiable, Hashable {
    case importPackage
    case sessionBrowser
    case analytics
    case videoOverlay
    case cloudSync

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .importPackage:
            return "mac.import.sidebar.import"
        case .sessionBrowser:
            return "mac.import.sidebar.sessions"
        case .analytics:
            return "mac.import.sidebar.analytics"
        case .videoOverlay:
            return "mac.import.sidebar.video"
        case .cloudSync:
            return "mac.import.sidebar.cloud"
        }
    }

    var subtitleKey: String {
        switch self {
        case .importPackage:
            return "mac.import.sidebar.import.subtitle"
        case .sessionBrowser:
            return "mac.import.sidebar.sessions.subtitle"
        case .analytics:
            return "mac.import.sidebar.analytics.subtitle"
        case .videoOverlay:
            return "mac.import.sidebar.video.subtitle"
        case .cloudSync:
            return "mac.import.sidebar.cloud.subtitle"
        }
    }

    var systemImage: String {
        switch self {
        case .importPackage:
            return "square.and.arrow.down"
        case .sessionBrowser:
            return "list.bullet.rectangle"
        case .analytics:
            return "chart.xyaxis.line"
        case .videoOverlay:
            return "film.stack"
        case .cloudSync:
            return "externaldrive.connected.to.line.below"
        }
    }
}

struct MacRootView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selection: MacRootDestination = .importPackage

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            MacSidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 224, ideal: 248, max: 300)
        } detail: {
            MacRootDetailView(selection: selection)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 960, minHeight: 660)
    }
}

private struct MacSidebarView: View {
    @Binding var selection: MacRootDestination

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("mac.import.sidebar.section")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)

                ForEach(MacRootDestination.allCases) { destination in
                    Button {
                        selection = destination
                    } label: {
                        MacSidebarRow(
                            destination: destination,
                            isSelected: selection == destination
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(LocalizedStringKey(destination.titleKey))
                    .accessibilityHint(LocalizedStringKey(destination.subtitleKey))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 0)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.ultraThinMaterial)
    }
}

private struct MacRootDetailView: View {
    let selection: MacRootDestination

    var body: some View {
        switch selection {
        case .importPackage:
            MacImportView()
        case .sessionBrowser:
            MacLockedDestinationView(
                destination: selection,
                titleKey: "mac.import.locked.sessions.title",
                subtitleKey: "mac.import.locked.sessions.subtitle",
                systemImage: "list.bullet.rectangle"
            )
        case .analytics:
            MacLockedDestinationView(
                destination: selection,
                titleKey: "mac.import.locked.analytics.title",
                subtitleKey: "mac.import.locked.analytics.subtitle",
                systemImage: "chart.xyaxis.line"
            )
        case .videoOverlay:
            MacLockedDestinationView(
                destination: selection,
                titleKey: "mac.import.locked.video.title",
                subtitleKey: "mac.import.locked.video.subtitle",
                systemImage: "film.stack"
            )
        case .cloudSync:
            MacLockedDestinationView(
                destination: selection,
                titleKey: "mac.import.locked.cloud.title",
                subtitleKey: "mac.import.locked.cloud.subtitle",
                systemImage: "externaldrive.connected.to.line.below"
            )
        }
    }
}

private struct MacLockedDestinationView: View {
    let destination: MacRootDestination
    let titleKey: String
    let subtitleKey: String
    let systemImage: String

    var body: some View {
        ScrollView {
            MacLockedFeatureCardView(
                titleKey: titleKey,
                subtitleKey: subtitleKey,
                systemImage: systemImage
            )
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.72), Color.cyan.opacity(0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle(LocalizedStringKey(destination.titleKey))
    }
}

private struct MacSidebarRow: View {
    let destination: MacRootDestination
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: destination.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                .frame(width: 22, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(destination.titleKey))
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(LocalizedStringKey(destination.subtitleKey))
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.84) : .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor : Color.clear
    }
}

#Preview {
    MacRootView()
}
