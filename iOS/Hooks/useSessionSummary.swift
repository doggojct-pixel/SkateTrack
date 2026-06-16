// [協作區 — 邊界適配層] useSessionSummary.swift
// 用途：向 SwiftUI Views 暴露單筆 Session Summary 載入狀態、核心指標與 Task-018a 摘要資料。
// 委派至：SessionRepositoryProtocol 讀取 Task-015 本機持久化資料，不讓 Views 直接碰 Core Data。

import Combine
import Foundation

struct SessionSummaryContent: Equatable, Sendable {
    let session: SessionData
    let motionSamples: [MotionSample]

    var metrics: SessionSummaryMetrics { session.summaryMetrics ?? .zero }
    var durationSeconds: TimeInterval? { session.durationSeconds }
    var fallCount: Int { session.fallEvents.count }
    var trickCount: Int { session.trickEvents.count }
    var hasRouteSamples: Bool { motionSamples.contains { $0.gpsCoordinate != nil } }
    var hasAltitudeSamples: Bool { motionSamples.contains { $0.altitudeMeters != nil } }
}

enum SessionSummaryViewState: Equatable {
    case loading
    case content(SessionSummaryContent)
    case error(String)
}

@MainActor
final class SessionSummaryViewModel: ObservableObject {
    @Published private(set) var viewState: SessionSummaryViewState = .loading

    private let sessionID: UUID
    private let repository: SessionRepositoryProtocol
    private let initialSession: SessionData?
    private var hasLoaded = false

    init(
        sessionID: UUID,
        initialSession: SessionData? = nil,
        repository: SessionRepositoryProtocol = SessionRepository.shared
    ) {
        self.sessionID = sessionID
        self.initialSession = initialSession
        self.repository = repository

        if let initialSession {
            viewState = .content(
                SessionSummaryContent(
                    session: initialSession,
                    motionSamples: initialSession.motionSamples
                )
            )
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        if initialSession == nil {
            viewState = .loading
        }

        do {
            let session = try await repository.fetchSession(id: sessionID)
            let samples = try await repository.loadMotionSamples(for: sessionID)
            let effectiveSamples = samples.isEmpty ? session.motionSamples : samples
            hasLoaded = true
            viewState = .content(SessionSummaryContent(session: session, motionSamples: effectiveSamples))
        } catch let error as RepositoryError {
            hasLoaded = true
            viewState = .error(error.localizationKey)
        } catch {
            hasLoaded = true
            viewState = .error("summary.error.generic")
        }
    }
}

@MainActor
func useSessionSummary(
    sessionID: UUID,
    initialSession: SessionData? = nil,
    repository: SessionRepositoryProtocol = SessionRepository.shared
) -> SessionSummaryViewModel {
    SessionSummaryViewModel(sessionID: sessionID, initialSession: initialSession, repository: repository)
}
