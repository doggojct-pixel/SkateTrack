// [協作區 — 邊界適配層] Shared/Persistence/SnowSessionRepository.swift
// 用途：提供 SnowRun / SnowSegment 的 production Core Data CRUD 與 session-level aggregate state。
// 委派至：Snow-Task-003/004 classifier pipeline、Snow UI、macOS viewer、package compatibility。

import CoreData
import Foundation

protocol SnowSessionRepositoryProtocol: AnyObject, Sendable {
    @discardableResult
    func saveRun(_ run: SnowRun) async throws -> SnowRun
    @discardableResult
    func saveSegment(_ segment: SnowSegment) async throws -> SnowSegment
    func fetchRuns(sessionID: UUID) async throws -> [SnowRun]
    func fetchSegments(sessionID: UUID) async throws -> [SnowSegment]
    func fetchRun(id: UUID) async throws -> SnowRun
    func fetchSegment(id: UUID) async throws -> SnowSegment
    func fetchState(sessionID: UUID) async throws -> SnowSessionState
    func deleteRun(id: UUID) async throws
    func deleteSegment(id: UUID) async throws
    func deleteSnowData(sessionID: UUID) async throws
}

final class SnowSessionRepository: SnowSessionRepositoryProtocol, @unchecked Sendable {
    static let shared = SnowSessionRepository()

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    @discardableResult
    func saveRun(_ run: SnowRun) async throws -> SnowRun {
        let context = persistenceController.viewContext
        try await context.perform {
            try SnowSessionEntityMapper.upsertRun(run, in: context)
            if context.hasChanges {
                try context.save()
            }
        }
        return run
    }

    @discardableResult
    func saveSegment(_ segment: SnowSegment) async throws -> SnowSegment {
        let context = persistenceController.viewContext
        try await context.perform {
            try SnowSessionEntityMapper.upsertSegment(segment, in: context)
            if context.hasChanges {
                try context.save()
            }
        }
        return segment
    }

    func fetchRuns(sessionID: UUID) async throws -> [SnowRun] {
        let context = persistenceController.viewContext
        return try await context.perform {
            try SnowSessionEntityMapper.fetchRunObjects(sessionID: sessionID, in: context)
                .map(SnowSessionEntityMapper.makeRun)
        }
    }

    func fetchSegments(sessionID: UUID) async throws -> [SnowSegment] {
        let context = persistenceController.viewContext
        return try await context.perform {
            try SnowSessionEntityMapper.fetchSegmentObjects(sessionID: sessionID, in: context)
                .map(SnowSessionEntityMapper.makeSegment)
        }
    }

    func fetchRun(id: UUID) async throws -> SnowRun {
        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try SnowSessionEntityMapper.fetchRunObject(id: id, in: context) else {
                throw RepositoryError.snowRunNotFound
            }
            return try SnowSessionEntityMapper.makeRun(from: object)
        }
    }

    func fetchSegment(id: UUID) async throws -> SnowSegment {
        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try SnowSessionEntityMapper.fetchSegmentObject(id: id, in: context) else {
                throw RepositoryError.snowSegmentNotFound
            }
            return try SnowSessionEntityMapper.makeSegment(from: object)
        }
    }

    func fetchState(sessionID: UUID) async throws -> SnowSessionState {
        let runs = try await fetchRuns(sessionID: sessionID)
        let segments = try await fetchSegments(sessionID: sessionID)
        let loadState: SnowSessionState.LoadState = runs.isEmpty && segments.isEmpty ? .empty : .loaded
        return SnowSessionState(
            sessionID: sessionID,
            loadState: loadState,
            runs: runs,
            segments: segments
        )
    }

    func deleteRun(id: UUID) async throws {
        let context = persistenceController.viewContext
        try await context.perform {
            guard let object = try SnowSessionEntityMapper.fetchRunObject(id: id, in: context) else {
                throw RepositoryError.snowRunNotFound
            }
            context.delete(object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func deleteSegment(id: UUID) async throws {
        let context = persistenceController.viewContext
        try await context.perform {
            guard let object = try SnowSessionEntityMapper.fetchSegmentObject(id: id, in: context) else {
                throw RepositoryError.snowSegmentNotFound
            }
            context.delete(object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func deleteSnowData(sessionID: UUID) async throws {
        let context = persistenceController.viewContext
        try await context.perform {
            try SnowSessionEntityMapper.deleteSnowObjects(sessionID: sessionID, in: context)
            if context.hasChanges {
                try context.save()
            }
        }
    }
}
