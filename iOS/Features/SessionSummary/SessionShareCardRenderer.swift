// [協作區 — 邊界適配層] SessionShareCardRenderer.swift
// 用途：將 Task-023a 分享卡 SwiftUI preview 渲染成 Task-023b 本機分享 PNG。
// 委派至：SessionShareExportService 寫入暫存檔；View 不直接操作 ImageRenderer。

import SwiftUI
import UIKit

@MainActor
struct SessionShareCardRenderer {
    private let cardWidth: CGFloat = 390
    private let canvasPadding: CGFloat = 22

    func renderPNG(card: SessionShareCardData) throws -> Data {
        let canvas = exportCanvas(card: card)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(width: cardWidth + canvasPadding * 2, height: nil)

        guard let image = renderer.uiImage, let data = image.pngData(), !data.isEmpty else {
            throw SessionShareExportError.imageEncodingFailed
        }
        return data
    }

    private func exportCanvas(card: SessionShareCardData) -> some View {
        SessionShareCardPreviewView(card: card)
            .frame(width: cardWidth)
            .padding(canvasPadding)
            .background(SkateTrackSessionStartColors.navy)
            .preferredColorScheme(.dark)
    }
}
