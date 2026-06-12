// [協作區] SessionShareExportPayload.swift
// 用途：描述 Task-023b 本機快速匯出的檔案集合，不負責產生檔案或開啟分享表。
// 委派至：SessionShareExportService 寫入暫存檔；SessionShareSheetView 橋接系統分享表。

import Foundation

struct SessionShareExportPayload: Identifiable, Equatable {
    let id: UUID
    let sessionID: UUID
    let directoryURL: URL
    let imageURL: URL
    let textURL: URL
    let jsonURL: URL
    let createdAt: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        directoryURL: URL,
        imageURL: URL,
        textURL: URL,
        jsonURL: URL,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionID = sessionID
        self.directoryURL = directoryURL
        self.imageURL = imageURL
        self.textURL = textURL
        self.jsonURL = jsonURL
        self.createdAt = createdAt
    }

    var itemURLs: [URL] {
        [imageURL, textURL, jsonURL]
    }
}
