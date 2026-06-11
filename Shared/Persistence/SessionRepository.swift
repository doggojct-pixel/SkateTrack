// [協作區 — 邊界適配層] Shared/Persistence/SessionRepository.swift
// 用途：提供完成 Session 的本機 save / fetch / delete / export API，隱藏 Core Data 與檔案細節。
// 委派至：Task-015b SessionRecordingCoordinator integration、history、summary、sync。

import CoreData
import Foundation

protocol SessionRepositoryProtocol: AnyObject, Sendable {
    @discardableResult
    func saveCompletedSession(_ session: SessionData) async throws -> SessionData
    func fetchRecentSessions(limit: Int) async throws -> [SessionData]
    func fetchSession(id: UUID) async throws -> SessionData
    func loadMotionSamples(for sessionID: UUID) async throws -> [MotionSample]
    func deleteSession(id: UUID) async throws
    func exportSessionBundle(id: UUID) async throws -> URL
}

final class SessionRepository: SessionRepositoryProtocol, @unchecked Sendable {
    static let shared = SessionRepository()

    private let persistenceController: PersistenceController
    private let sampleStore: MotionSampleFileStore
    private let exportDirectory: URL
    private let fileManager: FileManager

    init(
        persistenceController: PersistenceController = .shared,
        sampleStore: MotionSampleFileStore = MotionSampleFileStore(),
        exportDirectory: URL = SessionRepository.defaultExportDirectory(),
        fileManager: FileManager = .default
    ) {
        self.persistenceController = persistenceController
        self.sampleStore = sampleStore
        self.exportDirectory = exportDirectory
        self.fileManager = fileManager
    }

    @discardableResult
    func saveCompletedSession(_ session: SessionData) async throws -> SessionData {
        let sampleFileName = try sampleStore.save(session.motionSamples, for: session.id)
        let context = persistenceController.viewContext
        try await context.perform {
            try SessionEntityMapper.upsertSession(session, sampleFileName: sampleFileName, in: context)
            if context.hasChanges {
                try context.save()
            }
        }
        return session
    }

    func fetchRecentSessions(limit: Int = 20) async throws -> [SessionData] {
        let context = persistenceController.viewContext
        return try await context.perform {
            let objects = try SessionEntityMapper.fetchRecentSessionObjects(limit: limit, in: context)
            return try objects.map { object in
                try self.makeSessionData(from: object, in: context)
            }
        }
    }

    func fetchSession(id: UUID) async throws -> SessionData {
        let context = persistenceController.viewContext
        return try await context.perform {
            guard let object = try SessionEntityMapper.fetchSessionObject(id: id, in: context) else {
                throw RepositoryError.sessionNotFound
            }
            return try self.makeSessionData(from: object, in: context)
        }
    }

    func loadMotionSamples(for sessionID: UUID) async throws -> [MotionSample] {
        let context = persistenceController.viewContext
        let fileName = try await context.perform {
            guard let object = try SessionEntityMapper.fetchSessionObject(id: sessionID, in: context) else {
                throw RepositoryError.sessionNotFound
            }
            return SessionEntityMapper.sampleFileName(from: object)
        }
        return try sampleStore.load(fileName: fileName)
    }

    func deleteSession(id: UUID) async throws {
        let context = persistenceController.viewContext
        let sampleFileName = try await context.perform {
            guard let object = try SessionEntityMapper.fetchSessionObject(id: id, in: context) else {
                throw RepositoryError.sessionNotFound
            }
            let sampleFileName = SessionEntityMapper.sampleFileName(from: object)
            let fallEvents = try SessionEntityMapper.fetchFallEventObjects(sessionID: id, in: context)
            fallEvents.forEach(context.delete)
            context.delete(object)
            if context.hasChanges {
                try context.save()
            }
            return sampleFileName
        }
        try sampleStore.delete(fileName: sampleFileName)
    }

    func exportSessionBundle(id: UUID) async throws -> URL {
        let session = try await fetchSession(id: id)
        let samples = try await loadMotionSamples(for: id)
        let bundleURL = exportDirectory.appendingPathComponent(id.uuidString, isDirectory: true)

        do {
            if fileManager.fileExists(atPath: bundleURL.path) {
                try fileManager.removeItem(at: bundleURL)
            }
            try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(session).write(to: bundleURL.appendingPathComponent("session.json"), options: [.atomic])
            try encoder.encode(samples).write(to: bundleURL.appendingPathComponent("motionSamples.json"), options: [.atomic])
            return bundleURL
        } catch {
            throw RepositoryError.exportFailed
        }
    }

    static func defaultExportDirectory() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return cacheDirectory
            .appendingPathComponent("SkateTrack", isDirectory: true)
            .appendingPathComponent("Exports", isDirectory: true)
    }

    private func makeSessionData(
        from object: NSManagedObject,
        in context: NSManagedObjectContext
    ) throws -> SessionData {
        let sessionID: UUID = try SessionEntityMapper.requiredValue("id", from: object)
        let sampleFileName = SessionEntityMapper.sampleFileName(from: object)
        let samples = try sampleStore.load(fileName: sampleFileName)
        let fallEvents = try SessionEntityMapper.fetchFallEventObjects(sessionID: sessionID, in: context)
            .map(SessionEntityMapper.makeFallEvent)
        return try SessionEntityMapper.makeSessionData(
            from: object,
            motionSamples: samples,
            fallEvents: fallEvents
        )
    }
}
