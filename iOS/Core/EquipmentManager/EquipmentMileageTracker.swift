// [自主區] EquipmentMileageTracker.swift
// 用途：在 completed session 成功保存後，將本次里程安全累加到使用者選擇的裝備。
// 委派至：SessionRecordingCoordinator 呼叫；實際 Core Data 更新仍由 EquipmentRepository 負責。

import Foundation

protocol EquipmentMileageTracking: Sendable {
    @discardableResult
    func applyMileageIfNeeded(to session: SessionData) async throws -> EquipmentMileageTrackingResult
}

enum EquipmentMileageTrackingResult: Sendable, Equatable {
    case skippedNoEquipment
    case skippedZeroDistance
    case skippedAlreadyApplied
    case equipmentMissing(UUID)
    case applied(equipmentID: UUID, distanceKilometers: Double)
}

actor EquipmentMileageTracker: EquipmentMileageTracking {
    static let shared = EquipmentMileageTracker()

    private let repository: EquipmentRepositoryProtocol
    private var appliedSessionIDs: Set<UUID> = []

    init(repository: EquipmentRepositoryProtocol = EquipmentRepository.shared) {
        self.repository = repository
    }

    @discardableResult
    func applyMileageIfNeeded(to session: SessionData) async throws -> EquipmentMileageTrackingResult {
        guard let equipmentID = session.equipmentID else {
            return .skippedNoEquipment
        }

        let distanceKilometers = max(0, session.summaryMetrics?.distanceKilometers ?? 0)
        guard distanceKilometers > 0 else {
            return .skippedZeroDistance
        }

        guard appliedSessionIDs.contains(session.id) == false else {
            return .skippedAlreadyApplied
        }

        guard try await repository.addMileage(
            id: equipmentID,
            distanceKilometers: distanceKilometers
        ) != nil else {
            return .equipmentMissing(equipmentID)
        }

        appliedSessionIDs.insert(session.id)
        return .applied(equipmentID: equipmentID, distanceKilometers: distanceKilometers)
    }
}
