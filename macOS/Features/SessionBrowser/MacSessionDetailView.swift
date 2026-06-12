// [協作區] MacSessionDetailView.swift
// 用途：顯示 macOS 只讀 Session viewer 的 session detail、derived metrics、速度預覽與 route summary。
// 委派至：Task-028b Route / Chart Visualization；本檔不寫入資料庫、不執行 merge / restore。

import SwiftUI

struct MacSessionDetailView: View {
    let model: MacSessionViewerModel
    let packageFileName: String

    private var compactGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 172), spacing: 12)]
    }

    private var routeGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 180), spacing: 10)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailTitleBar
            metricsSection
            visualizationSection
            routeDataSection
            privacySection
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var detailTitleBar: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label("mac.viewer.detail.title", systemImage: "rectangle.grid.2x2")
                .font(.headline.bold())
            Spacer(minLength: 12)
            Text(packageFileName)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 320, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private var visualizationColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 360), spacing: 16)]
    }

    private var metricsSection: some View {
        MacSessionViewerSection(titleKey: "mac.viewer.metrics.title", systemImage: "speedometer") {
            LazyVGrid(columns: compactGridColumns, alignment: .leading, spacing: 12) {
                MacSessionViewerMetric(titleKey: "mac.package.preview.duration", value: formattedDuration(model.durationSeconds))
                MacSessionViewerMetric(titleKey: "mac.package.preview.distance", value: formattedDistance(model.displayMetrics.distanceKilometers))
                MacSessionViewerMetric(titleKey: "mac.package.preview.max_speed", value: formattedSpeed(model.displayMetrics.maxSpeedKilometersPerHour))
                MacSessionViewerMetric(titleKey: "mac.package.preview.average_speed", value: formattedSpeed(model.displayMetrics.averageSpeedKilometersPerHour))
                MacSessionViewerMetric(titleKey: "mac.package.preview.moving_ratio", value: formattedPercent(model.displayMetrics.movingRatio))
                MacSessionViewerMetric(titleKey: "mac.package.preview.motion_samples", value: "\(model.motionSampleCount)")
                MacSessionViewerMetric(titleKey: "mac.package.preview.route_samples", value: "\(model.routeSampleCount)")
                MacSessionViewerMetric(titleKey: "mac.package.preview.exported", value: formattedDate(model.exportedAt))
            }

            if model.usesDerivedMetrics {
                Label("mac.viewer.metrics.derived_notice", systemImage: "function")
                    .font(.caption)
                    .foregroundStyle(.cyan)
            }
        }
    }

    private var visualizationSection: some View {
        LazyVGrid(columns: visualizationColumns, alignment: .leading, spacing: 16) {
            MacRoutePreviewView(points: model.routePoints, summary: model.routeSummary)
            MacSpeedSparklineView(points: model.speedPoints)
        }
    }

    private var routeDataSection: some View {
        MacSessionViewerSection(titleKey: "mac.viewer.route.data.title", systemImage: "point.topleft.down.curvedto.point.bottomright.up") {
            if model.hasRoute {
                LazyVGrid(columns: routeGridColumns, alignment: .leading, spacing: 10) {
                    MacSessionViewerMetric(titleKey: "mac.viewer.route.points", value: "\(model.routeSummary.routePointCount)")
                    MacSessionViewerMetric(titleKey: "mac.viewer.route.unique_points", value: "\(model.routeSummary.uniqueRoutePointCount)")
                    MacSessionViewerMetric(titleKey: "mac.viewer.route.derived_distance", value: formattedDistance(model.routeSummary.derivedDistanceKilometers))
                    MacSessionViewerMetric(titleKey: "mac.viewer.route.start", value: formattedCoordinate(model.routeSummary.startCoordinate))
                    MacSessionViewerMetric(titleKey: "mac.viewer.route.finish", value: formattedCoordinate(model.routeSummary.finishCoordinate))
                }
                Label("mac.viewer.route.map_deferred", systemImage: "map")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("mac.package.preview.route_unavailable", systemImage: "map")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var privacySection: some View {
        MacSessionViewerSection(titleKey: "mac.package.preview.privacy.title", systemImage: "hand.raised.fill") {
            Label("mac.viewer.privacy.readonly", systemImage: "lock")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !model.privacyNotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.privacyNotes, id: \.self) { note in
                        Text("• \(note)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        Self.dateTimeFormatter.string(from: date)
    }

    private func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else { return String(localized: "mac.package.preview.value.none") }
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: String(localized: "mac.package.preview.duration.format"), minutes, seconds)
    }

    private func formattedDistance(_ distance: Double) -> String {
        String(format: String(localized: "mac.package.preview.distance.format"), distance)
    }

    private func formattedSpeed(_ speed: Double) -> String {
        String(format: String(localized: "mac.package.preview.speed.format"), speed)
    }

    private func formattedPercent(_ ratio: Double) -> String {
        String(format: String(localized: "mac.package.preview.percent.format"), ratio * 100)
    }

    private func formattedCoordinate(_ coordinate: GeoCoordinate?) -> String {
        guard let coordinate else { return String(localized: "mac.package.preview.value.none") }
        return String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct MacSessionViewerSection<Content: View>: View {
    let titleKey: String
    let systemImage: String
    private let content: Content

    init(titleKey: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(LocalizedStringKey(titleKey))
            } icon: {
                Image(systemName: systemImage)
            }
            .font(.headline.bold())
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MacSessionViewerMetric: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStringKey(titleKey))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(value)
                .font(.callout.weight(.semibold).monospacedDigit())
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
