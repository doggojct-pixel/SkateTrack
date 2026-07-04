// [協作區] MacPackageImportViewModel.swift
// 用途：macOS .skatetrack read-only package preview state；Task-030e 擴充為 in-memory multi-package viewer state。
// 委派至：MacImportView / MacSessionBrowserView / MacMultiPackageViewerState；不得進行 restore、merge、cloud sync 或 iOS DocumentPicker 行為。

import Foundation

struct MacPackageImportPreview: Identifiable, Equatable {
    let id = UUID()
    let fileURL: URL
    let payload: SkateTrackPackagePayload

    var manifest: SkateTrackPackageManifest {
        payload.manifest
    }

    var fileName: String {
        fileURL.lastPathComponent
    }

    var sessionCount: Int {
        payload.sessions.count
    }

    var motionSampleCount: Int {
        payload.sessions.reduce(0) { $0 + $1.motionSamples.count }
    }

    var routeSampleCount: Int {
        payload.sessions.reduce(0) { partial, packageSession in
            partial + packageSession.motionSamples.filter { $0.gpsCoordinate != nil }.count
        }
    }

    var primaryPackageSession: SkateTrackPackageSession? {
        payload.primarySession
    }

    var primarySession: SessionData? {
        primaryPackageSession?.session
    }

    var primaryTitle: String {
        if let displayName = primarySession?.spotSnapshot?.displayName, !displayName.isEmpty {
            return displayName
        }
        return String(localized: "mac.package.preview.untitled_session")
    }

    var exportedAt: Date? {
        primaryPackageSession?.exportedAt
    }

    var privacyNotes: [String] {
        primaryPackageSession?.privacyNotes ?? []
    }
}

@MainActor
final class MacPackageImportViewModel: ObservableObject {
    @Published private(set) var viewerState = MacMultiPackageViewerState()
    @Published private(set) var isImporting = false
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var lastReadFileName: String?

    private let reader: SkateTrackPackageReader

    init(reader: SkateTrackPackageReader = SkateTrackPackageReader()) {
        self.reader = reader
    }

    var preview: MacPackageImportPreview? {
        viewerState.selectedPackage
    }

    var openedPackages: [MacPackageImportPreview] {
        viewerState.packages
    }

    var batchSummary: MacPackageOpenBatchSummary {
        viewerState.batchSummary
    }

    var selectedPackageID: UUID? {
        viewerState.selection.selectedPackageID
    }

    var selectedSessionID: UUID? {
        viewerState.selection.selectedSessionID
    }

    var selectedPackageSession: SkateTrackPackageSession? {
        viewerState.selectedPackageSession
    }

    var selectedViewerModels: [MacSessionViewerModel] {
        preview?.payload.sessions.map(MacSessionViewerModel.init) ?? []
    }

    var selectedViewerModel: MacSessionViewerModel? {
        let models = selectedViewerModels
        if let selectedSessionID,
           let selected = models.first(where: { $0.id == selectedSessionID }) {
            return selected
        }
        return models.first
    }

    func importPackage(from url: URL) {
        isImporting = true
        errorMessageKey = nil
        lastReadFileName = url.lastPathComponent
        defer { isImporting = false }

        guard url.pathExtension.lowercased() == "skatetrack" else {
            clearPackagesForReadFailure(errorMessageKey: "mac.import.error.extension")
            return
        }

        let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let payload = try reader.readPackage(from: url)
            let preview = MacPackageImportPreview(fileURL: url, payload: payload)
            var nextState = viewerState
            nextState.replace(with: preview)
            viewerState = nextState
        } catch let packageError as SkateTrackPackageError {
            clearPackagesForReadFailure(errorMessageKey: packageError.localizationKey)
        } catch {
            clearPackagesForReadFailure(errorMessageKey: "mac.import.error.generic")
        }
    }

    func appendPackagePreviewForFutureBatch(_ preview: MacPackageImportPreview) {
        var nextState = viewerState
        nextState.appendOrReplacePackage(preview)
        viewerState = nextState
    }

    func selectPackage(id: UUID?) {
        var nextState = viewerState
        nextState.selectPackage(id: id)
        viewerState = nextState
    }

    func selectSession(id: UUID?) {
        var nextState = viewerState
        nextState.selectSession(id: id)
        viewerState = nextState
    }

    func removePackage(id: UUID) {
        var nextState = viewerState
        nextState.removePackage(id: id)
        viewerState = nextState
    }

    func ensureDefaultSelection() {
        var nextState = viewerState
        nextState.ensureValidSelection()
        viewerState = nextState
    }

    func clearPreview() {
        var nextState = viewerState
        nextState.clear()
        viewerState = nextState
        errorMessageKey = nil
        lastReadFileName = nil
    }

    private func clearPackagesForReadFailure(errorMessageKey: String) {
        var nextState = viewerState
        nextState.clear()
        viewerState = nextState
        self.errorMessageKey = errorMessageKey
    }
}
