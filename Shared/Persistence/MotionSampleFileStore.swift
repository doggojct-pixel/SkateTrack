// [自主區] Shared/Persistence/MotionSampleFileStore.swift
// 用途：將高頻 MotionSample 存成獨立檔案，避免把大量感測樣本塞入 Core Data。
// 委派至：SessionRepository、future export / sync pipeline。

import Foundation

final class MotionSampleFileStore {
    private let rootDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        rootDirectory: URL = MotionSampleFileStore.defaultRootDirectory(),
        fileManager: FileManager = .default
    ) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    static func defaultRootDirectory() -> URL {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return supportDirectory
            .appendingPathComponent("SkateTrack", isDirectory: true)
            .appendingPathComponent("MotionSamples", isDirectory: true)
    }

    func save(_ samples: [MotionSample], for sessionID: UUID) throws -> String? {
        guard !samples.isEmpty else { return nil }
        try ensureRootDirectoryExists()
        let fileName = "\(sessionID.uuidString).motionSamples.json"
        let fileURL = rootDirectory.appendingPathComponent(fileName)
        do {
            let data = try encoder.encode(samples)
            try data.write(to: fileURL, options: [.atomic])
            return fileName
        } catch {
            throw RepositoryError.encodingFailed
        }
    }

    func load(fileName: String?) throws -> [MotionSample] {
        guard let fileName else { return [] }
        let fileURL = rootDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw RepositoryError.motionSampleFileMissing
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([MotionSample].self, from: data)
        } catch {
            throw RepositoryError.decodingFailed
        }
    }

    func delete(fileName: String?) throws {
        guard let fileName else { return }
        let fileURL = rootDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw RepositoryError.deleteFailed
        }
    }

    func fileURL(for fileName: String?) -> URL? {
        guard let fileName else { return nil }
        return rootDirectory.appendingPathComponent(fileName)
    }

    private func ensureRootDirectoryExists() throws {
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }
}
