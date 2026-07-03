// [協作區] SessionSummaryHandoffView.swift
// 用途：作為 Task-017b 的 History-to-Summary 銜接畫面，先呈現已選 Session 摘要與 Task-018 交接提示。
// 委派至：Task-018 Session Summary 實作真正路線、圖表與詳細分析。

import SwiftUI

struct SessionSummaryHandoffView: View {
    let session: SessionData
    let onClose: () -> Void

    private var metrics: SessionSummaryMetrics { SessionSummaryDisplayMetrics.make(session: session, samples: session.motionSamples) }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    dragHandle
                    header
                    sessionIdentityCard
                    metricGrid
                    nextTaskNotice
                    closeButton
                }
                .padding(.horizontal, 22)
                .padding(.top, max(18, proxy.safeAreaInsets.top + 10))
                .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 18))
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(background.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("session-summary-handoff-view")
    }

    private var background: some View {
        ZStack {
            SkateTrackSessionStartColors.navy

            RadialGradient(
                colors: [SkateTrackSessionStartColors.teal.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 380
            )
        }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(SkateTrackSessionStartColors.border)
            .frame(width: 46, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("history.summary.handoff.title")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("history.summary.handoff.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("session-summary-handoff-header")
    }

    private var sessionIdentityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(LocalizedStringKey(session.sportMode.modeLocalizationKey))
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(dateLine)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                }

                Spacer()

                Text(LocalizedStringKey(session.powerType.localizationKey))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(accentColor.opacity(0.16))
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("session-summary-handoff-identity")
    }

    private var metricGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                metricTile(value: distanceText, labelKey: "history.summary.handoff.distance")
                metricTile(value: maxSpeedText, labelKey: "history.summary.handoff.maxSpeed")
            }

            HStack(spacing: 10) {
                metricTile(value: durationText, labelKey: "history.summary.handoff.duration")
                metricTile(value: averageSpeedText, labelKey: "history.summary.handoff.avgSpeed")
            }
        }
        .accessibilityIdentifier("session-summary-handoff-metrics")
    }

    private func metricTile(value: String, labelKey: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .tracking(0.9)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var nextTaskNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("history.summary.handoff.nextTaskTitle")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)

            Text("history.summary.handoff.nextTaskSubtitle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(SkateTrackSessionStartColors.card.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityIdentifier("session-summary-handoff-next-task")
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Text("history.summary.handoff.close")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(SkateTrackSessionStartColors.teal.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("session-summary-handoff-close")
    }

    private var accentColor: Color {
        switch session.sportMode {
        case .skateboard:
            return session.powerType == .electric ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        }
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.startDate)
    }

    private var distanceText: String {
        UnitFormatter.distance(meters: metrics.distanceKilometers * 1_000, maximumFractionDigits: 2)
    }

    private var maxSpeedText: String {
        String(format: "%.1f km/h", metrics.maxSpeedKilometersPerHour)
    }

    private var averageSpeedText: String {
        String(format: "%.1f km/h", metrics.averageSpeedKilometersPerHour)
    }

    private var durationText: String {
        guard let duration = session.durationSeconds else {
            return NSLocalizedString("general.value.unavailable", comment: "")
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3_600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? NSLocalizedString("general.value.unavailable", comment: "")
    }
}
