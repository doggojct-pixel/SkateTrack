// [協作區] SessionHistoryView.swift
// 用途：建立 iOS Session History 主畫面，讀取本機 Repository 並套用免費 5 筆限制。
// 委派至：useSessionHistory 查詢/分組，Task-016b Paywall 處理受限舊紀錄升級流程。

import SwiftUI

struct SessionHistoryView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @StateObject private var history: SessionHistoryViewModel
    @State private var isPaywallPresented = false
    @State private var selectedSummarySession: SessionData?
    @State private var isSelectionMode = false
    @State private var selectedSessionIDs: Set<UUID> = []
    @State private var isDeleteConfirmationPresented = false
    @State private var deletionErrorKey: String?

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
                        .onChange(of: history.selectedFilter) { _, _ in
                            selectedSessionIDs.removeAll()
                        }

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
            // Task-030c-b15-B-3: always refresh when History becomes visible so a
            // just-saved simulator/debug recording is not hidden by a stale cached list.
            await history.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .skateTrackSessionDidSave)) { _ in
            Task { await history.reload() }
        }
        .sheet(isPresented: $isPaywallPresented) {
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: .unlimitedHistory
            )
        }
        .sheet(item: $selectedSummarySession) { session in
            SessionSummaryView(
                sessionID: session.id,
                initialSession: session,
                subscriptionStatus: subscriptionStatus
            ) {
                selectedSummarySession = nil
            }
        }
        .confirmationDialog(
            "history.delete.confirm.title",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                Task { await deleteSelectedSessions() }
            } label: {
                Text(deleteConfirmationButtonText)
            }
            Button("general.cancel", role: .cancel) {}
        } message: {
            Text(deleteConfirmationMessageText)
        }
        .alert("history.delete.error.title", isPresented: deletionErrorBinding) {
            Button("general.ok", role: .cancel) { deletionErrorKey = nil }
        } message: {
            if let deletionErrorKey {
                Text(LocalizedStringKey(deletionErrorKey))
            }
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
            HStack(alignment: .firstTextBaseline) {
                Text("history.title")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                if history.filteredSessionCount > 0 {
                    Button {
                        toggleSelectionMode()
                    } label: {
                        Text(LocalizedStringKey(isSelectionMode ? "history.selection.cancel" : "history.selection.start"))
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(isSelectionMode ? SkateTrackSessionStartColors.amber : SkateTrackSessionStartColors.teal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("history-selection-toggle")
                }
            }

            Text(LocalizedStringKey(isSelectionMode ? "history.selection.mode.subtitle" : "history.subtitle"))
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

                if isSelectionMode {
                    SessionHistoryBulkActionBarView(
                        selectedCount: selectedSessionIDs.count,
                        visibleCount: visibleSessionIDs.count,
                        onSelectAll: selectAllVisibleSessions,
                        onClearSelection: { selectedSessionIDs.removeAll() },
                        onDelete: { isDeleteConfirmationPresented = selectedSessionIDs.isEmpty == false }
                    )
                }

                SessionHistoryListView(
                    sections: sections,
                    isSelectionMode: isSelectionMode,
                    selectedSessionIDs: selectedSessionIDs,
                    onEntryTap: handleEntryTap,
                    onToggleSelection: toggleSessionSelection
                )
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

    private var visibleSessionIDs: [UUID] {
        history.visibleSessionIDs(isSubscriber: subscriptionStatus.isSubscriber)
    }

    private var deleteConfirmationButtonText: String {
        let format = NSLocalizedString("history.delete.confirm.buttonFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, selectedSessionIDs.count)
    }

    private var deleteConfirmationMessageText: String {
        let format = NSLocalizedString("history.delete.confirm.messageFormat", comment: "")
        return String(format: format, locale: .autoupdatingCurrent, selectedSessionIDs.count)
    }

    private var deletionErrorBinding: Binding<Bool> {
        Binding(
            get: { deletionErrorKey != nil },
            set: { if $0 == false { deletionErrorKey = nil } }
        )
    }

    private func handleEntryTap(_ entry: SessionHistoryEntry) {
        if isSelectionMode {
            toggleSessionSelection(entry)
        } else if entry.isLocked {
            isPaywallPresented = true
        } else {
            selectedSummarySession = entry.session
        }
    }

    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        selectedSessionIDs.removeAll()
    }

    private func toggleSessionSelection(_ entry: SessionHistoryEntry) {
        if selectedSessionIDs.contains(entry.session.id) {
            selectedSessionIDs.remove(entry.session.id)
        } else {
            selectedSessionIDs.insert(entry.session.id)
        }
    }

    private func selectAllVisibleSessions() {
        selectedSessionIDs = Set(visibleSessionIDs)
    }

    private func deleteSelectedSessions() async {
        do {
            try await history.deleteSessions(ids: selectedSessionIDs)
            selectedSessionIDs.removeAll()
            isSelectionMode = false
        } catch let error as RepositoryError {
            deletionErrorKey = error.localizationKey
        } catch {
            deletionErrorKey = "history.delete.error.generic"
        }
    }
}

#Preview("History") {
    SessionHistoryView(subscriptionStatus: useSubscriptionStatus())
}
