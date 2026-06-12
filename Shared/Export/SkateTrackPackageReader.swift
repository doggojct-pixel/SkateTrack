// [自主區] Shared/Export/SkateTrackPackageReader.swift
// 用途：讀取並驗證可攜式 .skatetrack package；不做資料庫 import / restore。
// 委派至：Task-027b macOS import stub 與後續 package preview UI。

import Foundation

struct SkateTrackPackageReader {
    func decodePackage(from data: Data) throws -> SkateTrackPackagePayload {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let package = try decoder.decode(SkateTrackPackagePayload.self, from: data)
            try SkateTrackPackageManifest.validate(package.manifest)
            guard !package.sessions.isEmpty else { throw SkateTrackPackageError.emptySessionExport }
            return package
        } catch let error as SkateTrackPackageError {
            throw error
        } catch {
            throw SkateTrackPackageError.packageDecodingFailed
        }
    }

    func readPackage(from url: URL) throws -> SkateTrackPackagePayload {
        do {
            let data = try Data(contentsOf: url)
            return try decodePackage(from: data)
        } catch let error as SkateTrackPackageError {
            throw error
        } catch {
            throw SkateTrackPackageError.fileReadFailed
        }
    }
}
