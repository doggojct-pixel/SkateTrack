// [協作區 — 邊界適配層] useEquipmentManager.swift
// 用途：向 SwiftUI 裝備管理畫面暴露裝備 CRUD、磨耗報告與訂閱 gating 狀態。
// 委派至：EquipmentRepository、WearReminderEngine、FeatureFlagEngine。

import Foundation
import SwiftUI

@MainActor
final class EquipmentManagerViewModel: ObservableObject {
    @Published private(set) var equipment: [EquipmentProfile] = []
    @Published private(set) var isLoading = false
    @Published var errorMessageKey: String?

    private let repository: EquipmentRepositoryProtocol
    private let subscriptionStatus: SubscriptionStatusViewModel

    init(
        repository: EquipmentRepositoryProtocol = EquipmentRepository.shared,
        subscriptionStatus: SubscriptionStatusViewModel
    ) {
        self.repository = repository
        self.subscriptionStatus = subscriptionStatus
    }

    var hasManagementAccess: Bool {
        subscriptionStatus.hasAccess(to: .equipmentManager)
    }

    var displayEquipment: [EquipmentProfile] {
        hasManagementAccess ? equipment : Self.sampleEquipment
    }

    var canAddEquipment: Bool {
        hasManagementAccess
    }

    func wearReport(for equipment: EquipmentProfile) -> EquipmentWearReport {
        WearReminderEngine.report(for: equipment)
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            equipment = try await repository.fetchEquipment()
            errorMessageKey = nil
        } catch let repositoryError as RepositoryError {
            errorMessageKey = repositoryError.localizationKey
        } catch {
            errorMessageKey = "repository.error.storeUnavailable"
        }
    }

    func save(_ equipment: EquipmentProfile) async -> Bool {
        guard hasManagementAccess else {
            errorMessageKey = "gear.error.locked"
            return false
        }
        do {
            _ = try await repository.saveEquipment(equipment)
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

    func delete(_ equipment: EquipmentProfile) async {
        guard hasManagementAccess else {
            errorMessageKey = "gear.error.locked"
            return
        }
        do {
            try await repository.deleteEquipment(id: equipment.id)
            await refresh()
        } catch let repositoryError as RepositoryError {
            errorMessageKey = repositoryError.localizationKey
        } catch {
            errorMessageKey = "repository.error.deleteFailed"
        }
    }

    func resetWheelMileage(for equipment: EquipmentProfile) async {
        await resetMileage(for: equipment, component: .wheels)
    }

    func resetBearingMileage(for equipment: EquipmentProfile) async {
        await resetMileage(for: equipment, component: .bearings)
    }

    private func resetMileage(
        for equipment: EquipmentProfile,
        component: EquipmentWearComponent
    ) async {
        guard hasManagementAccess else {
            errorMessageKey = "gear.error.locked"
            return
        }
        do {
            switch component {
            case .wheels:
                _ = try await repository.resetWheelMileage(id: equipment.id)
            case .bearings:
                _ = try await repository.resetBearingMileage(id: equipment.id)
            }
            await refresh()
        } catch let repositoryError as RepositoryError {
            errorMessageKey = repositoryError.localizationKey
        } catch {
            errorMessageKey = "repository.error.saveFailed"
        }
    }

    static var sampleEquipment: [EquipmentProfile] {
        [
            try! EquipmentProfile(
                name: "Powell Peralta",
                equipmentType: .skateboard,
                sportMode: .skateboard(.streetPark),
                powerType: .humanPowered,
                totalDistanceKm: 247,
                wheelSetMileageKm: 142,
                bearingSetMileageKm: 52,
                wheelDiameterMillimeters: 54,
                wheelHardness: "99A",
                notes: "Demo gear shown for free users."
            ),
            try! EquipmentProfile(
                name: "K2 Inline Pro",
                equipmentType: .inlineSkates,
                sportMode: .inline(.fitnessSpeed),
                totalDistanceKm: 89,
                wheelSetMileageKm: 66,
                bearingSetMileageKm: 76,
                wheelDiameterMillimeters: 90,
                wheelHardness: "85A",
                bearingABEC: "ABEC 7",
                brakeType: "Heel brake",
                notes: "Demo inline skates shown for free users."
            )
        ]
    }
}

@MainActor
func useEquipmentManager(
    subscriptionStatus: SubscriptionStatusViewModel,
    repository: EquipmentRepositoryProtocol = EquipmentRepository.shared
) -> EquipmentManagerViewModel {
    EquipmentManagerViewModel(
        repository: repository,
        subscriptionStatus: subscriptionStatus
    )
}
