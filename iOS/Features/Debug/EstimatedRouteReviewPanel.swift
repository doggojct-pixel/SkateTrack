// [協作區] iOS/Features/Debug/EstimatedRouteReviewPanel.swift
// 用途：提供 b18-C DEBUG-only estimated route review panel，僅呈現 review-only artifact 文字資訊。
// 委派至：EstimatedRouteReviewOverlay 與 b18 product decision checkpoint。

#if DEBUG
import Foundation
import SwiftUI

struct EstimatedRouteReviewPanel: View {
    let overlay: EstimatedRouteReviewOverlay

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                safetyFlagsSection
                recordSummarySection
            }
            .padding(18)
        }
        .background(Color(.systemBackground))
        .navigationTitle(LocalizedStringKey("debug.estimatedRouteReview.title"))
        .accessibilityIdentifier("debug-estimated-route-review-panel")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            localized("debug.estimatedRouteReview.title")
                .font(.title2.weight(.bold))
            localized("debug.estimatedRouteReview.subtitle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(verbatim: overlay.taskIdentifier)
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("debug-estimated-route-review-task-id")
        }
    }

    private var safetyFlagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            localized("debug.estimatedRouteReview.safetyFlags")
                .font(.headline)
            flagRow("debug.estimatedRouteReview.routeGeometryDisabled", isSafe: !overlay.routeGeometryIncluded)
            flagRow("debug.estimatedRouteReview.userVisibleDisplayDisabled", isSafe: !overlay.userVisibleDisplayAllowed)
            flagRow("debug.estimatedRouteReview.trustedMetricsDisabled", isSafe: !overlay.trustedMetricsMutationApplied)
            flagRow("debug.estimatedRouteReview.persistenceDisabled", isSafe: !overlay.persistedOverlayApplied)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("debug-estimated-route-review-safety-flags")
    }

    private var recordSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                localized("debug.estimatedRouteReview.records")
                    .font(.headline)
                Spacer()
                Text(verbatim: "\(overlay.records.count)")
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("debug-estimated-route-review-record-count")
            }

            if overlay.records.isEmpty {
                localized("debug.estimatedRouteReview.empty")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(overlay.records.enumerated()), id: \.offset) { index, record in
                    recordRow(record, index: index)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("debug-estimated-route-review-records")
    }

    private func recordRow(_ record: EstimatedRouteReviewOverlayRecord, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: record.sessionReviewRole ?? record.sessionIdentifier)
                        .font(.subheadline.weight(.bold))
                    Text(verbatim: record.sessionIdentifier)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 10)
                Text(verbatim: record.decisionState.rawValue)
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            labeledValue("debug.estimatedRouteReview.disposition", value: record.reviewDisposition)
            labeledValue("debug.estimatedRouteReview.gapDuration", value: formattedSeconds(record.gapDurationSeconds))
            labeledValue("debug.estimatedRouteReview.blockingReasons", value: formattedReasons(record.blockingReasons))
            flagRow("debug.estimatedRouteReview.recordUserVisibleDisabled", isSafe: !record.userVisibleDisplayAllowed)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("debug-estimated-route-review-record-\(index)")
    }

    private func flagRow(_ key: String, isSafe: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isSafe ? "checkmark.shield.fill" : "xmark.octagon.fill")
                .foregroundStyle(isSafe ? .green : .red)
            localized(key)
                .font(.caption.weight(.semibold))
            Spacer()
            Text(verbatim: isSafe ? "false" : "true")
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private func labeledValue(_ key: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            localized(key)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func formattedSeconds(_ value: TimeInterval) -> String {
        String(format: "%.1fs", value)
    }

    private func formattedReasons(_ reasons: [String]) -> String {
        reasons.isEmpty ? "—" : reasons.joined(separator: "; ")
    }

    private func localized(_ key: String) -> Text {
        Text(LocalizedStringKey(key))
    }
}
#endif
