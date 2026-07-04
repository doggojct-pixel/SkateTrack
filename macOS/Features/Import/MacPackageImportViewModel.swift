// [協作區] MacPackageImportViewModel.swift
// 用途：macOS .skatetrack read-only package preview state；Task-030e 擴充為 in-memory multi-package viewer state 與多檔開啟結果。
// 委派至：MacImportView / MacSessionBrowserView / MacPackageOpenCoordinator / MacMultiPackageViewerState；不得進行 restore、merge、cloud sync 或 iOS DocumentPicker 行為。

import Foundation

struct MacPackageImportPreview: Identifiable, Equatable {
    let id: UUID
    let fileURL: URL
    let payload: SkateTrackPackagePayload
    let attentionWarnings: [MacPackageAttentionWarning]

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

    init(
        id: UUID = UUID(),
        fileURL: URL,
        payload: SkateTrackPackagePayload,
        attentionWarnings: [MacPackageAttentionWarning] = []
    ) {
        self.id = id
        self.fileURL = fileURL
        self.payload = payload
        self.attentionWarnings = attentionWarnings
    }
}

@MainActor
final class MacPackageImportViewModel: ObservableObject {
    @Published private(set) var viewerState = MacMultiPackageViewerState()
    @Published private(set) var isImporting = false
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var lastReadFileName: String?
    @Published private(set) var lastOpenResult: MacPackageOpenResult?

    private let openCoordinator: MacPackageOpenCoordinator

    init(reader: SkateTrackPackageReader = SkateTrackPackageReader()) {
        self.openCoordinator = MacPackageOpenCoordinator(reader: reader)
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

    var attentionSummary: MacPackageAttentionSummary {
        viewerState.attentionSummary
    }

    var hasAcknowledgeableDuplicateFilePathWarnings: Bool {
        viewerState.hasAcknowledgeableDuplicateFilePathWarnings
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
        openPackages(from: [url])
    }

    func openPackages(from urls: [URL]) {
        guard !urls.isEmpty else { return }

        isImporting = true
        errorMessageKey = nil
        lastOpenResult = nil
        lastReadFileName = urls.count == 1 ? urls.first?.lastPathComponent : nil
        defer { isImporting = false }

        let result = openCoordinator.openPackages(from: urls)
        lastOpenResult = result

        if result.hasAnySuccess {
            var nextState = viewerState
            nextState.mergeOpenedPreviews(result.previews)
            viewerState = nextState
            errorMessageKey = nil
        } else if viewerState.packages.isEmpty {
            clearPackagesForReadFailure(errorMessageKey: result.primaryErrorMessageKey ?? "mac.import.error.generic")
        } else {
            errorMessageKey = result.primaryErrorMessageKey ?? "mac.import.error.generic"
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

    func acknowledgeDuplicateFilePathWarnings() {
        var nextState = viewerState
        nextState.acknowledgeDuplicateFilePathWarnings()
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
        lastOpenResult = nil
    }

    private func clearPackagesForReadFailure(errorMessageKey: String) {
        var nextState = viewerState
        nextState.clear()
        viewerState = nextState
        self.errorMessageKey = errorMessageKey
    }
}
