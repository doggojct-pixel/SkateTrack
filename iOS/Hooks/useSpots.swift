// [協作區 — 邊界適配層] useSpots.swift
// 用途：向 SwiftUI Spot 畫面暴露本機場地 CRUD、favorite limit 與 Paywall intent。
// 委派至：SpotRepository 與 useSubscriptionStatus，不讓 View 直接碰 Core Data 或付費判斷細節。

import Foundation
import SwiftUI

@MainActor
final class SpotsViewModel: ObservableObject {
    static let freeFavoriteLimit = 3

    @Published private(set) var spots: [SpotProfile] = []
    @Published private(set) var isLoading = false
    @Published var errorMessageKey: String?
    @Published var paywallFeature: GatedFeature?

    private let repository: SpotRepositoryProtocol
    private let subscriptionStatus: SubscriptionStatusViewModel

    init(
        repository: SpotRepositoryProtocol = SpotRepository.shared,
        subscriptionStatus: SubscriptionStatusViewModel
    ) {
        self.repository = repository
        self.subscriptionStatus = subscriptionStatus
    }

    var hasUnlimitedFavoriteAccess: Bool {
        subscriptionStatus.hasAccess(to: .spotManagement)
    }

    var favoriteCount: Int {
        spots.filter(\.isFavorite).count
    }

    var canFavoriteMoreSpots: Bool {
        hasUnlimitedFavoriteAccess || favoriteCount < Self.freeFavoriteLimit
    }

    var favoriteLimitTextKey: String {
        hasUnlimitedFavoriteAccess ? "spots.favorite.unlimited" : "spots.favorite.limit"
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            spots = try await repository.fetchSpots()
            errorMessageKey = nil
        } catch let repositoryError as RepositoryError {
            errorMessageKey = repositoryError.localizationKey
        } catch {
            errorMessageKey = "repository.error.storeUnavailable"
        }
    }

    func save(_ spot: SpotProfile) async -> Bool {
        do {
            _ = try await repository.saveSpot(spot)
            await refresh()
            return true
        } catch let repositoryError as RepositoryError {
            errorMessageKey = repositoryError.localizationKey
            return false
        } catch {
            errorMessageKey = "repository.error.saveFailed"
            return false
        }
    }

    func delete(_ spot: SpotProfile) async {
        do {
            try await repository.deleteSpot(id: spot.id)
            await refresh()
        } catch let repositoryError as RepositoryError {
            errorMessageKey = repositoryError.localizationKey
        } catch {
            errorMessageKey = "repository.error.deleteFailed"
        }
    }

    func toggleFavorite(_ spot: SpotProfile) async {
        let targetState = !spot.isFavorite
        if targetState && !canFavoriteMoreSpots {
            paywallFeature = .spotManagement
            errorMessageKey = "spots.favorite.limit"
            return
        }

        do {
            _ = try await repository.setFavorite(targetState, for: spot.id)
            await refresh()
            errorMessageKey = nil
        } catch let repositoryError as RepositoryError {
            errorMessageKey = repositoryError.localizationKey
        } catch {
            errorMessageKey = "repository.error.saveFailed"
        }
    }

    func clearPaywallIntent() {
        paywallFeature = nil
    }
}

@MainActor
func useSpots(
    subscriptionStatus: SubscriptionStatusViewModel,
    repository: SpotRepositoryProtocol = SpotRepository.shared
) -> SpotsViewModel {
    SpotsViewModel(
        repository: repository,
        subscriptionStatus: subscriptionStatus
    )
}
