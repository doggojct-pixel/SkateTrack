// [協作區] Shared/Persistence/RepositoryError.swift
// 用途：定義 SkateTrack 本機資料層錯誤，讓 UI / ViewModel 可以使用本地化 key 顯示錯誤。
// 委派至：SessionRepository、MotionSampleFileStore、Task-015b recording integration。

import Foundation

enum RepositoryError: Error, Sendable, Equatable {
    case persistenceStoreUnavailable
    case sessionNotFound
    case motionSampleFileMissing
    case encodingFailed
    case decodingFailed
    case exportFailed
    case deleteFailed
    case saveFailed

    var localizationKey: String {
        switch self {
        case .persistenceStoreUnavailable:
            return "repository.error.storeUnavailable"
        case .sessionNotFound:
            return "repository.error.sessionNotFound"
        case .motionSampleFileMissing:
            return "repository.error.motionSampleFileMissing"
        case .encodingFailed:
            return "repository.error.encodingFailed"
        case .decodingFailed:
            return "repository.error.decodingFailed"
        case .exportFailed:
            return "repository.error.exportFailed"
        case .deleteFailed:
            return "repository.error.deleteFailed"
        case .saveFailed:
            return "repository.error.saveFailed"
        }
    }
}
