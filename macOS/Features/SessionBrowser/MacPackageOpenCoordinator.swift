// [協作區] macOS/Features/SessionBrowser/MacPackageOpenCoordinator.swift
// 用途：提供 Task-030e macOS read-only multi-file .skatetrack open foundation，逐檔讀取與分類結果。
// 委派至：MacPackageImportViewModel；不得寫入資料庫、建立文件關聯、merge、restore、sync 或修改 package payload。

import Foundation

struct MacPackageOpenFailure: Identifiable, Equatable {
    let id: String
    let fileURL: URL
    let fileName: String
    let errorMessageKey: String
}

private enum MacPackagePreviewReadResult: Equatable {
    case success(MacPackageImportPreview)
    case failure(String)
}

struct MacPackageOpenResult: Equatable {
    let requestedFileCount: Int
    let previews: [MacPackageImportPreview]
    let failures: [MacPackageOpenFailure]

    static let empty = MacPackageOpenResult(
        requestedFileCount: 0,
        previews: [],
        failures: []
    )

    var successfulPackageCount: Int {
        previews.count
    }

    var failedFileCount: Int {
        failures.count
    }

    var hasAnySuccess: Bool {
        !previews.isEmpty
    }

    var hasFailures: Bool {
        !failures.isEmpty
    }

    var isPartialSuccess: Bool {
        hasAnySuccess && hasFailures
    }

    var primaryErrorMessageKey: String? {
        failures.first?.errorMessageKey
    }
}

struct MacPackageOpenCoordinator {
    private let reader: SkateTrackPackageReader

    init(reader: SkateTrackPackageReader = SkateTrackPackageReader()) {
        self.reader = reader
    }

    func openPackages(from urls: [URL]) -> MacPackageOpenResult {
        var previews: [MacPackageImportPreview] = []
        var failures: [MacPackageOpenFailure] = []

        for (index, url) in urls.enumerated() {
            switch readPreview(from: url) {
            case .success(let preview):
                previews.append(preview)
            case .failure(let errorMessageKey):
                failures.append(
                    MacPackageOpenFailure(
                        id: "\(index)-\(url.lastPathComponent)",
                        fileURL: url,
                        fileName: url.lastPathComponent,
                        errorMessageKey: errorMessageKey
                    )
                )
            }
        }

        return MacPackageOpenResult(
            requestedFileCount: urls.count,
            previews: previews,
            failures: failures
        )
    }

    private func readPreview(from url: URL) -> MacPackagePreviewReadResult {
        guard url.pathExtension.lowercased() == "skatetrack" else {
            return .failure("mac.import.error.extension")
        }

        let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let payload = try reader.readPackage(from: url)
            return .success(MacPackageImportPreview(fileURL: url, payload: payload))
        } catch let packageError as SkateTrackPackageError {
            return .failure(packageError.localizationKey)
        } catch {
            return .failure("mac.import.error.generic")
        }
    }
}
