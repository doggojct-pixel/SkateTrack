// [協作區] MacPackageImportViewModel.swift
// 用途：macOS .skatetrack 匯入預覽狀態管理；只讀檔案並驗證 package，不寫入資料庫。
// 委派至：MacImportView / MacPackagePreviewView；不得進行 restore、merge、cloud sync 或 iOS DocumentPicker 行為。

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
    @Published private(set) var preview: MacPackageImportPreview?
    @Published private(set) var isImporting = false
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var lastReadFileName: String?

    private let reader: SkateTrackPackageReader

    init(reader: SkateTrackPackageReader = SkateTrackPackageReader()) {
        self.reader = reader
    }

    func importPackage(from url: URL) {
        isImporting = true
        errorMessageKey = nil
        lastReadFileName = url.lastPathComponent
        defer { isImporting = false }

        guard url.pathExtension.lowercased() == "skatetrack" else {
            preview = nil
            errorMessageKey = "mac.import.error.extension"
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
            preview = MacPackageImportPreview(fileURL: url, payload: payload)
        } catch let packageError as SkateTrackPackageError {
            preview = nil
            errorMessageKey = packageError.localizationKey
        } catch {
            preview = nil
            errorMessageKey = "mac.import.error.generic"
        }
    }

    func clearPreview() {
        preview = nil
        errorMessageKey = nil
        lastReadFileName = nil
    }
}
