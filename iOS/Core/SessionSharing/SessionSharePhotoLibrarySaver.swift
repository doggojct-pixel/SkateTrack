// [自主區] SessionSharePhotoLibrarySaver.swift
// 用途：以 add-only Photo Library 權限將 Task-023c 分享卡 PNG 儲存到照片。
// 委派至：SessionShareExportViewModel 統一管理 UI 狀態；View 不直接操作 Photos framework。

import Foundation
import Photos
import UIKit

enum SessionSharePhotoLibraryError: Error {
    case authorizationDenied
    case invalidImageData
    case saveFailed

    var localizationKey: String {
        switch self {
        case .authorizationDenied:
            return "summary.share.photos.error.permission"
        case .invalidImageData:
            return "summary.share.export.error.image"
        case .saveFailed:
            return "summary.share.photos.error.save"
        }
    }
}

struct SessionSharePhotoLibrarySaver {
    func savePNGData(_ data: Data) async throws {
        let status = await requestAddOnlyAuthorizationIfNeeded()
        guard status == .authorized || status == .limited else {
            throw SessionSharePhotoLibraryError.authorizationDenied
        }

        guard let image = UIImage(data: data) else {
            throw SessionSharePhotoLibraryError.invalidImageData
        }

        try await performPhotoLibrarySave(image: image)
    }

    private func requestAddOnlyAuthorizationIfNeeded() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard currentStatus == .notDetermined else { return currentStatus }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func performPhotoLibrarySave(image: UIImage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? SessionSharePhotoLibraryError.saveFailed)
                }
            }
        }
    }
}
