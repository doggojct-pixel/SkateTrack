// [協作區] SessionSummaryView.swift
// 用途：建立 Task-018a/018b/018c 的 Session Summary，顯示核心指標、路線、安全狀態與進階圖表門禁。
// 委派至：useSessionSummary 讀取 Repository；useSubscriptionStatus / FeatureFlagEngine 處理進階圖表付費門禁。

import SwiftUI

struct SessionSummaryView: View {
    let sessionID: UUID
    let onClose: () -> Void

    @StateObject private var summary: SessionSummaryViewModel
    @ObservedObject private var subscriptionStatus: SubscriptionStatusViewModel
    @State private var isAdvancedChartsPaywallPresented = false

    @MainActor
    init(
        sessionID: UUID,
        initialSession: SessionData? = nil,
        subscriptionStatus: SubscriptionStatusViewModel,
        onClose: @escaping () -> Void
    ) {
        self.sessionID = sessionID
        self.onClose = onClose
        self.subscriptionStatus = subscriptionStatus
        _summary = StateObject(
            wrappedValue: useSessionSummary(sessionID: sessionID, initialSession: initialSession)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    dragHandle

                    switch summary.viewState {
                    case .loading:
                        loadingState
                    case let .error(errorKey):
                        errorState(errorKey)
                    case let .content(content):
                        contentView(content)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, max(18, proxy.safeAreaInsets.top + 10))
                .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 18))
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(background.ignoresSafeArea())
            .refreshable { await summary.reload() }
        }
        .preferredColorScheme(.dark)
        .task { await summary.loadIfNeeded() }
        .sheet(isPresented: $isAdvancedChartsPaywallPresented) {
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: .advancedCharts
            )
        }
        .accessibilityIdentifier("session-summary-view")
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

    private func contentView(_ content: SessionSummaryContent) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            header(content)
            identityCard(content)
            if shouldShowEquipmentAttribution(for: content.session) {
                SessionEquipmentAttributionView(session: content.session)
            }
            SessionSummaryMetricsGridView(items: metricItems(for: content))
            summaryDetailStack(content)
            closeButton
        }
    }

    private func header(_ content: SessionSummaryContent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("summary.title")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("summary.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("session-summary-header")
    }

    private func identityCard(_ content: SessionSummaryContent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(content.session.sportMode.modeLocalizationKey))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(dateLine(for: content.session))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
            }

            Spacer()

            Text(LocalizedStringKey(content.session.powerType.localizationKey))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(accentColor(for: content.session))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(accentColor(for: content.session).opacity(0.16))
                .clipShape(Capsule())
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("session-summary-identity")
    }

    private func summaryDetailStack(_ content: SessionSummaryContent) -> some View {
        VStack(spacing: 10) {
            SessionRouteMapView(samples: content.motionSamples)
            SessionSummarySafetyStatusView(content: content)

            SessionAdvancedChartsView(
                content: content,
                subscriptionStatus: subscriptionStatus,
                onUnlock: { isAdvancedChartsPaywallPresented = true }
            )

            SessionSummaryShareStubView()
        }
        .accessibilityIdentifier("session-summary-detail-stack")
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(SkateTrackSessionStartColors.teal)
            Text("summary.loading")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
        .accessibilityIdentifier("session-summary-loading")
    }

    private func errorState(_ errorKey: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("summary.error.title")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(LocalizedStringKey(errorKey))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)

            Button { Task { await summary.reload() } } label: {
                Text("summary.retry")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(SkateTrackSessionStartColors.accent.opacity(0.82))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            closeButton
        }
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("session-summary-error")
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Text("summary.close")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(SkateTrackSessionStartColors.teal.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("session-summary-close")
    }
}

private extension SessionSummaryView {

    func shouldShowEquipmentAttribution(for session: SessionData) -> Bool {
        session.equipmentSnapshot != nil || session.equipmentID != nil
    }

    func metricItems(for content: SessionSummaryContent) -> [SessionSummaryMetricItem] {
        [
            .init(id: "distance", value: distanceText(content.metrics), labelKey: "summary.metric.distance", accent: SkateTrackSessionStartColors.teal),
            .init(id: "duration", value: durationText(content.session), labelKey: "summary.metric.duration", accent: .white),
            .init(id: "maxSpeed", value: speedText(content.metrics.maxSpeedKilometersPerHour), labelKey: "summary.metric.maxSpeed", accent: SkateTrackSessionStartColors.purple),
            .init(id: "avgSpeed", value: speedText(content.metrics.averageSpeedKilometersPerHour), labelKey: "summary.metric.avgSpeed", accent: .white),
            .init(id: "elevation", value: elevationText(content.metrics.elevationGainMeters), labelKey: "summary.metric.elevationGain", accent: SkateTrackSessionStartColors.amber),
            .init(id: "moving", value: percentText(content.metrics.movingRatio), labelKey: "summary.metric.movingRatio", accent: .white),
            .init(id: "falls", value: "\(content.fallCount)", labelKey: "summary.metric.falls", accent: content.fallCount > 0 ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal),
            .init(id: "tricks", value: "\(content.trickCount)", labelKey: "summary.metric.tricks", accent: .white)
        ]
    }

    func dateLine(for session: SessionData) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.startDate)
    }

    func distanceText(_ metrics: SessionSummaryMetrics) -> String {
        UnitFormatter.distance(meters: metrics.distanceKilometers * 1_000, maximumFractionDigits: 2)
    }

    func speedText(_ value: Double) -> String {
        guard value.isFinite else { return unavailableText }
        let format = NSLocalizedString("unit.speed.kmh.valueFormat", comment: "")
        let unit = NSLocalizedString("unit.speed.kmh.short", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, value, unit)
    }

    func elevationText(_ meters: Double) -> String {
        guard meters.isFinite else { return unavailableText }
        let format = NSLocalizedString("unit.length.meter.valueFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, meters)
    }

    func percentText(_ value: Double) -> String {
        guard value.isFinite else { return unavailableText }
        return String(format: "%.0f%%", min(max(value, 0), 1) * 100)
    }

    func durationText(_ session: SessionData) -> String {
        guard let duration = session.durationSeconds else { return unavailableText }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3_600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? unavailableText
    }

    var unavailableText: String {
        NSLocalizedString("general.value.unavailable", comment: "")
    }

    func accentColor(for session: SessionData) -> Color {
        switch session.sportMode {
        case .skateboard:
            return session.powerType == .electric ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.accent
        case .inline:
            return SkateTrackSessionStartColors.purple
        }
    }
}

#Preview("Session Summary") {
    if let session = try? SessionData(
        startDate: Date().addingTimeInterval(-1_800),
        endDate: Date(),
        sportMode: .skateboard(.streetPark),
        summaryMetrics: .zero
    ) {
        SessionSummaryView(
            sessionID: session.id,
            initialSession: session,
            subscriptionStatus: useSubscriptionStatus()
        ) {}
    }
}
