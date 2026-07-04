// [協作區] macOS/Features/SessionBrowser/MacPackageAttentionState.swift
// 用途：分類 Task-030e macOS read-only multi-package viewer 的 duplicate / attention states。
// 委派至：MacMultiPackageViewerState / MacPackageCardListView；不得 merge、delete、pick winner、import local history 或修改 package。

import Foundation

struct MacPackageAttentionWarning: Identifiable, Equatable {
    enum Reason: String, Equatable {
        case duplicateFilePath
        case duplicatePackageIdentifier
        case duplicateSessionIdentifier
    }

    let reason: Reason
    let relatedCount: Int

    var id: String {
        "\(reason.rawValue)-\(relatedCount)"
    }

    var titleKey: String {
        switch reason {
        case .duplicateFilePath:
            return "mac.viewer.attention.duplicate_file.title"
        case .duplicatePackageIdentifier:
            return "mac.viewer.attention.duplicate_package.title"
        case .duplicateSessionIdentifier:
            return "mac.viewer.attention.duplicate_session.title"
        }
    }

    var detailKey: String {
        switch reason {
        case .duplicateFilePath:
            return "mac.viewer.attention.duplicate_file.detail"
        case .duplicatePackageIdentifier:
            return "mac.viewer.attention.duplicate_package.detail"
        case .duplicateSessionIdentifier:
            return "mac.viewer.attention.duplicate_session.detail"
        }
    }
}

struct MacPackageAttentionSummary: Equatable {
    let packageCount: Int
    let duplicateFilePathCount: Int
    let duplicatePackageIdentifierCount: Int
    let duplicateSessionIdentifierCount: Int

    static let empty = MacPackageAttentionSummary(
        packageCount: 0,
        duplicateFilePathCount: 0,
        duplicatePackageIdentifierCount: 0,
        duplicateSessionIdentifierCount: 0
    )

    var hasAttention: Bool {
        packageCount > 0
    }

    static func make(from previews: [MacPackageImportPreview]) -> MacPackageAttentionSummary {
        let packagesWithWarnings = previews.filter { !$0.attentionWarnings.isEmpty }
        return MacPackageAttentionSummary(
            packageCount: packagesWithWarnings.count,
            duplicateFilePathCount: packagesWithWarnings.filter { $0.hasAttentionReason(.duplicateFilePath) }.count,
            duplicatePackageIdentifierCount: packagesWithWarnings.filter { $0.hasAttentionReason(.duplicatePackageIdentifier) }.count,
            duplicateSessionIdentifierCount: packagesWithWarnings.filter { $0.hasAttentionReason(.duplicateSessionIdentifier) }.count
        )
    }
}

extension MacPackageImportPreview {
    var hasAttentionWarnings: Bool {
        !attentionWarnings.isEmpty
    }

    func hasAttentionReason(_ reason: MacPackageAttentionWarning.Reason) -> Bool {
        attentionWarnings.contains { $0.reason == reason }
    }

    func replacingAttentionWarnings(_ warnings: [MacPackageAttentionWarning]) -> MacPackageImportPreview {
        MacPackageImportPreview(id: id, fileURL: fileURL, payload: payload, attentionWarnings: warnings)
    }
}

enum MacPackageAttentionClassifier {
    static func classifiedPreviews(
        from previews: [MacPackageImportPreview],
        acknowledgedDuplicateFilePaths: Set<String> = []
    ) -> [MacPackageImportPreview] {
        let duplicatePathCounts = occurrenceCounts(
            previews.map { normalizedPath(for: $0.fileURL) }
        )
        let uniquePreviews = uniquePreviewsByPath(from: previews)
        let duplicateSessionIdentifiers = duplicateSessionIdentifiers(in: uniquePreviews)
        let duplicatePackageIdentifiers = duplicatePackageIdentifiers(in: uniquePreviews)

        return uniquePreviews.map { preview in
            var warnings: [MacPackageAttentionWarning] = []
            let normalizedPath = normalizedPath(for: preview.fileURL)
            if (duplicatePathCounts[normalizedPath] ?? 0) > 1,
               !acknowledgedDuplicateFilePaths.contains(normalizedPath) {
                warnings.append(
                    MacPackageAttentionWarning(
                        reason: .duplicateFilePath,
                        relatedCount: duplicatePathCounts[normalizedPath] ?? 2
                    )
                )
            }

            if let packageIdentifier = packageIdentifierCandidate(for: preview),
               let relatedCount = duplicatePackageIdentifiers[packageIdentifier] {
                warnings.append(
                    MacPackageAttentionWarning(reason: .duplicatePackageIdentifier, relatedCount: relatedCount)
                )
            }

            if preview.payload.sessions.contains(where: { duplicateSessionIdentifiers[$0.id] != nil }) {
                let count = preview.payload.sessions.filter { duplicateSessionIdentifiers[$0.id] != nil }.count
                warnings.append(
                    MacPackageAttentionWarning(reason: .duplicateSessionIdentifier, relatedCount: count)
                )
            }

            return preview.replacingAttentionWarnings(warnings)
        }
    }

    private static func uniquePreviewsByPath(from previews: [MacPackageImportPreview]) -> [MacPackageImportPreview] {
        var seenPaths: Set<String> = []
        var unique: [MacPackageImportPreview] = []
        for preview in previews {
            let path = normalizedPath(for: preview.fileURL)
            guard !seenPaths.contains(path) else { continue }
            seenPaths.insert(path)
            unique.append(preview)
        }
        return unique
    }

    private static func duplicateSessionIdentifiers(in previews: [MacPackageImportPreview]) -> [UUID: Int] {
        let identifiers = previews.flatMap { preview in
            preview.payload.sessions.map(\.id)
        }
        return occurrenceCounts(identifiers).filter { $0.value > 1 }
    }

    private static func duplicatePackageIdentifiers(in previews: [MacPackageImportPreview]) -> [String: Int] {
        let identifiers = previews.compactMap(packageIdentifierCandidate)
        return occurrenceCounts(identifiers).filter { $0.value > 1 }
    }

    private static func packageIdentifierCandidate(for preview: MacPackageImportPreview) -> String? {
        // SkateTrackPackageManifest v1 currently has no dedicated package identifier.
        // Keep this hook nil until package metadata adds a real stable package ID.
        nil
    }

    private static func occurrenceCounts<T: Hashable>(_ values: [T]) -> [T: Int] {
        values.reduce(into: [:]) { counts, value in
            counts[value, default: 0] += 1
        }
    }

    private static func normalizedPath(for url: URL) -> String {
        url.standardizedFileURL.path
    }
}
