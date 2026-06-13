// [協作區 — 邊界適配層] SkateTrackPackageExportProvider.swift
// 用途：建立 iOS 單筆 Session 的 .skatetrack 暫存匯出檔，並交給系統分享表。
// 委派至：Shared/Export writer 寫檔；ViewModel 管理 UI state 與 cleanup。

import Foundation

struct SkateTrackPackageExportResult: Identifiable, Equatable {
    let id: UUID
    let sessionID: UUID
    let directoryURL: URL
    let fileURL: URL
    let manifest: SkateTrackPackageManifest
    let byteCount: Int

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        directoryURL: URL,
        fileURL: URL,
        manifest: SkateTrackPackageManifest,
        byteCount: Int
    ) {
        self.id = id
        self.sessionID = sessionID
        self.directoryURL = directoryURL
        self.fileURL = fileURL
        self.manifest = manifest
        self.byteCount = max(0, byteCount)
    }

    var itemURLs: [URL] {
        [fileURL]
    }
}

struct SkateTrackPackageExportProvider {
    private let fileManager: FileManager
    private let writer: SkateTrackPackageWriter

    init(
        fileManager: FileManager = .default,
        writer: SkateTrackPackageWriter = SkateTrackPackageWriter()
    ) {
        self.fileManager = fileManager
        self.writer = writer
    }

    func createExport(content: SessionSummaryContent) throws -> SkateTrackPackageExportResult {
        let effectiveSamples = content.motionSamples.isEmpty ? content.session.motionSamples : content.motionSamples
        let sessionItem = SkateTrackPackageSession(
            session: content.session,
            motionSamples: effectiveSamples
        )
        let manifest = SkateTrackPackageManifest(
            appVersion: bundleValue(for: "CFBundleShortVersionString"),
            buildNumber: bundleValue(for: "CFBundleVersion"),
            localeIdentifier: Locale.autoupdatingCurrent.identifier,
            sessionCount: 1,
            includesMotionSamples: !effectiveSamples.isEmpty,
            includesAccountData: false,
            includesAchievements: false,
            formatCapabilities: [
                "location-diagnostics-v1",
                "route-quality-summary-v1"
            ]
        )
        let payload = try SkateTrackPackagePayload(manifest: manifest, sessions: [sessionItem])
        let directoryURL = packageDirectoryURL(sessionID: content.session.id)
        let fileURL = directoryURL.appendingPathComponent(fileName(for: content.session))
        let byteCount = try writer.write(package: payload, to: fileURL)

        return SkateTrackPackageExportResult(
            sessionID: content.session.id,
            directoryURL: directoryURL,
            fileURL: fileURL,
            manifest: manifest,
            byteCount: byteCount
        )
    }

    func cleanup(_ result: SkateTrackPackageExportResult) {
        try? fileManager.removeItem(at: result.directoryURL)
    }

    private func packageDirectoryURL(sessionID: UUID) -> URL {
        let folderName = "\(sessionID.uuidString)-\(Int(Date().timeIntervalSince1970))"
        return fileManager.temporaryDirectory
            .appendingPathComponent("SkateTrackPackages", isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }

    private func fileName(for session: SessionData) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: session.startDate)
        return "SkateTrack-Session-\(stamp).skatetrack"
    }

    private func bundleValue(for key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "local"
    }
}
