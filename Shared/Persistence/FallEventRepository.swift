// [協作區 — 邊界適配層] Shared/Persistence/FallEventRepository.swift
// 用途：提供 Session 附屬跌倒事件查詢入口，避免後續 UI 直接讀 Core Data。
// 委派至：Task-018 summary、Task-019 history、Task-020 safety analytics。

import CoreData
import Foundation

protocol FallEventRepositoryProtocol: AnyObject {
    func fetchFallEvents(sessionID: UUID) async throws -> [FallEvent]
}

final class FallEventRepository: FallEventRepositoryProtocol {
    static let shared = FallEventRepository()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func fetchFallEvents(sessionID: UUID) async throws -> [FallEvent] {
        let context = persistenceController.viewContext
        return try await context.perform {
            try SessionEntityMapper.fetchFallEventObjects(sessionID: sessionID, in: context)
                .map(SessionEntityMapper.makeFallEvent)
        }
    }
}
