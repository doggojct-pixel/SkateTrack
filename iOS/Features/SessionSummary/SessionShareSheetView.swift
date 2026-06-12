// [協作區 — 系統橋接層] SessionShareSheetView.swift
// 用途：以 UIActivityViewController 開啟 iOS 系統分享表，僅接收 Task-023b 本機暫存檔 URL。
// 委派至：SessionShareExportViewModel 在分享表關閉後清理暫存檔。

import SwiftUI
import UIKit

struct SessionShareSheetView: UIViewControllerRepresentable {
    let itemURLs: [URL]
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: itemURLs, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            DispatchQueue.main.async {
                onComplete()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
