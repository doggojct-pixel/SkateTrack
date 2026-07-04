// [協作區] macOS/Features/SessionBrowser/MacPackageSessionListView.swift
// 用途：提供 Task-030e read-only selected package session list，讓使用者在同一 package 內切換 Session。
// 委派至：MacSessionBrowserView / MacPackageImportViewModel；不得寫入資料庫、merge、restore、sync、修改 package 或 route。

import SwiftUI

struct MacPackageSessionListView: View {
    let models: [MacSessionViewerModel]
    let selectedSessionID: UUID?
    let selectedModel: MacSessionViewerModel?
    let selectSessionAction: (UUID?) -> Void

    private var activeSelectedSessionID: UUID? {
        selectedSessionID ?? selectedModel?.id ?? models.first?.id
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 260), spacing: 12)]
    }

    var body: some View {
        Group {
            if !models.isEmpty {
                content
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            sessionGrid
        }
        .padding(18)
        .background(panelBackground)
        .overlay(panelBorder)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("mac.accessibility.session_list.label"))
        .accessibilityHint(Text("mac.accessibility.session_list.hint"))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label("mac.viewer.sessions.title", systemImage: "list.bullet.rectangle")
                .font(.headline)
                .foregroundStyle(.cyan)

            Text("mac.viewer.sessions.subtitle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(countText)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var sessionGrid: some View {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
            ForEach(models) { model in
                MacPackageSessionListRow(
                    model: model,
                    isSelected: model.id == activeSelectedSessionID,
                    action: { selectSessionAction(model.id) }
                )
            }
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.white.opacity(0.04))
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(.white.opacity(0.08), lineWidth: 1)
    }

    private var countText: String {
        if models.count == 1 {
            return String(localized: "mac.viewer.sessions.single_count")
        }
        return String(format: String(localized: "mac.viewer.sessions.count.format"), models.count)
    }
}

private struct MacPackageSessionListRow: View {
    let model: MacSessionViewerModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            rowContent
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .background(rowBackground)
        .overlay(rowBorder)
        .accessibilityLabel(Text(model.title))
        .accessibilityValue(Text(selectionText))
        .accessibilityHint(Text("mac.viewer.sessions.card.hint"))
        .accessibilityIdentifier("mac-session-list-card")
        .help(Text("mac.viewer.sessions.card.hint"))
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleLine
            metadataLine
            metricsLine
        }
    }

    private var titleLine: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .cyan : .secondary)
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(model.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 8)
        }
    }

    private var metadataLine: some View {
        HStack(spacing: 8) {
            Label {
                Text(verbatim: dateText)
            } icon: {
                Image(systemName: "calendar")
            }
            Label {
                Text(LocalizedStringKey(model.sportModeKey))
            } icon: {
                Image(systemName: "figure.skating")
            }
            Label {
                Text(LocalizedStringKey(model.powerTypeKey))
            } icon: {
                Image(systemName: "bolt")
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var metricsLine: some View {
        HStack(spacing: 10) {
            metricPill(text: distanceText, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            metricPill(text: speedText, systemImage: "speedometer")
            metricPill(text: sampleText, systemImage: "waveform.path.ecg.rectangle")
        }
    }

    private func metricPill(text: String, systemImage: String) -> some View {
        Label {
            Text(verbatim: text)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption2.monospacedDigit().weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(isSelected ? 0.12 : 0.065), in: Capsule())
            .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isSelected ? Color.cyan.opacity(0.14) : Color.white.opacity(0.045))
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(isSelected ? Color.cyan.opacity(0.52) : Color.white.opacity(0.08), lineWidth: 1)
    }

    private var dateText: String {
        Self.dateFormatter.string(from: model.startDate)
    }

    private var distanceText: String {
        String(format: String(localized: "mac.package.preview.distance.format"), model.displayMetrics.distanceKilometers)
    }

    private var speedText: String {
        String(format: String(localized: "mac.package.preview.speed.format"), model.displayMetrics.maxSpeedKilometersPerHour)
    }

    private var sampleText: String {
        String(
            format: String(localized: "mac.viewer.sessions.sample_count.format"),
            model.motionSampleCount,
            model.routeSampleCount
        )
    }

    private var selectionText: String {
        isSelected ? String(localized: "mac.viewer.sessions.card.selected") : String(localized: "mac.viewer.sessions.card.not_selected")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
