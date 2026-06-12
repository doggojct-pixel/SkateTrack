// [自主區] Shared/Export/SkateTrackPackageWriter.swift
// 用途：將可攜式 .skatetrack package 寫到呼叫端提供的 URL，不決定 iOS / macOS 路徑。
// 委派至：iOS/Core/Export 或未來 macOS import/export layer 負責選擇目的地。

import Foundation

struct SkateTrackPackageWriter {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func encodedData(for package: SkateTrackPackagePayload) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(package)
        } catch {
            throw SkateTrackPackageError.packageEncodingFailed
        }
    }

    @discardableResult
    func write(package: SkateTrackPackagePayload, to destinationURL: URL) throws -> Int {
        do {
            let data = try encodedData(for: package)
            let parentURL = destinationURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)
            try data.write(to: destinationURL, options: .atomic)
            return data.count
        } catch let error as SkateTrackPackageError {
            throw error
        } catch {
            throw SkateTrackPackageError.fileWriteFailed
        }
    }
}
