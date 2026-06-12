// [自主區] SessionShareExportService.swift
// 用途：建立 Task-023b 本機快速匯出的 PNG / TXT / JSON 暫存檔，並負責清理。
// 委派至：SessionShareCardRenderer 產生 PNG data；SessionShareSheetView 開啟系統分享表。

import Foundation

enum SessionShareExportError: Error {
    case imageEncodingFailed
    case fileWriteFailed

    var localizationKey: String {
        switch self {
        case .imageEncodingFailed:
            return "summary.share.export.error.image"
        case .fileWriteFailed:
            return "summary.share.export.error.file"
        }
    }
}

struct SessionShareExportService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createExport(card: SessionShareCardData, pngData: Data) throws -> SessionShareExportPayload {
        guard !pngData.isEmpty else { throw SessionShareExportError.imageEncodingFailed }

        let directoryURL = exportDirectoryURL(sessionID: card.id)
        let imageURL = directoryURL.appendingPathComponent("skatetrack-share-card.png")
        let textURL = directoryURL.appendingPathComponent("skatetrack-summary.txt")
        let jsonURL = directoryURL.appendingPathComponent("skatetrack-summary.json")

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try pngData.write(to: imageURL, options: .atomic)
            try textSummary(for: card).write(to: textURL, atomically: true, encoding: .utf8)
            try jsonData(for: card).write(to: jsonURL, options: .atomic)
        } catch {
            try? fileManager.removeItem(at: directoryURL)
            throw SessionShareExportError.fileWriteFailed
        }

        return SessionShareExportPayload(
            sessionID: card.id,
            directoryURL: directoryURL,
            imageURL: imageURL,
            textURL: textURL,
            jsonURL: jsonURL
        )
    }

    func cleanup(_ payload: SessionShareExportPayload) {
        try? fileManager.removeItem(at: payload.directoryURL)
    }

    private func exportDirectoryURL(sessionID: UUID) -> URL {
        let folderName = "\(sessionID.uuidString)-\(Int(Date().timeIntervalSince1970))"
        return fileManager.temporaryDirectory
            .appendingPathComponent("SkateTrackShare", isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }

    private func jsonData(for card: SessionShareCardData) throws -> Data {
        let package = SessionShareExportJSON(
            exportVersion: 1,
            generatedAt: Date(),
            appName: "SkateTrack",
            card: card
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    private func textSummary(for card: SessionShareCardData) -> String {
        [
            localized("summary.share.export.text.title"),
            "SkateTrack",
            "",
            "\(localized(card.sportModeLocalizationKey)) · \(localized(card.powerTypeLocalizationKey))",
            card.dateLine,
            "",
            "\(localized("summary.metric.distance")): \(card.distanceText)",
            "\(localized("summary.metric.duration")): \(card.durationText)",
            "\(localized("summary.metric.maxSpeed")): \(card.maxSpeedText)",
            "\(localized("summary.metric.avgSpeed")): \(card.averageSpeedText)",
            "\(localized("summary.metric.elevationGain")): \(card.elevationText)",
            "\(localized("summary.metric.movingRatio")): \(card.movingRatioText)",
            "\(localized("summary.share.spot")): \(card.spotName ?? localized("summary.share.spot.none"))",
            "\(localized("summary.share.equipment")): \(card.equipmentName ?? localized("summary.share.equipment.none"))",
            "\(localized("summary.share.route")): \(localized(card.routeStatusLocalizationKey))",
            "\(localized("summary.share.safety")): \(card.safetyStatusText)",
            "",
            localized("summary.share.export.text.footer")
        ].joined(separator: "\n")
    }

    private func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

private struct SessionShareExportJSON: Encodable {
    let exportVersion: Int
    let generatedAt: Date
    let appName: String
    let card: SessionShareCardData
}
