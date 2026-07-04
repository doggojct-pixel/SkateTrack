// [協作區] macOS/Features/SessionBrowser/MacMultiPackageViewerState.swift
// 用途：提供 Task-030e read-only multi-package viewer 的 in-memory package / session selection state。
// 委派至：MacPackageImportViewModel / MacSessionBrowserView；不得寫入資料庫、merge、restore、同步雲端或修改 package。

import Foundation

struct MacMultiPackageViewerSelection: Equatable {
    var selectedPackageID: UUID?
    var selectedSessionID: UUID?

    static let empty = MacMultiPackageViewerSelection(
        selectedPackageID: nil,
        selectedSessionID: nil
    )
}

struct MacPackageOpenBatchSummary: Equatable {
    let totalPackageCount: Int
    let totalSessionCount: Int
    let routeCapablePackageCount: Int
    let selectedPackageIndex: Int?

    var hasPackages: Bool {
        totalPackageCount > 0
    }
}

struct MacMultiPackageViewerState: Equatable {
    private(set) var packages: [MacPackageImportPreview]
    private(set) var selection: MacMultiPackageViewerSelection

    init(
        packages: [MacPackageImportPreview] = [],
        selection: MacMultiPackageViewerSelection = .empty
    ) {
        self.packages = packages
        self.selection = selection
        ensureValidSelection()
    }

    var selectedPackage: MacPackageImportPreview? {
        guard let selectedPackageID = selection.selectedPackageID else {
            return packages.first
        }
        return packages.first(where: { $0.id == selectedPackageID }) ?? packages.first
    }

    var selectedPackageIndex: Int? {
        guard let selectedPackage else { return nil }
        return packages.firstIndex(where: { $0.id == selectedPackage.id })
    }

    var selectedPackageSession: SkateTrackPackageSession? {
        guard let selectedPackage else { return nil }
        if let selectedSessionID = selection.selectedSessionID,
           let selected = selectedPackage.payload.sessions.first(where: { $0.id == selectedSessionID }) {
            return selected
        }
        return selectedPackage.payload.sessions.first
    }

    var batchSummary: MacPackageOpenBatchSummary {
        MacPackageOpenBatchSummary(
            totalPackageCount: packages.count,
            totalSessionCount: packages.reduce(0) { $0 + $1.sessionCount },
            routeCapablePackageCount: packages.filter { $0.routeSampleCount > 0 }.count,
            selectedPackageIndex: selectedPackageIndex
        )
    }

    mutating func replace(with preview: MacPackageImportPreview) {
        replace(with: [preview])
    }

    mutating func replace(with previews: [MacPackageImportPreview]) {
        packages = uniquePreviews(from: previews)
        selection = .empty
        ensureValidSelection()
    }

    mutating func appendOrReplacePackage(_ preview: MacPackageImportPreview) {
        if let existingIndex = packages.firstIndex(where: { $0.fileURL.path == preview.fileURL.path }) {
            packages[existingIndex] = preview
        } else {
            packages.append(preview)
        }
        selection.selectedPackageID = preview.id
        selection.selectedSessionID = preview.primaryPackageSession?.id ?? preview.payload.sessions.first?.id
        ensureValidSelection()
    }

    mutating func selectPackage(id: UUID?) {
        selection.selectedPackageID = id
        selection.selectedSessionID = nil
        ensureValidSelection()
    }

    mutating func selectSession(id: UUID?) {
        selection.selectedSessionID = id
        ensureValidSelection()
    }

    mutating func removePackage(id: UUID) {
        packages.removeAll { $0.id == id }
        if selection.selectedPackageID == id {
            selection.selectedPackageID = nil
            selection.selectedSessionID = nil
        }
        ensureValidSelection()
    }

    mutating func clear() {
        packages.removeAll()
        selection = .empty
    }

    private func uniquePreviews(from previews: [MacPackageImportPreview]) -> [MacPackageImportPreview] {
        var seenPaths: Set<String> = []
        var unique: [MacPackageImportPreview] = []
        for preview in previews {
            let path = preview.fileURL.standardizedFileURL.path
            guard !seenPaths.contains(path) else { continue }
            seenPaths.insert(path)
            unique.append(preview)
        }
        return unique
    }

    mutating func ensureValidSelection() {
        guard !packages.isEmpty else {
            selection = .empty
            return
        }

        if let selectedPackageID = selection.selectedPackageID,
           packages.contains(where: { $0.id == selectedPackageID }) {
            // Keep the current package selection.
        } else {
            selection.selectedPackageID = packages.first?.id
        }

        guard let selectedPackage else {
            selection.selectedSessionID = nil
            return
        }

        if let selectedSessionID = selection.selectedSessionID,
           selectedPackage.payload.sessions.contains(where: { $0.id == selectedSessionID }) {
            return
        }

        selection.selectedSessionID = selectedPackage.payload.sessions.first?.id
    }
}
