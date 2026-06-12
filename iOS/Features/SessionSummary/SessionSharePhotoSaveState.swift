// [協作區] SessionSharePhotoSaveState.swift
// 用途：描述 Task-023c 分享卡儲存到照片的 UI 狀態與本地化訊息。
// 委派至：SessionShareExportViewModel 更新狀態；SessionShareCardActionView 呈現狀態。

import Foundation

enum SessionSharePhotoSaveState: Equatable {
    case idle
    case saving
    case saved
    case failed(String)

    var messageKey: String? {
        switch self {
        case .idle, .saving:
            return nil
        case .saved:
            return "summary.share.photos.success"
        case .failed(let key):
            return key
        }
    }

    var isSaving: Bool {
        if case .saving = self { return true }
        return false
    }
}
