// [協作區] SpotListView.swift
// 用途：Spot Management Foundation 的主畫面，提供本機場地列表、地圖、CRUD 與 favorite limit。
// 委派至：useSpots / SpotRepository；不接 天氣服務、外部服務、公開場地資料庫或定位權限。

import SwiftUI

enum SpotDisplayMode: String, CaseIterable, Identifiable {
    case list
    case map

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .list: return "spots.list"
        case .map: return "spots.map"
        }
    }
}

struct SpotListView: View {
    @ObservedObject var subscriptionStatus: SubscriptionStatusViewModel
    @Binding var isDetailPresented: Bool
    @StateObject private var viewModel: SpotsViewModel
    @StateObject private var weatherRisk: WeatherRiskViewModel
    @State private var displayMode: SpotDisplayMode = .list
    @State private var selectedSpot: SpotProfile?
    @State private var isEditorPresented = false
    @State private var isHealthReminderSettingsPresented = false
    private let rideabilityEngine = WeatherRideabilityEngine()

    init(
        subscriptionStatus: SubscriptionStatusViewModel,
        isDetailPresented: Binding<Bool>
    ) {
        self.subscriptionStatus = subscriptionStatus
        self._isDetailPresented = isDetailPresented
        _viewModel = StateObject(wrappedValue: useSpots(subscriptionStatus: subscriptionStatus))
        _weatherRisk = StateObject(wrappedValue: useWeatherRisk(subscriptionStatus: subscriptionStatus))
    }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            if let selectedSpot {
                SpotDetailView(
                    spot: selectedSpot,
                    weatherRisk: weatherRisk,
                    onBack: closeDetail,
                    onToggleFavorite: { await toggleFavoriteAndRefreshSelection(selectedSpot) },
                    onSave: saveFromDetail,
                    onDelete: deleteSelectedSpot,
                    onOpenHealthReminders: { isHealthReminderSettingsPresented = true }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(5)
            } else {
                content
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isEditorPresented) {
            SpotEditorView(onSave: saveNewSpot)
        }
        .sheet(item: $viewModel.paywallFeature) { feature in
            SubscriptionPaywallView(
                subscriptionStatus: subscriptionStatus,
                lockedFeature: feature
            )
        }
        .sheet(isPresented: $isHealthReminderSettingsPresented) {
            HealthReminderSettingsView(subscriptionStatus: subscriptionStatus)
        }
        .task {
            await viewModel.refresh()
            weatherRisk.updateContext(.rideStart(), spot: nil)
            weatherRisk.refresh()
        }
        .onChange(of: selectedSpot) { _, newValue in
            isDetailPresented = newValue != nil
        }
        .onChange(of: subscriptionStatus.isSubscriber) { _, _ in
            Task { await viewModel.refresh() }
        }
        .accessibilityIdentifier("spots-root-view")
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                SpotFavoriteLimitBanner(
                    favoriteCount: viewModel.favoriteCount,
                    favoriteLimit: SpotsViewModel.freeFavoriteLimit,
                    hasUnlimitedAccess: viewModel.hasUnlimitedFavoriteAccess,
                    onUnlock: { viewModel.paywallFeature = .spotManagement }
                )
                modePicker
                errorMessage
                bodyContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 88)
            .padding(.bottom, 36)
        }
        .refreshable { await viewModel.refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("spots.eyebrow")
                .tracking(2)
                .font(.caption.weight(.black))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline) {
                Text("spots.title")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button { isEditorPresented = true } label: {
                    Label("spots.add", systemImage: "plus")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(SkateTrackSessionStartColors.teal.opacity(0.80))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("spots-add-button")
            }

            Text("spots.subtitle")
                .font(.subheadline)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(SpotDisplayMode.allCases) { mode in
                Button { displayMode = mode } label: {
                    Text(LocalizedStringKey(mode.localizationKey))
                        .font(.caption.weight(.black))
                        .foregroundStyle(displayMode == mode ? .white : SkateTrackSessionStartColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(displayMode == mode ? SkateTrackSessionStartColors.teal.opacity(0.30) : SkateTrackSessionStartColors.card.opacity(0.78))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(displayMode == mode ? SkateTrackSessionStartColors.teal.opacity(0.48) : SkateTrackSessionStartColors.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityIdentifier("spots-display-mode-picker")
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let key = viewModel.errorMessageKey {
            Text(LocalizedStringKey(key))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SkateTrackSessionStartColors.accent2)
                .accessibilityIdentifier("spots-error-message")
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        if viewModel.isLoading && viewModel.spots.isEmpty {
            ProgressView()
                .tint(SkateTrackSessionStartColors.teal)
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if viewModel.spots.isEmpty {
            emptyState
        } else if displayMode == .map {
            SpotMapView(
                spots: viewModel.spots,
                onSelectSpot: openDetail,
                onToggleFavorite: { spot in await viewModel.toggleFavorite(spot) }
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.spots) { spot in
                    Button { openDetail(spot) } label: {
                        SpotCardView(
                            spot: spot,
                            rideabilityLevel: rideabilityLevel(for: spot),
                            onToggleFavorite: { Task { await viewModel.toggleFavorite(spot) } }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(SkateTrackSessionStartColors.teal)
            Text("spots.empty.title")
                .font(.headline.weight(.heavy))
                .foregroundStyle(.white)
            Text("spots.empty.subtitle")
                .font(.subheadline)
                .foregroundStyle(SkateTrackSessionStartColors.textSecondary)
                .multilineTextAlignment(.center)
            Button { isEditorPresented = true } label: {
                Text("spots.add")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(SkateTrackSessionStartColors.teal.opacity(0.82))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(SkateTrackSessionStartColors.card.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(SkateTrackSessionStartColors.border, lineWidth: 1))
        .accessibilityIdentifier("spots-empty-state")
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
                colors: [SkateTrackSessionStartColors.teal.opacity(0.24), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )
        }
    }

    private func rideabilityLevel(for spot: SpotProfile) -> WeatherSuitabilityLevel {
        rideabilityEngine.report(
            weatherReport: weatherRisk.report,
            context: .spotPreview(spot),
            spot: spot
        ).level
    }

    private func openDetail(_ spot: SpotProfile) {
        selectedSpot = spot
    }

    private func closeDetail() {
        selectedSpot = nil
        isDetailPresented = false
    }

    private func saveNewSpot(_ spot: SpotProfile) async -> Bool {
        await viewModel.save(spot)
    }

    private func saveFromDetail(_ spot: SpotProfile) async -> Bool {
        let didSave = await viewModel.save(spot)
        if didSave {
            selectedSpot = viewModel.spots.first { $0.id == spot.id } ?? spot
        }
        return didSave
    }

    private func toggleFavoriteAndRefreshSelection(_ spot: SpotProfile) async {
        await viewModel.toggleFavorite(spot)
        selectedSpot = viewModel.spots.first { $0.id == spot.id } ?? selectedSpot
    }

    private func deleteSelectedSpot() async {
        guard let selectedSpot else { return }
        await viewModel.delete(selectedSpot)
        closeDetail()
    }
}
