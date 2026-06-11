// [協作區] SessionHistoryView.swift
// 用途：建立 iOS Session History 主畫面，讀取本機 Repository 並套用免費 5 筆限制。
// 委派至：useSessionHistory 查詢/分組，Task-016b Paywall 處理受限舊紀錄升級流程。

import SwiftUI

struct SessionHistoryView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @StateObject private var history: SessionHistoryViewModel
    @State private var isPaywallPresented = false
    @State private var selectedPreviewSession: SessionData?

    @MainActor
    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        history: SessionHistoryViewModel? = nil
    ) {
        self.subscriptionStatus = subscriptionStatus
        let resolvedHistory = history ?? SessionHistoryViewModel()
        _history = StateObject(wrappedValue: resolvedHistory)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                            .padding(.top, proxy.safeAreaInsets.top + 22)
                            .padding(.horizontal, 20)

                        weeklySummary
                            .padding(.horizontal, 20)

                        SessionHistoryFilterBar(
                            selectedFilter: $history.selectedFilter,
                            accentColor: SkateTrackSessionStartColors.teal
                        )

                        content
                            .padding(.horizontal, 20)
                            .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 24))
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .refreshable {
                    await history.reload()
                }
            }
        }
        .background(SkateTrackSessionStartColors.navy)
        .preferredColorScheme(.dark)
        .task {
            await history.loadIfNeeded()
        }
        .sheet(isPresented: $isPaywallPresented) {
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: .unlimitedHistory
            )
        }
        .sheet(item: $selectedPreviewSession) { session in
            summaryPlaceholder(for: session)
        }
        .accessibilityIdentifier("session-history-view")
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SkateTrackSessionStartColors.navy3,
                    SkateTrackSessionStartColors.navy2,
                    SkateTrackSessionStartColors.navy
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [SkateTrackSessionStartColors.teal.opacity(0.26), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("history.title")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("history.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("history-header")
    }

    private var weeklySummary: some View {
        HStack(spacing: 10) {
            summaryTile(
                value: weeklyDistanceText,
                labelKey: "history.totalDistance",
                eyebrowKey: "history.thisWeek",
                accentColor: SkateTrackSessionStartColors.teal
            )

            summaryTile(
                value: "\(history.totalSessionCount)",
                labelKey: "history.totalSessions",
                eyebrowKey: "history.allTime",
                accentColor: SkateTrackSessionStartColors.purple
            )
        }
        .accessibilityIdentifier("history-weekly-summary")
    }

    private func summaryTile(
        value: String,
        labelKey: String,
        eyebrowKey: String,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStringKey(eyebrowKey))
                .tracking(1.2)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(SkateTrackSessionStartColors.textTertiary)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
    }

    @ViewBuilder
    private var content: some View {
        switch history.viewState {
        case .loading:
            loadingState
        case .empty:
            emptyState
        case let .error(errorKey):
            errorState(errorKey)
        case .content:
            historyContent
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(SkateTrackSessionStartColors.teal)
            Text("history.loading")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .accessibilityIdentifier("history-loading-state")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(SkateTrackSessionStartColors.teal)

            Text("history.empty.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("history.empty.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("history-empty-state")
    }

    private func errorState(_ errorKey: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("history.error.title")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(LocalizedStringKey(errorKey))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)

            Button {
                Task { await history.reload() }
            } label: {
                Text("history.retry")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(SkateTrackSessionStartColors.accent.opacity(0.82))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("history-error-state")
    }

    @ViewBuilder
    private var historyContent: some View {
        let sections = history.groupedSections(isSubscriber: subscriptionStatus.isSubscriber)
        let lockedCount = history.lockedSessionCount(isSubscriber: subscriptionStatus.isSubscriber)

        if sections.isEmpty {
            filteredEmptyState
        } else {
            VStack(alignment: .leading, spacing: 14) {
                if history.hasAccessibleHistoryLimit(isSubscriber: subscriptionStatus.isSubscriber) {
                    HistoryLimitPaywallBanner(lockedCount: lockedCount) {
                        isPaywallPresented = true
                    }
                }

                SessionHistoryListView(sections: sections) { entry in
                    handleEntryTap(entry)
                }
            }
        }
    }

    private var filteredEmptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("history.filtered.empty.title")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("history.filtered.empty.subtitle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(SkateTrackSessionStartColors.card.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("history-filtered-empty-state")
    }

    private var weeklyDistanceText: String {
        UnitFormatter.distance(meters: history.weeklyDistanceKilometers * 1_000, maximumFractionDigits: 2)
    }

    private func handleEntryTap(_ entry: SessionHistoryEntry) {
        if entry.isLocked {
            isPaywallPresented = true
        } else {
            selectedPreviewSession = entry.session
        }
    }

    private func summaryPlaceholder(for session: SessionData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule()
                .fill(SkateTrackSessionStartColors.border)
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)

            Text("history.summary.placeholder.title")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(LocalizedStringKey(session.sportMode.modeLocalizationKey))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.teal)

            Text("history.summary.placeholder.subtitle")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("history.summary.placeholder.close") {
                selectedPreviewSession = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(SkateTrackSessionStartColors.teal)
            .padding(.top, 6)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SkateTrackSessionStartColors.navy.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview("History") {
    SessionHistoryView(subscriptionStatus: useSubscriptionStatus())
}
