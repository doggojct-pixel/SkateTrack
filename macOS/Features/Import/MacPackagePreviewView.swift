// [協作區] MacPackagePreviewView.swift
// 用途：顯示 .skatetrack package manifest 與單筆 session 只讀摘要。
// 委派至：Task-028 完整 macOS viewer；本檔不做圖表、地圖、merge 或資料庫 import。

import Foundation
import SwiftUI

struct MacPackagePreviewView: View {
    let preview: MacPackageImportPreview

    private var summaryMetrics: SessionSummaryMetrics? {
        preview.primarySession?.summaryMetrics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            manifestSection
            sessionSection
            privacySection
            lockedNextSteps
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("mac.package.preview.valid")
                    .font(.headline)
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            Text(preview.primaryTitle)
                .font(.largeTitle.bold())

            Text(preview.fileName)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var manifestSection: some View {
        MacPreviewSection(titleKey: "mac.package.preview.manifest.title", systemImage: "doc.text.magnifyingglass") {
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                MacPreviewMetric(titleKey: "mac.package.preview.schema", value: "\(preview.manifest.schemaVersion)")
                MacPreviewMetric(titleKey: "mac.package.preview.package_type", value: preview.manifest.packageType.rawValue)
                MacPreviewMetric(titleKey: "mac.package.preview.app_version", value: preview.manifest.appVersion)
                MacPreviewMetric(titleKey: "mac.package.preview.build", value: preview.manifest.buildNumber)
                MacPreviewMetric(titleKey: "mac.package.preview.created", value: formattedDate(preview.manifest.createdAt))
                MacPreviewMetric(titleKey: "mac.package.preview.locale", value: preview.manifest.localeIdentifier)
            }
        }
    }

    private var sessionSection: some View {
        MacPreviewSection(titleKey: "mac.package.preview.session.title", systemImage: "figure.skating") {
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                MacPreviewMetric(titleKey: "mac.package.preview.sessions", value: "\(preview.sessionCount)")
                MacPreviewMetric(titleKey: "mac.package.preview.motion_samples", value: "\(preview.motionSampleCount)")
                MacPreviewMetric(titleKey: "mac.package.preview.route_samples", value: "\(preview.routeSampleCount)")
                MacPreviewMetric(titleKey: "mac.package.preview.duration", value: formattedDuration(preview.primarySession?.durationSeconds))
                MacPreviewMetric(titleKey: "mac.package.preview.distance", value: formattedDistance(summaryMetrics?.distanceKilometers))
                MacPreviewMetric(titleKey: "mac.package.preview.max_speed", value: formattedSpeed(summaryMetrics?.maxSpeedKilometersPerHour))
                MacPreviewMetric(titleKey: "mac.package.preview.average_speed", value: formattedSpeed(summaryMetrics?.averageSpeedKilometersPerHour))
                MacPreviewMetric(titleKey: "mac.package.preview.moving_ratio", value: formattedPercent(summaryMetrics?.movingRatio))
                MacPreviewMetric(titleKey: "mac.package.preview.exported", value: formattedOptionalDate(preview.exportedAt))
            }

            if preview.routeSampleCount > 0 {
                Label("mac.package.preview.route_available", systemImage: "map.fill")
                    .font(.callout)
                    .foregroundStyle(.cyan)
            } else {
                Label("mac.package.preview.route_unavailable", systemImage: "map")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var privacySection: some View {
        MacPreviewSection(titleKey: "mac.package.preview.privacy.title", systemImage: "hand.raised.fill") {
            Label("mac.package.preview.privacy.boundary", systemImage: "lock.shield")
                .font(.callout)
                .foregroundStyle(.secondary)

            if !preview.privacyNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(preview.privacyNotes, id: \.self) { note in
                        Text("• \(note)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var lockedNextSteps: some View {
        MacLockedFeatureCardView(
            titleKey: "mac.package.preview.locked.viewer.title",
            subtitleKey: "mac.package.preview.locked.viewer.subtitle",
            systemImage: "chart.bar.doc.horizontal"
        )
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 190), spacing: 12)]
    }

    private func formattedDate(_ date: Date) -> String {
        Self.dateTimeFormatter.string(from: date)
    }

    private func formattedOptionalDate(_ date: Date?) -> String {
        guard let date else { return String(localized: "mac.package.preview.value.none") }
        return formattedDate(date)
    }

    private func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else { return String(localized: "mac.package.preview.value.none") }
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: String(localized: "mac.package.preview.duration.format"), minutes, seconds)
    }

    private func formattedDistance(_ distance: Double?) -> String {
        guard let distance else { return String(localized: "mac.package.preview.value.none") }
        return String(format: String(localized: "mac.package.preview.distance.format"), distance)
    }

    private func formattedSpeed(_ speed: Double?) -> String {
        guard let speed else { return String(localized: "mac.package.preview.value.none") }
        return String(format: String(localized: "mac.package.preview.speed.format"), speed)
    }

    private func formattedPercent(_ ratio: Double?) -> String {
        guard let ratio else { return String(localized: "mac.package.preview.value.none") }
        return String(format: String(localized: "mac.package.preview.percent.format"), ratio * 100)
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct MacPreviewSection<Content: View>: View {
    let titleKey: String
    let systemImage: String
    private let content: Content

    init(titleKey: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text(LocalizedStringKey(titleKey))
            } icon: {
                Image(systemName: systemImage)
            }
            .font(.title3.bold())
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MacPreviewMetric: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
