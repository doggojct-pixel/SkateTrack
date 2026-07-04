// [協作區] macOS/Features/SessionBrowser/MacPackageCardListView.swift
// 用途：提供 Task-030e read-only multi-package cards 與 batch summary，讓使用者在已開啟 packages 間切換。
// 委派至：MacSessionBrowserView / MacPackageImportViewModel；不得寫入資料庫、merge、restore、sync 或修改 package / route。

import SwiftUI

struct MacPackageCardListView: View {
    let packages: [MacPackageImportPreview]
    let selectedPackageID: UUID?
    let batchSummary: MacPackageOpenBatchSummary
    let selectPackageAction: (UUID) -> Void
    let removePackageAction: (UUID) -> Void

    private var activeSelectedPackageID: UUID? {
        selectedPackageID ?? packages.first?.id
    }

    var body: some View {
        Group {
            if packages.count > 1 {
                content
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            packageScroller
        }
        .padding(18)
        .background(panelBackground)
        .overlay(panelBorder)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("mac.accessibility.package_cards.label"))
        .accessibilityHint(Text("mac.accessibility.package_cards.hint"))
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.white.opacity(0.045))
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(.white.opacity(0.08), lineWidth: 1)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label("mac.viewer.packages.title", systemImage: "rectangle.stack.fill")
                .font(.headline)
                .foregroundStyle(.green)

            Spacer(minLength: 12)

            Text(summaryText)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var packageScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(packages) { package in
                    MacPackageSelectionCard(
                        package: package,
                        position: packagePosition(for: package.id),
                        isSelected: package.id == activeSelectedPackageID,
                        selectAction: { selectPackageAction(package.id) },
                        removeAction: { removePackageAction(package.id) }
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var summaryText: String {
        String(
            format: String(localized: "mac.viewer.packages.summary.format"),
            batchSummary.totalPackageCount,
            batchSummary.totalSessionCount,
            batchSummary.routeCapablePackageCount
        )
    }

    private func packagePosition(for id: UUID) -> Int {
        (packages.firstIndex { $0.id == id } ?? 0) + 1
    }
}

private struct MacPackageSelectionCard: View {
    let package: MacPackageImportPreview
    let position: Int
    let isSelected: Bool
    let selectAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardSelectButton
            removeButton
                .padding(12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(package.primaryTitle))
        .accessibilityValue(Text(selectionAccessibilityKey))
        .accessibilityHint(Text("mac.viewer.packages.card.hint"))
    }

    private var cardSelectButton: some View {
        Button(action: selectAction) {
            cardContent
                .padding(14)
                .frame(width: 250, alignment: .topLeading)
                .frame(minHeight: 170, alignment: .topLeading)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .background(cardBackground)
        .overlay(cardBorder)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleBlock
                .padding(.trailing, 24)
            Divider().opacity(0.18)
            metricsSection
            if package.hasAttentionWarnings {
                attentionSection
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(positionText)
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(positionForegroundStyle)
            Text(package.primaryTitle)
                .font(.callout.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            Text(package.fileName)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var removeButton: some View {
        Button(role: .destructive, action: removeAction) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel(Text("mac.viewer.packages.card.remove"))
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            metricRow(systemImage: "list.bullet.rectangle", text: sessionCountText)
            metricRow(systemImage: "point.3.connected.trianglepath.dotted", text: routeCountText)
            metricRow(systemImage: "waveform.path.ecg.rectangle", text: motionCountText)
        }
    }

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("mac.viewer.attention.card.badge", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)

            ForEach(package.attentionWarnings.prefix(2)) { warning in
                Text(LocalizedStringKey(warning.titleKey))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(cardFill)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(cardStroke, lineWidth: 1)
    }

    private var cardFill: Color {
        if package.hasAttentionWarnings {
            return isSelected ? Color.orange.opacity(0.18) : Color.orange.opacity(0.10)
        }
        return isSelected ? Color.cyan.opacity(0.16) : Color.white.opacity(0.055)
    }

    private var cardStroke: Color {
        if package.hasAttentionWarnings {
            return Color.orange.opacity(isSelected ? 0.62 : 0.28)
        }
        return isSelected ? Color.cyan.opacity(0.56) : Color.white.opacity(0.08)
    }

    private var positionForegroundStyle: Color {
        if package.hasAttentionWarnings { return .orange }
        return isSelected ? .cyan : .secondary
    }

    private var metricIconColor: Color {
        if package.hasAttentionWarnings { return .orange }
        return isSelected ? .cyan : .secondary
    }

    private var positionText: String {
        String(format: String(localized: "mac.viewer.packages.card.position.format"), position)
    }

    private var sessionCountText: String {
        String(
            format: String(localized: "mac.viewer.packages.card.session_count.format"),
            package.sessionCount
        )
    }

    private var routeCountText: String {
        String(
            format: String(localized: "mac.viewer.packages.card.route_count.format"),
            package.routeSampleCount
        )
    }

    private var motionCountText: String {
        String(
            format: String(localized: "mac.viewer.packages.card.motion_count.format"),
            package.motionSampleCount
        )
    }

    private var selectionAccessibilityKey: String {
        isSelected ? "mac.viewer.packages.card.selected" : "mac.viewer.packages.card.not_selected"
    }

    private func metricRow(systemImage: String, text: String) -> some View {
        Label {
            Text(text)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(metricIconColor)
        }
    }
}
