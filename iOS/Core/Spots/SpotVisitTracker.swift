// [自主區] SpotVisitTracker.swift
// 用途：在 completed session 成功保存後，將本次場地造訪安全寫回本機 Spot 統計。
// 委派至：SessionRecordingCoordinator 呼叫；實際 Core Data 更新仍由 SpotRepository 負責。

import Foundation

protocol SpotVisitTracking: Sendable {
    @discardableResult
    func applyVisitIfNeeded(to session: SessionData) async throws -> SpotVisitTrackingResult
}

enum SpotVisitTrackingResult: Sendable, Equatable {
    case skippedNoSpot
    case skippedAlreadyApplied
    case spotMissing(UUID)
    case applied(spotID: UUID, sessionID: UUID)
}

actor SpotVisitTracker: SpotVisitTracking {
    static let shared = SpotVisitTracker()

    private let repository: SpotRepositoryProtocol
    private var appliedSessionIDs: Set<UUID> = []

    init(repository: SpotRepositoryProtocol = SpotRepository.shared) {
        self.repository = repository
    }

    @discardableResult
    func applyVisitIfNeeded(to session: SessionData) async throws -> SpotVisitTrackingResult {
        guard let spotID = session.spotID else {
            return .skippedNoSpot
        }

        guard appliedSessionIDs.contains(session.id) == false else {
            return .skippedAlreadyApplied
        }

        guard try await repository.fetchSpot(id: spotID) != nil else {
            return .spotMissing(spotID)
        }

        let visit = SpotVisit(
            spotID: spotID,
            sessionID: session.id,
            visitedAt: session.endDate ?? session.startDate,
            distanceKilometers: session.summaryMetrics?.distanceKilometers ?? 0,
            confidence: 1
        )
        _ = try await repository.recordVisit(visit)
        appliedSessionIDs.insert(session.id)
        return .applied(spotID: spotID, sessionID: session.id)
    }
}
