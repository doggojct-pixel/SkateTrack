// [協作區 — 邊界適配層] useSessionHistory.swift
// 用途：向 SwiftUI Views 暴露 Session History 查詢、篩選、分組與免費 5 筆限制狀態。
// 委派至：SessionRepositoryProtocol 讀取 Task-015 本機持久化資料，useSubscriptionStatus 判斷付費權限。

import Combine
import Foundation

enum SessionHistoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case skate
    case inline
    case electric

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .all:
            return "history.filter.all"
        case .skate:
            return "history.filter.skate"
        case .inline:
            return "history.filter.inline"
        case .electric:
            return "history.filter.electric"
        }
    }

    func matches(_ session: SessionData) -> Bool {
        switch self {
        case .all:
            return true
        case .skate:
            if case .skateboard = session.sportMode { return true }
            return false
        case .inline:
            if case .inline = session.sportMode { return true }
            return false
        case .electric:
            return session.powerType == .electric
        }
    }
}

enum SessionHistoryViewState: Equatable {
    case loading
    case empty
    case content
    case error(String)
}

struct SessionHistoryEntry: Identifiable, Equatable {
    let session: SessionData
    let globalIndex: Int
    let isLocked: Bool

    var id: UUID { session.id }
}

struct SessionHistoryMonthSection: Identifiable, Equatable {
    let id: String
    let title: String
    let entries: [SessionHistoryEntry]
}

@MainActor
final class SessionHistoryViewModel: ObservableObject {
    static let freeAccessibleSessionCount = 5

    @Published private(set) var viewState: SessionHistoryViewState = .loading
    @Published var selectedFilter: SessionHistoryFilter = .all

    private let repository: SessionRepositoryProtocol
    private let fetchLimit: Int
    private var sessions: [SessionData] = []
    private var hasLoaded = false

    init(
        repository: SessionRepositoryProtocol = SessionRepository.shared,
        fetchLimit: Int = 200
    ) {
        self.repository = repository
        self.fetchLimit = fetchLimit
    }

    var totalSessionCount: Int {
        sessions.count
    }

    var weeklyDistanceKilometers: Double {
        guard let week = Calendar.autoupdatingCurrent.dateInterval(of: .weekOfYear, for: Date()) else {
            return 0
        }
        return sessions
            .filter { week.contains($0.startDate) }
            .reduce(0) { partialResult, session in
                partialResult + (session.summaryMetrics?.distanceKilometers ?? 0)
            }
    }

    var filteredSessionCount: Int {
        filteredSessions.count
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        viewState = .loading
        do {
            sessions = try await repository.fetchRecentSessions(limit: fetchLimit)
            hasLoaded = true
            viewState = sessions.isEmpty ? .empty : .content
        } catch let error as RepositoryError {
            hasLoaded = true
            viewState = .error(error.localizationKey)
        } catch {
            hasLoaded = true
            viewState = .error("history.error.generic")
        }
    }

    func groupedSections(isSubscriber: Bool) -> [SessionHistoryMonthSection] {
        let entries = filteredEntries(isSubscriber: isSubscriber)
        var sections: [SessionHistoryMonthSection] = []
        var currentKey: String?
        var currentTitle: String?
        var currentEntries: [SessionHistoryEntry] = []

        for entry in entries {
            let key = Self.monthKey(for: entry.session.startDate)
            let title = Self.monthTitle(for: entry.session.startDate)

            if currentKey == nil {
                currentKey = key
                currentTitle = title
            }

            if key != currentKey {
                if let currentKey, let currentTitle {
                    sections.append(SessionHistoryMonthSection(id: currentKey, title: currentTitle, entries: currentEntries))
                }
                currentKey = key
                currentTitle = title
                currentEntries = [entry]
            } else {
                currentEntries.append(entry)
            }
        }

        if let currentKey, let currentTitle, !currentEntries.isEmpty {
            sections.append(SessionHistoryMonthSection(id: currentKey, title: currentTitle, entries: currentEntries))
        }

        return sections
    }

    func lockedSessionCount(isSubscriber: Bool) -> Int {
        guard !isSubscriber else { return 0 }
        return max(0, sessions.count - Self.freeAccessibleSessionCount)
    }

    func hasAccessibleHistoryLimit(isSubscriber: Bool) -> Bool {
        !isSubscriber && sessions.count > Self.freeAccessibleSessionCount
    }

    private var filteredSessions: [SessionData] {
        sessions.filter { selectedFilter.matches($0) }
    }

    private func filteredEntries(isSubscriber: Bool) -> [SessionHistoryEntry] {
        let rankByID = Dictionary(uniqueKeysWithValues: sessions.enumerated().map { index, session in
            (session.id, index)
        })

        return filteredSessions.map { session in
            let globalIndex = rankByID[session.id] ?? 0
            let isLocked = !isSubscriber && globalIndex >= Self.freeAccessibleSessionCount
            return SessionHistoryEntry(session: session, globalIndex: globalIndex, isLocked: isLocked)
        }
    }

    private static func monthKey(for date: Date) -> String {
        let components = Calendar.autoupdatingCurrent.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    private static func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        if let dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMM", options: 0, locale: formatter.locale) {
            formatter.dateFormat = dateFormat
        }
        return formatter.string(from: date)
    }
}

@MainActor
func useSessionHistory(repository: SessionRepositoryProtocol = SessionRepository.shared) -> SessionHistoryViewModel {
    SessionHistoryViewModel(repository: repository)
}
