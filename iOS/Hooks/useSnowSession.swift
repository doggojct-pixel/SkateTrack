// [協作區 — 邊界適配層] iOS/Hooks/useSnowSession.swift
// 用途：向 SwiftUI 暴露 repository-backed Snow session state，作為 Snow-Task-005 UI 的資料邊界。
// 委派至：SnowSessionRepository；不建立 mock provider、不做 classifier 或 run boundary detection。

import Combine
import Foundation

@MainActor
final class SnowSessionViewModel: ObservableObject {
    @Published private(set) var state: SnowSessionState = .empty

    private let repository: SnowSessionRepositoryProtocol
    private var currentSessionID: UUID?

    init(
        sessionID: UUID? = nil,
        repository: SnowSessionRepositoryProtocol = SnowSessionRepository.shared
    ) {
        self.currentSessionID = sessionID
        self.repository = repository
        if let sessionID {
            state = SnowSessionState(sessionID: sessionID, loadState: .idle)
        }
    }

    func load(sessionID: UUID) async {
        currentSessionID = sessionID
        state = SnowSessionState(sessionID: sessionID, loadState: .loading)
        do {
            state = try await repository.fetchState(sessionID: sessionID)
        } catch let error as RepositoryError {
            state = SnowSessionState(sessionID: sessionID, loadState: .error(error.localizationKey))
        } catch {
            state = SnowSessionState(sessionID: sessionID, loadState: .error("snow.session.error.generic"))
        }
    }

    func reload() async {
        guard let currentSessionID else {
            state = .empty
            return
        }
        await load(sessionID: currentSessionID)
    }

    func save(segment: SnowSegment) async throws {
        try await repository.saveSegment(segment)
        await reload()
    }

    func save(run: SnowRun) async throws {
        try await repository.saveRun(run)
        await reload()
    }

    func deleteSnowData() async throws {
        guard let currentSessionID else { return }
        try await repository.deleteSnowData(sessionID: currentSessionID)
        await load(sessionID: currentSessionID)
    }
}
